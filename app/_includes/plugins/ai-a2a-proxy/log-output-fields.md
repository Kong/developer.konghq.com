When `config.logging.log_statistics` is enabled, the plugin writes the following fields to the
`ai.a2a.rpc[]` array:

{% table %}
columns:
  - title: Field
    key: field
  - title: Type
    key: type
  - title: Description
    key: description
rows:
  - field: "`ai.a2a.rpc[].method`"
    type: string
    description: A2A operation name
  - field: "`ai.a2a.rpc[].binding`"
    type: string
    description: "Protocol binding: `jsonrpc` or `rest`"
  - field: "`ai.a2a.rpc[].latency`"
    type: number
    description: End-to-end proxy latency in milliseconds
  - field: "`ai.a2a.rpc[].id`"
    type: string
    description: Request ID (JSON-RPC) or task ID (REST)
  - field: "`ai.a2a.rpc[].task_id`"
    type: string
    description: Task ID extracted from the response
  - field: "`ai.a2a.rpc[].task_state`"
    type: string
    description: "Normalized task state (see [task states](/plugins/ai-a2a-proxy/#task-states))"
  - field: "`ai.a2a.rpc[].context_id`"
    type: string
    description: A2A context ID extracted from the response
  - field: "`ai.a2a.rpc[].error`"
    type: string
    description: Error type string when the upstream returned an error
  - field: "`ai.a2a.rpc[].response_body_size`"
    type: number
    description: Response body size in bytes
  - field: "`ai.a2a.rpc[].streaming`"
    type: boolean
    description: "`true` for SSE streaming responses"
  - field: "`ai.a2a.rpc[].ttfb_latency`"
    type: number
    description: Time to first byte in milliseconds (streaming only)
  - field: "`ai.a2a.rpc[].sse_events_count`"
    type: number
    description: "Count of SSE `data:` events received (streaming only)"
  - field: "`ai.a2a.rpc[].payload.request`"
    type: string
    description: "Request body (only when `log_payloads` is enabled)"
  - field: "`ai.a2a.rpc[].payload.response`"
    type: string
    description: "Response body (only when `log_payloads` is enabled)"
{% endtable %}
