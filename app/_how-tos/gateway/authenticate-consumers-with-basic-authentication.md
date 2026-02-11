---
title: Authenticate Consumers with basic authentication
permalink: /how-to/authenticate-consumers-with-basic-authentication/
content_type: how_to
related_resources:
  - text: Authentication
    url: /gateway/authentication/

description: Use the Basic Authentication plugin to allow Consumers to authenticate with a username and password.
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
    q: How do I authenticate Consumers with basic authentication?
    a: Create a [Consumer](/gateway/entities/consumer/) with a username and password in the `basicauth_credentials` configuration. Enable the [Basic Authentication plugin](/plugins/basic-auth/) globally, and authenticate with the base64-encoded Consumer credentials.

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
We're going to use basic [authentication](/gateway/authentication/) in this tutorial, so the Consumer needs a username and password to access any {{site.base_gateway}} Services.

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

Authentication lets you identify a Consumer. In this how-to, we'll be using the [Basic Authentication plugin](/plugins/basic-auth/) for authentication, which allows users to authenticate with a username and password when they make a request.

Enable the plugin globally, which means it applies to all {{site.base_gateway}} Services and Routes:

{% entity_examples %}
entities:
  plugins:
    - name: basic-auth
      config:
        hide_credentials: true
{% endentity_examples %}

## Validate

When a Consumer authenticates with basic auth, the authorization header must be base64-encoded. For example, since we are using `jsmith` as the username and `my-password` as the password, then the field’s value is the base64 encoding of `jsmith:my-password`, or `anNtaXRoOm15LXBhc3N3b3Jk`.

First, run the following to verify that unauthorized requests return an error:

<!--vale off-->
{% validation unauthorized-check %}
url: /anything
headers:
  - 'authorization: Basic wrongpassword'
{% endvalidation %}
<!--vale on-->

Then, run the following command to test Consumer authentication:

{% validation request-check %}
url: '/anything'
display_headers: true
headers:
  - 'authorization: Basic anNtaXRoOm15LXBhc3N3b3Jk'
status_code: 200
{% endvalidation %}
