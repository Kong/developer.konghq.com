---
title: Create a centrally-managed Consumer in {{site.konnect_short_name}}

description: Learn how to create a realm and authenticate a centrally-managed Consumer with key authentication.

content_type: how_to
related_resources:
  - text: Authentication
    url: /gateway/authentication/

products:
    - gateway

works_on:
    - konnect

tools:
  - deck

min_version:
  gateway: '3.10'

entities: 
  - consumer
  - plugin

tags:
    - consumer

tldr:
    q: How do I centrally manage Consumers in {{site.konnect_short_name}}?
    a: Centrally-managed Consumers exist outside of a Control Plane. To create one, you must first create a realm using the {{site.konnect_short_name}} API as well as a Consumer associated with the realm. Then, create a key for the centrally-managed Consumer that they can use for authentication. Enable the Key Authentication plugin, configuring `identity_realms`. Centrally-managed Consumers can then authenticate via key auth with their key.

prereqs:
  entities:
    services:
        - example-service
    routes:
        - example-route

cleanup:
  inline:
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg
---

## 1. Create a realm

First, export your Control Plane UUID so we can use it in the request. You can find this under your Control Plane settings in [Gateway Manager](https://cloud.konghq.com/gateway-manager/):
```sh
export KONNECT_CONTROL_PLANE_ID=<control-plane-uuid>
```

Centrally-managed Consumers are assigned to realms instead of Control Planes. Realms exist outside of the Control Plane.

Use the [`/realms` endpoint](/api/konnect/consumers/v1/#/operations/create-realm) to create a realm and associate it with allowed Control Planes:

<!--vale off-->
{% control_plane_request %}
url: /v1/realms
status_code: 201
method: POST
headers:
    - 'Accept: application/json'
    - 'Content-Type: application/json'
    - 'Authorization: Bearer $DECK_KONNECT_TOKEN'
body:
    name: prod
    allowed_control_planes: [$KONNECT_CONTROL_PLANE_ID]
{% endcontrol_plane_request %}
<!--vale on-->

Export the ID of the realm from the response:
```sh
export DECK_REALM_ID=<realm-id>
```


## 2. Create the centrally-managed Consumer

Use the [create a Consumer](/api/konnect/consumers/v1/#/operations/create-consumer) endpoint to create a centrally-managed Consumer:

<!--vale off-->
{% control_plane_request %}
url: /v1/realms/$DECK_REALM_ID/consumers
status_code: 201
method: POST
headers:
    - 'Accept: application/json'
    - 'Content-Type: application/json'
    - 'Authorization: Bearer $DECK_KONNECT_TOKEN'
body:
    username: Ariel
{% endcontrol_plane_request %}
<!--vale on-->


Export the ID of the Consumer from the response:
```sh
export CONSUMER_ID=<consumer-id>
```

## 3. Create a Consumer key for authentication

Centrally-managed Consumers require a key for authentication. Configure authentication keys for Consumers using the [create a key](/api/konnect/consumers/v1/#/operations/create-consumer-key) endpoint:

<!--vale off-->
{% control_plane_request %}
url: /v1/realms/$DECK_REALM_ID/consumers/$CONSUMER_ID/keys
status_code: 201
method: POST
headers:
    - 'Accept: application/json'
    - 'Content-Type: application/json'
    - 'Authorization: Bearer $DECK_KONNECT_TOKEN'
body:
    type: new
{% endcontrol_plane_request %}
<!--vale on-->  

Export the Consumer key from the `secret` field in the response:
```sh
export CONSUMER_KEY=<consumer-key>
```

## 4. Enable authentication with the Key Authentication plugin

Consumers require authentication. Currently, you can only use the [Key Auth plugin](/plugins/key-auth/) to authenticate centrally-managed Consumers. In this example, we'll configure `identity_realms` on first the realm and then the Control Plane. By doing it this way, the Data Plane will first reach out to the realm. If the API key is not found in the realm, the Data Plane will look for the API key in the Control Plane config.

Enable the Key Auth plugin on the `example-service`:

{% entity_examples %}
entities:
  plugins:
    - name: key-auth
      service: example-service
      config:
        key_names:
        - apikey
        identity_realms:
        - id: ${realm_id}
          scope: realm
        - id: null
          scope: cp

variables:
  realm_id:
    value: $REALM_ID
{% endentity_examples %}

`identity_realms` are scoped to the Control Plane by default (`scope: cp`). The order in which you configure the `identity_realms` dictates the priority in which the data plane attempts to authenticate the provided API keys:

* **Realm is listed first:** The data plane will first reach out to the realm. If the API key is not found in the realm, the data plane will look for the API key in the control plane config. 
* **Control plane scope listed first:** The data plane will initially check the control plane configuration (LMDB) for the API key before looking up the API Key in the realm.
* **Realm only:** You can also configure a single `identity_realms` by omitting the `scope: cp` from the example. In this case, the data plane will only attempt to authenticate API keys against the realm. If the API key isn't found, the request will be blocked.
* **Control plane only:** You can configure a look up only in the control plane config by only specifying `scope: cp` for `identity_realms`. In this scenario, the data plane will only check the control plane configuration (LMDB) for API key authentication. If the API key isn't found, the request will be blocked.

## 5. Validate

After configuring the Key Authentication plugin, you can verify that it was configured correctly and is working, by sending requests with and without the API key you created for your centrally-managed Consumer.

This request should be successful:

{% validation request-check %}
url: /anything
headers:
  - 'apikey:$CONSUMER_KEY'
status_code: 200
{% endvalidation %}

Sending the wrong API key:

{% validation unauthorized-check %}
url: /anything
headers:
  - 'apikey:another_key'
{% endvalidation %}



