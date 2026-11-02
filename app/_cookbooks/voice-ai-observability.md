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
  ai-gateway: '2.0'
categories:
  - observability
  - llm
featured: true
popular: false

# Machine-readable fields for AI agent setup
plugins:
  - key-auth
  - opentelemetry
  - ai-model
  - ai-model-provider
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
        This tutorial uses {{site.konnect_product_name}}. The {{site.ai_gateway}} [quickstart script](https://get.konghq.com/ai) provisions a recipe-scoped {{site.ai_gateway}} and local data plane.

        1. Create a new personal access token by opening the [{{site.konnect_short_name}} PAT page](https://cloud.konghq.com/global/account/tokens) and selecting **Generate Token**.
        1. Export your token. You reuse the same token later for kongctl commands:

           ```bash
           export KONNECT_TOKEN='YOUR_KONNECT_PAT'
           ```

        1. Set the recipe-scoped {{site.ai_gateway}} name and run the quickstart script. The two `-e` flags pass non-default tracing settings into the data plane container; the [OpenTelemetry](/ai-gateway/policies/opentelemetry/) Policy doesn't export traces unless you start the data plane with `KONG_TRACING_INSTRUMENTATIONS` enabled, and the default sampling rate (`0.01`) drops 99% of spans before the AI Policy sees them:

           ```bash
           export KONNECT_CONTROL_PLANE_NAME='voice-ai-observability-recipe'
           curl -Ls https://get.konghq.com/ai | \
             bash -s -- -k $KONNECT_TOKEN \
               -e KONG_TRACING_INSTRUMENTATIONS=all \
               -e KONG_TRACING_SAMPLING_RATE=1.0
           ```

           The script provisions an {{site.ai_gateway}} named `voice-ai-observability-recipe`, a local data plane connected to it with tracing enabled, and prints `export` lines for the rest of the session vars, including `AI_GATEWAY_ID`. Paste those into your shell when prompted.
    - title: kongctl
      content: |
        This tutorial uses [kongctl](/kongctl/) to manage {{site.ai_gateway}} configuration.

        1. Install **kongctl** from the [kongctl documentation](/kongctl/).
        1. Verify it's installed:

           ```bash
           kongctl version
           ```
    - title: AI Credentials
      content: |
        Every provider tab uses OpenAI for the STT and TTS hops (Whisper and TTS-1), so you need an OpenAI key regardless of which LLM provider you pick.

        1. [Create an OpenAI account](https://auth.openai.com/create-account).
        1. [Get an API key](https://platform.openai.com/api-keys).
        1. Export the OpenAI key. You reuse the key for STT, TTS, and the LLM hop when you pick the OpenAI tab below:

           ```sh
           export DECK_OPENAI_TOKEN='Bearer sk-YOUR-KEY'
           ```

        Then configure the LLM provider you plan to use for the reasoning hop:

        {% navtabs "Providers" %}
        {% navtab "OpenAI" %}
        You already exported the OpenAI key above. The recipe uses the same `DECK_OPENAI_TOKEN` for STT, TTS, and the LLM hop.
        {% endnavtab %}
        {% navtab "Anthropic" %}
        This tutorial uses Anthropic:

        1. [Create an Anthropic account](https://console.anthropic.com/).
        1. [Get an API key](https://console.anthropic.com/settings/keys).
        1. Export the API key and the [Messages API schema version](https://docs.claude.com/en/api/versioning) Kong should send upstream on every request:

           ```sh
           export DECK_ANTHROPIC_TOKEN='YOUR-ANTHROPIC-KEY'
           export DECK_ANTHROPIC_VERSION='2023-06-01'
           ```
        {% endnavtab %}
        {% navtab "AWS Bedrock" %}
        This tutorial uses AWS Bedrock:

        1. Ensure you have an AWS account with [Bedrock model access](https://docs.aws.amazon.com/bedrock/latest/userguide/model-access.html) enabled.
        1. Export your AWS credentials:

           ```sh
           export DECK_AWS_ACCESS_KEY_ID='your-access-key'
           export DECK_AWS_SECRET_ACCESS_KEY='your-secret-key'
           export DECK_AWS_REGION='us-east-1'
           ```
        {% endnavtab %}
        {% navtab "Azure OpenAI" %}
        This tutorial uses Azure OpenAI:

        1. [Create an Azure OpenAI resource](https://portal.azure.com/#create/Microsoft.CognitiveServicesOpenAI).
        1. Deploy a model and note your instance name, deployment ID, and API version.
        1. Export your credentials:

           ```sh
           export DECK_AZURE_API_KEY='your-azure-api-key'
           export DECK_AZURE_INSTANCE='your-instance-name'
           export DECK_AZURE_DEPLOYMENT_ID='your-deployment-id'
           export DECK_AZURE_API_VERSION='YOUR-API-VERSION'  # check Azure docs for current version
           ```
        {% endnavtab %}
        {% navtab "Google Gemini" %}
        This tutorial uses Google Gemini via Vertex AI:

        1. [Create a Google Cloud project](https://console.cloud.google.com/) with Vertex AI enabled.
        1. Create a service account and mount the JSON key file in your Kong container.
        1. Export your project details:

           ```sh
           export DECK_GCP_API_ENDPOINT='your-api-endpoint'
           export DECK_GCP_PROJECT_ID='your-project-id'
           export DECK_GCP_LOCATION_ID='us-central1'
           ```
        {% endnavtab %}
        {% navtab "Mistral" %}
        This tutorial uses Mistral:

        1. [Create a Mistral account](https://console.mistral.ai/).
        1. [Get an API key](https://console.mistral.ai/api-keys/).
        1. Export the API key as an environment variable:

           ```sh
           export DECK_MISTRAL_TOKEN='Bearer your-mistral-key'
           ```
        {% endnavtab %}
        {% endnavtabs %}
    - title: Langfuse
      content: |
        [Langfuse](https://langfuse.com) is an open-source observability platform that receives OpenTelemetry traces and groups them into conversation-level Sessions. This recipe exports Kong's `gen_ai.*` spans to Langfuse for per-hop and conversation-level analysis.

        Langfuse authenticates OTLP ingestion with HTTP Basic Auth, where the username is your project's **Public Key** (`pk-lf-...`) and the password is its **Secret Key** (`sk-lf-...`).

        1. Sign up for Langfuse Cloud (free tier) on the region you want to use, or [self-host Langfuse v3.22.0 or later](https://langfuse.com/self-hosting) using Docker Compose. OTLP ingestion is only available on self-hosted Langfuse v3.22.0+. Each region is a fully separate deployment with its own UI, account, projects, and API keys. Keys issued in one region don't authenticate against another, so pick one and stick with it:

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

           The `tr -d '\n'` strips the newline that GNU `base64` inserts after 76 characters, which would otherwise corrupt the `Authorization` header. If your endpoint and key region don't match, Langfuse returns `401 Unauthorized` on every trace export.

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
  A production voice AI system is a pipeline: speech-to-text (STT), LLM reasoning, and text-to-speech (TTS) execute in sequence for every conversational turn. Each hop carries its own latency budget, error modes, and cost profile. This recipe sets up {{site.ai_gateway_name}} to govern all three hops through separate AI Models, each with its own routing and provider credentials. A shared Key Auth AI Auth Strategy identifies the calling voice agent on every hop, and a global [OpenTelemetry](/ai-gateway/policies/opentelemetry/) Policy exports `gen_ai.*` spans to [Langfuse](https://langfuse.com) for per-hop latency, token usage, and cost visibility, with conversation-level trace grouping for full-turn analysis.

  By the end, you'll have three Kong endpoints (`/stt`, `/llm`, `/tts`) proxying a complete voice pipeline behind a single API key, with every hop producing OpenTelemetry traces that appear as a single conversation trace in Langfuse.
---

## The problem

Voice AI systems present observability challenges that text-based LLM applications don't face. The core difficulty is that a single conversational turn requires multiple API calls in sequence, each with distinct providers, latency characteristics, and failure modes.

- **Three independent failure surfaces per turn.** A cascading voice pipeline makes at least three API calls for every user interaction: STT (audio to text), LLM (text to response), and TTS (response to audio). Each hop can fail independently. The STT service may return a low-confidence transcription. The LLM may time out. The TTS service may rate-limit. When a user reports that "the call sounded broken," you need to identify which hop failed, but each provider has its own dashboard and log format with no shared correlation identifier.

- **The observable unit is a conversation, not a request.** Users don't experience individual API calls. They experience a phone call or voice interaction spanning dozens of turns. Turn 3 might complete in 400ms while turn 7 hits a 3-second TTS timeout. Traditional API monitoring shows average latency across all requests. It doesn't show latency progression within a conversation. Debugging user-reported issues requires conversation-scoped traces that group all hops from all turns under a single identifier.

- **Latency budgets compound across hops.** Natural-sounding voice interaction requires end-to-end turn latency under approximately 800ms. STT taking 350ms eats into the LLM's budget. A 200ms LLM response leaves only 250ms for TTS. Monitoring each hop in isolation doesn't reveal the cascading impact. You need a waterfall view showing how latency distributes across the pipeline so you can identify which hop is consuming the budget.

- **Credential management scales with the pipeline.** A text-only LLM application manages one provider's credentials. A voice pipeline manages three: STT provider keys, LLM provider keys, and TTS provider keys. Each has its own rotation policy, billing dashboard, and rate limits. Switching STT providers (Deepgram to Whisper, or Whisper to a self-hosted model) means re-tooling authentication, monitoring, and cost tracking for that hop across every service that calls it.

- **Cost attribution is per-model, but budgets are per-conversation.** LLM providers charge per token. STT providers charge per audio-second. TTS providers charge per character. Building a cost-per-minute or cost-per-conversation view requires normalizing these different units and correlating charges across hops that run on separate billing systems.

The alternative to the cascading pipeline is realtime speech-to-speech APIs (OpenAI Realtime, Gemini Live), which use a single WebSocket connection to a multimodal model that ingests and emits audio natively. Latency drops sharply, but per-hop observability disappears by design: there are no separate STT, LLM, or TTS stages to instrument. Regulated industries (finance, healthcare, legal) remain on cascading architectures because the text intermediary between STT and TTS provides an audit trail and a checkpoint for compliance checks before responses are spoken.

## The solution

This recipe places {{site.ai_gateway_name}} between the voice agent and all three providers. Each pipeline hop gets its own AI Model, backed by an AI Model Provider holding that hop's upstream credentials. A shared Key Auth AI Auth Strategy identifies the calling voice agent on every hop, and a global [OpenTelemetry](/ai-gateway/policies/opentelemetry/) Policy exports `gen_ai.*` spans from every hop to Langfuse, where they appear as a single conversation trace.

{% table %}
columns:
  - title: Component
    key: component
  - title: Responsibility
    key: responsibility
rows:
  - component: AI Model `voice-ai-observability-stt`
    responsibility: "Routes audio to OpenAI Whisper for transcription (`capabilities: [audio/transcription]`)"
  - component: AI Model `voice-ai-observability-llm`
    responsibility: Routes text to any supported LLM provider for the reasoning hop (the provider varies per tab)
  - component: AI Model `voice-ai-observability-tts`
    responsibility: "Routes text to OpenAI TTS for speech synthesis (`capabilities: [audio/speech]`)"
  - component: AI Model Providers (2)
    responsibility: Hold upstream credentials and inject them into every request that targets them
  - component: Key Auth AI Auth Strategy
    responsibility: Authenticates the voice agent with a shared `apikey` header on every AI Model
  - component: OpenTelemetry AI Policy (global)
    responsibility: Exports `gen_ai.*` spans with provider, model, token usage, and latency to Langfuse from all three Models
  - component: Langfuse
    responsibility: Groups spans by W3C trace ID into conversation-level Sessions for full-turn visibility
{% endtable %}

All three calls share a single W3C trace ID, which Langfuse uses to group the per-hop spans into one conversation-level trace.

<!-- vale off -->
{% mermaid %}
sequenceDiagram
    participant V as Voice Agent
    participant K as Kong AI Gateway
    participant P as Provider (Whisper / LLM / TTS)
    participant Lf as Langfuse

    V->>K: POST /stt (apikey, audio)
    activate K
    K->>K: key-auth Auth Strategy + STT AI Model (inject OpenAI creds)
    K->>P: Whisper transcription
    activate P
    P-->>K: Transcription
    deactivate P
    K->>Lf: gen_ai.* span (STT)
    K-->>V: Transcription
    deactivate K

    V->>K: POST /llm (apikey, text)
    activate K
    K->>K: key-auth Auth Strategy + LLM AI Model (translate format, inject creds)
    K->>P: LLM completion
    activate P
    P-->>K: Response
    deactivate P
    K->>Lf: gen_ai.* span (LLM)
    K-->>V: Text response
    deactivate K

    V->>K: POST /tts (apikey, text)
    activate K
    K->>K: key-auth Auth Strategy + TTS AI Model (inject OpenAI creds)
    K->>P: TTS synthesis
    activate P
    P-->>K: Audio
    deactivate P
    K->>Lf: gen_ai.* span (TTS)
    K-->>V: Audio
    deactivate K
{% endmermaid %}
<!-- vale on -->

Kong decouples the voice agent from individual providers. Swap the LLM from OpenAI to Anthropic by changing a tab and re-applying. Replace Whisper with a self-hosted STT model by updating one AI Model target. The observability contract (same `gen_ai.*` spans, same Prometheus labels, same Langfuse trace structure) stays identical regardless of which providers sit behind the gateway.

## How it works

### Tracing terminology

OpenTelemetry's vocabulary shows up in several places below; here's what each term means in this recipe.

- **Span**. One unit of work with a start, an end, and attributes. Examples here include the `voice-turn` parent span the demo opens, the AI Model's server-phase span Kong emits, and the `gen_ai.*` generation span Kong populates from the provider response.
- **Trace**. A tree of spans sharing one `trace_id` that represents a single logical operation. In this recipe, that means one voice turn (STT to LLM to TTS).
- **Root span**. The top of the tree; everything else is a descendant. The demo's `voice-turn` span is the root, and Kong's per-hop spans nest below the demo's httpx client spans.
- **`traceparent` header**. The W3C-standard HTTP header that carries the active `trace_id` and parent `span_id` across services. The demo's httpx instrumentation injects it on every outbound call; Kong's OpenTelemetry Policy extracts it on every inbound request.
- **Propagation**. The act of moving trace context from one process to another via headers like `traceparent`. Without it, each AI Model emits its own disconnected trace.
- **Exporter**. The component that ships finished spans to a backend over OTLP. The demo SDK and Kong's Policy each run their own exporter, both pointed at Langfuse.
- **Session (Langfuse-specific)**. A grouping of multiple traces under one logical conversation, keyed by the `langfuse.session.id` attribute on the root span of each trace.

### Per-turn flow

When the demo processes a conversational turn, it makes three sequential requests through Kong:

1. **Authenticate at the gateway.** Every request includes the `apikey` header. The Key Auth AI Auth Strategy matches the value against the registered AI Consumer (`voice-agent`) before any AI Model routes the request. Kong rejects unknown keys with `401 Unauthorized`.

2. **STT hop.** The agent sends an audio file to `/voice-ai-observability/stt`. The `voice-ai-observability-stt` AI Model's target references the OpenAI Model Provider, which injects OpenAI credentials and forwards the audio to Whisper's transcription endpoint. The global OpenTelemetry Policy emits a `gen_ai.*` span with the provider name (`openai`), model (`whisper-1`), and operation metadata.

3. **LLM hop.** The agent sends the transcribed text to `/voice-ai-observability/llm`. The `voice-ai-observability-llm` AI Model's target references the configured LLM provider's AI Model Provider, translates the request format if needed (for example, OpenAI format to Anthropic's messages API), and forwards to the provider. The span includes `gen_ai.usage.input_tokens` and `gen_ai.usage.output_tokens` for cost attribution.

4. **TTS hop.** The agent sends the LLM response text to `/voice-ai-observability/tts`. The `voice-ai-observability-tts` AI Model injects OpenAI credentials and forwards to the TTS endpoint. Kong returns the response to the agent as raw audio bytes.

5. **Trace and Session grouping.** Before any HTTP call, the voice agent (the demo) opens a `voice-turn` parent span via the OpenTelemetry SDK and tags it with `langfuse.session.id`. The httpx auto-instrumentation in the demo wraps the OpenAI SDK's underlying httpx client, so every STT/LLM/TTS call becomes a child span of `voice-turn` and the instrumentation injects a real W3C `traceparent` into the outbound request. Kong's OpenTelemetry Policy extracts that `traceparent` and roots its per-hop server, routing, balancer, DNS, and `gen_ai.*` spans as descendants of the demo's httpx client span. Both exporters ship spans to Langfuse independently; Langfuse reassembles by `trace_id`. The `langfuse.session.id` attribute on the root span tells Langfuse to roll multiple per-turn traces up under one Session for cross-turn analysis.

### Key Auth: voice agent identification

Authentication in {{site.ai_gateway_name}} 2.0 is an AI Auth Strategy, not a policy: policies handle AI-specific behavior like tracing and rate limiting. The Key Auth AI Auth Strategy sits in front of routing and gates every request to all three AI Models. The recipe defines a single `voice-agent` AI Consumer with a static credential. In production, replace the single AI Consumer with one AI Consumer per tenant or per voice client, rotated through [AI Vaults](/ai-gateway/entities/ai-vault/).

#### Configuration details

{%- raw %}
```yaml
ai_gateway_auth_strategies:
  - ref: voice-ai-observability-auth
    type: key-auth
    display_name: "voice-ai-observability key auth"
    config:
      key_names:
        - apikey
      hide_credentials: true

ai_gateway_consumers:
  - ref: voice-ai-observability-consumer
    name: voice-ai-observability-consumer
    display_name: "voice-ai-observability voice agent"
    type: api-key
    credentials:
      - ref: voice-ai-observability-credential
        name: voice-ai-observability-credential
        display_name: "voice-ai-observability demo API key"
        type: api-key
        api_key: !secret {source: !env CONSUMER_API_KEY}
```
{% endraw -%}
{:.no-copy-code}

- **`key_names: [apikey]`**. The header (or query parameter) checked for the API key. The recipe uses `apikey` because this check performs an exact string match on the header value and doesn't inspect `Authorization` for Bearer tokens. The OpenAI SDK's `api_key` field always serializes as `Authorization: Bearer <key>`, which Kong would read as the literal string `Bearer <key>` and fail to match against any stored credential. The demo passes the key through `default_headers` instead.
- **`hide_credentials: true`**. Strips the `apikey` header from the request before it reaches the upstream provider. Without this setting, Kong forwards the credential to OpenAI, Anthropic, and other providers, leaking the gateway-side credential into provider logs.
- **`api_key` is write-only.** An AI Consumer credential's `api_key` field must be a `!secret` reference. Kong rejects a plain string here, even for a demo value like this recipe's. You export `CONSUMER_API_KEY` once in [Apply the Kong configuration](#apply-the-kong-configuration) and reuse it across every provider tab.
- **One AI Auth Strategy, three AI Models.** All three AI Models below reference `voice-ai-observability-auth` via `access.auth_strategies`, so one AI Consumer credential authenticates every hop.

For richer identity flows (JWT-based SSO, scoped audiences, IdP integration), swap Key Auth for the [OpenID Connect](/ai-gateway/openid-connect/) AI Auth Strategy. The [Claude Code SSO recipe](/cookbooks/claude-code-sso/) shows the pattern.

### AI Model and AI Model Provider: speech-to-text transcription

The `voice-ai-observability-stt` AI Model declares `capabilities: [audio/transcription]` to route audio files to OpenAI's Whisper model. The STT AI Model is the entry point of the cascading pipeline: raw audio goes in, transcribed text comes out. Routing STT through Kong instead of calling Whisper directly gives you credential injection, payload logging, and `gen_ai.*` telemetry on the transcription hop without instrumenting your application code.

#### Configuration details

{%- raw %}
```yaml
ai_gateway_model_providers:
  - ref: voice-ai-observability-openai-provider
    type: openai
    display_name: "voice-ai-observability (OpenAI: STT/TTS)"
    config:
      auth:
        type: basic
        headers:
          - name: Authorization
            value: !secret {source: !env DECK_OPENAI_TOKEN}

ai_gateway_models:
  - ref: voice-ai-observability-stt
    type: model
    display_name: "voice-ai-observability (STT)"
    formats:
      - type: openai
    capabilities:
      - audio/transcription
    access:
      auth_strategies:
        - voice-ai-observability-auth
    config:
      max_request_body_size: 26214400
      response_streaming: deny
      logging:
        payloads: true
      route:
        paths:
          - /voice-ai-observability/stt
        protocols: [http, https]
        methods: [POST, OPTIONS]
        strip_path: true
    targets:
      - name: whisper-1
        provider: voice-ai-observability-openai-provider
        config:
          type: openai
```
{% endraw -%}
{:.no-copy-code}

- **`capabilities: [audio/transcription]`**. Declares this AI Model as a speech-to-text operation. Kong uses the capability for Prometheus metric labels and OpenTelemetry span attributes, separating STT metrics from LLM and TTS traffic. See the [AI Model entity reference](/ai-gateway/entities/ai-model/) for the full capabilities enum, which also includes `audio/speech` and `audio/translation` for other audio operations.
- **`max_request_body_size: 26214400`**. Raises the request body limit to 25 MB. Audio files can be several megabytes, and the default limit rejects most audio uploads. Set this to at least three times the expected raw audio file size.
- **`response_streaming: deny`**. Whisper returns the full transcript in one response. Streaming would add complexity for no benefit, so this AI Model refuses streaming requests.
- **`logging.payloads`**. Includes request and response bodies in Kong's log output. For STT, this captures the transcription text. Disable in production if audio payloads contain sensitive content.
- **`targets[].name: whisper-1`**. The upstream model identifier. The value stays fixed across every provider tab because STT always uses Whisper.

### AI Model and AI Model Provider: LLM chat completion

The `voice-ai-observability-llm` AI Model handles the reasoning hop of the pipeline. It's the only AI Model that varies by provider: the AI Model Provider, upstream model name, and provider-specific target fields change depending on which tab you select. It declares `capabilities: [generate]` and `formats: [{type: openai}]`, so it accepts OpenAI-format chat completion requests and Kong translates them to the upstream provider's native format when needed.

#### Configuration details

Here's the OpenAI tab's configuration. Every provider tab follows the same shape, and only the AI Model Provider's `type`/`config.auth` and the target's `config` differ:

{%- raw %}
```yaml
ai_gateway_model_providers:
  - ref: voice-ai-observability-llm-provider
    type: openai
    display_name: "voice-ai-observability (LLM)"
    config:
      auth:
        type: basic
        headers:
          - name: Authorization
            value: !secret {source: !env DECK_OPENAI_TOKEN}

ai_gateway_models:
  - ref: voice-ai-observability-llm
    type: model
    display_name: "voice-ai-observability (LLM)"
    formats:
      - type: openai
    capabilities:
      - generate
    access:
      auth_strategies:
        - voice-ai-observability-auth
    config:
      max_request_body_size: 8388608
      response_streaming: allow
      logging:
        payloads: true
      route:
        paths:
          - /voice-ai-observability/llm
        protocols: [http, https]
        methods: [POST, OPTIONS]
        strip_path: true
    targets:
      - name: !env CHAT_MODEL
        provider: voice-ai-observability-llm-provider
        config:
          type: openai
```
{% endraw -%}
{:.no-copy-code}

- **Two AI Model Providers, one OpenAI tab exception.** STT and TTS always use `voice-ai-observability-openai-provider`. The LLM hop uses a second, independent AI Model Provider (`voice-ai-observability-llm-provider`) so it can point at any supported provider. On the OpenAI tab both AI Model Providers end up with identical configuration, which is expected: one AI Model Provider can back many AI Models, but this recipe keeps the LLM hop's Provider separate so switching it never touches the STT/TTS Provider.
- **`max_request_body_size: 8388608`**. Allows up to 8 MB of request body. Long conversation histories and system prompts can exceed the default limit.
- **`response_streaming: allow`**. Lets clients request server-sent events for token-by-token chat responses. The recipe demo doesn't stream, but production voice agents often do to start TTS earlier in the turn.
- **`formats: [{type: openai}]`**. Accepts an OpenAI-format chat-completion body and normalizes every provider's reply back to OpenAI format, which is what lets the demo call `chat.completions.create(...)` unchanged across every tab. To pass requests through in a provider's native format instead, set `formats` to that format (for example `anthropic`); see the [AI Model entity reference](/ai-gateway/entities/ai-model/) for the supported formats.
- **`config.auth`** (on the AI Model Provider). OpenAI and Mistral use `Authorization: Bearer <key>`, Anthropic uses `x-api-key`, Azure uses `api-key`, Bedrock uses AWS access key pairs, and Gemini uses GCP service account credentials. Kong injects these into every upstream request; the demo only ever holds the recipe's `apikey` credential.
- **`targets[].name`**. The upstream model identifier, resolved from `CHAT_MODEL` at apply time. Change it and re-apply to swap models without changing client code.
- **`targets[].config`**. Provider-specific target fields, for example Bedrock's `region` or Azure's `deployment_id`/`api_version`, live here alongside the `type` discriminator matching the AI Model Provider.

{:.info}
> `logging.payloads` on the AI Model captures full prompt and reply text. The `gen_ai.input.messages` and `gen_ai.output.messages` span attributes in the OpenTelemetry trace also carry this data when payload logging is enabled.

### AI Model and AI Model Provider: text-to-speech synthesis

The `voice-ai-observability-tts` AI Model converts the LLM response to audio, completing the cascading pipeline. Like STT, it uses OpenAI (TTS-1) across all provider tabs, reusing the same `voice-ai-observability-openai-provider` AI Model Provider that backs STT. Routing TTS through Kong gives you the same telemetry contract as the other hops: credential injection, usage logging, and `gen_ai.*` span emission.

#### Configuration details

{%- raw %}
```yaml
ai_gateway_models:
  - ref: voice-ai-observability-tts
    type: model
    display_name: "voice-ai-observability (TTS)"
    formats:
      - type: openai
    capabilities:
      - audio/speech
    access:
      auth_strategies:
        - voice-ai-observability-auth
    config:
      max_request_body_size: 1048576
      response_streaming: allow
      logging:
        payloads: true
      route:
        paths:
          - /voice-ai-observability/tts
        protocols: [http, https]
        methods: [POST, OPTIONS]
        strip_path: true
    targets:
      - name: tts-1
        provider: voice-ai-observability-openai-provider
        config:
          type: openai
```
{% endraw -%}
{:.no-copy-code}

- **`capabilities: [audio/speech]`**. Classifies this as a text-to-speech operation. Kong labels Prometheus metrics and OpenTelemetry spans accordingly, so you can filter TTS latency and cost separately from STT and LLM traffic.
- **`max_request_body_size: 1048576`**. TTS input is plain text, so 1 MB is generous. Set this lower if your voice agent never sends prompts above a few KB.
- **`response_streaming: allow`**. Lets clients request streamed audio chunks instead of waiting for the entire synthesis to finish. Production voice agents use this to begin playback as soon as the first chunk arrives.
- **`targets[].name: tts-1`**. OpenAI's standard TTS model. The [OpenAI TTS documentation](https://platform.openai.com/docs/guides/text-to-speech) lists available voices and higher-quality model variants. The response is raw audio bytes (MP3 by default); the client selects other formats via the `response_format` field in the request body.

### OpenTelemetry: trace export to Langfuse

The [OpenTelemetry](/ai-gateway/policies/opentelemetry/) Policy runs with `global: true`, so it applies to every AI Model on this {{site.ai_gateway}} so you don't list it individually in each Model's `policies`. That single AI Policy captures traces from all three pipeline hops and exports spans to Langfuse's OTLP endpoint, where Langfuse groups them by W3C trace ID into conversation-level traces.

#### Configuration details

{%- raw %}
```yaml
ai_gateway_policies:
  - ref: voice-ai-observability-otel
    type: opentelemetry
    display_name: "voice-ai-observability tracing"
    global: true
    config:
      traces_endpoint: !env DECK_LANGFUSE_OTLP_ENDPOINT
      headers:
        Authorization: !secret {source: !env DECK_LANGFUSE_AUTH_HEADER}
        x-langfuse-ingestion-version: "4"
      sampling_rate: 1
      propagation:
        default_format: w3c
```
{% endraw -%}
{:.no-copy-code}

- **`global: true`**. Applies this AI Policy to every AI Model on the {{site.ai_gateway}} instead of one Model at a time. The global scope lets one AI Policy instance capture the full STT to LLM to TTS pipeline without declaring it three times.
- **`traces_endpoint`**. The OTLP/HTTP endpoint where Kong sends trace data. For Langfuse Cloud, use `https://us.cloud.langfuse.com/api/public/otel/v1/traces` (US) or `https://cloud.langfuse.com/api/public/otel/v1/traces` (EU). For self-hosted Langfuse, use `http://host.docker.internal:3000/api/public/otel/v1/traces`.
- **`headers.Authorization`**. Basic auth header constructed from your Langfuse public key and secret key: `Basic <base64(pk:sk)>`. The header authenticates trace export to your Langfuse project.
- **`headers.x-langfuse-ingestion-version: "4"`**. Enables Langfuse's real-time Fast Preview display for incoming traces.
- **`sampling_rate: 1`**. Samples 100% of requests. Reduce this in high-traffic production environments to control trace volume and cost.
- **`propagation.default_format: w3c`**. Uses W3C Trace Context for trace ID propagation. When a client sends a `traceparent` header, the AI Policy preserves that trace ID on the emitted span. Langfuse uses that shared trace ID to group multiple requests (STT, LLM, TTS) under a single trace.

Kong emits `gen_ai.*` span attributes on every AI Model request. These attributes follow the [OpenTelemetry GenAI semantic conventions](https://opentelemetry.io/docs/specs/semconv/registry/attributes/gen-ai/) and include:

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
    description: "Model name from the request"
  - attribute: "`gen_ai.response.model`"
    description: "Model name from the provider response"
  - attribute: "`gen_ai.operation.name`"
    description: "Operation type (`chat`, `audio/transcription`, `audio/speech`)"
  - attribute: "`gen_ai.usage.input_tokens`"
    description: "Input token count"
  - attribute: "`gen_ai.usage.output_tokens`"
    description: "Output token count"
  - attribute: "`gen_ai.input.messages`"
    description: "Full input messages (when payload logging is enabled)"
  - attribute: "`gen_ai.output.messages`"
    description: "Full output messages (when payload logging is enabled)"
{% endtable %}

### Production considerations

{:.info}
> In production, store credentials in [AI Vaults](/ai-gateway/entities/ai-vault/) using {%raw%}`{vault://backend/key}`{%endraw%} references rather than environment variables. AI Vaults support HashiCorp Vault, AWS Secrets Manager, GCP Secret Manager, and the {{site.konnect_short_name}} Config Store.

Review your data retention and access control policies before enabling `logging.payloads` in production, since the resulting `gen_ai.input.messages` and `gen_ai.output.messages` span attributes may contain PII, sensitive business context, or credentials passed in prompts.

## Apply the Kong configuration

The following configuration creates two AI Model Providers (one fixed to OpenAI for STT/TTS, one for your chosen LLM provider), three AI Models (`voice-ai-observability-stt`, `voice-ai-observability-llm`, `voice-ai-observability-tts`), a Key Auth AI Auth Strategy with a `voice-agent` AI Consumer, and a global OpenTelemetry Policy exporting traces to Langfuse. A kongctl namespace scopes every resource, so you can tear down the recipe cleanly without affecting other configurations on the same {{site.ai_gateway}}. See the [kongctl documentation](/kongctl/) for more on federated configuration management.

First, adopt the quickstart {{site.ai_gateway}} into a kongctl namespace so the following apply commands can manage it.

```bash
kongctl adopt ai-gateway "${KONNECT_CONTROL_PLANE_NAME}" \
  --namespace "${KONNECT_CONTROL_PLANE_NAME}" \
  --pat "${KONNECT_TOKEN}"
```

Adoption stamps the `KONGCTL-namespace` label on the {{site.ai_gateway}}.

Export the demo AI Consumer's API key. The AI Consumer credential's `api_key` field is write-only and must come from an env var, even for this fixed demo value:

```bash
export CONSUMER_API_KEY='voice-demo-key'
```

You exported provider credentials and the Langfuse endpoint once in the prerequisites. Each tab below only sets the LLM model env var (which is recipe-specific) and runs the apply.

{% navtabs "Providers" %}
{% tab OpenAI %}

Export the per-tab environment variable:

```bash
export CHAT_MODEL='gpt-4o'  # or gpt-4o-mini, o3
```

Apply the Kong configuration:

```bash
{%- raw %}
cat <<'EOF' > kong-recipe.yaml
_defaults:
  kongctl:
    namespace: voice-ai-observability-recipe
ai_gateway_model_providers:
- ref: voice-ai-observability-openai-provider
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: voice-ai-observability-openai-provider
  display_name: 'voice-ai-observability (OpenAI: STT/TTS)'
  type: openai
  config:
    auth:
      type: basic
      headers:
      - name: Authorization
        value: !secret {source: !env 'DECK_OPENAI_TOKEN'}
- ref: voice-ai-observability-llm-provider
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: voice-ai-observability-llm-provider
  display_name: voice-ai-observability (LLM)
  type: openai
  config:
    auth:
      type: basic
      headers:
      - name: Authorization
        value: !secret {source: !env 'DECK_OPENAI_TOKEN'}
ai_gateway_auth_strategies:
- ref: voice-ai-observability-auth
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: voice-ai-observability-auth
  display_name: voice-ai-observability key auth
  type: key-auth
  config:
    key_names:
    - apikey
    hide_credentials: true
ai_gateway_consumers:
- ref: voice-ai-observability-consumer
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: voice-ai-observability-consumer
  display_name: voice-ai-observability voice agent
  type: api-key
  credentials:
  - ref: voice-ai-observability-credential
    name: voice-ai-observability-credential
    display_name: voice-ai-observability demo API key
    type: api-key
    api_key: !secret {source: !env 'CONSUMER_API_KEY'}
ai_gateway_policies:
- ref: voice-ai-observability-otel
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: voice-ai-observability-otel
  display_name: voice-ai-observability tracing
  type: opentelemetry
  global: true
  config:
    traces_endpoint: !env 'DECK_LANGFUSE_OTLP_ENDPOINT'
    headers:
      Authorization: !secret {source: !env 'DECK_LANGFUSE_AUTH_HEADER'}
      x-langfuse-ingestion-version: '4'
    sampling_rate: 1
    propagation:
      default_format: w3c
ai_gateway_models:
- ref: voice-ai-observability-stt
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: voice-ai-observability-stt
  display_name: voice-ai-observability (STT)
  type: model
  formats:
  - type: openai
  capabilities:
  - audio/transcription
  access:
    auth_strategies:
    - voice-ai-observability-auth
  config:
    max_request_body_size: 26214400
    response_streaming: deny
    logging:
      payloads: true
    route:
      paths:
      - /voice-ai-observability/stt
      protocols:
      - http
      - https
      methods:
      - POST
      - OPTIONS
      strip_path: true
  targets:
  - name: whisper-1
    provider: voice-ai-observability-openai-provider
    config:
      type: openai
- ref: voice-ai-observability-llm
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: voice-ai-observability-llm
  display_name: voice-ai-observability (LLM)
  type: model
  formats:
  - type: openai
  capabilities:
  - generate
  access:
    auth_strategies:
    - voice-ai-observability-auth
  config:
    max_request_body_size: 8388608
    response_streaming: allow
    logging:
      payloads: true
    route:
      paths:
      - /voice-ai-observability/llm
      protocols:
      - http
      - https
      methods:
      - POST
      - OPTIONS
      strip_path: true
  targets:
  - name: !env 'CHAT_MODEL'
    provider: voice-ai-observability-llm-provider
    config:
      type: openai
- ref: voice-ai-observability-tts
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: voice-ai-observability-tts
  display_name: voice-ai-observability (TTS)
  type: model
  formats:
  - type: openai
  capabilities:
  - audio/speech
  access:
    auth_strategies:
    - voice-ai-observability-auth
  config:
    max_request_body_size: 1048576
    response_streaming: allow
    logging:
      payloads: true
    route:
      paths:
      - /voice-ai-observability/tts
      protocols:
      - http
      - https
      methods:
      - POST
      - OPTIONS
      strip_path: true
  targets:
  - name: tts-1
    provider: voice-ai-observability-openai-provider
    config:
      type: openai
EOF
{% endraw -%}

kongctl apply -f kong-recipe.yaml -o text --auto-approve --pat "${KONNECT_TOKEN}"

rm -f kong-recipe.yaml
```
{: data-test-step="block" .collapsible }

{% endtab %}
{% tab Anthropic %}

Export the per-tab environment variable:

```bash
export CHAT_MODEL='claude-sonnet-4-5-20250929'  # or claude-haiku-4-5-20251001
```

Apply the Kong configuration:

```bash
{%- raw %}
cat <<'EOF' > kong-recipe.yaml
_defaults:
  kongctl:
    namespace: voice-ai-observability-recipe
ai_gateway_model_providers:
- ref: voice-ai-observability-openai-provider
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: voice-ai-observability-openai-provider
  display_name: 'voice-ai-observability (OpenAI: STT/TTS)'
  type: openai
  config:
    auth:
      type: basic
      headers:
      - name: Authorization
        value: !secret {source: !env 'DECK_OPENAI_TOKEN'}
- ref: voice-ai-observability-llm-provider
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: voice-ai-observability-llm-provider
  display_name: voice-ai-observability (LLM)
  type: anthropic
  config:
    auth:
      type: basic
      headers:
      - name: x-api-key
        value: !secret {source: !env 'DECK_ANTHROPIC_TOKEN'}
ai_gateway_auth_strategies:
- ref: voice-ai-observability-auth
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: voice-ai-observability-auth
  display_name: voice-ai-observability key auth
  type: key-auth
  config:
    key_names:
    - apikey
    hide_credentials: true
ai_gateway_consumers:
- ref: voice-ai-observability-consumer
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: voice-ai-observability-consumer
  display_name: voice-ai-observability voice agent
  type: api-key
  credentials:
  - ref: voice-ai-observability-credential
    name: voice-ai-observability-credential
    display_name: voice-ai-observability demo API key
    type: api-key
    api_key: !secret {source: !env 'CONSUMER_API_KEY'}
ai_gateway_policies:
- ref: voice-ai-observability-otel
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: voice-ai-observability-otel
  display_name: voice-ai-observability tracing
  type: opentelemetry
  global: true
  config:
    traces_endpoint: !env 'DECK_LANGFUSE_OTLP_ENDPOINT'
    headers:
      Authorization: !secret {source: !env 'DECK_LANGFUSE_AUTH_HEADER'}
      x-langfuse-ingestion-version: '4'
    sampling_rate: 1
    propagation:
      default_format: w3c
ai_gateway_models:
- ref: voice-ai-observability-stt
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: voice-ai-observability-stt
  display_name: voice-ai-observability (STT)
  type: model
  formats:
  - type: openai
  capabilities:
  - audio/transcription
  access:
    auth_strategies:
    - voice-ai-observability-auth
  config:
    max_request_body_size: 26214400
    response_streaming: deny
    logging:
      payloads: true
    route:
      paths:
      - /voice-ai-observability/stt
      protocols:
      - http
      - https
      methods:
      - POST
      - OPTIONS
      strip_path: true
  targets:
  - name: whisper-1
    provider: voice-ai-observability-openai-provider
    config:
      type: openai
- ref: voice-ai-observability-llm
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: voice-ai-observability-llm
  display_name: voice-ai-observability (LLM)
  type: model
  formats:
  - type: openai
  capabilities:
  - generate
  access:
    auth_strategies:
    - voice-ai-observability-auth
  config:
    max_request_body_size: 8388608
    response_streaming: allow
    logging:
      payloads: true
    route:
      paths:
      - /voice-ai-observability/llm
      protocols:
      - http
      - https
      methods:
      - POST
      - OPTIONS
      strip_path: true
  targets:
  - name: !env 'CHAT_MODEL'
    provider: voice-ai-observability-llm-provider
    config:
      version: !env 'DECK_ANTHROPIC_VERSION'
      type: anthropic
- ref: voice-ai-observability-tts
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: voice-ai-observability-tts
  display_name: voice-ai-observability (TTS)
  type: model
  formats:
  - type: openai
  capabilities:
  - audio/speech
  access:
    auth_strategies:
    - voice-ai-observability-auth
  config:
    max_request_body_size: 1048576
    response_streaming: allow
    logging:
      payloads: true
    route:
      paths:
      - /voice-ai-observability/tts
      protocols:
      - http
      - https
      methods:
      - POST
      - OPTIONS
      strip_path: true
  targets:
  - name: tts-1
    provider: voice-ai-observability-openai-provider
    config:
      type: openai
EOF
{% endraw -%}

kongctl apply -f kong-recipe.yaml -o text --auto-approve --pat "${KONNECT_TOKEN}"

rm -f kong-recipe.yaml
```
{: data-test-step="block" .collapsible }

{% endtab %}
{% tab AWS Bedrock %}

Export the per-tab environment variable:

```bash
export CHAT_MODEL='amazon.nova-pro-v1:0'  # or global.anthropic.claude-sonnet-4-5-20250929-v1:0
```

Apply the Kong configuration:

```bash
{%- raw %}
cat <<'EOF' > kong-recipe.yaml
_defaults:
  kongctl:
    namespace: voice-ai-observability-recipe
ai_gateway_model_providers:
- ref: voice-ai-observability-openai-provider
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: voice-ai-observability-openai-provider
  display_name: 'voice-ai-observability (OpenAI: STT/TTS)'
  type: openai
  config:
    auth:
      type: basic
      headers:
      - name: Authorization
        value: !secret {source: !env 'DECK_OPENAI_TOKEN'}
- ref: voice-ai-observability-llm-provider
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: voice-ai-observability-llm-provider
  display_name: voice-ai-observability (LLM)
  type: bedrock
  config:
    auth:
      type: aws
      access_key_id: !env 'DECK_AWS_ACCESS_KEY_ID'
      secret_access_key: !secret {source: !env 'DECK_AWS_SECRET_ACCESS_KEY'}
ai_gateway_auth_strategies:
- ref: voice-ai-observability-auth
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: voice-ai-observability-auth
  display_name: voice-ai-observability key auth
  type: key-auth
  config:
    key_names:
    - apikey
    hide_credentials: true
ai_gateway_consumers:
- ref: voice-ai-observability-consumer
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: voice-ai-observability-consumer
  display_name: voice-ai-observability voice agent
  type: api-key
  credentials:
  - ref: voice-ai-observability-credential
    name: voice-ai-observability-credential
    display_name: voice-ai-observability demo API key
    type: api-key
    api_key: !secret {source: !env 'CONSUMER_API_KEY'}
ai_gateway_policies:
- ref: voice-ai-observability-otel
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: voice-ai-observability-otel
  display_name: voice-ai-observability tracing
  type: opentelemetry
  global: true
  config:
    traces_endpoint: !env 'DECK_LANGFUSE_OTLP_ENDPOINT'
    headers:
      Authorization: !secret {source: !env 'DECK_LANGFUSE_AUTH_HEADER'}
      x-langfuse-ingestion-version: '4'
    sampling_rate: 1
    propagation:
      default_format: w3c
ai_gateway_models:
- ref: voice-ai-observability-stt
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: voice-ai-observability-stt
  display_name: voice-ai-observability (STT)
  type: model
  formats:
  - type: openai
  capabilities:
  - audio/transcription
  access:
    auth_strategies:
    - voice-ai-observability-auth
  config:
    max_request_body_size: 26214400
    response_streaming: deny
    logging:
      payloads: true
    route:
      paths:
      - /voice-ai-observability/stt
      protocols:
      - http
      - https
      methods:
      - POST
      - OPTIONS
      strip_path: true
  targets:
  - name: whisper-1
    provider: voice-ai-observability-openai-provider
    config:
      type: openai
- ref: voice-ai-observability-llm
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: voice-ai-observability-llm
  display_name: voice-ai-observability (LLM)
  type: model
  formats:
  - type: openai
  capabilities:
  - generate
  access:
    auth_strategies:
    - voice-ai-observability-auth
  config:
    max_request_body_size: 8388608
    response_streaming: allow
    logging:
      payloads: true
    route:
      paths:
      - /voice-ai-observability/llm
      protocols:
      - http
      - https
      methods:
      - POST
      - OPTIONS
      strip_path: true
  targets:
  - name: !env 'CHAT_MODEL'
    provider: voice-ai-observability-llm-provider
    config:
      region: !env 'DECK_AWS_REGION'
      type: bedrock
- ref: voice-ai-observability-tts
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: voice-ai-observability-tts
  display_name: voice-ai-observability (TTS)
  type: model
  formats:
  - type: openai
  capabilities:
  - audio/speech
  access:
    auth_strategies:
    - voice-ai-observability-auth
  config:
    max_request_body_size: 1048576
    response_streaming: allow
    logging:
      payloads: true
    route:
      paths:
      - /voice-ai-observability/tts
      protocols:
      - http
      - https
      methods:
      - POST
      - OPTIONS
      strip_path: true
  targets:
  - name: tts-1
    provider: voice-ai-observability-openai-provider
    config:
      type: openai
EOF
{% endraw -%}

kongctl apply -f kong-recipe.yaml -o text --auto-approve --pat "${KONNECT_TOKEN}"

rm -f kong-recipe.yaml
```
{: data-test-step="block" .collapsible }

{% endtab %}
{% tab Azure OpenAI %}

Export the per-tab environment variable. It must match the model deployed at `DECK_AZURE_DEPLOYMENT_ID` from the AI Credentials prereq:

```bash
export CHAT_MODEL='gpt-4o'  # matches your Azure deployment name
```

Apply the Kong configuration:

```bash
{%- raw %}
cat <<'EOF' > kong-recipe.yaml
_defaults:
  kongctl:
    namespace: voice-ai-observability-recipe
ai_gateway_model_providers:
- ref: voice-ai-observability-openai-provider
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: voice-ai-observability-openai-provider
  display_name: 'voice-ai-observability (OpenAI: STT/TTS)'
  type: openai
  config:
    auth:
      type: basic
      headers:
      - name: Authorization
        value: !secret {source: !env 'DECK_OPENAI_TOKEN'}
- ref: voice-ai-observability-llm-provider
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: voice-ai-observability-llm-provider
  display_name: voice-ai-observability (LLM)
  type: azure
  config:
    auth:
      type: basic
      headers:
      - name: api-key
        value: !secret {source: !env 'DECK_AZURE_API_KEY'}
    service: azure-openai
    instance: !env 'DECK_AZURE_INSTANCE'
ai_gateway_auth_strategies:
- ref: voice-ai-observability-auth
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: voice-ai-observability-auth
  display_name: voice-ai-observability key auth
  type: key-auth
  config:
    key_names:
    - apikey
    hide_credentials: true
ai_gateway_consumers:
- ref: voice-ai-observability-consumer
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: voice-ai-observability-consumer
  display_name: voice-ai-observability voice agent
  type: api-key
  credentials:
  - ref: voice-ai-observability-credential
    name: voice-ai-observability-credential
    display_name: voice-ai-observability demo API key
    type: api-key
    api_key: !secret {source: !env 'CONSUMER_API_KEY'}
ai_gateway_policies:
- ref: voice-ai-observability-otel
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: voice-ai-observability-otel
  display_name: voice-ai-observability tracing
  type: opentelemetry
  global: true
  config:
    traces_endpoint: !env 'DECK_LANGFUSE_OTLP_ENDPOINT'
    headers:
      Authorization: !secret {source: !env 'DECK_LANGFUSE_AUTH_HEADER'}
      x-langfuse-ingestion-version: '4'
    sampling_rate: 1
    propagation:
      default_format: w3c
ai_gateway_models:
- ref: voice-ai-observability-stt
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: voice-ai-observability-stt
  display_name: voice-ai-observability (STT)
  type: model
  formats:
  - type: openai
  capabilities:
  - audio/transcription
  access:
    auth_strategies:
    - voice-ai-observability-auth
  config:
    max_request_body_size: 26214400
    response_streaming: deny
    logging:
      payloads: true
    route:
      paths:
      - /voice-ai-observability/stt
      protocols:
      - http
      - https
      methods:
      - POST
      - OPTIONS
      strip_path: true
  targets:
  - name: whisper-1
    provider: voice-ai-observability-openai-provider
    config:
      type: openai
- ref: voice-ai-observability-llm
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: voice-ai-observability-llm
  display_name: voice-ai-observability (LLM)
  type: model
  formats:
  - type: openai
  capabilities:
  - generate
  access:
    auth_strategies:
    - voice-ai-observability-auth
  config:
    max_request_body_size: 8388608
    response_streaming: allow
    logging:
      payloads: true
    route:
      paths:
      - /voice-ai-observability/llm
      protocols:
      - http
      - https
      methods:
      - POST
      - OPTIONS
      strip_path: true
  targets:
  - name: !env 'CHAT_MODEL'
    provider: voice-ai-observability-llm-provider
    config:
      api_version: !env 'DECK_AZURE_API_VERSION'
      deployment_id: !env 'DECK_AZURE_DEPLOYMENT_ID'
      type: azure
- ref: voice-ai-observability-tts
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: voice-ai-observability-tts
  display_name: voice-ai-observability (TTS)
  type: model
  formats:
  - type: openai
  capabilities:
  - audio/speech
  access:
    auth_strategies:
    - voice-ai-observability-auth
  config:
    max_request_body_size: 1048576
    response_streaming: allow
    logging:
      payloads: true
    route:
      paths:
      - /voice-ai-observability/tts
      protocols:
      - http
      - https
      methods:
      - POST
      - OPTIONS
      strip_path: true
  targets:
  - name: tts-1
    provider: voice-ai-observability-openai-provider
    config:
      type: openai
EOF
{% endraw -%}

kongctl apply -f kong-recipe.yaml -o text --auto-approve --pat "${KONNECT_TOKEN}"

rm -f kong-recipe.yaml
```
{: data-test-step="block" .collapsible }

{% endtab %}
{% tab Google Gemini %}

Export the per-tab environment variable:

```bash
export CHAT_MODEL='gemini-2.0-flash'  # or gemini-1.5-pro
```

Apply the Kong configuration:

```bash
{%- raw %}
cat <<'EOF' > kong-recipe.yaml
_defaults:
  kongctl:
    namespace: voice-ai-observability-recipe
ai_gateway_model_providers:
- ref: voice-ai-observability-openai-provider
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: voice-ai-observability-openai-provider
  display_name: 'voice-ai-observability (OpenAI: STT/TTS)'
  type: openai
  config:
    auth:
      type: basic
      headers:
      - name: Authorization
        value: !secret {source: !env 'DECK_OPENAI_TOKEN'}
- ref: voice-ai-observability-llm-provider
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: voice-ai-observability-llm-provider
  display_name: voice-ai-observability (LLM)
  type: gemini
  config:
    auth:
      type: gcp
      use_gcp_service_account: true
ai_gateway_auth_strategies:
- ref: voice-ai-observability-auth
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: voice-ai-observability-auth
  display_name: voice-ai-observability key auth
  type: key-auth
  config:
    key_names:
    - apikey
    hide_credentials: true
ai_gateway_consumers:
- ref: voice-ai-observability-consumer
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: voice-ai-observability-consumer
  display_name: voice-ai-observability voice agent
  type: api-key
  credentials:
  - ref: voice-ai-observability-credential
    name: voice-ai-observability-credential
    display_name: voice-ai-observability demo API key
    type: api-key
    api_key: !secret {source: !env 'CONSUMER_API_KEY'}
ai_gateway_policies:
- ref: voice-ai-observability-otel
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: voice-ai-observability-otel
  display_name: voice-ai-observability tracing
  type: opentelemetry
  global: true
  config:
    traces_endpoint: !env 'DECK_LANGFUSE_OTLP_ENDPOINT'
    headers:
      Authorization: !secret {source: !env 'DECK_LANGFUSE_AUTH_HEADER'}
      x-langfuse-ingestion-version: '4'
    sampling_rate: 1
    propagation:
      default_format: w3c
ai_gateway_models:
- ref: voice-ai-observability-stt
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: voice-ai-observability-stt
  display_name: voice-ai-observability (STT)
  type: model
  formats:
  - type: openai
  capabilities:
  - audio/transcription
  access:
    auth_strategies:
    - voice-ai-observability-auth
  config:
    max_request_body_size: 26214400
    response_streaming: deny
    logging:
      payloads: true
    route:
      paths:
      - /voice-ai-observability/stt
      protocols:
      - http
      - https
      methods:
      - POST
      - OPTIONS
      strip_path: true
  targets:
  - name: whisper-1
    provider: voice-ai-observability-openai-provider
    config:
      type: openai
- ref: voice-ai-observability-llm
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: voice-ai-observability-llm
  display_name: voice-ai-observability (LLM)
  type: model
  formats:
  - type: openai
  capabilities:
  - generate
  access:
    auth_strategies:
    - voice-ai-observability-auth
  config:
    max_request_body_size: 8388608
    response_streaming: allow
    logging:
      payloads: true
    route:
      paths:
      - /voice-ai-observability/llm
      protocols:
      - http
      - https
      methods:
      - POST
      - OPTIONS
      strip_path: true
  targets:
  - name: !env 'CHAT_MODEL'
    provider: voice-ai-observability-llm-provider
    config:
      gcp_environment:
        api_endpoint: !env 'DECK_GCP_API_ENDPOINT'
        project_id: !env 'DECK_GCP_PROJECT_ID'
        location_id: !env 'DECK_GCP_LOCATION_ID'
      type: gemini
- ref: voice-ai-observability-tts
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: voice-ai-observability-tts
  display_name: voice-ai-observability (TTS)
  type: model
  formats:
  - type: openai
  capabilities:
  - audio/speech
  access:
    auth_strategies:
    - voice-ai-observability-auth
  config:
    max_request_body_size: 1048576
    response_streaming: allow
    logging:
      payloads: true
    route:
      paths:
      - /voice-ai-observability/tts
      protocols:
      - http
      - https
      methods:
      - POST
      - OPTIONS
      strip_path: true
  targets:
  - name: tts-1
    provider: voice-ai-observability-openai-provider
    config:
      type: openai
EOF
{% endraw -%}

kongctl apply -f kong-recipe.yaml -o text --auto-approve --pat "${KONNECT_TOKEN}"

rm -f kong-recipe.yaml
```
{: data-test-step="block" .collapsible }

{% endtab %}
{% tab Mistral %}

Export the per-tab environment variable:

```bash
export CHAT_MODEL='mistral-large-latest'  # or mistral-small-latest
```

Apply the Kong configuration:

```bash
{%- raw %}
cat <<'EOF' > kong-recipe.yaml
_defaults:
  kongctl:
    namespace: voice-ai-observability-recipe
ai_gateway_model_providers:
- ref: voice-ai-observability-openai-provider
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: voice-ai-observability-openai-provider
  display_name: 'voice-ai-observability (OpenAI: STT/TTS)'
  type: openai
  config:
    auth:
      type: basic
      headers:
      - name: Authorization
        value: !secret {source: !env 'DECK_OPENAI_TOKEN'}
- ref: voice-ai-observability-llm-provider
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: voice-ai-observability-llm-provider
  display_name: voice-ai-observability (LLM)
  type: mistral
  config:
    auth:
      type: basic
      headers:
      - name: Authorization
        value: !secret {source: !env 'DECK_MISTRAL_TOKEN'}
ai_gateway_auth_strategies:
- ref: voice-ai-observability-auth
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: voice-ai-observability-auth
  display_name: voice-ai-observability key auth
  type: key-auth
  config:
    key_names:
    - apikey
    hide_credentials: true
ai_gateway_consumers:
- ref: voice-ai-observability-consumer
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: voice-ai-observability-consumer
  display_name: voice-ai-observability voice agent
  type: api-key
  credentials:
  - ref: voice-ai-observability-credential
    name: voice-ai-observability-credential
    display_name: voice-ai-observability demo API key
    type: api-key
    api_key: !secret {source: !env 'CONSUMER_API_KEY'}
ai_gateway_policies:
- ref: voice-ai-observability-otel
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: voice-ai-observability-otel
  display_name: voice-ai-observability tracing
  type: opentelemetry
  global: true
  config:
    traces_endpoint: !env 'DECK_LANGFUSE_OTLP_ENDPOINT'
    headers:
      Authorization: !secret {source: !env 'DECK_LANGFUSE_AUTH_HEADER'}
      x-langfuse-ingestion-version: '4'
    sampling_rate: 1
    propagation:
      default_format: w3c
ai_gateway_models:
- ref: voice-ai-observability-stt
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: voice-ai-observability-stt
  display_name: voice-ai-observability (STT)
  type: model
  formats:
  - type: openai
  capabilities:
  - audio/transcription
  access:
    auth_strategies:
    - voice-ai-observability-auth
  config:
    max_request_body_size: 26214400
    response_streaming: deny
    logging:
      payloads: true
    route:
      paths:
      - /voice-ai-observability/stt
      protocols:
      - http
      - https
      methods:
      - POST
      - OPTIONS
      strip_path: true
  targets:
  - name: whisper-1
    provider: voice-ai-observability-openai-provider
    config:
      type: openai
- ref: voice-ai-observability-llm
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: voice-ai-observability-llm
  display_name: voice-ai-observability (LLM)
  type: model
  formats:
  - type: openai
  capabilities:
  - generate
  access:
    auth_strategies:
    - voice-ai-observability-auth
  config:
    max_request_body_size: 8388608
    response_streaming: allow
    logging:
      payloads: true
    route:
      paths:
      - /voice-ai-observability/llm
      protocols:
      - http
      - https
      methods:
      - POST
      - OPTIONS
      strip_path: true
  targets:
  - name: !env 'CHAT_MODEL'
    provider: voice-ai-observability-llm-provider
    config:
      format: openai
      type: mistral
- ref: voice-ai-observability-tts
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: voice-ai-observability-tts
  display_name: voice-ai-observability (TTS)
  type: model
  formats:
  - type: openai
  capabilities:
  - audio/speech
  access:
    auth_strategies:
    - voice-ai-observability-auth
  config:
    max_request_body_size: 1048576
    response_streaming: allow
    logging:
      payloads: true
    route:
      paths:
      - /voice-ai-observability/tts
      protocols:
      - http
      - https
      methods:
      - POST
      - OPTIONS
      strip_path: true
  targets:
  - name: tts-1
    provider: voice-ai-observability-openai-provider
    config:
      type: openai
EOF
{% endraw -%}

kongctl apply -f kong-recipe.yaml -o text --auto-approve --pat "${KONNECT_TOKEN}"

rm -f kong-recipe.yaml
```
{: data-test-step="block" .collapsible }

{% endtab %}
{% endnavtabs %}

## Try it out

The demo script runs a short three-turn voice conversation through the recipe. It opens with a setup phase that synthesizes the question audio for each turn directly via OpenAI's TTS API, bypassing Kong. These calls stand in for a microphone source a real voice agent would have, and the demo doesn't trace them. Before any traced turn runs, the demo also sends one request with an invalid `apikey` to confirm Kong returns `401`. It then runs three traced turns. Each turn opens a `voice-turn` parent span via the OpenTelemetry SDK and executes the three production hops through Kong: STT, then LLM, then TTS. The httpx instrumentation injects W3C `traceparent` into every outbound request so Kong's per-hop spans nest as descendants of the demo's parent span. All three turns share a single Langfuse `langfuse.session.id`, so they roll up into one Session for cross-turn analysis.

{:.info}
> The demo passes the API key via `default_headers` because the OpenAI SDK reserves `api_key` for the `Authorization: Bearer` header. To let clients pass the key through `api_key` directly, attach a [Pre-Function](/ai-gateway/policies/pre-function/) Policy that copies the Bearer token to the `apikey` header server-side.

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
    description: "Upstream model that served the request (LLM hop only)"
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
CONSUMER_API_KEY = os.getenv("CONSUMER_API_KEY", "voice-demo-key")
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
    default_headers={"apikey": CONSUMER_API_KEY},
)

llm_client = OpenAI(
    base_url=f"{PROXY_URL}/voice-ai-observability/llm",
    api_key="placeholder",
    default_headers={"apikey": CONSUMER_API_KEY},
)

tts_client = OpenAI(
    base_url=f"{PROXY_URL}/voice-ai-observability/tts",
    api_key="placeholder",
    default_headers={"apikey": CONSUMER_API_KEY},
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

    Confirms key-auth is enforced on the recipe's AI Models before any
    traced turn runs. Suppress instrumentation so this setup probe doesn't
    pollute Langfuse with an unauthenticated outlier.
    """
    bad_key = "wrong-key"
    print(f"  {DIM(f'Attempting request with apikey={bad_key!r}...')}")
    bad_client = OpenAI(
        base_url=f"{PROXY_URL}/voice-ai-observability/llm",
        api_key="placeholder",
        default_headers={"apikey": bad_key},
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
    """Transcribe audio via the Kong STT AI Model."""
    with tempfile.NamedTemporaryFile(suffix=".mp3", delete=False) as tmp:
        tmp.write(audio_bytes)
        tmp_path = Path(tmp.name)

    try:
        start = time.perf_counter()
        with open(tmp_path, "rb") as f:
            raw = stt_client.audio.transcriptions.with_raw_response.create(
                model="whisper-1", file=f
            )
        elapsed = time.perf_counter() - start
    finally:
        tmp_path.unlink(missing_ok=True)

    transcript = raw.parse()
    upstream_ms = raw.headers.get("x-kong-upstream-latency", "-")

    print(f"  {CYAN(BOLD('[STT]'))} \"{transcript.text}\" {DIM(f'(upstream={upstream_ms}ms, {elapsed:.3f}s wall)')}")
    return transcript.text, elapsed


def llm_chat(messages):
    """Send the conversation so far to the LLM via the Kong chat AI Model."""
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
    """Synthesize the LLM response to audio via the Kong TTS AI Model."""
    start = time.perf_counter()
    raw = tts_client.audio.speech.with_raw_response.create(
        model="tts-1", voice="alloy", input=text
    )
    elapsed = time.perf_counter() - start
    audio_bytes = raw.parse().read()
    upstream_ms = raw.headers.get("x-kong-upstream-latency", "-")

    print(f"  {CYAN(BOLD('[TTS]'))} Generated {len(audio_bytes):,} bytes of audio {DIM(f'(upstream={upstream_ms}ms, {elapsed:.3f}s wall)')}")
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
  Attempting request with apikey='wrong-key'...
  [AUTH] expected reject -> 401 Error code: 401 - {'message': 'No API key found in request'}

Synthesizing question audio (out of band, not traced)...
  Synthesized: "What are the three laws of robotics?"
  Synthesized: "Who wrote them?"
  Synthesized: "What year were they first published?"

Turn 1: "What are the three laws of robotics?"
============================================================

1. Speech -> Text (STT)
  [STT] "What are the three laws of robotics?" (upstream=642ms, 0.876s wall)

2. Transcription -> LLM
  [LLM] "Isaac Asimov's three laws state that a robot must not harm a human, must obey human orders unless they conflict with the first law, and must protect its own existence unless that conflicts with the first two."
         Model: gpt-4o  Tokens: 58 in / 44 out  Upstream: 821ms (0.842s wall)

3. LLM Response -> Speech (TTS)
  [TTS] Generated 218,400 bytes of audio (upstream=2811ms, 2.943s wall)

------------------------------------------------------------
Turn complete: 4.661s total (stt: 0.876s + llm: 0.842s + tts: 2.943s)
Trace ID: a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6

Turn 2: "Who wrote them?"
============================================================

1. Speech -> Text (STT)
  [STT] "Who wrote them?" (upstream=298ms, 0.412s wall)

2. Transcription -> LLM
  [LLM] "Isaac Asimov, the science fiction author, wrote the three laws of robotics."
         Model: gpt-4o  Tokens: 88 in / 16 out  Upstream: 318ms (0.331s wall)

3. LLM Response -> Speech (TTS)
  [TTS] Generated 65,760 bytes of audio (upstream=498ms, 0.624s wall)

------------------------------------------------------------
Turn complete: 1.367s total (stt: 0.412s + llm: 0.331s + tts: 0.624s)
Trace ID: b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7

Turn 3: "What year were they first published?"
============================================================

1. Speech -> Text (STT)
  [STT] "What year were they first published?" (upstream=361ms, 0.487s wall)

2. Transcription -> LLM
  [LLM] "Asimov first introduced the three laws in his 1942 short story 'Runaround.'"
         Model: gpt-4o  Tokens: 116 in / 19 out  Upstream: 401ms (0.418s wall)

3. LLM Response -> Speech (TTS)
  [TTS] Generated 70,080 bytes of audio (upstream=724ms, 0.892s wall)

------------------------------------------------------------
Turn complete: 1.797s total (stt: 0.487s + llm: 0.418s + tts: 0.892s)
Trace ID: c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8

============================================================
Session complete: voice-demo-7f3a2c1b9e8d
View this conversation in Langfuse -> Sessions -> voice-demo-7f3a2c1b9e8d
```
{:.no-copy-code}

### What happened

1. **Auth boundary check.** Before any traced traffic, the demo printed the credential it was about to send, then sent one request with `apikey: wrong-key`. The Key Auth AI Auth Strategy rejected it with `401`, confirming Kong is gating every AI Model. The demo suppresses this call from instrumentation, so it doesn't appear in Langfuse.

2. **Setup (not traced).** Before any spans opened, the demo made three TTS calls *directly to OpenAI* to synthesize question audio for each turn. These calls bypassed Kong entirely and stand in for the microphone source a production voice agent would have. The demo explicitly suppresses them from OpenTelemetry instrumentation, so they don't appear in your Langfuse traces.

3. **Per-turn parent span.** For each turn, the demo opened a `voice-turn` parent span via the OpenTelemetry SDK before any HTTP call. The span carries `langfuse.session.id`, `langfuse.trace.name`, and `langfuse.trace.tags` attributes. These tell Langfuse to roll the per-turn traces up under one Session.

4. **Three traced hops through Kong.** Each `OpenAI(...).create(...)` call (STT, LLM, TTS) ran while the `voice-turn` span was active. The httpx auto-instrumentation wrapped the OpenAI SDK's underlying client, emitted a child span per call, and injected a real W3C `traceparent` header into every outbound request. Every call carried the `apikey` header, so the Key Auth AI Auth Strategy admitted it before the matching AI Model routed the request.

5. **Kong's per-hop spans nest under the demo's spans.** Kong's OpenTelemetry Policy extracted the `traceparent` and rooted its server, routing, balancer, and `gen_ai.*` generation spans as descendants of the demo's httpx client span. The `gen_ai.*` spans on the LLM hop carry `gen_ai.usage.input_tokens` and `gen_ai.usage.output_tokens`. These are the same numbers the CLI prints from the parsed `completion.usage` field that the OpenAI-format response normalizes for every provider. The STT and TTS hops also print the `X-Kong-Upstream-Latency` header Kong attaches, read the same way as the LLM hop via `with_raw_response`.

6. **Two exporters, one trace.** The demo's SDK and Kong's Policy export to the same Langfuse OTLP endpoint independently. They share `trace_id` because the `traceparent` header propagates the demo's active context to Kong, and Langfuse reassembles the tree by `trace_id`.

7. **Session rollup.** Because every turn's root span carried the same `langfuse.session.id`, Langfuse groups all three turns under a single Session. Session rollup is what makes cross-turn analysis (latency progression, conversation-scoped cost, per-turn error correlation) possible.

8. **Where latency actually came from, and why this is the recipe's whole point.** Look at the per-hop times printed by the demo and the matching durations in Langfuse. STT and the LLM combined typically come in under 1.5 seconds; TTS is the dominant cost, often 3-6 seconds, and it scales linearly with how long the LLM's reply is. [The problem](#the-problem) section frames natural-sounding voice interaction as a sub-800ms budget, and the demo runs nowhere near it. That gap is exactly why per-hop observability matters. Without spans on every hop, you'd see one slow turn and have no idea whether STT mis-transcribed, the LLM was wordy, or TTS choked on a long reply. With them, the answer is one glance at the waterfall: a chatty LLM cascades into a slow TTS, and the production fix (stream TTS, cap response length, switch to a faster TTS model, swap to a realtime API) comes from the data, not guesswork. Observability is what turns "the call sounded broken" into a specific, fixable hop.

### Verify in Langfuse

Open your Langfuse project and navigate to **Sessions** in the left nav. Find the session ID printed at the end of the demo output (search by ID or scan the recent list).

You should see three traces grouped under the session, one per turn. Click into the first trace and confirm the tree:

- **Root**: `voice-turn` (Service: `voice-ai-demo`), with `langfuse.session.id`, `langfuse.trace.name`, and `langfuse.trace.tags` attributes attached.
- **Three children** (one per pipeline hop), each named after the outbound HTTP call: `POST /voice-ai-observability/stt`, `POST /voice-ai-observability/llm`, `POST /voice-ai-observability/tts`.
- **Under each httpx span**: Kong's server span plus its routing and balancer descendants, and a `gen_ai.*` generation span (`generate_content whisper-1`, `chat <chat-model>`, `generate_content tts-1`).

Per-hop timings in Langfuse should be within a few tens of milliseconds of the times printed by the demo CLI. Any larger discrepancy points at network overhead between the demo, Kong, and the upstream provider.

### Explore in {{site.konnect_short_name}}

Open [{{site.konnect_short_name}}](https://cloud.konghq.com/) and find the {{site.ai_gateway}} named `voice-ai-observability-recipe`. The recipe created two AI Model Providers holding your chosen providers' credentials, three AI Models (`voice-ai-observability-stt`, `voice-ai-observability-llm`, `voice-ai-observability-tts`), a Key Auth AI Auth Strategy, a global OpenTelemetry AI Policy, and a `voice-agent` AI Consumer with a demo API key credential, all scoped to this recipe by the kongctl namespace applied above.

For platform-wide traffic analysis across every {{site.ai_gateway}}, open the **Observability** L1 menu in {{site.konnect_short_name}}.

## Variations and next steps

**Swap the OTel backend.** Replace the Langfuse endpoint with any OTLP-compatible backend. Change `DECK_LANGFUSE_OTLP_ENDPOINT` and `DECK_LANGFUSE_AUTH_HEADER` (and update the demo's exporter the same way) to point at Jaeger, Grafana Tempo, Honeycomb, Datadog, or Dynatrace. Two things to know before you migrate:

- **Portable across backends.** Kong's per-hop spans, the demo's `voice-turn` span tree, and the `gen_ai.*` semantic attributes (token counts, model names, provider) are all standard OpenTelemetry GenAI semantic conventions. They render correctly in any backend that supports OTLP ingestion and the GenAI semconv registry.
- **Langfuse-specific and won't transfer.** The `langfuse.session.id`, `langfuse.trace.name`, and `langfuse.trace.tags` attributes are how Langfuse drives its Sessions UI, conversation rollups, and LLM-aware cost panels. On a generic backend `langfuse.session.id` is just a string attribute. To recreate Sessions-style grouping, you'd filter traces by that attribute, or restructure to use the backend's native session/grouping concept (for example, Datadog's `session.id` or Honeycomb's parent-id chains).

**Propagate session attributes onto every span.** Kong's child spans share the `trace_id` of the demo's `voice-turn` root, but they don't carry the `langfuse.session.id` attribute themselves. For trace-level Session grouping in Langfuse this is sufficient: Langfuse only needs the attribute on the root. To filter or aggregate *individual* observations by session (for example, a per-span cost panel grouped by session), use OpenTelemetry's [`BaggageSpanProcessor`](https://opentelemetry.io/docs/languages/python/) on the demo side to copy `session.id` into baggage and propagate it on outbound HTTP.

**Swap Key Auth for SSO.** Replace the Key Auth AI Auth Strategy with the [OpenID Connect](/ai-gateway/openid-connect/) AI Auth Strategy when humans run voice agents on managed devices and you need per-user identity, JWT claims, or short-lived tokens. The [Claude Code SSO recipe](/cookbooks/claude-code-sso/) is an end-to-end example with Okta. Drop the `voice-agent` AI Consumer, point Kong at your IdP's issuer URL, and let a claims mapping put JWT subjects onto Kong AI Consumers automatically.

**Add per-hop rate limiting.** Attach the [AI Rate Limiting Advanced](/ai-gateway/policies/ai-rate-limiting-advanced/) Policy to individual AI Models via their `policies` list to enforce separate token budgets for STT, LLM, and TTS. Separate budgets prevent a runaway LLM prompt from consuming the entire pipeline's token quota.

**Replace STT or TTS providers.** Update the STT or TTS AI Model's target to use a different provider without changing the LLM configuration or the observability pipeline. Switch from OpenAI Whisper to a self-hosted speech model by adding a new AI Model Provider and pointing the STT target's `provider` field at it. The `gen_ai.*` span attributes and Prometheus labels update automatically to reflect the new provider.

**Add Prometheus metrics dashboards.** Kong emits AI-specific Prometheus metrics (`ai_llm_requests_total`, `ai_llm_cost_total`, `ai_llm_tokens_total`, `ai_llm_provider_latency`) with a `request_mode` label that distinguishes `oneshot`, `stream`, and `realtime` traffic. Import the [{{site.ai_gateway_name}} Grafana dashboard](https://grafana.com/grafana/dashboards/21162-kong-cx-ai/) for pre-built cost, latency, and throughput panels across all three pipeline hops.

**Explore realtime speech-to-speech.** For latency-sensitive applications where per-hop observability is less critical, an AI Model can declare `capabilities: [realtime]` for OpenAI Realtime and Gemini Live WebSocket connections. Realtime mode collapses the three-hop pipeline into a single persistent WebSocket, trading the per-hop waterfall view for significantly lower turn latency. Kong tracks realtime traffic with the `request_mode=realtime` Prometheus label.

## Cleanup

The recipe's kongctl namespace scoped all resources, so this teardown removes only this recipe's configuration. Tear down the local data plane and delete the {{site.ai_gateway}} from {{site.konnect_short_name}}:

```bash
export KONNECT_CONTROL_PLANE_NAME='voice-ai-observability-recipe' && curl -Ls https://get.konghq.com/ai | bash -s -- -d -k $KONNECT_TOKEN
```
