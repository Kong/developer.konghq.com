---
title: Model-Based Routing
description: Dynamically route requests across OpenAI and AWS Bedrock based on prompt complexity analysis.
url: "/cookbooks/model-based-routing/"
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
  - llm
  - cost-optimization
featured: true
popular: false

# Machine-readable fields for AI agent setup
plugins:
  - key-auth
  - ai-prompt-decorator
  - datakit
  - ai-model
  - ai-model-provider
requires_embeddings: false
providers:
  - openai
  - bedrock

hint: "{{site.konnect_short_name}} account, kongctl, an OpenAI API key, and AWS Bedrock credentials."
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

        1. Set the recipe-scoped {{site.ai_gateway}} name and run the quickstart script:

           ```bash
           export KONNECT_CONTROL_PLANE_NAME='model-based-routing-recipe'
           curl -Ls https://get.konghq.com/ai | bash -s -- -k $KONNECT_TOKEN
           ```

           This provisions an {{site.ai_gateway}} named `model-based-routing-recipe`, a local data plane connected to it, and prints `export` lines for the rest of the session vars, including `AI_GATEWAY_ID`. Paste those into your shell when prompted.
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
        This recipe routes every request across two providers, so you need credentials for both. OpenAI serves the fast tier and the prompt-complexity classifier; AWS Bedrock serves the smart tier.

        1. **OpenAI**:
           1. [Create an OpenAI account](https://auth.openai.com/create-account).
           1. [Get an API key](https://platform.openai.com/api-keys).
           1. Export the API key as an environment variable:

              ```sh
              export OPENAI_TOKEN='Bearer sk-YOUR-KEY'
              ```
        1. **AWS Bedrock**:
           1. Ensure you have an AWS account with [Bedrock model access](https://docs.aws.amazon.com/bedrock/latest/userguide/model-access.html) enabled for a Claude model.
           1. Export your AWS credentials:

              ```sh
              export AWS_ACCESS_KEY_ID='your-access-key'
              export AWS_SECRET_ACCESS_KEY='your-secret-key'
              export AWS_REGION='us-east-1'
              ```
    - title: Python 3.11+
      icon_url: /assets/icons/python.svg
      content: |
        The demo script requires Python 3.11 or later. Set up an isolated environment:

        ```bash
        python3 -m venv .venv
        source .venv/bin/activate
        pip install 'openai>=1.0.0'
        ```

overview: |
  Route chat requests across OpenAI and AWS Bedrock based on how complex each prompt actually
  is, without the client choosing a tier or a provider. By the end of this recipe, you'll
  have a single `/chat` endpoint that classifies every incoming prompt with a small, cheap
  model, then dispatches the request to a fast OpenAI model for simple prompts or to Claude on
  AWS Bedrock for prompts that need deeper reasoning.
---

## The problem

Teams running production LLM traffic on a single model face a tradeoff they can't route
around at the application layer:

- **A single capable model overpays for easy requests.** A frontier model priced for deep
  reasoning charges the same per-token rate for "hello" as it does for a multi-step analysis
  task. Industry cost breakdowns of production LLM traffic commonly show the majority of
  requests are simple completions that a much cheaper model could have handled equally well.
- **A single cheap model falls short on hard requests.** A small, fast model that keeps
  costs down on simple traffic produces worse answers, or fails outright, on requests that
  need multi-step reasoning, code generation, or long-context analysis.
- **Hardcoded, keyword-based routing breaks down fast.** Rules like "if the prompt contains
  the word 'code', use the bigger model" don't generalize. Real user prompts don't follow
  templates, and the rule set that tries to keep up becomes an unmaintainable pile of
  string-matching heuristics that still classify most prompts incorrectly.
- **Client-chosen tiers push a platform decision onto every caller.** If application code
  decides which model tier to call, every team integrating with the platform needs to
  implement and maintain that same judgment call, and nothing stops a caller from always
  requesting the expensive tier out of caution.

The root issue is that model selection needs to be a per-request decision made close to the
request, using the actual content of the prompt, not a static assignment baked into
application code or a client-side guess.

## The solution

{{site.ai_gateway_name}} inserts a classification step ahead of the actual chat request. A
small, inexpensive model reads each incoming prompt and returns a tier recommendation, and
{{site.base_gateway}} uses that recommendation to dispatch the request to the right upstream
model, either a fast OpenAI model for simple prompts or Claude on AWS Bedrock for prompts
that need deeper reasoning. The client always calls the same `/chat` endpoint with a standard
chat completion body. It never chooses a provider, never chooses a model, and never sees the
classification step happen.

<!-- vale off -->
{% mermaid %}
sequenceDiagram
    participant C as Client
    participant Chat as chat AI Model
    participant Sel as selector AI Model<br/>(OpenAI o3-mini)
    participant Fast as fast-tier AI Model<br/>(OpenAI)
    participant Smart as smart-tier AI Model<br/>(Bedrock Claude)

    C->>Chat: POST /chat (apikey, prompt)
    activate Chat
    Chat->>Chat: key-auth Auth Strategy: validate apikey (else 401)
    Chat->>Sel: Datakit Policy calls /model-selection with the prompt
    activate Sel
    Sel-->>Chat: Tier recommendation ("fast" or "smart")
    deactivate Sel
    alt Fast tier
        Chat->>Fast: Datakit calls /model-based-routing-fast
        activate Fast
        Fast-->>Chat: Completion
        deactivate Fast
    else Smart tier
        Chat->>Smart: Datakit calls /model-based-routing-smart
        activate Smart
        Smart-->>Chat: Completion
        deactivate Smart
    end
    Chat-->>C: Completion (+ X-Kong-LLM-Model)
    deactivate Chat
{% endmermaid %}
<!-- vale on -->

{% table %}
columns:
  - title: Component
    key: component
  - title: Responsibility
    key: responsibility
rows:
  - component: Client application
    responsibility: "Sends a standard chat completion request to `/chat` with an `apikey` header. No routing logic required."
  - component: Key Auth AI Auth Strategy
    responsibility: Validates the `apikey` header against a registered AI Consumer credential before any classification or upstream call happens.
  - component: Datakit Policy (orchestrator)
    responsibility: Extracts the prompt, calls the selector AI Model, reads back the tier recommendation, and calls whichever tier AI Model matches.
  - component: selector AI Model
    responsibility: Classifies prompt complexity using a small OpenAI model and an AI Prompt Decorator Policy that constrains the answer to a single word.
  - component: fast-tier AI Model
    responsibility: Serves simple prompts using a fast, inexpensive OpenAI model.
  - component: smart-tier AI Model
    responsibility: Serves complex prompts using Claude on AWS Bedrock.
  - component: AI Model Providers
    responsibility: Hold the OpenAI and AWS Bedrock credentials and inject them into every upstream call.
{% endtable %}

## How it works

A request to `/chat` passes through four stages: authentication, classification, dispatch,
and response relay.

1. A client sends a chat completion request to `/chat` with an `apikey` header. The request
   body's `model` field carries a placeholder value; Kong ignores it.
2. The Key Auth AI Auth Strategy validates the `apikey` header against a registered AI Consumer
   credential. An invalid or missing key gets a `401` before any classification or upstream
   call happens.
3. The Datakit Policy attached to the `/chat` AI Model extracts the prompt and calls the
   selector AI Model at `/model-selection`, forwarding the same `apikey` header.
4. The selector AI Model's AI Prompt Decorator Policy prepends classification instructions to
   the prompt, then its AI Proxy target sends the decorated prompt to a small OpenAI model,
   which returns exactly one word: `fast` or `smart`.
5. Back in the Datakit workflow, a parsed tier decision determines which internal AI Model to
   call next: the fast tier (OpenAI) or the smart tier (AWS Bedrock, Claude).
6. Datakit calls the chosen tier's AI Model directly, then returns that Model's response to
   the client as the final answer to `/chat`, including the `X-Kong-LLM-Model` header showing
   which upstream model actually served the request.

### Key Auth: API key authentication and AI Consumer mapping

Authentication in {{site.ai_gateway_name}} 2.0 is an AI Auth Strategy, not an AI Policy. Every AI
Model in this recipe (the public `/chat` endpoint and the three internal Models) shares the
same Key Auth AI Auth Strategy and the same AI Consumer credential, so a single API key
authenticates both the client's request and every internal call the Datakit workflow makes on
its behalf.

#### Configuration details

{%- raw %}
```yaml
ai_gateway_auth_strategies:
  - ref: model-based-routing-auth
    type: key-auth
    display_name: "model-based-routing key auth"
    config:
      key_names:
        - apikey
      hide_credentials: true

ai_gateway_consumers:
  - ref: model-based-routing-consumer
    name: model-based-routing-consumer
    display_name: "model-based-routing demo consumer"
    type: api-key
    credentials:
      - ref: model-based-routing-credential
        name: model-based-routing-credential
        display_name: "model-based-routing demo API key"
        type: api-key
        api_key: !secret {source: !env CONSUMER_API_KEY}
```
{% endraw -%}
{:.no-copy-code}

**`key_names: [apikey]`**. The header Kong checks for the API key. The Datakit Policy reads
this same header from the client's request and forwards it on every internal call, so one
credential authenticates the whole request chain.

**`hide_credentials: true`**. Strips the API key before any request leaves Kong, so neither
provider ever sees the AI Consumer's key.

**`api_key` is write-only.** An AI Consumer credential's `api_key` field must be a `!secret`
reference. Kong rejects a plain string here, even for a demo value like this recipe's.

### AI Prompt Decorator: classify prompt complexity

The [AI Prompt Decorator](/ai-gateway/policies/ai-prompt-decorator/) Policy prepends a hidden
system message to the selector AI Model, instructing the classifier model to analyze the
prompt and return only `fast` or `smart`. The client never sees this instruction. It only
sees its own prompt and, eventually, an answer.

#### Configuration details

{%- raw %}
```yaml
ai_gateway_policies:
  - ref: model-based-routing-decorator
    type: ai-prompt-decorator
    display_name: "model-based-routing classifier prompt"
    config:
      llm_format: openai
      prompts:
        prepend:
          - role: system
            content: >
              You are a model router. Analyze the user's prompt and recommend
              the most appropriate model tier.

              Return ONLY ONE of these values:
              - "fast" for simple tasks (greetings, basic questions, straightforward requests)
              - "smart" for complex tasks (reasoning, analysis, coding, creative writing)

              Respond with just the single word "fast" or "smart", nothing else.
```
{% endraw -%}
{:.no-copy-code}

**`prompts.prepend`**. The AI Prompt Decorator Policy inserts the system message before the
user's prompt in the message array that Kong sends to the classifier model. The system message
constrains the classifier's output to a single word, which the Datakit workflow parses directly.

Adjust the classification rules in the system message to fit your workload. For example,
treat translation as `fast` or multi-step planning as `smart`, depending on which upstream tier
handles your traffic best.

### AI Model and AI Model Provider: the selector, fast tier, and smart tier

Three of this recipe's four AI Models exist to serve the dynamic-routing mechanism rather
than to be called directly: the selector classifies prompts using a small OpenAI model, the
fast tier serves simple prompts using a larger OpenAI model, and the smart tier serves complex
prompts using Claude on AWS Bedrock. Each AI Model references an AI Model Provider that holds
that provider's credentials.

#### Configuration details

{%- raw %}
```yaml
ai_gateway_model_providers:
  - ref: model-based-routing-openai-provider
    type: openai
    display_name: "model-based-routing (OpenAI)"
    config:
      auth:
        type: basic
        headers:
          - name: Authorization
            value: !secret {source: !env OPENAI_TOKEN}

  - ref: model-based-routing-bedrock-provider
    type: bedrock
    display_name: "model-based-routing (AWS Bedrock)"
    config:
      auth:
        type: aws
        access_key_id: !env AWS_ACCESS_KEY_ID
        secret_access_key: !secret {source: !env AWS_SECRET_ACCESS_KEY}

ai_gateway_models:
  - ref: model-based-routing-selector
    type: model
    display_name: "model-based-routing (selector)"
    formats:
      - type: openai
    capabilities:
      - generate
    access:
      auth_strategies:
        - model-based-routing-auth
    policies:
      - model-based-routing-decorator
    config:
      max_request_body_size: 5242880
      response_streaming: deny
      route:
        paths:
          - /model-selection
    targets:
      - name: !env OPENAI_SELECTOR_SLM
        provider: model-based-routing-openai-provider
        config:
          type: openai
```
{% endraw -%}
{:.no-copy-code}

**`config.auth`** (on the AI Model Provider). Kong holds provider credentials here and injects
them into every upstream request routed through that AI Model Provider. AWS Bedrock authenticates with
`access_key_id`/`secret_access_key`, and the region lives on the target, not the AI Model Provider,
because one AWS account's credentials can serve targets in different regions.

**`response_streaming: deny`** on every AI Model in this recipe. The Datakit Policy needs a
complete response body from the selector call to parse the tier decision, and needs a
complete response body from whichever tier it calls to relay back to the client. Streaming
responses from any of the four Models in this recipe wouldn't reach the orchestrator step
that depends on them, so this recipe doesn't support token-by-token streaming on `/chat`.

**`targets[].name`**. The upstream model identifier. The selector uses a small, cheap model
since the classifier only needs to return one word, not generate a full answer.

The fast tier and smart tier AI Models (`model-based-routing-fast`,
`model-based-routing-smart`) follow the same shape, targeting a larger OpenAI model and a
Claude model on Bedrock respectively. Clients don't call either Model directly. Both exist so
the Datakit Policy on `/chat` can call them internally and relay their response.

### Datakit: dynamic tier orchestration

The [Datakit](/ai-gateway/policies/datakit/) Policy attached to the public `/chat` AI Model runs the whole
dynamic-routing workflow as a sequence of declarative nodes: extract the prompt, call the
selector, parse the tier, call the matching tier's AI Model, and return that response to the
client.

#### Configuration details

{%- raw %}
```yaml
ai_gateway_policies:
  - ref: model-based-routing-orchestrator
    type: datakit
    display_name: "model-based-routing tier orchestration"
    config:
      nodes:
        - name: EXTRACT_PROMPT
          type: jq
          input: request.body
          output: prompt_data
          jq: '{messages: .messages}'

        - name: EXTRACT_AUTH
          type: jq
          input: request.headers
          output: auth_header
          jq: '{apikey: (.apikey // .Apikey // .APIKey)}'

        - name: CALL_MODEL_SELECTOR
          type: call
          url: http://localhost:8000/model-selection
          method: POST
          inputs:
            body: EXTRACT_PROMPT.prompt_data
            headers: EXTRACT_AUTH.auth_header

        - name: EXTRACT_TIER
          type: jq
          input: CALL_MODEL_SELECTOR.body
          output: tier
          jq: '.choices[0].message.content | gsub("^\\s+|\\s+$"; "")'

        - name: IS_SMART
          type: jq
          input: EXTRACT_TIER.tier
          output: value
          jq: '. == "smart"'

        - name: ROUTE_DECISION
          type: branch
          input: IS_SMART.value
          then:
            - CALL_SMART
            - RESPOND_SMART
          else:
            - CALL_FAST
            - RESPOND_FAST

        - name: CALL_SMART
          type: call
          url: http://localhost:8000/model-based-routing-smart
          method: POST
          inputs:
            body: EXTRACT_PROMPT.prompt_data
            headers: EXTRACT_AUTH.auth_header

        - name: RESPOND_SMART
          type: exit
          inputs:
            body: CALL_SMART.body
            headers: CALL_SMART.headers

        - name: CALL_FAST
          type: call
          url: http://localhost:8000/model-based-routing-fast
          method: POST
          inputs:
            body: EXTRACT_PROMPT.prompt_data
            headers: EXTRACT_AUTH.auth_header

        - name: RESPOND_FAST
          type: exit
          inputs:
            body: CALL_FAST.body
            headers: CALL_FAST.headers
```
{% endraw -%}
{:.no-copy-code}

**`EXTRACT_PROMPT` / `EXTRACT_AUTH`**. Pull the message array and the `apikey` header out of
the client's original request, so both can be forwarded to every internal call this workflow
makes.

**`CALL_MODEL_SELECTOR`**. Calls the selector AI Model's `/model-selection` path the same way
an external client would, reusing the client's own API key.

**`EXTRACT_TIER` / `IS_SMART`**. Parse the classifier's single-word answer into a tier string,
then into a boolean the `branch` node can act on.

**`ROUTE_DECISION`**. A `branch` node that calls the smart tier's AI Model when the classifier
says `smart`, or the fast tier's AI Model otherwise.

**`RESPOND_SMART` / `RESPOND_FAST`**. An `exit` node returns a response built from an earlier
node directly to the client, bypassing this AI Model's own target. Each branch reaches its
matching `exit` node with the body and headers from whichever tier's AI Model actually served
the request, including `X-Kong-LLM-Model`.

This exact node graph (the `branch` and `exit` node fields in the selector configuration) has not yet been
verified against a live {{site.ai_gateway}}. Confirm it with a real deployment before relying on it in
production, and see the [Datakit Policy reference](/ai-gateway/policies/datakit/) for the full field
set on each node type.

{:.info}
> In production, store credentials in [AI Vaults](/ai-gateway/entities/ai-vault/) using {%raw%}`{vault://backend/key}`{%endraw%} references rather than environment variables. AI Vaults support HashiCorp Vault, AWS Secrets Manager, GCP Secret Manager, and the {{site.konnect_short_name}} Config Store.

## Apply the Kong configuration

The following configuration creates two AI Model Providers (OpenAI and AWS Bedrock), a
Key Auth AI Auth Strategy with a demo AI Consumer, an AI Prompt Decorator Policy for
classification, a Datakit Policy for orchestration, and four AI Models: the public `/chat`
endpoint plus the selector, fast-tier, and smart-tier Models it calls internally. A kongctl
namespace scopes every resource, so you can tear the configuration down cleanly without
affecting other configurations on the same {{site.ai_gateway}}.

First, adopt the quickstart {{site.ai_gateway}} into a kongctl namespace so the following apply command can
manage it.

```bash
kongctl adopt ai-gateway "${KONNECT_CONTROL_PLANE_NAME}" \
  --namespace "${KONNECT_CONTROL_PLANE_NAME}" \
  --pat "${KONNECT_TOKEN}"
```

Adoption stamps the `KONGCTL-namespace` label on the {{site.ai_gateway}}.

Export the demo AI Consumer's API key and the model selections for each tier. The AI Consumer
credential's `api_key` field is write-only and must come from an env var, even for this fixed
demo value:

```bash
export CONSUMER_API_KEY='demo-api-key'
export OPENAI_SELECTOR_SLM='o3-mini'                                  # classifier model
export OPENAI_FAST_MODEL='gpt-4o-mini'                                # fast tier
export BEDROCK_SMART_MODEL='anthropic.claude-3-5-sonnet-20241022-v2:0'  # smart tier
```

Apply the Kong configuration:

```bash
{%- raw %}
cat <<'EOF' > kong-recipe.yaml
_defaults:
  kongctl:
    namespace: model-based-routing-recipe

ai_gateway_model_providers:
  - ref: model-based-routing-openai-provider
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    name: model-based-routing-openai-provider
    display_name: "model-based-routing (OpenAI)"
    type: openai
    config:
      auth:
        type: basic
        headers:
          - name: Authorization
            value: !secret {source: !env OPENAI_TOKEN}

  - ref: model-based-routing-bedrock-provider
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    name: model-based-routing-bedrock-provider
    display_name: "model-based-routing (AWS Bedrock)"
    type: bedrock
    config:
      auth:
        type: aws
        access_key_id: !env AWS_ACCESS_KEY_ID
        secret_access_key: !secret {source: !env AWS_SECRET_ACCESS_KEY}

ai_gateway_auth_strategies:
  - ref: model-based-routing-auth
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    name: model-based-routing-auth
    display_name: "model-based-routing key auth"
    type: key-auth
    config:
      key_names:
        - apikey
      hide_credentials: true

ai_gateway_consumers:
  - ref: model-based-routing-consumer
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    name: model-based-routing-consumer
    display_name: "model-based-routing demo consumer"
    type: api-key
    credentials:
      - ref: model-based-routing-credential
        name: model-based-routing-credential
        display_name: "model-based-routing demo API key"
        type: api-key
        api_key: !secret {source: !env CONSUMER_API_KEY}

ai_gateway_policies:
  - ref: model-based-routing-decorator
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    name: model-based-routing-decorator
    display_name: "model-based-routing classifier prompt"
    type: ai-prompt-decorator
    config:
      llm_format: openai
      prompts:
        prepend:
          - role: system
            content: >
              You are a model router. Analyze the user's prompt and recommend
              the most appropriate model tier.

              Return ONLY ONE of these values:
              - "fast" for simple tasks (greetings, basic questions, straightforward requests)
              - "smart" for complex tasks (reasoning, analysis, coding, creative writing)

              Respond with just the single word "fast" or "smart", nothing else.

  - ref: model-based-routing-orchestrator
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    name: model-based-routing-orchestrator
    display_name: "model-based-routing tier orchestration"
    type: datakit
    config:
      nodes:
        - name: EXTRACT_PROMPT
          type: jq
          input: request.body
          output: prompt_data
          jq: '{messages: .messages}'

        - name: EXTRACT_AUTH
          type: jq
          input: request.headers
          output: auth_header
          jq: '{apikey: (.apikey // .Apikey // .APIKey)}'

        - name: CALL_MODEL_SELECTOR
          type: call
          url: http://localhost:8000/model-selection
          method: POST
          inputs:
            body: EXTRACT_PROMPT.prompt_data
            headers: EXTRACT_AUTH.auth_header

        - name: EXTRACT_TIER
          type: jq
          input: CALL_MODEL_SELECTOR.body
          output: tier
          jq: '.choices[0].message.content | gsub("^\\s+|\\s+$"; "")'

        - name: IS_SMART
          type: jq
          input: EXTRACT_TIER.tier
          output: value
          jq: '. == "smart"'

        - name: ROUTE_DECISION
          type: branch
          input: IS_SMART.value
          then:
            - CALL_SMART
            - RESPOND_SMART
          else:
            - CALL_FAST
            - RESPOND_FAST

        - name: CALL_SMART
          type: call
          url: http://localhost:8000/model-based-routing-smart
          method: POST
          inputs:
            body: EXTRACT_PROMPT.prompt_data
            headers: EXTRACT_AUTH.auth_header

        - name: RESPOND_SMART
          type: exit
          inputs:
            body: CALL_SMART.body
            headers: CALL_SMART.headers

        - name: CALL_FAST
          type: call
          url: http://localhost:8000/model-based-routing-fast
          method: POST
          inputs:
            body: EXTRACT_PROMPT.prompt_data
            headers: EXTRACT_AUTH.auth_header

        - name: RESPOND_FAST
          type: exit
          inputs:
            body: CALL_FAST.body
            headers: CALL_FAST.headers

ai_gateway_models:
  - ref: model-based-routing-selector
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    name: model-based-routing-selector
    display_name: "model-based-routing (selector)"
    type: model
    formats:
      - type: openai
    capabilities:
      - generate
    access:
      auth_strategies:
        - model-based-routing-auth
    policies:
      - model-based-routing-decorator
    config:
      max_request_body_size: 5242880
      response_streaming: deny
      logging:
        payloads: false
      route:
        paths:
          - /model-selection
        protocols:
          - http
          - https
        methods:
          - POST
          - OPTIONS
        strip_path: true
    targets:
      - name: !env OPENAI_SELECTOR_SLM
        provider: model-based-routing-openai-provider
        config:
          type: openai

  - ref: model-based-routing-fast
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    name: model-based-routing-fast
    display_name: "model-based-routing (fast tier)"
    type: model
    formats:
      - type: openai
    capabilities:
      - generate
    access:
      auth_strategies:
        - model-based-routing-auth
    config:
      max_request_body_size: 10485760
      response_streaming: deny
      logging:
        payloads: false
      route:
        paths:
          - /model-based-routing-fast
        protocols:
          - http
          - https
        methods:
          - POST
          - OPTIONS
        strip_path: true
    targets:
      - name: !env OPENAI_FAST_MODEL
        provider: model-based-routing-openai-provider
        config:
          type: openai

  - ref: model-based-routing-smart
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    name: model-based-routing-smart
    display_name: "model-based-routing (smart tier)"
    type: model
    formats:
      - type: openai
    capabilities:
      - generate
    access:
      auth_strategies:
        - model-based-routing-auth
    config:
      max_request_body_size: 10485760
      response_streaming: deny
      logging:
        payloads: false
      route:
        paths:
          - /model-based-routing-smart
        protocols:
          - http
          - https
        methods:
          - POST
          - OPTIONS
        strip_path: true
    targets:
      - name: !env BEDROCK_SMART_MODEL
        provider: model-based-routing-bedrock-provider
        config:
          region: !env AWS_REGION
          type: bedrock

  - ref: model-based-routing-chat
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    name: model-based-routing-chat
    display_name: "model-based-routing (chat)"
    type: model
    formats:
      - type: openai
    capabilities:
      - generate
    access:
      auth_strategies:
        - model-based-routing-auth
    policies:
      - model-based-routing-orchestrator
    config:
      max_request_body_size: 10485760
      response_streaming: deny
      logging:
        payloads: false
      route:
        paths:
          - /chat
        protocols:
          - http
          - https
        methods:
          - POST
          - OPTIONS
        strip_path: true
    targets:
      - name: !env OPENAI_FAST_MODEL
        provider: model-based-routing-openai-provider
        config:
          type: openai
EOF
{% endraw -%}

kongctl apply -f kong-recipe.yaml -o text --auto-approve --pat "${KONNECT_TOKEN}"

rm -f kong-recipe.yaml
```
{: data-test-step="block" .collapsible }

## Try it out

The demo script sends a simple prompt and a complex prompt to `/chat`, printing the
`X-Kong-LLM-Model` header on each response so you can confirm which upstream model actually
answered. A final call presents an invalid API key and shows Kong rejecting it with `401`
before any classification or upstream call.

{:.info}
> The demo passes the API key via `default_headers` because the OpenAI SDK reserves `api_key` for the `Authorization: Bearer` header. To let clients pass the key through `api_key` directly, attach a [Pre-Function](/ai-gateway/policies/pre-function/) Policy that copies the Bearer token to the `apikey` header server-side.

Create the demo script:

```bash
cat <<'EOF' > demo.py
"""Model-based routing demo. See README for context.

Sends a simple prompt and a complex prompt to Kong's /chat endpoint. Kong classifies each
prompt's complexity internally (via an OpenAI o3-mini call) and dynamically routes the
request to either the OpenAI fast tier or the AWS Bedrock (Claude) smart tier. The demo
prints the X-Kong-LLM-Model header on each response so you can confirm which upstream model
actually served the request. A final call with an invalid API key shows Kong rejecting the
request with 401 before any classification or upstream call happens.

Run with:

    python demo.py

Requires the Kong configuration from the README to be applied and PROXY_URL (defaults to
http://localhost:8000) reachable.
"""

import os
import sys
import time

from openai import APIStatusError, OpenAI

PROXY_URL = os.getenv("PROXY_URL", "http://localhost:8000")
API_KEY = "demo-api-key"

SIMPLE_PROMPT = "Hi there! What's 2 + 2?"
COMPLEX_PROMPT = (
    "Perform in depth analysis of the ancient Roman world during the time "
    "of Pliny the Elder in two paragraphs."
)

# ANSI color codes. Disabled when stdout isn't a TTY or NO_COLOR is set.
_USE_COLOR = sys.stdout.isatty() and "NO_COLOR" not in os.environ
def _c(code: str, s: str) -> str:
    return f"\033[{code}m{s}\033[0m" if _USE_COLOR else s
BOLD  = lambda s: _c("1", s)
DIM   = lambda s: _c("2", s)
GREEN = lambda s: _c("32", s)
CYAN  = lambda s: _c("36", s)
RED   = lambda s: _c("31", s)


def make_client(api_key: str) -> OpenAI:
    """Construct an OpenAI client that sends the given API key in the apikey header."""
    return OpenAI(
        base_url=f"{PROXY_URL}/chat",
        api_key="unused",  # required by the SDK; Kong reads the apikey header instead
        default_headers={"apikey": api_key},
    )


def call(client: OpenAI, label: str, prompt: str) -> None:
    """Send one chat request and print which upstream model Kong routed it to."""
    print(f"\n{BOLD('[REQUEST]')} {label}: {prompt!r}")
    start_ms = round(time.time() * 1000)
    try:
        # The body's "model" field is a placeholder. Kong's internal classifier
        # overwrites it with "fast" or "smart" before the request reaches the
        # upstream provider, so the value sent here never reaches OpenAI or Bedrock.
        raw = client.chat.completions.with_raw_response.create(
            model="fast",
            messages=[{"role": "user", "content": prompt}],
        )
    except APIStatusError as e:
        elapsed_ms = round(time.time() * 1000) - start_ms
        print(f"{RED(BOLD('[BLOCKED]'))} {RED(BOLD(str(e.status_code)))} {e.message}  ({elapsed_ms}ms)")
        return

    elapsed_ms = round(time.time() * 1000) - start_ms
    completion = raw.parse()
    upstream_model = raw.headers.get("x-kong-llm-model", ".")
    upstream_latency = raw.headers.get("x-kong-upstream-latency", ".")
    proxy_latency = raw.headers.get("x-kong-proxy-latency", ".")
    answer = completion.choices[0].message.content

    print(f"[RESPONSE] {DIM(answer)}")
    print(f"{GREEN(BOLD('[ROUTED TO]'))} upstream model={CYAN(BOLD(upstream_model))}")
    print(f"[LATENCY] {DIM(f'upstream={upstream_latency}ms  proxy={proxy_latency}ms  total={elapsed_ms}ms')}")


def section(title: str) -> None:
    bar = "=" * 70
    print(f"\n{bar}\n{BOLD(title)}\n{bar}")


def main() -> None:
    section("1. Simple prompt. Kong's classifier should recommend the fast tier")
    client = make_client(API_KEY)
    call(client, "simple", SIMPLE_PROMPT)

    section("2. Complex prompt. Kong's classifier should recommend the smart tier")
    call(client, "complex", COMPLEX_PROMPT)

    section("3. Invalid API key. Kong rejects before any classification or upstream call")
    bad_client = make_client("not-a-real-key")
    call(bad_client, "simple", SIMPLE_PROMPT)

    section("Done.")


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        sys.exit(130)
EOF
```
{:.collapsible}

Run it:

```bash
python demo.py
```

Example output:

```text
======================================================================
1. Simple prompt. Kong's classifier should recommend the fast tier
======================================================================

[REQUEST] simple: "Hi there! What's 2 + 2?"
[RESPONSE] 2 + 2 equals 4.
[ROUTED TO] upstream model=openai/gpt-4o-mini
[LATENCY] upstream=612ms  proxy=780ms  total=1401ms

======================================================================
2. Complex prompt. Kong's classifier should recommend the smart tier
======================================================================

[REQUEST] complex: "Perform in depth analysis of the ancient Roman world during the time of Pliny the Elder in two paragraphs."
[RESPONSE] Pliny the Elder lived during the early Roman Empire, a period marked by...
[ROUTED TO] upstream model=bedrock/anthropic.claude-3-5-sonnet-20241022-v2:0
[LATENCY] upstream=2114ms  proxy=845ms  total=2984ms

======================================================================
3. Invalid API key. Kong rejects before any classification or upstream call
======================================================================

[REQUEST] simple: "Hi there! What's 2 + 2?"
[BLOCKED] 401 Error code: 401 - {'message': 'Unauthorized'}  (28ms)

======================================================================
Done.
======================================================================
```
{:.no-copy-code}

Example request body sent to `/chat` (identical for the simple and complex calls, only the
prompt text changes):

```json
{
  "model": "fast",
  "messages": [
    { "role": "user", "content": "Hi there! What's 2 + 2?" }
  ]
}
```
{:.no-copy-code}

### What happened

1. **Both prompts hit the same endpoint.** Neither call told Kong which tier or provider to
   use. The `model` field in the request body is a placeholder the classification step
   overwrites internally.
2. **Kong classified each prompt before proxying it.** Kong classified the simple greeting as
   `fast` and routed it to the OpenAI fast-tier Model. Kong classified the Roman history
   analysis as `smart` and routed it to the Bedrock smart-tier Model. The `X-Kong-LLM-Model` header on each
   response shows the actual upstream model that answered.
3. **The proxy latency includes the classification round trip.** Because the orchestrator
   AI Policy calls the selector AI Model internally before calling the chosen tier, `proxy`
   latency in this recipe includes both the classification call and the orchestration
   overhead, not just Kong's own request handling.
4. **Kong enforced auth before doing any of that work.** The third request used a key no
   AI Consumer holds. The Key Auth AI Auth Strategy rejected it in about 30 ms, well before the
   classification step or any provider call would have started, so the request consumed no
   provider quota.

### Explore in {{site.konnect_short_name}}

Open [{{site.konnect_short_name}}](https://cloud.konghq.com/) and find the {{site.ai_gateway}} named
`model-based-routing-recipe`. The recipe created two AI Model Providers (OpenAI and AWS
Bedrock), four AI Models (`model-based-routing-chat`, `model-based-routing-selector`,
`model-based-routing-fast`, `model-based-routing-smart`), a Key Auth AI Auth Strategy, an AI
Prompt Decorator Policy, a Datakit Policy, and an AI Consumer with a demo API key credential, all
scoped to this recipe by the kongctl namespace applied above.

For platform-wide traffic analysis across every {{site.ai_gateway}}, head to the **Observability** L1
menu in {{site.konnect_short_name}}.

## Variations and next steps

**Add a third tier.** Extend the classifier's system message to return a third value (for
example, `"batch"` for non-interactive workloads) and add a matching internal AI Model and
`branch` path in the orchestrator AI Policy.

**Tune the classification rules.** The AI Prompt Decorator's system message defines what
counts as simple versus complex. Adjust it to match your own traffic patterns, for example
treating short code snippets as `fast` and long-form creative writing as `smart`.

**Add per-consumer rate limits.** With the Key Auth AI Auth Strategy mapping requests to AI Consumers,
attach the [AI Rate Limiting Advanced](/ai-gateway/policies/ai-rate-limiting-advanced/) Policy
to the `/chat` AI Model to apply token quotas per AI Consumer. See the
[LLM cost optimization recipe](/cookbooks/llm-cost-optimization/) for a worked example of
cost-based tiered rate limiting.

**Add tracing across the classification hop.** Attach the
[OpenTelemetry](/ai-gateway/policies/opentelemetry/) Policy to see the classification call and the chosen
tier's call as separate spans in your observability backend. See the
[Voice AI observability recipe](/cookbooks/voice-ai-observability/) for a worked example.

## Cleanup

The recipe's kongctl namespace scoped all resources, so this teardown removes only this
recipe's configuration. Tear down the local data plane and delete the {{site.ai_gateway}} from {{site.konnect_short_name}}:

```bash
export KONNECT_CONTROL_PLANE_NAME='model-based-routing-recipe' && curl -Ls https://get.konghq.com/ai | bash -s -- -d -k $KONNECT_TOKEN
```
