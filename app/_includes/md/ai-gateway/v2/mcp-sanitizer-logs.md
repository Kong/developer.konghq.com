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
