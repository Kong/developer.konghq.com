<!--vale off-->
{%- assign provider = include.providers.providers | where: "name", include.provider_name | first -%}
{%- assign compare_provider = nil -%}
{%- if include.compare_provider_name -%}
  {%- assign compare_provider = include.providers.providers | where: "name", include.compare_provider_name | first -%}
{%- endif -%}
{% if provider %}
{%- assign default_generate_paths = "/chat/completions|/completions|/responses" | split: "|" -%}
{%- assign generate_paths = provider.capabilities.generate.paths -%}
{%- if generate_paths == nil or generate_paths == empty -%}
  {%- assign generate_paths = default_generate_paths -%}
{%- endif -%}
{%- assign generate_paths_size = generate_paths.size -%}
{%- assign generate_paths_display = "" -%}
{%- for p in generate_paths -%}
  {%- if forloop.first -%}
    {%- assign generate_paths_display = "`" | append: p | append: "`" -%}
  {%- elsif forloop.last and generate_paths_size > 2 -%}
    {%- assign generate_paths_display = generate_paths_display | append: ", or `" | append: p | append: "`" -%}
  {%- elsif forloop.last -%}
    {%- assign generate_paths_display = generate_paths_display | append: " or `" | append: p | append: "`" -%}
  {%- else -%}
    {%- assign generate_paths_display = generate_paths_display | append: ", `" | append: p | append: "`" -%}
  {%- endif -%}
{%- endfor -%}
You can proxy requests to {{ provider.name }} AI models through {{site.ai_gateway}} by creating [AI Model Provider](/ai-gateway/entities/ai-model-provider/) and [AI Model](/ai-gateway/entities/ai-model/) entities. This reference documents all supported AI capabilities, configuration requirements, and provider-specific details needed for proper integration.
{% if compare_provider %}
{{site.ai_gateway}} supports both **{{ include.variant_label }}** and **{{ include.compare_variant_label }}**. The following sections cover both variants together and note where their capabilities differ.
{% endif %}

{%- capture generate_label -%}{% if page.output_format == 'markdown' %}Generate{% else %}[Generate](#text-generation){% endif %}{%- endcapture -%}
{%- capture agentic_label -%}{% if page.output_format == 'markdown' %}Agentic{% else %}[Agentic](#agentic){% endif %}{%- endcapture -%}
{%- capture realtime_label -%}{% if page.output_format == 'markdown' %}Realtime{% else %}[Realtime](#realtime){% endif %}{%- endcapture -%}
{%- capture embeddings_label -%}{% if page.output_format == 'markdown' %}Embeddings{% else %}[Embeddings](#embeddings){% endif %}{%- endcapture -%}
{%- capture image_label -%}{% if page.output_format == 'markdown' %}Image{% else %}[Image](#image){% endif %}{%- endcapture -%}
{%- capture audio_speech_label -%}{% if page.output_format == 'markdown' %}Audio speech{% else %}[Audio speech](#audio){% endif %}{%- endcapture -%}
{%- capture audio_transcription_label -%}{% if page.output_format == 'markdown' %}Audio transcription{% else %}[Audio transcription](#audio){% endif %}{%- endcapture -%}
{%- capture audio_translation_label -%}{% if page.output_format == 'markdown' %}Audio translation{% else %}[Audio translation](#audio){% endif %}{%- endcapture -%}
{%- capture video_label -%}{% if page.output_format == 'markdown' %}Video{% else %}[Video](#video){% endif %}{%- endcapture -%}
{%- capture rerank_label -%}{% if page.output_format == 'markdown' %}Rerank{% else %}[Rerank](#rerank){% endif %}{%- endcapture -%}
{%- capture batches_label -%}{% if page.output_format == 'markdown' %}Batches{% else %}[Batches](#batches){% endif %}{%- endcapture -%}
{%- capture files_label -%}{% if page.output_format == 'markdown' %}Files{% else %}[Files](#files){% endif %}{%- endcapture -%}
{%- capture skills_label -%}{% if page.output_format == 'markdown' %}Skills{% else %}[Skills](#skills){% endif %}{%- endcapture -%}

## Upstream paths

{{site.ai_gateway}} automatically routes requests to the appropriate {{ provider.name }} API endpoints. The following table shows the upstream paths used for each capability.

{% table %}
vertical_align: middle
columns:
  - title: Capability
    key: capability
{% if compare_provider %}
  - title: Variant
    key: variant
{% endif %}
  - title: Path template
    key: path_template
  - title: Description
    key: description
  - title: Upstream path or API
    key: upstream_path
rows:
{%- assign all_capability_keys = "generate,agentic,realtime,embeddings,image,audio_speech,audio_transcription,audio_translation,video,rerank,batches,files,skills" | split: "," -%}
{% for cap in all_capability_keys %}
{% assign cap_supported = false %}
{% if provider.capabilities[cap].supported %}{% assign cap_supported = true %}{% endif %}
{% assign cap_supported_compare = false %}
{% if compare_provider.capabilities[cap].supported %}{% assign cap_supported_compare = true %}{% endif %}
{% if cap_supported or cap_supported_compare %}
{% case cap %}
{% when 'generate' %}{% assign cap_label = generate_label %}{% assign cap_path_template = generate_paths_display %}{% assign cap_description = "Text generation for chat completions and responses" %}
{% when 'agentic' %}{% assign cap_label = agentic_label %}{% assign cap_path_template = "`/assistants` or `/responses`" %}{% assign cap_description = "Agent and assistant-based interactions" %}
{% when 'realtime' %}{% assign cap_label = realtime_label %}{% assign cap_path_template = "`/realtime`" %}{% assign cap_description = "Bidirectional streaming for real-time applications" %}
{% when 'embeddings' %}{% assign cap_label = embeddings_label %}{% assign cap_path_template = "`/embeddings`" %}{% assign cap_description = "Vector embeddings from text input" %}
{% when 'image' %}{% assign cap_label = image_label %}{% assign cap_path_template = "`/images/generations` or `/images/edits`" %}{% assign cap_description = "Image generation and editing" %}
{% when 'audio_speech' %}{% assign cap_label = audio_speech_label %}{% assign cap_path_template = "`/audio/speech`" %}{% assign cap_description = "Text-to-speech synthesis" %}
{% when 'audio_transcription' %}{% assign cap_label = audio_transcription_label %}{% assign cap_path_template = "`/audio/transcriptions`" %}{% assign cap_description = "Speech-to-text conversion" %}
{% when 'audio_translation' %}{% assign cap_label = audio_translation_label %}{% assign cap_path_template = "`/audio/translations`" %}{% assign cap_description = "Audio translation between languages" %}
{% when 'video' %}{% assign cap_label = video_label %}{% assign cap_path_template = "`/videos`" %}{% assign cap_description = "Video generation" %}
{% when 'rerank' %}{% assign cap_label = rerank_label %}{% assign cap_path_template = "`/rerank`" %}{% assign cap_description = "Semantic reranking of documents" %}
{% when 'batches' %}{% assign cap_label = batches_label %}{% assign cap_path_template = "`/batches`" %}{% assign cap_description = "Batch processing of requests" %}
{% when 'files' %}{% assign cap_label = files_label %}{% assign cap_path_template = "`/files`" %}{% assign cap_description = "File management and storage" %}
{% when 'skills' %}{% assign cap_label = skills_label %}{% assign cap_path_template = "`/skills`" %}{% assign cap_description = "Manage reusable skill bundles hosted with the provider" %}
{% endcase %}
{% if compare_provider %}
{% if cap_supported and cap_supported_compare %}
{% if provider.capabilities[cap].upstream_path == compare_provider.capabilities[cap].upstream_path %}
  - capability: "{{ cap_label }}"
    variant: "{{ include.variant_label }} & {{ include.compare_variant_label }}"
    path_template: "{{ cap_path_template }}"
    description: "{{ cap_description }}"
    upstream_path: "{{ provider.capabilities[cap].upstream_path }}"
{% else %}
  - capability: "{{ cap_label }}"
    variant: "{{ include.variant_label }}"
    path_template: "{{ cap_path_template }}"
    description: "{{ cap_description }}"
    upstream_path: "{{ provider.capabilities[cap].upstream_path }}"
  - capability: "{{ cap_label }}"
    variant: "{{ include.compare_variant_label }}"
    path_template: "{{ cap_path_template }}"
    description: "{{ cap_description }}"
    upstream_path: "{{ compare_provider.capabilities[cap].upstream_path }}"
{% endif %}
{% elsif cap_supported %}
  - capability: "{{ cap_label }}"
    variant: "{{ include.variant_label }} only"
    path_template: "{{ cap_path_template }}"
    description: "{{ cap_description }}"
    upstream_path: "{{ provider.capabilities[cap].upstream_path }}"
{% else %}
  - capability: "{{ cap_label }}"
    variant: "{{ include.compare_variant_label }} only"
    path_template: "{{ cap_path_template }}"
    description: "{{ cap_description }}"
    upstream_path: "{{ compare_provider.capabilities[cap].upstream_path }}"
{% endif %}
{% else %}
  - capability: "{{ cap_label }}"
    path_template: "{{ cap_path_template }}"
    description: "{{ cap_description }}"
    upstream_path: "{{ provider.capabilities[cap].upstream_path }}"
{% endif %}
{% endif %}
{% endfor %}
{% endtable %}

{%- assign note_counter = 0 -%}
{%- assign generate_note_num = 0 %}{% if provider.capabilities.generate.note.content %}{% assign note_counter = note_counter | plus: 1 %}{% assign generate_note_num = note_counter %}{% endif -%}
{%- assign embeddings_note_num = 0 %}{% if provider.capabilities.embeddings.note.content %}{% assign note_counter = note_counter | plus: 1 %}{% assign embeddings_note_num = note_counter %}{% endif -%}
{%- assign agentic_note_num = 0 %}{% if provider.capabilities.agentic.note.content %}{% assign note_counter = note_counter | plus: 1 %}{% assign agentic_note_num = note_counter %}{% endif -%}
{%- assign audio_speech_note_num = 0 %}{% if provider.capabilities.audio_speech.note.content %}{% assign note_counter = note_counter | plus: 1 %}{% assign audio_speech_note_num = note_counter %}{% endif -%}
{%- assign audio_transcription_note_num = 0 %}{% if provider.capabilities.audio_transcription.note.content %}{% assign note_counter = note_counter | plus: 1 %}{% assign audio_transcription_note_num = note_counter %}{% endif -%}
{%- assign audio_translation_note_num = 0 %}{% if provider.capabilities.audio_translation.note.content %}{% assign note_counter = note_counter | plus: 1 %}{% assign audio_translation_note_num = note_counter %}{% endif -%}
{%- assign image_note_num = 0 %}{% if provider.capabilities.image.note.content %}{% assign note_counter = note_counter | plus: 1 %}{% assign image_note_num = note_counter %}{% endif -%}
{%- assign video_note_num = 0 %}{% if provider.capabilities.video.note.content %}{% assign note_counter = note_counter | plus: 1 %}{% assign video_note_num = note_counter %}{% endif -%}
{%- assign realtime_note_num = 0 %}{% if provider.capabilities.realtime.note.content %}{% assign note_counter = note_counter | plus: 1 %}{% assign realtime_note_num = note_counter %}{% endif -%}
{%- assign batches_note_num = 0 %}{% if provider.capabilities.batches.note.content %}{% assign note_counter = note_counter | plus: 1 %}{% assign batches_note_num = note_counter %}{% endif -%}
{%- assign files_note_num = 0 %}{% if provider.capabilities.files.note.content %}{% assign note_counter = note_counter | plus: 1 %}{% assign files_note_num = note_counter %}{% endif -%}
{%- assign skills_note_num = 0 %}{% if provider.capabilities.skills.note.content %}{% assign note_counter = note_counter | plus: 1 %}{% assign skills_note_num = note_counter %}{% endif -%}
{%- assign rerank_note_num = 0 %}{% if provider.capabilities.rerank.note.content %}{% assign note_counter = note_counter | plus: 1 %}{% assign rerank_note_num = note_counter %}{% endif -%}
{%- assign compare_generate_note_num = 0 %}{% if compare_provider.capabilities.generate.note.content %}{% assign note_counter = note_counter | plus: 1 %}{% assign compare_generate_note_num = note_counter %}{% endif -%}
{%- assign compare_embeddings_note_num = 0 %}{% if compare_provider.capabilities.embeddings.note.content %}{% assign note_counter = note_counter | plus: 1 %}{% assign compare_embeddings_note_num = note_counter %}{% endif -%}
{%- assign compare_agentic_note_num = 0 %}{% if compare_provider.capabilities.agentic.note.content %}{% assign note_counter = note_counter | plus: 1 %}{% assign compare_agentic_note_num = note_counter %}{% endif -%}
{%- assign compare_audio_speech_note_num = 0 %}{% if compare_provider.capabilities.audio_speech.note.content %}{% assign note_counter = note_counter | plus: 1 %}{% assign compare_audio_speech_note_num = note_counter %}{% endif -%}
{%- assign compare_audio_transcription_note_num = 0 %}{% if compare_provider.capabilities.audio_transcription.note.content %}{% assign note_counter = note_counter | plus: 1 %}{% assign compare_audio_transcription_note_num = note_counter %}{% endif -%}
{%- assign compare_audio_translation_note_num = 0 %}{% if compare_provider.capabilities.audio_translation.note.content %}{% assign note_counter = note_counter | plus: 1 %}{% assign compare_audio_translation_note_num = note_counter %}{% endif -%}
{%- assign compare_image_note_num = 0 %}{% if compare_provider.capabilities.image.note.content %}{% assign note_counter = note_counter | plus: 1 %}{% assign compare_image_note_num = note_counter %}{% endif -%}
{%- assign compare_video_note_num = 0 %}{% if compare_provider.capabilities.video.note.content %}{% assign note_counter = note_counter | plus: 1 %}{% assign compare_video_note_num = note_counter %}{% endif -%}
{%- assign compare_realtime_note_num = 0 %}{% if compare_provider.capabilities.realtime.note.content %}{% assign note_counter = note_counter | plus: 1 %}{% assign compare_realtime_note_num = note_counter %}{% endif -%}
{%- assign compare_batches_note_num = 0 %}{% if compare_provider.capabilities.batches.note.content %}{% assign note_counter = note_counter | plus: 1 %}{% assign compare_batches_note_num = note_counter %}{% endif -%}
{%- assign compare_files_note_num = 0 %}{% if compare_provider.capabilities.files.note.content %}{% assign note_counter = note_counter | plus: 1 %}{% assign compare_files_note_num = note_counter %}{% endif -%}
{%- assign compare_skills_note_num = 0 %}{% if compare_provider.capabilities.skills.note.content %}{% assign note_counter = note_counter | plus: 1 %}{% assign compare_skills_note_num = note_counter %}{% endif -%}
{%- assign compare_rerank_note_num = 0 %}{% if compare_provider.capabilities.rerank.note.content %}{% assign note_counter = note_counter | plus: 1 %}{% assign compare_rerank_note_num = note_counter %}{% endif -%}
{%- assign has_text = false -%}
{%- assign has_embeddings = false -%}
{%- assign has_agentic = false -%}
{%- assign has_audio = false -%}
{%- assign has_image = false -%}
{%- assign has_video = false -%}
{%- assign has_realtime = false -%}
{%- assign has_batches = false -%}
{%- assign has_files = false -%}
{%- assign has_skills = false -%}
{%- assign has_rerank = false -%}
{%- if provider.capabilities.generate.supported or compare_provider.capabilities.generate.supported %}{% assign has_text = true %}{% endif -%}
{%- if provider.capabilities.embeddings.supported or compare_provider.capabilities.embeddings.supported %}{% assign has_embeddings = true %}{% endif -%}
{%- if provider.capabilities.agentic.supported or compare_provider.capabilities.agentic.supported %}{% assign has_agentic = true %}{% endif -%}
{%- if provider.capabilities.audio_speech.supported or provider.capabilities.audio_transcription.supported or provider.capabilities.audio_translation.supported or compare_provider.capabilities.audio_speech.supported or compare_provider.capabilities.audio_transcription.supported or compare_provider.capabilities.audio_translation.supported %}{% assign has_audio = true %}{% endif -%}
{%- if provider.capabilities.image.supported or compare_provider.capabilities.image.supported %}{% assign has_image = true %}{% endif -%}
{%- if provider.capabilities.video.supported or compare_provider.capabilities.video.supported %}{% assign has_video = true %}{% endif -%}
{%- if provider.capabilities.realtime.supported or compare_provider.capabilities.realtime.supported %}{% assign has_realtime = true %}{% endif -%}
{%- if provider.capabilities.batches.supported or compare_provider.capabilities.batches.supported %}{% assign has_batches = true %}{% endif -%}
{%- if provider.capabilities.files.supported or compare_provider.capabilities.files.supported %}{% assign has_files = true %}{% endif -%}
{%- if provider.capabilities.skills.supported or compare_provider.capabilities.skills.supported %}{% assign has_skills = true %}{% endif -%}
{%- if provider.capabilities.rerank.supported or compare_provider.capabilities.rerank.supported %}{% assign has_rerank = true %}{% endif -%}

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
{% if compare_provider %}
  - title: Variant
    key: variant
{% endif %}
  - title: Streaming
    key: streaming
  - title: Model example
    key: model_example
  - title: Path template
    key: path_template
  - title: Min version
    key: min_version
rows:
{% if compare_provider %}
{% if provider.capabilities.generate.supported and compare_provider.capabilities.generate.supported %}
{% if provider.capabilities.generate.model_example == compare_provider.capabilities.generate.model_example and provider.capabilities.generate.streaming == compare_provider.capabilities.generate.streaming %}
  - capability: "generate{% if generate_note_num != 0 %}<sup>{{ generate_note_num }}</sup>{% endif %}"
    variant: "{{ include.variant_label }} & {{ include.compare_variant_label }}"
    streaming: {{ provider.capabilities.generate.streaming }}
    model_example: "{{ provider.capabilities.generate.model_example }}"
    path_template: "{{ generate_paths_display }}"
    min_version: "{{ provider.capabilities.generate.min_version }}"
{% else %}
  - capability: "generate{% if generate_note_num != 0 %}<sup>{{ generate_note_num }}</sup>{% endif %}"
    variant: "{{ include.variant_label }}"
    streaming: {{ provider.capabilities.generate.streaming }}
    model_example: "{{ provider.capabilities.generate.model_example }}"
    path_template: "{{ generate_paths_display }}"
    min_version: "{{ provider.capabilities.generate.min_version }}"
  - capability: "generate{% if compare_generate_note_num != 0 %}<sup>{{ compare_generate_note_num }}</sup>{% endif %}"
    variant: "{{ include.compare_variant_label }}"
    streaming: {{ compare_provider.capabilities.generate.streaming }}
    model_example: "{{ compare_provider.capabilities.generate.model_example }}"
    path_template: "{{ generate_paths_display }}"
    min_version: "{{ compare_provider.capabilities.generate.min_version }}"
{% endif %}
{% elsif provider.capabilities.generate.supported %}
  - capability: "generate{% if generate_note_num != 0 %}<sup>{{ generate_note_num }}</sup>{% endif %}"
    variant: "{{ include.variant_label }} only"
    streaming: {{ provider.capabilities.generate.streaming }}
    model_example: "{{ provider.capabilities.generate.model_example }}"
    path_template: "{{ generate_paths_display }}"
    min_version: "{{ provider.capabilities.generate.min_version }}"
{% else %}
  - capability: "generate{% if compare_generate_note_num != 0 %}<sup>{{ compare_generate_note_num }}</sup>{% endif %}"
    variant: "{{ include.compare_variant_label }} only"
    streaming: {{ compare_provider.capabilities.generate.streaming }}
    model_example: "{{ compare_provider.capabilities.generate.model_example }}"
    path_template: "{{ generate_paths_display }}"
    min_version: "{{ compare_provider.capabilities.generate.min_version }}"
{% endif %}
{% elsif provider.capabilities.generate %}
  - capability: "generate{% if generate_note_num != 0 %}<sup>{{ generate_note_num }}</sup>{% endif %}"
    streaming: {{ provider.capabilities.generate.streaming  }}
    model_example: "{{ provider.capabilities.generate.model_example }}"
    path_template: "{{ generate_paths_display }}"
    min_version: "{{ provider.capabilities.generate.min_version }}"
{% endif %}
{% endtable %}
{% if provider.capabilities.generate.note.content %}<sup>{{ generate_note_num }}</sup> {% if compare_provider %}**{{ include.variant_label }}:** {% endif %}{{ provider.capabilities.generate.note.content }}{% endif %}
{% if compare_provider.capabilities.generate.note.content %}<sup>{{ compare_generate_note_num }}</sup> **{{ include.compare_variant_label }}:** {{ compare_provider.capabilities.generate.note.content }}{% endif %}
{%- endif -%}

{% if has_embeddings %}

### Embeddings

Support for {{ provider.name }} embeddings generation:

{% table %}
vertical_align: middle
columns:
  - title: Capability
    key: capability
{% if compare_provider %}
  - title: Variant
    key: variant
{% endif %}
  - title: Model example
    key: model_example
  - title: Path template
    key: path_template
  - title: Min version
    key: min_version
rows:
{% if compare_provider %}
{% if provider.capabilities.embeddings.supported and compare_provider.capabilities.embeddings.supported %}
{% if provider.capabilities.embeddings.model_example == compare_provider.capabilities.embeddings.model_example %}
  - capability: "embeddings{% if embeddings_note_num != 0 %}<sup>{{ embeddings_note_num }}</sup>{% endif %}"
    variant: "{{ include.variant_label }} & {{ include.compare_variant_label }}"
    model_example: "{{ provider.capabilities.embeddings.model_example }}"
    path_template: "`/embeddings`"
    min_version: "{{ provider.capabilities.embeddings.min_version }}"
{% else %}
  - capability: "embeddings{% if embeddings_note_num != 0 %}<sup>{{ embeddings_note_num }}</sup>{% endif %}"
    variant: "{{ include.variant_label }}"
    model_example: "{{ provider.capabilities.embeddings.model_example }}"
    path_template: "`/embeddings`"
    min_version: "{{ provider.capabilities.embeddings.min_version }}"
  - capability: "embeddings{% if compare_embeddings_note_num != 0 %}<sup>{{ compare_embeddings_note_num }}</sup>{% endif %}"
    variant: "{{ include.compare_variant_label }}"
    model_example: "{{ compare_provider.capabilities.embeddings.model_example }}"
    path_template: "`/embeddings`"
    min_version: "{{ compare_provider.capabilities.embeddings.min_version }}"
{% endif %}
{% elsif provider.capabilities.embeddings.supported %}
  - capability: "embeddings{% if embeddings_note_num != 0 %}<sup>{{ embeddings_note_num }}</sup>{% endif %}"
    variant: "{{ include.variant_label }} only"
    model_example: "{{ provider.capabilities.embeddings.model_example }}"
    path_template: "`/embeddings`"
    min_version: "{{ provider.capabilities.embeddings.min_version }}"
{% else %}
  - capability: "embeddings{% if compare_embeddings_note_num != 0 %}<sup>{{ compare_embeddings_note_num }}</sup>{% endif %}"
    variant: "{{ include.compare_variant_label }} only"
    model_example: "{{ compare_provider.capabilities.embeddings.model_example }}"
    path_template: "`/embeddings`"
    min_version: "{{ compare_provider.capabilities.embeddings.min_version }}"
{% endif %}
{% elsif provider.capabilities.embeddings %}
  - capability: "embeddings{% if embeddings_note_num != 0 %}<sup>{{ embeddings_note_num }}</sup>{% endif %}"
    model_example: "{{ provider.capabilities.embeddings.model_example }}"
    path_template: "`/embeddings`"
    min_version: "{{ provider.capabilities.embeddings.min_version }}"
{% endif %}
{% endtable %}
{% if provider.capabilities.embeddings.note.content %}<sup>{{ embeddings_note_num }}</sup> {% if compare_provider %}**{{ include.variant_label }}:** {% endif %}{{ provider.capabilities.embeddings.note.content }}{% endif %}
{% if compare_provider.capabilities.embeddings.note.content %}<sup>{{ compare_embeddings_note_num }}</sup> **{{ include.compare_variant_label }}:** {{ compare_provider.capabilities.embeddings.note.content }}{% endif %}
{%- endif -%}

{% if has_agentic %}

### Agentic

Support for {{ provider.name }} agent and assistant capabilities:

{% table %}
vertical_align: middle
columns:
  - title: Capability
    key: capability
{% if compare_provider %}
  - title: Variant
    key: variant
{% endif %}
  - title: Model example
    key: model_example
  - title: Path template
    key: path_template
  - title: Min version
    key: min_version
rows:
{% if compare_provider %}
{% if provider.capabilities.agentic.supported and compare_provider.capabilities.agentic.supported %}
  - capability: "agentic{% if agentic_note_num != 0 %}<sup>{{ agentic_note_num }}</sup>{% endif %}"
    variant: "{{ include.variant_label }} & {{ include.compare_variant_label }}"
    model_example: "{{ provider.capabilities.agentic.model_example }}"
    path_template: "`/assistants` or `/responses`"
    min_version: "{{ provider.capabilities.agentic.min_version }}"
{% elsif provider.capabilities.agentic.supported %}
  - capability: "agentic{% if agentic_note_num != 0 %}<sup>{{ agentic_note_num }}</sup>{% endif %}"
    variant: "{{ include.variant_label }} only"
    model_example: "{{ provider.capabilities.agentic.model_example }}"
    path_template: "`/assistants` or `/responses`"
    min_version: "{{ provider.capabilities.agentic.min_version }}"
{% else %}
  - capability: "agentic{% if compare_agentic_note_num != 0 %}<sup>{{ compare_agentic_note_num }}</sup>{% endif %}"
    variant: "{{ include.compare_variant_label }} only"
    model_example: "{{ compare_provider.capabilities.agentic.model_example }}"
    path_template: "`/assistants` or `/responses`"
    min_version: "{{ compare_provider.capabilities.agentic.min_version }}"
{% endif %}
{% elsif provider.capabilities.agentic %}
  - capability: "agentic{% if agentic_note_num != 0 %}<sup>{{ agentic_note_num }}</sup>{% endif %}"
    model_example: "{{ provider.capabilities.agentic.model_example }}"
    path_template: "`/assistants` or `/responses`"
    min_version: "{{ provider.capabilities.agentic.min_version }}"
{% endif %}
{% endtable %}
{% if provider.capabilities.agentic.note.content %}<sup>{{ agentic_note_num }}</sup> {% if compare_provider %}**{{ include.variant_label }}:** {% endif %}{{ provider.capabilities.agentic.note.content }}{% endif %}
{% if compare_provider.capabilities.agentic.note.content %}<sup>{{ compare_agentic_note_num }}</sup> **{{ include.compare_variant_label }}:** {{ compare_provider.capabilities.agentic.note.content }}{% endif %}
{%- endif -%}

{% if has_audio %}

### Audio

Support for {{ provider.name }} audio capabilities (speech synthesis, transcription, and translation):

{% table %}
vertical_align: middle
columns:
  - title: Capability
    key: capability
{% if compare_provider %}
  - title: Variant
    key: variant
{% endif %}
  - title: Model example
    key: model_example
  - title: Path template
    key: path_template
  - title: Min version
    key: min_version
rows:
{%- assign audio_capability_keys = "audio_speech,audio_transcription,audio_translation" | split: "," -%}
{% for cap in audio_capability_keys %}
{% assign cap_supported = false %}
{% if provider.capabilities[cap].supported %}{% assign cap_supported = true %}{% endif %}
{% assign cap_supported_compare = false %}
{% if compare_provider.capabilities[cap].supported %}{% assign cap_supported_compare = true %}{% endif %}
{% if cap_supported or cap_supported_compare %}
{% case cap %}
{% when 'audio_speech' %}{% assign cap_short = "speech" %}{% assign cap_path_template = "`/audio/speech`" %}
{% when 'audio_transcription' %}{% assign cap_short = "transcription" %}{% assign cap_path_template = "`/audio/transcriptions`" %}
{% when 'audio_translation' %}{% assign cap_short = "translation" %}{% assign cap_path_template = "`/audio/translations`" %}
{% endcase %}
{% if compare_provider %}
{% if cap_supported and cap_supported_compare %}
  - capability: "{{ cap_short }}"
    variant: "{{ include.variant_label }} & {{ include.compare_variant_label }}"
    model_example: "{{ provider.capabilities[cap].model_example }}"
    path_template: "{{ cap_path_template }}"
    min_version: "{{ provider.capabilities[cap].min_version }}"
{% elsif cap_supported %}
  - capability: "{{ cap_short }}"
    variant: "{{ include.variant_label }} only"
    model_example: "{{ provider.capabilities[cap].model_example }}"
    path_template: "{{ cap_path_template }}"
    min_version: "{{ provider.capabilities[cap].min_version }}"
{% else %}
  - capability: "{{ cap_short }}"
    variant: "{{ include.compare_variant_label }} only"
    model_example: "{{ compare_provider.capabilities[cap].model_example }}"
    path_template: "{{ cap_path_template }}"
    min_version: "{{ compare_provider.capabilities[cap].min_version }}"
{% endif %}
{% else %}
  - capability: "{{ cap_short }}"
    model_example: "{{ provider.capabilities[cap].model_example }}"
    path_template: "{{ cap_path_template }}"
    min_version: "{{ provider.capabilities[cap].min_version }}"
{% endif %}
{% endif %}
{% endfor %}
{% endtable %}

{:.info}
> For requests with large payloads, consider increasing [`config.max_request_body_size`](/ai-gateway/entities/ai-model/#schema-aigateway-model-config-max-request-body-size) on your [AI Model](/ai-gateway/entities/ai-model/) entity to three times the raw binary size.
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
{% if compare_provider %}
  - title: Variant
    key: variant
{% endif %}
  - title: Model example
    key: model_example
  - title: Path template
    key: path_template
  - title: Min version
    key: min_version
rows:
{% if compare_provider %}
{% if provider.capabilities.image.supported and compare_provider.capabilities.image.supported %}
  - capability: "image{% if image_note_num != 0 %}<sup>{{ image_note_num }}</sup>{% endif %}"
    variant: "{{ include.variant_label }} & {{ include.compare_variant_label }}"
    model_example: "{{ provider.capabilities.image.model_example }}"
    path_template: "`/images/generations` or `/images/edits`"
    min_version: "{{ provider.capabilities.image.min_version }}"
{% elsif provider.capabilities.image.supported %}
  - capability: "image{% if image_note_num != 0 %}<sup>{{ image_note_num }}</sup>{% endif %}"
    variant: "{{ include.variant_label }} only"
    model_example: "{{ provider.capabilities.image.model_example }}"
    path_template: "`/images/generations` or `/images/edits`"
    min_version: "{{ provider.capabilities.image.min_version }}"
{% else %}
  - capability: "image{% if compare_image_note_num != 0 %}<sup>{{ compare_image_note_num }}</sup>{% endif %}"
    variant: "{{ include.compare_variant_label }} only"
    model_example: "{{ compare_provider.capabilities.image.model_example }}"
    path_template: "`/images/generations` or `/images/edits`"
    min_version: "{{ compare_provider.capabilities.image.min_version }}"
{% endif %}
{% elsif provider.capabilities.image %}
  - capability: "image{% if image_note_num != 0 %}<sup>{{ image_note_num }}</sup>{% endif %}"
    model_example: "{{ provider.capabilities.image.model_example }}"
    path_template: "`/images/generations` or `/images/edits`"
    min_version: "{{ provider.capabilities.image.min_version }}"
{% endif %}
{% endtable %}

{:.info}
> For requests with large payloads, consider increasing [`config.max_request_body_size`](/ai-gateway/entities/ai-model/#schema-aigateway-model-config-max-request-body-size) on your [AI Model](/ai-gateway/entities/ai-model/) entity to three times the raw binary size.
>
> Supported image sizes and formats vary by model. Refer to your provider's documentation for allowed dimensions and requirements.

{% if provider.capabilities.image.note.content %}<sup>{{ image_note_num }}</sup> {% if compare_provider %}**{{ include.variant_label }}:** {% endif %}{{ provider.capabilities.image.note.content }}{% endif %}
{% if compare_provider.capabilities.image.note.content %}<sup>{{ compare_image_note_num }}</sup> **{{ include.compare_variant_label }}:** {{ compare_provider.capabilities.image.note.content }}{% endif %}
{%- endif -%}

{% if has_video %}

### Video

Support for {{ provider.name }} video generation capabilities:

{% table %}
vertical_align: middle
columns:
  - title: Capability
    key: capability
{% if compare_provider %}
  - title: Variant
    key: variant
{% endif %}
  - title: Model example
    key: model_example
  - title: Path template
    key: path_template
  - title: Min version
    key: min_version
rows:
{% if compare_provider %}
{% if provider.capabilities.video.supported and compare_provider.capabilities.video.supported %}
  - capability: "video{% if video_note_num != 0 %}<sup>{{ video_note_num }}</sup>{% endif %}"
    variant: "{{ include.variant_label }} & {{ include.compare_variant_label }}"
    model_example: "{{ provider.capabilities.video.model_example }}"
    path_template: "`/videos`"
    min_version: "{{ provider.capabilities.video.min_version }}"
{% elsif provider.capabilities.video.supported %}
  - capability: "video{% if video_note_num != 0 %}<sup>{{ video_note_num }}</sup>{% endif %}"
    variant: "{{ include.variant_label }} only"
    model_example: "{{ provider.capabilities.video.model_example }}"
    path_template: "`/videos`"
    min_version: "{{ provider.capabilities.video.min_version }}"
{% else %}
  - capability: "video{% if compare_video_note_num != 0 %}<sup>{{ compare_video_note_num }}</sup>{% endif %}"
    variant: "{{ include.compare_variant_label }} only"
    model_example: "{{ compare_provider.capabilities.video.model_example }}"
    path_template: "`/videos`"
    min_version: "{{ compare_provider.capabilities.video.min_version }}"
{% endif %}
{% elsif provider.capabilities.video %}
  - capability: "video{% if video_note_num != 0 %}<sup>{{ video_note_num }}</sup>{% endif %}"
    model_example: "{{ provider.capabilities.video.model_example }}"
    path_template: "`/videos`"
    min_version: "{{ provider.capabilities.video.min_version }}"
{% endif %}
{% endtable %}

{:.info}
> For requests with large payloads (video generation), consider increasing [`config.max_request_body_size`](/ai-gateway/entities/ai-model/#schema-aigateway-model-config-max-request-body-size) on your [AI Model](/ai-gateway/entities/ai-model/) entity to three times the raw binary size.

{% if provider.capabilities.video.note.content %}<sup>{{ video_note_num }}</sup> {% if compare_provider %}**{{ include.variant_label }}:** {% endif %}{{ provider.capabilities.video.note.content }}{% endif %}
{% if compare_provider.capabilities.video.note.content %}<sup>{{ compare_video_note_num }}</sup> **{{ include.compare_variant_label }}:** {{ compare_provider.capabilities.video.note.content }}{% endif %}
{%- endif -%}

{% if has_realtime %}

### Realtime

Support for {{ provider.name }}'s bidirectional streaming for realtime applications:

{:.info}
> Realtime processing uses WebSocket protocol (ws/wss). This protocol is automatically enabled when you configure your [AI Model](/ai-gateway/entities/ai-model/) with the [realtime capability](/ai-gateway/entities/ai-model/#capabilities).

{% table %}
vertical_align: middle
columns:
  - title: Capability
    key: capability
{% if compare_provider %}
  - title: Variant
    key: variant
{% endif %}
  - title: Model example
    key: model_example
  - title: Path template
    key: path_template
  - title: Min version
    key: min_version
rows:
{% if compare_provider %}
{% if provider.capabilities.realtime.supported and compare_provider.capabilities.realtime.supported %}
  - capability: "realtime{% if realtime_note_num != 0 %}<sup>{{ realtime_note_num }}</sup>{% endif %}"
    variant: "{{ include.variant_label }} & {{ include.compare_variant_label }}"
    model_example: "{{ provider.capabilities.realtime.model_example }}"
    path_template: "`/realtime`"
    min_version: "{{ provider.capabilities.realtime.min_version }}"
{% elsif provider.capabilities.realtime.supported %}
  - capability: "realtime{% if realtime_note_num != 0 %}<sup>{{ realtime_note_num }}</sup>{% endif %}"
    variant: "{{ include.variant_label }} only"
    model_example: "{{ provider.capabilities.realtime.model_example }}"
    path_template: "`/realtime`"
    min_version: "{{ provider.capabilities.realtime.min_version }}"
{% else %}
  - capability: "realtime{% if compare_realtime_note_num != 0 %}<sup>{{ compare_realtime_note_num }}</sup>{% endif %}"
    variant: "{{ include.compare_variant_label }} only"
    model_example: "{{ compare_provider.capabilities.realtime.model_example }}"
    path_template: "`/realtime`"
    min_version: "{{ compare_provider.capabilities.realtime.min_version }}"
{% endif %}
{% elsif provider.capabilities.realtime %}
  - capability: "realtime{% if realtime_note_num != 0 %}<sup>{{ realtime_note_num }}</sup>{% endif %}"
    model_example: "{{ provider.capabilities.realtime.model_example }}"
    path_template: "`/realtime`"
    min_version: "{{ provider.capabilities.realtime.min_version }}"
{% endif %}
{% endtable %}
{% if provider.capabilities.realtime.note.content %}<sup>{{ realtime_note_num }}</sup> {% if compare_provider %}**{{ include.variant_label }}:** {% endif %}{{ provider.capabilities.realtime.note.content }}{% endif %}
{% if compare_provider.capabilities.realtime.note.content %}<sup>{{ compare_realtime_note_num }}</sup> **{{ include.compare_variant_label }}:** {{ compare_provider.capabilities.realtime.note.content }}{% endif %}
{%- endif -%}

{% if has_batches %}

### Batches

Support for {{ provider.name }} batch processing capabilities:

{% table %}
vertical_align: middle
columns:
  - title: Capability
    key: capability
{% if compare_provider %}
  - title: Variant
    key: variant
{% endif %}
  - title: Model example
    key: model_example
  - title: Path template
    key: path_template
  - title: Min version
    key: min_version
rows:
{% if compare_provider %}
{% if provider.capabilities.batches.supported and compare_provider.capabilities.batches.supported %}
  - capability: "batches{% if batches_note_num != 0 %}<sup>{{ batches_note_num }}</sup>{% endif %}"
    variant: "{{ include.variant_label }} & {{ include.compare_variant_label }}"
    model_example: "{{ provider.capabilities.batches.model_example }}"
    path_template: "`/batches`"
    min_version: "{{ provider.capabilities.batches.min_version }}"
{% elsif provider.capabilities.batches.supported %}
  - capability: "batches{% if batches_note_num != 0 %}<sup>{{ batches_note_num }}</sup>{% endif %}"
    variant: "{{ include.variant_label }} only"
    model_example: "{{ provider.capabilities.batches.model_example }}"
    path_template: "`/batches`"
    min_version: "{{ provider.capabilities.batches.min_version }}"
{% else %}
  - capability: "batches{% if compare_batches_note_num != 0 %}<sup>{{ compare_batches_note_num }}</sup>{% endif %}"
    variant: "{{ include.compare_variant_label }} only"
    model_example: "{{ compare_provider.capabilities.batches.model_example }}"
    path_template: "`/batches`"
    min_version: "{{ compare_provider.capabilities.batches.min_version }}"
{% endif %}
{% elsif provider.capabilities.batches %}
  - capability: "batches{% if batches_note_num != 0 %}<sup>{{ batches_note_num }}</sup>{% endif %}"
    model_example: "{{ provider.capabilities.batches.model_example }}"
    path_template: "`/batches`"
    min_version: "{{ provider.capabilities.batches.min_version }}"
{% endif %}
{% endtable %}
{% if provider.capabilities.batches.note.content %}<sup>{{ batches_note_num }}</sup> {% if compare_provider %}**{{ include.variant_label }}:** {% endif %}{{ provider.capabilities.batches.note.content }}{% endif %}
{% if compare_provider.capabilities.batches.note.content %}<sup>{{ compare_batches_note_num }}</sup> **{{ include.compare_variant_label }}:** {{ compare_provider.capabilities.batches.note.content }}{% endif %}
{:.warning}
> Batches are configured on a separate AI Model with `type: "api"`, distinct from regular models that handle synchronous capabilities like generate and embeddings.
> Create a dedicated AI Model exclusively for batches and files, as each model must be either a regular model or an API model, not both.
{%- endif -%}

{% if has_files %}

### Files

Support for {{ provider.name }} file management capabilities:

{% table %}
vertical_align: middle
columns:
  - title: Capability
    key: capability
{% if compare_provider %}
  - title: Variant
    key: variant
{% endif %}
  - title: Model example
    key: model_example
  - title: Path template
    key: path_template
  - title: Min version
    key: min_version
rows:
{% if compare_provider %}
{% if provider.capabilities.files.supported and compare_provider.capabilities.files.supported %}
  - capability: "files{% if files_note_num != 0 %}<sup>{{ files_note_num }}</sup>{% endif %}"
    variant: "{{ include.variant_label }} & {{ include.compare_variant_label }}"
    model_example: "{{ provider.capabilities.files.model_example }}"
    path_template: "`/files`"
    min_version: "{{ provider.capabilities.files.min_version }}"
{% elsif provider.capabilities.files.supported %}
  - capability: "files{% if files_note_num != 0 %}<sup>{{ files_note_num }}</sup>{% endif %}"
    variant: "{{ include.variant_label }} only"
    model_example: "{{ provider.capabilities.files.model_example }}"
    path_template: "`/files`"
    min_version: "{{ provider.capabilities.files.min_version }}"
{% else %}
  - capability: "files{% if compare_files_note_num != 0 %}<sup>{{ compare_files_note_num }}</sup>{% endif %}"
    variant: "{{ include.compare_variant_label }} only"
    model_example: "{{ compare_provider.capabilities.files.model_example }}"
    path_template: "`/files`"
    min_version: "{{ compare_provider.capabilities.files.min_version }}"
{% endif %}
{% elsif provider.capabilities.files %}
  - capability: "files{% if files_note_num != 0 %}<sup>{{ files_note_num }}</sup>{% endif %}"
    model_example: "{{ provider.capabilities.files.model_example }}"
    path_template: "`/files`"
    min_version: "{{ provider.capabilities.files.min_version }}"
{% endif %}
{% endtable %}
{% if provider.capabilities.files.note.content %}<sup>{{ files_note_num }}</sup> {% if compare_provider %}**{{ include.variant_label }}:** {% endif %}{{ provider.capabilities.files.note.content }}{% endif %}
{% if compare_provider.capabilities.files.note.content %}<sup>{{ compare_files_note_num }}</sup> **{{ include.compare_variant_label }}:** {{ compare_provider.capabilities.files.note.content }}{% endif %}

{:.warning}
> Batches are configured on a separate AI Model with [`type: "api"`](/ai-gateway/entities/ai-model/#schema-aigateway-model-type), distinct from regular models that handle synchronous capabilities like generate and embeddings.
> Create a dedicated AI Model exclusively for batches and files, as each model must be either a regular model or an API model, not both.
{%- endif -%}

{% if has_skills %}

### Skills

Support for {{ provider.name }} skills management capabilities:

{% table %}
vertical_align: middle
columns:
  - title: Capability
    key: capability
{% if compare_provider %}
  - title: Variant
    key: variant
{% endif %}
  - title: Model example
    key: model_example
  - title: Path template
    key: path_template
  - title: Min version
    key: min_version
rows:
{% if compare_provider %}
{% if provider.capabilities.skills.supported and compare_provider.capabilities.skills.supported %}
  - capability: "skills{% if skills_note_num != 0 %}<sup>{{ skills_note_num }}</sup>{% endif %}"
    variant: "{{ include.variant_label }} & {{ include.compare_variant_label }}"
    model_example: "{{ provider.capabilities.skills.model_example }}"
    path_template: "`/skills`"
    min_version: "{{ provider.capabilities.skills.min_version }}"
{% elsif provider.capabilities.skills.supported %}
  - capability: "skills{% if skills_note_num != 0 %}<sup>{{ skills_note_num }}</sup>{% endif %}"
    variant: "{{ include.variant_label }} only"
    model_example: "{{ provider.capabilities.skills.model_example }}"
    path_template: "`/skills`"
    min_version: "{{ provider.capabilities.skills.min_version }}"
{% else %}
  - capability: "skills{% if compare_skills_note_num != 0 %}<sup>{{ compare_skills_note_num }}</sup>{% endif %}"
    variant: "{{ include.compare_variant_label }} only"
    model_example: "{{ compare_provider.capabilities.skills.model_example }}"
    path_template: "`/skills`"
    min_version: "{{ compare_provider.capabilities.skills.min_version }}"
{% endif %}
{% elsif provider.capabilities.skills %}
  - capability: "skills{% if skills_note_num != 0 %}<sup>{{ skills_note_num }}</sup>{% endif %}"
    model_example: "{{ provider.capabilities.skills.model_example }}"
    path_template: "`/skills`"
    min_version: "{{ provider.capabilities.skills.min_version }}"
{% endif %}
{% endtable %}
{% if provider.capabilities.skills.note.content %}<sup>{{ skills_note_num }}</sup> {% if compare_provider %}**{{ include.variant_label }}:** {% endif %}{{ provider.capabilities.skills.note.content }}{% endif %}
{% if compare_provider.capabilities.skills.note.content %}<sup>{{ compare_skills_note_num }}</sup> **{{ include.compare_variant_label }}:** {{ compare_provider.capabilities.skills.note.content }}{% endif %}

{:.warning}
> Skills are configured on a separate AI Model with [`type: "api"`](/ai-gateway/entities/ai-model/#schema-aigateway-model-type), distinct from regular models that handle synchronous capabilities like generate and embeddings.
> Create a dedicated AI Model exclusively for batches, files, and skills, as each model must be either a regular model or an API model, not both.
{%- endif -%}

{% if has_rerank %}

### Rerank

Support for {{ provider.name }} reranking capabilities:

{% table %}
vertical_align: middle
columns:
  - title: Capability
    key: capability
{% if compare_provider %}
  - title: Variant
    key: variant
{% endif %}
  - title: Model example
    key: model_example
  - title: Path template
    key: path_template
  - title: Min version
    key: min_version
rows:
{% if compare_provider %}
{% if provider.capabilities.rerank.supported and compare_provider.capabilities.rerank.supported %}
  - capability: "rerank{% if rerank_note_num != 0 %}<sup>{{ rerank_note_num }}</sup>{% endif %}"
    variant: "{{ include.variant_label }} & {{ include.compare_variant_label }}"
    model_example: "{{ provider.capabilities.rerank.model_example }}"
    path_template: "`/rerank`"
    min_version: "{{ provider.capabilities.rerank.min_version }}"
{% elsif provider.capabilities.rerank.supported %}
  - capability: "rerank{% if rerank_note_num != 0 %}<sup>{{ rerank_note_num }}</sup>{% endif %}"
    variant: "{{ include.variant_label }} only"
    model_example: "{{ provider.capabilities.rerank.model_example }}"
    path_template: "`/rerank`"
    min_version: "{{ provider.capabilities.rerank.min_version }}"
{% else %}
  - capability: "rerank{% if compare_rerank_note_num != 0 %}<sup>{{ compare_rerank_note_num }}</sup>{% endif %}"
    variant: "{{ include.compare_variant_label }} only"
    model_example: "{{ compare_provider.capabilities.rerank.model_example }}"
    path_template: "`/rerank`"
    min_version: "{{ compare_provider.capabilities.rerank.min_version }}"
{% endif %}
{% elsif provider.capabilities.rerank %}
  - capability: "rerank{% if rerank_note_num != 0 %}<sup>{{ rerank_note_num }}</sup>{% endif %}"
    model_example: "{{ provider.capabilities.rerank.model_example }}"
    path_template: "`/rerank`"
    min_version: "{{ provider.capabilities.rerank.min_version }}"
{% endif %}
{% endtable %}
{% if provider.capabilities.rerank.note.content %}<sup>{{ rerank_note_num }}</sup> {% if compare_provider %}**{{ include.variant_label }}:** {% endif %}{{ provider.capabilities.rerank.note.content }}{% endif %}
{% if compare_provider.capabilities.rerank.note.content %}<sup>{{ compare_rerank_note_num }}</sup> **{{ include.compare_variant_label }}:** {{ compare_provider.capabilities.rerank.note.content }}{% endif %}
{%- endif -%}

## {{ provider.name }} base URL

{%- assign has_capability_path = false -%}
{%- for url in provider.url_patterns -%}
  {%- if url contains "{capability_path}" -%}
    {%- assign has_capability_path = true -%}
  {%- endif -%}
{%- endfor -%}

{% if compare_provider %}
By default, {{site.ai_gateway}} routes {{ provider.name }} requests to {{ include.variant_label }} at `{{ provider.url_patterns.first }}`.{% if has_capability_path %} The `{capability_path}` is determined by the AI capability.{% endif %}

{{ compare_provider.variant_trigger }} This switches routing to {{ include.compare_variant_label }} at `{{ compare_provider.url_patterns.first }}`.

{{site.ai_gateway}} uses the correct URL automatically based on this configuration. You only need to set `upstream_url` in your [AI Model](/ai-gateway/entities/ai-model/) configuration if you're using a self-hosted or {{ provider.name }}-compatible endpoint instead.
{% else %}
{% if provider.url_is_variable %}
The base URL is <code>{{ provider.url_patterns.first }}</code>.{% if has_capability_path %} The `{capability_path}` is determined by the AI capability.{% endif %}
{% elsif provider.url_patterns.size > 1 %}
The base URL is {% for url in provider.url_patterns %}<code>{{ url }}</code>{% unless forloop.last %} or {% endunless %}{% endfor %}.{% if has_capability_path %} The `{capability_path}` is determined by the AI capability.{% endif %}
{% else %}
The base URL is `{{ provider.url_patterns.first }}`.{% if has_capability_path %} The `{capability_path}` is determined by the AI capability.{% endif %}
{% endif %}

{{site.ai_gateway}} uses this URL automatically. You only need to configure a URL if you're using a self-hosted or {{ provider.name }}-compatible endpoint, in which case set the `upstream_url` option in your [AI Model](/ai-gateway/entities/ai-model/) configuration.
{% endif %}

{% else %}
Provider "{{ include.provider_name }}" not found.
{% endif %}
<!--vale on-->
