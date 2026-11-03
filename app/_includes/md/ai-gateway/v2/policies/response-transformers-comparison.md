<!---shared by the Response Transformer, Response Transformer Advanced, and AI Response Transformer Policies --->

## Choose a response transformation policy

{{site.ai_gateway}} has three [AI Policies](/ai-gateway/entities/ai-policy/) that change a response before it reaches the client.
Choose by how predictable the change is.

### Which policy fits your case

The following table shows when to use each policy, with an example of a change it fits:

<!-- vale off -->
{% table %}
columns:
  - title: Policy
    key: policy
  - title: Use it when
    key: when
  - title: Example
    key: example
rows:
  - policy: "[Response Transformer](/ai-gateway/policies/response-transformer/)"
    when: You know the exact headers or top-level JSON properties to change.
    example: Remove an internal header, rename a property, or add a header to every response.
  - policy: "[Response Transformer Advanced](/ai-gateway/policies/response-transformer-advanced/)"
    when: |
      A rule needs more control than that, such as when:

      * The change applies only to some status codes.
      * The field you need is nested in an object or an array.
      * You want to keep only an allowed set of properties.
      * You want to replace the whole body or transform it with Lua.
    example: Add a header to error responses only, or remove a property from every entry in an array.
  - policy: "[AI Response Transformer](/ai-gateway/policies/ai-response-transformer/)"
    when: No rule can describe the change.
    example: Summarize or translate a response, redact sensitive details written in free text, or reshape output that has no fixed structure.
{% endtable %}
<!-- vale on -->

We recommend the other two policies for changes a rule can express, because the AI Response Transformer Policy adds an LLM request, with its cost and latency, to every response.

You can combine policies.
The rule-based policies have a higher priority than the AI Response Transformer Policy, so they run first.
For details, see [AI Policy priority](/ai-gateway/entities/ai-policy/#ai-policy-priority).

### Compare behavior and scopes

The following table compares how repeatable each policy's result is, which can set the status code, and where each policy applies.
The AI Response Transformer Policy sets the status code only when you set `parse_llm_response_json_instructions` to `true`.

<!-- vale off -->
{% table %}
columns:
  - title: Capability
    key: capability
  - title: Response Transformer
    key: standard
  - title: Response Transformer Advanced
    key: advanced
  - title: AI Response Transformer
    key: ai_response
rows:
  - capability: Same result every time
    standard: true
    advanced: true
    ai_response: false
  - capability: Sets the status code
    standard: false
    advanced: false
    ai_response: true
  - capability: Scopes
    standard: AI Model, AI Agent, AI MCP Server, AI Consumer, AI Consumer Group, global
    advanced: AI Model, AI Agent, AI MCP Server, AI Consumer, AI Consumer Group, global
    ai_response: AI Model, AI Consumer, AI Consumer Group, global
{% endtable %}
<!-- vale on -->
