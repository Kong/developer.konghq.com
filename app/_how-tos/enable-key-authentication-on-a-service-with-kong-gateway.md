---
title: Enable key authentication on a Gateway Service with {{site.base_gateway}}
content_type: how_to

related_resources:
  - text: Authentication
    url: /authentication/
  - text: Key Auth plugin
    url: /plugins/key-auth/

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

## 1. Enable the Key Authentication plugin on the Service:

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

## 2. Create a Consumer

[Consumers](/gateway/entities/consumer/) let you identify the client that's interacting with {{site.base_gateway}}.
The Consumer needs an API key to access any {{site.base_gateway}} Services.

{% entity_examples %}
entities:
  consumers:
    - username: alex
      keyauth_credentials:
        - key: hello_world
{% endentity_examples %}

## 3. Apply the configuration

{% include how-tos/steps/apply_config.md %}

## 4. Validate

After configuring the Key Authentication plugin, you can verify that it was configured correctly and is working, by sending requests with and without the API key you created for your Consumer.

{% validation request %}
preamble: "This request should be successful:"
url: /anything
headers:
  - 'apikey:hello_world'
status_code: 200
{% endvalidation %}

{% validation auth-check %}
preamble: "This request should return a `401` error with the message `Unauthorized`:"
url: /anything
headers:
  - 'apikey:another_key'
{% endvalidation %}
