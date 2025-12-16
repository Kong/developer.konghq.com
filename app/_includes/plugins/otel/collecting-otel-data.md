{% assign plugin = include.plugin | default: "default" %}

{% capture data %}
## Collecting telemetry data

There are two ways to set up an OpenTelemetry backend:
* Sending data directly to an OpenTelemetry-compatible backend that natively supports OTLP over HTTP, like Jaeger (v1.35.0+).

  This is the simplest setup, since it doesn't require any additional components between the data plane and the backend.

  All the vendors supported by OpenTelemetry are listed in [OpenTelemetry's Vendor support](https://opentelemetry.io/vendors/).
* Using the OpenTelemetry Collector, which acts as an intermediary between the data plane and one or more backends.

  OTEL Collector can receive all OpenTelemetry signals supported by the OpenTelemetry plugin, including traces, metrics, and logs, and then process, transform, or route that data before exporting it to a compatible backend.

  This option is useful when you need capabilities such as signal fan-out, filtering, enrichment, batching, or exporting to multiple backends. The OpenTelemetry Collector supports a wide range of exporters, available at [open-telemetry/opentelemetry-collector-contrib](https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/exporter).

Both approaches rely on backends that support OTLP over HTTP using Protobuf encoding.
{% endcapture %}

{% if plugin == "OpenTelemetry" %}

{{data}}

{% else %}

{{data}}

{:.info}
> Check [OpenTelemetry](/plugins/opentelemetry/) and [{{site.base_gateway}} tracing](/gateway/tracing/) documentation for more details about OpenTelemetry in {{site.base_gateway}}.
{% endif %}