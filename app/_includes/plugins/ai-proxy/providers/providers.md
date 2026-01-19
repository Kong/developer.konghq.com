{% assign provider = include.providers.providers | where: "name", include.provider_name | first %}

{% if provider %}

You can proxy requests to {{ provider.name }} AI models through Kong AI Gateway using the [AI Proxy](/plugins/ai-proxy/) and [AI Proxy Advanced](/plugins/ai-proxy-advanced/) plugins. This reference documents all supported AI capabilities, configuration requirements, and provider-specific details needed for proper integration.

## {{ provider.name }} base URL

The base URL for {{ provider.name }} is `{{ provider.url_pattern }}`, where `{route_type_path}` is determined by the capability being used.

{:.info}
> While only the **Llama2** and **Mistral** models are classed as self-hosted, the target URL can be overridden for any of the supported providers.
>
> For example, a self-hosted or otherwise OpenAI-compatible endpoint can be called by setting the same `upstream_url` plugin option.

{% comment %}First pass: collect all notes and assign numbers{% endcomment %}
{% assign chat_note_num = 0 %}
{% assign completions_note_num = 0 %}
{% assign embeddings_note_num = 0 %}
{% assign function_calling_note_num = 0 %}
{% assign files_note_num = 0 %}
{% assign batches_note_num = 0 %}
{% assign assistants_note_num = 0 %}
{% assign responses_note_num = 0 %}
{% assign audio_speech_note_num = 0 %}
{% assign audio_transcriptions_note_num = 0 %}
{% assign audio_translations_note_num = 0 %}
{% assign image_generations_note_num = 0 %}
{% assign image_edits_note_num = 0 %}
{% assign video_generations_note_num = 0 %}
{% assign realtime_note_num = 0 %}
{% assign note_counter = 0 %}

{% if provider.chat.note.content %}
  {% assign note_counter = note_counter | plus: 1 %}
  {% assign chat_note_num = note_counter %}
{% endif %}
{% if provider.completions.note.content %}
  {% assign note_counter = note_counter | plus: 1 %}
  {% assign completions_note_num = note_counter %}
{% endif %}
{% if provider.embeddings.note.content %}
  {% assign note_counter = note_counter | plus: 1 %}
  {% assign embeddings_note_num = note_counter %}
{% endif %}
{% if provider.function_calling.note.content %}
  {% assign note_counter = note_counter | plus: 1 %}
  {% assign function_calling_note_num = note_counter %}
{% endif %}
{% if provider.files.note.content %}
  {% assign note_counter = note_counter | plus: 1 %}
  {% assign files_note_num = note_counter %}
{% endif %}
{% if provider.batches.note.content %}
  {% assign note_counter = note_counter | plus: 1 %}
  {% assign batches_note_num = note_counter %}
{% endif %}
{% if provider.assistants.note.content %}
  {% assign note_counter = note_counter | plus: 1 %}
  {% assign assistants_note_num = note_counter %}
{% endif %}
{% if provider.responses.note.content %}
  {% assign note_counter = note_counter | plus: 1 %}
  {% assign responses_note_num = note_counter %}
{% endif %}
{% if provider.audio.speech.note.content %}
  {% assign note_counter = note_counter | plus: 1 %}
  {% assign audio_speech_note_num = note_counter %}
{% endif %}
{% if provider.audio.transcriptions.note.content %}
  {% assign note_counter = note_counter | plus: 1 %}
  {% assign audio_transcriptions_note_num = note_counter %}
{% endif %}
{% if provider.audio.translations.note.content %}
  {% assign note_counter = note_counter | plus: 1 %}
  {% assign audio_translations_note_num = note_counter %}
{% endif %}
{% if provider.image.generations.note.content %}
  {% assign note_counter = note_counter | plus: 1 %}
  {% assign image_generations_note_num = note_counter %}
{% endif %}
{% if provider.image.edits.note.content %}
  {% assign note_counter = note_counter | plus: 1 %}
  {% assign image_edits_note_num = note_counter %}
{% endif %}
{% if provider.video.generations.note.content %}
  {% assign note_counter = note_counter | plus: 1 %}
  {% assign video_generations_note_num = note_counter %}
{% endif %}
{% if provider.realtime.note.content %}
  {% assign note_counter = note_counter | plus: 1 %}
  {% assign realtime_note_num = note_counter %}
{% endif %}

{% assign has_text = false %}
{% assign has_advanced_text = false %}
{% assign has_processing = false %}
{% assign has_audio = false %}
{% assign has_image = false %}
{% assign has_video = false %}
{% assign has_realtime = false %}

{% if provider.chat.supported or provider.completions.supported or provider.embeddings.supported %}
  {% assign has_text = true %}
{% endif %}

{% if provider.function_calling.supported %}
  {% assign has_advanced_text = true %}
{% endif %}

{% if provider.files.supported or provider.batches.supported or provider.assistants.supported or provider.responses.supported %}
  {% assign has_processing = true %}
{% endif %}

{% if provider.audio.speech.supported or provider.audio.transcriptions.supported or provider.audio.translations.supported %}
  {% assign has_audio = true %}
{% endif %}

{% if provider.image.generations.supported or provider.image.edits.supported %}
  {% assign has_image = true %}
{% endif %}

{% if provider.video.generations.supported %}
  {% assign has_video = true %}
{% endif %}

{% if provider.realtime.supported %}
  {% assign has_realtime = true %}
{% endif %}

## Supported capabilities

The following tables show the AI capabilities supported by {{ provider.name }} provider when used with the [AI Proxy](/plugins/ai-proxy/) or the [AI Proxy Advanced](/plugins/ai-proxy-advanced/) plugin.

{:.info}
> Set the plugin's [`route_type`](/plugins/ai-proxy/reference/#schema--config-route-type) based on the capability you want to use. See the tables below for supported route types.

{% if has_text %}

### Text generation

Support for {{ provider.name }} basic text generation capabilities including chat, completions, and embeddings:

<table>
  <thead>
    <tr>
      <th>Capability</th>
      <th>Upstream path</th>
      <th>Route type</th>
      <th>Streaming</th>
      <th>Model example</th>
      <th>Min version</th>
    </tr>
  </thead>
  <tbody>
    {% if provider.chat.supported %}
    <tr>
      <td>Chat completions{% if provider.chat.note.content %}<sup>{{ chat_note_num }}</sup>{% endif %}</td>
      <td>
        {% assign path_stripped = provider.chat.upstream_path | strip_html %}
        {% if path_stripped contains '/' %}
          <code>{{ provider.chat.upstream_path }}</code>
        {% else %}
          {{ provider.chat.upstream_path }}
        {% endif %}
      </td>
      <td><code>{{ provider.chat.route_type }}</code></td>
      <td>{{ provider.chat.streaming | to_check }}</td>
      <td>{{ provider.chat.model_example }}</td>
      <td>{{ provider.chat.min_version }}</td>
    </tr>
    {% endif %}

    {% if provider.completions.supported %}
    <tr>
      <td>Completions{% if provider.completions.note.content %}<sup>{{ completions_note_num }}</sup>{% endif %}</td>
      <td>
        {% assign path_stripped = provider.completions.upstream_path | strip_html %}
        {% if path_stripped contains '/' %}
          <code>{{ provider.completions.upstream_path }}</code>
        {% else %}
          {{ provider.completions.upstream_path }}
        {% endif %}
      </td>
      <td><code>{{ provider.completions.route_type }}</code></td>
      <td>{{ provider.completions.streaming | to_check }}</td>
      <td>{{ provider.completions.model_example }}</td>
      <td>{{ provider.completions.min_version }}</td>
    </tr>
    {% endif %}

    {% if provider.embeddings.supported %}
    <tr>
      <td>Embeddings{% if provider.embeddings.note.content %}<sup>{{ embeddings_note_num }}</sup>{% endif %}</td>
      <td>
        {% assign path_stripped = provider.embeddings.upstream_path | strip_html %}
        {% if path_stripped contains '/' %}
          <code>{{ provider.embeddings.upstream_path }}</code>
        {% else %}
          {{ provider.embeddings.upstream_path }}
        {% endif %}
      </td>
      <td><code>{{ provider.embeddings.route_type }}</code></td>
      <td>{{ provider.embeddings.streaming | to_check }}</td>
      <td>{{ provider.embeddings.model_example }}</td>
      <td>{{ provider.embeddings.min_version }}</td>
    </tr>
    {% endif %}
  </tbody>
</table>

{% if provider.chat.note.content or provider.completions.note.content or provider.embeddings.note.content %}

{% if provider.chat.note.content %}<sup>{{ chat_note_num }}</sup> {{ provider.chat.note.content }}

{% endif %}
{% if provider.completions.note.content %}<sup>{{ completions_note_num }}</sup> {{ provider.completions.note.content }}

{% endif %}
{% if provider.embeddings.note.content %}<sup>{{ embeddings_note_num }}</sup> {{ provider.embeddings.note.content }}{% endif %}
{% endif %}
{% endif %}

{% if has_advanced_text %}

### Advanced text generation

Support for {{ provider.name }} function calling to allow {{ provider.name }} models to use external tools and APIs:

<table>
  <thead>
    <tr>
      <th>Capability</th>
      <th>Upstream path</th>
      <th>Route type</th>
      <th>Streaming</th>
      <th>Model example</th>
      <th>Min version</th>
    </tr>
  </thead>
  <tbody>
    {% if provider.function_calling.supported %}
    <tr>
      <td>Function calling{% if provider.function_calling.note.content %}<sup>{{ function_calling_note_num }}</sup>{% endif %}</td>
      <td>
        {% assign path_stripped = provider.function_calling.upstream_path | strip_html %}
        {% if path_stripped contains '/' %}
          <code>{{ provider.function_calling.upstream_path }}</code>
        {% else %}
          {{ provider.function_calling.upstream_path }}
        {% endif %}
      </td>
      <td><code>{{ provider.function_calling.route_type }}</code></td>
      <td>{{ provider.function_calling.streaming | to_check }}</td>
      <td>{{ provider.function_calling.model_example }}</td>
      <td>{{ provider.function_calling.min_version }}</td>
    </tr>
    {% endif %}
  </tbody>
</table>

{% if provider.function_calling.note.content %}

<sup>{{ function_calling_note_num }}</sup> {{ provider.function_calling.note.content }}
{% endif %}
{% endif %}

{% if has_processing %}

### Processing

Support for {{ provider.name }} file operations, batch operations, assistants, and response handling:

<table>
  <thead>
    <tr>
      <th>Capability</th>
      <th>Upstream path</th>
      <th>Route type</th>
      <th>Streaming</th>
      <th>Model example</th>
      <th>Min version</th>
    </tr>
  </thead>
  <tbody>
    {% if provider.files.supported %}
    <tr>
      <td>Files{% if provider.files.note.content %}<sup>{{ files_note_num }}</sup>{% endif %}</td>
      <td>
        {% assign path_stripped = provider.files.upstream_path | strip_html %}
        {% if path_stripped contains '/' %}
          <code>{{ provider.files.upstream_path }}</code>
        {% else %}
          {{ provider.files.upstream_path }}
        {% endif %}
      </td>
      <td><code>{{ provider.files.route_type }}</code></td>
      <td>{{ provider.files.streaming | to_check }}</td>
      <td>{{ provider.files.model_example }}</td>
      <td>{{ provider.files.min_version }}</td>
    </tr>
    {% endif %}

    {% if provider.batches.supported %}
    <tr>
      <td>Batches{% if provider.batches.note.content %}<sup>{{ batches_note_num }}</sup>{% endif %}</td>
      <td>
        {% assign path_stripped = provider.batches.upstream_path | strip_html %}
        {% if path_stripped contains '/' %}
          <code>{{ provider.batches.upstream_path }}</code>
        {% else %}
          {{ provider.batches.upstream_path }}
        {% endif %}
      </td>
      <td><code>{{ provider.batches.route_type }}</code></td>
      <td>{{ provider.batches.streaming | to_check }}</td>
      <td>{{ provider.batches.model_example }}</td>
      <td>{{ provider.batches.min_version }}</td>
    </tr>
    {% endif %}

    {% if provider.assistants.supported %}
    <tr>
      <td>Assistants{% if provider.assistants.note.content %}<sup>{{ assistants_note_num }}</sup>{% endif %}</td>
      <td>
        {% assign path_stripped = provider.assistants.upstream_path | strip_html %}
        {% if path_stripped contains '/' %}
          <code>{{ provider.assistants.upstream_path }}</code>
        {% else %}
          {{ provider.assistants.upstream_path }}
        {% endif %}
      </td>
      <td><code>{{ provider.assistants.route_type }}</code></td>
      <td>{{ provider.assistants.streaming | to_check }}</td>
      <td>{{ provider.assistants.model_example }}</td>
      <td>{{ provider.assistants.min_version }}</td>
    </tr>
    {% endif %}

    {% if provider.responses.supported %}
    <tr>
      <td>Responses{% if provider.responses.note.content %}<sup>{{ responses_note_num }}</sup>{% endif %}</td>
      <td>
        {% assign path_stripped = provider.responses.upstream_path | strip_html %}
        {% if path_stripped contains '/' %}
          <code>{{ provider.responses.upstream_path }}</code>
        {% else %}
          {{ provider.responses.upstream_path }}
        {% endif %}
      </td>
      <td><code>{{ provider.responses.route_type }}</code></td>
      <td>{{ provider.responses.streaming | to_check }}</td>
      <td>{{ provider.responses.model_example }}</td>
      <td>{{ provider.responses.min_version }}</td>
    </tr>
    {% endif %}
  </tbody>
</table>

{% if provider.files.note.content or provider.batches.note.content or provider.assistants.note.content or provider.responses.note.content %}

{% if provider.files.note.content %}<sup>{{ files_note_num }}</sup> {{ provider.files.note.content }}

{% endif %}
{% if provider.batches.note.content %}<sup>{{ batches_note_num }}</sup> {{ provider.batches.note.content }}

{% endif %}
{% if provider.assistants.note.content %}<sup>{{ assistants_note_num }}</sup> {{ provider.assistants.note.content }}

{% endif %}
{% if provider.responses.note.content %}<sup>{{ responses_note_num }}</sup> {{ provider.responses.note.content }}{% endif %}
{% endif %}
{% endif %}

{% if has_audio %}

### Audio

Support for {{ provider.name }} text-to-speech, transcription, and translation capabilities:

<table>
  <thead>
    <tr>
      <th>Capability</th>
      <th>Upstream path</th>
      <th>Route type</th>
      <th>Streaming</th>
      <th>Model example</th>
      <th>Min version</th>
    </tr>
  </thead>
  <tbody>
    {% if provider.audio.speech.supported %}
    <tr>
      <td>Speech{% if provider.audio.speech.note.content %}<sup>{{ audio_speech_note_num }}</sup>{% endif %}</td>
      <td>
        {% assign path_stripped = provider.audio.speech.upstream_path | strip_html %}
        {% if path_stripped contains '/' %}
          <code>{{ provider.audio.speech.upstream_path }}</code>
        {% else %}
          {{ provider.audio.speech.upstream_path }}
        {% endif %}
      </td>
      <td><code>{{ provider.audio.speech.route_type }}</code></td>
      <td>{{ provider.audio.speech.streaming | to_check }}</td>
      <td>{{ provider.audio.speech.model_example }}</td>
      <td>{{ provider.audio.speech.min_version }}</td>
    </tr>
    {% endif %}

    {% if provider.audio.transcriptions.supported %}
    <tr>
      <td>Transcriptions{% if provider.audio.transcriptions.note.content %}<sup>{{ audio_transcriptions_note_num }}</sup>{% endif %}</td>
      <td>
        {% assign path_stripped = provider.audio.transcriptions.upstream_path | strip_html %}
        {% if path_stripped contains '/' %}
          <code>{{ provider.audio.transcriptions.upstream_path }}</code>
        {% else %}
          {{ provider.audio.transcriptions.upstream_path }}
        {% endif %}
      </td>
      <td><code>{{ provider.audio.transcriptions.route_type }}</code></td>
      <td>{{ provider.audio.transcriptions.streaming | to_check }}</td>
      <td>{{ provider.audio.transcriptions.model_example }}</td>
      <td>{{ provider.audio.transcriptions.min_version }}</td>
    </tr>
    {% endif %}

    {% if provider.audio.translations.supported %}
    <tr>
      <td>Translations{% if provider.audio.translations.note.content %}<sup>{{ audio_translations_note_num }}</sup>{% endif %}</td>
      <td>
        {% assign path_stripped = provider.audio.translations.upstream_path | strip_html %}
        {% if path_stripped contains '/' %}
          <code>{{ provider.audio.translations.upstream_path }}</code>
        {% else %}
          {{ provider.audio.translations.upstream_path }}
        {% endif %}
      </td>
      <td><code>{{ provider.audio.translations.route_type }}</code></td>
      <td>{{ provider.audio.translations.streaming | to_check }}</td>
      <td>{{ provider.audio.translations.model_example }}</td>
      <td>{{ provider.audio.translations.min_version }}</td>
    </tr>
    {% endif %}
  </tbody>
</table>

{:.info}
> For requests with large payloads (audio transcription/translation), consider increasing `config.max_request_body_size` to three times the raw binary size.

{% if provider.audio.speech.note.content or provider.audio.transcriptions.note.content or provider.audio.translations.note.content %}

{% if provider.audio.speech.note.content %}<sup>{{ audio_speech_note_num }}</sup> {{ provider.audio.speech.note.content }}

{% endif %}
{% if provider.audio.transcriptions.note.content %}<sup>{{ audio_transcriptions_note_num }}</sup> {{ provider.audio.transcriptions.note.content }}

{% endif %}
{% if provider.audio.translations.note.content %}<sup>{{ audio_translations_note_num }}</sup> {{ provider.audio.translations.note.content }}{% endif %}
{% endif %}
{% endif %}

{% if has_image %}

### Image

Support for {{ provider.name }} image generation and editing capabilities:

<table>
  <thead>
    <tr>
      <th>Capability</th>
      <th>Upstream path</th>
      <th>Route type</th>
      <th>Streaming</th>
      <th>Model example</th>
      <th>Min version</th>
    </tr>
  </thead>
  <tbody>
    {% if provider.image.generations.supported %}
    <tr>
      <td>Generations{% if provider.image.generations.note.content %}<sup>{{ image_generations_note_num }}</sup>{% endif %}</td>
      <td>
        {% assign path_stripped = provider.image.generations.upstream_path | strip_html %}
        {% if path_stripped contains '/' %}
          <code>{{ provider.image.generations.upstream_path }}</code>
        {% else %}
          {{ provider.image.generations.upstream_path }}
        {% endif %}
      </td>
      <td><code>{{ provider.image.generations.route_type }}</code></td>
      <td>{{ provider.image.generations.streaming | to_check }}</td>
      <td>{{ provider.image.generations.model_example }}</td>
      <td>{{ provider.image.generations.min_version }}</td>
    </tr>
    {% endif %}

    {% if provider.image.edits.supported %}
    <tr>
      <td>Edits{% if provider.image.edits.note.content %}<sup>{{ image_edits_note_num }}</sup>{% endif %}</td>
      <td>
        {% assign path_stripped = provider.image.edits.upstream_path | strip_html %}
        {% if path_stripped contains '/' %}
          <code>{{ provider.image.edits.upstream_path }}</code>
        {% else %}
          {{ provider.image.edits.upstream_path }}
        {% endif %}
      </td>
      <td><code>{{ provider.image.edits.route_type }}</code></td>
      <td>{{ provider.image.edits.streaming | to_check }}</td>
      <td>{{ provider.image.edits.model_example }}</td>
      <td>{{ provider.image.edits.min_version }}</td>
    </tr>
    {% endif %}
  </tbody>
</table>

{:.info}
> For requests with large payloads (image edits), consider increasing `config.max_request_body_size` to three times the raw binary size.

{% if provider.image.generations.note.content or provider.image.edits.note.content %}

{% if provider.image.generations.note.content %}<sup>{{ image_generations_note_num }}</sup> {{ provider.image.generations.note.content }}

{% endif %}
{% if provider.image.edits.note.content %}<sup>{{ image_edits_note_num }}</sup> {{ provider.image.edits.note.content }}{% endif %}
{% endif %}
{% endif %}

{% if has_video %}

### Video

Support for {{ provider.name }} video generation capabilities:

<table>
  <thead>
    <tr>
      <th>Capability</th>
      <th>Upstream path</th>
      <th>Route type</th>
      <th>Streaming</th>
      <th>Model example</th>
      <th>Min version</th>
    </tr>
  </thead>
  <tbody>
    {% if provider.video.generations.supported %}
    <tr>
      <td>Generations{% if provider.video.generations.note.content %}<sup>{{ video_generations_note_num }}</sup>{% endif %}</td>
      <td>
        {% assign path_stripped = provider.video.generations.upstream_path | strip_html %}
        {% if path_stripped contains '/' %}
          <code>{{ provider.video.generations.upstream_path }}</code>
        {% else %}
          {{ provider.video.generations.upstream_path }}
        {% endif %}
      </td>
      <td><code>{{ provider.video.generations.route_type }}</code></td>
      <td>{{ provider.video.generations.streaming | to_check }}</td>
      <td>{{ provider.video.generations.model_example }}</td>
      <td>{{ provider.video.generations.min_version }}</td>
    </tr>
    {% endif %}
  </tbody>
</table>

{:.info}
> For requests with large payloads (video generation), consider increasing `config.max_request_body_size` to three times the raw binary size.

{% if provider.video.generations.note.content %}

<sup>{{ video_generations_note_num }}</sup> {{ provider.video.generations.note.content }}
{% endif %}
{% endif %}

{% if has_realtime %}

### Realtime

Support for {{ provider.name }}'s bidirectional streaming for realtime applications:

{:.warning}
> Realtime processing requires the [AI Proxy Advanced](/plugins/ai-proxy-advanced/) plugin and uses WebSocket protocol.

<table>
  <thead>
    <tr>
      <th>Capability</th>
      <th>Upstream path</th>
      <th>Route type</th>
      <th>Streaming</th>
      <th>Model example</th>
      <th>Min version</th>
    </tr>
  </thead>
  <tbody>
    {% if provider.realtime.supported %}
    <tr>
      <td>Realtime{% if provider.realtime.note.content %}<sup>{{ realtime_note_num }}</sup>{% endif %}</td>
      <td>
        {% assign path_stripped = provider.realtime.upstream_path | strip_html %}
        {% if path_stripped contains '/' %}
          <code>{{ provider.realtime.upstream_path }}</code>
        {% else %}
          {{ provider.realtime.upstream_path }}
        {% endif %}
      </td>
      <td><code>{{ provider.realtime.route_type }}</code></td>
      <td>{{ provider.realtime.streaming | to_check }}</td>
      <td>{{ provider.realtime.model_example }}</td>
      <td>{{ provider.realtime.min_version }}</td>
    </tr>
    {% endif %}
  </tbody>
</table>

{% if provider.realtime.note.content %}

<sup>{{ realtime_note_num }}</sup> {{ provider.realtime.note.content }}
{% endif %}
{% endif %}

{% else %}
Provider "{{ include.provider_name }}" not found.
{% endif %}