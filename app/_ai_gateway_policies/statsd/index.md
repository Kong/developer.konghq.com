---
description: 'Send request metrics, such as request count, request and response size, and latency, to a StatsD server. Covers the metrics, tags, naming options, scopes, and limitations.'
min_version:
  ai-gateway: '2.0'
works_on:
  - on-prem
  - konnect
products:
  - ai-gateway
content_type: plugin
categories:
  - analytics-monitoring
tags:
  - statsd
  - metrics
  - monitoring
  - ai
search_aliases:
  - statsd
  - metrics
  - collectd
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
The StatsD Policy is an [AI Policy](/ai-gateway/entities/ai-policy/) that sends request metrics from {{site.ai_gateway}}, such as request count, request and response size, and latency, to a StatsD server.
The Policy sends the metrics over UDP by default, or over TCP when you set [`config.use_tcp`](/ai-gateway/policies/statsd/reference/#schema--config-use-tcp), so the server must be reachable from the data plane at the address set in [`config.host`](/ai-gateway/policies/statsd/reference/#schema--config-host) and [`config.port`](/ai-gateway/policies/statsd/reference/#schema--config-port).

## Metrics

When you don't set [`config.metrics`](/ai-gateway/policies/statsd/reference/#schema--config-metrics), the StatsD Policy sends the following metrics for each request.
Each metric name starts with the [`config.prefix`](/ai-gateway/policies/statsd/reference/#schema--config-prefix) value, which is `kong` by default.
In the names, `<entity>` is the name of the [AI Agent](/ai-gateway/entities/ai-agent/) or [AI MCP Server](/ai-gateway/entities/ai-mcp-server/) that handled the request.
For [AI Models](/ai-gateway/entities/ai-model/), see [Limitations](#limitations).

{% table %}
columns:
  - title: Metric
    key: metric
  - title: Name
    key: name
  - title: Description
    key: description
  - title: Default type
    key: type
rows:
  - metric: "`request_count`"
    name: "`kong.service.<entity>.request.count`"
    description: Counts the request.
    type: "`counter`"
  - metric: "`latency`"
    name: "`kong.service.<entity>.latency`"
    description: Tracks the time in milliseconds between the request and the response.
    type: "`timer`"
  - metric: "`request_size`"
    name: "`kong.service.<entity>.request.size`"
    description: Tracks the size of the request in bytes.
    type: "`counter`"
  - metric: "`response_size`"
    name: "`kong.service.<entity>.response.size`"
    description: Tracks the size of the response in bytes.
    type: "`counter`"
  - metric: "`status_count`"
    name: "`kong.service.<entity>.status.<status>`"
    description: Counts the responses for each HTTP status code.
    type: "`counter`"
  - metric: "`upstream_latency`"
    name: "`kong.service.<entity>.upstream_latency`"
    description: Tracks the time in milliseconds the upstream took to process the request.
    type: "`timer`"
  - metric: "`kong_latency`"
    name: "`kong.service.<entity>.kong_latency`"
    description: Tracks the time in milliseconds {{site.ai_gateway}} spent processing the request itself.
    type: "`timer`"
  - metric: "`unique_users`"
    name: "`kong.service.<entity>.user.uniques`"
    description: Tracks the unique AI Consumers that made requests.
    type: "`set`"
  - metric: "`request_per_user`"
    name: "`kong.service.<entity>.user.<consumer_identifier>.request.count`"
    description: Counts the requests for each AI Consumer.
    type: "`counter`"
  - metric: "`status_count_per_user`"
    name: "`kong.service.<entity>.user.<consumer_identifier>.status.<status>`"
    description: Counts the responses for each HTTP status code and AI Consumer.
    type: "`counter`"
  - metric: "`status_count_per_workspace`"
    name: "`kong.service.<entity>.workspace.<workspace_id>.status.<status>`"
    description: Counts the responses for each HTTP status code, with a workspace ID in the name.
    type: "`counter`"
  - metric: "`shdict_usage`"
    name: |
      `kong.node.<node_hostname>.shdict.<dictionary>.free_space`
      <br>
      `kong.node.<node_hostname>.shdict.<dictionary>.capacity`
    description: Tracks the free space and capacity of each shared memory dictionary on the data plane node, about once a minute.
    type: "`gauge`"
{% endtable %}

When you set `config.metrics`, the Policy sends only the metrics in the list.

### Metric types

The `stat_type` field of each metric in `config.metrics` sets the metric type.
The Policy sends each type to the StatsD server as a type code:

{% table %}
columns:
  - title: Type
    key: type
  - title: Code
    key: code
rows:
  - type: "`counter`"
    code: "`c`"
  - type: "`timer`"
    code: "`ms`"
  - type: "`gauge`"
    code: "`g`"
  - type: "`histogram`"
    code: "`h`"
  - type: "`meter`"
    code: "`m`"
  - type: "`set`"
    code: "`s`"
{% endtable %}

Metrics of type `counter` or `gauge` require a `sample_rate`.
{{site.ai_gateway}} rejects the Policy when a `counter` or `gauge` metric doesn't set one.
The Policy reports every request and appends the rate to the metric, for example `kong.service.<entity>.request.count:1|c|@0.5`, so your StatsD server can scale the counts.

For `unique_users` and `status_count`, the Policy ignores `stat_type` and sends a `set` and a `counter`.

## Per-consumer metrics

The `request_per_user`, `status_count_per_user`, and `unique_users` metrics report a value for each [AI Consumer](/ai-gateway/entities/ai-consumer/).
Set the `consumer_identifier` field of the metric to choose the value that goes in the metric name:

* `username`: The name of the AI Consumer, for example `kong.service.<entity>.user.<username>.request.count`.
* `consumer_id`: The ID of the AI Consumer, including its hyphens.

For an authenticated request, the Policy doesn't send a per-consumer metric without a `consumer_identifier`.
The default [`config.consumer_identifier_default`](/ai-gateway/policies/statsd/reference/#schema--config-consumer-identifier-default) is `custom_id`, and `api-key` AI Consumers don't have a custom ID.
`oauth` AI Consumers set their own `custom_id`, for example to the `sub` claim.
For requests that authentication rejects, the default metrics include per-consumer metrics with the user name `anonymous`.

For a configuration, see [Count requests per AI Consumer](/ai-gateway/policies/statsd/examples/count-requests-per-consumer/).

## Tags

By default, the Policy puts the entity in the metric name.
Set [`config.tag_style`](/ai-gateway/policies/statsd/reference/#schema--config-tag-style) to send the metrics with tags instead.
The metric names then drop the entity, for example `kong.request.count`, and each metric carries the `route`, `workspace`, `node`, `status`, and `service` tags, plus a `consumer` tag when the request is authenticated.
The `shdict_usage` metric carries only the `node` and `shdict` tags.
The `route` tag holds a route name that {{site.ai_gateway}} generated for the entity, and `service` holds the entity name.

The Policy supports four tag formats:

{% table %}
columns:
  - title: "`tag_style`"
    key: style
  - title: Example
    key: example
rows:
  - style: "`dogstatsd`"
    example: "`kong.request.count:1|c|#route:<route>,status:200`"
  - style: "`influxdb`"
    example: "`kong.request.count,route=<route>,status=200:1|c`"
  - style: "`librato`"
    example: "`kong.request.count#route=<route>,status=200:1|c`"
  - style: "`signalfx`"
    example: "`kong.request.count[route=<route>,status=200]:1|c`"
{% endtable %}

Choose the format that matches your backend, for example `dogstatsd` for Datadog, `influxdb` for InfluxDB, `librato` for Librato, and `signalfx` for SignalFx.
When you set `tag_style`, the Policy doesn't send the `status_count` metric.
For a configuration, see [Send metrics with DogStatsD tags](/ai-gateway/policies/statsd/examples/use-dogstatsd-tags/).

## Metric names

Use the following settings to change what the metric names contain after the prefix.
`service_identifier` is a field of each metric in `config.metrics`.
Set [`config.service_identifier_default`](/ai-gateway/policies/statsd/reference/#schema--config-service-identifier-default) to apply one value to every metric.

{% table %}
columns:
  - title: Setting
    key: setting
  - title: Effect on the metric name
    key: effect
rows:
  - setting: "[`config.hostname_in_prefix`](/ai-gateway/policies/statsd/reference/#schema--config-hostname-in-prefix): `true`"
    effect: "Adds `node.<hostname>` after the prefix, for example `kong.node.<hostname>.service.<entity>.request.count`."
  - setting: "`service_identifier`: `service_name`"
    effect: "Uses the entity name as `<entity>`."
  - setting: "`service_identifier`: `service_id`"
    effect: "Uses an ID that {{site.ai_gateway}} generates for the entity."
  - setting: "`service_identifier`: `service_host`"
    effect: "Uses the host of the upstream URL, with each dot replaced by an underscore."
  - setting: "`service_identifier`: `service_name_or_host`"
    effect: "Uses the entity name. This is the default."
{% endtable %}

## Which requests the Policy reports

The StatsD Policy reports every request sent to the entity it's attached to, including requests that authentication rejects.
For example, the Policy reports a request that authentication rejects with the `401` status code.

To report only some responses, set [`config.allow_status_codes`](/ai-gateway/policies/statsd/reference/#schema--config-allow-status-codes) to a list of status code ranges, for example `200-205` and `400-499`.
The Policy then skips every response with another status code.
For a configuration, see [Report requests in a status range](/ai-gateway/policies/statsd/examples/log-on-status-range/).

## Packet size and transport

By default, the Policy sends each metric in its own UDP datagram.
Set [`config.udp_packet_size`](/ai-gateway/policies/statsd/reference/#schema--config-udp-packet-size) to the largest datagram size, in bytes, that the Policy may fill with several metrics.
The Policy separates the metrics in a datagram with newlines.
The value can't be larger than `65507`, so consider the MTU of your network when you set it.

Set `config.use_tcp` to `true` to send the metrics over TCP.

## Queuing

{% include md/ai-gateway/v2/policies/queues.md name="StatsD" slug="statsd" %}

The Policy sends the metrics of a request up to [`config.queue.max_coalescing_delay`](/ai-gateway/policies/statsd/reference/#schema--config-queue-max-coalescing-delay) seconds late.
Keep this value low for near-real-time dashboards.

## Scopes

You can apply the StatsD Policy globally, or attach it to an [AI Model](/ai-gateway/entities/ai-model/), an AI Agent, an AI MCP Server, or an AI Consumer.
For details about how scopes work, see [AI Policy scopes](/ai-gateway/entities/ai-policy/#ai-policy-scopes).

* At AI Agent and AI MCP Server scope, the Policy reports requests to that entity.
* At AI Model scope, the Policy reports requests to that AI Model.
  See [Limitations](#limitations) for the metric names.
* At AI Consumer scope, the Policy reports only requests authenticated as that AI Consumer.
* At global scope, the Policy reports requests to every entity on the gateway.
  To report only some traffic, set a [condition](/ai-gateway/conditions/) on the Policy.
  For example, the following condition reports only requests that include the header `x-rt: on`:

  ```yaml
  condition: 'http.headers.x_rt == "on"'
  ```

Use AI Consumer scope to count requests per caller, and use global scope when every entity needs the same metrics.

## Limitations

The StatsD Policy has the following limitations:

* **AI Model names:** at AI Model scope, and at global scope for AI Model traffic, every metric name contains `ai-gateway` as the entity, regardless of which AI Model handled the request.
  As a result, you can't tell AI Models apart in your StatsD server by the entity part of the name.

{:.warning}
> **AI Consumer Group scope:** {{site.ai_gateway}} accepts a StatsD Policy attached to an AI Consumer Group, but the data plane fails to apply the change.
> The data plane stays on its previous configuration until you detach the Policy from the AI Consumer Group.
