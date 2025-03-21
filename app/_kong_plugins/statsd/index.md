---
title: 'StatsD'
name: 'StatsD'

content_type: plugin

publisher: kong-inc
description: 'Send metrics to StatsD'


products:
    - gateway

works_on:
    - on-prem
    - konnect


topologies:
  on_prem:
    - hybrid
    - db-less
    - traditional
  konnect_deployments:
    - hybrid
    - cloud-gateways
    - serverless
icon: statsd.png

categories:
  - analytics-monitoring

search_aliases:
  - collectd
---


The StatsD plugin logs [metrics](#metrics) for a [Gateway Service](/gateway/entities/service/) or [Route](/gateway/entities/route/) to a StatsD server.
It can also be used to log metrics on the [Collectd](https://collectd.org/)
daemon by enabling its
[StatsD plugin](https://collectd.org/wiki/index.php/Plugin:StatsD).

By default, the plugin sends a packet for each metric it observes. The `udp_packet_size` option
configures the greatest datagram size the plugin can combine. It should be less than
65507 according to UDP protocol. Consider the MTU of the network when setting this parameter.


## Queueing

The StatsD plugin uses a queue to decouple the production and
consumption of data. This reduces the number of concurrent requests
made to the upstream server under high load situations and provides
buffering during temporary network or upstream outages.

You can set several parameters to configure the behavior and capacity
of the queues used by the plugin. For more information about how to
use these parameters, see
[Plugin Queuing Reference](/gateway/latest/kong-plugins/queue/reference/)
in the {{site.base_gateway}} documentation.

The queue parameters all reside in a record under the key `queue` in
the `config` parameter section of the plugin.

Queues are not shared between workers and queueing parameters are
scoped to one worker.  For whole-system capacity planning, the number
of workers need to be considered when setting queue parameters.



## Metrics

The following configure the metrics that will be logged:
<!-- vale off -->
{% table %}
columns:
  - title: Metric
    key: metric
  - title: Description
    key: description
  - title: Namespace syntax
    key: namespace
rows:
  - metric: request_count
    description: The number of requests.
    namespace: "`kong.service.<service_identifier>.request.count`"
  - metric: request_size
    description: The request's body size in bytes.
    namespace: "`kong.service.<service_identifier>.request.size`"
  - metric: response_size
    description: The response's body size in bytes.
    namespace: "`kong.service.<service_identifier>.response.size`"
  - metric: latency
    description: The time interval in milliseconds between the request and response.
    namespace: "`kong.service.<service_identifier>.latency`"
  - metric: status_count
    description: Tracks each status code returned in a response.
    namespace: "`kong.service.<service_identifier>.status.<status>`"
  - metric: unique_users
    description: Tracks unique users who made requests to the underlying Service or Route.
    namespace: "`kong.service.<service_identifier>.user.uniques`"
  - metric: request_per_user
    description: Tracks the request count per Consumer.
    namespace: "`kong.service.<service_identifier>.user.<consumer_identifier>.request.count`"
  - metric: upstream_latency
    description: Tracks the time in milliseconds it took for the final Service to process the request.
    namespace: "`kong.service.<service_identifier>.upstream_latency`"
  - metric: kong_latency
    description: Tracks the internal {{site.base_gateway}} latency in milliseconds that it took to run all the plugins.
    namespace: "`kong.service.<service_identifier>.kong_latency`"
  - metric: status_count_per_user
    description: Tracks the status code per Consumer per Service.
    namespace: "`kong.service.<service_identifier>.user.<consumer_identifier>.status.<status>`"
  - metric: status_count_per_workspace
    description: The status code per Workspace.
    namespace: "`kong.service.<service_identifier>.workspace.<workspace_identifier>.status.<status>`"
  - metric: status_count_per_user_per_route
    description: The status code per consumer per Route.
    namespace: "`kong.route.<route_id>.user.<consumer_identifier>.status.<status>`"
  - metric: shdict_usage
    description: >-
      The usage of a shared dict, sent once every minute.<br><br>
      Monitors any `lua_shared_dict` used by {{site.base_gateway}}. You can find all the shared dicts {{site.base_gateway}} has configured using the [`/status`](/gateway/api/admin-ee/latest/#/operations/get-status) endpoint of the Admin API.<br><br>
      For example, the metric might report on `shdict.kong_locks` or `shdict.kong_counters`.
    namespace: "`kong.node.<node_hostname>.shdict.<lua_shared_dict>.free_space`<br><br>`kong.node.<node_hostname>.shdict.<lua_shared_dict>.capacity`"
  - metric: cache_datastore_hits_total
    description: The total number of cache hits. ({{site.ee_product_name}} only)
    namespace: "`kong.service.<service_identifier>.cache_datastore_hits_total`"
  - metric: cache_datastore_misses_total
    description: The total number of cache misses. ({{site.ee_product_name}} only)
    namespace: "`kong.service.<service_identifier>.cache_datastore_misses_total`"
{% endtable %}

<!-- vale on -->
If a request URI doesn't match any Routes, the following metrics are sent instead:
<!-- vale off -->
| Metric                     | Description | Namespace |
| ---                        | ---         | --- |
| `request_count`            | The request count. | `kong.global.unmatched.request.count` |
| `request_size`             | The request's body size in bytes. | `kong.global.unmatched.request.size` |
| `response_size`            | The response's body size in bytes. | `kong.global.unmatched.response.size` |
| `latency`                  | The time interval between when the request started and when the response is received from the upstream server. | `kong.global.unmatched.latency` |
| `status_count`             | The status count. | `kong.global.unmatched.status.<status>.count` |
| `kong_latency`             | The internal {{site.base_gateway}} latency in milliseconds that it took to run all the plugins. | `kong.global.unmatched.kong_latency` |
<!-- vale on -->
If you enable the `tag_style` configuration for the StatsD Plugin, the following metrics are sent instead:
<!-- vale off -->
| Metric                     | Description | Namespace |
| ---                        | ---         | --- |
| `request_count`            | The number of requests. | `kong.request.count` |
| `request_size`             | The request's body size in bytes. | `kong.request.size` |
| `response_size`            | The response's body size in bytes. | `kong.response.size` |
| `latency`                  | The time interval in milliseconds between the request and response. | `kong.latency` |
| `request_per_user`         | Tracks the request count per consumer. | `kong.request.count` |
| `upstream_latency`         | Tracks the time in milliseconds it took for the final Service to process the request. | `kong.upstream_latency` |
| `shdict_usage`             | The usage of shared dict, sent once every minute. | `kong.shdict.free_space` and `kong.shdict.capacity` |
| `cache_datastore_hits_total`            | The total number of cache hits. ({{site.base_gateway}} only) | `kong.cache_datastore_hits_total` |
| `cache_datastore_misses_total`            | The total number of cache misses. ({{site.base_gateway}} only) | `kong.cache_datastore_misses_total` |
<!-- vale on -->


The StatsD Plugin supports Librato, InfluxDB, DogStatsD, and SignalFX-style tags, which are used like Prometheus labels.

* **Librato-style tags**: Must be appended to the metric name with a delimiting `#`, for example:
`metric.name#tagName=val,tag2Name=val2:0|c`
See the [Librato StatsD](https://github.com/librato/statsd-librato-backend#tags) documentation for more information.

* **InfluxDB-style tags**: Must be appended to the metric name with a delimiting comma, for example:
`metric.name,tagName=val,tag2Name=val2:0|c`
See the [InfluxDB StatsD](https://www.influxdata.com/blog/getting-started-with-sending-statsd-metrics-to-telegraf-influxdb/#introducing-influx-statsd) documentation for more information.

* **DogStatsD-style tags**: Appended as a `|#` delimited section at the end of the metric, for example:
`metric.name:0|c|#tagName:val,tag2Name:val2`
See the [Datadog StatsD Tags](https://docs.datadoghq.com/developers/dogstatsd/data_types/#tagging) documentation for more information about the concept description and Datagram Format.
[AWS CloudWatch](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CloudWatch-Agent-custom-metrics-statsd.html) also uses the DogStatsD protocol.

* **SignalFX dimension**: Add the tags to the metric name in square brackets, for example:
`metric.name[tagName=val,tag2Name=val2]:0|c`
See the [SignalFX StatsD](https://github.com/signalfx/signalfx-agent/blob/main/docs/monitors/collectd-statsd.md#adding-dimensions-to-statsd-metrics) documentation for more information.

When the `tag_style` config is enabled, {{site.base_gateway}} uses a filter label, like `service`, `route`, `workspace`, `consumer`, `node`, or `status`, on the metrics tags to see if these can be found. For `shdict_usage` metrics, only `node` and `shdict` are added.

For example:

```
kong.request.size,workspace=default,route=d02485d7-8a28-4ec2-bc0b-caabed82b499,status=200,consumer=d24d866a-020a-4605-bc3c-124f8e1d5e3f,service=bdabce05-e936-4673-8651-29d2e9eca382,node=c80a9c5845bd:120|c
```



### Metric Fields

The Plugin can be configured with any combination of [Metrics](#metrics), with each entry containing the following fields:
<!-- vale off -->
{% table %}
columns:
  - title: Field
    key: field
  - title: Description
    key: description
  - title: Datatype
    key: datatype
  - title: Allowed values
    key: allowed
rows:
  - field: "`name`<br>*required*"
    description: StatsD metric's name.
    datatype: String
    allowed: "[Metrics](#metrics)"
  - field: "`stat_type`<br>*required*"
    description: Determines what sort of event a metric represents.
    datatype: String
    allowed: "`gauge`, `timer`, `counter`, `histogram`, `meter` and `set`"
  - field: "`sample_rate`<br>*required* <br>*conditional*"
    description: Sampling rate.
    datatype: Number
    allowed: "`number`"
  - field: "`consumer_identifier`<br>*conditional*"
    description: Authenticated user detail.
    datatype: String
    allowed: "One of the following options: `consumer_id`, `custom_id`, `username`, `null`"
  - field: "`service_identifier`<br>*conditional*"
    description: Service detail.
    datatype: String
    allowed: "One of the following options: `service_id`, `service_name`, `service_host`, `service_name_or_host`, `null`"
  - field: "`workspace_identifier`<br>*conditional*"
    description: Workspace detail.
    datatype: String
    allowed: "One of the following options: `workspace_id`, `workspace_name`, `null`"
{% endtable %}

<!-- vale on -->
### Metric behavior

- All metrics are logged by default.
- Metrics with a `stat_type` of `counter` or `gauge` **require** the `sample_rate` field.
- The `unique_users` metric only supports the `set` stat type.
- The following metrics only support the `counter` stat type:
  - `status_count`
  - `status_count_per_user`
  - `status_count_per_user_per_route`
  - `request_per_user`
- The `shdict_usage` metric only supports the `gauge` stat type.
- The following metrics **require** a `consumer_identifier`:
  - `status_count_per_user`
  - `request_per_user`
  - `unique_users`
  - `status_count_per_user_per_route`
- The `service_identifier` field is optional for all metrics. If not set, it defaults to `service_name_or_host`.
- The `status_count_per_workspace` metric requires a `workspace_identifier`.


## {{site.base_gateway}} process errors

This logging plugin logs HTTP request and response data, and also supports stream data (TCP, TLS, and UDP).
The {{site.base_gateway}} process error file is the Nginx error file. You can find it at the following path:
`{prefix}/logs/error.log`




