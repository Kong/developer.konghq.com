---
title: Enable OAuth 2.0 authentication for WebSocket requests
permalink: /how-to/enable-oauth2-authentication-for-websocket-requests/
content_type: how_to

description: Create an OAuth 2.0 Client Credentials flow for a WebSocket Gateway Service.

related_resources:
  - text: Authentication
    url: /authentication/

products:
    - gateway
breadcrumbs:
  - /gateway/
entities: 
  - service
  - consumer
  - route

plugins:
    - oauth2

tags:
  - authentication
  - oauth2

tools:
    - deck

works_on:
    - on-prem

prereqs:
  entities:
    services:
        - websocket-service
    routes:
        - websocket-route
tldr:
    q: How do I set up OAuth 2.0 for a WebSocket Service?
    a: Since the [OAuth 2.0 Authentication](/plugins/oauth2/) plugin can't issue new tokens from a WebSocket Route, create a separate HTTP Service and Route to handle token generation. Enable the plugin on both the WebSocket Service and on the HTTP Route, and make sure to set `config.global_credentials` to `true`.

cleanup:
  inline:
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg

min_version:
    gateway: '3.4'

automated_tests: false
---

## Create an HTTP Service and Route to handle token creation
In the [prerequisites](#prerequisites), you created a WebSocket Service and Route.

To use the [OAuth 2.0 Authentication](/plugins/oauth2/) plugin with WebSocket services, you need an additional non-WebSocket Route to issue tokens:
{% entity_examples %}
entities:
  routes:
    - name: websocket-token-route
      protocols:
        - https
      paths:
        - /token-route
      methods:
        - POST
{% endentity_examples %}

## Generate a provision key

{% include /how-tos/steps/oauth-provision-key.md %}

## Enable the OAuth 2.0 plugin

Enable the plugin on:
* The WebSocket Gateway Service we created in the [prerequisites](#prerequisites), to secure it
* The HTTP Route, to enable token generation

Set [`config.global_credentials`](/plugins/oauth2/reference/#schema--config-global-credentials) to `true` to allow tokens created by other plugin instances.

{% entity_examples %}
entities:
  plugins:
    - name: oauth2
      service: example-websocket-service
      config:
        scopes:
          - email
          - profile
        global_credentials: true
        provision_key: ${key}
        enable_client_credentials: true
    - name: oauth2
      route: websocket-token-route
      config:
        scopes:
          - email
          - profile
        global_credentials: true
        provision_key: ${key}
        enable_client_credentials: true
variables:
  key:
    value: $PROVISION_KEY
{% endentity_examples %}

## Create a Consumer

{% include /how-tos/steps/oauth-consumer.md %}

## Create an application

{% include /how-tos/steps/oauth-application.md %}

## Generate a token

Use the applications's client credentials to generate a token:
```sh
curl -X POST "https://localhost:8443/token-route/oauth2/token" \
  --header "Content-Type: application/json" \
  --json '{ 
    "client_id": "'$CLIENT_ID'", 
    "client_secret": "'$CLIENT_SECRET'", 
    "grant_type": "client_credentials" 
  }'
```

{:.info}
> **Note**: This request requires HTTPS, so we need to use the `8443` port instead of `8000`.

## Validate

To validate that the configuration works as expected, open a WebSocket connection to `ws://localhost:8000/anything` using the `Authorization` header with the Bearer token we generated. You can do this using [Insomnia](/insomnia/requests/#how-do-i-create-requests-in-insomnia). 