---
title: 'Metering & Billing'
name: 'Metering & Billing'
tier: enterprise
content_type: plugin

publisher: kong-inc
description: 'Meter API requests and AI token usage for usage-based billing. Supports flexible customer identification, custom pricing dimensions, and fine-grained traffic filtering. Integrates natively with {{site.konnect_short_name}} {{site.metering_and_billing}}.'


products:
    - gateway

works_on:
    - on-prem
    - konnect

min_version:
    gateway: '3.14'

topologies:
  on_prem:
    - hybrid
    - db-less
    - traditional
  konnect_deployments:
    - hybrid
    - cloud-gateways
    - serverless

tags:
  - monetization

search_aliases:
  - metering-and-billing
  - metering


icon: metering-and-billing.png

categories:
   - monetization

related_resources:
  - text: "{{site.konnect_short_name}} {{site.metering_and_billing}}"
    url: /metering-and-billing/
  - text: "{{site.konnect_short_name}} metering"
    url: /metering-and-billing/metering/
  - text: Meter API requests by Consumer with {{site.metering_and_billing}}
    url: /how-to/meter-api-requests-by-consumer/
---

The Metering & Billing plugin allows you to meter API requests and AI token usage for usage-based billing for both {{site.base_gateway}} on-prem and {{site.konnect_short_name}} deployments. 
The plugin supports flexible customer identification, custom pricing dimensions, and fine-grained traffic filtering. 

If you're using {{site.base_gateway}} on-prem and want to meter traffic, you must use the Metering & Billing plugin. 

For {{site.konnect_short_name}}, you can either use the [built-in {{site.metering_and_billing}}](/metering-and-billing/) event ingestion that uses events from Advanced Analytics or use the Metering & Billing plugin.
{% include /plugins/metering-and-billing/konnect-use-case-table.md %}

## How it works

The Metering & Billing plugin runs in the {{site.base_gateway}} request/response path and emits usage events in [CloudEvents](https://cloudevents.io/) format. 
These events are immutable once emitted and aren't observability or analytics signals.

For each request, the plugin:

1. Resolves the subject (the customer identity that gets billed) from the configured source (a Consumer, application, or request header).
2. Captures standard {{site.base_gateway}} metadata on the event, including Route, Service, and response status.
3. Attaches any configured custom attributes from request headers or query parameters, such as department, project, or priority tier.
4. Buffers the event locally and delivers it in batches to the configured ingest endpoint, with automatic retries on failure:
   * [{{site.konnect_short_name}} {{site.metering_and_billing}} ingest endpoint](/api/konnect/metering-and-billing/v3/#/operations/ingest-metering-events): `https://us.api.konghq.com/v3/openmeter/events`
   * [OpenMeter self-hosted ingest endpoint](https://openmeter.io/docs/api/open-source#tag/events/POST/api/v1/events): `https://127.0.0.1/api/v1/events`

### Events and subjects

Every usage event has a subject that identifies who is billed for the request. The subject is the most important configuration decision because it determines how usage is grouped and aggregated. You can set the subject to a {{site.base_gateway}} [Consumer](/gateway/entities/consumer/), {{site.konnect_short_name}} [Dev Portal application](/dev-portal/self-service/), or any request header value such as `x-customer-id` or `x-tenant-id`.

If the plugin can't resolve a subject from the configured source (for example, if the expected header is missing), the event is dropped.

### Filtering traffic and custom dimensions

You can further narrow which traffic and dimensions the plugin will ingest as events. 
The following table describes how you can configure the plugin to filter traffic or custom dimensions:

<!--vale off-->
{% table %}
columns:
  - title: Use case
    key: use-case
  - title: "Description"
    key: description
  - title: Configuration example
    key: example
rows:
  - use-case: "[Filtering on custom dimensions](/plugins/metering-and-billing/examples/filter-by-department/)"
    description: |
      You can use event attributes to capture custom properties for the usage event for pricing dimensions or reporting. 
      Event attributes allow you to filter based on criteria such as provider, department, priority, or project for tiered or per-dimension pricing.

      You can define any attribute that is found in the header, query, or path of a request.
    example: Set [`config.attributes`](/plugins/metering-and-billing/reference/#schema--config-attributes) with the source, what attribute to look up in the source, and which source value to use. 
  - use-case: Filtering traffic in a control plane
    description: Since plugins can be applied globally, to Routes, Gateway Services, or Consumers, you can apply the Metering & Billing plugin to these entities to further narrow down the traffic you want to meter from the control plane. 
    example: Scope the plugin to a Route, Service, or Consumer.
{% endtable %}
<!--vale on-->

### Buffering and delivery

The plugin buffers events in a local queue before sending them to the ingest endpoint in batches. If delivery fails, the queue retries with exponential backoff up to the configured maximum retry duration. Events that can't be delivered within that window are dropped. The plugin itself is stateless; it doesn't persist events across Gateway restarts.

## Enforcing entitlements

The Metering & Billing plugin only meters events, it doesn't enforce metered limits. You must use a [rate limiting plugin](/plugins/?terms=rate%2520limiting) alongside the Metering & Billing plugin to enforce limits.

For example, if you're metering AI request tokens to 100 per month, you must use [AI Rate Limiting Advanced](/plugins/ai-rate-limiting-advanced/) to limit the tokens. 

## Usage-based billing

The Metering & Billing plugin can't bill customers. If you want to bill customers based on usage events from the plugin, use [{{site.konnect_short_name}} {{site.metering_and_billing}}](/metering-and-billing/billing-invoicing-subscriptions/) or [OpenMeter self-hosted](https://openmeter.io/).

