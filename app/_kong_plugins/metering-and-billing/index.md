---
title: 'Metering & Billing'
name: 'Metering & Billing'

content_type: plugin

publisher: kong-inc
description: 'Meter API requests and AI token usage for usage-based billing. Supports flexible customer identification, custom pricing dimensions, and fine-grained traffic filtering. Integrates natively with {{site.konnect_short_name}} {{site.metering-and-billing}}.'


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
  - text: How-to guide for the plugin
    url: /how-to/guide/
---

The Metering & Billing plugin allows you to meter API requests and AI token usage for usage-based billing for both {{site.base_gateway}} on prem and {{site.konnect_short_name}} deployments. 
The plugin supports flexible customer identification, custom pricing dimensions, and fine-grained traffic filtering. 
Kong Gateway use cases

If you're using {{site.base_gateway}} on prem and want to meter traffic, you must use the Metering & Billing plugin. 
For {{site.konnect_short_name}}, you can either use the built-in {{site.metering-and-billing}} event ingestion that uses events from Advanced Analytics or use the Metering & Billing plugin.

{:.danger}
> **Event duplication:** 
> Do **not** use both the Metering & Billing plugin and the {{site.konnect_short_name}} built-in event ingestion in {{site.konnect_short_name}}. 
> This can result in duplicate events.

The following table can help you determine which to use based on your use case:

<!--vale off-->
{% table %}
columns:
  - title: Use case
    key: use-case
  - title: "{{site.konnect_short_name}} built-in"
    key: builtin
  - title: Metering & Billing plugin
    key: plugin
rows:
  - use-case: How do you want to set up event ingestion?
    builtin: Enabled with one click in Konnect UI
    plugin: Manual plugin configuration
  - use-case: Who do you want to bill?
    builtin: Consumer or application
    plugin: Consumer, Consumer Group, application, or any request header (for example, `x-customer-id` or `x-tenant-id`)
  - use-case: Do you want to bill based on custom dimensions, like department or priority tier?
    builtin: No
    plugin: Yes. Attach any request header or query parameter as a dimension on the event (for example, department, project, priority tier)
  - use-case: How do you want to filter traffic for events?
    builtin: At the Gateway control plane-level only (all Routes and Services in a control plane)
    plugin: Filter by Route, Service, header, or expression
{% endtable %}
<!--vale on-->

## How it works

The Metering & Billing plugin runs in the {{site.base_gateway}} request/response path and emits usage events in [CloudEvents](https://cloudevents.io/) format. 
These events are immutable once emitted and aren't observability or analytics signals.

For each request, the plugin:

1. Resolves the subject (the customer identity that gets billed) from the configured source (a Consumer, Consumer Group, application, or request header).
2. Captures standard {{site.base_gateway}} metadata on the event, including Route, Service, and response status.
3. Attaches any configured custom attributes from request headers or query parameters, such as department, project, or priority tier.
4. Buffers the event locally and delivers it in batches to the configured ingest endpoint ({{site.konnect_short_name}} {{site.metering-and-billing}} or OpenMeter self-hosted), with automatic retries on failure.

The following diagram shows how the plugin works:

<!--vale off-->
{% mermaid %}
sequenceDiagram
    autonumber
    participant client as Client
    participant kong as {{site.base_gateway}}
    participant plugin as Metering & Billing Plugin
    participant queue as Event Queue
    participant ingest as Ingest Endpoint<br>({{site.konnect_short_name}} {{site.metering-and-billing}} or OpenMeter)

    client->>kong: API or AI Gateway request
    kong->>plugin: log() phase triggers after response
    plugin->>plugin: Resolve subject from consumer,<br>application, or request header
    plugin->>plugin: Build CloudEvent with Kong metadata<br>and custom attributes
    plugin->>queue: Enqueue event(s)
    note right of plugin: AI requests enqueue 3 events:<br>API request, input tokens, output tokens
    queue->>ingest: Deliver batch (with retries)
    ingest->>ingest: Ingest, deduplicate,<br>aggregate, and invoice
{% endmermaid %}

<!--vale on-->

### Events and subjects

Every usage event has a subject that identifies who is billed for the request. The subject is the most important configuration decision because it determines how usage is grouped and aggregated. You can set the subject to a {{site.base_gateway}} Consumer, Consumer Group, {{site.konnect_short_name}} Dev Portal application, or any request header value such as `x-customer-id` or `x-tenant-id`.

If the plugin can't resolve a subject from the configured source (for example, if the expected header is missing) it sets the subject to `unknown`.

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
  - use-case: Filtering on custom dimensions
    description: |
      You can use event attributes to capture custom properties for the usage event for pricing dimensions or reporting. 
      Event attributes allow you to filter based on criteria such as provider, department, priority, or project for tiered or per-dimension pricing.

      You can define any attribute that is found in the header, query, or path of a request.
    example: 
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

The Metering & Billing plugin can't bill customers. If you want to bill customers based on usage events from the plugin, use [{{site.konnect_short_name}} {{site.metering-and-billing}}](/metering-and-billing/billing-invoicing-subscriptions/) or [OpenMeter self-hosted](https://openmeter.io/).

