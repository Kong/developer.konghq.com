---
title: Enable authentication with Vault in {{site.base_gateway}}
permalink: /how-to/enable-vault-authentication/
description: Use the Vault Authentication plugin to secure access to your {{site.base_gateway}} resources.
content_type: how_to
related_resources:
  - text: Authentication
    url: /gateway/authentication/

products:
    - gateway

plugins:
  - vault-auth

works_on:
  - on-prem

min_version:
  gateway: '3.4'

entities: 
  - plugin
  - service
  - route
  - consumer

tags:
    - authentication
    - hashicorp-vault

tldr:
    q: How can I use Vault to manage authentication in {{site.base_gateway}}?
    a: |
      Create a HashiCorp Vault, then use the `POST /vault-auth` API to create a Vault object with your Vault configuration. 
      Enable the Vault Authentication and associate it with the Vault object. Create a Consumer and use the `POST /vault-auth/$VAULT/credentials/$CONSUMER` API to generate credentials for the Consumer.

tools:
    - deck

prereqs:
  entities:
    services:
        - example-service
    routes:
        - example-route
  inline: 
    - title: HashiCorp Vault
      include_content: prereqs/hashicorp
      icon_url: /assets/icons/hashicorp.svg

cleanup:
  inline:
    - title: Clean up HashiCorp Vault
      include_content: cleanup/third-party/hashicorp
      icon_url: /assets/icons/hashicorp.svg
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg
---

## Create a Consumer

[Consumers](/gateway/entities/consumer/) let you identify the client that's interacting with {{site.base_gateway}}. The credentials will be generated in a later step, so we only need to specify a username.

{% entity_examples %}
entities:
  consumers:
    - username: alex
{% endentity_examples %}

## Create a Vault object

A Vault object represents the connection between {{site.base_gateway}} and a [Vault](https://www.vaultproject.io/) server. It defines the connection and authentication information used to communicate with the Vault API. This allows different instances of the `vault-auth` plugin to communicate with different Vault servers, providing a flexible deployment and consumption model.

{:.warning}
> **Important**: The Vault object used for Vault authentication is different from the [Vault entity](/gateway/entities/vault/) used for secrets management.

In this tutorial, we're using `host.docker.internal` as our host instead of the `localhost` that HashiCorp Vault is using because {{site.base_gateway}} is running in a container that has a different `localhost` to you. We'll also use the default `8200` port:

<!--vale off-->
{% control_plane_request %}
url: /vault-auth
method: POST
headers:
    - 'Accept: application/json'
body:
  name: kong-auth
  mount: secret
  protocol: http
  host: $VAULT_HOST
  port: 8200
  vault_token: root
  kv: v2
status_code: 201
extract_body:
  - name: id
    variable: DECK_VAULT_ID
{% endcontrol_plane_request %}
<!--vale on-->

Add the value of `id` in the response to your environment, we'll need it in the next step:
```sh
export DECK_VAULT_ID='YOUR_VAULT_ID_HERE'
```

## Enable the Vault Authentication plugin

Enable the [Vault Authentication](/plugins/vault-auth/) plugin, and use the ID of the Vault object to link it to the plugin:
{% entity_examples %}
entities:
  plugins:
    - name: vault-auth
      config:
        vault: 
          id: ${id}

variables:
  id:
    value: $VAULT_ID
{% endentity_examples %}

## Generate consumer credentials

Use the `POST /vault-auth/{vault}/credentials/{consumer}` endpoint to generate credentials for the Consumer we created:
<!--vale off-->
{% control_plane_request %}
url: /vault-auth/kong-auth/credentials/alex
method: POST
headers:
    - 'Accept: application/json'
status_code: 201
extract_body:
  - name: data.access_token
    variable: ACCESS_TOKEN
  - name: data.secret_token
    variable: SECRET_TOKEN
{% endcontrol_plane_request %}
<!--vale on-->

This request returns an `access_token` and `secret_token`. Add these to your environment:
```sh
export ACCESS_TOKEN='YOUR_CONSUMER_ACCESS_TOKEN'
export SECRET_TOKEN='YOUR_CONSUMER_SECRET_TOKEN'
```

## Validate

To validate that the authentication is working as expected, send a request to the Route we created in the [prerequisites](#pre-configured-entities) using the credentials we generated:
<!--vale off-->
{% validation request-check %}
url: '/anything'
status_code: 200
headers:
  - 'access_token: $ACCESS_TOKEN'
  - 'secret_token: $SECRET_TOKEN'
message: OK
{% endvalidation %}
<!--vale on-->