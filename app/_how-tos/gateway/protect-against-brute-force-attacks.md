---
title: Protect against brute force attacks with basic authentication
permalink: /how-to/protect-against-brute-force-attacks/
content_type: how_to
related_resources:
  - text: Authentication
    url: /gateway/authentication/

description: Use the Basic Authentication plugin to protect against brute force attacks.
products:
    - gateway

plugins:
  - basic-auth

works_on:
    - on-prem
    - konnect

min_version:
  gateway: '3.13'

entities: 
  - plugin
  - service
  - route
  - consumer

tags:
    - authentication

tldr:
    q: How do I protect against brute force attacks with basic authentication?
    a: Enable the [Basic Authentication plugin](/plugins/basic-auth/) globally with `brute_force_protection`, and attempt to authenticate with the wrong base64-encoded Consumer credentials four times. This will return an `429 Too Many Requests` error after the fourth failed login attempt.

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
We're going to use [basic authentication](/plugins/basic-auth/) in this tutorial, so the Consumer needs a username and password to access any {{site.base_gateway}} Services.

Create a Consumer:

{% entity_examples %}
entities:
  consumers:
    - username: jsmith
      basicauth_credentials:
       - username: jsmith
         password: my-password
{% endentity_examples %}

## Enable authentication

Use the [Basic Authentication plugin](/plugins/basic-auth/) to identify Consumers with username-and-password credentials, including optional brute-force protection.

Enable the plugin globally, across all {{site.base_gateway}} Services and Routes:

{% entity_examples %}
entities:
  plugins:
    - name: basic-auth
      config:
        brute_force_protection:
          strategy: memory
{% endentity_examples %}

## Validate

When a Consumer authenticates with basic auth, the authorization header must be base64-encoded. For example, since we are using `jsmith` as the username and `my-password` as the password, then the field’s value is the base64 encoding of `jsmith:my-password`, or `anNtaXRoOm15LXBhc3N3b3Jk`.

Run the following four times to verify that unauthorized requests return a `429` error after the third attempt:

<!--vale off-->
{% validation unauthorized-check %}
url: /anything
headers:
  - 'authorization: Basic dGVzdDp3cm9uZ3Bhc3N3b3Jk'
{% endvalidation %}
<!--vale on-->
