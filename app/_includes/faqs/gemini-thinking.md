{% if include.section == "question" %}

How do I get reasoning traces from Gemini models?

{% elsif include.section == "answer" %}

Pass `thinkingConfig` parameters via `extra_body` in your requests to enable detailed reasoning traces. See [Use Gemini's thinkingConfig with AI Proxy Advanced](/how-to/use-gemini-3-thinking-config/).

{% endif %}
