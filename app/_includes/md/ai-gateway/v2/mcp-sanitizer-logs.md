Each logged RPC that the Policy processed includes a `sanitizer` object in the [`ai.mcp` log entry](/ai-gateway/ai-audit-log-reference/#ai-mcp-logs).
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
    description: The number of PII categories the PII service identified, such as `email` or `phone`.
  - property: "`ai.mcp.rpc[].sanitizer.sanitized`"
    description: The number of PII categories the Policy sanitized.
  - property: "`ai.mcp.rpc[].sanitizer.duration`"
    description: The duration of sanitization.
  - property: "`ai.mcp.rpc[].sanitizer.sanitized_items`"
    description: A list of the sanitized PII items. Each item includes `original_text`, `redact_text`, `entity_type`, and `count`.
{% endtable %}

By default, {{site.ai_gateway}} masks `original_text` in `sanitized_items`: it keeps only the first and last character and replaces the rest with `*`.
Set [`redact_logged_original_text`](/ai-gateway/policies/ai-mcp-sanitizer/reference/#schema--config-redact-logged-original-text) to `false` to log the original text. In that case, the log contains the sensitive data.
Set [`skip_logging_sanitized_items`](/ai-gateway/policies/ai-mcp-sanitizer/reference/#schema--config-skip-logging-sanitized-items) to `true` to omit `sanitized_items` entirely.

{:.warning}
> If you enable `payloads` in the AI MCP Server's [`config.logging`](/ai-gateway/entities/ai-mcp-server/#schema-aigateway-mcpserver-config-logging), the logged request payload contains the original tool call arguments, not the sanitized ones.
> The `redact_logged_original_text` setting does not apply to the payload.
> Do not enable `payloads` if your logs must not contain PII.
