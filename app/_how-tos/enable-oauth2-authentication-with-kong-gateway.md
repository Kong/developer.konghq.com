---
title: Enable OAuth 2.0 authentication with {{site.base_gateway}}
content_type: how_to

description: Create an OAuth 2.0 Client Credentials flow for a Gateway Service.

related_resources:
  - text: Authentication
    url: /authentication/

products:
    - gateway

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
        - example-service
    routes:
        - example-route
tldr:
    q: How do I set up OAuth 2.0 with {{site.base_gateway}}?
    a: Enable the [OAuth 2.0 Authentication](/plugins/oauth2/) plugin, then create a Consumer and an application using the `/consumers/{consumer}/oauth2` API. Send a request to the `/{route_path}/oauth/token` with the client credentials to generate a token.

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
---

## 1. Enable the OAuth 2.0 Authentication plugin

Enable the [OAuth 2.0 Authentication](/plugins/oauth2/) plugin on the Gateway Service we created in the [prerequisites](#prerequisites).

{% entity_examples %}
entities:
  plugins:
    - name: oauth2
      service: example-service
      config:
        scopes:
          - email
          - profile
        global_credentials: true
        provision_key: somekey
        enable_client_credentials: true
{% endentity_examples %}

## 2. Create a Consumer

{% include /how-tos/steps/oauth-consumer.md %}

## 3. Create an application

{% include /how-tos/steps/oauth-application.md %}

## 4. Generate a token

Use the applications's client credentials to generate a token and export it to an environment variable:
```sh
export TOKEN=$(curl -X POST "https://localhost:8443/anything/oauth2/token" \
  --header "Content-Type: application/json" \
  --json '{ 
    "client_id": "'$CLIENT_ID'", 
    "client_secret": "'$CLIENT_SECRET'", 
    "grant_type": "client_credentials" 
  }' | jq -r '.access_token')
```

## 5. Validate

To validate that the configuration works as expected, send a request to the `/anything` Route using the token we generated:
{% validation request-check %}
url: /anything
headers:
  - 'Authorization: Bearer $TOKEN'
status_code: 200
{% endvalidation %}
