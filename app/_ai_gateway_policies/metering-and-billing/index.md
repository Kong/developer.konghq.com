---
min_version:
  ai-gateway: '2.0'
works_on:
  - konnect
products:
  - ai-gateway
content_type: plugin
related_resources:
  - text: "{{site.konnect_short_name}} {{site.metering_and_billing}}"
    url: /metering-and-billing/
  - text: AI Rate Limiting Advanced Policy
    url: /ai-gateway/policies/ai-rate-limiting-advanced/
---

{:.warning}
> {{site.metering_and_billing}} requires a separate purchase. [Contact Sales](https://konghq.com/contact-sales) for pricing and availability.

The Metering & Billing Policy meters API requests and AI token usage for usage-based billing on {{site.ai_gateway}} traffic.
The Policy supports flexible customer identification, custom pricing dimensions, and fine-grained traffic filtering.

{:.warning}
> **Legacy built-in event ingestion:** If you previously enabled metering using the built-in {{site.konnect_short_name}} UI, do not enable the Metering & Billing Policy at the same time. This can result in duplicate events. Disable the built-in event ingestion first, then enable the Policy.

## How it works

The Metering & Billing Policy runs in the {{site.ai_gateway}} request/response path and emits usage events in [CloudEvents](https://cloudevents.io/) format.
These events are immutable once emitted and aren't observability or analytics signals.

For each request, the Policy:

1. Resolves the subject (the customer identity that gets billed) from the configured source (an AI Consumer, application, or request header).
1. Captures standard {{site.ai_gateway}} metadata on the event, including the AI Model, AI Agent, or AI MCP Server that handled the request, and the response status.
1. Attaches any configured custom attributes from request headers or query parameters, such as department, project, or priority tier.
1. Buffers the event locally and delivers it in batches to the configured ingest endpoint, with automatic retries on failure:
   * [{{site.konnect_short_name}} {{site.metering_and_billing}} ingest endpoint](/api/konnect/metering-and-billing/v3/#/operations/ingest-metering-events): `https://us.api.konghq.com/v3/openmeter/events`
   * [OpenMeter self-hosted ingest endpoint](https://openmeter.io/docs/api/v3#tag/metering-events/POST/openmeter/events): `https://127.0.0.1/api/v3/openmeter/events`

### Events and subjects

Every usage event has a subject that identifies who is billed for the request. The subject is the most important configuration decision because it determines how usage is grouped and aggregated. You can set the subject to an [AI Consumer](/ai-gateway/entities/ai-consumer/), {{site.konnect_short_name}} [Dev Portal application](/dev-portal/self-service/), or any request header value such as `x-customer-id` or `x-tenant-id`.

If the Policy can't resolve a subject from the configured source (for example, if the expected header is missing), the event is dropped.

### Filtering traffic and custom dimensions

You can further narrow which traffic and dimensions the Policy will ingest as events.
The following table describes how you can configure the Policy to filter traffic or custom dimensions:

<!--vale off-->
{% table %}
columns:
  - title: Use case
    key: use-case
  - title: "Description"
    key: description
  - title: How to configure
    key: example
rows:
  - use-case: "Filtering on custom dimensions"
    description: |
      You can use event attributes to capture custom properties for the usage event for pricing dimensions or reporting.
      Event attributes allow you to filter based on criteria such as provider, department, priority, or project for tiered or per-dimension pricing.

      You can define any attribute that is found in the header, query, or path of a request.
    example: Set [`config.attributes`](./reference/#schema--config-attributes) with the source, what attribute to look up in the source, and which source value to use.
  - use-case: Filtering traffic in a control plane
    description: Since the Policy can be applied globally or scoped to an [AI Consumer](/ai-gateway/entities/ai-consumer/), [AI Model](/ai-gateway/entities/ai-model/), [AI Agent](/ai-gateway/entities/ai-agent/), or [AI MCP Server](/ai-gateway/entities/ai-mcp-server/), you can attach the Metering & Billing Policy to these entities to further narrow down the traffic you want to meter.
    example: Scope the Policy to an AI Consumer, AI Model, AI Agent, or AI MCP Server.
{% endtable %}
<!--vale on-->

### Buffering and delivery

The Policy buffers events in a local queue before sending them to the ingest endpoint in batches. If delivery fails, the queue retries with exponential backoff up to the configured maximum retry duration. Events that can't be delivered within that window are dropped. The Policy itself is stateless; it doesn't persist events across restarts.

## Enforcing entitlements

The Metering & Billing Policy only meters events, it doesn't enforce metered limits. You must use a rate limiting policy alongside the Metering & Billing Policy to enforce limits.

For example, if you're metering AI request tokens to 100 per month, you must use the [AI Rate Limiting Advanced Policy](/ai-gateway/policies/ai-rate-limiting-advanced/) to limit the tokens.

## Usage-based billing

The Metering & Billing Policy can't bill customers. If you want to bill customers based on usage events from the Policy, use [{{site.konnect_short_name}} {{site.metering_and_billing}}](/metering-and-billing/billing-invoicing-subscriptions/) or [OpenMeter self-hosted](https://openmeter.io/).

## Examples

### Meter AI token usage

Emit separate usage events for AI input and output tokens on {{site.ai_gateway}} requests, billed to the authenticated AI Consumer:

{% entity_example %}
type: policy
data:
  name: metering-and-billing
  type: metering-and-billing
  config:
    ingest_endpoint: https://us.api.konghq.com/v3/openmeter/events
    api_token: your-api-token
    meter_api_requests: false
    meter_ai_token_usage: true
    subject:
      look_up_value_in: consumer
formats:
  - konnect-api
  - kongctl
{% endentity_example %}

### Capture custom billing dimensions

Attach department and project dimensions from request headers to every usage event:

{% entity_example %}
type: policy
data:
  name: metering-and-billing
  type: metering-and-billing
  config:
    ingest_endpoint: https://us.api.konghq.com/v3/openmeter/events
    api_token: your-api-token
    meter_api_requests: true
    meter_ai_token_usage: false
    subject:
      look_up_value_in: consumer
    attributes:
      - source: header
        look_up_value_in: x-department
        event_property_name: department
      - source: header
        look_up_value_in: x-project
        event_property_name: project
formats:
  - konnect-api
  - kongctl
{% endentity_example %}

These attributes are included in the event data payload and can be used to apply tiered pricing rules, enforce per-department usage budgets, or produce internal chargeback reports. If a header is absent on a given request, that attribute is omitted from that event.
