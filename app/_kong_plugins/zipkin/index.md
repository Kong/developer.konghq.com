---
title: 'Zipkin'
name: 'Zipkin'

content_type: plugin
publisher: kong-inc
description: 'Propagate Zipkin spans and report tracing data to a Zipkin server'

tags:
  - zipkin
  - tracing

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
icon: zipkin.png

categories:
  - analytics-monitoring

search_aliases:
  - Zipkin

related_resources:
  - text: Tracing With Zipkin in {{site.base_gateway}}
    url: https://konghq.com/blog/engineering/tracing-with-zipkin-in-kong-2-1-0
  - text: "{{site.base_gateway}} tracing"
    url: /gateway/tracing/
  - text: OpenTelemetry plugin
    url: /plugins/opentelemetry/
  - text: "{{site.base_gateway}} monitoring and metrics"
    url: /gateway/monitoring/

min_version:
  gateway: '1.0'
---

When enabled, the Zipkin plugin traces requests in a way that's compatible with [zipkin](https://zipkin.io/).

The code is structured around an [OpenTracing](http://opentracing.io/) core using the [opentracing-lua library](https://github.com/Kong/opentracing-lua) to collect timing data of a request in each of {{site.base_gateway}}'s phases.
The plugin uses an `opentracing-lua` compatible extractor, injector, and reporters to implement Zipkin's protocols.


## Reporter

Tracing data is reported to another system using an OpenTracing reporter.
This plugin records tracing data for a given request, and sends it as a batch to a Zipkin server using the [Zipkin v2 API](https://zipkin.io/zipkin-api/#/default/post_spans). Zipkin version 1.31 or later is required.

The [`config.http_endpoint`](/plugins/zipkin/reference/#schema--config-http-endpoint) configuration variable must contain the full URI including scheme, host, port, and path sections (for example, your URI likely ends in `/api/v2/spans`).

## Spans

The plugin does *request sampling*. For each request that triggers the plugin, a random number between 0 and 1 is chosen.

If the number is smaller than the configured [`config.sample_ratio`](/plugins/zipkin/reference/#schema--config-sample-ratio), then a trace with several spans will be generated. If `config.sample_ratio` is set to 1, then all requests will generate a trace (this might be very noisy).

For each request that gets traced, the following spans are produced: request, proxy, and balancer.

### Request span

_Span kind: SERVER_

There is one request span per request, which encompasses the whole request in {{site.base_gateway}}.

The [proxy](#proxy-span) and [balancer](#balancer-span) spans are children of this span. It contains the following logs/annotations for the rewrite phase:

* `krs`: `kong.rewrite.start`
* `krf`: `kong.rewrite.finish`

The request span has the following tags:

<!--vale off-->
{% table %}
columns:
  - title: Tag
    key: tag
  - title: Description
    key: description
rows:
  - tag: "`lc`"
    description: |
      Hardcoded to `kong`.
  - tag: "`kong.service`" 
    description: |
      The UUID of the Gateway Service matched when processing the request, if any.
  - tag: "`kong.service_name`"
    description: |
      The name of the Gateway Service matched when processing the request, if Gateway Service exists and has a `name` attribute.
  - tag: "`kong.route`"
    description: |
      The UUID of the Route matched when processing the request, if any (it can be nil on non-matched requests).
  - tag: "`kong.route_name`"
    description: |
      The name of the Route matched when processing the request, if Route exists and has a `name` attribute.
  - tag: "`http.method`"
    description: |
      The HTTP method used on the original request (only for HTTP requests).
  - tag: "`http.path`"
    description: |
      The path of the request (only for HTTP requests).
{% endtable %}
<!--vale on -->

Additional tags: 
* If the plugin `tags_header` config option is set, and the request contains headers with the appropriate name and correct encoding tags, then the trace will include the tags.
* If the plugin `static_tags` config option is set, then the tags in the config option will be included in the trace.

### Proxy span

_Span kind: CLIENT_

There is one proxy span per request, encompassing most of {{site.base_gateway}}'s internal processing of a request.

The proxy span contains the following logs/annotations for the start/finish of the of the [{{site.base_gateway}} plugin phases](/gateway/entities/plugin/#plugin-contexts):

{% table %}
columns:
  - title: Tag
    key: tag
  - title: Phase
    key: phase
rows:
  - tag: "`kas`"
    phase: "`kong.access.start`"
  - tag: "`kaf`"
    phase: "`kong.access.finish`"
  - tag: "`kbs`"
    phase: "`kong.body_filter.start`"
  - tag: "`kbf`"
    phase: "`kong.body_filter.finish`"
  - tag: "`khs`"
    phase: "`kong.header_filter.start`"
  - tag: "`khf`"
    phase: "`kong.header_filter.finish`"
  - tag: "`kps`"
    phase: "`kong.preread.start` (only for stream requests)"
  - tag: "`kpf`"
    phase: "`kong.preread.finish` (only for stream requests)"
{% endtable %}
<!--vale on-->

### Balancer span

_Span kind: CLIENT_

There are zero or more balancer spans per request, each encompassing one balancer attempt.
This span contains the following tags specific to load balancing:

<!--vale off-->
{% table %}
columns:
  - title: Tag
    key: tag
  - title: Description
    key: description
rows:
  - tag: "`kong.balancer.try`"
    description: |
      A number indicating the attempt (one for the first load-balancing attempt, two for the second, and so on).
  - tag: "`peer.ipv4` or `peer.ipv6`"
    description: The balancer IP.
  - tag: "`peer.port`"
    description: The balancer port.
  - tag: "`error`"
    description: |
      Set to `true` if the balancing attempt was unsuccessful, otherwise unset.
  - tag: "`http.status_code`"
    description: The HTTP status code received, in case of error.
  - tag: "`kong.balancer.state`"
    description: |
      An NGINX-specific description of the error, `next/failed` for HTTP failures, or `0` for stream failures.
      Equivalent to `state_name` in OpenResty's balancer's `get_last_failure` function.{% endtable %}
<!--vale on-->

## Propagation

The Zipkin plugin supports propagation of the following header formats:
- `w3c`: [W3C trace context](https://www.w3.org/TR/trace-context/)
- `b3` and `b3-single`: [Zipkin headers](https://github.com/openzipkin/b3-propagation)
- `jaeger`: [Jaeger headers](https://www.jaegertracing.io/docs/1.20/client-libraries/#propagation-format)
- `ot`: [OpenTracing headers](https://github.com/opentracing/specification/blob/master/rfc/trace_identifiers.md)
- `datadog`: [Datadog headers](https://docs.datadoghq.com/tracing/trace_collection/library_config/go/#trace-context-propagation-for-distributed-tracing)
- `aws`: [AWS X-Ray header](https://docs.aws.amazon.com/xray/latest/devguide/xray-concepts.html#xray-concepts-tracingheader) {% new_in 3.4 %}
- `gcp`: [GCP X-Cloud-Trace-Context header](https://cloud.google.com/trace/docs/setup#force-trace) {% new_in 3.5 %}

{% include /plugins/tracing-headers-propagation.md %}

See the plugin's [configuration reference](/plugins/zipkin/reference/#schema--config-propagation) for a complete overview of the available options and values.

{:.info}
> **Note:** If any of the `config.propagation.*` configuration options (`extract`, `clear`,  or `inject`) are configured, the `config.propagation` configuration takes precedence over the deprecated [`config.header_type`](/plugins/zipkin/reference/#schema--config-header-type) and [`config.default_header_type`](/plugins/zipkin/reference/#schema--config-default-header-type) parameters. 
If none of the `config.propagation.*` configuration options are set, the `config.header_type` and `config.default_header_type` parameters are still used to determine the propagation behavior.
<br><br>In {{site.base_gateway}} 3.6 or earlier, the plugin detects the propagation format from the headers and will use the appropriate format to propagate the span context. If no appropriate format is found, the plugin will fallback to the default format, which is `b3`.

## Trace IDs in serialized logs {% new_in 3.5 %}

When the Zipkin plugin is configured along with a plugin that uses the 
[Log Serializer](/gateway/pdk/reference/kong.log/#kong-log-serialize),
the trace ID of each request is added to the key `trace_id` in the serialized log output.

The value of this field is an object that can contain different formats
of the current request's trace ID. In case of multiple tracing headers in the
same request, the `trace_id` field includes one trace ID format
for each different header format, as in the following example:

```
"trace_id": {
  "b3": "4bf92f3577b34da6a3ce929d0e0e4736",
  "datadog": "11803532876627986230"
},
```

## Queuing

{% include_cached /plugins/queues.md name=page.name %}