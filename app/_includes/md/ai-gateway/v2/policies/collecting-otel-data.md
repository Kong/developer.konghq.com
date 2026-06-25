## Collecting telemetry data

To set up an OpenTelemetry backend for {{site.ai_gateway}}, you need support for OTLP over HTTP with Protobuf encoding. You can:

* Send data directly to an OpenTelemetry-compatible backend that natively supports OTLP over HTTP with Protobuf encoding, like Jaeger (v1.35.0+).

  This is the simplest setup, since it doesn't require any additional components between the data plane and the backend.

* Use the OpenTelemetry Collector, which acts as an intermediary between the data plane and one or more backends.

  OTEL Collector can receive all OpenTelemetry signals supported by the {{site.ai_gateway}} OpenTelemetry Policy, including traces, metrics, and logs, and then process, transform, or route that data before exporting it to a compatible backend.

  This option is useful when you need capabilities such as signal fan-out, filtering, enrichment, batching, or exporting to multiple backends. The OpenTelemetry Collector supports a wide range of exporters, available at [open-telemetry/opentelemetry-collector-contrib](https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/exporter).

{% assign policy = include.policy | default: "default" %}
{% unless policy == "OpenTelemetry" %}
{:.info}
> Check [OpenTelemetry Policy](/ai-gateway/entities/ai-opentelemetry-policy/) and [{{site.base_gateway}} tracing](/gateway/tracing/) documentation for more details about OpenTelemetry and tracing in {{site.ai_gateway}}.
{% endunless %}
