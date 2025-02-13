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
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg
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

Set the variables needed to start {{site.base_gateway}} with Keyring enabled:
```sh
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

In this example, the `config` column for the AI Proxy contains the following data, where the value `Bearer my-openai-token` is encoded:
```json
{
   "auth":{
      "param_name":null,
      "header_name":"Authorization",
      "param_value":null,
      "header_value":"$ke$1$-jFoDw5l9-2ed38633f83b49482c39477d-2c4e73a404092e3b2874ecb7eb88f2fb89728816261b",
      "allow_override":false,
      "param_location":null,
      "azure_client_id":null,
      "azure_tenant_id":null,
      "aws_access_key_id":null,
      "azure_client_secret":null,
      "aws_secret_access_key":null,
      "gcp_use_service_account":false,
      "gcp_service_account_json":null,
      "azure_use_managed_identity":false
   },
   "model":{
      "name":"gpt-4",
      "options":{
         "top_k":null,
         "top_p":null,
         "gemini":null,
         "bedrock":null,
         "input_cost":null,
         "max_tokens":512,
         "huggingface":null,
         "output_cost":null,
         "temperature":1,
         "upstream_url":null,
         "llama2_format":null,
         "upstream_path":null,
         "azure_instance":null,
         "mistral_format":null,
         "anthropic_version":null,
         "azure_api_version":"2023-05-15",
         "azure_deployment_id":null
      },
      "provider":"openai"
   },
   "logging":{
      "log_payloads":false,
      "log_statistics":false
   },
   "route_type":"llm/v1/chat",
   "model_name_header":true,
   "response_streaming":"allow",
   "max_request_body_size":8192
}
```
{: .no-copy-code }