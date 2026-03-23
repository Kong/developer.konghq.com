{% assign plugin = include.plugin %}

{% if include.section == "question" %}

What does `llm_format` control in {{ plugin }}?

{% elsif include.section == "answer" %}

{% if plugin == "AI Proxy" %}

`llm_format` sets the expected request format on the client-facing side of the gateway.

{% elsif plugin == "AI Proxy Advanced" %}

`llm_format` sets the expected format for both requests and responses on the client-facing (inbound) side of the gateway. The outbound format between the gateway and LLM providers is determined by `target[].model.provider`.

{% endif %}

{% endif %}