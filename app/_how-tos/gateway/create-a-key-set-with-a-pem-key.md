---
title: Create a Key Set with a PEM Key
permalink: /how-to/create-a-key-set-with-a-pem-key/
content_type: how_to

description: Create a PEM Key and add it to a Key Set using the /key-sets API endpoint.

entities: 
  - key
  - key-set

tags:
  - security

related_resources:
  - text: Key entity
    url: /gateway/entities/key/
  - text: Key Set entity
    url: /gateway/entities/key-set/
  - text: Create a Key Set with a JWK
    url: /how-to/create-a-key-set-with-a-jwk/
  - text: "Securing {{site.base_gateway}}"
    url: /gateway/security/

products:
    - gateway

works_on:
    - on-prem
    - konnect

min_version:
  gateway: '3.4'

tldr:
  q: How do I create a PEM key and add it to a Key Set?
  a: Create a Key Set with the `/key-sets` endpoint, then create a Key and configure the `set.id` or `set.name` parameter to point to the Key Set. 

prereqs:
  inline:
    - title: PEM key pair
      content: |
        This tutorial requires a public key and private key. You can generate them using OpenSSL:
        ```sh
        openssl genrsa -out private.pem 2048
        openssl rsa -in private.pem -outform PEM -pubout -out public.pem
        ```
      icon_url: /assets/icons/key.svg

cleanup:
  inline:
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg

automated_tests: false
---

## Create a Key Set
Using the Admin API, create a Key Set to hold PEM keys:

{% control_plane_request %}
url: /key-sets
method: POST
headers:
    - 'Accept: application/json'
    - 'Content-Type: application/json'
body:
    name: my-pem-key-set
status_code: 201
{% endcontrol_plane_request %}

You will get a `201 Created` response with details about the new Key Set.

## Create a Key

Create a Key and use either the `set.id` from the response in the previous step, or the `set.name` parameter to add it to the Key Set.
To avoid errors, the private and public keys should be strings, and newlines should replaced with `\n`:

{% control_plane_request %}
url: /keys
method: POST
headers:
    - 'Accept: application/json'
    - 'Content-Type: application/json'
    - 'Kong-Admin-Token: $KONG_ADMIN_TOKEN'
body:
    name: my-pem-key
    kid: my-pem-key
    set:
      name: my-pem-key-set
    pem:
      private_key: "-----BEGIN PRIVATE KEY-----\nprivate-key-content\n-----END PRIVATE KEY-----"
      public_key: "-----BEGIN PUBLIC KEY-----\npublic-key-content\n-----END PUBLIC KEY-----"
status_code: 201
{% endcontrol_plane_request %}

You will get a `201 Created` response with details about the new Key, including the Key Set ID.