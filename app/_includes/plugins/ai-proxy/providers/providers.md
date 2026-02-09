{% assign provider = include.providers.providers | where: "name", include.provider_name | first %}

{% if provider %}

You can proxy requests to {{ provider.name }} AI models through {{site.ai_gateway}} using the [AI Proxy](/plugins/ai-proxy/) and [AI Proxy Advanced](/plugins/ai-proxy-advanced/) plugins. This reference documents all supported AI capabilities, configuration requirements, and provider-specific details needed for proper integration.

## Upstream paths

{{site.ai_gateway}} automatically routes requests to the appropriate {{ provider.name }} API endpoints. The following table shows the upstream paths used for each capability.

<div class="w-full overflow-x-auto">
<table class="w-full">
<thead>
  <tr>
    <th>Capability</th>
    <th>Upstream path or API</th>
  </tr>
</thead>
<tbody>
  {% if provider.chat.supported %}
  <tr>
    <td><a href="#text-generation">Chat completions</a></td>
    <td>{% if provider.chat.upstream_path contains '<code>' %}{{ provider.chat.upstream_path }}{% else %}<code>{{ provider.chat.upstream_path }}</code>{% endif %}</td>
  </tr>
  {% endif %}
  {% if provider.completions.supported %}
  <tr>
    <td><a href="#text-generation">Completions</a></td>
    <td>{% if provider.completions.upstream_path contains '<code>' %}{{ provider.completions.upstream_path }}{% else %}<code>{{ provider.completions.upstream_path }}</code>{% endif %}</td>
  </tr>
  {% endif %}
  {% if provider.embeddings.supported %}
  <tr>
    <td><a href="#text-generation">Embeddings</a></td>
    <td>{% if provider.embeddings.upstream_path contains '<code>' %}{{ provider.embeddings.upstream_path }}{% else %}<code>{{ provider.embeddings.upstream_path }}</code>{% endif %}</td>
  </tr>
  {% endif %}
  {% if provider.function_calling.supported %}
  <tr>
    <td><a href="#advanced-text-generation">Function calling</a></td>
    <td>{% if provider.function_calling.upstream_path contains '<code>' %}{{ provider.function_calling.upstream_path }}{% else %}<code>{{ provider.function_calling.upstream_path }}</code>{% endif %}</td>
  </tr>
  {% endif %}
  {% if provider.files.supported %}
  <tr>
    <td><a href="#processing">Files</a></td>
    <td>{% if provider.files.upstream_path contains '<code>' %}{{ provider.files.upstream_path }}{% else %}<code>{{ provider.files.upstream_path }}</code>{% endif %}</td>
  </tr>
  {% endif %}
  {% if provider.batches.supported %}
  <tr>
    <td><a href="#processing">Batches</a></td>
    <td>{% if provider.batches.upstream_path contains '<code>' %}{{ provider.batches.upstream_path }}{% else %}<code>{{ provider.batches.upstream_path }}</code>{% endif %}</td>
  </tr>
  {% endif %}
  {% if provider.assistants.supported %}
  <tr>
    <td><a href="#processing">Assistants</a></td>
    <td>{% if provider.assistants.upstream_path contains '<code>' %}{{ provider.assistants.upstream_path }}{% else %}<code>{{ provider.assistants.upstream_path }}</code>{% endif %}</td>
  </tr>
  {% endif %}
  {% if provider.responses.supported %}
  <tr>
    <td><a href="#processing">Responses</a></td>
    <td>{% if provider.responses.upstream_path contains '<code>' %}{{ provider.responses.upstream_path }}{% else %}<code>{{ provider.responses.upstream_path }}</code>{% endif %}</td>
  </tr>
  {% endif %}
  {% if provider.audio.speech.supported %}
  <tr>
    <td><a href="#audio">Speech</a></td>
    <td>{% if provider.audio.speech.upstream_path contains '<code>' %}{{ provider.audio.speech.upstream_path }}{% else %}<code>{{ provider.audio.speech.upstream_path }}</code>{% endif %}</td>
  </tr>
  {% endif %}
  {% if provider.audio.transcriptions.supported %}
  <tr>
    <td><a href="#audio">Transcriptions</a></td>
    <td>{% if provider.audio.transcriptions.upstream_path contains '<code>' %}{{ provider.audio.transcriptions.upstream_path }}{% else %}<code>{{ provider.audio.transcriptions.upstream_path }}</code>{% endif %}</td>
  </tr>
  {% endif %}
  {% if provider.audio.translations.supported %}
  <tr>
    <td><a href="#audio">Translations</a></td>
    <td>{% if provider.audio.translations.upstream_path contains '<code>' %}{{ provider.audio.translations.upstream_path }}{% else %}<code>{{ provider.audio.translations.upstream_path }}</code>{% endif %}</td>
  </tr>
  {% endif %}
  {% if provider.image.generations.supported %}
  <tr>
    <td><a href="#image">Image generations</a></td>
    <td>{% if provider.image.generations.upstream_path contains '<code>' %}{{ provider.image.generations.upstream_path }}{% else %}<code>{{ provider.image.generations.upstream_path }}</code>{% endif %}</td>
  </tr>
  {% endif %}
  {% if provider.image.edits.supported %}
  <tr>
    <td><a href="#image">Image edits</a></td>
    <td>{% if provider.image.edits.upstream_path contains '<code>' %}{{ provider.image.edits.upstream_path }}{% else %}<code>{{ provider.image.edits.upstream_path }}</code>{% endif %}</td>
  </tr>
  {% endif %}
  {% if provider.video.generations.supported %}
  <tr>
    <td><a href="#video">Video generations</a></td>
    <td>{% if provider.video.generations.upstream_path contains '<code>' %}{{ provider.video.generations.upstream_path }}{% else %}<code>{{ provider.video.generations.upstream_path }}</code>{% endif %}</td>
  </tr>
  {% endif %}
  {% if provider.realtime.supported %}
  <tr>
    <td><a href="#realtime">Realtime</a></td>
    <td>{% if provider.realtime.upstream_path contains '<code>' %}{{ provider.realtime.upstream_path }}{% else %}<code>{{ provider.realtime.upstream_path }}</code>{% endif %}</td>
  </tr>
  {% endif %}
</tbody>
</table>
</div>

{% assign note_counter = 0 %}
{% assign chat_note_num = 0 %}{% if provider.chat.note.content %}{% assign note_counter = note_counter | plus: 1 %}{% assign chat_note_num = note_counter %}{% endif %}
{% assign completions_note_num = 0 %}{% if provider.completions.note.content %}{% assign note_counter = note_counter | plus: 1 %}{% assign completions_note_num = note_counter %}{% endif %}
{% assign embeddings_note_num = 0 %}{% if provider.embeddings.note.content %}{% assign note_counter = note_counter | plus: 1 %}{% assign embeddings_note_num = note_counter %}{% endif %}
{% assign function_calling_note_num = 0 %}{% if provider.function_calling.note.content %}{% assign note_counter = note_counter | plus: 1 %}{% assign function_calling_note_num = note_counter %}{% endif %}
{% assign files_note_num = 0 %}{% if provider.files.note.content %}{% assign note_counter = note_counter | plus: 1 %}{% assign files_note_num = note_counter %}{% endif %}
{% assign batches_note_num = 0 %}{% if provider.batches.note.content %}{% assign note_counter = note_counter | plus: 1 %}{% assign batches_note_num = note_counter %}{% endif %}
{% assign assistants_note_num = 0 %}{% if provider.assistants.note.content %}{% assign note_counter = note_counter | plus: 1 %}{% assign assistants_note_num = note_counter %}{% endif %}
{% assign responses_note_num = 0 %}{% if provider.responses.note.content %}{% assign note_counter = note_counter | plus: 1 %}{% assign responses_note_num = note_counter %}{% endif %}
{% assign audio_speech_note_num = 0 %}{% if provider.audio.speech.note.content %}{% assign note_counter = note_counter | plus: 1 %}{% assign audio_speech_note_num = note_counter %}{% endif %}
{% assign audio_transcriptions_note_num = 0 %}{% if provider.audio.transcriptions.note.content %}{% assign note_counter = note_counter | plus: 1 %}{% assign audio_transcriptions_note_num = note_counter %}{% endif %}
{% assign audio_translations_note_num = 0 %}{% if provider.audio.translations.note.content %}{% assign note_counter = note_counter | plus: 1 %}{% assign audio_translations_note_num = note_counter %}{% endif %}
{% assign image_generations_note_num = 0 %}{% if provider.image.generations.note.content %}{% assign note_counter = note_counter | plus: 1 %}{% assign image_generations_note_num = note_counter %}{% endif %}
{% assign image_edits_note_num = 0 %}{% if provider.image.edits.note.content %}{% assign note_counter = note_counter | plus: 1 %}{% assign image_edits_note_num = note_counter %}{% endif %}
{% assign video_generations_note_num = 0 %}{% if provider.video.generations.note.content %}{% assign note_counter = note_counter | plus: 1 %}{% assign video_generations_note_num = note_counter %}{% endif %}
{% assign realtime_note_num = 0 %}{% if provider.realtime.note.content %}{% assign note_counter = note_counter | plus: 1 %}{% assign realtime_note_num = note_counter %}{% endif %}

{% assign has_text = false %}
{% assign has_advanced_text = false %}
{% assign has_processing = false %}
{% assign has_audio = false %}
{% assign has_image = false %}
{% assign has_video = false %}
{% assign has_realtime = false %}

{% if provider.chat.supported or provider.completions.supported or provider.embeddings.supported %}{% assign has_text = true %}{% endif %}
{% if provider.function_calling.supported %}{% assign has_advanced_text = true %}{% endif %}
{% if provider.files.supported or provider.batches.supported or provider.assistants.supported or provider.responses.supported %}{% assign has_processing = true %}{% endif %}
{% if provider.audio.speech.supported or provider.audio.transcriptions.supported or provider.audio.translations.supported %}{% assign has_audio = true %}{% endif %}
{% if provider.image.generations.supported or provider.image.edits.supported %}{% assign has_image = true %}{% endif %}
{% if provider.video.generations.supported %}{% assign has_video = true %}{% endif %}
{% if provider.realtime.supported %}{% assign has_realtime = true %}{% endif %}

{% capture table_header_with_streaming %}
<thead>
  <tr>
    <th>Capability</th>
    <th>Route type</th>
    <th>Streaming</th>
    <th>Model example</th>
    <th>Min version</th>
  </tr>
</thead>
{% endcapture %}

{% capture table_header_no_streaming %}
<thead>
  <tr>
    <th>Capability</th>
    <th>Route type</th>
    <th>Model example</th>
    <th>Min version</th>
  </tr>
</thead>
{% endcapture %}

## Supported capabilities

The following tables show the AI capabilities supported by {{ provider.name }} provider when used with the [AI Proxy](/plugins/ai-proxy/) or the [AI Proxy Advanced](/plugins/ai-proxy-advanced/) plugin.

{:.info}
> Set the plugin's [`route_type`](/plugins/ai-proxy/reference/#schema--config-route-type) based on the capability you want to use. See the tables below for supported route types.

{% if has_text %}
### Text generation

Support for {{ provider.name }} basic text generation capabilities including chat, completions, and embeddings:


<div class="w-full overflow-x-auto">
<table class="w-full">
  {{ table_header_with_streaming }}
  <tbody>
    {% if provider.chat.supported %}
    <tr>
      <td>Chat completions{% if chat_note_num != 0 %}<sup>{{ chat_note_num }}</sup>{% endif %}</td>
      <td><code>{{ provider.chat.route_type }}</code></td>
      <td>{{ provider.chat.streaming | to_check }}</td>
      <td>{{ provider.chat.model_example }}</td>
      <td>{{ provider.chat.min_version }}</td>
    </tr>
    {% endif %}
    {% if provider.completions.supported %}
    <tr>
      <td>Completions{% if completions_note_num != 0 %}<sup>{{ completions_note_num }}</sup>{% endif %}</td>
      <td><code>{{ provider.completions.route_type }}</code></td>
      <td>{{ provider.completions.streaming | to_check }}</td>
      <td>{{ provider.completions.model_example }}</td>
      <td>{{ provider.completions.min_version }}</td>
    </tr>
    {% endif %}
    {% if provider.embeddings.supported %}
    <tr>
      <td>Embeddings{% if embeddings_note_num != 0 %}<sup>{{ embeddings_note_num }}</sup>{% endif %}</td>
      <td><code>{{ provider.embeddings.route_type }}</code></td>
      <td>{{ provider.embeddings.streaming | to_check }}</td>
      <td>{{ provider.embeddings.model_example }}</td>
      <td>{{ provider.embeddings.min_version }}</td>
    </tr>
    {% endif %}
  </tbody>
</table>
</div>

{% if provider.chat.note.content %}<sup>{{ chat_note_num }}</sup> {{ provider.chat.note.content }}

{% endif %}
{% if provider.completions.note.content %}<sup>{{ completions_note_num }}</sup> {{ provider.completions.note.content }}

{% endif %}
{% if provider.embeddings.note.content %}<sup>{{ embeddings_note_num }}</sup> {{ provider.embeddings.note.content }}

{% endif %}
{% endif %}

{% if has_advanced_text %}
### Advanced text generation

Support for {{ provider.name }} function calling to allow {{ provider.name }} models to use external tools and APIs:

<div class="w-full overflow-x-auto">
<table class="w-full">
  {{ table_header_no_streaming }}
  <tbody>
    {% if provider.function_calling.supported %}
    <tr>
      <td>Function calling{% if function_calling_note_num != 0 %}<sup>{{ function_calling_note_num }}</sup>{% endif %}</td>
      <td><code>{{ provider.function_calling.route_type }}</code></td>
      <td>{{ provider.function_calling.model_example }}</td>
      <td>{{ provider.function_calling.min_version }}</td>
    </tr>
    {% endif %}
  </tbody>
</table>
</div>

{% if provider.function_calling.note.content %}<sup>{{ function_calling_note_num }}</sup> {{ provider.function_calling.note.content }}

{% endif %}
{% endif %}

{% if has_processing %}
### Processing

Support for {{ provider.name }} file operations, batch operations, assistants, and response handling:

<div class="w-full overflow-x-auto">
<table class="w-full">
  {{ table_header_no_streaming }}
  <tbody>
    {% if provider.files.supported %}
    <tr>
      <td>Files{% if files_note_num != 0 %}<sup>{{ files_note_num }}</sup>{% endif %}</td>
      <td><code>{{ provider.files.route_type }}</code></td>
      <td>{{ provider.files.model_example }}</td>
      <td>{{ provider.files.min_version }}</td>
    </tr>
    {% endif %}
    {% if provider.batches.supported %}
    <tr>
      <td>Batches{% if batches_note_num != 0 %}<sup>{{ batches_note_num }}</sup>{% endif %}</td>
      <td><code>{{ provider.batches.route_type }}</code></td>
      <td>{{ provider.batches.model_example }}</td>
      <td>{{ provider.batches.min_version }}</td>
    </tr>
    {% endif %}
    {% if provider.assistants.supported %}
    <tr>
      <td>Assistants{% if assistants_note_num != 0 %}<sup>{{ assistants_note_num }}</sup>{% endif %}</td>
      <td><code>{{ provider.assistants.route_type }}</code></td>
      <td>{{ provider.assistants.model_example }}</td>
      <td>{{ provider.assistants.min_version }}</td>
    </tr>
    {% endif %}
    {% if provider.responses.supported %}
    <tr>
      <td>Responses{% if responses_note_num != 0 %}<sup>{{ responses_note_num }}</sup>{% endif %}</td>
      <td><code>{{ provider.responses.route_type }}</code></td>
      <td>{{ provider.responses.model_example }}</td>
      <td>{{ provider.responses.min_version }}</td>
    </tr>
    {% endif %}
  </tbody>
</table>
</div>

{% if provider.files.note.content %}<sup>{{ files_note_num }}</sup> {{ provider.files.note.content }}

{% endif %}
{% if provider.batches.note.content %}<sup>{{ batches_note_num }}</sup> {{ provider.batches.note.content }}

{% endif %}
{% if provider.assistants.note.content %}<sup>{{ assistants_note_num }}</sup> {{ provider.assistants.note.content }}

{% endif %}
{% if provider.responses.note.content %}<sup>{{ responses_note_num }}</sup> {{ provider.responses.note.content }}

{% endif %}
{% endif %}

{% if has_audio %}
### Audio

Support for {{ provider.name }} text-to-speech, transcription, and translation capabilities:

<div class="w-full overflow-x-auto">
<table class="w-full">
  {{ table_header_no_streaming }}
  <tbody>
    {% if provider.audio.speech.supported %}
    <tr>
      <td>Speech{% if audio_speech_note_num != 0 %}<sup>{{ audio_speech_note_num }}</sup>{% endif %}</td>
      <td><code>{{ provider.audio.speech.route_type }}</code></td>
      <td>{{ provider.audio.speech.model_example }}</td>
      <td>{{ provider.audio.speech.min_version }}</td>
    </tr>
    {% endif %}
    {% if provider.audio.transcriptions.supported %}
    <tr>
      <td>Transcriptions{% if audio_transcriptions_note_num != 0 %}<sup>{{ audio_transcriptions_note_num }}</sup>{% endif %}</td>
      <td><code>{{ provider.audio.transcriptions.route_type }}</code></td>
      <td>{{ provider.audio.transcriptions.model_example }}</td>
      <td>{{ provider.audio.transcriptions.min_version }}</td>
    </tr>
    {% endif %}
    {% if provider.audio.translations.supported %}
    <tr>
      <td>Translations{% if audio_translations_note_num != 0 %}<sup>{{ audio_translations_note_num }}</sup>{% endif %}</td>
      <td><code>{{ provider.audio.translations.route_type }}</code></td>
      <td>{{ provider.audio.translations.model_example }}</td>
      <td>{{ provider.audio.translations.min_version }}</td>
    </tr>
    {% endif %}
  </tbody>
</table>
</div>

{:.info}
> For requests with large payloads, consider increasing `config.max_request_body_size` to three times the raw binary size.
>
> Supported audio formats, voices, and parameters vary by model. Refer to your provider's documentation for available options.

{% if provider.audio.speech.note.content %}<sup>{{ audio_speech_note_num }}</sup> {{ provider.audio.speech.note.content }}

{% endif %}
{% if provider.audio.transcriptions.note.content %}<sup>{{ audio_transcriptions_note_num }}</sup> {{ provider.audio.transcriptions.note.content }}

{% endif %}
{% if provider.audio.translations.note.content %}<sup>{{ audio_translations_note_num }}</sup> {{ provider.audio.translations.note.content }}

{% endif %}
{% endif %}

{% if has_image %}
### Image

Support for {{ provider.name }} image generation and editing capabilities:

<div class="w-full overflow-x-auto">
<table class="w-full">
  {{ table_header_no_streaming }}
  <tbody>
    {% if provider.image.generations.supported %}
    <tr>
      <td>Generations{% if image_generations_note_num != 0 %}<sup>{{ image_generations_note_num }}</sup>{% endif %}</td>
      <td><code>{{ provider.image.generations.route_type }}</code></td>
      <td>{{ provider.image.generations.model_example }}</td>
      <td>{{ provider.image.generations.min_version }}</td>
    </tr>
    {% endif %}
    {% if provider.image.edits.supported %}
    <tr>
      <td>Edits{% if image_edits_note_num != 0 %}<sup>{{ image_edits_note_num }}</sup>{% endif %}</td>
      <td><code>{{ provider.image.edits.route_type }}</code></td>
      <td>{{ provider.image.edits.model_example }}</td>
      <td>{{ provider.image.edits.min_version }}</td>
    </tr>
    {% endif %}
  </tbody>
</table>
</div>

{:.info}
> For requests with large payloads, consider increasing `config.max_request_body_size` to three times the raw binary size.
>
> Supported image sizes and formats vary by model. Refer to your provider's documentation for allowed dimensions and requirements.


{% if provider.image.generations.note.content %}<sup>{{ image_generations_note_num }}</sup> {{ provider.image.generations.note.content }}

{% endif %}
{% if provider.image.edits.note.content %}<sup>{{ image_edits_note_num }}</sup> {{ provider.image.edits.note.content }}

{% endif %}
{% endif %}

{% if has_video %}
### Video

Support for {{ provider.name }} video generation capabilities:

<div class="w-full overflow-x-auto">
<table class="w-full">
  {{ table_header_no_streaming }}
  <tbody>
    {% if provider.video.generations.supported %}
    <tr>
      <td>Generations{% if video_generations_note_num != 0 %}<sup>{{ video_generations_note_num }}</sup>{% endif %}</td>
      <td><code>{{ provider.video.generations.route_type }}</code></td>
      <td>{{ provider.video.generations.model_example }}</td>
      <td>{{ provider.video.generations.min_version }}</td>
    </tr>
    {% endif %}
  </tbody>
</table>
</div>

{:.info}
> For requests with large payloads (video generation), consider increasing `config.max_request_body_size` to three times the raw binary size.

{% if provider.video.generations.note.content %}<sup>{{ video_generations_note_num }}</sup> {{ provider.video.generations.note.content }}

{% endif %}
{% endif %}

{% if has_realtime %}
### Realtime

Support for {{ provider.name }}'s bidirectional streaming for realtime applications:

{:.warning}
> Realtime processing requires the [AI Proxy Advanced](/plugins/ai-proxy-advanced/) plugin and uses WebSocket protocol.
>
> To use the realtime route, you must configure the protocols `ws` and/or `wss` on both the Service and on the Route where the plugin is associated.

<div class="w-full overflow-x-auto">
<table class="w-full">
  {{ table_header_no_streaming }}
  <tbody>
    {% if provider.realtime.supported %}
    <tr>
      <td>Realtime{% if realtime_note_num != 0 %}<sup>{{ realtime_note_num }}</sup>{% endif %}</td>
      <td><code>{{ provider.realtime.route_type }}</code></td>
      <td>{{ provider.realtime.model_example }}</td>
      <td>{{ provider.realtime.min_version }}</td>
    </tr>
    {% endif %}
  </tbody>
</table>
</div>

{% if provider.realtime.note.content %}<sup>{{ realtime_note_num }}</sup> {{ provider.realtime.note.content }}

{% endif %}
{% endif %}

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