---
min_version:
  ai-gateway: '2.0'
works_on:
  - on-prem
  - konnect
products:
  - ai-gateway
content_type: plugin
description: 'Send request metrics, such as request count, request and response size, and latency, to a Datadog agent. Covers the metrics and tags the policy sends, scopes, queuing, and limitations.'
categories:
  - analytics-monitoring
tags:
  - datadog
  - metrics
  - monitoring
  - ai
search_aliases:
  - datadog
  - statsd
  - metrics
related_resources:
  - text: AI Policy entity
    url: /ai-gateway/entities/ai-policy/
  - text: AI Model entity
    url: /ai-gateway/entities/ai-model/
  - text: AI Agent entity
    url: /ai-gateway/entities/ai-agent/
  - text: AI MCP Server entity
    url: /ai-gateway/entities/ai-mcp-server/
  - text: AI Consumer entity
    url: /ai-gateway/entities/ai-consumer/
---

Dashboards that show traffic and latency per entity help you find slow upstreams, error spikes, and unexpected usage before users report them.
The Datadog Policy is an [AI Policy](/ai-gateway/entities/ai-policy/) that sends request metrics from {{site.ai_gateway}}, such as request count, request and response size, and latency, to a Datadog agent.
The policy sends the metrics over UDP in the DogStatsD format, so the agent must be reachable from the data plane at the address set in [`config.host`](/ai-gateway/policies/datadog/reference/#schema--config-host) and [`config.port`](/ai-gateway/policies/datadog/reference/#schema--config-port).

## Metrics

The Datadog Policy sends the following metrics.
Each metric name starts with the [`config.prefix`](/ai-gateway/policies/datadog/reference/#schema--config-prefix) value, which is `kong` by default:

{% table %}
columns:
  - title: Metric
    key: metric
  - title: Name in Datadog
    key: name
  - title: Description
    key: description
  - title: Default type
    key: type
rows:
  - metric: "`request_count`"
    name: "`kong.request.count`"
    description: Counts the request.
    type: "`counter`"
  - metric: "`request_size`"
    name: "`kong.request.size`"
    description: Tracks the request body size in bytes.
    type: "`timer`"
  - metric: "`response_size`"
    name: "`kong.response.size`"
    description: Tracks the response body size in bytes.
    type: "`timer`"
  - metric: "`latency`"
    name: "`kong.latency`"
    description: Tracks the time {{site.ai_gateway}} took to handle the request, including the response from the upstream.
    type: "`timer`"
  - metric: "`upstream_latency`"
    name: "`kong.upstream_latency`"
    description: |
      Tracks the time the upstream took to process the request.
      <br><br>
      A value of `-1` means {{site.ai_gateway}} didn't forward the request to the upstream.
      Filter out `-1` values when you use `upstream_latency` in latency calculations.
    type: "`timer`"
  - metric: "`kong_latency`"
    name: "`kong.kong_latency`"
    description: Tracks the time {{site.ai_gateway}} spent processing the request itself, separate from the upstream.
    type: "`timer`"
{% endtable %}

When you don't set [`config.metrics`](/ai-gateway/policies/datadog/reference/#schema--config-metrics), the policy sends all six metrics with the default types and adds the tag `app:kong`.
When you set `config.metrics`, the policy sends only the listed metrics and doesn't add `app:kong`.

### Metric types

The `stat_type` field of each metric in `config.metrics` sets the metric type.
The policy sends each type to the agent as a DogStatsD type code, for example `c` for `counter` and `ms` for `timer`.

Metrics of type `counter` or `gauge` require a `sample_rate`.
{{site.ai_gateway}} rejects the policy when a `counter` or `gauge` metric doesn't set one.

## Tags

The policy adds the following tags to each metric:

* `name`: The name of the [AI Agent](/ai-gateway/entities/ai-agent/) or [AI MCP Server](/ai-gateway/entities/ai-mcp-server/) that handled the request.
  To change the tag name, set [`config.service_name_tag`](/ai-gateway/policies/datadog/reference/#schema--config-service-name-tag).
  For AI Models, see [Limitations](#limitations).
* `status`: The HTTP status code of the response.
  To change the tag name, set [`config.status_tag`](/ai-gateway/policies/datadog/reference/#schema--config-status-tag).
* `app:kong`: The policy adds this tag only when you don't set `config.metrics`.

You can add more tags:

* Set `tags` on a metric to add your own tags, for example `env:production`.
* Set [`config.route_name_tag`](/ai-gateway/policies/datadog/reference/#schema--config-route-name-tag) to add a tag with the name of the route that {{site.ai_gateway}} generated for the entity.
* Set `consumer_identifier` on a metric to add the caller as a tag.
  The default tag name is `consumer`, and you can change it with [`config.consumer_tag`](/ai-gateway/policies/datadog/reference/#schema--config-consumer-tag).

### Identify AI Consumers

The `consumer_identifier` field of a metric sets which value of the [AI Consumer](/ai-gateway/entities/ai-consumer/) the policy adds:

* `consumer_id`: The ID of the AI Consumer, with hyphens replaced by underscores.
  For a configuration, see [Log request count](/ai-gateway/policies/datadog/examples/request-count/).
* `username`: The name of the AI Consumer.
  For a request that authentication rejects, the tag value is `anonymous`.
* `custom_id`: AI Consumers don't have a custom ID, so the policy doesn't add a tag.
  Use `consumer_id` or `username` instead.

## Which requests the policy reports

The Datadog Policy reports every request sent to the entity it's attached to, including requests that end early.
For example, the policy reports a request that authentication rejects with the `401` status code.
The policy reports a request that another policy ends, such as the [Request Termination Policy](/ai-gateway/policies/request-termination/), with that policy's status code and an `upstream_latency` of `-1`.

For streaming responses, `latency` covers the whole streamed response.

## Scopes

You can apply the Datadog Policy globally, or attach it to an [AI Model](/ai-gateway/entities/ai-model/), an AI Agent, an AI MCP Server, or an AI Consumer.
For details about how scopes work, see [AI Policy scopes](/ai-gateway/entities/ai-policy/#ai-policy-scopes).

* At AI Agent and AI MCP Server scope, the policy reports requests to that entity.
* At AI Model scope, the policy reports requests to that AI Model.
  See [Limitations](#limitations) for the `name` tag.
* At AI Consumer scope, the policy reports only requests authenticated as that AI Consumer.
* At global scope, the policy reports requests to every entity on the gateway.
  To report only some traffic, set a [condition](/ai-gateway/conditions/) on the policy.
  For example, the following condition reports only requests that include the header `x-rt: on`:

  ```yaml
  condition: 'http.headers.x_rt == "on"'
  ```

Use AI Consumer scope to count requests per caller, and use global scope when every entity needs the same metrics.

## Queuing

{% include md/ai-gateway/v2/policies/queues.md name="Datadog" slug="datadog" %}

A larger [`config.queue.max_batch_size`](/ai-gateway/policies/datadog/reference/#schema--config-queue-max-batch-size) makes the policy wait for a full batch before it sends.
A single request's metrics are sent to the agent up to [`config.queue.max_coalescing_delay`](/ai-gateway/policies/datadog/reference/#schema--config-queue-max-coalescing-delay) seconds late.
Keep these values low for near-real-time dashboards.

## Limitations

At AI Model scope, the Datadog Policy sets the `name` tag of every metric to `ai-gateway`, regardless of which AI Model handled the request.
The `route_name_tag` tag doesn't identify the AI Model either, because it contains a generated route name.
As a result, you can't tell AI Models apart in Datadog by grouping on `name`.

To tell AI Models apart, create one Datadog Policy per AI Model, attach each policy to its AI Model, and add a tag that identifies the AI Model to each metric in `config.metrics`, for example `model:gpt-4o`.
Use this workaround only with a policy attached to a single AI Model.
