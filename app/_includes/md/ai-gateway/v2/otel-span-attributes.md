<!-- vale off -->
{% table %}
columns:
  - title: Attribute
    key: key
  - title: Value Type
    key: type
  - title: Description
    key: desc
rows:
  - key: "`kong.a2a.operation`"
    type: string
    desc: A2A operation name
  - key: "`kong.a2a.protocol.version`"
    type: string
    desc: "Value of the `A2A-Version` request header, or `unknown`"
  - key: "`kong.a2a.task.id`"
    type: string
    desc: Task ID from the response
  - key: "`kong.a2a.task.state`"
    type: string
    desc: Normalized task state
  - key: "`kong.a2a.context.id`"
    type: string
    desc: A2A context ID
  - key: "`kong.a2a.error`"
    type: string
    desc: Error type string when present
  - key: "`kong.a2a.streaming`"
    type: boolean
    desc: "`true` for SSE streaming responses"
  - key: "`kong.a2a.ttfb_latency`"
    type: int
    desc: Time to first byte in milliseconds (streaming only)
  - key: "`kong.a2a.sse_events_count`"
    type: int
    desc: Count of SSE events (streaming only)
  - key: "`rpc.system`"
    type: string
    desc: "`jsonrpc` (JSON-RPC binding only)"
  - key: "`rpc.method`"
    type: string
    desc: A2A operation name (JSON-RPC binding only)
{% endtable %}
<!-- vale on -->
