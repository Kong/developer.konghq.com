To run the {{include.name}} Policy without blocking, set [`config.continue_on_detection`](./reference/#schema--config-continue-on-detection) to `true`.
When a request matches, the Policy lets the request continue to the LLM.
The caller receives the LLM's normal response, so `config.rejection_mode` has no effect while this setting is enabled.

{% if include.logs_detection %}
Detections are still recorded in the {{site.ai_gateway}} logs.
The `ai.proxy.guardrail_triggered` object is populated with the Policy that matched and the direction of the match.
To include the matched content, also set `config.log_blocked_content` to `true`.
For the full list of fields, see the [{{site.ai_gateway}} audit log reference](/ai-gateway/ai-audit-log-reference/).

This is useful when you roll out new rules: run them in detection-only mode, review the logs for false positives, then set `continue_on_detection` back to `false` to enforce them.
{% else %}
Unlike other AI guardrail Policies, the {{include.name}} Policy doesn't populate the `ai.proxy.guardrail_triggered` object when this setting is enabled.
For the fields that other guardrail Policies record, see the [{{site.ai_gateway}} audit log reference](/ai-gateway/ai-audit-log-reference/).

Set `continue_on_detection` back to `false` to enforce the rules.
{% endif %}
