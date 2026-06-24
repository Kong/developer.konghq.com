{%- assign provider = include.providers.providers | where: "name", include.provider_name | first -%}
{% if provider %}
You can proxy requests to {{ provider.name }} AI models through {{site.ai_gateway}} using the [AI Proxy](/plugins/ai-proxy/) and [AI Proxy Advanced](/plugins/ai-proxy-advanced/) plugins. This reference documents all supported AI capabilities, configuration requirements, and provider-specific details needed for proper integration.

## Upstream paths

{{site.ai_gateway}} automatically routes requests to the appropriate {{ provider.name }} API endpoints. The following table shows the upstream paths used for each capability.

{% table %}
vertical_align: middle
columns:
  - title: Capability
    key: capability
  - title: Upstream path or API
    key: upstream_path
rows:
{% if provider.chat.supported %}
  - capability: "{% if page.output_format == 'markdown' %}Chat completions{% else %}[Chat completions](#text-generation){% endif %}"
    upstream_path: "{{ provider.chat.upstream_path }}"
{% endif %}
{% if provider.completions.supported %}
  - capability: "{% if page.output_format == 'markdown' %}Completions{% else %}[Completions](#text-generation){% endif %}"
    upstream_path: "{{ provider.completions.upstream_path }}"
{% endif %}
{% if provider.embeddings.supported %}
  - capability: "{% if page.output_format == 'markdown' %}Embeddings{% else %}[Embeddings](#text-generation){% endif %}"
    upstream_path: "{{ provider.embeddings.upstream_path }}"
{% endif %}
{% if provider.function_calling.supported %}
  - capability: "{% if page.output_format == 'markdown' %}Function calling{% else %}[Function calling](#advanced-text-generation){% endif %}"
    upstream_path: "{{ provider.function_calling.upstream_path }}"
{% endif %}
{% if provider.files.supported %}
  - capability: "{% if page.output_format == 'markdown' %}Files{% else %}[Files](#processing){% endif %}"
    upstream_path: "{{ provider.files.upstream_path }}"
{% endif %}
{% if provider.batches.supported %}
  - capability: "{% if page.output_format == 'markdown' %}Batches{% else %}[Batches](#processing){% endif %}"
    upstream_path: "{{ provider.batches.upstream_path }}"
{% endif %}
{% if provider.assistants.supported %}
  - capability: "{% if page.output_format == 'markdown' %}Assistants{% else %}[Assistants](#processing){% endif %}"
    upstream_path: "{{ provider.assistants.upstream_path }}"
{% endif %}
{% if provider.responses.supported %}
  - capability: "{% if page.output_format == 'markdown' %}Responses{% else %}[Responses](#processing){% endif %}"
    upstream_path: "{{ provider.responses.upstream_path }}"
{% endif %}
{% if provider.audio.speech.supported %}
  - capability: "{% if page.output_format == 'markdown' %}Speech{% else %}[Speech](#audio){% endif %}"
    upstream_path: "{{ provider.audio.speech.upstream_path }}"
{% endif %}
{% if provider.audio.transcriptions.supported %}
  - capability: "{% if page.output_format == 'markdown' %}Transcriptions{% else %}[Transcriptions](#audio){% endif %}"
    upstream_path: "{{ provider.audio.transcriptions.upstream_path }}"
{% endif %}
{% if provider.audio.translations.supported %}
  - capability: "{% if page.output_format == 'markdown' %}Translations{% else %}[Translations](#audio){% endif %}"
    upstream_path: "{{ provider.audio.translations.upstream_path }}"
{% endif %}
{% if provider.image.generations.supported %}
  - capability: "{% if page.output_format == 'markdown' %}Image generations{% else %}[Image generations](#image){% endif %}"
    upstream_path: "{{ provider.image.generations.upstream_path }}"
{% endif %}
{% if provider.image.edits.supported %}
  - capability: "{% if page.output_format == 'markdown' %}Image edits{% else %}[Image edits](#image){% endif %}"
    upstream_path: "{{ provider.image.edits.upstream_path }}"
{% endif %}
{% if provider.video.generations.supported %}
  - capability: "{% if page.output_format == 'markdown' %}Video generations{% else %}[Video generations](#video){% endif %}"
    upstream_path: "{{ provider.video.generations.upstream_path }}"
{% endif %}
{% if provider.realtime.supported %}
  - capability: "{% if page.output_format == 'markdown' %}Realtime{% else %}[Realtime](#realtime){% endif %}"
    upstream_path: "{{ provider.realtime.upstream_path }}"
{% endif %}
{% endtable %}

{%- assign note_counter = 0 -%}
{%- assign chat_note_num = 0 %}{% if provider.chat.note.content %}{% assign note_counter = note_counter | plus: 1 %}{% assign chat_note_num = note_counter %}{% endif -%}
{%- assign completions_note_num = 0 %}{% if provider.completions.note.content %}{% assign note_counter = note_counter | plus: 1 %}{% assign completions_note_num = note_counter %}{% endif -%}
{%- assign embeddings_note_num = 0 %}{% if provider.embeddings.note.content %}{% assign note_counter = note_counter | plus: 1 %}{% assign embeddings_note_num = note_counter %}{% endif -%}
{%- assign function_calling_note_num = 0 %}{% if provider.function_calling.note.content %}{% assign note_counter = note_counter | plus: 1 %}{% assign function_calling_note_num = note_counter %}{% endif -%}
{%- assign files_note_num = 0 %}{% if provider.files.note.content %}{% assign note_counter = note_counter | plus: 1 %}{% assign files_note_num = note_counter %}{% endif -%}
{%- assign batches_note_num = 0 %}{% if provider.batches.note.content %}{% assign note_counter = note_counter | plus: 1 %}{% assign batches_note_num = note_counter %}{% endif -%}
{%- assign assistants_note_num = 0 %}{% if provider.assistants.note.content %}{% assign note_counter = note_counter | plus: 1 %}{% assign assistants_note_num = note_counter %}{% endif -%}
{%- assign responses_note_num = 0 %}{% if provider.responses.note.content %}{% assign note_counter = note_counter | plus: 1 %}{% assign responses_note_num = note_counter %}{% endif -%}
{%- assign audio_speech_note_num = 0 %}{% if provider.audio.speech.note.content %}{% assign note_counter = note_counter | plus: 1 %}{% assign audio_speech_note_num = note_counter %}{% endif -%}
{%- assign audio_transcriptions_note_num = 0 %}{% if provider.audio.transcriptions.note.content %}{% assign note_counter = note_counter | plus: 1 %}{% assign audio_transcriptions_note_num = note_counter %}{% endif -%}
{%- assign audio_translations_note_num = 0 %}{% if provider.audio.translations.note.content %}{% assign note_counter = note_counter | plus: 1 %}{% assign audio_translations_note_num = note_counter %}{% endif -%}
{%- assign image_generations_note_num = 0 %}{% if provider.image.generations.note.content %}{% assign note_counter = note_counter | plus: 1 %}{% assign image_generations_note_num = note_counter %}{% endif -%}
{%- assign image_edits_note_num = 0 %}{% if provider.image.edits.note.content %}{% assign note_counter = note_counter | plus: 1 %}{% assign image_edits_note_num = note_counter %}{% endif -%}
{%- assign video_generations_note_num = 0 %}{% if provider.video.generations.note.content %}{% assign note_counter = note_counter | plus: 1 %}{% assign video_generations_note_num = note_counter %}{% endif -%}
{%- assign realtime_note_num = 0 %}{% if provider.realtime.note.content %}{% assign note_counter = note_counter | plus: 1 %}{% assign realtime_note_num = note_counter %}{% endif -%}
{%- assign has_text = false -%}
{%- assign has_advanced_text = false -%}
{%- assign has_processing = false -%}
{%- assign has_audio = false -%}
{%- assign has_image = false -%}
{%- assign has_video = false -%}
{%- assign has_realtime = false -%}
{%- if provider.chat.supported or provider.completions.supported or provider.embeddings.supported %}{% assign has_text = true %}{% endif -%}
{%- if provider.function_calling.supported %}{% assign has_advanced_text = true %}{% endif -%}
{%- if provider.files.supported or provider.batches.supported or provider.assistants.supported or provider.responses.supported %}{% assign has_processing = true %}{% endif -%}
{%- if provider.audio.speech.supported or provider.audio.transcriptions.supported or provider.audio.translations.supported %}{% assign has_audio = true %}{% endif -%}
{%- if provider.image.generations.supported or provider.image.edits.supported %}{% assign has_image = true %}{% endif -%}
{%- if provider.video.generations.supported %}{% assign has_video = true %}{% endif -%}
{%- if provider.realtime.supported %}{% assign has_realtime = true %}{% endif -%}

## Supported capabilities

The following tables show the AI capabilities supported by {{ provider.name }} provider when used with the [AI Proxy](/plugins/ai-proxy/) or the [AI Proxy Advanced](/plugins/ai-proxy-advanced/) plugin.

{:.info}
> Set the plugin's [`route_type`](/plugins/ai-proxy/reference/#schema--config-route-type) based on the capability you want to use. See the tables below for supported route types.

{% if has_text %}

### Text generation

Support for {{ provider.name }} basic text generation capabilities including chat, completions, and embeddings:

{% table %}
vertical_align: middle
columns:
  - title: Capability
    key: capability
  - title: Route type
    key: route_type
  - title: Streaming
    key: streaming
  - title: Model example
    key: model_example
  - title: Min version
    key: min_version
rows:
{% if provider.chat.supported %}
  - capability: "Chat completions{% if chat_note_num != 0 %}<sup>{{ chat_note_num }}</sup>{% endif %}"
    route_type: "`{{ provider.chat.route_type }}`"
    streaming: {{ provider.chat.streaming  }}
    model_example: "{{ provider.chat.model_example }}"
    min_version: "{{ provider.chat.min_version }}"
{% endif %}
{% if provider.completions.supported %}
  - capability: "Completions{% if completions_note_num != 0 %}<sup>{{ completions_note_num }}</sup>{% endif %}"
    route_type: "`{{ provider.completions.route_type }}`"
    streaming: {{ provider.completions.streaming  }}
    model_example: "{{ provider.completions.model_example }}"
    min_version: "{{ provider.completions.min_version }}"
{% endif %}
{% if provider.embeddings.supported %}
  - capability: "Embeddings{% if embeddings_note_num != 0 %}<sup>{{ embeddings_note_num }}</sup>{% endif %}"
    route_type: "`{{ provider.embeddings.route_type }}`"
    streaming: {{ provider.embeddings.streaming  }}
    model_example: "{{ provider.embeddings.model_example }}"
    min_version: "{{ provider.embeddings.min_version }}"
{% endif %}
{% endtable %}
{% if provider.chat.note.content %}<sup>{{ chat_note_num }}</sup> {{ provider.chat.note.content }}{% endif %}
{% if provider.completions.note.content %}<sup>{{ completions_note_num }}</sup> {{ provider.completions.note.content }}{% endif %}
{% if provider.embeddings.note.content %}<sup>{{ embeddings_note_num }}</sup> {{ provider.embeddings.note.content }}{% endif %}
{%- endif -%}
{% if has_advanced_text %}

### Advanced text generation

Support for {{ provider.name }} function calling to allow {{ provider.name }} models to use external tools and APIs:

{% table %}
vertical_align: middle
columns:
  - title: Capability
    key: capability
  - title: Route type
    key: route_type
  - title: Model example
    key: model_example
  - title: Min version
    key: min_version
rows:
{% if provider.function_calling.supported %}
  - capability: "Function calling{% if function_calling_note_num != 0 %}<sup>{{ function_calling_note_num }}</sup>{% endif %}"
    route_type: "`{{ provider.function_calling.route_type }}`"
    model_example: "{{ provider.function_calling.model_example }}"
    min_version: "{{ provider.function_calling.min_version }}"
{% endif %}
{% endtable %}
{% if provider.function_calling.note.content %}<sup>{{ function_calling_note_num }}</sup> {{ provider.function_calling.note.content }}{% endif %}
{%- endif -%}
{% if has_processing %}

### Processing

Support for {{ provider.name }} file operations, batch operations, assistants, and response handling:

{% table %}
vertical_align: middle
columns:
  - title: Capability
    key: capability
  - title: Route type
    key: route_type
  - title: Model example
    key: model_example
  - title: Min version
    key: min_version
rows:
{% if provider.files.supported %}
  - capability: "Files{% if files_note_num != 0 %}<sup>{{ files_note_num }}</sup>{% endif %}"
    route_type: "`{{ provider.files.route_type }}`"
    model_example: "{{ provider.files.model_example }}"
    min_version: "{{ provider.files.min_version }}"
{% endif %}
{% if provider.batches.supported %}
  - capability: "Batches{% if batches_note_num != 0 %}<sup>{{ batches_note_num }}</sup>{% endif %}"
    route_type: "`{{ provider.batches.route_type }}`"
    model_example: "{{ provider.batches.model_example }}"
    min_version: "{{ provider.batches.min_version }}"
{% endif %}
{% if provider.assistants.supported %}
  - capability: "Assistants{% if assistants_note_num != 0 %}<sup>{{ assistants_note_num }}</sup>{% endif %}"
    route_type: "`{{ provider.assistants.route_type }}`"
    model_example: "{{ provider.assistants.model_example }}"
    min_version: "{{ provider.assistants.min_version }}"
{% endif %}
{% if provider.responses.supported %}
  - capability: "Responses{% if responses_note_num != 0 %}<sup>{{ responses_note_num }}</sup>{% endif %}"
    route_type: "`{{ provider.responses.route_type }}`"
    model_example: "{{ provider.responses.model_example }}"
    min_version: "{{ provider.responses.min_version }}"
{% endif %}
{% endtable %}
{% if provider.files.note.content %}
<sup>{{ files_note_num }}</sup> {{ provider.files.note.content }}{% endif %}
{% if provider.batches.note.content %}
<sup>{{ batches_note_num }}</sup> {{ provider.batches.note.content }}{% endif %}
{% if provider.assistants.note.content %}
<sup>{{ assistants_note_num }}</sup> {{ provider.assistants.note.content }}{% endif %}
{% if provider.responses.note.content %}
<sup>{{ responses_note_num }}</sup> {{ provider.responses.note.content }}{% endif %}
{%- endif -%}
{% if has_audio %}

### Audio

Support for {{ provider.name }} text-to-speech, transcription, and translation capabilities:

{% table %}
vertical_align: middle
columns:
  - title: Capability
    key: capability
  - title: Route type
    key: route_type
  - title: Model example
    key: model_example
  - title: Min version
    key: min_version
rows:
{% if provider.audio.speech.supported %}
  - capability: "Speech{% if audio_speech_note_num != 0 %}<sup>{{ audio_speech_note_num }}</sup>{% endif %}"
    route_type: "`{{ provider.audio.speech.route_type }}`"
    model_example: "{{ provider.audio.speech.model_example }}"
    min_version: "{{ provider.audio.speech.min_version }}"
{% endif %}
{% if provider.audio.transcriptions.supported %}
  - capability: "Transcriptions{% if audio_transcriptions_note_num != 0 %}<sup>{{ audio_transcriptions_note_num }}</sup>{% endif %}"
    route_type: "`{{ provider.audio.transcriptions.route_type }}`"
    model_example: "{{ provider.audio.transcriptions.model_example }}"
    min_version: "{{ provider.audio.transcriptions.min_version }}"
{% endif %}
{% if provider.audio.translations.supported %}
  - capability: "Translations{% if audio_translations_note_num != 0 %}<sup>{{ audio_translations_note_num }}</sup>{% endif %}"
    route_type: "`{{ provider.audio.translations.route_type }}`"
    model_example: "{{ provider.audio.translations.model_example }}"
    min_version: "{{ provider.audio.translations.min_version }}"
{% endif %}
{% endtable %}

{:.info}
> For requests with large payloads, consider increasing `config.max_request_body_size` to three times the raw binary size.
>
> Supported audio formats, voices, and parameters vary by model. Refer to your provider's documentation for available options.

{% if provider.audio.speech.note.content %}<sup>{{ audio_speech_note_num }}</sup> {{ provider.audio.speech.note.content }}{% endif %}
{% if provider.audio.transcriptions.note.content %}<sup>{{ audio_transcriptions_note_num }}</sup> {{ provider.audio.transcriptions.note.content }}{% endif %}
{% if provider.audio.translations.note.content %}<sup>{{ audio_translations_note_num }}</sup> {{ provider.audio.translations.note.content }}{% endif %}
{%- endif -%}
{% if has_image %}

### Image

Support for {{ provider.name }} image generation and editing capabilities:

{% table %}
vertical_align: middle
columns:
  - title: Capability
    key: capability
  - title: Route type
    key: route_type
  - title: Model example
    key: model_example
  - title: Min version
    key: min_version
rows:
{% if provider.image.generations.supported %}
  - capability: "Generations{% if image_generations_note_num != 0 %}<sup>{{ image_generations_note_num }}</sup>{% endif %}"
    route_type: "`{{ provider.image.generations.route_type }}`"
    model_example: "{{ provider.image.generations.model_example }}"
    min_version: "{{ provider.image.generations.min_version }}"
{% endif %}
{% if provider.image.edits.supported %}
  - capability: "Edits{% if image_edits_note_num != 0 %}<sup>{{ image_edits_note_num }}</sup>{% endif %}"
    route_type: "`{{ provider.image.edits.route_type }}`"
    model_example: "{{ provider.image.edits.model_example }}"
    min_version: "{{ provider.image.edits.min_version }}"
{% endif %}
{% endtable %}

{:.info}
> For requests with large payloads, consider increasing `config.max_request_body_size` to three times the raw binary size.
>
> Supported image sizes and formats vary by model. Refer to your provider's documentation for allowed dimensions and requirements.

{% if provider.image.generations.note.content %}<sup>{{ image_generations_note_num }}</sup> {{ provider.image.generations.note.content }}{% endif %}
{% if provider.image.edits.note.content %}<sup>{{ image_edits_note_num }}</sup> {{ provider.image.edits.note.content }}{% endif %}
{%- endif -%}
{% if has_video %}

### Video

Support for {{ provider.name }} video generation capabilities:

{% table %}
vertical_align: middle
columns:
  - title: Capability
    key: capability
  - title: Route type
    key: route_type
  - title: Model example
    key: model_example
  - title: Min version
    key: min_version
rows:
{% if provider.video.generations.supported %}
  - capability: "Generations{% if video_generations_note_num != 0 %}<sup>{{ video_generations_note_num }}</sup>{% endif %}"
    route_type: "`{{ provider.video.generations.route_type }}`"
    model_example: "{{ provider.video.generations.model_example }}"
    min_version: "{{ provider.video.generations.min_version }}"
{% endif %}
{% endtable %}

{:.info}
> For requests with large payloads (video generation), consider increasing `config.max_request_body_size` to three times the raw binary size.

{% if provider.video.generations.note.content %}<sup>{{ video_generations_note_num }}</sup> {{ provider.video.generations.note.content }}{% endif %}
{%- endif -%}
{% if has_realtime %}

### Realtime

Support for {{ provider.name }}'s bidirectional streaming for realtime applications:

{:.warning}
> Realtime processing requires the [AI Proxy Advanced](/plugins/ai-proxy-advanced/) plugin and uses WebSocket protocol.
>
> To use the realtime route, you must configure the protocols `ws` and/or `wss` on both the Service and on the Route where the plugin is associated.

{% table %}
vertical_align: middle
columns:
  - title: Capability
    key: capability
  - title: Route type
    key: route_type
  - title: Model example
    key: model_example
  - title: Min version
    key: min_version
rows:
{% if provider.realtime.supported %}
  - capability: "Realtime{% if realtime_note_num != 0 %}<sup>{{ realtime_note_num }}</sup>{% endif %}"
    route_type: "`{{ provider.realtime.route_type }}`"
    model_example: "{{ provider.realtime.model_example }}"
    min_version: "{{ provider.realtime.min_version }}"
{% endif %}
{% endtable %}
{% if provider.realtime.note.content %}<sup>{{ realtime_note_num }}</sup> {{ provider.realtime.note.content }}{% endif %}
{%- endif -%}

## {{ provider.name }} base URL

{% if provider.url_is_variable %}
The base URL is <code>{{ provider.url_patterns.first }}</code>, where `{route_type_path}` is determined by the capability.
{% elsif provider.url_patterns.size > 1 %}
The base URL is {% for url in provider.url_patterns %}<code>{{ url }}</code>{% unless forloop.last %} or {% endunless %}{% endfor %}, where `{route_type_path}` is determined by the capability.
{% else %}
The base URL is `{{ provider.url_patterns.first }}`, where `{route_type_path}` is determined by the capability.
{% endif %}

{{site.ai_gateway}} uses this URL automatically. You only need to configure a URL if you're using a self-hosted or {{ provider.name }}-compatible endpoint, in which case set the `upstream_url` plugin option.

{% else %}
Provider "{{ include.provider_name }}" not found.
{% endif %}