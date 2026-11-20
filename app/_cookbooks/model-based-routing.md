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
works_on:
  - konnect
min_version:
  ai-gateway: '2.0'
categories:
  - llm
  - cost-optimization
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
    - title: OpenAI
      content: |
        OpenAI serves the prompt classifier and the fast tier.

        1. [Create an OpenAI account](https://auth.openai.com/create-account).
        1. [Get an API key](https://platform.openai.com/api-keys).
        1. Export the API key:

           ```sh
           export OPENAI_TOKEN='Bearer sk-YOUR-KEY'
           ```
    - title: AWS Bedrock
      content: |
        AWS Bedrock serves the smart tier with a Claude model.

        1. Get an AWS account with [Bedrock model access](https://docs.aws.amazon.com/bedrock/latest/userguide/model-access.html) enabled for Claude Sonnet 4.5.
        1. Export your AWS credentials and region:

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
  Route each chat request to a fast OpenAI model or to Claude on AWS Bedrock, based on how complex the prompt is, without the client choosing a model or a provider. You'll set up:

  * One `/chat` endpoint that accepts only requests with a valid AI Consumer API key
  * A small classifier model that labels each prompt `fast` or `smart`
  * A workflow in {{site.ai_gateway}} that sends the prompt to the matching tier and returns its answer
---

## What this cookbook solves

Most teams send all LLM traffic to one model, or let each client choose a model tier, which causes the following problems:

{% table %}
columns:
  - title: Problem
    key: problem
  - title: Solution
    key: solution
rows:
  - problem: "A capable model charges the same per-token price for a greeting as for a multi-step analysis, so simple requests cost more than they need to."
    solution: "A selector AI Model classifies each prompt with a small OpenAI model. The Datakit Policy sends prompts labeled `fast` to a cheaper OpenAI model."
  - problem: "A small, cheap model gives weak answers to prompts that need reasoning, code generation, or long-form analysis."
    solution: "Prompts labeled `smart` go to a smart-tier AI Model that uses Claude on AWS Bedrock."
  - problem: "Keyword rules such as \"if the prompt mentions code, use the bigger model\" don't generalize, and the rule set grows without getting more accurate."
    solution: "The AI Prompt Decorator Policy gives the classifier its rules as a system message. You change the rules in the configuration, not in application code."
  - problem: "When clients choose the tier, each team repeats the same decision, and nothing stops a caller from always choosing the expensive tier."
    solution: "Clients call one `/chat` endpoint. {{site.ai_gateway}} chooses the tier, and the client never names a provider or a model."
  - problem: "Each service holds copies of the OpenAI and AWS credentials."
    solution: "Two AI Model Providers keep the credentials in Kong. Clients hold an AI Consumer key, and the Key Auth AI Auth Strategy rejects unknown keys with `401` before any classification."
{% endtable %}

## Try it out

Apply the configuration, then run a demo script that sends a simple prompt, a complex prompt, and one request with an invalid API key to `/chat`.

### Apply the Kong configuration

The configuration creates two AI Model Providers (OpenAI and AWS Bedrock), a Key Auth AI Auth Strategy, an AI Consumer with a demo API key, an AI Prompt Decorator Policy, a Datakit Policy, and four AI Models: the public `/chat` AI Model and the selector, fast-tier, and smart-tier AI Models that it calls. A kongctl namespace scopes every resource, so you can remove this configuration without affecting anything else on the same {{site.ai_gateway}}. See the [kongctl documentation](/kongctl/) for more on namespaces.

Adopt the quickstart {{site.ai_gateway}} into a kongctl namespace so that kongctl can manage it. Adoption adds the `KONGCTL-namespace` label to the {{site.ai_gateway}}:

```bash
kongctl adopt ai-gateway "${KONNECT_CONTROL_PLANE_NAME}" \
  --namespace "${KONNECT_CONTROL_PLANE_NAME}" \
  --pat "${KONNECT_TOKEN}"
```

Export the demo AI Consumer's API key. The credential's `api_key` field is write-only, so its value must come from an environment variable, even for a fixed demo key:

```bash
export CONSUMER_API_KEY='demo-api-key'
```

Export the three upstream models. `OPENAI_SELECTOR_SLM` is the classifier, `OPENAI_FAST_MODEL` serves the fast tier, and `BEDROCK_SMART_MODEL` serves the smart tier. Provider credentials come from the prerequisites:

```bash
export OPENAI_SELECTOR_SLM='gpt-4o-mini'
export OPENAI_FAST_MODEL='gpt-4o-mini'
export BEDROCK_SMART_MODEL='global.anthropic.claude-sonnet-4-5-20250929-v1:0'
```

Apply the Kong configuration:

```bash
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
      hide_credentials: false

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
        - name: CLASSIFIER_BODY
          type: jq
          input: request.body
          jq: '{model: "classifier", messages: .messages}'

        - name: FAST_BODY
          type: jq
          input: request.body
          jq: '{model: "fast", messages: .messages}'

        - name: SMART_BODY
          type: jq
          input: request.body
          jq: '{model: "smart", messages: .messages}'

        - name: EXTRACT_AUTH
          type: jq
          input: request.headers
          jq: '{apikey: (.apikey // .Apikey // .APIKey)}'

        - name: CALL_MODEL_SELECTOR
          type: call
          url: http://localhost:8000/model-selection/chat/completions
          method: POST
          inputs:
            body: CLASSIFIER_BODY
            headers: EXTRACT_AUTH

        - name: EXTRACT_TIER
          type: jq
          input: CALL_MODEL_SELECTOR.body
          jq: '.choices[0].message.content | gsub("^\\s+|\\s+$"; "")'

        - name: IS_SMART
          type: jq
          input: EXTRACT_TIER
          jq: '. == "smart"'

        - name: ROUTE_DECISION
          type: branch
          input: IS_SMART
          then:
            - CALL_SMART
            - RESPOND_SMART
          else:
            - CALL_FAST
            - RESPOND_FAST

        - name: CALL_SMART
          type: call
          url: http://localhost:8000/model-based-routing-smart/chat/completions
          method: POST
          inputs:
            body: SMART_BODY
            headers: EXTRACT_AUTH

        - name: RESPOND_SMART
          type: exit
          inputs:
            body: CALL_SMART.body
            headers: CALL_SMART.headers

        - name: CALL_FAST
          type: call
          url: http://localhost:8000/model-based-routing-fast/chat/completions
          method: POST
          inputs:
            body: FAST_BODY
            headers: EXTRACT_AUTH

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
        model:
          body_param: model
          values:
            - classifier
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
        model:
          body_param: model
          values:
            - fast
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
        model:
          body_param: model
          values:
            - smart
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
        model:
          body_param: model
          values:
            - auto
    targets:
      - name: !env OPENAI_FAST_MODEL
        provider: model-based-routing-openai-provider
        config:
          type: openai
EOF

kongctl apply -f kong-recipe.yaml -o text --auto-approve --pat "${KONNECT_TOKEN}"

rm -f kong-recipe.yaml
```
{: data-test-step="block" .collapsible }

### Run the demo

The script sends a simple prompt and a complex prompt to `/chat`, then sends one request with an invalid API key. In the output, look for the upstream model on each `[ROUTED TO]` line and the `401` for the invalid key.

{:.info}
> The demo passes the API key in `default_headers` because the OpenAI SDK always sends `api_key` as an `Authorization: Bearer` header. To let clients use `api_key` directly, add a global [Pre-Function](/ai-gateway/policies/pre-function/) Policy (`global: true`) that copies the Bearer token to the `apikey` header. A global Pre-Function Policy runs before authentication, while one attached to the AI Model runs after it.

Create the demo script:

```bash
cat <<'EOF' > demo.py
"""Model-based routing demo for Kong AI Gateway.

Shows three things:
  1. A simple prompt sent to /chat is classified as "fast" and served by the
     OpenAI fast tier. The X-Kong-LLM-Model response header names the upstream model.
  2. A complex prompt sent to the same endpoint is classified as "smart" and
     served by the Claude model on AWS Bedrock.
  3. A request with an invalid key gets 401 from Kong before any classification
     or upstream call.

Expected output: one [ROUTED TO] line with an OpenAI model for the simple prompt,
one [ROUTED TO] line with a Bedrock model for the complex prompt, then a
[BLOCKED] 401 line for the invalid key.

Run: python demo.py (set PROXY_URL if the data plane is not at http://localhost:8000,
and CONSUMER_API_KEY if you changed the demo key).
"""

import os
import sys
import time

from openai import APIStatusError, OpenAI

PROXY_URL = os.getenv("PROXY_URL", "http://localhost:8000")
API_KEY = os.getenv("CONSUMER_API_KEY", "demo-api-key")

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
        # The SDK requires a model field. The Datakit workflow forwards only the
        # messages to the classifier and the tiers, so this value never reaches a provider.
        raw = client.chat.completions.with_raw_response.create(
            model="auto",
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
    section("1. Simple prompt. Expected tier: fast (OpenAI)")
    client = make_client(API_KEY)
    call(client, "simple", SIMPLE_PROMPT)

    section("2. Complex prompt. Expected tier: smart (AWS Bedrock)")
    call(client, "complex", COMPLEX_PROMPT)

    section("3. Invalid API key. Kong rejects before any classification or upstream call")
    bad_key = "not-a-real-key"
    print(f"\nTrying apikey={bad_key!r}")
    bad_client = make_client(bad_key)
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
1. Simple prompt. Expected tier: fast (OpenAI)
======================================================================

[REQUEST] simple: "Hi there! What's 2 + 2?"
[RESPONSE] 2 + 2 equals 4.
[ROUTED TO] upstream model=openai/gpt-4o-mini
[LATENCY] upstream=612ms  proxy=780ms  total=1401ms

======================================================================
2. Complex prompt. Expected tier: smart (AWS Bedrock)
======================================================================

[REQUEST] complex: 'Perform in depth analysis of the ancient Roman world during the time of Pliny the Elder in two paragraphs.'
[RESPONSE] Pliny the Elder lived during the early Roman Empire, a period marked by...
[ROUTED TO] upstream model=bedrock/global.anthropic.claude-sonnet-4-5-20250929-v1:0
[LATENCY] upstream=2114ms  proxy=845ms  total=2984ms

======================================================================
3. Invalid API key. Kong rejects before any classification or upstream call
======================================================================

Trying apikey='not-a-real-key'

[REQUEST] simple: "Hi there! What's 2 + 2?"
[BLOCKED] 401 Error code: 401 - Unauthorized  (28ms)

======================================================================
Done.
======================================================================
```
{:.no-copy-code}

### Check the results

The output confirms the following:

{% table %}
columns:
  - title: Behavior
    key: behavior
  - title: Evidence
    key: evidence
rows:
  - behavior: "Routing by prompt complexity"
    evidence: "The `[ROUTED TO]` lines show an OpenAI model for the simple prompt and a Bedrock model for the complex prompt, from the `X-Kong-LLM-Model` header. Both requests used the same path and the same `model` value."
  - behavior: "The client doesn't choose the model"
    evidence: "The demo sends `model: auto` on every request, the alias of the `/chat` AI Model. The Datakit Policy sends each internal call the alias of the AI Model it calls, and the tier AI Model's target sets the upstream model."
  - behavior: "Classification adds latency"
    evidence: "The proxy latency includes the classifier call, so it's higher than for a direct call to one AI Model."
  - behavior: "Authentication before classification"
    evidence: "The invalid key gets `401` in about 30 ms. Kong rejected it before the classifier or any provider was called."
{% endtable %}

To review the created entities, and per-consumer usage, open the `model-based-routing-recipe` {{site.ai_gateway}} in [{{site.konnect_short_name}}](https://cloud.konghq.com/). For traffic across all your {{site.ai_gateway}}s, use the **Observability** menu.

## How it works

Kong authenticates the request on the `/chat` AI Model. The Datakit Policy on that AI Model calls the selector AI Model, reads the tier from its answer, calls the matching tier's AI Model, and returns that response to the client.

<!-- vale off -->
{% mermaid %}
sequenceDiagram
    participant C as Client
    participant K as Kong AI Gateway (/chat)
    participant S as Selector AI Model
    participant T as Tier AI Model
    participant L as OpenAI or AWS Bedrock

    C->>K: POST /chat (apikey, messages)
    activate K
    K->>K: Key Auth AI Auth Strategy validates apikey (else 401)
    K->>S: Datakit call to /model-selection
    activate S
    S-->>K: fast or smart
    deactivate S
    K->>T: Datakit call to /model-based-routing-fast or /model-based-routing-smart
    activate T
    T->>L: Request with the AI Model Provider's credentials
    activate L
    L-->>T: Completion
    deactivate L
    T-->>K: OpenAI-format response with X-Kong-LLM-Model
    deactivate T
    K-->>C: Datakit exit returns the tier's response
    deactivate K
{% endmermaid %}
<!-- vale on -->

Kong selects the AI Model for a request before any AI Policy runs, so a policy can't move a request to another AI Model. The Datakit Policy works around this: it calls the other AI Models over HTTP and returns their response with an `exit` node. This cookbook hasn't confirmed this workflow against a live {{site.ai_gateway}}.

### Key Auth AI Auth Strategy and AI Consumer

Authentication is an AI Auth Strategy, not an AI Policy. The Key Auth AI Auth Strategy reads the `apikey` header and matches the key against the AI Consumer credentials. On a match, Kong attaches the AI Consumer to the request. The AI Consumer is the identity that rate limits, ACLs, and analytics use. All four AI Models reference this AI Auth Strategy in `access.auth_strategies`, so the Datakit Policy forwards the client's key on each internal call.

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
  - setting: "`hide_credentials: false`"
    purpose: "Kong keeps the `apikey` header on the request, because the Datakit Policy reads it and forwards it on the internal calls. With `true`, Kong removes the key before the Datakit Policy runs, and the internal calls fail with `401`. The upstream providers also receive the `apikey` header, but each AI Model Provider replaces the `Authorization` header with its own credentials."
  - setting: "`credentials[].api_key`"
    purpose: "The AI Consumer's key. The field is write-only, so it takes a `!secret` reference to `CONSUMER_API_KEY`, even for a demo value."
{% endtable %}

Kong adds `X-Consumer-Username` and related headers to the upstream request, not to the response. Per-consumer usage appears in {{site.konnect_short_name}} analytics.

### AI Prompt Decorator Policy and selector AI Model

The selector AI Model (`/model-selection`) is the classifier. The [AI Prompt Decorator](/ai-gateway/policies/ai-prompt-decorator/) Policy on it adds a system message before the user's prompt. The message tells the classifier model to answer with one word, `fast` or `smart`.

The following settings configure the AI Prompt Decorator Policy and the selector AI Model:

{% table %}
columns:
  - title: Setting
    key: setting
  - title: Purpose
    key: purpose
rows:
  - setting: "`prompts.prepend`"
    purpose: "The system message with the classification rules. Kong adds it before the user's messages. Edit it to change what counts as simple or complex."
  - setting: "`llm_format: openai`"
    purpose: "The policy reads and writes OpenAI-format messages, which match the selector AI Model's `formats`."
  - setting: "`policies: [model-based-routing-decorator]`"
    purpose: "Attaches the policy to the selector AI Model only. The tier AI Models receive the prompt without the classification message."
  - setting: "`targets[].name`"
    purpose: "The classifier model, from `OPENAI_SELECTOR_SLM`. A small model is enough, because it returns only one word."
{% endtable %}

### Datakit Policy

The [Datakit](/ai-gateway/policies/datakit/) Policy is attached to the `/chat` AI Model and runs the routing workflow as a graph of nodes. Its `call` nodes send requests to the data plane's own proxy listener at `http://localhost:8000`, at each AI Model's path plus `/chat/completions`, so each internal call goes through the same authentication as a client request.

The following nodes make up the workflow:

{% table %}
columns:
  - title: Setting
    key: setting
  - title: Purpose
    key: purpose
rows:
  - setting: "`CLASSIFIER_BODY`, `FAST_BODY`, `SMART_BODY`"
    purpose: "`jq` nodes that build each internal request body: the client's `messages` array and the alias of the AI Model to call (`classifier`, `fast`, or `smart`). A node's result is read by the node's name, for example `FAST_BODY`."
  - setting: "`EXTRACT_AUTH`"
    purpose: "A `jq` node that copies the `apikey` header from the request headers, so the internal calls authenticate as the same AI Consumer."
  - setting: "`CALL_MODEL_SELECTOR`"
    purpose: "A `call` node that sends `CLASSIFIER_BODY` and the key to `/model-selection/chat/completions`."
  - setting: "`EXTRACT_TIER`, `IS_SMART`"
    purpose: "`jq` nodes that read the classifier's answer and turn it into a boolean. Any answer other than `smart` selects the fast tier."
  - setting: "`ROUTE_DECISION`"
    purpose: "A `branch` node. It runs `CALL_SMART` and `RESPOND_SMART` when the input is `true`, and `CALL_FAST` and `RESPOND_FAST` otherwise."
  - setting: "`CALL_SMART`, `CALL_FAST`"
    purpose: "`call` nodes that send `SMART_BODY` or `FAST_BODY` and the key to `/model-based-routing-smart/chat/completions` or `/model-based-routing-fast/chat/completions`."
  - setting: "`RESPOND_SMART`, `RESPOND_FAST`"
    purpose: "`exit` nodes that return the tier's body and headers to the client, including `X-Kong-LLM-Model`. {{site.ai_gateway}} then doesn't call the `/chat` AI Model's own target."
{% endtable %}

### AI Model Providers and AI Models

The two AI Model Providers hold the OpenAI and AWS credentials. The selector and fast-tier AI Models use the OpenAI AI Model Provider, and the smart-tier AI Model uses the AWS Bedrock AI Model Provider. Clients call only `/chat`. The other three AI Models exist for the Datakit Policy, but a client with a valid key can also call them directly, because the internal calls use the client's own key.

The following settings configure the AI Model Providers and the AI Models:

{% table %}
columns:
  - title: Setting
    key: setting
  - title: Purpose
    key: purpose
rows:
  - setting: "`config.auth` (AI Model Providers)"
    purpose: "The provider credentials. OpenAI uses an `Authorization` header. AWS Bedrock uses `access_key_id` and `secret_access_key`. Kong adds them to each upstream request."
  - setting: "`targets[].config.region` (smart tier)"
    purpose: "The AWS region for Bedrock, from `AWS_REGION`. The region belongs to the target, not to the AI Model Provider."
  - setting: "`targets[].name` (fast and smart tiers)"
    purpose: "The upstream models, from `OPENAI_FAST_MODEL` and `BEDROCK_SMART_MODEL`. Change them and re-apply to swap models without changing clients."
  - setting: "`config.route.model`"
    purpose: "The alias each AI Model answers to in the body's `model` field: `classifier`, `fast`, `smart`, and `auto` for `/chat`. Without a selector, an AI Model accepts only its own name as `model`."
  - setting: "`targets` (`/chat` AI Model)"
    purpose: "An AI Model needs at least one target. The `exit` nodes return before Kong uses it."
  - setting: "`config.response_streaming: deny`"
    purpose: "Clients can't set `stream=true` on any of the four AI Models. The Datakit Policy needs complete response bodies to read the tier and to return the answer."
  - setting: "`config.max_request_body_size`"
    purpose: "Accepts request bodies up to 10 MB on the `/chat` and tier AI Models, and 5 MB on the selector AI Model."
  - setting: "`config.route.protocols: [http, https]`"
    purpose: "Accepts HTTP, so you can call the local data plane at `http://localhost:8000`, and so the Datakit Policy can call the other AI Models over HTTP."
  - setting: "`config.route.strip_path: true`"
    purpose: "Kong removes the route path before it forwards the request upstream."
  - setting: "`config.logging.payloads: false`"
    purpose: "Kong doesn't log request and response payloads."
{% endtable %}

{:.info}
> **Production credentials:** This cookbook stores the AI Consumer's API key and the provider credentials in environment variables for simplicity. In production, use [AI Vaults](/ai-gateway/entities/ai-vault/) to reference them from a secret manager, for example AWS Secrets Manager, HashiCorp Vault, GCP Secret Manager, or Azure Key Vault.

### Response headers

The `exit` node returns the tier AI Model's response headers. The demo reads the following headers:

{% table %}
columns:
  - title: Header
    key: header
  - title: Description
    key: description
rows:
  - header: "`X-Kong-LLM-Model`"
    description: "The upstream model that served the request, with the provider name as a prefix, for example `openai/gpt-4o-mini`."
  - header: "`X-Kong-Upstream-Latency`"
    description: "Time in milliseconds that Kong waited for the provider to respond."
  - header: "`X-Kong-Proxy-Latency`"
    description: "Time in milliseconds that Kong spent processing the request, excluding the upstream call."
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
  - variation: "Swap models"
    how: "Change `OPENAI_SELECTOR_SLM`, `OPENAI_FAST_MODEL`, or `BEDROCK_SMART_MODEL` and re-apply. Clients keep calling `/chat`."
  - variation: "Tune the classification rules"
    how: "Edit the system message in the AI Prompt Decorator Policy, for example to treat translation as `fast` or multi-step planning as `smart`, and re-apply."
  - variation: "Add a third tier"
    how: "Add a third answer to the classification rules, an AI Model for the new tier, and a matching `jq`, `branch`, `call`, and `exit` path in the Datakit Policy."
  - variation: "Route by semantic similarity"
    how: "Instead of a classifier call, set `config.balancer.algorithm: semantic` on one AI Model with several targets. See the [AI Model reference](/ai-gateway/entities/ai-model/) and the [LLM cost optimization cookbook](/cookbooks/llm-cost-optimization/) for an example."
  - variation: "Add per-consumer token limits"
    how: "Attach the [AI Rate Limiting Advanced](/ai-gateway/policies/ai-rate-limiting-advanced/) Policy to the `/chat` AI Model to give each AI Consumer its own token budget."
  - variation: "Trace the classification call"
    how: "Add a global [OpenTelemetry](/ai-gateway/policies/opentelemetry/) Policy to see the classifier call and the tier call as separate spans. See the [Voice AI pipeline observability cookbook](/cookbooks/voice-ai-observability/) for an example."
{% endtable %}

## Cleanup

The recipe's kongctl namespace scoped all resources, so this teardown removes only this recipe's configuration. Tear down the local data plane and delete the {{site.ai_gateway}} from {{site.konnect_short_name}}:

```bash
export KONNECT_CONTROL_PLANE_NAME='model-based-routing-recipe' && curl -Ls https://get.konghq.com/ai | bash -s -- -d -k $KONNECT_TOKEN
```
