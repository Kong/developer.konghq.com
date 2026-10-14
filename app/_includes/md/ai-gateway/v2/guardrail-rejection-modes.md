Use [`config.rejection_mode`](./reference/#schema--config-rejection-mode) to control how {{site.ai_gateway}} responds to a blocked request:

{% table %}
columns:
  - title: Mode
    key: mode
  - title: Status code
    key: status
  - title: Response body
    key: body
rows:
  - mode: "`none` (default)"
    status: "`400`"
    body: |
      A JSON error with the block message, for example `{"error": {"message": "..."}}`.
      The response omits the guardrail's name.
      Clients can tell it apart from a malformed request only by its message, because the status code is the same.
  - mode: "`stealth`"
    status: "`403`"
    body: |
      A generic JSON error, `{"error": {"message": "request forbidden"}}`.
      The response hides all guardrail details.
  - mode: "`verbose`"
    status: "`403`"
    body: |
      A structured JSON error that names the Policy that blocked the request and the reason.
      See [Verbose response](#verbose-response).
{% endtable %}

Use `none` or `stealth` for clients outside your organization, so responses don't reveal how your guardrails are configured.
Use `verbose` in development or for trusted internal clients, to see why a request was blocked.

### Verbose response

In `verbose` mode, the response always has the status code `403` and the error code `GUARDRAIL_BLOCKED`.
Clients can check the `error.code` field to tell a guardrail rejection apart from other errors:

* `type`: Always `guardrail_rejected`.
* `plugin`: The type of the Policy that blocked the request.
* `reason`: Why the request was blocked.
* `code`: Always `GUARDRAIL_BLOCKED`.
* `detail`: Additional context about the match. This field is only present when the Policy has details to report.

{% if include.checks_responses %}

### Streaming responses

When a guardrail blocks a streaming response, the final chunk of the stream has `finish_reason` set to `blocked_by_guard`.
The chunks that the guardrail already evaluated and sent are not recalled, so the HTTP status code of the response remains `200`.
The `rejection_mode` setting changes what the chunk reports:

* `none`: The `delta.content` field contains the block message.
* `stealth`: The `delta.content` field contains the message `request forbidden`.
* `verbose`: The `delta.content` field contains the block reason, and `choices[0]` also includes a `guardrail_result` object with the same fields as the verbose response.
{% elsif include.request_only %}
The {{include.name}} Policy evaluates the request before it reaches the LLM, so a blocked request returns the same error response whether or not the request sets `stream` to `true`.
{% endif %}
