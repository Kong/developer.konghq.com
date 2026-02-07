---
title: Create a centrally-managed Consumer in {{site.konnect_short_name}}
permalink: /how-to/create-centrally-managed-consumer/

description: Learn how to create a realm and authenticate a centrally-managed Consumer with key authentication.

content_type: how_to
related_resources:
  - text: About centrally-managed Consumers
    url: /gateway/entities/consumer/#centrally-managed-consumers
  - text: Authentication
    url: /gateway/authentication/

products:
    - gateway

works_on:
    - konnect

tools:
  # - konnect-api
  - deck

min_version:
  gateway: '3.10'

entities: 
  - consumer
  - plugin

tags:
    - consumer
    - authentication

tldr:
    q: How do I centrally manage Consumers in {{site.konnect_short_name}}?
    a: Centrally-managed Consumers exist outside of a control plane. To create one, you must first create a realm using the {{site.konnect_short_name}} API as well as a Consumer associated with the realm. Then, create a key for the centrally-managed Consumer that they can use for authentication. Enable the Key Authentication plugin, configuring `identity_realms`. Centrally-managed Consumers can then authenticate via key auth with their key.
faqs:
  - q: When should I use centrally-managed Consumers instead of Consumers scoped to control planes?
    a: |
      You should use centrally-managed Consumers in the following scenarios:
      * You want to share the Consumer identity in more than one control plane
      * The Consumer uses the key authentication strategy
      * You don't need to scope plugins to Consumers directly, they can be scoped to Consumer Groups instead.

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

## Create a realm

First, export your control plane ID and [region](/konnect-platform/geos/) (for example, `us`) so we can use it in the request. You can find these under your [control plane settings](https://cloud.konghq.com/gateway-manager/):
```sh
export KONNECT_CONTROL_PLANE_ID={control-plane-id}
export DECK_CONTROL_PLANE_REGION={region}
```

Centrally-managed Consumers are assigned to realms instead of control planes. Realms exist outside of the control plane.

Use the [`/realms` endpoint](/api/konnect/consumers/#/operations/create-realm) to create a realm and associate it with allowed control planes:

<!--vale off-->
{% konnect_api_request %}
url: /v1/realms
status_code: 201
method: POST
body:
    name: prod
    allowed_control_planes: [$KONNECT_CONTROL_PLANE_ID]
{% endkonnect_api_request %}
<!--vale on-->

Export the ID of the realm from the response:
```sh
export DECK_REALM_ID={realm-id}
```


## Create the centrally-managed Consumer

Use the [create a Consumer](/api/konnect/consumers/#/operations/create-consumer) endpoint to create a centrally-managed Consumer:

<!--vale off-->
{% konnect_api_request %}
url: /v1/realms/$DECK_REALM_ID/consumers
status_code: 201
method: POST
body:
    username: Ariel
{% endkonnect_api_request %}
<!--vale on-->


Export the ID of the Consumer from the response:
```sh
export CONSUMER_ID={consumer-id}
```

## Create a Consumer key for authentication

Centrally-managed Consumers require a key for authentication. Configure authentication keys for Consumers using the [create a key](/api/konnect/consumers/#/operations/create-consumer-key) endpoint:

<!--vale off-->
{% konnect_api_request %}
url: /v1/realms/$DECK_REALM_ID/consumers/$CONSUMER_ID/keys
status_code: 201
method: POST
body:
    type: new
{% endkonnect_api_request %}
<!--vale on-->  

Export the Consumer key from the `secret` field in the response:
```sh
export CONSUMER_KEY={consumer-key}
```

## Enable authentication with the Key Authentication plugin

Consumers require authentication. Currently, you can only use the [Key Auth plugin](/plugins/key-auth/) to authenticate centrally-managed Consumers. In this example, we'll configure `identity_realms` on first the realm and then the control plane. By doing it this way, the data plane will first reach out to the realm. If the API key is not found in the realm, the data plane will look for the API key in the control plane config.

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
          region: ${region}
        - id: null
          scope: cp

variables:
  realm_id:
    value: $REALM_ID
  region:
    value: $CONTROL_PLANE_REGION
{% endentity_examples %}

`identity_realms` are scoped to the control plane by default (`scope: cp`). The order in which you configure the `identity_realms` dictates the priority in which the data plane attempts to authenticate the provided API keys. See [identity realms precedence](/plugins/key-auth/#identity-realms) for more information.

## Validate

After configuring the Key Authentication plugin, you can verify that it was configured correctly and is working, by sending requests with and without the API key you created for your centrally-managed Consumer.

Send a request with a valid API key:

{% validation request-check %}
url: /anything
headers:
  - 'apikey:$CONSUMER_KEY'
status_code: 200
display_headers: true
{% endvalidation %}

You will see a successful `200` response.

When we send the wrong API key, it won't be authorized:

{% validation unauthorized-check %}
url: /anything
headers:
  - 'apikey:another_key'
{% endvalidation %}



