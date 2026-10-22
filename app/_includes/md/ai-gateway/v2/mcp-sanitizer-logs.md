When you enable `log_statistics` in the AI MCP Server's [`config.logging`](/ai-gateway/entities/ai-mcp-server/#schema-aigateway-mcpserver-config-logging), each logged RPC that the Policy processed includes a `sanitizer` object in the [`ai.mcp` log entry](/ai-gateway/ai-audit-log-reference/#ai-mcp-logs).
{{site.ai_gateway}} adds the object to the same log entry as the rest of the request, so one request produces one entry.

The `sanitizer` object has the following properties:

{% table %}
columns:
  - title: Property
    key: property
  - title: Description
    key: description
rows:
  - property: "`ai.mcp.rpc[].sanitizer.identified`"
    description: The number of PII items the PII service identified.
  - property: "`ai.mcp.rpc[].sanitizer.sanitized`"
    description: The number of PII items the Policy sanitized.
  - property: "`ai.mcp.rpc[].sanitizer.duration`"
    description: The duration of sanitization.
  - property: "`ai.mcp.rpc[].sanitizer.sanitized_items`"
    description: A list of the sanitized PII items. Each item includes `original_text`, `redact_text`, `entity_type`, and `count`.
{% endtable %}

The `sanitized_items` entries include the original text, so the log contains the sensitive data.
Set [`skip_logging_sanitized_items`](/ai-gateway/policies/ai-mcp-sanitizer/reference/#schema--config-skip-logging-sanitized-items) to `true` to omit `sanitized_items` and keep that data out of your logs.
