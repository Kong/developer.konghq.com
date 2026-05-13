---
title: Voice AI Pipeline Observability
description: Observe and govern a cascading voice AI pipeline (STT, LLM, TTS) with per-hop telemetry and conversation-level tracing through Langfuse.
url: "/cookbooks/voice-ai-observability/"
content_type: cookbook
layout: cookbook
products:
  - ai-gateway
tools:
  - kongctl
canonical: true
works_on:
  - konnect
min_version:
  gateway: '3.14'
categories:
  - observability
  - llm
featured: true
popular: false

# Machine-readable fields for AI agent setup
plugins:
  - ai-proxy-advanced
  - opentelemetry
  - key-auth
requires_embeddings: false
providers:
  - openai
  - anthropic
  - bedrock
  - azure
  - gemini
  - mistral

hint: "Requires an OpenAI API key (for STT/TTS), LLM provider credentials, a Langfuse account, and Python 3.11+."
prereqs:
  skip_product: true
  skip_tool: true
  inline:
    - title: "{{site.konnect_product_name}}"
      content: |
        This tutorial uses {{site.konnect_product_name}}. The [quickstart script](https://get.konghq.com/quickstart) provisions a recipe-scoped Control Plane and local Data Plane.

        1. Create a new personal access token by opening the [Konnect PAT page](https://cloud.konghq.com/global/account/tokens) and selecting **Generate Token**.
        1. Export your token. The same token is reused later for kongctl commands:

           ```bash
           export KONNECT_TOKEN='YOUR_KONNECT_PAT'
           ```

        1. Set the recipe-scoped control plane name and run the quickstart script. The two `-e` flags pass non-default tracing settings into the Data Plane container; the [OpenTelemetry](/plugins/opentelemetry/) Plugin will not export traces unless the Data Plane is started with `KONG_TRACING_INSTRUMENTATIONS` enabled, and the default sampling rate (`0.01`) drops 99% of spans before the Plugin sees them:

           ```bash
           export KONNECT_CONTROL_PLANE_NAME='voice-ai-observability-recipe'
           curl -Ls https://get.konghq.com/quickstart | \
             bash -s -- -k $KONNECT_TOKEN \
               -e KONG_TRACING_INSTRUMENTATIONS=all \
               -e KONG_TRACING_SAMPLING_RATE=1.0 \
               --deck-output
           ```

           This provisions a Konnect Control Plane named `voice-ai-observability-recipe`, a local Data Plane connected to it with tracing enabled, and prints `export` lines for the rest of the session vars. Paste those into your shell when prompted.
    - title: kongctl + decK
      content: |
        This tutorial uses [kongctl](/kongctl/) and [decK](/deck/) to manage Kong configuration.

        1. Install **kongctl** from [developer.konghq.com/kongctl](/kongctl/).
        1. Install **decK** version 1.43 or later from [docs.konghq.com/deck](https://docs.konghq.com/deck/).
        1. Verify both are installed:

           ```bash
           kongctl version
           deck version
           ```
    - title: AI Credentials
      content: |
        Every provider tab uses OpenAI for the STT and TTS hops (Whisper and TTS-1), so an OpenAI key is required regardless of which LLM provider you pick. Configure the LLM provider you plan to use as well.

        1. [Create an OpenAI account](https://auth.openai.com/create-account).
        1. [Get an API key](https://platform.openai.com/api-keys).
        1. Export the OpenAI key (used by all providers for STT and TTS):

           ```sh
           export DECK_OPENAI_TOKEN='Bearer sk-YOUR-KEY'
           ```

        Then configure your LLM provider:

        {% navtabs "Providers" %}
        {% navtab "OpenAI" %}
        Already covered above. The same `DECK_OPENAI_TOKEN` is used for STT, TTS, and the LLM hop.
        {% endnavtab %}
        {% navtab "Anthropic" %}
        1. [Create an Anthropic account](https://console.anthropic.com/).
        1. [Get an API key](https://console.anthropic.com/settings/keys).
        1. Create decK variables for the API key and the [Messages API schema version](https://docs.claude.com/en/api/versioning) Kong should send upstream on every request:

           ```sh
           export DECK_ANTHROPIC_TOKEN='YOUR-ANTHROPIC-KEY'
           export DECK_ANTHROPIC_VERSION='2023-06-01'
           ```
        {% endnavtab %}
        {% navtab "AWS Bedrock" %}
        1. Ensure you have an AWS account with [Bedrock model access](https://docs.aws.amazon.com/bedrock/latest/userguide/model-access.html) enabled.
        1. Create decK variables with your AWS credentials:

           ```sh
           export DECK_AWS_ACCESS_KEY_ID='your-access-key'
           export DECK_AWS_SECRET_ACCESS_KEY='your-secret-key'
           export DECK_AWS_REGION='us-east-1'
           ```
        {% endnavtab %}
        {% navtab "Azure" %}
        1. [Create an Azure OpenAI resource](https://portal.azure.com/#create/Microsoft.CognitiveServicesOpenAI).
        1. Deploy a model and note your instance name, deployment ID, and API version.
        1. Create decK variables:

           ```sh
           export DECK_AZURE_API_KEY='your-azure-api-key'
           export DECK_AZURE_INSTANCE='your-instance-name'
           export DECK_AZURE_DEPLOYMENT_ID='your-deployment-id'
           export DECK_AZURE_API_VERSION='YOUR-API-VERSION'  # check Azure docs for current version
           ```
        {% endnavtab %}
        {% navtab "Google Gemini" %}
        1. [Create a Google Cloud project](https://console.cloud.google.com/) with Vertex AI enabled.
        1. Create a service account and mount the JSON key file in your Kong container.
        1. Create decK variables:

           ```sh
           export DECK_GCP_API_ENDPOINT='your-api-endpoint'
           export DECK_GCP_PROJECT_ID='your-project-id'
           export DECK_GCP_LOCATION_ID='us-central1'
           ```
        {% endnavtab %}
        {% navtab "Mistral" %}
        1. [Create a Mistral account](https://console.mistral.ai/).
        1. [Get an API key](https://console.mistral.ai/api-keys/).
        1. Create a decK variable with the API key:

           ```sh
           export DECK_MISTRAL_TOKEN='Bearer your-mistral-key'
           ```
        {% endnavtab %}
        {% endnavtabs %}
    - title: Langfuse
      content: |
        [Langfuse](https://langfuse.com) is an open-source observability platform that receives OpenTelemetry traces and groups them into conversation-level sessions. This recipe exports Kong's `gen_ai.*` spans to Langfuse for per-hop and conversation-level analysis.

        Langfuse authenticates OTLP ingestion with HTTP Basic Auth, where the username is your project's **Public Key** (`pk-lf-...`) and the password is its **Secret Key** (`sk-lf-...`).

        1. Sign up for Langfuse Cloud (free tier) on the region you want to use, or [self-host Langfuse v3.22.0 or later](https://langfuse.com/self-hosting) using Docker Compose. OTLP ingestion is only available on self-hosted Langfuse v3.22.0+. Each region is a fully separate deployment with its own UI, account, projects, and API keys. Keys issued in one region will not authenticate against another, so pick one and stick with it:

           - **US**: [us.cloud.langfuse.com](https://us.cloud.langfuse.com)
           - **EU**: [cloud.langfuse.com](https://cloud.langfuse.com)
           - **HIPAA**: [hipaa.cloud.langfuse.com](https://hipaa.cloud.langfuse.com)
        1. Create a project and copy the **Public Key** and **Secret Key** from the project settings.
        1. Export both keys and the OTLP endpoint for the **same region** you signed up under, then derive the Basic Auth header from them:

           ```bash
           export DECK_LANGFUSE_PUBLIC_KEY='pk-lf-YOUR-PUBLIC-KEY'
           export DECK_LANGFUSE_SECRET_KEY='sk-lf-YOUR-SECRET-KEY'
           # Pick the endpoint that matches the region you signed up under:
           #   US:    https://us.cloud.langfuse.com/api/public/otel/v1/traces
           #   EU:    https://cloud.langfuse.com/api/public/otel/v1/traces
           #   HIPAA: https://hipaa.cloud.langfuse.com/api/public/otel/v1/traces
           export DECK_LANGFUSE_OTLP_ENDPOINT='https://us.cloud.langfuse.com/api/public/otel/v1/traces'
           export DECK_LANGFUSE_AUTH_HEADER="Basic $(printf '%s:%s' "$DECK_LANGFUSE_PUBLIC_KEY" "$DECK_LANGFUSE_SECRET_KEY" | base64 | tr -d '\n')"
           ```

           The `tr -d '\n'` strips the newline that GNU `base64` inserts after 76 characters, which would otherwise corrupt the `Authorization` header. If your endpoint and key region don't match, Langfuse will return `401 Unauthorized` on every trace export.

           For self-hosted Langfuse, set the endpoint to `http://host.docker.internal:3000/api/public/otel/v1/traces` so the Kong container can reach Langfuse on the host.
    - title: Python 3.11+
      icon_url: /assets/icons/python.svg
      content: |
        The demo script requires Python 3.11 or later. Set up an isolated environment:

        ```bash
        python3 -m venv .venv
        source .venv/bin/activate
        pip install 'openai>=1.0.0' 'opentelemetry-api>=1.27.0' 'opentelemetry-sdk>=1.27.0' 'opentelemetry-exporter-otlp-proto-http>=1.27.0' 'opentelemetry-instrumentation-httpx>=0.48b0'
        ```

        The demo uses the OpenTelemetry SDK plus the httpx auto-instrumentation to emit a `voice-turn` parent span per turn and to inject W3C `traceparent` into every outbound call so Kong's per-hop spans nest correctly under it in Langfuse.

overview: |
  A production voice AI system is a pipeline: speech-to-text (STT), LLM reasoning, and text-to-speech (TTS) execute in sequence for every conversational turn. Each hop carries its own latency budget, error modes, and cost profile. This recipe sets up {{site.ai_gateway_name}} to govern all three hops through separate Routes, each with its own [AI Proxy Advanced](/plugins/ai-proxy-advanced/) instance. The [Key Auth](/plugins/key-auth/) Plugin identifies the calling voice agent on every hop, and a global [OpenTelemetry](/plugins/opentelemetry/) Plugin exports `gen_ai.*` spans to [Langfuse](https://langfuse.com) for per-hop latency, token usage, and cost visibility, with conversation-level trace grouping for full-turn analysis.

  By the end, you will have three Kong endpoints (`/stt`, `/llm`, `/tts`) proxying a complete voice pipeline behind a single API key, with every hop producing OpenTelemetry traces that appear as a single conversation trace in Langfuse.
---

## The problem

Voice AI systems present observability challenges that text-based LLM applications do not face. The core difficulty is that a single conversational turn requires multiple API calls in sequence, each with distinct providers, latency characteristics, and failure modes.

- **Three independent failure surfaces per turn.** A cascading voice pipeline makes at least three API calls for every user interaction: STT (audio to text), LLM (text to response), and TTS (response to audio). Each hop can fail independently. The STT Service may return a low-confidence transcription. The LLM may time out. The TTS Service may rate-limit. When a user reports that "the call sounded broken," you need to identify which hop failed, but each provider has its own dashboard and log format with no shared correlation identifier.

- **The observable unit is a conversation, not a request.** Users do not experience individual API calls. They experience a phone call or voice interaction spanning dozens of turns. Turn 3 completed in 400ms, but turn 7 had a 3-second TTS timeout. Traditional API monitoring shows average latency across all requests. It does not show latency progression within a conversation. Debugging user-reported issues requires conversation-scoped traces that group all hops from all turns under a single identifier.

- **Latency budgets compound across hops.** Natural-sounding voice interaction requires end-to-end turn latency under approximately 800ms. STT taking 350ms eats into the LLM's budget. A 200ms LLM response leaves only 250ms for TTS. Monitoring each hop in isolation does not reveal the cascading impact. You need a waterfall view showing how latency distributes across the pipeline so you can identify which hop is consuming the budget.

- **Credential management scales with the pipeline.** A text-only LLM application manages one provider's credentials. A voice pipeline manages three: STT provider keys, LLM provider keys, and TTS provider keys. Each has its own rotation policy, billing dashboard, and rate limits. Switching STT providers (Deepgram to Whisper, or Whisper to a self-hosted model) means re-tooling authentication, monitoring, and cost tracking for that hop across every Service that calls it.

- **Cost attribution is per-model, but budgets are per-conversation.** LLM providers charge per token. STT providers charge per audio-second. TTS providers charge per character. Building a cost-per-minute or cost-per-conversation view requires normalizing these different units and correlating charges across hops that run on separate billing systems.

The alternative to the cascading pipeline is realtime speech-to-speech APIs (OpenAI Realtime, Gemini Live), which use a single WebSocket connection to a multimodal model that ingests and emits audio natively. Latency drops sharply, but per-hop observability disappears by design: there are no separate STT, LLM, or TTS stages to instrument. Regulated industries (finance, healthcare, legal) remain on cascading architectures because the text intermediary between STT and TTS provides an audit trail and a checkpoint for compliance checks before responses are spoken.

## The solution

This recipe places {{site.ai_gateway_name}} between the voice agent and all three providers. Each pipeline hop gets its own Kong Service, Route, and [AI Proxy Advanced](/plugins/ai-proxy-advanced/) Plugin instance. The [Key Auth](/plugins/key-auth/) Plugin identifies the calling voice agent on every hop, and a global [OpenTelemetry](/plugins/opentelemetry/) Plugin exports `gen_ai.*` spans from every hop to Langfuse, where they appear as a single conversation trace.

{% table %}
columns:
  - title: Component
    key: component
  - title: Role
    key: role
rows:
  - component: "`voice-ai-stt` Service"
    role: Routes audio to OpenAI Whisper for transcription (`audio/v1/audio/transcriptions`)
  - component: "`voice-ai-llm` Service"
    role: Routes text to any supported LLM provider (`llm/v1/chat`), provider varies per tab
  - component: "`voice-ai-tts` Service"
    role: Routes text to OpenAI TTS for speech synthesis (`audio/v1/audio/speech`)
  - component: AI Proxy Advanced (3 instances)
    role: Injects credentials, handles format translation, emits per-hop telemetry
  - component: Key Auth Plugin (global)
    role: Authenticates the voice agent with a shared `apikey` header on every Route
  - component: OpenTelemetry Plugin (global)
    role: Exports `gen_ai.*` spans with provider, model, token usage, and latency to Langfuse
  - component: Langfuse
    role: Groups spans by W3C trace ID into conversation-level traces for full-turn visibility
{% endtable %}

All three calls share a single W3C trace ID, which Langfuse uses to group the per-hop spans into one conversation-level trace.

<!-- vale off -->
{% mermaid %}
sequenceDiagram
    participant V as Voice Agent
    participant K as {{site.ai_gateway_name}}
    participant P as Provider (Whisper / LLM / TTS)
    participant Lf as Langfuse

    V->>K: POST /stt (apikey, audio)
    activate K
    K->>K: key-auth + ai-proxy-advanced (inject OpenAI creds)
    K->>P: Whisper transcription
    activate P
    P-->>K: Transcription
    deactivate P
    K->>Lf: gen_ai.* span (STT)
    K-->>V: Transcription
    deactivate K

    V->>K: POST /llm (apikey, text)
    activate K
    K->>K: key-auth + ai-proxy-advanced (translate format, inject creds)
    K->>P: LLM completion
    activate P
    P-->>K: Response
    deactivate P
    K->>Lf: gen_ai.* span (LLM)
    K-->>V: Text response
    deactivate K

    V->>K: POST /tts (apikey, text)
    activate K
    K->>K: key-auth + ai-proxy-advanced (inject OpenAI creds)
    K->>P: TTS synthesis
    activate P
    P-->>K: Audio
    deactivate P
    K->>Lf: gen_ai.* span (TTS)
    K-->>V: Audio
    deactivate K
{% endmermaid %}
<!-- vale on -->

Kong decouples the voice agent from individual providers. Swap the LLM from OpenAI to Anthropic by changing a tab and re-applying. Replace Whisper with a self-hosted STT model by updating one Service target. The observability contract (same `gen_ai.*` spans, same Prometheus labels, same Langfuse trace structure) stays identical regardless of which providers sit behind the gateway.

## How it works

### Tracing terminology

OpenTelemetry's vocabulary shows up in several places below; here is what each term means in this recipe.

- **Span**. One unit of work with a start, an end, and attributes. Examples here include the `voice-turn` parent span the demo opens, the `kong.access.plugin.ai-proxy-advanced` Plugin-phase span Kong emits, and the `gen_ai.*` generation span Kong populates from the provider response.
- **Trace**. A tree of spans sharing one `trace_id` that represents a single logical operation. In this recipe, that means one voice turn (STT → LLM → TTS).
- **Root span**. The top of the tree; everything else is a descendant. The demo's `voice-turn` span is the root, and Kong's per-hop spans nest below the demo's httpx client spans.
- **`traceparent` header**. The W3C-standard HTTP header that carries the active `trace_id` and parent `span_id` across services. The demo's httpx instrumentation injects it on every outbound call; Kong's OpenTelemetry Plugin extracts it on every inbound request.
- **Propagation**. The act of moving trace context from one process to another via headers like `traceparent`. Without it, each Service emits its own disconnected trace.
- **Exporter**. The component that ships finished spans to a backend over OTLP. The demo SDK and Kong's Plugin each run their own exporter, both pointed at Langfuse.
- **Session (Langfuse-specific)**. A grouping of multiple traces under one logical conversation, keyed by the `langfuse.session.id` attribute on the root span of each trace.

### Per-turn flow

When the demo processes a conversational turn, it makes three sequential requests through Kong:

1. **Authenticate at the gateway.** Every request includes the `apikey` header. The Key Auth Plugin matches the value against the registered Consumer (`voice-agent`) before any AI Proxy Advanced logic runs. Unknown keys are rejected with `401 Unauthorized`.

2. **STT hop.** The agent sends an audio file to `/voice-ai-observability/stt`. The AI Proxy Advanced Plugin on this Route injects OpenAI credentials, forwards the audio to Whisper's transcription endpoint, and logs the result. The OpenTelemetry Plugin emits a `gen_ai.*` span with the provider name (`openai`), model (`whisper-1`), and operation metadata.

3. **LLM hop.** The agent sends the transcribed text to `/voice-ai-observability/llm`. The AI Proxy Advanced Plugin on this Route injects the configured LLM provider's credentials, translates the request format if needed (for example, OpenAI format to Anthropic's messages API), and forwards to the provider. The span includes `gen_ai.usage.input_tokens` and `gen_ai.usage.output_tokens` for cost attribution.

4. **TTS hop.** The agent sends the LLM response text to `/voice-ai-observability/tts`. The AI Proxy Advanced Plugin injects OpenAI credentials and forwards to the TTS endpoint. The response is raw audio bytes returned to the agent.

5. **Trace and Session grouping.** Before any HTTP call, the voice agent (the demo) opens a `voice-turn` parent span via the OpenTelemetry SDK and tags it with `langfuse.session.id`. The httpx auto-instrumentation in the demo wraps the OpenAI SDK's underlying httpx client, so every STT/LLM/TTS call becomes a child span of `voice-turn` and a real W3C `traceparent` is injected into the outbound request. Kong's OpenTelemetry Plugin extracts that `traceparent` and roots its per-hop server, Plugin, balancer, dns, and `gen_ai.*` spans as descendants of the demo's httpx client span. Both exporters ship spans to Langfuse independently; Langfuse reassembles by `trace_id`. The `langfuse.session.id` attribute on the root span tells Langfuse to roll multiple per-turn traces up under one Session for cross-turn analysis.

### Key Auth: Voice agent identification

The [Key Auth](/plugins/key-auth/) Plugin authenticates the calling voice agent before any per-hop logic runs. It is configured at the global level so all three Routes (`/stt`, `/llm`, `/tts`) require the same `apikey` header. The recipe defines a single `voice-agent` Consumer with a static credential. In production, replace this with one Consumer per tenant or per voice client, rotated through [Kong Vaults](/gateway/secrets-management/).

#### Configuration details

```yaml
plugins:
  - name: key-auth
    config:
      key_names:
        - apikey
      hide_credentials: true

consumers:
  - username: voice-agent
    keyauth_credentials:
      - key: voice-demo-key
```
{:.no-copy-code}

- **`key_names: [apikey]`**. The header (or query parameter) the Plugin reads to identify the Consumer. Clients send `apikey: voice-demo-key`. See the [Key Auth reference](/plugins/key-auth/) for the full list of recognized parameter sources.
- **`hide_credentials: true`**. Strips the credential from the request before it reaches the upstream provider. Without this, the `apikey` header would be forwarded to OpenAI, Anthropic, etc., leaking the gateway-side credential into provider logs.
- **`consumers[].keyauth_credentials[].key`**. The credential the Consumer presents. For non-trivial deployments, generate per-Consumer keys with `kongctl create consumer-credential` or rotate via [Kong Vaults](/gateway/secrets-management/).

For richer identity flows (JWT-based SSO, scoped audiences, IdP integration), swap Key Auth for the [OpenID Connect](/plugins/openid-connect/) Plugin. The [Claude Code SSO recipe](/cookbooks/claude-code-sso/) shows the pattern.

### AI Proxy Advanced: Speech-to-text transcription

The STT Service uses the [AI Proxy Advanced](/plugins/ai-proxy-advanced/) Plugin with `genai_category: audio/transcription` to route audio files to OpenAI's Whisper model. This is the entry point of the cascading pipeline: raw audio goes in, transcribed text comes out. By routing STT through Kong instead of calling Whisper directly, you get credential injection, payload logging, and `gen_ai.*` telemetry on the transcription hop without instrumenting your application code.

#### Configuration details

```yaml
plugins:
  - name: ai-proxy-advanced
    config:
      genai_category: audio/transcription
      max_request_body_size: 26214400
      response_streaming: deny
      targets:
        - route_type: audio/v1/audio/transcriptions
          auth:
            header_name: Authorization
            header_value: "Bearer <openai-key>"
          logging:
            log_payloads: true
          model:
            provider: openai
            name: whisper-1
```
{:.no-copy-code}

- **`genai_category: audio/transcription`**. Classifies this Plugin instance as an audio transcription operation. Kong uses this category for Prometheus metric labels (`genai_category=audio/transcription`) and OpenTelemetry span attributes, separating STT metrics from LLM and TTS traffic.
- **`max_request_body_size: 26214400`**. Raises the request body limit to 25 MB. Audio files can be several megabytes, and the default limit rejects most audio uploads. Set this to at least three times the expected raw audio file size, per the [AI Proxy Advanced documentation](/plugins/ai-proxy-advanced/).
- **`response_streaming: deny`**. Whisper returns the full transcript in one response. Streaming would add complexity for no benefit, so the Plugin is configured to refuse streaming requests on this Route.
- **`route_type: audio/v1/audio/transcriptions`**. Selects the Whisper transcription endpoint. The Plugin supports several other audio operations on the same target type. See the [AI Proxy Advanced route types](/plugins/ai-proxy-advanced/) for the current list.
- **`logging.log_payloads`**. Includes request and response bodies in log output. For STT, this captures the transcription text. Disable in production if audio payloads contain sensitive content.
- **No `log_statistics`**. Kong's AI Proxy Advanced Plugin rejects `log_statistics` on `audio/*` route types because token-counting concepts don't map onto audio operations. Statistics-style metrics (count, latency, request volume) for audio hops still come from Kong's Prometheus exporter labelled with `genai_category=audio/transcription` and `audio/speech`; this option is reserved for `llm/*` route types only.

### AI Proxy Advanced: LLM chat completion

The LLM Service handles the reasoning hop of the pipeline. This is the only Service that varies by provider: the auth block, model name, and provider-specific options change depending on which tab you select. The `route_type: llm/v1/chat` target accepts OpenAI-format chat completion requests, and Kong translates them to the upstream provider's native format when needed.

#### Configuration details

```yaml
plugins:
  - name: ai-proxy-advanced
    config:
      max_request_body_size: 8388608
      response_streaming: allow
      targets:
        - route_type: llm/v1/chat
          auth:
            header_name: Authorization
            header_value: "Bearer <provider-key>"
          logging:
            log_statistics: true
            log_payloads: true
          model:
            provider: openai
            name: gpt-4o
```
{:.no-copy-code}

- **`max_request_body_size: 8388608`**. Allows up to 8 MB of request body. Long conversation histories, large system prompts, and tool-call payloads can exceed the default limit.
- **`response_streaming: allow`**. Lets clients request server-sent events for token-by-token chat responses. The recipe demo does not stream, but production voice agents often do to start TTS earlier in the turn.
- **`route_type: llm/v1/chat`**. Selects the chat completions translation path. The Plugin accepts OpenAI-format request bodies and translates them to the upstream provider's native format. Responses are normalized back to OpenAI format. To pass requests through in a provider's native format, set `llm_format` (for example `anthropic`, `bedrock`, `gemini`) on the Plugin config; see the [AI Proxy Advanced documentation](/plugins/ai-proxy-advanced/) for the full route-type and llm_format support matrix.
- **`auth`**. The auth block varies by provider. OpenAI and Mistral use `Authorization: Bearer <key>`, Anthropic uses `x-api-key`, Azure uses `api-key`, Bedrock uses AWS access key pairs, and Gemini uses GCP service account credentials. Kong injects these into every upstream request. Clients send a placeholder credential.
- **`model.provider`** and **`model.name`**. Identify the upstream LLM. The model name resolves from the `DECK_CHAT_MODEL` environment variable at apply time, so you can switch models without editing the deck file.
- **`logging.log_statistics` and `logging.log_payloads`**. Statistics capture prompt and completion token counts; payload logging captures the full prompt and reply text. The `gen_ai.input.messages` and `gen_ai.output.messages` span attributes in the OpenTelemetry trace also contain this data when payload logging is enabled.

### AI Proxy Advanced: Text-to-speech synthesis

The TTS Service converts the LLM response to audio, completing the cascading pipeline. Like the STT Service, it is fixed to OpenAI (TTS-1 model) across all provider tabs. Routing TTS through Kong gives you the same telemetry contract as the other hops: credential injection, usage logging, and `gen_ai.*` span emission.

#### Configuration details

```yaml
plugins:
  - name: ai-proxy-advanced
    config:
      genai_category: audio/speech
      max_request_body_size: 1048576
      response_streaming: allow
      targets:
        - route_type: audio/v1/audio/speech
          auth:
            header_name: Authorization
            header_value: "Bearer <openai-key>"
          logging:
            log_payloads: true
          model:
            provider: openai
            name: tts-1
```
{:.no-copy-code}

- **`genai_category: audio/speech`**. Classifies this as a text-to-speech operation. Prometheus metrics and OTel spans are labeled accordingly, so you can filter TTS latency and cost separately from STT and LLM traffic.
- **`max_request_body_size: 1048576`**. TTS input is plain text, so 1 MB is generous. Set this lower if your voice agent never sends prompts above a few KB.
- **`response_streaming: allow`**. Lets clients request streamed audio chunks instead of waiting for the entire synthesis to finish. Production voice agents use this to begin playback as soon as the first chunk arrives.
- **`route_type: audio/v1/audio/speech`**. Selects the TTS endpoint. The response is raw audio bytes (MP3 by default). The client can request other formats via the `response_format` field in the request body. See the [AI Proxy Advanced reference](/plugins/ai-proxy-advanced/) for supported audio formats and voices.
- **`model.name: tts-1`**. OpenAI's standard TTS model. Available voices and higher-quality model variants are listed in the [OpenAI TTS documentation](https://platform.openai.com/docs/guides/text-to-speech).

### OpenTelemetry: Trace export to Langfuse

The [OpenTelemetry](/plugins/opentelemetry/) Plugin runs as a global Plugin (not scoped to a single Service), so it captures traces from all three pipeline hops. It exports spans to Langfuse's OTLP endpoint, where they are grouped by W3C trace ID into conversation-level traces.

#### Configuration details

```yaml
plugins:
  - name: opentelemetry
    config:
      traces_endpoint: "https://us.cloud.langfuse.com/api/public/otel/v1/traces"
      headers:
        Authorization: "Basic <base64-encoded-credentials>"
        x-langfuse-ingestion-version: "4"
      sampling_rate: 1
      propagation:
        default_format: w3c
```
{:.no-copy-code}

- **`traces_endpoint`**. The OTLP/HTTP endpoint where Kong sends trace data. For Langfuse Cloud, use `https://us.cloud.langfuse.com/api/public/otel/v1/traces` (US) or `https://cloud.langfuse.com/api/public/otel/v1/traces` (EU). For self-hosted Langfuse, use `http://host.docker.internal:3000/api/public/otel/v1/traces`.
- **`headers.Authorization`**. Basic auth header constructed from your Langfuse public key and secret key: `Basic <base64(pk:sk)>`. This authenticates trace export to your Langfuse project.
- **`headers.x-langfuse-ingestion-version: "4"`**. Enables Langfuse's real-time Fast Preview display for incoming traces.
- **`sampling_rate: 1`**. Samples 100% of requests. Reduce this in high-traffic production environments to control trace volume and cost.
- **`propagation.default_format: w3c`**. Uses W3C Trace Context for trace ID propagation. When a client sends a `traceparent` header, the Plugin preserves that trace ID on the emitted span. This is how multiple requests (STT, LLM, TTS) get grouped under a single trace.

Kong emits `gen_ai.*` span attributes on every AI Proxy Advanced request (v3.13+). These attributes follow the [OpenTelemetry GenAI semantic conventions](https://opentelemetry.io/docs/specs/semconv/registry/attributes/gen-ai/) and include:

{% table %}
columns:
  - title: Attribute
    key: attribute
  - title: Description
    key: description
rows:
  - attribute: "`gen_ai.provider.name`"
    description: "Provider identifier (for example, `openai`, `anthropic`)"
  - attribute: "`gen_ai.request.model`"
    description: Model name from the request
  - attribute: "`gen_ai.response.model`"
    description: Model name from the provider response
  - attribute: "`gen_ai.operation.name`"
    description: "Operation type (`chat`, `embeddings`)"
  - attribute: "`gen_ai.usage.input_tokens`"
    description: Input token count
  - attribute: "`gen_ai.usage.output_tokens`"
    description: Output token count
  - attribute: "`gen_ai.input.messages`"
    description: Full input messages (when payload logging enabled)
  - attribute: "`gen_ai.output.messages`"
    description: Full output messages (when payload logging enabled)
{% endtable %}

### Production considerations

{:.info}
> In production, store credentials in [Kong Vaults](/gateway/secrets-management/) using {%raw%}`{vault://backend/key}`{%endraw%} references rather than environment variables. Kong supports HashiCorp Vault, AWS Secrets Manager, GCP Secret Manager, and the Konnect Config Store.

The `gen_ai.input.messages` and `gen_ai.output.messages` span attributes capture full prompt and response payloads. Review your data retention and access control policies before enabling payload logging in production, as these attributes may contain PII, sensitive business context, or credentials passed in prompts.

## Apply the Kong configuration

This section configures the Control Plane in two parts. First, adopt the quickstart Control Plane into a kongctl namespace so the apply commands below can manage it. The recipe's `select_tags` and the `voice-ai-observability-recipe` namespace scope every resource so teardown removes only this recipe's configuration.

```bash
kongctl adopt control-plane "${KONNECT_CONTROL_PLANE_NAME}" \
  --namespace "${KONNECT_CONTROL_PLANE_NAME}" \
  --pat "${KONNECT_TOKEN}"
```

Adoption stamps the `KONGCTL-namespace` label on the Control Plane.

The configuration creates three Kong Services and Routes (`/stt`, `/llm`, `/tts`), each with an [AI Proxy Advanced](/plugins/ai-proxy-advanced/) Plugin handling credential injection and telemetry, plus a global [Key Auth](/plugins/key-auth/) Plugin for voice agent identification, a global [OpenTelemetry](/plugins/opentelemetry/) Plugin exporting traces to Langfuse, and a `voice-agent` Consumer with the `voice-demo-key` API key.

Select your LLM provider below, export the per-tab environment variables, and apply. The STT and TTS hops use OpenAI regardless of which LLM provider you choose, so `DECK_OPENAI_TOKEN`, `DECK_LANGFUSE_OTLP_ENDPOINT`, and `DECK_LANGFUSE_AUTH_HEADER` are exported once during the prerequisites and reused across tabs.

{% navtabs "Providers" %}
{% tab OpenAI %}

Export the per-tab environment variable:

```bash
export DECK_CHAT_MODEL='gpt-4o'  # or gpt-4o-mini, o3
```

Apply the Kong configuration:

```bash
{%- raw %}
cat <<'EOF' > kong-recipe.yaml
_format_version: '3.0'
_info:
  select_tags:
  - voice-ai-observability-recipe
services:
- name: voice-ai-stt
  url: http://localhost
  routes:
  - name: voice-ai-stt
    paths:
    - /voice-ai-observability/stt
    protocols:
    - http
    - https
    methods:
    - POST
    - OPTIONS
    strip_path: true
  plugins:
  - name: ai-proxy-advanced
    instance_name: voice-ai-stt-proxy
    config:
      genai_category: audio/transcription
      max_request_body_size: 26214400
      response_streaming: deny
      targets:
      - route_type: audio/v1/audio/transcriptions
        auth:
          header_name: Authorization
          header_value: ${{ env "DECK_OPENAI_TOKEN" }}
        logging:
          log_payloads: true
        model:
          provider: openai
          name: whisper-1
- name: voice-ai-llm
  url: http://localhost
  routes:
  - name: voice-ai-llm
    paths:
    - /voice-ai-observability/llm
    protocols:
    - http
    - https
    methods:
    - POST
    - OPTIONS
    strip_path: true
  plugins:
  - name: ai-proxy-advanced
    instance_name: voice-ai-llm-proxy
    config:
      max_request_body_size: 8388608
      response_streaming: allow
      targets:
      - route_type: llm/v1/chat
        auth:
          header_name: Authorization
          header_value: ${{ env "DECK_OPENAI_TOKEN" }}
        logging:
          log_statistics: true
          log_payloads: true
        model:
          provider: openai
          name: ${{ env "DECK_CHAT_MODEL" }}
- name: voice-ai-tts
  url: http://localhost
  routes:
  - name: voice-ai-tts
    paths:
    - /voice-ai-observability/tts
    protocols:
    - http
    - https
    methods:
    - POST
    - OPTIONS
    strip_path: true
  plugins:
  - name: ai-proxy-advanced
    instance_name: voice-ai-tts-proxy
    config:
      genai_category: audio/speech
      max_request_body_size: 1048576
      response_streaming: allow
      targets:
      - route_type: audio/v1/audio/speech
        auth:
          header_name: Authorization
          header_value: ${{ env "DECK_OPENAI_TOKEN" }}
        logging:
          log_payloads: true
        model:
          provider: openai
          name: tts-1
plugins:
- name: key-auth
  instance_name: voice-ai-observability-auth
  config:
    key_names:
    - apikey
    hide_credentials: true
- name: opentelemetry
  instance_name: voice-ai-observability-otel
  config:
    traces_endpoint: ${{ env "DECK_LANGFUSE_OTLP_ENDPOINT" }}
    headers:
      Authorization: ${{ env "DECK_LANGFUSE_AUTH_HEADER" }}
      x-langfuse-ingestion-version: '4'
    sampling_rate: 1
    propagation:
      default_format: w3c
consumers:
- username: voice-agent
  keyauth_credentials:
  - key: voice-demo-key
EOF
{% endraw -%}

echo "
_defaults:
  kongctl:
    namespace: voice-ai-observability-recipe
control_planes:
  - ref: recipe-cp
    name: \"${KONNECT_CONTROL_PLANE_NAME}\"
    _deck:
      files:
        - kong-recipe.yaml
" | kongctl apply -f - -o text --auto-approve --pat "${KONNECT_TOKEN}"

rm -f kong-recipe.yaml
```
{: data-test-step="block" .collapsible }

{% endtab %}
{% tab Anthropic %}

Export the per-tab environment variable:

```bash
export DECK_CHAT_MODEL='claude-sonnet-4-5-20250929'  # or claude-haiku-4-5-20251001
```

Apply the Kong configuration:

```bash
{%- raw %}
cat <<'EOF' > kong-recipe.yaml
_format_version: '3.0'
_info:
  select_tags:
  - voice-ai-observability-recipe
services:
- name: voice-ai-stt
  url: http://localhost
  routes:
  - name: voice-ai-stt
    paths:
    - /voice-ai-observability/stt
    protocols:
    - http
    - https
    methods:
    - POST
    - OPTIONS
    strip_path: true
  plugins:
  - name: ai-proxy-advanced
    instance_name: voice-ai-stt-proxy
    config:
      genai_category: audio/transcription
      max_request_body_size: 26214400
      response_streaming: deny
      targets:
      - route_type: audio/v1/audio/transcriptions
        auth:
          header_name: Authorization
          header_value: ${{ env "DECK_OPENAI_TOKEN" }}
        logging:
          log_payloads: true
        model:
          provider: openai
          name: whisper-1
- name: voice-ai-llm
  url: http://localhost
  routes:
  - name: voice-ai-llm
    paths:
    - /voice-ai-observability/llm
    protocols:
    - http
    - https
    methods:
    - POST
    - OPTIONS
    strip_path: true
  plugins:
  - name: ai-proxy-advanced
    instance_name: voice-ai-llm-proxy
    config:
      max_request_body_size: 8388608
      response_streaming: allow
      targets:
      - route_type: llm/v1/chat
        auth:
          header_name: x-api-key
          header_value: ${{ env "DECK_ANTHROPIC_TOKEN" }}
        logging:
          log_statistics: true
          log_payloads: true
        model:
          provider: anthropic
          name: ${{ env "DECK_CHAT_MODEL" }}
          options:
            anthropic_version: ${{ env "DECK_ANTHROPIC_VERSION" }}
- name: voice-ai-tts
  url: http://localhost
  routes:
  - name: voice-ai-tts
    paths:
    - /voice-ai-observability/tts
    protocols:
    - http
    - https
    methods:
    - POST
    - OPTIONS
    strip_path: true
  plugins:
  - name: ai-proxy-advanced
    instance_name: voice-ai-tts-proxy
    config:
      genai_category: audio/speech
      max_request_body_size: 1048576
      response_streaming: allow
      targets:
      - route_type: audio/v1/audio/speech
        auth:
          header_name: Authorization
          header_value: ${{ env "DECK_OPENAI_TOKEN" }}
        logging:
          log_payloads: true
        model:
          provider: openai
          name: tts-1
plugins:
- name: key-auth
  instance_name: voice-ai-observability-auth
  config:
    key_names:
    - apikey
    hide_credentials: true
- name: opentelemetry
  instance_name: voice-ai-observability-otel
  config:
    traces_endpoint: ${{ env "DECK_LANGFUSE_OTLP_ENDPOINT" }}
    headers:
      Authorization: ${{ env "DECK_LANGFUSE_AUTH_HEADER" }}
      x-langfuse-ingestion-version: '4'
    sampling_rate: 1
    propagation:
      default_format: w3c
consumers:
- username: voice-agent
  keyauth_credentials:
  - key: voice-demo-key
EOF
{% endraw -%}

echo "
_defaults:
  kongctl:
    namespace: voice-ai-observability-recipe
control_planes:
  - ref: recipe-cp
    name: \"${KONNECT_CONTROL_PLANE_NAME}\"
    _deck:
      files:
        - kong-recipe.yaml
" | kongctl apply -f - -o text --auto-approve --pat "${KONNECT_TOKEN}"

rm -f kong-recipe.yaml
```
{: data-test-step="block" .collapsible }

{% endtab %}
{% tab AWS Bedrock %}

Export the per-tab environment variable:

```bash
export DECK_CHAT_MODEL='amazon.nova-pro-v1:0'  # or global.anthropic.claude-sonnet-4-5-20250929-v1:0
```

Apply the Kong configuration:

```bash
{%- raw %}
cat <<'EOF' > kong-recipe.yaml
_format_version: '3.0'
_info:
  select_tags:
  - voice-ai-observability-recipe
services:
- name: voice-ai-stt
  url: http://localhost
  routes:
  - name: voice-ai-stt
    paths:
    - /voice-ai-observability/stt
    protocols:
    - http
    - https
    methods:
    - POST
    - OPTIONS
    strip_path: true
  plugins:
  - name: ai-proxy-advanced
    instance_name: voice-ai-stt-proxy
    config:
      genai_category: audio/transcription
      max_request_body_size: 26214400
      response_streaming: deny
      targets:
      - route_type: audio/v1/audio/transcriptions
        auth:
          header_name: Authorization
          header_value: ${{ env "DECK_OPENAI_TOKEN" }}
        logging:
          log_payloads: true
        model:
          provider: openai
          name: whisper-1
- name: voice-ai-llm
  url: http://localhost
  routes:
  - name: voice-ai-llm
    paths:
    - /voice-ai-observability/llm
    protocols:
    - http
    - https
    methods:
    - POST
    - OPTIONS
    strip_path: true
  plugins:
  - name: ai-proxy-advanced
    instance_name: voice-ai-llm-proxy
    config:
      max_request_body_size: 8388608
      response_streaming: allow
      targets:
      - route_type: llm/v1/chat
        auth:
          aws_access_key_id: ${{ env "DECK_AWS_ACCESS_KEY_ID" }}
          aws_secret_access_key: ${{ env "DECK_AWS_SECRET_ACCESS_KEY" }}
        logging:
          log_statistics: true
          log_payloads: true
        model:
          provider: bedrock
          name: ${{ env "DECK_CHAT_MODEL" }}
          options:
            bedrock:
              aws_region: ${{ env "DECK_AWS_REGION" }}
- name: voice-ai-tts
  url: http://localhost
  routes:
  - name: voice-ai-tts
    paths:
    - /voice-ai-observability/tts
    protocols:
    - http
    - https
    methods:
    - POST
    - OPTIONS
    strip_path: true
  plugins:
  - name: ai-proxy-advanced
    instance_name: voice-ai-tts-proxy
    config:
      genai_category: audio/speech
      max_request_body_size: 1048576
      response_streaming: allow
      targets:
      - route_type: audio/v1/audio/speech
        auth:
          header_name: Authorization
          header_value: ${{ env "DECK_OPENAI_TOKEN" }}
        logging:
          log_payloads: true
        model:
          provider: openai
          name: tts-1
plugins:
- name: key-auth
  instance_name: voice-ai-observability-auth
  config:
    key_names:
    - apikey
    hide_credentials: true
- name: opentelemetry
  instance_name: voice-ai-observability-otel
  config:
    traces_endpoint: ${{ env "DECK_LANGFUSE_OTLP_ENDPOINT" }}
    headers:
      Authorization: ${{ env "DECK_LANGFUSE_AUTH_HEADER" }}
      x-langfuse-ingestion-version: '4'
    sampling_rate: 1
    propagation:
      default_format: w3c
consumers:
- username: voice-agent
  keyauth_credentials:
  - key: voice-demo-key
EOF
{% endraw -%}

echo "
_defaults:
  kongctl:
    namespace: voice-ai-observability-recipe
control_planes:
  - ref: recipe-cp
    name: \"${KONNECT_CONTROL_PLANE_NAME}\"
    _deck:
      files:
        - kong-recipe.yaml
" | kongctl apply -f - -o text --auto-approve --pat "${KONNECT_TOKEN}"

rm -f kong-recipe.yaml
```
{: data-test-step="block" .collapsible }

{% endtab %}
{% tab Azure %}

Export the per-tab environment variable:

```bash
export DECK_CHAT_MODEL='gpt-4o'  # matches your Azure deployment name
```

Apply the Kong configuration:

```bash
{%- raw %}
cat <<'EOF' > kong-recipe.yaml
_format_version: '3.0'
_info:
  select_tags:
  - voice-ai-observability-recipe
services:
- name: voice-ai-stt
  url: http://localhost
  routes:
  - name: voice-ai-stt
    paths:
    - /voice-ai-observability/stt
    protocols:
    - http
    - https
    methods:
    - POST
    - OPTIONS
    strip_path: true
  plugins:
  - name: ai-proxy-advanced
    instance_name: voice-ai-stt-proxy
    config:
      genai_category: audio/transcription
      max_request_body_size: 26214400
      response_streaming: deny
      targets:
      - route_type: audio/v1/audio/transcriptions
        auth:
          header_name: Authorization
          header_value: ${{ env "DECK_OPENAI_TOKEN" }}
        logging:
          log_payloads: true
        model:
          provider: openai
          name: whisper-1
- name: voice-ai-llm
  url: http://localhost
  routes:
  - name: voice-ai-llm
    paths:
    - /voice-ai-observability/llm
    protocols:
    - http
    - https
    methods:
    - POST
    - OPTIONS
    strip_path: true
  plugins:
  - name: ai-proxy-advanced
    instance_name: voice-ai-llm-proxy
    config:
      max_request_body_size: 8388608
      response_streaming: allow
      targets:
      - route_type: llm/v1/chat
        auth:
          header_name: api-key
          header_value: ${{ env "DECK_AZURE_API_KEY" }}
        logging:
          log_statistics: true
          log_payloads: true
        model:
          provider: azure
          name: ${{ env "DECK_CHAT_MODEL" }}
          options:
            azure_api_version: ${{ env "DECK_AZURE_API_VERSION" }}
            azure_deployment_id: ${{ env "DECK_AZURE_DEPLOYMENT_ID" }}
            azure_instance: ${{ env "DECK_AZURE_INSTANCE" }}
- name: voice-ai-tts
  url: http://localhost
  routes:
  - name: voice-ai-tts
    paths:
    - /voice-ai-observability/tts
    protocols:
    - http
    - https
    methods:
    - POST
    - OPTIONS
    strip_path: true
  plugins:
  - name: ai-proxy-advanced
    instance_name: voice-ai-tts-proxy
    config:
      genai_category: audio/speech
      max_request_body_size: 1048576
      response_streaming: allow
      targets:
      - route_type: audio/v1/audio/speech
        auth:
          header_name: Authorization
          header_value: ${{ env "DECK_OPENAI_TOKEN" }}
        logging:
          log_payloads: true
        model:
          provider: openai
          name: tts-1
plugins:
- name: key-auth
  instance_name: voice-ai-observability-auth
  config:
    key_names:
    - apikey
    hide_credentials: true
- name: opentelemetry
  instance_name: voice-ai-observability-otel
  config:
    traces_endpoint: ${{ env "DECK_LANGFUSE_OTLP_ENDPOINT" }}
    headers:
      Authorization: ${{ env "DECK_LANGFUSE_AUTH_HEADER" }}
      x-langfuse-ingestion-version: '4'
    sampling_rate: 1
    propagation:
      default_format: w3c
consumers:
- username: voice-agent
  keyauth_credentials:
  - key: voice-demo-key
EOF
{% endraw -%}

echo "
_defaults:
  kongctl:
    namespace: voice-ai-observability-recipe
control_planes:
  - ref: recipe-cp
    name: \"${KONNECT_CONTROL_PLANE_NAME}\"
    _deck:
      files:
        - kong-recipe.yaml
" | kongctl apply -f - -o text --auto-approve --pat "${KONNECT_TOKEN}"

rm -f kong-recipe.yaml
```
{: data-test-step="block" .collapsible }

{% endtab %}
{% tab Google Gemini %}

Export the per-tab environment variable:

```bash
export DECK_CHAT_MODEL='gemini-2.0-flash'  # or gemini-1.5-pro
```

Apply the Kong configuration:

```bash
{%- raw %}
cat <<'EOF' > kong-recipe.yaml
_format_version: '3.0'
_info:
  select_tags:
  - voice-ai-observability-recipe
services:
- name: voice-ai-stt
  url: http://localhost
  routes:
  - name: voice-ai-stt
    paths:
    - /voice-ai-observability/stt
    protocols:
    - http
    - https
    methods:
    - POST
    - OPTIONS
    strip_path: true
  plugins:
  - name: ai-proxy-advanced
    instance_name: voice-ai-stt-proxy
    config:
      genai_category: audio/transcription
      max_request_body_size: 26214400
      response_streaming: deny
      targets:
      - route_type: audio/v1/audio/transcriptions
        auth:
          header_name: Authorization
          header_value: ${{ env "DECK_OPENAI_TOKEN" }}
        logging:
          log_payloads: true
        model:
          provider: openai
          name: whisper-1
- name: voice-ai-llm
  url: http://localhost
  routes:
  - name: voice-ai-llm
    paths:
    - /voice-ai-observability/llm
    protocols:
    - http
    - https
    methods:
    - POST
    - OPTIONS
    strip_path: true
  plugins:
  - name: ai-proxy-advanced
    instance_name: voice-ai-llm-proxy
    config:
      max_request_body_size: 8388608
      response_streaming: allow
      targets:
      - route_type: llm/v1/chat
        auth:
          gcp_use_service_account: true
        logging:
          log_statistics: true
          log_payloads: true
        model:
          provider: gemini
          name: ${{ env "DECK_CHAT_MODEL" }}
          options:
            gemini:
              api_endpoint: ${{ env "DECK_GCP_API_ENDPOINT" }}
              project_id: ${{ env "DECK_GCP_PROJECT_ID" }}
              location_id: ${{ env "DECK_GCP_LOCATION_ID" }}
- name: voice-ai-tts
  url: http://localhost
  routes:
  - name: voice-ai-tts
    paths:
    - /voice-ai-observability/tts
    protocols:
    - http
    - https
    methods:
    - POST
    - OPTIONS
    strip_path: true
  plugins:
  - name: ai-proxy-advanced
    instance_name: voice-ai-tts-proxy
    config:
      genai_category: audio/speech
      max_request_body_size: 1048576
      response_streaming: allow
      targets:
      - route_type: audio/v1/audio/speech
        auth:
          header_name: Authorization
          header_value: ${{ env "DECK_OPENAI_TOKEN" }}
        logging:
          log_payloads: true
        model:
          provider: openai
          name: tts-1
plugins:
- name: key-auth
  instance_name: voice-ai-observability-auth
  config:
    key_names:
    - apikey
    hide_credentials: true
- name: opentelemetry
  instance_name: voice-ai-observability-otel
  config:
    traces_endpoint: ${{ env "DECK_LANGFUSE_OTLP_ENDPOINT" }}
    headers:
      Authorization: ${{ env "DECK_LANGFUSE_AUTH_HEADER" }}
      x-langfuse-ingestion-version: '4'
    sampling_rate: 1
    propagation:
      default_format: w3c
consumers:
- username: voice-agent
  keyauth_credentials:
  - key: voice-demo-key
EOF
{% endraw -%}

echo "
_defaults:
  kongctl:
    namespace: voice-ai-observability-recipe
control_planes:
  - ref: recipe-cp
    name: \"${KONNECT_CONTROL_PLANE_NAME}\"
    _deck:
      files:
        - kong-recipe.yaml
" | kongctl apply -f - -o text --auto-approve --pat "${KONNECT_TOKEN}"

rm -f kong-recipe.yaml
```
{: data-test-step="block" .collapsible }

{% endtab %}
{% tab Mistral %}

Export the per-tab environment variable:

```bash
export DECK_CHAT_MODEL='mistral-large-latest'  # or mistral-small-latest
```

Apply the Kong configuration:

```bash
{%- raw %}
cat <<'EOF' > kong-recipe.yaml
_format_version: '3.0'
_info:
  select_tags:
  - voice-ai-observability-recipe
services:
- name: voice-ai-stt
  url: http://localhost
  routes:
  - name: voice-ai-stt
    paths:
    - /voice-ai-observability/stt
    protocols:
    - http
    - https
    methods:
    - POST
    - OPTIONS
    strip_path: true
  plugins:
  - name: ai-proxy-advanced
    instance_name: voice-ai-stt-proxy
    config:
      genai_category: audio/transcription
      max_request_body_size: 26214400
      response_streaming: deny
      targets:
      - route_type: audio/v1/audio/transcriptions
        auth:
          header_name: Authorization
          header_value: ${{ env "DECK_OPENAI_TOKEN" }}
        logging:
          log_payloads: true
        model:
          provider: openai
          name: whisper-1
- name: voice-ai-llm
  url: http://localhost
  routes:
  - name: voice-ai-llm
    paths:
    - /voice-ai-observability/llm
    protocols:
    - http
    - https
    methods:
    - POST
    - OPTIONS
    strip_path: true
  plugins:
  - name: ai-proxy-advanced
    instance_name: voice-ai-llm-proxy
    config:
      max_request_body_size: 8388608
      response_streaming: allow
      targets:
      - route_type: llm/v1/chat
        auth:
          header_name: Authorization
          header_value: ${{ env "DECK_MISTRAL_TOKEN" }}
        logging:
          log_statistics: true
          log_payloads: true
        model:
          provider: mistral
          name: ${{ env "DECK_CHAT_MODEL" }}
          options:
            mistral_format: openai
            upstream_url: https://api.mistral.ai/v1/chat/completions
- name: voice-ai-tts
  url: http://localhost
  routes:
  - name: voice-ai-tts
    paths:
    - /voice-ai-observability/tts
    protocols:
    - http
    - https
    methods:
    - POST
    - OPTIONS
    strip_path: true
  plugins:
  - name: ai-proxy-advanced
    instance_name: voice-ai-tts-proxy
    config:
      genai_category: audio/speech
      max_request_body_size: 1048576
      response_streaming: allow
      targets:
      - route_type: audio/v1/audio/speech
        auth:
          header_name: Authorization
          header_value: ${{ env "DECK_OPENAI_TOKEN" }}
        logging:
          log_payloads: true
        model:
          provider: openai
          name: tts-1
plugins:
- name: key-auth
  instance_name: voice-ai-observability-auth
  config:
    key_names:
    - apikey
    hide_credentials: true
- name: opentelemetry
  instance_name: voice-ai-observability-otel
  config:
    traces_endpoint: ${{ env "DECK_LANGFUSE_OTLP_ENDPOINT" }}
    headers:
      Authorization: ${{ env "DECK_LANGFUSE_AUTH_HEADER" }}
      x-langfuse-ingestion-version: '4'
    sampling_rate: 1
    propagation:
      default_format: w3c
consumers:
- username: voice-agent
  keyauth_credentials:
  - key: voice-demo-key
EOF
{% endraw -%}

echo "
_defaults:
  kongctl:
    namespace: voice-ai-observability-recipe
control_planes:
  - ref: recipe-cp
    name: \"${KONNECT_CONTROL_PLANE_NAME}\"
    _deck:
      files:
        - kong-recipe.yaml
" | kongctl apply -f - -o text --auto-approve --pat "${KONNECT_TOKEN}"

rm -f kong-recipe.yaml
```
{: data-test-step="block" .collapsible }

{% endtab %}
{% endnavtabs %}

## Try it out

The demo script runs a short three-turn voice conversation through the recipe. It opens with a setup phase that synthesizes the question audio for each turn directly via OpenAI's TTS API, bypassing Kong. These calls stand in for a microphone source a real voice agent would have, and are intentionally not traced. Before any traced turn runs, the demo also sends one request with an invalid `apikey` to confirm Kong returns `401`. It then runs three traced turns. Each turn opens a `voice-turn` parent span via the OpenTelemetry SDK and executes the three production hops through Kong: STT → LLM → TTS. The httpx instrumentation injects W3C `traceparent` into every outbound request so Kong's per-hop spans nest as descendants of the demo's parent span. All three turns share a single Langfuse `langfuse.session.id`, so they roll up into one Session for cross-turn analysis.

{:.info}

> The demo passes the API key via `default_headers` because the OpenAI SDK reserves `api_key` for the `Authorization: Bearer` header. To let clients pass the key through `api_key` directly, attach a [pre-function](/plugins/pre-function/) Plugin that copies the Bearer token to the `apikey` header server-side. See [Authenticate OpenAI SDK clients with Key Auth](/how-to/authenticate-openai-sdk-clients-with-key-auth/) for the pattern.

Look for per-hop timing in the output and the trace ID printed at the end of each turn. The `[LLM]` line shows the upstream model and token counts read from the parsed `completion.usage` field, which Kong's OpenAI-format response normalizes for every provider. After the script completes, open Langfuse, navigate to **Sessions**, and find the printed Session ID to see the three turns grouped under one conversation.

A single LLM hop request and response (with the Kong response headers visible to the client) looks like this:

```json
POST /voice-ai-observability/llm
apikey: voice-demo-key

{
  "model": "gpt-4o",
  "messages": [
    {"role": "system", "content": "You are a helpful voice assistant..."},
    {"role": "user", "content": "What are the three laws of robotics?"}
  ]
}
```
{:.no-copy-code}

Response (Kong normalizes any provider's reply to OpenAI format):

```text
HTTP/1.1 200 OK
X-Kong-LLM-Model: gpt-4o
X-Kong-Upstream-Latency: 821
X-Kong-Proxy-Latency: 18

{"choices": [{"message": {"role": "assistant", "content": "..."}}], "usage": {"prompt_tokens": 58, "completion_tokens": 44, "total_tokens": 102}}
```
{:.no-copy-code}

Kong adds these response headers on every hop:

{% table %}
columns:
  - title: Header
    key: header
  - title: Description
    key: description
rows:
  - header: "`X-Kong-LLM-Model`"
    description: Upstream model that served the request (LLM hop only)
  - header: "`X-Kong-Upstream-Latency`"
    description: Time (ms) Kong spent waiting for the provider
  - header: "`X-Kong-Proxy-Latency`"
    description: Time (ms) Kong spent processing the request
{% endtable %}

Create the demo script:

```bash
cat <<'EOF' > demo.py
"""Voice AI pipeline observability demo. See README for context."""

import os
import sys
import tempfile
import time
import uuid
from pathlib import Path

from openai import APIStatusError, OpenAI
from opentelemetry import context as otel_context
from opentelemetry import trace
from opentelemetry.exporter.otlp.proto.http.trace_exporter import OTLPSpanExporter
from opentelemetry.instrumentation.httpx import HTTPXClientInstrumentor
from opentelemetry.sdk.resources import Resource
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

PROXY_URL = os.getenv("PROXY_URL", "http://localhost:8000")
CHAT_MODEL = os.getenv("CHAT_MODEL", "gpt-4o")
VOICE_API_KEY = os.getenv("VOICE_API_KEY", "voice-demo-key")
SESSION_ID = os.getenv("SESSION_ID", f"voice-demo-{uuid.uuid4().hex[:12]}")

# ANSI color codes. Disabled when stdout isn't a TTY or NO_COLOR is set.
_USE_COLOR = sys.stdout.isatty() and "NO_COLOR" not in os.environ
def _c(code: str, s: str) -> str:
    return f"\033[{code}m{s}\033[0m" if _USE_COLOR else s
BOLD   = lambda s: _c("1", s)
DIM    = lambda s: _c("2", s)
GREEN  = lambda s: _c("32", s)
BLUE   = lambda s: _c("34", s)
CYAN   = lambda s: _c("36", s)
RED    = lambda s: _c("31", s)
MAGENTA= lambda s: _c("35", s)

LANGFUSE_OTLP_ENDPOINT = os.environ["DECK_LANGFUSE_OTLP_ENDPOINT"]
LANGFUSE_AUTH_HEADER = os.environ["DECK_LANGFUSE_AUTH_HEADER"]

# DECK_OPENAI_TOKEN carries the "Bearer " prefix Kong needs; strip it for the
# direct OpenAI client used by the setup phase.
RAW_OPENAI_KEY = os.environ["DECK_OPENAI_TOKEN"].removeprefix("Bearer ").strip()


# ---------------------------------------------------------------------------
# OpenTelemetry SDK setup
# ---------------------------------------------------------------------------

provider = TracerProvider(resource=Resource.create({"service.name": "voice-ai-demo"}))
provider.add_span_processor(
    BatchSpanProcessor(
        OTLPSpanExporter(
            endpoint=LANGFUSE_OTLP_ENDPOINT,
            headers={
                "Authorization": LANGFUSE_AUTH_HEADER,
                "x-langfuse-ingestion-version": "4",
            },
        )
    )
)
trace.set_tracer_provider(provider)
tracer = trace.get_tracer("voice-ai-demo")

HTTPXClientInstrumentor().instrument()


# ---------------------------------------------------------------------------
# Kong-pointed clients (key-auth via apikey header in default_headers)
# ---------------------------------------------------------------------------
#
# The OpenAI SDK reserves api_key for the Authorization: Bearer header. Kong
# replaces that header server-side with the real provider credential, so we
# pass the recipe's key-auth credential through default_headers instead.

stt_client = OpenAI(
    base_url=f"{PROXY_URL}/voice-ai-observability/stt",
    api_key="placeholder",
    default_headers={"apikey": VOICE_API_KEY},
)

llm_client = OpenAI(
    base_url=f"{PROXY_URL}/voice-ai-observability/llm",
    api_key="placeholder",
    default_headers={"apikey": VOICE_API_KEY},
)

tts_client = OpenAI(
    base_url=f"{PROXY_URL}/voice-ai-observability/tts",
    api_key="placeholder",
    default_headers={"apikey": VOICE_API_KEY},
)


# ---------------------------------------------------------------------------
# Out-of-band setup: synthesize question audio directly via OpenAI
# ---------------------------------------------------------------------------

def synthesize_question_audio(text):
    """Synthesize question audio directly via OpenAI, bypassing Kong.

    This stands in for a microphone source. The call is suppressed from
    OpenTelemetry instrumentation so it does not appear in Langfuse, since
    the recipe traces what happens through Kong, and a real voice agent
    would receive raw audio from a hardware input.
    """
    direct_client = OpenAI(api_key=RAW_OPENAI_KEY, base_url="https://api.openai.com/v1")

    # Suppress httpx instrumentation for this call so the setup span is not
    # emitted to Langfuse (would otherwise surface as an unparented orphan).
    token = otel_context.attach(
        otel_context.set_value("suppress_instrumentation", True)
    )
    try:
        response = direct_client.audio.speech.create(
            model="tts-1", voice="alloy", input=text
        )
        return response.read()
    finally:
        otel_context.detach(token)


# ---------------------------------------------------------------------------
# Negative path: invalid key-auth credential
# ---------------------------------------------------------------------------

def check_auth_boundary():
    """Send a request with an invalid key, expecting Kong to return 401.

    Confirms key-auth is enforced on the recipe's Routes before any traced
    turn runs. Suppress instrumentation so this setup probe doesn't pollute
    Langfuse with an unauthenticated outlier.
    """
    bad_client = OpenAI(
        base_url=f"{PROXY_URL}/voice-ai-observability/llm",
        api_key="placeholder",
        default_headers={"apikey": "wrong-key"},
    )
    token = otel_context.attach(
        otel_context.set_value("suppress_instrumentation", True)
    )
    try:
        bad_client.chat.completions.create(
            model=CHAT_MODEL,
            messages=[{"role": "user", "content": "ping"}],
        )
    except APIStatusError as exc:
        print(f"  {GREEN(BOLD('[AUTH]'))} expected reject -> {RED(BOLD(str(exc.status_code)))} {exc.message[:80]}")
        return exc.status_code
    finally:
        otel_context.detach(token)
    print(f"  {RED(BOLD('[AUTH]'))} unexpected: invalid key was accepted")
    return None


# ---------------------------------------------------------------------------
# Pipeline stages: three traced hops through Kong
# ---------------------------------------------------------------------------

def speech_to_text(audio_bytes):
    """Transcribe audio via the Kong STT route."""
    with tempfile.NamedTemporaryFile(suffix=".mp3", delete=False) as tmp:
        tmp.write(audio_bytes)
        tmp_path = Path(tmp.name)

    try:
        start = time.perf_counter()
        with open(tmp_path, "rb") as f:
            transcript = stt_client.audio.transcriptions.create(
                model="whisper-1", file=f
            )
        elapsed = time.perf_counter() - start
    finally:
        tmp_path.unlink(missing_ok=True)

    print(f"  {CYAN(BOLD('[STT]'))} \"{transcript.text}\" {DIM(f'({elapsed:.3f}s)')}")
    return transcript.text, elapsed


def llm_chat(messages):
    """Send the conversation so far to the LLM via the Kong chat route."""
    start = time.perf_counter()
    raw = llm_client.chat.completions.with_raw_response.create(
        model=CHAT_MODEL, messages=messages
    )
    elapsed = time.perf_counter() - start
    completion = raw.parse()

    reply = completion.choices[0].message.content
    usage = completion.usage
    kong_model = raw.headers.get("x-kong-llm-model", CHAT_MODEL)
    upstream_ms = raw.headers.get("x-kong-upstream-latency", "-")

    print(f"  {CYAN(BOLD('[LLM]'))} \"{reply}\"")
    stats = (
        f"Model: {kong_model}  "
        f"Tokens: {usage.prompt_tokens} in / {usage.completion_tokens} out  "
        f"Upstream: {upstream_ms}ms ({elapsed:.3f}s wall)"
    )
    print(f"         {DIM(stats)}")
    return reply, elapsed


def text_to_speech(text):
    """Synthesize the LLM response to audio via the Kong TTS route."""
    start = time.perf_counter()
    response = tts_client.audio.speech.create(
        model="tts-1", voice="alloy", input=text
    )
    audio_bytes = response.read()
    elapsed = time.perf_counter() - start

    print(f"  {CYAN(BOLD('[TTS]'))} Generated {len(audio_bytes):,} bytes of audio {DIM(f'({elapsed:.3f}s)')}")
    return audio_bytes, elapsed


# ---------------------------------------------------------------------------
# Per-turn orchestration
# ---------------------------------------------------------------------------

def run_turn(question, audio_bytes, turn_number, history):
    """Execute one full cascading voice pipeline turn under a `voice-turn` span.

    `history` is the running OpenAI-format messages list for the conversation;
    this turn's user transcription and assistant reply are appended to it so
    later turns see prior context.
    """
    print(f"\n{BOLD(f'Turn {turn_number}:')} \"{question}\"")
    print("=" * 60)

    with tracer.start_as_current_span(
        "voice-turn",
        attributes={
            "langfuse.session.id": SESSION_ID,
            "langfuse.trace.name": f"voice-turn-{turn_number}",
            "langfuse.trace.tags": ["voice-ai", "cascading-pipeline"],
            "voice.turn.number": turn_number,
            "voice.question": question,
        },
    ) as span:
        timings = {}

        print("\n1. Speech -> Text (STT)")
        transcription, timings["stt"] = speech_to_text(audio_bytes)
        history.append({"role": "user", "content": transcription})

        print("\n2. Transcription -> LLM")
        response_text, timings["llm"] = llm_chat(history)
        history.append({"role": "assistant", "content": response_text})

        print("\n3. LLM Response -> Speech (TTS)")
        _, timings["tts"] = text_to_speech(response_text)

        span.set_attribute("voice.response", response_text)
        trace_id = f"{span.get_span_context().trace_id:032x}"

    total = sum(timings.values())
    breakdown = " + ".join(f"{k}: {v:.3f}s" for k, v in timings.items())
    print(f"\n{'-' * 60}")
    print(f"{BOLD('Turn complete:')} {total:.3f}s total {DIM(f'({breakdown})')}")
    # Trace ID is the link readers paste into Langfuse. That's the headline output.
    print(f"Trace ID: {MAGENTA(BOLD(trace_id))}")


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

if __name__ == "__main__":
    print(BOLD("Voice AI Pipeline Observability Demo"))
    print("=" * 60)
    print(f"Kong Proxy:  {PROXY_URL}")
    print(f"Chat Model:  {CYAN(BOLD(CHAT_MODEL))}")
    # Session ID is what the reader uses to find this run in Langfuse.
    print(f"Session ID:  {BLUE(BOLD(SESSION_ID))}")

    print(f"\n{DIM('Checking key-auth boundary...')}")
    check_auth_boundary()

    questions = [
        "What are the three laws of robotics?",
        "Who wrote them?",
        "What year were they first published?",
    ]

    print(f"\n{DIM('Synthesizing question audio (out of band, not traced)...')}")
    audio_clips = []
    for q in questions:
        audio_clips.append(synthesize_question_audio(q))
        print(f"  {DIM(f'Synthesized: ' + chr(34) + q + chr(34))}")

    history = [
        {
            "role": "system",
            "content": (
                "You are a helpful voice assistant. Always answer in a single "
                "spoken sentence. Never use bullet points, numbered lists, or "
                "markdown. Spell out numbers and acronyms as words. Your reply "
                "will be read aloud by a text-to-speech engine."
            ),
        }
    ]

    for i, (question, audio) in enumerate(zip(questions, audio_clips), start=1):
        run_turn(question, audio, i, history)

    print()
    print("=" * 60)
    print(f"{BOLD('Session complete:')} {BLUE(BOLD(SESSION_ID))}")
    print(f"View this conversation in Langfuse -> Sessions -> {BLUE(BOLD(SESSION_ID))}")

    # BatchSpanProcessor flushes asynchronously; block until exporter drains.
    provider.shutdown()
    sys.exit(0)
EOF
```
{:.collapsible}

Run it:

```bash
python demo.py
```

Example output:

```text
Voice AI Pipeline Observability Demo
============================================================
Kong Proxy:  http://localhost:8000
Chat Model:  gpt-4o
Session ID:  voice-demo-7f3a2c1b9e8d

Checking key-auth boundary...
  [AUTH] expected reject -> 401 Error code: 401 - {'message': 'No API key found in request'}

Synthesizing question audio (out of band, not traced)...
  Synthesized: "What are the three laws of robotics?"
  Synthesized: "Who wrote them?"
  Synthesized: "What year were they first published?"

Turn 1: "What are the three laws of robotics?"
============================================================

1. Speech -> Text (STT)
  [STT] "What are the three laws of robotics?" (0.876s)

2. Transcription -> LLM
  [LLM] "Isaac Asimov's three laws state that a robot must not harm a human, must obey human orders unless they conflict with the first law, and must protect its own existence unless that conflicts with the first two."
         Model: gpt-4o  Tokens: 58 in / 44 out  Upstream: 821ms (0.842s wall)

3. LLM Response -> Speech (TTS)
  [TTS] Generated 218,400 bytes of audio (2.943s)

------------------------------------------------------------
Turn complete: 4.661s total (stt: 0.876s + llm: 0.842s + tts: 2.943s)
Trace ID: a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6

Turn 2: "Who wrote them?"
============================================================

1. Speech -> Text (STT)
  [STT] "Who wrote them?" (0.412s)

2. Transcription -> LLM
  [LLM] "Isaac Asimov, the science fiction author, wrote the three laws of robotics."
         Model: gpt-4o  Tokens: 88 in / 16 out  Upstream: 318ms (0.331s wall)

3. LLM Response -> Speech (TTS)
  [TTS] Generated 65,760 bytes of audio (0.624s)

------------------------------------------------------------
Turn complete: 1.367s total (stt: 0.412s + llm: 0.331s + tts: 0.624s)
Trace ID: b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7

Turn 3: "What year were they first published?"
============================================================

1. Speech -> Text (STT)
  [STT] "What year were they first published?" (0.487s)

2. Transcription -> LLM
  [LLM] "Asimov first introduced the three laws in his 1942 short story 'Runaround.'"
         Model: gpt-4o  Tokens: 116 in / 19 out  Upstream: 401ms (0.418s wall)

3. LLM Response -> Speech (TTS)
  [TTS] Generated 70,080 bytes of audio (0.892s)

------------------------------------------------------------
Turn complete: 1.797s total (stt: 0.487s + llm: 0.418s + tts: 0.892s)
Trace ID: c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8

============================================================
Session complete: voice-demo-7f3a2c1b9e8d
View this conversation in Langfuse -> Sessions -> voice-demo-7f3a2c1b9e8d
```
{:.no-copy-code}

### What happened

1. **Auth boundary check.** Before any traced traffic, the demo sent one request with `apikey: wrong-key`. The Key Auth Plugin rejected it with `401`, confirming Kong is gating every Route. This call was suppressed from instrumentation so it does not appear in Langfuse.

2. **Setup (not traced).** Before any spans opened, the demo made three TTS calls *directly to OpenAI* to synthesize question audio for each turn. These calls bypassed Kong entirely and stand in for the microphone source a production voice agent would have. They are explicitly suppressed from OpenTelemetry instrumentation, so they do not appear in your Langfuse traces.

3. **Per-turn parent span.** For each turn, the demo opened a `voice-turn` parent span via the OpenTelemetry SDK before any HTTP call. The span carries `langfuse.session.id`, `langfuse.trace.name`, and `langfuse.trace.tags` attributes. These tell Langfuse to roll the per-turn traces up under one Session.

4. **Three traced hops through Kong.** Each `OpenAI(...).create(...)` call (STT, LLM, TTS) ran while the `voice-turn` span was active. The httpx auto-instrumentation wrapped the OpenAI SDK's underlying client, emitted a child span per call, and injected a real W3C `traceparent` header into every outbound request. Every call carried the `apikey` header, so the Key Auth Plugin admitted it before AI Proxy Advanced ran.

5. **Kong's per-hop spans nest under the demo's spans.** Kong's OpenTelemetry Plugin extracted the `traceparent` and rooted its server, Plugin (ai-proxy-advanced, opentelemetry, balancer, dns), and `gen_ai.*` generation spans as descendants of the demo's httpx client span. The `gen_ai.*` spans on the LLM hop carry `gen_ai.usage.input_tokens` and `gen_ai.usage.output_tokens`. These are the same numbers the CLI prints from the parsed `completion.usage` field that the OpenAI-format response normalizes for every provider.

6. **Two exporters, one trace.** The demo's SDK and Kong's Plugin export to the same Langfuse OTLP endpoint independently. They share `trace_id` because the `traceparent` header propagates the demo's active context to Kong, and Langfuse reassembles the tree by `trace_id`.

7. **Session rollup.** Because every turn's root span carried the same `langfuse.session.id`, Langfuse groups all three turns under a single Session. This is how cross-turn analysis (latency progression, conversation-scoped cost, per-turn error correlation) works.

8. **Where latency actually came from, and why this is the recipe's whole point.** Look at the per-hop times printed by the demo and the matching durations in Langfuse. STT and the LLM combined typically come in under 1.5 seconds; TTS is the dominant cost, often 3–6 seconds, and it scales linearly with how long the LLM's reply is. The Problem section frames natural-sounding voice interaction as a sub-800ms budget, and the demo runs nowhere near it. That gap is exactly why per-hop observability matters. Without spans on every hop, you would see one slow turn and have no idea whether STT mis-transcribed, the LLM was wordy, or TTS choked on a long reply. With them, the answer is one glance at the waterfall: a chatty LLM cascades into a slow TTS, and the production fix (stream TTS, cap response length, switch to a faster TTS model, swap to a realtime API) is selected from the data, not guessed at. Observability is what turns "the call sounded broken" into a specific, fixable hop.

### Verify in Langfuse

Open your Langfuse project and navigate to **Sessions** in the left nav. Find the session ID printed at the end of the demo output (search by ID or scan the recent list).

You should see three traces grouped under the session, one per turn. Click into the first trace and confirm the tree:

- **Root**: `voice-turn` (Service: `voice-ai-demo`), with `langfuse.session.id`, `langfuse.trace.name`, and `langfuse.trace.tags` attributes attached.
- **Three children** (one per pipeline hop), each named after the outbound HTTP call: `POST /voice-ai-observability/stt`, `POST /voice-ai-observability/llm`, `POST /voice-ai-observability/tts`.
- **Under each httpx span**: Kong's server span plus the Plugin / balancer / dns descendants, and a `gen_ai.*` generation span (`generate_content whisper-1`, `chat <chat-model>`, `generate_content tts-1`).

Per-hop timings in Langfuse should be within a few tens of milliseconds of the times printed by the demo CLI. Any larger discrepancy points at network overhead between the demo, Kong, and the upstream provider.

### Explore in Konnect

Sign in to [{{site.konnect_product_name}}](https://cloud.konghq.com/) and navigate to **API Gateway** → **Gateways** → `voice-ai-observability-recipe`. From there:

- Open the **Gateway services** tab to see the three Services (`voice-ai-stt`, `voice-ai-llm`, `voice-ai-tts`) and click into each to inspect their Routes (`/voice-ai-observability/stt`, `/voice-ai-observability/llm`, `/voice-ai-observability/tts`).
- Open the **Plugins** tab to confirm the global Key Auth and OpenTelemetry Plugins, plus the three per-Service AI Proxy Advanced instances.
- Open the **Consumers** tab to find the `voice-agent` Consumer and its `voice-demo-key` credential.
- Open the **Analytics** tab on any Service for an at-a-glance view of recipe traffic (request count, latency, status codes).
- For deeper analysis, open the Konnect **Observability** menu in the left nav for cross-Service dashboards and historical trends.

## Variations and next steps

**Swap the OTel backend.** Replace the Langfuse endpoint with any OTLP-compatible backend. Change `DECK_LANGFUSE_OTLP_ENDPOINT` and `DECK_LANGFUSE_AUTH_HEADER` (and update the demo's exporter the same way) to point at Jaeger, Grafana Tempo, Honeycomb, Datadog, or Dynatrace. Two things to know before you migrate:

- **Portable across backends.** Kong's per-hop spans, the demo's `voice-turn` span tree, and the `gen_ai.*` semantic attributes (token counts, model names, provider) are all standard OpenTelemetry GenAI semantic conventions. They render correctly in any backend that supports OTLP ingestion and the GenAI semconv registry.
- **Langfuse-specific and won't transfer.** The `langfuse.session.id`, `langfuse.trace.name`, and `langfuse.trace.tags` attributes are how Langfuse drives its Sessions UI, conversation rollups, and LLM-aware cost panels. On a generic backend `langfuse.session.id` is just a string attribute. To recreate Sessions-style grouping you would filter traces by that attribute, or restructure to use the backend's native session/grouping concept (Datadog's `session.id`, Honeycomb's parent-id chains, etc.).

**Propagate session attributes onto every span.** Kong's child spans share the `trace_id` of the demo's `voice-turn` root, but they do not carry the `langfuse.session.id` attribute themselves. For trace-level Session grouping in Langfuse this is sufficient: Langfuse only needs the attribute on the root. To filter or aggregate *individual* observations by session (for example, a per-span cost panel grouped by session), use OpenTelemetry's [`BaggageSpanProcessor`](https://opentelemetry.io/docs/languages/python/) on the demo side to copy `session.id` into baggage and have it propagated on outbound HTTP. Kong does not natively read OTel baggage onto its emitted spans, so a complete per-span propagation also requires either a Kong Plugin extension that reads the baggage header and stamps it as a span attribute, or a templating Plugin that maps a custom HTTP header onto the OTel span attributes.

**Swap key-auth for SSO.** Replace the Key Auth Plugin with [OpenID Connect](/plugins/openid-connect/) when voice agents are run by humans on managed devices and you need per-user identity, JWT claims, or short-lived tokens. The [Claude Code SSO recipe](/cookbooks/claude-code-sso/) is an end-to-end example with Okta. Drop the `voice-agent` Consumer, point Kong at your IdP's issuer URL, and let `consumer_claim` map JWT subjects onto Kong Consumers automatically.

**Add per-hop rate limiting.** Attach [AI Rate Limiting Advanced](/plugins/ai-rate-limiting-advanced/) to individual Services to enforce separate token budgets for STT, LLM, and TTS. This prevents a runaway LLM prompt from consuming the entire pipeline's token quota. Configure `llm_providers` per Service to track token usage against provider-specific limits.

**Replace STT or TTS providers.** Update the STT or TTS Service target to use a different provider without changing the LLM configuration or the observability pipeline. Switch from OpenAI Whisper to a self-hosted speech model by changing `model.provider` and `model.options.upstream_url` on the STT target. The `gen_ai.*` span attributes and Prometheus labels update automatically to reflect the new provider.

**Add Prometheus metrics dashboards.** Kong emits AI-specific Prometheus metrics (`ai_llm_requests_total`, `ai_llm_cost_total`, `ai_llm_tokens_total`, `ai_llm_provider_latency`) with a `request_mode` label that distinguishes `oneshot`, `stream`, and `realtime` traffic. Import the [{{site.ai_gateway_name}} Grafana dashboard](https://grafana.com/grafana/dashboards/21162-kong-cx-ai/) for pre-built cost, latency, and throughput panels across all three pipeline hops.

**Explore realtime speech-to-speech.** For latency-sensitive applications where per-hop observability is less critical, the AI Proxy Advanced Plugin supports `route_type: realtime/v1/realtime` with `genai_category: realtime/generation` for OpenAI Realtime and Gemini Live WebSocket connections. Realtime mode collapses the three-hop pipeline into a single persistent WebSocket, trading the per-hop waterfall view for significantly lower turn latency. Kong tracks realtime traffic with the `request_mode=realtime` Prometheus label.

## Cleanup

The recipe's `select_tags` and kongctl namespace scoped all resources, so this teardown removes only this recipe's configuration. Tear down the local data plane and delete the control plane from Konnect:

```bash
export KONNECT_CONTROL_PLANE_NAME='voice-ai-observability-recipe' && curl -Ls https://get.konghq.com/quickstart | bash -s -- -d -k $KONNECT_TOKEN
```
