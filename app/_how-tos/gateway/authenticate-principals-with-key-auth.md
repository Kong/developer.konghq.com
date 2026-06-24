---
title: Authenticate Principals with the Key Authentication plugin
permalink: /how-to/authenticate-principals-with-key-auth/
content_type: how_to
breadcrumbs:
  - /identity/
related_resources:
  - text: Authentication
    url: /gateway/authentication/

description: Use the Key Authentication plugin to allow Principals to authenticate with an API key.
products:
    - gateway
    - identity

plugins:
  - key-auth
works_on:
    - on-prem
    - konnect

min_version:
  gateway: '3.15'
entities: 
  - plugin
  - service
  - route
  - principal

tags:
    - authentication

tools:
    - deck

tldr:
  q: How do I authenticate Principals with key authentication?
  a: |
    Create a principal, create an API key for it, then enable the Key Authentication plugin with `principals.enabled: true` and set `principals.directory` to your directory name. Authenticate by sending the API key in the `apikey` header.

prereqs:
  entities:
    services:
        - example-service
    routes:
        - example-route
  inline:
    - title: Kong Identity directory
      include_content: prereqs/kong-identity-directory
      icon_url: /assets/icons/identity.svg

cleanup:
  inline:
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg
---

## Create a Principal

{% include /how-tos/steps/principal.md %}

## Add key auth

Add an API key credential to the principal so clients can authenticate with {{site.base_gateway}} using key auth. 

The following example:
- Sets a system-generated key (`v1`)
- Stores the key secret as `$KEY_SECRET`

<!--vale off-->
{% konnect_api_request %}
url: /v2/directories/$DIRECTORY_ID/principals/$PRINCIPAL_ID/api-keys
status_code: 201
method: POST
body:
  type: v1
capture:
  - variable: KEY_SECRET
    jq: ".secret"
{% endkonnect_api_request %}
<!--vale on-->

## Get the directory name
To configure the Key Auth plugin, you'll need the name of the directory you created. Store it as `DECK_DIRECTORY_NAME` with this script:
{% include /how-tos/steps/get-directory-name.md %}

## Configure the Key Auth plugin via decK

Enable the [Key Auth](/plugins/key-auth/) plugin to allow clients to authenticate with a key when they make a request:

{% entity_examples %}
entities:
  plugins:
  - name: key-auth
    route: example-route
    config:
      identity_realms: []
      principals:
        enabled: true
        directory: ${directory_name}
variables:
  directory_name:
    value: $DIRECTORY_NAME
format:
  - deck
{% endentity_examples %}

This configuration:

- Enables the plugin on `example-route`.
- Sets principal authentication by looking up API keys in the `kong-identity-directory` directory.

## Validate

By default, the Key Auth plugin reads the key from the `apikey` header.

First, run the following to verify that requests without a valid key are rejected:

<!--vale off-->
{% validation unauthorized-check %}
url: /anything
{% endvalidation %}
<!--vale on-->

Then, run the following command to test principal authentication using the API key stored in `$KEY_SECRET`:

{% validation request-check %}
url: '/anything'
display_headers: true
headers:
  - 'apikey: $KEY_SECRET'
status_code: 200
{% endvalidation %}