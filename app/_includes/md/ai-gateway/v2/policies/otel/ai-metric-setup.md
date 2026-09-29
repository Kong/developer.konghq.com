Metrics are natively supported by the OpenTelemetry Policy. To send metrics, set the following [`config.metrics`](/ai-gateway/policies/opentelemetry/reference/#schema--config-metrics) parameters:

<!-- vale off -->
{% table %}
columns:
  - title: Setting
    key: setting
  - title: Source
    key: source
  - title: Description
    key: required_for
rows:
  - setting: "`config.metrics.enable_ai_metrics`: `true`"
    source: "[OpenTelemetry](/ai-gateway/policies/opentelemetry/reference/)"
    required_for: "Enable all AI metrics"
  - setting: "`config.metrics.endpoint`"
    source: "[OpenTelemetry](/ai-gateway/policies/opentelemetry/reference/)"
    required_for: "Set to a valid OTLP-compatible metrics endpoint"
{% endtable %}
<!-- vale on -->

Some metrics have additional requirements:

* `gen_ai.server.request.duration` and `mcp.client.operation.duration` require `config.metrics.enable_latency_metrics` set to `true` in the [OpenTelemetry AI Policy](/ai-gateway/policies/opentelemetry/reference/).
* The `error.type` attribute on duration metrics requires `config.metrics.enable_request_metrics` set to `true` in the [OpenTelemetry AI Policy](/ai-gateway/policies/opentelemetry/reference/).