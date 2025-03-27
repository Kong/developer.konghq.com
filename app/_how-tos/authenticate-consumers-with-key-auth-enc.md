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

prereqs:
  entities:
    services:
        - example-service
    routes:
        - example-route
tldr:
    q: How do I secure a service with encrypted key authentication?
    a: First, [enable {{site.base_gateway}}'s encryption Keyring](/gateway/keyring/#enable-keyring). Then enable the [Key Authentication Encrypted](/plugins/key-auth-enc/) plugin on the [Gateway Service](/gateway/entities/service/). This plugin will require all requests made to this Service to have a valid API key.

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

## 1. Enable Keyring encryption

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
export KONG_KEYRING_RECOVERY_PUBLIC_KEY=/path/to/generated/cert.pem
```

Once the configuration is updated, you can start your {{site.base_gateway}} instance and use the following request to make create a new key in the Keyring:

```sh
curl -X POST localhost:8001/keyring/generate
```

This key will then be used to encrypt sensitive fields in the database.

## 2. Enable the Key Authentication Encrypted plugin on the Service:

Authentication lets you identify a Consumer. In this how-to, we'll be using the [Key Auth Encrypted](/plugins/key-auth-enc/) for authentication, which allows users to authenticate with a key when they make a request.

Enable the plugin for the Service:

{% entity_examples %}
entities:
  plugins:
    - name: key-auth
      service: example-service
      config:
        key_names:
        - apikey
{% endentity_examples %}

## 3. Create a Consumer

[Consumers](/gateway/entities/consumer/) let you identify the client that's interacting with {{site.base_gateway}}.
The Consumer needs an API key to access any {{site.base_gateway}} Services.

{% entity_examples %}
entities:
  consumers:
    - username: alex
      keyauth_credentials:
        - key: hello_world
{% endentity_examples %}

## 4. Validate

After configuring the Key Authentication Encryption plugin, you can verify that it was configured correctly and is working, by sending requests with and without the API key you created for your Consumer.

This request should be successful:

{% validation request-check %}
url: /anything
headers:
  - 'apikey:hello_world'
status_code: 200
{% endvalidation %}

Sending the wrong API key:

{% validation unauthorized-check %}
url: /anything
headers:
  - 'apikey:another_key'
{% endvalidation %}