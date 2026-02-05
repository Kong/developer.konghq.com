---
title: Configure the {{site.konnect_short_name}} Config Store vault
permalink: /how-to/configure-the-konnect-config-store/
description: Learn how to use the {{site.konnect_short_name}} Config Store vault.
content_type: how_to
related_resources:
  - text: Secrets management
    url: /gateway/secrets-management/
  - text: Vault entity
    url: /gateway/entities/vault/
  - text: Store a Mistral API key as a secret in Konnect Config Store
    url: /how-to/store-a-mistral-api-key-as-a-secret-in-konnect-config-store/

products:
    - gateway

works_on:
    - konnect

entities: 
  - vault

tags:
    - security
    - secrets-management

tldr:
    q: How do I use a {{site.konnect_short_name}}-native Vault?
    a: |
      1. Use the {{site.konnect_short_name}} API to create a Config Store using the `/config-stores` endpoint.
      2. Create a {{site.konnect_short_name}} Vault using the [`/vaults/` endpoint](/api/konnect/control-planes-config/#/operations/create-vault) or UI.
      3. Store your secret as a key/value pair using the `/secrets` endpoint or the UI. 
      4. Reference the secret using the Vault prefix and key (for example: `{vault://mysecretvault/secret-key}`). 

faqs:
  - q: Can I reference {{site.konnect_short_name}} Config Store Vault secrets in `kong.conf`?
    a: No. You can't reference secrets stored in a {{site.konnect_short_name}} Config Store Vault in `kong.conf` because {{site.konnect_short_name}} resolves the secret after {{site.base_gateway}} connects to the control plane. For more information about the fields you can reference as secrets, see [What can be stored as a secret?](/gateway/entities/vault/#what-can-be-stored-as-a-secret).

prereqs:
  inline:
    - title: Konnect API
      include_content: prereqs/konnect-api-for-curl

tools:
  - deck
  # - konnect-api
 
cleanup:
  inline:
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg

min_version:
    gateway: '3.4'

next_steps:
  - text: Review the Vaults entity
    url: /gateway/entities/vault/
  - text: What can be stored as a secret?
    url: /gateway/entities/vault/#what-can-be-stored-as-a-secret  
---

## Configure a {{site.konnect_short_name}} Config Store

Before you can configure a {{site.konnect_short_name}} Vault, you must first create a Config Store using the [Control Planes Configuration API](/api/konnect/control-planes-config/) by sending a `POST` request to the `/config-stores` endpoint:

<!--vale off-->
{% konnect_api_request %}
url: /v2/control-planes/$CONTROL_PLANE_ID/config-stores
status_code: 201
method: POST
body:
    name: my-config-store
{% endkonnect_api_request %}
<!--vale on-->

Export the Config Store ID in the response body as an environment variable so you can use it later:

```sh
export DECK_CONFIG_STORE_ID='CONFIG STORE ID'
```

{:.info}
> **Note:** If you're configuring the {{site.konnect_short_name}} Vault via the {{site.konnect_short_name}} UI, you can skip this step as the UI creates the Config Store for you.

## Configure {{site.konnect_short_name}} as your Vault

Enable {{site.konnect_short_name}} as your vault with the [Vault entity](/gateway/entities/vault/):

{% navtabs "config-store-vault" %}
{% navtab "decK" %}
{% entity_examples %}
entities:
  vaults:
  - name: konnect
    prefix: mysecretvault
    description: Storing secrets in Konnect
    config:
      config_store_id: ${config-store-id}

variables:
  config-store-id:
    value: $CONFIG_STORE_ID
{% endentity_examples %}
{% endnavtab %}
{% navtab "{{site.konnect_short_name}} UI" %}
1. In {{site.konnect_short_name}}, navigate to [**API Gateway**](https://cloud.konghq.com/gateway-manager/) in the {{site.konnect_short_name}} sidebar.
1. Click your control plane.
1. Navigate to **Vaults** in the sidebar.
1. Click **New vault**.
1. In the **Vault Configuration** dropdown, select "Konnect".
1. Enter `mysecretvault` in the **Prefix** field.
1. Enter `Storing secrets in {{site.konnect_short_name}}` in the **Description** field.
1. Click **Save**. 
{% endnavtab %}
{% endnavtabs %}


## Store a secret in your {{site.konnect_short_name}} Vault

By storing a secret in a {{site.konnect_short_name}} Vault, you can reference it within [`kong.conf`](/gateway/manage-kong-conf/) or as a referenceable plugin fields without having to store any values in plain-text.

{% navtabs "config-store-secret" %}
{% navtab "{{site.konnect_short_name}} API" %}
Store your secret by sending a `POST` request to the `/secrets` endpoint:

<!--vale off-->
{% konnect_api_request %}
url: /v2/control-planes/$CONTROL_PLANE_ID/config-stores/$DECK_CONFIG_STORE_ID/secrets/
status_code: 201
method: POST
body:
    key: secret-key
    value: my-secret-value
{% endkonnect_api_request %}
<!--vale on-->
{% endnavtab %}
{% navtab "{{site.konnect_short_name}} UI" %}
1. Navigate to the {{site.konnect_short_name}} Vault you just created.
1. Click **Store New Secret**.
1. Enter `secret-key` in the **Key** field.
1. Enter `my-secret-value` in the **Value** field.
1. Click **Save**.
{% endnavtab %}
{% endnavtabs %}

## Validate

You can validate that your secret was stored correctly by sending a `GET` request to the `/secrets` endpoint:

<!--vale off-->
{% konnect_api_request %}
url: /v2/control-planes/$CONTROL_PLANE_ID/config-stores/$DECK_CONFIG_STORE_ID/secrets/
status_code: 201
method: GET
{% endkonnect_api_request %}
<!--vale on-->

{:.info}
> **Note:** If you configured your Vault and secret using the UI, you can find your Config Store ID by sending a GET request to the [`/control-planes/{controlPlaneId}/config-stores` endpoint](/api/konnect/control-planes-config/v2/#/operations/list-config-stores).

If your secret was successfully stored in {{site.konnect_short_name}}, the endpoint should return a `201` status code and your `secret-key` key in the output.

You can now reference your {{site.konnect_short_name}} secret in configurations as `{vault://mysecretvault/secret-key}`. For more information about supported secret types, see [What can be stored as a secret](/gateway/entities/vault/#what-can-be-stored-as-a-secret). 