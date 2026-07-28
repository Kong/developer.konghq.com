---
title: "{{site.konnect_short_name}} Config Store vault"
layout: reference
content_type: reference
description: "Store and reference secrets natively in {{site.konnect_short_name}} without connecting to a third-party vault backend."
breadcrumbs:
  - /gateway/
  - /gateway/entities/
  - /gateway/entities/vault/

permalink: /gateway/entities/vault/konnect-config-store/

works_on:
  - konnect

products:
  - gateway

tools:
  - konnect-api
  - deck
  - kic
  - terraform

tags:
  - secrets-management
  - konnect-config-store

min_version:
  gateway: '3.4'

related_resources:
  - text: "{{site.base_gateway}} Vault entity"
    url: /gateway/entities/vault/
  - text: "Supported {{site.base_gateway}} Vault backends"
    url: /gateway/entities/vault/#supported-vault-backends
  - text: Secrets management
    url: /gateway/secrets-management/

how_to_list:
  config:
    products:
      - gateway
    tags:
      - konnect-config-store
    description: true
    view_more: false
---

The {{site.konnect_short_name}} Config Store vault lets you store and reference secrets directly in {{site.konnect_short_name}}, without connecting to a third-party vault backend.
You can manage secrets using the [Control Planes Configuration API](/api/konnect/control-planes-config/) or the {{site.konnect_short_name}} UI.

Because {{site.konnect_short_name}} resolves these secrets after {{site.base_gateway}} connects to the control plane, you can only configure the {{site.konnect_short_name}} Config Store vault using a Vault entity.
It doesn't support `kong.conf` parameters or environment variables, and you can't use it to resolve secrets referenced in `kong.conf`.

{:.warning}
> **Warning:** The {{site.konnect_short_name}} Config Store stores secrets at the control plane level, and secret references are resolved before sending the configuration to the data planes.
> Because of this behavior, you can't use {{site.konnect_short_name}} Config Store secrets directly in Lua code via the Kong PDK.

## Create a {{site.konnect_short_name}} Config Store vault

Before creating the Vault entity, create a Config Store by sending a `POST` request to the `/config-stores` endpoint:

<!--vale off-->
{% konnect_api_request %}
url: /v2/control-planes/$CONTROL_PLANE_ID/config-stores
status_code: 201
method: POST
body:
    name: my-config-store
{% endkonnect_api_request %}
<!--vale on-->

Export the Config Store ID from the response:

```bash
export DECK_CONFIG_STORE_ID='CONFIG STORE ID'
```

Then create the `konnect` Vault entity:

{% entity_example %}
type: vault
data:
  name: konnect
  prefix: mysecretvault
  description: Storing secrets in Konnect
  config:
    config_store_id: ${config-store-id}

variables:
  config-store-id:
    value: $CONFIG_STORE_ID
{% endentity_example %}

## Vault configuration options

The following table lists the available configuration parameters for a {{site.konnect_short_name}} Config Store Vault:

<!--vale off-->
{% table %}
columns:
  - title: Field name
    key: field
  - title: Parameter format
    key: parameter
  - title: Description
    key: description
rows:
  - field: Config Store ID
    parameter: |
      * **Vault entity:** `vaults.config.config_store_id`
    description: |
      The ID of the {{site.konnect_short_name}} Config Store to use for this Vault. Create a Config Store by sending a `POST` request to the [`/config-stores` endpoint](/api/konnect/control-planes-config/#/operations/create-config-store), or by creating a Vault through the {{site.konnect_short_name}} UI, which creates the Config Store for you.
{% endtable %}
<!--vale on-->

## Tutorials

{% how_to_list page.how_to_list.config %}