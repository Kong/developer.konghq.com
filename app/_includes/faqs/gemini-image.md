{% if include.section == "question" %}

How do I control aspect ratio and resolution for Gemini image generation?

{% elsif include.section == "answer" %}

Pass `imageConfig` parameters via `generationConfig` in your image generation requests. See [Use Gemini's imageConfig with AI Proxy](/how-to/use-gemini-3-image-config/).

{% endif %}
