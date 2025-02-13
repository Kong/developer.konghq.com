---
title: Encrypt sensitive data in {{site.base_gateway}} with a Keyring
content_type: how_to
related_resources:
  - text: Keyring
    url: /gateway/keyring/

tools:
  - deck

products:
    - gateway

works_on:
    - on-prem

tier: enterprise

tldr:
    q: How do I configure a Keyring to encrypt data?
    a: |
        Generate an RSA key pair, then set the following parameters, either as environment variables or in `kong.conf`:
        ```
        keyring_enabled = on
        keyring_strategy = cluster
        keyring_recovery_public_key = /path/to/public.pem
        ```

prereqs:
  skip_product: true

cleanup:
  inline:
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg

min_version:
    gateway: '3.4'
---

## 1. Generate an RSA key pair

These keys are needed for [disaster recovery](/gateway/keyring/#disaster-recovery). You can generate them using OpenSSL:
```sh
openssl genrsa -out private.pem 2048
openssl rsa -in private.pem -pubout -out public.pem
```

## 2. Set environment variables

Set the variables needed to start {{site.base_gateway}} with Keyring enabled. Since the Keyring feature requires a {{site.ee_product_name}} license, make sure to include it in the environment too.
```sh
export KONG_LICENSE_DATA="<license-contents-go-here>"
export KONG_KEYRING_ENABLED=on
export KONG_KEYRING_STRATEGY=cluster
export KONG_KEYRING_RECOVERY_PUBLIC_KEY=$(cat public.pem | base64)
```

{:.info}
> **Note:** `KONG_KEYRING_RECOVERY_PUBLIC_KEY` can be:
* The absolute path to the generated public key file
* The public key content
* The base64-encoded public key content

## 3. Start {{site.base_gateway}}

Create the {{site.base_gateway}} container with the environment variables. In this example, we can use the quickstart:
```sh
curl -Ls https://get.konghq.com/quickstart | bash -s -- -e KONG_LICENSE_DATA \
    -e KONG_KEYRING_ENABLED \
    -e KONG_KEYRING_STRATEGY \
    -e KONG_KEYRING_RECOVERY_PUBLIC_KEY
```

## 4. Generate a key

Using the Admin API, generate a new key in the Keyring:
{% control_plane_request %}
  url: /keyring/generate
  method: POST
  headers:
      - 'Accept: application/json'
{% endcontrol_plane_request %}

You will get a `201 Created` response with the key and key ID. The generated key will now be used to encrypt sensitive fields in the database.

## 5. Validate

### Create a plugin

To validate that it’s working, you can create a plugin with data in an encrypted field, and then check the database to make sure the data is encrypted. 

For example, the `config.auth.header_value` parameter in AI Proxy is encrypted:
{% entity_examples %}
entities:
  plugins:
    - name: ai-proxy
      config:
        route_type: llm/v1/chat
        auth:
          header_name: Authorization
          header_value: Bearer my-openai-token
        model:
          provider: openai
          name: gpt-4
          options:
            max_tokens: 512
            temperature: 1.0
{% endentity_examples %}

When you create this plugin while Keyring is enabled, the value of `config.auth.header_value` will be encrypted in the database. You can check the `plugins` table in the Kong database to make sure it's encrypted.

### Query the database

1. Open an interactive shell in the database container:
```sh
docker exec -it kong-quickstart-database sh
```

1. Connect to the database. With the quickstart, you only need to specify the username `kong`:
```sh
psql -U kong
```

1. Query the `plugins` table. With this query, we'll look for the value of `config.auth.header_value` for the `ai-proxy` plugin:
```sql
SELECT "config" -> 'auth' -> 'header_value' FROM public.plugins WHERE "name" = 'ai-proxy';
```

The value returned should be encrypted.