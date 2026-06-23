---
title: Authenticate Principals with basic authentication
permalink: /how-to/authenticate-principals-with-basic-authentication/
content_type: how_to
related_resources:
  - text: Authentication
    url: /gateway/authentication/

description: Use the Basic Authentication plugin to allow Principals to authenticate with a username and password.
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
  - principal

tags:
    - authentication

tldr:
  q: How do I authenticate Principals with basic authentication?
  a: |
    Create a Principal and enable the Basic Authentication plugin globally with `principals.enabled: true`. Set `principals.directory` to your directory ID, then authenticate with the base64-encoded Principal credentials.
tools:
    - deck

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

## Add basic auth credentials

Create basic auth credentials for the Principal in two steps:

Create the username `example-user`:

<!--vale off-->
{% konnect_api_request %}
url: /v2/directories/$DIRECTORY_ID/principals/$PRINCIPAL_ID/basic-auths
status_code: 201
method: POST
body:
  username: example-user
{% endkonnect_api_request %}
<!--vale on-->

Then, set the password to: `example-password`

<!--vale off-->
{% konnect_api_request %}
url: /v2/directories/$DIRECTORY_ID/principals/$PRINCIPAL_ID/basic-auths/$BASIC_AUTH_ID/passwords
status_code: 201
method: POST
body:
  secret: example-password
{% endkonnect_api_request %}
<!--vale on-->

This sets the following credentials for the Principal:

- Username: `example-user`
- Password: `example-password`

## Get the directory name

To configure the Basic Auth plugin, you'll need the name of the directory you created. Store it as `DECK_DIRECTORY-NAME` with this script:

{% include /how-tos/steps/get-directory-name.md %}

## Configure the Basic Auth plugin via decK

Enable the [Basic Authentication plugin](/plugins/basic-auth/) to allow users to authenticate with a username and password when they make a request.

{% entity_examples %}
entities:
  plugins:
  - config:
      hide_credentials: true
      principals:
        directory: ${directory_name}
        enabled: true
    enabled: true
    name: basic-auth
    protocols:
    - http
    - https
    route: example-route
variables:
  directory_name:
    value: $DIRECTORY_NAME
formats:
  - deck
{% endentity_examples %}

This configuration:

- Applies the plugin to `example-route`
- Sets the authentication method with Principals in the `example-directory` Directory

## Validate

When a Principal authenticates with basic auth, the authorization header must be base64-encoded. For example, since we are using `example-user` as the username and `example-password` as the password, then the field’s value is the base64 encoding of `example-user:example-password`, or `ZXhhbXBsZS11c2VyOmV4YW1wbGUtcGFzc3dvcmQ=`.

First, run the following to verify that unauthorized requests return an error:

<!--vale off-->
{% validation unauthorized-check %}
url: /anything
headers:
  - 'authorization: Basic wrongpassword'
{% endvalidation %}
<!--vale on-->

Then, run the following command to test Principal authentication:

{% validation request-check %}
url: '/anything'
display_headers: true
headers:
  - 'authorization: Basic ZXhhbXBsZS11c2VyOmV4YW1wbGUtcGFzc3dvcmQ='
status_code: 200
{% endvalidation %}