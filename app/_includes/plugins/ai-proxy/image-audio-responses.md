{% assign plugin = include.plugin %}

{% navtabs "responses-audio-image" %}

{% navtab "llm/v1/audio/file/speech" %}

{% include plugins/ai-proxy/responses-partials/image-audio/audio-speech.md %}

{% endnavtab %}

{% navtab "audio/v1/audio/transcriptions" %}

{% include plugins/ai-proxy/responses-partials/image-audio/audio-transcription.md %}

{% endnavtab %}

{% navtab "audio/v1/audio/translations" %}

{% include plugins/ai-proxy/responses-partials/image-audio/audio-translation.md %}

{% endnavtab %}

{% navtab "image/v1/images/generations" %}

{% include plugins/ai-proxy/responses-partials/image-audio/image-generation.md %}

{% endnavtab %}

{% navtab "image/v1/images/edit" %}

{% include plugins/ai-proxy/responses-partials/image-audio/image-edit.md %}

{% endnavtab %}

{% navtab "video/v1/videos/generation" %}

{% include plugins/ai-proxy/responses-partials/video/video-generation.md %}

{% endnavtab %}

{% if plugin == "AI Proxy Advanced" %}

{% navtab "realtime/v1/realtime" %}

{% include plugins/ai-proxy/responses-partials/image-audio/realtime.md %}

{% endnavtab %}

{% endif %}

{% endnavtabs %}