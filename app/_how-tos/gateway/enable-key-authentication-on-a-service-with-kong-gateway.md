---
title: Enable key authentication on a Gateway Service with {{site.base_gateway}}
permalink: /how-to/enable-key-authentication-on-a-service-with-kong-gateway/
content_type: how_to

description: Enable the Key Authentication plugin on a Gateway Service to require Consumers to authenticate with an API key.

related_resources:
  - text: Authentication
    url: /authentication/
breadcrumbs:
  - /gateway/authentication/
products:
    - gateway

entities:
  - service
  - consumer
  - route

plugins:
    - key-auth

tags:
  - authentication
  - key-auth

tools:
    - deck

works_on:
    - on-prem
    - konnect

prereqs:
  entities:
    services:
        - example-service
    routes:
        - example-route
tldr:
    q: How do I secure a service with key authentication?
    a: Enable the Key Authentication plugin on the Gateway Service. This plugin will require all requests made to this Service to have a valid API key.

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

## Enable the Key Authentication plugin on the Service:

Enable Key Auth for the Service.

{% entity_examples %}
entities:
  plugins:
    - name: key-auth
      service: example-service
      config:
        key_names:
        - apikey
{% endentity_examples %}

## Create a Consumer

[Consumers](/gateway/entities/consumer/) let you identify the client that's interacting with {{site.base_gateway}}.The Consumer needs an API key to access any {{site.base_gateway}} Services.

{% entity_examples %}
entities:
  consumers:
    - username: alex
      keyauth_credentials:
        - key: hello_world
{% endentity_examples %}

## Validate

After configuring the Key Authentication plugin, you can verify that it was configured correctly and is working, by sending requests with and without the API key you created for your Consumer.

This request should be successful:

<!-- vale off -->
{% validation request-check %}
url: /anything
headers:
  - 'apikey: hello_world'
status_code: 200
{% endvalidation %}
<!-- vale on -->

This request includes an invalid API key:

<!-- vale off -->
{% validation unauthorized-check %}
url: /anything
headers:
  - 'apikey: another_key'
status_code: 401
{% endvalidation %}
<!-- vale on -->
