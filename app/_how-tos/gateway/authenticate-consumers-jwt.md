---
title: Authenticate Consumers with the JWT plugin
permalink: /how-to/authenticate-consumers-jwt/
content_type: how_to
related_resources:
  - text: Authentication
    url: /gateway/authentication/
description: Learn how to authenticate Consumers with a signed JWT credential.

products:
    - gateway

plugins:
  - jwt

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
    - jwt

tldr:
    q: How do I authenticate Consumers with JWT tokens?
    a: Create a Consumer with an algorithm, key, and secret in the `jwt_secrets` configuration. Enable the JWT plugin globally, and authenticate with the signed Consumer credentials.

tools:
    - deck

prereqs:
  entities:
    services:
        - example-service
    routes:
        - example-route

cleanup:
  inline:
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg
---

## Create a Consumer

[Consumers](/gateway/entities/consumer/) let you identify the client that's interacting with {{site.base_gateway}}.
We're going to use JWT [authentication](/gateway/authentication/) in this tutorial, so the Consumer needs a key and secret to access any {{site.base_gateway}} Services. 

We're specifying the key and secret here, but you can leave it out of the configuration in production if you want {{site.base_gateway}} to autogenerate it. 

Create a Consumer:

{% entity_examples %}
entities:
  consumers:
    - username: jsmith
      jwt_secrets:
         - algorithm: HS256
           key: YJdmaDvVTJxtcWRCvkMikc8oELgAVNcz
           secret: C50k0bcahDhLNhLKSUBSR1OMiFGzNZ7X
{% endentity_examples %}

## Enable authentication

Authentication lets you identify a Consumer. In this how-to, we'll be using the [JWT plugin](/plugins/jwt/) for authentication, which allows users to authenticate with a JWT token when they make a request.

Enable the plugin globally, which means it applies to all {{site.base_gateway}} Services and Routes:

{% entity_examples %}
entities:
  plugins:
    - name: jwt
      config:
        header_names: 
        - authorization
        key_claim_name: iss
{% endentity_examples %}

## Sign the Consumer credential

Since we specified the `HS256` algorithm when we were configuring the Consumer credentials, we need to sign our credential before we can use it for authentication. JWT credentials are signed with a header, payload, and the secret.

The header value is:

```json
{
    "typ": "JWT",
    "alg": "HS256"
}
```
{:.no-copy-code}

Since we configured `iss` for the `config.key_claim_name`, we'll specify the Consumer's key in the `iss` payload:

```json
{
   "iss": "YJdmaDvVTJxtcWRCvkMikc8oELgAVNcz"
}
```
{:.no-copy-code}

The secret is the value we set in the Consumer credentials previously:
```
C50k0bcahDhLNhLKSUBSR1OMiFGzNZ7X
```
{:.no-copy-code}

Using the [JWT debugger](https://jwt.io) with the header (`HS256`), claims (`iss`), and `secret` associated with this `key`, you’ll end up with a JWT token of:

```
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJZSmRtYUR2VlRKeHRjV1JDdmtNaWtjOG9FTGdBVk5jeiJ9.xG-DrlD4vcYBqhuhK_jrwFIALvVvU-qTOiNyIfUhn_Y
```
{:.no-copy-code}

Save the token as an environment variable:

{% env_variables %}
JWT_TOKEN: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJZSmRtYUR2VlRKeHRjV1JDdmtNaWtjOG9FTGdBVk5jeiJ9.xG-DrlD4vcYBqhuhK_jrwFIALvVvU-qTOiNyIfUhn_Y
{% endenv_variables %}

## Validate

When a Consumer authenticates with JWT, you can now use the signed credential in the authorization header.

First, run the following to verify that unauthorized requests return an error:

<!--vale off-->
{% validation unauthorized-check %}
url: /anything
status_code: 401
{% endvalidation %}
<!--vale on-->

Then, run the following command to test Consumer authentication:

{% validation request-check %}
url: '/anything'
headers:
  - 'Authorization: Bearer $JWT_TOKEN'
  - 'Content-Type: application/json'
status_code: 200
{% endvalidation %}
