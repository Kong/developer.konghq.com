---
title: Configure OpenID Connect with Consumer Group authorization
permalink: /how-to/configure-oidc-with-consumer-groups/
content_type: how_to

related_resources:
  - text: OpenID Connect in {{site.base_gateway}}
    url: /gateway/openid-connect/
  - text: Authentication in {{site.base_gateway}}
    url: /gateway/authentication/
  - text: OpenID Connect authorization options
    url: /plugins/openid-connect/#authorization
  - text: Consumer Group authorization in OIDC
    url: /plugins/openid-connect/#consumer-group-authorization
  - text: OpenID Connect tutorials
    url: /how-to/?query=openid-connect

plugins:
  - openid-connect

entities:
  - route
  - service
  - consumer
  - consumer-group

products:
  - gateway

works_on:
  - on-prem
  - konnect

min_version:
  gateway: '3.12'

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
      include_content: prereqs/auth/oidc/keycloak-consumer-group
      icon_url: /assets/icons/keycloak.svg

tags:
  - authorization
  - openid-connect
search_aliases:
  - oidc

description: Configure the OpenID Connect plugin together with Consumer Groups to map Consumer Groups to IdP client claims.

tldr:
  q: How do I map Consumer Groups to IdP client claims with OpenID Connect?
  a: |
    Use the OpenID Connect plugin with [Consumer Groups](/gateway/entities/consumer-group/) for authorization and dynamically map claim values to Consumer Groups. This only allows IdP users that have a matching Consumer Group in {{site.base_gateway}} to access your Services, giving you more control over which clients have access to {{site.base_gateway}}.
  
    Set up `client_credential` authentication and enable Consumer Group mapping by setting a claim to map to.

cleanup:
  inline:
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg

automated_tests: false
---

## Enable the OpenID Connect plugin

Using the Keycloak and {{site.base_gateway}} configuration from the [prerequisites](#prerequisites), 
set up an instance of the OpenID Connect plugin. In this example, we're using the `client_credentials` grant with the `tier` Consumer Group claim.

Enable the OpenID Connect plugin on the `example-service` Service:

{% entity_examples %}
entities:
  plugins:
    - name: openid-connect
      service: example-service
      config:
        issuer: ${issuer}
        auth_methods:
        - client_credentials
        consumer_groups_claim:
        - tier
variables:
  issuer:
    value: $ISSUER
{% endentity_examples %}

In this example:
* `issuer`: Settings that connect the plugin to your IdP (in this case, the sample Keycloak app).
* `auth_methods`:  Specifies that the plugin should use the client credentials grant.
* `consumer_group_claim`: Looks for a client claim name in the token payload and maps it to the Consumer Group entity by the entity's `name` value.

## Create a Consumer Group

First, let's try to access the Service without a matching Consumer Group.
Request the Service with the basic authentication credentials created in the [prerequisites](#prerequisites):

{% validation request-check %}
url: /anything
method: GET
status_code: 401
headers:
  - 'Authorization: Basic {{ "kong:wrong-secret" | base64 }}'
display_headers: true
{% endvalidation %}

You should get a `401 Unauthorized` error code, which means the Service is protected by claim authorization.

Create a Consumer Group with a name that matches the client claim value in your IdP, in this case `gold`:

{% entity_examples %}
entities:
  consumer_groups:
    - name: gold
{% endentity_examples %}

## Verify Consumer Group authorization

Now, your configured Consumer Group can access the `example-route` Route by using client name and client secret in `client-name:client-secret` format:

{% validation request-check %}
url: /anything
method: GET
status_code: 200
headers:
  - 'Authorization: Basic {{ "kong:$CLIENT_SECRET" | base64 }}'
display_headers: true
{% endvalidation %}

This time, you should get a `200` response. 
The OIDC plugin decodes the token it receives from the IdP, finds the client claim value, and maps it to our Consumer Group `gold`.