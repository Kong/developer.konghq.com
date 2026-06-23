{%- assign provider = include.providers.providers | where: "name", include.provider_name | first -%}
{% if provider %}
You can proxy requests to {{ provider.name }} AI models through {{site.ai_gateway}} by creating [AI Providers](/ai-gateway/entities/ai-provider/) and [AI Models](/ai-gateway/entities/ai-model/). This reference documents all supported AI capabilities, configuration requirements, and provider-specific details needed for proper integration.

## Upstream paths

{{site.ai_gateway}} automatically routes requests to the appropriate {{ provider.name }} API endpoints. The following table shows the upstream paths used for each capability.

{% table %}
vertical_align: middle
columns:
  - title: Capability
    key: capability
  - title: Path template
    key: path_template
  - title: Description
    key: description
  - title: Upstream path or API
    key: upstream_path
rows:
{% if provider.capabilities.generate.supported %}
  - capability: "{% if page.output_format == 'markdown' %}Generate{% else %}[Generate](#text-generation){% endif %}"
    path_template: "`/chat/completions`, `/completions`, or `/responses`"
    description: "Text generation for chat completions and responses"
    upstream_path: "{{ provider.capabilities.generate.upstream_path }}"
{% endif %}
{% if provider.capabilities.agentic.supported %}
  - capability: "{% if page.output_format == 'markdown' %}Agentic{% else %}[Agentic](#agentic){% endif %}"
    path_template: "`/assistants` or `/responses`"
    description: "Agent and assistant-based interactions"
    upstream_path: "{{ provider.capabilities.agentic.upstream_path }}"
{% endif %}
{% if provider.capabilities.realtime.supported %}
  - capability: "{% if page.output_format == 'markdown' %}Realtime{% else %}[Realtime](#realtime){% endif %}"
    path_template: "`/realtime`"
    description: "Bidirectional streaming for real-time applications"
    upstream_path: "{{ provider.capabilities.realtime.upstream_path }}"
{% endif %}
{% if provider.capabilities.embeddings.supported %}
  - capability: "{% if page.output_format == 'markdown' %}Embeddings{% else %}[Embeddings](#embeddings){% endif %}"
    path_template: "`/embeddings`"
    description: "Vector embeddings from text input"
    upstream_path: "{{ provider.capabilities.embeddings.upstream_path }}"
{% endif %}
{% if provider.capabilities.image.supported %}
  - capability: "{% if page.output_format == 'markdown' %}Image{% else %}[Image](#image){% endif %}"
    path_template: "`/images/generations` or `/images/edits`"
    description: "Image generation and editing"
    upstream_path: "{{ provider.capabilities.image.upstream_path }}"
{% endif %}
{% if provider.capabilities.audio_speech.supported %}
  - capability: "{% if page.output_format == 'markdown' %}Audio speech{% else %}[Audio speech](#audio){% endif %}"
    path_template: "`/audio/speech`"
    description: "Text-to-speech synthesis"
    upstream_path: "{{ provider.capabilities.audio_speech.upstream_path }}"
{% endif %}
{% if provider.capabilities.audio_transcription.supported %}
  - capability: "{% if page.output_format == 'markdown' %}Audio transcription{% else %}[Audio transcription](#audio){% endif %}"
    path_template: "`/audio/transcriptions`"
    description: "Speech-to-text conversion"
    upstream_path: "{{ provider.capabilities.audio_transcription.upstream_path }}"
{% endif %}
{% if provider.capabilities.audio_translation.supported %}
  - capability: "{% if page.output_format == 'markdown' %}Audio translation{% else %}[Audio translation](#audio){% endif %}"
    path_template: "`/audio/translations`"
    description: "Audio translation between languages"
    upstream_path: "{{ provider.capabilities.audio_translation.upstream_path }}"
{% endif %}
{% if provider.capabilities.video.supported %}
  - capability: "{% if page.output_format == 'markdown' %}Video{% else %}[Video](#video){% endif %}"
    path_template: "`/videos`"
    description: "Video generation"
    upstream_path: "{{ provider.capabilities.video.upstream_path }}"
{% endif %}
{% if provider.capabilities.rerank.supported %}
  - capability: "{% if page.output_format == 'markdown' %}Rerank{% else %}[Rerank](#rerank){% endif %}"
    path_template: "`/rerank`"
    description: "Semantic reranking of documents"
    upstream_path: "{{ provider.capabilities.rerank.upstream_path }}"
{% endif %}
{% if provider.capabilities.batches.supported %}
  - capability: "{% if page.output_format == 'markdown' %}Batches{% else %}[Batches](#batches){% endif %}"
    path_template: "`/batches`"
    description: "Batch processing of requests"
    upstream_path: "{{ provider.capabilities.batches.upstream_path }}"
{% endif %}
{% if provider.capabilities.files.supported %}
  - capability: "{% if page.output_format == 'markdown' %}Files{% else %}[Files](#files){% endif %}"
    path_template: "`/files`"
    description: "File management and storage"
    upstream_path: "{{ provider.capabilities.files.upstream_path }}"
{% endif %}
{% endtable %}

{%- assign note_counter = 0 -%}
{%- assign generate_note_num = 0 %}{% if provider.capabilities.generate.note.content %}{% assign note_counter = note_counter | plus: 1 %}{% assign generate_note_num = note_counter %}{% endif -%}
{%- assign agentic_note_num = 0 %}{% if provider.capabilities.agentic.note.content %}{% assign note_counter = note_counter | plus: 1 %}{% assign agentic_note_num = note_counter %}{% endif -%}
{%- assign realtime_note_num = 0 %}{% if provider.capabilities.realtime.note.content %}{% assign note_counter = note_counter | plus: 1 %}{% assign realtime_note_num = note_counter %}{% endif -%}
{%- assign embeddings_note_num = 0 %}{% if provider.capabilities.embeddings.note.content %}{% assign note_counter = note_counter | plus: 1 %}{% assign embeddings_note_num = note_counter %}{% endif -%}
{%- assign image_note_num = 0 %}{% if provider.capabilities.image.note.content %}{% assign note_counter = note_counter | plus: 1 %}{% assign image_note_num = note_counter %}{% endif -%}
{%- assign audio_speech_note_num = 0 %}{% if provider.capabilities.audio_speech.note.content %}{% assign note_counter = note_counter | plus: 1 %}{% assign audio_speech_note_num = note_counter %}{% endif -%}
{%- assign audio_transcription_note_num = 0 %}{% if provider.capabilities.audio_transcription.note.content %}{% assign note_counter = note_counter | plus: 1 %}{% assign audio_transcription_note_num = note_counter %}{% endif -%}
{%- assign audio_translation_note_num = 0 %}{% if provider.capabilities.audio_translation.note.content %}{% assign note_counter = note_counter | plus: 1 %}{% assign audio_translation_note_num = note_counter %}{% endif -%}
{%- assign video_note_num = 0 %}{% if provider.capabilities.video.note.content %}{% assign note_counter = note_counter | plus: 1 %}{% assign video_note_num = note_counter %}{% endif -%}
{%- assign rerank_note_num = 0 %}{% if provider.capabilities.rerank.note.content %}{% assign note_counter = note_counter | plus: 1 %}{% assign rerank_note_num = note_counter %}{% endif -%}
{%- assign batches_note_num = 0 %}{% if provider.capabilities.batches.note.content %}{% assign note_counter = note_counter | plus: 1 %}{% assign batches_note_num = note_counter %}{% endif -%}
{%- assign files_note_num = 0 %}{% if provider.capabilities.files.note.content %}{% assign note_counter = note_counter | plus: 1 %}{% assign files_note_num = note_counter %}{% endif -%}
{%- assign has_text = false -%}
{%- assign has_agentic = false -%}
{%- assign has_realtime = false -%}
{%- assign has_embeddings = false -%}
{%- assign has_image = false -%}
{%- assign has_audio = false -%}
{%- assign has_video = false -%}
{%- assign has_rerank = false -%}
{%- assign has_batches = false -%}
{%- assign has_files = false -%}
{%- if provider.capabilities.generate.supported %}{% assign has_text = true %}{% endif -%}
{%- if provider.capabilities.agentic.supported %}{% assign has_agentic = true %}{% endif -%}
{%- if provider.capabilities.realtime.supported %}{% assign has_realtime = true %}{% endif -%}
{%- if provider.capabilities.embeddings.supported %}{% assign has_embeddings = true %}{% endif -%}
{%- if provider.capabilities.image.supported %}{% assign has_image = true %}{% endif -%}
{%- if provider.capabilities.audio_speech.supported or provider.capabilities.audio_transcription.supported or provider.capabilities.audio_translation.supported %}{% assign has_audio = true %}{% endif -%}
{%- if provider.capabilities.video.supported %}{% assign has_video = true %}{% endif -%}
{%- if provider.capabilities.rerank.supported %}{% assign has_rerank = true %}{% endif -%}
{%- if provider.capabilities.batches.supported %}{% assign has_batches = true %}{% endif -%}
{%- if provider.capabilities.files.supported %}{% assign has_files = true %}{% endif -%}

## Supported capabilities

The following tables show the AI capabilities supported by the {{ provider.name }} provider when configuring [AI Models](/ai-gateway/entities/ai-model/).

{:.info}
> By default, {{site.ai_gateway}} uses the path templates shown in the tables below (e.g., `/chat/completions`, `/embeddings`, etc.). To customize these paths, configure the `config.paths` field in your [AI Model](/ai-gateway/entities/ai-model/) entity. Custom paths take the form `{configured_path}/{template_path}` — for example, if you set a custom path of `/v2`, requests to `/embeddings` would be routed to `/v2/embeddings`.

{% if has_text %}

### Text generation

Support for {{ provider.name }} text generation capabilities:

{% table %}
vertical_align: middle
columns:
  - title: Capability
    key: capability
  - title: Streaming
    key: streaming
  - title: Model example
    key: model_example
  - title: Path template
    key: path_template
  - title: Min version
    key: min_version
rows:
{% if provider.capabilities.generate %}
  - capability: "generate{% if generate_note_num != 0 %}<sup>{{ generate_note_num }}</sup>{% endif %}"
    streaming: {{ provider.capabilities.generate.streaming  }}
    model_example: "{{ provider.capabilities.generate.model_example }}"
    path_template: "`/chat/completions`, `/completions`, or `/responses`"
    min_version: "{{ provider.capabilities.generate.min_version }}"
{% endif %}
{% endtable %}
{% if provider.capabilities.generate.note.content %}<sup>{{ generate_note_num }}</sup> {{ provider.capabilities.generate.note.content }}{% endif %}
{%- endif -%}

{% if has_embeddings %}

### Embeddings

Support for {{ provider.name }} embeddings generation:

{% table %}
vertical_align: middle
columns:
  - title: Capability
    key: capability
  - title: Model example
    key: model_example
  - title: Path template
    key: path_template
  - title: Min version
    key: min_version
rows:
{% if provider.capabilities.embeddings %}
  - capability: "embeddings{% if embeddings_note_num != 0 %}<sup>{{ embeddings_note_num }}</sup>{% endif %}"
    model_example: "{{ provider.capabilities.embeddings.model_example }}"
    path_template: "`/embeddings`"
    min_version: "{{ provider.capabilities.embeddings.min_version }}"
{% endif %}
{% endtable %}
{% if provider.capabilities.embeddings.note.content %}<sup>{{ embeddings_note_num }}</sup> {{ provider.capabilities.embeddings.note.content }}{% endif %}
{%- endif -%}

{% if has_agentic %}

### Agentic

Support for {{ provider.name }} agent and assistant capabilities:

{% table %}
vertical_align: middle
columns:
  - title: Capability
    key: capability
  - title: Model example
    key: model_example
  - title: Path template
    key: path_template
  - title: Min version
    key: min_version
rows:
{% if provider.capabilities.agentic %}
  - capability: "agentic{% if agentic_note_num != 0 %}<sup>{{ agentic_note_num }}</sup>{% endif %}"
    model_example: "{{ provider.capabilities.agentic.model_example }}"
    path_template: "`/assistants` or `/responses`"
    min_version: "{{ provider.capabilities.agentic.min_version }}"
{% endif %}
{% endtable %}
{% if provider.capabilities.agentic.note.content %}<sup>{{ agentic_note_num }}</sup> {{ provider.capabilities.agentic.note.content }}{% endif %}
{%- endif -%}

{% if has_audio %}

### Audio

Support for {{ provider.name }} audio capabilities (speech synthesis, transcription, and translation):

{% table %}
vertical_align: middle
columns:
  - title: Capability
    key: capability
  - title: Model example
    key: model_example
  - title: Path template
    key: path_template
  - title: Min version
    key: min_version
rows:
{% if provider.capabilities.audio_speech %}
  - capability: "speech{% if audio_speech_note_num != 0 %}<sup>{{ audio_speech_note_num }}</sup>{% endif %}"
    model_example: "{{ provider.capabilities.audio_speech.model_example }}"
    path_template: "`/audio/speech`"
    min_version: "{{ provider.capabilities.audio_speech.min_version }}"
{% endif %}
{% if provider.capabilities.audio_transcription %}
  - capability: "transcription{% if audio_transcription_note_num != 0 %}<sup>{{ audio_transcription_note_num }}</sup>{% endif %}"
    model_example: "{{ provider.capabilities.audio_transcription.model_example }}"
    path_template: "`/audio/transcriptions`"
    min_version: "{{ provider.capabilities.audio_transcription.min_version }}"
{% endif %}
{% if provider.capabilities.audio_translation %}
  - capability: "translation{% if audio_translation_note_num != 0 %}<sup>{{ audio_translation_note_num }}</sup>{% endif %}"
    model_example: "{{ provider.capabilities.audio_translation.model_example }}"
    path_template: "`/audio/translations`"
    min_version: "{{ provider.capabilities.audio_translation.min_version }}"
{% endif %}
{% endtable %}

{:.info}
> For requests with large payloads, consider increasing `config.max_request_body_size` to three times the raw binary size.
>
> Supported audio formats, voices, and parameters vary by model. Refer to your provider's documentation for available options.

{% if provider.capabilities.audio_speech.note.content %}<sup>{{ audio_speech_note_num }}</sup> {{ provider.capabilities.audio_speech.note.content }}{% endif %}
{% if provider.capabilities.audio_transcription.note.content %}<sup>{{ audio_transcription_note_num }}</sup> {{ provider.capabilities.audio_transcription.note.content }}{% endif %}
{% if provider.capabilities.audio_translation.note.content %}<sup>{{ audio_translation_note_num }}</sup> {{ provider.capabilities.audio_translation.note.content }}{% endif %}
{%- endif -%}

{% if has_image %}

### Image

Support for {{ provider.name }} image generation and editing capabilities:

{% table %}
vertical_align: middle
columns:
  - title: Capability
    key: capability
  - title: Model example
    key: model_example
  - title: Path template
    key: path_template
  - title: Min version
    key: min_version
rows:
{% if provider.capabilities.image %}
  - capability: "image{% if image_note_num != 0 %}<sup>{{ image_note_num }}</sup>{% endif %}"
    model_example: "{{ provider.capabilities.image.model_example }}"
    path_template: "`/images/generations` or `/images/edits`"
    min_version: "{{ provider.capabilities.image.min_version }}"
{% endif %}
{% endtable %}

{:.info}
> For requests with large payloads, consider increasing `config.max_request_body_size` to three times the raw binary size.
>
> Supported image sizes and formats vary by model. Refer to your provider's documentation for allowed dimensions and requirements.

{% if provider.capabilities.image.note.content %}<sup>{{ image_note_num }}</sup> {{ provider.capabilities.image.note.content }}{% endif %}
{%- endif -%}

{% if has_video %}

### Video

Support for {{ provider.name }} video generation capabilities:

{% table %}
vertical_align: middle
columns:
  - title: Capability
    key: capability
  - title: Model example
    key: model_example
  - title: Path template
    key: path_template
  - title: Min version
    key: min_version
rows:
{% if provider.capabilities.video %}
  - capability: "video{% if video_note_num != 0 %}<sup>{{ video_note_num }}</sup>{% endif %}"
    model_example: "{{ provider.capabilities.video.model_example }}"
    path_template: "`/videos`"
    min_version: "{{ provider.capabilities.video.min_version }}"
{% endif %}
{% endtable %}

{:.info}
> For requests with large payloads (video generation), consider increasing `config.max_request_body_size` to three times the raw binary size.

{% if provider.capabilities.video.note.content %}<sup>{{ video_note_num }}</sup> {{ provider.capabilities.video.note.content }}{% endif %}
{%- endif -%}

{% if has_realtime %}

### Realtime

Support for {{ provider.name }}'s bidirectional streaming for realtime applications:

{:.warning}
> Realtime processing uses WebSocket protocol (ws/wss). Configure the protocols on both the Service and Route where the AI model is associated.

{% table %}
vertical_align: middle
columns:
  - title: Capability
    key: capability
  - title: Model example
    key: model_example
  - title: Path template
    key: path_template
  - title: Min version
    key: min_version
rows:
{% if provider.capabilities.realtime %}
  - capability: "realtime{% if realtime_note_num != 0 %}<sup>{{ realtime_note_num }}</sup>{% endif %}"
    model_example: "{{ provider.capabilities.realtime.model_example }}"
    path_template: "`/realtime`"
    min_version: "{{ provider.capabilities.realtime.min_version }}"
{% endif %}
{% endtable %}
{% if provider.capabilities.realtime.note.content %}<sup>{{ realtime_note_num }}</sup> {{ provider.capabilities.realtime.note.content }}{% endif %}
{%- endif -%}

{% if has_batches %}

### Batches

Support for {{ provider.name }} batch processing capabilities:

{% table %}
vertical_align: middle
columns:
  - title: Capability
    key: capability
  - title: Model example
    key: model_example
  - title: Path template
    key: path_template
  - title: Min version
    key: min_version
rows:
{% if provider.capabilities.batches %}
  - capability: "batches{% if batches_note_num != 0 %}<sup>{{ batches_note_num }}</sup>{% endif %}"
    model_example: "{{ provider.capabilities.batches.model_example }}"
    path_template: "`/batches`"
    min_version: "{{ provider.capabilities.batches.min_version }}"
{% endif %}
{% endtable %}
{% if provider.capabilities.batches.note.content %}<sup>{{ batches_note_num }}</sup> {{ provider.capabilities.batches.note.content }}{% endif %}
{%- endif -%}

{% if has_files %}

### Files

Support for {{ provider.name }} file management capabilities:

{% table %}
vertical_align: middle
columns:
  - title: Capability
    key: capability
  - title: Model example
    key: model_example
  - title: Path template
    key: path_template
  - title: Min version
    key: min_version
rows:
{% if provider.capabilities.files %}
  - capability: "files{% if files_note_num != 0 %}<sup>{{ files_note_num }}</sup>{% endif %}"
    model_example: "{{ provider.capabilities.files.model_example }}"
    path_template: "`/files`"
    min_version: "{{ provider.capabilities.files.min_version }}"
{% endif %}
{% endtable %}
{% if provider.capabilities.files.note.content %}<sup>{{ files_note_num }}</sup> {{ provider.capabilities.files.note.content }}{% endif %}
{%- endif -%}

{% if has_rerank %}

### Rerank

Support for {{ provider.name }} reranking capabilities:

{% table %}
vertical_align: middle
columns:
  - title: Capability
    key: capability
  - title: Model example
    key: model_example
  - title: Path template
    key: path_template
  - title: Min version
    key: min_version
rows:
{% if provider.capabilities.rerank %}
  - capability: "rerank{% if rerank_note_num != 0 %}<sup>{{ rerank_note_num }}</sup>{% endif %}"
    model_example: "{{ provider.capabilities.rerank.model_example }}"
    path_template: "`/rerank`"
    min_version: "{{ provider.capabilities.rerank.min_version }}"
{% endif %}
{% endtable %}
{% if provider.capabilities.rerank.note.content %}<sup>{{ rerank_note_num }}</sup> {{ provider.capabilities.rerank.note.content }}{% endif %}
{%- endif -%}

## {{ provider.name }} base URL

{% if provider.url_is_variable %}
The base URL is <code>{{ provider.url_patterns.first }}</code>, where `{capability_path}` is determined by the AI capability.
{% elsif provider.url_patterns.size > 1 %}
The base URL is {% for url in provider.url_patterns %}<code>{{ url }}</code>{% unless forloop.last %} or {% endunless %}{% endfor %}, where `{capability_path}` is determined by the AI capability.
{% else %}
The base URL is `{{ provider.url_patterns.first }}`, where `{capability_path}` is determined by the AI capability.
{% endif %}

{{site.ai_gateway}} uses this URL automatically. You only need to configure a URL if you're using a self-hosted or {{ provider.name }}-compatible endpoint, in which case set the `upstream_url` provider option.

{% else %}
Provider "{{ include.provider_name }}" not found.
{% endif %}
