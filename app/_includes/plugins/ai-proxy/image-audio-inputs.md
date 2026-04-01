{% assign plugin = include.plugin %}

{% navtabs "image-audio" %}

{% navtab "audio/v1/audio/speech" %}

{% include plugins/ai-proxy/inputs-partials/image-audio/audio-speech.md %}

{% endnavtab %}

{% navtab "audio/v1/audio/transcriptions" %}

{% include plugins/ai-proxy/inputs-partials/image-audio/audio-transcription.md %}

{% endnavtab %}

{% navtab "audio/v1/audio/translations" %}

{% include plugins/ai-proxy/inputs-partials/image-audio/audio-translation.md %}

{% endnavtab %}

{% navtab "image/v1/images/generations" %}

{% include plugins/ai-proxy/inputs-partials/image-audio/image-generation.md %}

{% endnavtab %}

{% navtab "image/v1/images/edits" %}

{% include plugins/ai-proxy/inputs-partials/image-audio/image-edit.md %}

{% endnavtab %}

{% navtab "video/v1/videos/generations" %}

{% include plugins/ai-proxy/inputs-partials/video/video-generation.md %}

{% endnavtab %}

{% if plugin == "AI Proxy Advanced" %}

{% navtab "realtime/v1/realtime" %}

{% include plugins/ai-proxy/inputs-partials/image-audio/realtime.md %}

{% endnavtab %}

{% endif %}

{% endnavtabs %}