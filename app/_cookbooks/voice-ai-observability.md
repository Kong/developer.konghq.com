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
works_on:
  - konnect
min_version:
  ai-gateway: '2.0'
categories:
  - observability
  - llm
featured: true
popular: false
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

        1. Set the recipe-scoped {{site.ai_gateway}} name and run the quickstart script. The two `-e` flags start the data plane with tracing turned on. Kong records spans for the OpenTelemetry Policy only when `KONG_TRACING_INSTRUMENTATIONS` is set (default `off`). `KONG_TRACING_SAMPLING_RATE=1.0` samples every request (default `0.01`):

           ```bash
           export KONNECT_CONTROL_PLANE_NAME='voice-ai-observability-recipe'
           curl -Ls https://get.konghq.com/ai | \
             bash -s -- -k $KONNECT_TOKEN \
               -e KONG_TRACING_INSTRUMENTATIONS=all \
               -e KONG_TRACING_SAMPLING_RATE=1.0
           ```

           This provisions an {{site.ai_gateway}} named `voice-ai-observability-recipe`, a local data plane connected to it, and prints `export` lines for the rest of the session vars, including `AI_GATEWAY_ID`. Paste those into your shell when prompted.
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
        The STT and TTS hops always use OpenAI (`whisper-1` and `tts-1`), so you need an OpenAI key for every provider tab.

        1. [Create an OpenAI account](https://auth.openai.com/create-account).
        1. [Get an API key](https://platform.openai.com/api-keys).
        1. Export the API key:

           ```sh
           export OPENAI_TOKEN='Bearer sk-YOUR-KEY'
           ```

        Pick the provider for the LLM hop and export its credentials. The provider's tab in [Apply the Kong configuration](#apply-the-kong-configuration) reads these variables.

        {% navtabs "Providers" %}
        {% navtab "OpenAI" %}
        The LLM hop reuses `OPENAI_TOKEN`. You don't need other credentials.
        {% endnavtab %}
        {% navtab "Anthropic" %}
        1. [Create an Anthropic account](https://console.anthropic.com/).
        1. [Get an API key](https://console.anthropic.com/settings/keys).
        1. Export the API key and the [Messages API version](https://docs.claude.com/en/api/versioning) that Kong sends upstream on each request:

           ```sh
           export ANTHROPIC_TOKEN='YOUR-ANTHROPIC-KEY'
           export ANTHROPIC_VERSION='2023-06-01'
           ```
        {% endnavtab %}
        {% navtab "AWS Bedrock" %}
        1. Get an AWS account with [Bedrock model access](https://docs.aws.amazon.com/bedrock/latest/userguide/model-access.html) enabled.
        1. Export your AWS credentials and region:

           ```sh
           export AWS_ACCESS_KEY_ID='your-access-key'
           export AWS_SECRET_ACCESS_KEY='your-secret-key'
           export AWS_REGION='us-east-1'
           ```
        {% endnavtab %}
        {% navtab "Azure OpenAI" %}
        Azure binds each deployment to one model, and the deployment ID selects the upstream model ([Azure OpenAI REST API reference](https://learn.microsoft.com/en-us/azure/ai-services/openai/reference)).

        1. [Create an Azure OpenAI resource](https://portal.azure.com/#create/Microsoft.CognitiveServicesOpenAI).
        1. Deploy a chat model in the resource, for example `gpt-4o`.
        1. Export your credentials. Use the current API version from the Azure OpenAI REST API reference:

           ```sh
           export AZURE_API_KEY='your-azure-api-key'
           export AZURE_INSTANCE='your-instance-name'
           export AZURE_DEPLOYMENT_ID='your-deployment-id'
           export AZURE_API_VERSION='YOUR-API-VERSION'
           ```
        {% endnavtab %}
        {% navtab "Google Gemini" %}
        1. [Create a Google Cloud project](https://console.cloud.google.com/) with Vertex AI enabled.
        1. [Create a service account key](https://cloud.google.com/iam/docs/keys-create-delete) for a service account that can call Vertex AI.
        1. Export the key and your project details:

           ```sh
           export GEMINI_SERVICE_ACCOUNT_JSON="$(cat path/to/service-account-key.json)"
           export GCP_API_ENDPOINT='your-api-endpoint'
           export GCP_PROJECT_ID='your-project-id'
           export GCP_LOCATION_ID='us-central1'
           ```
        {% endnavtab %}
        {% navtab "Mistral" %}
        1. [Create a Mistral account](https://console.mistral.ai/).
        1. [Get an API key](https://console.mistral.ai/api-keys/).
        1. Export the API key:

           ```sh
           export MISTRAL_TOKEN='Bearer your-mistral-key'
           ```
        {% endnavtab %}
        {% endnavtabs %}
    - title: Langfuse
      content: |
        [Langfuse](https://langfuse.com) receives the traces over OTLP/HTTP and groups the turns of a conversation into a Session. Langfuse authenticates OTLP requests with HTTP Basic Auth: the username is the project's public key (`pk-lf-...`) and the password is its secret key (`sk-lf-...`).

        1. Sign up for [Langfuse Cloud](https://cloud.langfuse.com), or [self-host Langfuse](https://langfuse.com/self-hosting) v3.22.0 or later. Keys work only in the data region where you created them.
        1. Create a project and copy its public key and secret key from the project settings.
        1. Export the keys, the OTLP traces endpoint of your data region, and the Basic Auth header. The following example uses the EU region. Get the endpoint for the other regions from the [Langfuse OpenTelemetry documentation](https://langfuse.com/integrations/native/opentelemetry). For a self-hosted Langfuse on the same machine, use `http://host.docker.internal:3000/api/public/otel/v1/traces`, so that the data plane container can reach it:

           ```bash
           export LANGFUSE_PUBLIC_KEY='pk-lf-YOUR-PUBLIC-KEY'
           export LANGFUSE_SECRET_KEY='sk-lf-YOUR-SECRET-KEY'
           export LANGFUSE_OTLP_ENDPOINT='https://cloud.langfuse.com/api/public/otel/v1/traces'
           export LANGFUSE_AUTH_HEADER="Basic $(printf '%s:%s' "$LANGFUSE_PUBLIC_KEY" "$LANGFUSE_SECRET_KEY" | base64 | tr -d '\n')"
           ```

           GNU `base64` wraps long output across lines. The `tr -d '\n'` keeps the header on one line.
    - title: Python 3.11+
      icon_url: /assets/icons/python.svg
      content: |
        The demo script requires Python 3.11 or later. Set up an isolated environment:

        ```bash
        python3 -m venv .venv
        source .venv/bin/activate
        pip install 'openai>=1.0.0' 'opentelemetry-api>=1.27.0' 'opentelemetry-sdk>=1.27.0' 'opentelemetry-exporter-otlp-proto-http>=1.27.0' 'opentelemetry-instrumentation-httpx>=0.48b0'
        ```
overview: |
  Route each hop of a cascading voice pipeline (speech-to-text, LLM, text-to-speech) through {{site.ai_gateway_name}}, and see each conversation in Langfuse as a set of turns with a span for each hop. You'll set up:

  * Three AI Models, one for each hop, behind one AI Consumer API key
  * Provider credentials that stay in {{site.ai_gateway}} instead of in the voice agent
  * OTLP export of each hop's spans into the voice agent's trace, grouped into one Langfuse Session for each conversation
---

## What this cookbook solves

Most voice agents call the speech-to-text (STT), LLM, and text-to-speech (TTS) providers directly, each with its own SDK and dashboard, which causes the following problems:

{% table %}
columns:
  - title: Problem
    key: problem
  - title: Solution
    key: solution
rows:
  - problem: "A slow or broken turn can come from any of three hops, and each provider logs the call in its own place with no shared ID."
    solution: "Each hop is an AI Model. The global OpenTelemetry Policy exports a span for each hop into the voice agent's trace for the turn."
  - problem: "Users experience a conversation, but request monitoring shows single calls with no link between the turns."
    solution: "The voice agent tags each turn with one `langfuse.session.id`, and Langfuse groups the turns into one Session."
  - problem: "Latency adds up across the hops, and monitoring each hop alone doesn't show which hop uses the turn's latency budget."
    solution: "Langfuse shows each turn as a tree of spans, with the duration of the STT, LLM, and TTS hops."
  - problem: "The voice agent holds credentials for every provider in the pipeline."
    solution: "Two AI Model Providers keep the credentials in Kong. The agent holds one AI Consumer key, and the Key Auth AI Auth Strategy rejects unknown keys with `401` before any provider call."
  - problem: "Switching the LLM provider means changing the agent's client code."
    solution: "The LLM AI Model accepts OpenAI-format requests from any provider tab. Kong translates each request to the provider's native format and the response back."
{% endtable %}

## Try it out

Apply the configuration, run a demo script that sends an invalid key and then three voice turns through the pipeline, and open the conversation in Langfuse.

### Apply the Kong configuration

The configuration creates two AI Model Providers (OpenAI for STT and TTS, and your provider for the LLM hop), a Key Auth AI Auth Strategy, an AI Consumer with a demo API key, three AI Models (STT, LLM, and TTS), and a global OpenTelemetry Policy that exports traces to Langfuse. A kongctl namespace scopes every resource, so you can remove this configuration without affecting anything else on the same {{site.ai_gateway}}. See the [kongctl documentation](/kongctl/) for more on namespaces.

Adopt the quickstart {{site.ai_gateway}} into a kongctl namespace so that kongctl can manage it. Adoption adds the `KONGCTL-namespace` label to the {{site.ai_gateway}}:

```bash
kongctl adopt ai-gateway "${KONNECT_CONTROL_PLANE_NAME}" \
  --namespace "${KONNECT_CONTROL_PLANE_NAME}" \
  --pat "${KONNECT_TOKEN}"
```

Export the demo AI Consumer's API key. The credential's `api_key` field is write-only, so its value must come from an environment variable, even for a fixed demo key:

```bash
export CONSUMER_API_KEY='voice-demo-key'
```

Select your provider. Each tab exports `CHAT_MODEL`, the upstream model for the LLM hop, then applies the configuration. Provider credentials and the Langfuse values come from the prerequisites.

{% navtabs "Providers" %}
{% navtab "OpenAI" %}

Export the model env var:

```bash
export CHAT_MODEL='gpt-4o'
```

Apply the Kong configuration:

```bash
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
        value: !secret {source: !env 'OPENAI_TOKEN'}
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
        value: !secret {source: !env 'OPENAI_TOKEN'}
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
    traces_endpoint: !env 'LANGFUSE_OTLP_ENDPOINT'
    headers:
      Authorization: !env 'LANGFUSE_AUTH_HEADER'
      x-langfuse-ingestion-version: '4'
    sampling_rate: 1
    propagation:
      default_format: w3c
      extract:
      - w3c
      inject:
      - w3c
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
      model:
        body_param: model
        values:
        - whisper-1
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
      model:
        body_param: model
        values:
        - !env 'CHAT_MODEL'
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
      model:
        body_param: model
        values:
        - tts-1
  targets:
  - name: tts-1
    provider: voice-ai-observability-openai-provider
    config:
      type: openai
EOF

kongctl apply -f kong-recipe.yaml -o text --auto-approve --pat "${KONNECT_TOKEN}"

rm -f kong-recipe.yaml
```
{: data-test-step="block" .collapsible }

{% endnavtab %}
{% navtab "Anthropic" %}

Export the model env var:

```bash
export CHAT_MODEL='claude-sonnet-4-5-20250929'
```

Apply the Kong configuration:

```bash
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
        value: !secret {source: !env 'OPENAI_TOKEN'}
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
        value: !secret {source: !env 'ANTHROPIC_TOKEN'}
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
    traces_endpoint: !env 'LANGFUSE_OTLP_ENDPOINT'
    headers:
      Authorization: !env 'LANGFUSE_AUTH_HEADER'
      x-langfuse-ingestion-version: '4'
    sampling_rate: 1
    propagation:
      default_format: w3c
      extract:
      - w3c
      inject:
      - w3c
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
      model:
        body_param: model
        values:
        - whisper-1
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
      model:
        body_param: model
        values:
        - !env 'CHAT_MODEL'
  targets:
  - name: !env 'CHAT_MODEL'
    provider: voice-ai-observability-llm-provider
    config:
      version: !env 'ANTHROPIC_VERSION'
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
      model:
        body_param: model
        values:
        - tts-1
  targets:
  - name: tts-1
    provider: voice-ai-observability-openai-provider
    config:
      type: openai
EOF

kongctl apply -f kong-recipe.yaml -o text --auto-approve --pat "${KONNECT_TOKEN}"

rm -f kong-recipe.yaml
```
{: data-test-step="block" .collapsible }

{% endnavtab %}
{% navtab "AWS Bedrock" %}

Export the model env var:

```bash
export CHAT_MODEL='amazon.nova-pro-v1:0'
```

Apply the Kong configuration:

```bash
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
        value: !secret {source: !env 'OPENAI_TOKEN'}
- ref: voice-ai-observability-llm-provider
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: voice-ai-observability-llm-provider
  display_name: voice-ai-observability (LLM)
  type: bedrock
  config:
    auth:
      type: aws
      access_key_id: !env 'AWS_ACCESS_KEY_ID'
      secret_access_key: !secret {source: !env 'AWS_SECRET_ACCESS_KEY'}
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
    traces_endpoint: !env 'LANGFUSE_OTLP_ENDPOINT'
    headers:
      Authorization: !env 'LANGFUSE_AUTH_HEADER'
      x-langfuse-ingestion-version: '4'
    sampling_rate: 1
    propagation:
      default_format: w3c
      extract:
      - w3c
      inject:
      - w3c
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
      model:
        body_param: model
        values:
        - whisper-1
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
      model:
        body_param: model
        values:
        - !env 'CHAT_MODEL'
  targets:
  - name: !env 'CHAT_MODEL'
    provider: voice-ai-observability-llm-provider
    config:
      region: !env 'AWS_REGION'
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
      model:
        body_param: model
        values:
        - tts-1
  targets:
  - name: tts-1
    provider: voice-ai-observability-openai-provider
    config:
      type: openai
EOF

kongctl apply -f kong-recipe.yaml -o text --auto-approve --pat "${KONNECT_TOKEN}"

rm -f kong-recipe.yaml
```
{: data-test-step="block" .collapsible }

{% endnavtab %}
{% navtab "Azure OpenAI" %}

Kong records this model name in the `X-Kong-LLM-Model` header, but the deployment ID from the AI Credentials prerequisite selects the upstream model. Set the name to the model in your deployment:

```bash
export CHAT_MODEL='gpt-4o'
```

Apply the Kong configuration:

```bash
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
        value: !secret {source: !env 'OPENAI_TOKEN'}
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
        value: !secret {source: !env 'AZURE_API_KEY'}
    service: azure-openai
    instance: !env 'AZURE_INSTANCE'
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
    traces_endpoint: !env 'LANGFUSE_OTLP_ENDPOINT'
    headers:
      Authorization: !env 'LANGFUSE_AUTH_HEADER'
      x-langfuse-ingestion-version: '4'
    sampling_rate: 1
    propagation:
      default_format: w3c
      extract:
      - w3c
      inject:
      - w3c
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
      model:
        body_param: model
        values:
        - whisper-1
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
      model:
        body_param: model
        values:
        - !env 'CHAT_MODEL'
  targets:
  - name: !env 'CHAT_MODEL'
    provider: voice-ai-observability-llm-provider
    config:
      api_version: !env 'AZURE_API_VERSION'
      deployment_id: !env 'AZURE_DEPLOYMENT_ID'
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
      model:
        body_param: model
        values:
        - tts-1
  targets:
  - name: tts-1
    provider: voice-ai-observability-openai-provider
    config:
      type: openai
EOF

kongctl apply -f kong-recipe.yaml -o text --auto-approve --pat "${KONNECT_TOKEN}"

rm -f kong-recipe.yaml
```
{: data-test-step="block" .collapsible }

{% endnavtab %}
{% navtab "Google Gemini" %}

Export the model env var:

```bash
export CHAT_MODEL='gemini-2.0-flash'
```

Apply the Kong configuration:

```bash
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
        value: !secret {source: !env 'OPENAI_TOKEN'}
- ref: voice-ai-observability-llm-provider
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: voice-ai-observability-llm-provider
  display_name: voice-ai-observability (LLM)
  type: gemini
  config:
    auth:
      type: gcp
      use_gcp_service_account: true
      service_account_json: !secret {source: !env 'GEMINI_SERVICE_ACCOUNT_JSON'}
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
    traces_endpoint: !env 'LANGFUSE_OTLP_ENDPOINT'
    headers:
      Authorization: !env 'LANGFUSE_AUTH_HEADER'
      x-langfuse-ingestion-version: '4'
    sampling_rate: 1
    propagation:
      default_format: w3c
      extract:
      - w3c
      inject:
      - w3c
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
      model:
        body_param: model
        values:
        - whisper-1
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
      model:
        body_param: model
        values:
        - !env 'CHAT_MODEL'
  targets:
  - name: !env 'CHAT_MODEL'
    provider: voice-ai-observability-llm-provider
    config:
      gcp_environment:
        api_endpoint: !env 'GCP_API_ENDPOINT'
        project_id: !env 'GCP_PROJECT_ID'
        location_id: !env 'GCP_LOCATION_ID'
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
      model:
        body_param: model
        values:
        - tts-1
  targets:
  - name: tts-1
    provider: voice-ai-observability-openai-provider
    config:
      type: openai
EOF

kongctl apply -f kong-recipe.yaml -o text --auto-approve --pat "${KONNECT_TOKEN}"

rm -f kong-recipe.yaml
```
{: data-test-step="block" .collapsible }

{% endnavtab %}
{% navtab "Mistral" %}

Export the model env var:

```bash
export CHAT_MODEL='mistral-large-latest'
```

Apply the Kong configuration:

```bash
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
        value: !secret {source: !env 'OPENAI_TOKEN'}
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
        value: !secret {source: !env 'MISTRAL_TOKEN'}
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
    traces_endpoint: !env 'LANGFUSE_OTLP_ENDPOINT'
    headers:
      Authorization: !env 'LANGFUSE_AUTH_HEADER'
      x-langfuse-ingestion-version: '4'
    sampling_rate: 1
    propagation:
      default_format: w3c
      extract:
      - w3c
      inject:
      - w3c
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
      model:
        body_param: model
        values:
        - whisper-1
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
      model:
        body_param: model
        values:
        - !env 'CHAT_MODEL'
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
      model:
        body_param: model
        values:
        - tts-1
  targets:
  - name: tts-1
    provider: voice-ai-observability-openai-provider
    config:
      type: openai
EOF

kongctl apply -f kong-recipe.yaml -o text --auto-approve --pat "${KONNECT_TOKEN}"

rm -f kong-recipe.yaml
```
{: data-test-step="block" .collapsible }

{% endnavtab %}
{% endnavtabs %}

### Run the demo

The script first sends one request with an invalid API key. It then synthesizes the audio of three questions directly with OpenAI, without Kong and without tracing, to stand in for a microphone. For each question, it opens a `voice-turn` span and runs the three hops through Kong. In the output, look for the `401` for the invalid key, the timing of each hop, and the trace ID and Session ID to open in Langfuse.

{:.info}
> The demo passes the API key in `default_headers` because the OpenAI SDK always sends `api_key` as an `Authorization: Bearer` header. To let clients use `api_key` directly, add a global [Pre-Function](/ai-gateway/policies/pre-function/) Policy (`global: true`) that copies the Bearer token to the `apikey` header. A global Pre-Function Policy runs before authentication, while one attached to the AI Model runs after it.

Create the demo script:

```bash
cat <<'EOF' > demo.py
"""Voice AI pipeline observability demo for Kong AI Gateway.

Shows four things:
  1. A request with an invalid apikey gets 401 from Kong before any provider call.
  2. Each conversational turn runs three hops through Kong: speech-to-text (STT),
     the LLM, and text-to-speech (TTS), each on its own AI Model.
  3. Each turn opens a `voice-turn` parent span. Each hop sends a W3C traceparent
     header from the current span, so Kong's spans join the turn's trace.
  4. All turns share one langfuse.session.id, so Langfuse groups them into one Session.

The question audio for each turn is synthesized first, directly with OpenAI and
without tracing. It stands in for a microphone.

Expected output: an [AUTH] 401 line, then for each of three turns an [STT], [LLM],
and [TTS] line with timings, and the turn's trace ID. The last line prints the
Session ID to open in Langfuse.

Run: python demo.py. It needs OPENAI_TOKEN, LANGFUSE_OTLP_ENDPOINT, and
LANGFUSE_AUTH_HEADER from the prerequisites. Set PROXY_URL if the data plane is not
at http://localhost:8000, CHAT_MODEL to match the applied model, and
CONSUMER_API_KEY if you changed the demo key.
"""

import os
import sys
import tempfile
import time
import uuid
from pathlib import Path

from openai import APIStatusError, OpenAI
from opentelemetry import context as otel_context
from opentelemetry import trace
from opentelemetry.propagate import inject
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

LANGFUSE_OTLP_ENDPOINT = os.environ["LANGFUSE_OTLP_ENDPOINT"]
LANGFUSE_AUTH_HEADER = os.environ["LANGFUSE_AUTH_HEADER"]

# OPENAI_TOKEN carries the "Bearer " prefix Kong needs; strip it for the
# direct OpenAI client used by the setup phase.
RAW_OPENAI_KEY = os.environ["OPENAI_TOKEN"].removeprefix("Bearer ").strip()


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

def trace_headers():
    """Return a W3C traceparent header for the current span.

    The OpenAI SDK's HTTP client isn't always the one that the httpx
    instrumentation patches, so each Kong call sends the header explicitly.
    """
    headers = {}
    inject(headers)
    return headers


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
                model="whisper-1", file=f, extra_headers=trace_headers()
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
        model=CHAT_MODEL, messages=messages, extra_headers=trace_headers()
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
        model="tts-1", voice="alloy", input=text, extra_headers=trace_headers()
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

Example output with the OpenAI tab's model:

```text
Voice AI Pipeline Observability Demo
============================================================
Kong Proxy:  http://localhost:8000
Chat Model:  gpt-4o
Session ID:  voice-demo-7f3a2c1b9e8d

Checking key-auth boundary...
  Attempting request with apikey='wrong-key'...
  [AUTH] expected reject -> 401 Error code: 401 - Unauthorized

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
         Model: openai/gpt-4o  Tokens: 58 in / 44 out  Upstream: 821ms (0.842s wall)

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
         Model: openai/gpt-4o  Tokens: 88 in / 16 out  Upstream: 318ms (0.331s wall)

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
         Model: openai/gpt-4o  Tokens: 116 in / 19 out  Upstream: 401ms (0.418s wall)

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

### Open the conversation in Langfuse

Open your Langfuse project, click **Sessions**, and find the Session ID that the demo printed. The Session holds three traces, one for each turn. Open a trace to see its spans: the demo's `voice-turn` root span, one HTTP client span for each hop, and Kong's spans for that hop under each client span. This cookbook hasn't confirmed the nesting of Kong's spans against a live {{site.ai_gateway}}. If Kong's spans show up as separate traces, check the `propagation` settings in [OpenTelemetry Policy](#opentelemetry-policy).

### Check the results

The demo output and Langfuse confirm the following:

{% table %}
columns:
  - title: Behavior
    key: behavior
  - title: Evidence
    key: evidence
rows:
  - behavior: "Authentication before any provider call"
    evidence: "The invalid key gets `401`. Kong rejected it before the LLM AI Model contacted the provider."
  - behavior: "Three hops through Kong"
    evidence: "Each turn prints an `[STT]`, `[LLM]`, and `[TTS]` line with the upstream latency from the `X-Kong-Upstream-Latency` header."
  - behavior: "One trace for each turn"
    evidence: "Each Langfuse trace has the `voice-turn` span as its root and the spans of all three hops in its tree, with their durations."
  - behavior: "One Session for the conversation"
    evidence: "The Langfuse Session with the printed ID holds the three turns."
  - behavior: "Provider credentials stay in Kong"
    evidence: "The demo sends only the AI Consumer key to Kong. The AI Model Providers add the provider credentials to each upstream request."
{% endtable %}

To review the created entities, and per-consumer usage, open the `voice-ai-observability-recipe` {{site.ai_gateway}} in [{{site.konnect_short_name}}](https://cloud.konghq.com/). For traffic across all your {{site.ai_gateway}}s, use the **Observability** menu.

## How it works

For each turn, the voice agent calls three AI Models in sequence through Kong. Kong authenticates each call, adds the provider credentials, and exports its spans to Langfuse into the trace that the agent started.

<!-- vale off -->
{% mermaid %}
sequenceDiagram
    participant V as Voice agent
    participant K as Kong AI Gateway
    participant P as Providers
    participant Lf as Langfuse

    V->>K: POST /voice-ai-observability/stt (apikey, traceparent, audio)
    activate K
    K->>K: Key Auth AI Auth Strategy validates apikey (else 401)
    K->>P: Transcription request to OpenAI whisper-1
    activate P
    P-->>K: Transcript
    deactivate P
    K-->>V: Transcript
    deactivate K
    V->>K: POST /voice-ai-observability/llm (apikey, traceparent, messages)
    activate K
    K->>P: Chat request in the LLM provider's native format
    activate P
    P-->>K: Completion
    deactivate P
    K-->>V: OpenAI-format response
    deactivate K
    V->>K: POST /voice-ai-observability/tts (apikey, traceparent, text)
    activate K
    K->>P: Speech request to OpenAI tts-1
    activate P
    P-->>K: Audio
    deactivate P
    K-->>V: Audio
    deactivate K
    K->>Lf: OpenTelemetry Policy exports each hop's spans
    V->>Lf: Demo exports the voice-turn span
{% endmermaid %}
<!-- vale on -->

The demo opens a `voice-turn` span before the first hop and sets `langfuse.session.id` on it. Each hop sends a W3C `traceparent` header from the current span (the demo injects it with OpenTelemetry's propagator, because the OpenAI SDK's HTTP client isn't always the one the httpx instrumentation patches), so Kong's spans join the same trace. The demo and Kong export their spans separately, and Langfuse joins them by trace ID.

### Key Auth AI Auth Strategy and AI Consumer

Authentication is an AI Auth Strategy, not an AI Policy. The Key Auth AI Auth Strategy reads the `apikey` header and matches the key against the AI Consumer credentials. On a match, Kong attaches the AI Consumer to the request. The AI Consumer is the identity that rate limits, ACLs, and analytics use. All three AI Models reference this AI Auth Strategy in `access.auth_strategies`, so one key works for every hop.

The following settings configure the Key Auth AI Auth Strategy and the AI Consumer:

{% table %}
columns:
  - title: Setting
    key: setting
  - title: Purpose
    key: purpose
rows:
  - setting: "`key_names: [apikey]`"
    purpose: "Kong reads the key from the `apikey` header. Key Auth compares the whole header value, so it can't read a key from an `Authorization: Bearer` header. The note in [Run the demo](#run-the-demo) shows the workaround."
  - setting: "`hide_credentials: true`"
    purpose: "Kong removes the key before it forwards the request. The providers never see the AI Consumer key."
  - setting: "`name: voice-ai-observability-consumer` (AI Consumer)"
    purpose: "The identity of the voice agent. For several agents or tenants, create one AI Consumer for each."
  - setting: "`credentials[].api_key`"
    purpose: "The AI Consumer's key. The field is write-only, so it takes a `!secret` reference to `CONSUMER_API_KEY`, even for a demo value."
{% endtable %}

Kong adds `X-Consumer-Username` and related headers to the upstream request, not to the response. Per-consumer usage appears in {{site.konnect_short_name}} analytics.

### AI Model Providers and AI Models

The STT and TTS AI Models use the OpenAI AI Model Provider. The LLM AI Model uses a second AI Model Provider for the provider you selected. The LLM AI Model Provider is a separate entity even on the OpenAI tab, so a provider switch never touches the STT and TTS hops. Each AI Model has its own path and one capability.

The following settings configure the AI Model Providers and the AI Models:

{% table %}
columns:
  - title: Setting
    key: setting
  - title: Purpose
    key: purpose
rows:
  - setting: "`config.auth` (AI Model Providers)"
    purpose: "The provider credentials. Kong adds them to each upstream request. The fields of the LLM AI Model Provider depend on the provider tab."
  - setting: "`formats: [{type: openai}]`"
    purpose: "All three AI Models accept OpenAI-format requests. On the LLM AI Model, Kong translates each request to the provider's native format and the response back to OpenAI format."
  - setting: "`capabilities`"
    purpose: "`audio/transcription` on the STT AI Model, `generate` on the LLM AI Model, and `audio/speech` on the TTS AI Model."
  - setting: "`config.route.model`"
    purpose: "Each AI Model answers to one value in the request's `model` field (`body_param: model`): `whisper-1` for speech-to-text, the `CHAT_MODEL` value for the LLM, and `tts-1` for text-to-speech. These are the values the demo sends. Without a selector, an AI Model accepts only its own name as `model`."
  - setting: "`targets[].name`"
    purpose: "`whisper-1` for STT and `tts-1` for TTS. The LLM model comes from `CHAT_MODEL`. Change it and re-apply to swap models without changing the agent."
  - setting: "`targets[].config`"
    purpose: "The provider `type` and provider-specific target fields, for example Bedrock's `region` or Azure's `deployment_id` and `api_version`."
  - setting: "`config.max_request_body_size`"
    purpose: "25 MB on the STT AI Model for audio uploads, 8 MB on the LLM AI Model, and 1 MB on the TTS AI Model, which receives text."
  - setting: "`config.response_streaming`"
    purpose: "`deny` on the STT AI Model, so clients can't set `stream=true`. `allow` on the LLM and TTS AI Models, so clients can request streamed responses. The demo doesn't stream."
  - setting: "`config.logging.payloads: true`"
    purpose: "Kong logs request and response payloads. The default is `false`."
  - setting: "`config.route.protocols: [http, https]`"
    purpose: "Accepts HTTP, so you can call the local data plane at `http://localhost:8000`."
  - setting: "`config.route.strip_path: true`"
    purpose: "Kong removes the AI Model's path before it forwards the request."
{% endtable %}

### OpenTelemetry Policy

The [OpenTelemetry](/ai-gateway/policies/opentelemetry/) Policy has `global: true`, so it applies to all three AI Models without a reference in their `policies`. It sends the spans from the data plane to Langfuse. Kong adds `gen_ai.*` attributes to the spans, for example the provider, the model, and the token counts. See the [Gen AI OpenTelemetry spans attributes reference](/ai-gateway/llm-open-telemetry/) for the full list.

The following settings configure the OpenTelemetry Policy:

{% table %}
columns:
  - title: Setting
    key: setting
  - title: Purpose
    key: purpose
rows:
  - setting: "`global: true`"
    purpose: "Applies the policy to every AI Model on the {{site.ai_gateway}}."
  - setting: "`traces_endpoint`"
    purpose: "The Langfuse OTLP/HTTP traces URL, from `LANGFUSE_OTLP_ENDPOINT`."
  - setting: "`headers.Authorization`"
    purpose: "The Basic Auth header, from `LANGFUSE_AUTH_HEADER`. Policy configuration doesn't accept `!secret`, so the value uses `!env`."
  - setting: "`headers.x-langfuse-ingestion-version: \"4\"`"
    purpose: "Langfuse shows new spans in real time. Without this header, Langfuse can show them up to 10 minutes later."
  - setting: "`sampling_rate: 1`"
    purpose: "Samples every request. This value overrides the data plane's sampling rate. Lower it for production traffic."
  - setting: "`propagation`"
    purpose: "Kong reads the W3C `traceparent` header from the request (`extract`) and writes it to the upstream request (`inject`), so its spans join the voice agent's trace."
{% endtable %}

{:.info}
> **Production credentials:** This cookbook stores the AI Consumer's API key, the provider credentials, and the Langfuse keys in environment variables for simplicity. In production, use [AI Vaults](/ai-gateway/entities/ai-vault/) to reference them from a secret manager, for example AWS Secrets Manager, HashiCorp Vault, GCP Secret Manager, or Azure Key Vault. Span attributes such as `gen_ai.input.messages` can carry prompts and responses, so review who can read the Langfuse project.

### Demo span attributes

The Session grouping comes from the voice agent, not from Kong. Langfuse reads trace attributes from any span in the trace.

The demo sets the following attributes on each `voice-turn` span:

{% table %}
columns:
  - title: Setting
    key: setting
  - title: Purpose
    key: purpose
rows:
  - setting: "`langfuse.session.id`"
    purpose: "Groups the turns of one conversation into one Langfuse Session."
  - setting: "`langfuse.trace.name`"
    purpose: "Names each trace `voice-turn-<N>`."
  - setting: "`langfuse.trace.tags`"
    purpose: "Tags each trace with `voice-ai` and `cascading-pipeline`."
{% endtable %}

### Response headers

Kong adds the following response headers, which the demo reads:

{% table %}
columns:
  - title: Header
    key: header
  - title: Description
    key: description
rows:
  - header: "`X-Kong-LLM-Model`"
    description: "The upstream model that served the request, with the provider name as a prefix, for example `openai/gpt-4o`. The demo reads it on the LLM hop."
  - header: "`X-Kong-Upstream-Latency`"
    description: "Time in milliseconds that Kong waited for the provider to respond."
{% endtable %}

## Variations and next steps

You can change or extend this configuration in the following ways:

{% table %}
columns:
  - title: Variation
    key: variation
  - title: How
    key: how
rows:
  - variation: "Switch the LLM provider"
    how: "Select a different provider tab in [Apply the Kong configuration](#apply-the-kong-configuration) and re-apply. The STT and TTS AI Models and the agent's code don't change."
  - variation: "Replace the STT or TTS provider"
    how: "Add an AI Model Provider for the new service and point the STT or TTS AI Model's target at it. See the [AI Model reference](/ai-gateway/entities/ai-model/) for the capabilities."
  - variation: "Send traces to another backend"
    how: "Change `LANGFUSE_OTLP_ENDPOINT` and `LANGFUSE_AUTH_HEADER` to point at any OTLP/HTTP backend, and change the demo's exporter the same way. The `langfuse.*` attributes are specific to Langfuse."
  - variation: "Put the session ID on every span"
    how: "Langfuse filters and aggregations work more reliably when each span carries `langfuse.session.id`. See [Propagating trace attributes to all spans](https://langfuse.com/integrations/native/opentelemetry#propagating-attributes) in the Langfuse documentation."
  - variation: "Add per-hop token limits"
    how: "Attach the [AI Rate Limiting Advanced](/ai-gateway/policies/ai-rate-limiting-advanced/) Policy to the LLM AI Model. See the [LLM cost optimization cookbook](/cookbooks/llm-cost-optimization/) for an example."
  - variation: "Authenticate users with an identity provider"
    how: "Replace the Key Auth AI Auth Strategy with an [OpenID Connect AI Auth Strategy](/ai-gateway/openid-connect/) and map JWT claims to AI Consumers. The AI Models and AI Model Providers don't change. See the [Claude Code SSO cookbook](/cookbooks/claude-code-sso/) for an example with Okta."
{% endtable %}

## Cleanup

The recipe's kongctl namespace scoped all resources, so this teardown removes only this recipe's configuration. Tear down the local data plane and delete the {{site.ai_gateway}} from {{site.konnect_short_name}}:

```bash
export KONNECT_CONTROL_PLANE_NAME='voice-ai-observability-recipe' && curl -Ls https://get.konghq.com/ai | bash -s -- -d -k $KONNECT_TOKEN
```
