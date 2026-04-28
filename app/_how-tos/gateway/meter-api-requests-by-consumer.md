---
title: Track API requests by Consumer with {{site.metering_and_billing}}
permalink: /how-to/meter-api-requests-by-consumer/
description: Learn how to use the {{site.metering_and_billing}} plugin on a self-managed {{site.base_gateway}} to emit per-Consumer API usage events to {{site.konnect_short_name}} {{site.metering_and_billing}}.
content_type: how_to

breadcrumbs:
  - /gateway/

products:
    - gateway

works_on:
    - on-prem

plugins:
  - metering-and-billing

entities:
  - service
  - route
  - plugin
  - consumer

tools:
    - deck

min_version:
  gateway: '3.14'

tags:
  - metering
  - billing

prereqs:
  entities:
    services:
        - example-service
    routes:
        - example-route
  inline:
    - title: "{{site.konnect_short_name}} system account token"
      include_content: prereqs/metering-and-billing-spat
      icon_url: /assets/icons/kogo-white.svg

cleanup:
  inline:
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg

tldr:
  q: How do I meter API requests by Consumer using the {{site.metering_and_billing}} plugin on a self-managed gateway?
  a: |
    Configure the {{site.metering_and_billing}} plugin on a Gateway Service with `meter_api_requests: true` and `subject.look_up_value_in: consumer`. 
    <br><br>
    In this guide, the Gateway runs on-prem, while the plugin sends one CloudEvent per API request directly to the {{site.konnect_short_name}} {{site.metering_and_billing}} ingest endpoint, with the authenticated Consumer as the event subject. 
    <br><br>
    You can verify that events appear in the {{site.konnect_short_name}} UI under **{{site.metering_and_billing}}** > **Events**.

related_resources:
  - text: "{{site.metering_and_billing}} plugin reference"
    url: /plugins/metering-and-billing/
  - text: Metering reference
    url: /metering-and-billing/metering/
  - text: Customers and usage attribution
    url: /metering-and-billing/customer/
  - text: Billing and invoicing
    url: /metering-and-billing/billing-invoicing/
  - text: Get started with {{site.metering_and_billing}}
    url: /metering-and-billing/get-started/
  - text: Meter and bill active users
    url: /how-to/meter-and-bill-active-users/

automated_tests: false
---

You can track per-consumer API usage without modifying your upstream services by using the {{site.metering_and_billing}} plugin.
The plugin emits a CloudEvent for every API request that passes through {{site.base_gateway}}, using the authenticated Consumer as the billable subject.

In this guide, you'll:

* Create a Consumer with a Key Auth credential
* Configure Key Authentication on the example Service
* Configure the {{site.metering_and_billing}} plugin to emit usage events to {{site.konnect_short_name}}
* Verify that usage events appear in the {{site.konnect_short_name}} UI

## Create a Consumer

[Consumers](/gateway/entities/consumer/) can represent the clients that call your APIs.
The {{site.metering_and_billing}} plugin uses the Consumer's `username` as the `subject` field in each CloudEvent it emits, which enables per-client billing downstream.

<!--vale off-->
{% entity_examples %}
entities:
  consumers:
    - username: alice
      keyauth_credentials:
        - key: alice-key
{% endentity_examples %}
<!--vale on-->

## Configure Key Authentication

This {{site.metering_and_billing}} plugin configuration requires an [authenticated](/gateway/authentication/) Consumer to be present on each request.
Enable the [Key Auth](/plugins/key-auth/) plugin on the example Service:

<!--vale off-->
{% entity_examples %}
entities:
  plugins:
    - name: key-auth
      service: example-service
      config:
        key_names:
          - apikey
{% endentity_examples %}
<!--vale on-->

## Configure the Metering & Billing plugin

Enable the {{site.metering_and_billing}} plugin on the example Service.
Setting `meter_api_requests: true` tells the plugin to emit one event per request.
Setting `subject.look_up_value_in: consumer` populates the `subject` field in each CloudEvent with the authenticated Consumer's username.

<!--vale off-->
{% entity_examples %}
entities:
  plugins:
    - name: metering-and-billing
      service: example-service
      config:
        ingest_endpoint: https://us.api.konghq.com/v3/openmeter/events
        api_token: ${AUTH_TOKEN}
        meter_api_requests: true
        meter_ai_token_usage: false
        subject:
          look_up_value_in: consumer
variables:
  AUTH_TOKEN:
    value: $AUTH_TOKEN
    description: A {{site.konnect_short_name}} system account token (`spat_`) with the Metering Ingest role.
{% endentity_examples %}
<!--vale on-->

## Validate

Send a few requests through the example Service using the `alice` Consumer's API key:

<!--vale off-->
```sh
for _ in {1..3}; do
  curl -i http://localhost:8000/anything \
       -H "apikey: alice-key"
  echo
done
```
<!--vale on-->

This sends three requests, each emitting a CloudEvent with `subject: alice` to {{site.konnect_short_name}}.

Now verify that the events were received:

1. In the {{site.konnect_short_name}} sidebar, click **{{site.metering_and_billing}}**.
1. Click the **Events** tab.

You'll see three events listed, each with `subject: alice`, one for each request that passed through {{site.base_gateway}}.

You'll also see an error message like `no customer found for event subject: consumer` associated with the event.
This is expected since we're only tracking API usage.
If you want to meter and bill Consumers' usage, see [Metering](/metering-and-billing/metering/), [Customers and usage attribution](/metering-and-billing/customer/), and [Billing and invoicing](/metering-and-billing/billing-invoicing/).
