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
    - key-auth-enc

tags:
  - authentication
  - key-auth

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
  gateway:
    - name: KONG_KEYRING_ENABLED
    - name: KONG_KEYRING_STRATEGY
    - name: KONG_KEYRING_RECOVERY_PUBLIC_KEY
  inline: 
    - title: Enable Keyring
      position: before
      content: |
          Before configuring this plugin, you must enable {{site.base_gateway}}'s encryption [Keyring](/gateway/keyring).

          Use the `openssl` CLI to generate an RSA key pair that can be used to export and recover Keyring material:
          ```sh
          openssl genrsa -out key.pem 2048
          openssl rsa -in key.pem -pubout -out cert.pem
          ```

          To enable data encryption, you must modify the {{site.base_gateway}} configuration.

          Create the following environment variables:
          ```sh
          export KONG_KEYRING_ENABLED=on
          export KONG_KEYRING_STRATEGY=cluster
          export KONG_KEYRING_RECOVERY_PUBLIC_KEY=$(cat cert.pem | base64)
          ```
      icon_url: /assets/icons/keyring.svg

tldr:
    q: How do I secure a service with encrypted key authentication?
    a: First, [enable {{site.base_gateway}}'s encryption Keyring](/gateway/keyring/#enable-keyring). Then enable the [Key Authentication Encrypted](/plugins/key-auth-enc/) plugin on the [Gateway Service](/gateway/entities/service/). This plugin will require all requests made to this Service to have a valid API key.

cleanup:
  inline:
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg

min_version:
    gateway: '3.4'
---

## 1. Generate a Keyring key

Using the [Admin API](/api/gateway/admin-ee/#/operations/post-keyring-generate), generate a new key in the Keyring:

<!--vale off-->
{% control_plane_request %}
  url: /keyring/generate
  method: POST
  headers:
      - 'Accept: application/json'
{% endcontrol_plane_request %}
<!--vale on-->

You will get a `201 Created` response with the key and key ID. The generated key will now be used to encrypt sensitive fields in the database.

## 2. Enable the Key Authentication Encrypted plugin on the Service:

Authentication lets you identify a Consumer. In this how-to, we'll be using the [Key Auth Encrypted](/plugins/key-auth-enc/) for authentication, which allows users to authenticate with a key when they make a request.

Enable the plugin for the Service:

<!--vale off-->
{% entity_examples %}
entities:
  plugins:
    - name: key-auth-enc
      service: example-service
      config:
        key_names:
        - apikey
{% endentity_examples %}
<!--vale on-->

## 3. Create a Consumer and key

[Consumers](/gateway/entities/consumer/) let you identify the client that's interacting with {{site.base_gateway}}. First, you need to create a Consumer:

<!--vale off-->
{% entity_examples %}
entities:
  consumers:
    - username: jsmith
{% endentity_examples %}
<!--vale on-->

The Consumer needs an API key to access any {{site.base_gateway}} Services. We recommend not specifying the key as {{site.base_gateway}} will autogenerate one for you in the response. Only specify a key if you are migrating an existing system to {{site.base_gateway}}.

<!--vale off-->
{% control_plane_request %}
  url: /consumers/jsmith/key-auth-enc
  method: POST
  headers:
      - 'Accept: application/json'
{% endcontrol_plane_request %}
<!--vale on-->

Copy the key in the response and export it as an environment variable:

```bash
export CONSUMER_KEY=<consumer-key>
```

## 4. Validate

After configuring the Key Authentication Encryption plugin, you can verify that it was configured correctly and is working by sending requests with and without the API key you created for your Consumer.

First, run the following to verify that unauthorized requests return an error:

<!--vale off-->
{% validation request-check %}
url: /anything
headers:
  - 'apikey:hello_world'
{% endvalidation %}
<!--vale on-->

Then, run the following command to test Consumer authentication:

<!--vale off-->
{% validation unauthorized-check %}
url: /anything
headers:
  - 'apikey: "$CONSUMER_KEY"'
message: OK
status_code: 200
{% endvalidation %}
<!--vale on-->


