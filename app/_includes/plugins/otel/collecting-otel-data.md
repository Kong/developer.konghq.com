{% assign plugin = include.plugin | default: "default" %}

{% if plugin == "OpenTelemetry" %}
## Collecting telemetry data

There are two ways to set up an OpenTelemetry backend:
* Using an OpenTelemetry-compatible backend directly, like Jaeger (v1.35.0+).

  All the vendors supported by OpenTelemetry are listed in [OpenTelemetry's Vendor support](https://opentelemetry.io/vendors/).
* Using the OpenTelemetry Collector, which is middleware that can be used to proxy OpenTelemetry spans to a compatible backend.

  You can view all the available OpenTelemetry Collector exporters at [open-telemetry/opentelemetry-collector-contrib](https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/exporter).
{% else %}
## Collecting telemetry data

There are two ways to set up an OpenTelemetry backend:
* Using an OpenTelemetry-compatible backend directly, like Jaeger (v1.35.0+).

  All the vendors supported by OpenTelemetry are listed in [OpenTelemetry's Vendor support](https://opentelemetry.io/vendors/).
* Using the OpenTelemetry Collector, which is middleware that can be used to proxy OpenTelemetry spans to a compatible backend.

  You can view all the available OpenTelemetry Collector exporters at [open-telemetry/opentelemetry-collector-contrib](https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/exporter).

  {:.info}
  > Check [OpenTelemetry](/plugins/opentelemetry/) and [{{site.base_gateway}} tracing](/gateway/tracing/) documentation for more details about OpenTelemetry and tracing in {{site.base_gateway}}.
{% endif %}