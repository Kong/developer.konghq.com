{% if include.section == "question" %}

Can I use different providers under `targets` with a single `llm_format`?

{% elsif include.section == "answer" %}

Yes, but only if `llm_format` is set to `openai`. The only translation supported today is OpenAI to the target provider.

For example, you can set `llm_format: openai` and have both OpenAI and Gemini targets. Setting `llm_format: gemini` with an OpenAI target is not supported.

{% endif %}