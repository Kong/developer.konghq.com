---
title: Configure OpenID Connect with Consumer authorization
permalink: /how-to/configure-oidc-with-consumers/
content_type: how_to

related_resources:
  - text: OpenID Connect in {{site.base_gateway}}
    url: /gateway/openid-connect/
  - text: Authentication in {{site.base_gateway}}
    url: /gateway/authentication/
  - text: OpenID Connect authorization options
    url: /plugins/openid-connect/#authorization
  - text: Consumer authorization in OIDC
    url: /plugins/openid-connect/#consumer-authorization
  - text: OpenID Connect tutorials
    url: /how-to/?query=openid-connect

plugins:
  - openid-connect

entities:
  - route
  - service
  - consumer

products:
  - gateway

works_on:
  - on-prem
  - konnect

min_version:
  gateway: '3.4'

tools:
  - deck

prereqs:
  entities:
    services:
      - example-service
    routes:
      - example-route
  inline:
    - title: Set up Keycloak
      include_content: prereqs/auth/oidc/keycloak-password
      icon_url: /assets/icons/keycloak.svg

tags:
  - authorization
  - openid-connect
search_aliases:
  - oidc

description: Configure the OpenID Connect plugin together with Consumers to map Consumers to IdP users.

tldr:
  q: How do I map Consumers to IdP users with OpenID Connect?
  a: |
    Use the OpenID Connect plugin with [Consumers](/gateway/entities/consumer/) for authorization and dynamically map claim values to Consumers. This only allows IdP users that have a matching Consumer in {{site.base_gateway}} to access your Services, giving you more control over which clients have access to {{site.base_gateway}}.
  
    Set up any type of authentication (the password grant, in this guide) and enable Consumer mapping by setting a claim to map to.

faqs:
  - q: When using Consumer authorization, is Consumer mapping required?
    a: |
      Consumer mapping is required by default, but you can make Consumer mapping optional and non-authorizing by setting the OpenID Connect plugin's configuration parameter [`config.consumer_optional`](/plugins/openid-connect/reference/#schema--config-consumer-optional) to `true`.
  - q: Can I use Consumer mapping with ACL allow/deny lists?
    a: |
      Yes, you can combine the Consumer claim with the authorization group claim to further secure your environment. See the how-to on [configuring OIDC with ACL groups](/how-to/configure-oidc-with-acl-auth/) for more information.

cleanup:
  inline:
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg
---

## Enable the OpenID Connect plugin

Using the Keycloak and {{site.base_gateway}} configuration from the [prerequisites](#prerequisites), 
set up an instance of the OpenID Connect plugin. In this example, we're using the simple password grant with the `preferred_username` Consumer claim.

Enable the OpenID Connect plugin on the `example-service` Service:

{% entity_examples %}
entities:
  plugins:
    - name: openid-connect
      service: example-service
      config:
        issuer: ${issuer}
        client_id:
        - ${client-id}
        client_secret:
        - ${client-secret}
        client_auth:
        - client_secret_post
        auth_methods:
        - password
        consumer_claim:
        - preferred_username
        consumer_by:
        - username
variables:
  issuer:
    value: $ISSUER
  client-id:
    value: $CLIENT_ID
  client-secret:
    value: $CLIENT_SECRET
{% endentity_examples %}

In this example:
* `issuer`, `client ID`, `client secret`, and `client auth`: Settings that connect the plugin to your IdP (in this case, the sample Keycloak app).
* `auth_methods`:  Specifies that the plugin should use the password grant, for easy testing.
* `consumer_claim` and `consumer_by` : Looks for a `preferred_username` in the token payload and maps it to the Consumer entity by the entity's `username` value.

{% include_cached plugins/oidc/client-auth.md %}

## Create a Consumer

First, let's try to access the Service without a matching Consumer.
Request the Service with the basic authentication credentials created in the [prerequisites](#prerequisites):

{% validation request-check %}
url: /anything
method: GET
status_code: 403
user: "alex:doe"
display_headers: true
{% endvalidation %}

You should get a `403 Forbidden` error code, which means the Service is protected by authentication.

Create a Consumer with a username that matches the user in your IdP, in this case `alex`:

{% entity_examples %}
entities:
  consumers:
    - username: alex
{% endentity_examples %}

## Verify Consumer authorization

Now, your configured Consumer can access the `example-route` Route by using their username and password in `username:password` format:

{% validation request-check %}
url: /anything
method: GET
status_code: 200
user: "alex:doe"
display_headers: true
{% endvalidation %}

This time, you should get a `200` response. 
The OIDC plugin decodes the token it receives from the IdP, finds the `preferred_username` value, and maps it to our Consumer `alex`.

In the response, you'll see that the plugin added the `X-Consumer-Id` and `X-Consumer-Username` as request headers, and returned an `Authorization` bearer token:

```json
"Authorization": "Bearer abcxyz...",
"X-Consumer-Id": "some-uuid",
"X-Consumer-Username": "alex"
```
{:.no-copy-code}