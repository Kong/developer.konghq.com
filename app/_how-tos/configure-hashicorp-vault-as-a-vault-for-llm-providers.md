---
title: Configure dynamic authentication to LLM providers using HashiCorp vault
description: "Use HashiCorp Vault to securely store and reference API keys for OpenAI, Mistral, and other LLM providers in Kong AI Gateway."
content_type: how_to
products:
    - gateway
    - ai-gateway

series:
  id: hashicorp-vault-llms
  position: 1

related_resources:
  - text: Secrets management
    url: /gateway/secrets-management/
  - text: Configure HashiCorp Vault as a vault backend with certificate authentication
    url: /how-to/configure-hashicorp-vault-with-cert-auth/
  - text: Store Keyring data in a HashiCorp Vault
    url: /how-to/store-keyring-in-hashicorp-vault/
  - text: Configure Hashicorp Vault with {{ site.kic_product_name }}
    url: "/kubernetes-ingress-controller/vault/hashicorp/"

works_on:
    - on-prem
    - konnect

min_version:
  gateway: '3.4'

breadcrumbs:
    - /ai-gateway/

entities:
  - vault

tags:
    - secrets-management
    - security
    - hashicorp-vault

tldr:
  q: How can I access HashiCorp Vault secrets in {{site.base_gateway}}?
  a: |
    Write secrets like `vault kv put secret/openai key="OPENAI_API_KEY"` to HashiCorp Vault. Then configure a Vault entity in {{site.base_gateway}} with the host, token, and mount path. Inside the Gateway container, run `kong vault get {vault://hashicorp-vault/openai/key}` to confirm access. Use the `{vault://...}` syntax in plugin fields to dynamically authenticate to LLM providers such as OpenAI and Mistral.

tools:
    - deck

prereqs:
  inline:
    - title: HashiCorp Vault
      include_content: prereqs/hashicorp
      icon_url: /assets/icons/hashicorp.svg
    - title: OpenAI
      include_content: prereqs/openai
      icon_url: /assets/icons/openai.svg
    - title: Mistral
      include_content: prereqs/mistral
      icon_url: /assets/icons/mistral.svg

cleanup:
  inline:
    - title: Clean up HashiCorp Vault
      include_content: cleanup/third-party/hashicorp
      icon_url: /assets/icons/hashicorp.svg
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg
---

## Create secrets in HashiCorp Vault

Write an Openai secret to HashiCorp Vault:

```
vault kv put secret/openai key="OPENAI_API_KEY"
```

Next, write a Mistal secret to HashiCorp Vault:

```
vault kv put secret/mistral key="MISTRAL_API_KEY"
```

## Create decK environment variables

We'll use decK environment variables for the `host` and `token` in the {{site.base_gateway}} Vault configuration. This is because these values typically vary between environments.

In this tutorial, we're using `host.docker.internal` as our host instead of the `localhost` variable that HashiCorp Vault is using. This is because if you used the quick-start script {{site.base_gateway}} is running in a container and uses a different `localhost`.

Because we are running HashiCorp Vault in dev mode, we are using `root` for our `token` value.

```
export DECK_HCV_HOST=host.docker.internal
export DECK_HCV_TOKEN='root'
```


## Create a Vault entity for HashiCorp Vault

Using decK, create a Vault entity in the `kong.yaml` file with the required parameters for HashiCorp Vault:

{% entity_examples %}
entities:
  vaults:
    - name: hcv
      prefix: hashicorp-vault
      description: Storing secrets in HashiCorp Vault
      config:
        host: ${hcv_host}
        token: ${hcv_token}
        kv: v2
        mount: secret
        port: 8200
        protocol: http

variables:
  hcv_host:
    value: $HCV_HOST
  hcv_token:
    value: $HCV_TOKEN
{% endentity_examples %}

## Validate

Since {{site.konnect_short_name}} data plane container names can vary, set your container name as an environment variable:
{: data-deployment-topology="konnect" }
```sh
export KONNECT_DP_CONTAINER='your-dp-container-name'
```
{: data-deployment-topology="konnect" }

To validate that the secret was stored correctly in HashiCorp Vault, you can call a secret from your vault using the `kong vault get` command within the Data Plane container.

{% validation vault-secret %}
secret: '{vault://hashicorp-vault/mistral/key}'
value: MISTRAL_API_KEY
{% endvalidation %}


{% validation vault-secret %}
secret: '{vault://hashicorp-vault/openai/key}'
value: OPENAI_API_KEY
{% endvalidation %}


If the vault was configured correctly, this command should return the value of the secrets for OpenAI and Mistral. You can use `{vault://hashicorp-vault/openai/key}` and `{vault://hashicorp-vault/mistral/key}` to reference the secret in any referenceable field.
