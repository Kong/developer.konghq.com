---
title: Authenticate Consumers with the JWT plugin and Auth0
content_type: how_to
related_resources:
  - text: Authentication
    url: /gateway/authentication/
description: REPLACE ME!!!!!!!!!!!

products:
    - gateway

plugins:
  - basic-auth

works_on:
    - on-prem
    - konnect

min_version:
  gateway: '3.4'

entities: 
  - plugin
  - service
  - route
  - consumer

tags:
    - authentication

tldr:
    q: How do I authenticate Consumers with JWT tokens?
    a: Create a Consumer with a username and password in the `basicauth_credentials` configuration. Enable the Basic Authentication plugin globally, and authenticate with the base64-encoded Consumer credentials.

tools:
    - deck

prereqs:
  entities:
    services:
        - example-service
    routes:
        - example-route
  inline:
    - title: Auth0
      content: |
        ```bash
        export TENANT_NAME='<your-auth0-tenant>'
        export AUTH0_REGION='<your-auth0-region>'
        ```
      icon_url: /assets/icons/third-party/auth0.svg
  

cleanup:
  inline:
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg
---

## 1. Download the Auth0 certificate

[Auth0](https://auth0.com/) is a popular solution for authorization, and relies heavily on JWTs. Auth0 relies on RS256, does not base64 encode, and publicly hosts the public key certificate used to sign tokens.

First, download your [Auth0 application signing certificate](https://auth0.com/docs/get-started/tenant-settings/signing-keys#how-it-works) as a .pem file. You can find this in you Auth0 dashboard under the advanced settings for your application.

```bash
curl -o $TENANT_NAME.pem https://$TENANT_NAME.$AUTH0_REGION.auth0.com/pem
```

Extract the public key from the X509 certificate:

```bash
openssl x509 -pubkey -noout -in $TENANT_NAME.pem > pubkey.pem
```

## 1. Create a Consumer

[Consumers](/gateway/entities/consumer/) let you identify the client that's interacting with {{site.base_gateway}}.
We're going to use JWT [authentication](/gateway/authentication/) in this tutorial, so the Consumer needs a key and secret to access any {{site.base_gateway}} Services. We're specifying the key and secret here, but you can leave it out of the configuration in production if you want {{site.base_gateway}} to autogenerate it. 

Create a Consumer:

{% entity_examples %}
entities:
  consumers:
    - username: jsmith
{% endentity_examples %}

<!--vale off-->
{% control_plane_request %}
  url: /consumers/jsmith/jwt
  method: POST
  headers:
      - 'Accept: application/json'
  body:
    algorithm: RS256
    rsa_public_key: "@./pubkey.pem"
    key: "https://$TENANT_NAME.auth0.com/"
{% endcontrol_plane_request %}
<!--vale on-->

## 2. Enable authentication

Authentication lets you identify a Consumer. In this how-to, we'll be using the [JWT plugin](/plugins/jwt/) for authentication, which allows users to authenticate with a JWT token when they make a request.

Enable the plugin on the Route:

{% entity_examples %}
entities:
  plugins:
    - name: jwt
      route: example-route
      config:
        header_names: 
        - authorization
{% endentity_examples %}

## 4. Validate

The JWT plugin by default validates the `key_claim_name` against the `iss` field in the token. Keys issued by Auth0 have their `iss` field set to `http://$TENANT_NAME.auth0.com/`. You can use the [JWT debugger](https://jwt.io/) to validate the `iss` field for the `key` parameter when creating the Consumer.

When a Consumer authenticates with JWT, you can now use their credential in the authorization header.

First, run the following to verify that unauthorized requests return an error:

<!--vale off-->
{% validation unauthorized-check %}
url: /anything
headers:
  - 'authorization: Bearer wrongpassword'
  - 'Content-Type: application/json'
status_code: 401
{% endvalidation %}
<!--vale on-->

Then, run the following command to test Consumer authentication:

{% validation request-check %}
url: '/anything'
headers:
  - 'authorization: Bearer $JWT_TOKEN'
  - 'Content-Type: application/json'
status_code: 200
{% endvalidation %}
