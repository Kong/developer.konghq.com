---
title: Configure Hashicorp Vault
description: "Configure Hashicorp Vault with {{ site.kic_product_name }} and the KongVault CRD"
content_type: how_to

permalink: /kubernetes-ingress-controller/vault/hashicorp/
breadcrumbs:
  - /kubernetes-ingress-controller/
  - /gateway/secrets-management/

min_version:
  kic: '3.1'

products:
  - kic

tools:
  - kic

works_on:
  - on-prem
  - konnect

entities: []

tldr:
  q: How do I configure Hashicorp Vault with {{ site.kic_product_name }}?
  a: Create a `KongVault` CRD and then use the `vault://` reference in your plugin configuration

prereqs:
  enterprise: true
  kubernetes:
    skip_proxy_ip: true
  inline: 
    - title: HashiCorp Vault
      include_content: prereqs/hashicorp-vault-k8s
      icon_url: /assets/icons/hashicorp.svg

cleanup:
  inline:
    - title: Uninstall KIC from your cluster
      include_content: cleanup/products/kic
      icon_url: /assets/icons/kubernetes.svg
    - title: Uninstall HashiCorp Vault from your cluster
      content: |
        ```bash
        kubectl delete namespace vault
        ```
      icon_url: /assets/icons/hashicorp.svg

next_steps:
  - text: Review the Vaults entity
    url: /gateway/entities/vault/
  - text: What can be stored as a secret?
    url: /gateway/entities/vault/#what-can-be-stored-as-a-secret   

related_resources:
  - text: Secrets management
    url: /gateway/secrets-management/

tags:
  - secrets-management
  - security

---

## Create a KongVault entity

{{ site.kic_product_name }} uses the `KongVault` entity to configure the connection to a Vault. As we're running Hashicorp Vault in `dev` mode, we can use the `root` token to access the Vault:

{% entity_example %}
type: vault
data:
  name: hcv
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
    value: vault.vault.svc.cluster.local
  hcv_token:
    value: root
{% endentity_example %}

We can now access secrets in this vault using the `vault://hashicorp-vault/$KEY` syntax. The `hashicorp-vault` prefix matches the `prefix` field in the `KongVault` resource.

## Validate your configuration

To validate that the secret was stored correctly in HashiCorp Vault, you can call a secret from your vault using the `kong vault get` command within the Data Plane Pod. 

{% validation vault-secret %}
secret: '{vault://hashicorp-vault/customer/acme/name}'
value: 'ACME Inc.'
command: kubectl exec -n kong -it deployment/kong-gateway -c proxy -- 
{% endvalidation %}

If the vault was configured correctly, this command should return the value of the secret. You can use `{vault://hashicorp-vault/customer/acme/name}` to reference the secret in any referenceable field.

For more information about supported secret types, see [What can be stored as a secret](/gateway/entities/vault/#what-can-be-stored-as-a-secret). 