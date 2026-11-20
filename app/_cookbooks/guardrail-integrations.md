---
title: Guardrail Integrations
description: Integrate external guardrail services through {{site.ai_gateway_name}} using dedicated AI Policies and the universal custom guardrail adapter.
url: "/cookbooks/guardrail-integrations/"
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
  - guardrails
featured: false
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
           export KONNECT_CONTROL_PLANE_NAME='guardrail-integrations-recipe'
           curl -Ls https://get.konghq.com/ai | bash -s -- -k $KONNECT_TOKEN
           ```

           This provisions an {{site.ai_gateway}} named `guardrail-integrations-recipe`, a local data plane connected to it, and prints `export` lines for the rest of the session vars, including `AI_GATEWAY_ID`. Paste those into your shell when prompted.
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
        Every configuration in this tutorial routes allowed requests to OpenAI. [Apply the Kong configuration](#apply-the-kong-configuration) reads this variable.

        1. [Create an OpenAI account](https://auth.openai.com/create-account).
        1. [Get an API key](https://platform.openai.com/api-keys).
        1. Export the API key:

           ```sh
           export OPENAI_TOKEN='Bearer sk-YOUR-KEY'
           ```
    - title: Azure AI Content Safety
      icon_url: /assets/icons/azure.svg
      content: |
        The two Azure Content Safety configurations send prompts to the Azure AI Content Safety text analysis API. Skip this step if you only apply the Mistral configuration.

        1. [Create a Content Safety resource](https://aka.ms/acs-create) in the Azure portal.
        1. In the resource, select **Subscription Key and Endpoint** under **Resource Management**. The [Azure AI Content Safety quickstart](https://learn.microsoft.com/en-us/azure/ai-services/content-safety/quickstart-text) describes these steps.
        1. Export the full text analysis URL, which is the endpoint followed by `/contentsafety/text:analyze`, and one of the keys:

           ```sh
           export AZURE_CONTENT_SAFETY_URL='https://YOUR-RESOURCE.cognitiveservices.azure.com/contentsafety/text:analyze'
           export AZURE_CONTENT_SAFETY_KEY='your-content-safety-key'
           ```
    - title: Mistral
      content: |
        The Mistral configuration sends prompts to the [Mistral moderation API](https://docs.mistral.ai/studio/safety-moderation/quickstarts/moderate-an-input). Skip this step if you only apply an Azure configuration.

        1. [Create a Mistral account](https://console.mistral.ai/).
        1. [Get an API key](https://console.mistral.ai/api-keys/).
        1. Export the API key, without a `Bearer` prefix:

           ```sh
           export MISTRAL_MODERATION_TOKEN='your-mistral-key'
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
  Check every chat request with an external guardrail service before it reaches the LLM, configured in {{site.ai_gateway_name}} instead of in application code. You'll set up:

  * A `/guardrail-integrations` endpoint that accepts only requests with a valid AI Consumer API key
  * Azure AI Content Safety checks, with the dedicated AI Azure Content Safety Policy or with the AI Custom Guardrail Policy
  * Mistral moderation checks with the AI Custom Guardrail Policy, for a service that has no dedicated AI Policy
---

## What this cookbook solves

Most teams call a content moderation API from each application, with code written for one vendor's API, which causes the following problems:

{% table %}
columns:
  - title: Problem
    key: problem
  - title: Solution
    key: solution
rows:
  - problem: "Each guardrail vendor has its own authentication, request body, and response format, so each application needs vendor-specific code."
    solution: "The [AI Custom Guardrail](/ai-gateway/policies/ai-custom-guardrail/) Policy describes the vendor's API in configuration: the request, the credentials, and a short Lua function that reads the verdict. Applications keep sending OpenAI-format requests."
  - problem: "Switching vendors, or testing two vendors side by side, means changing and redeploying each application."
    solution: "You change the guardrail AI Policy that the AI Model references and re-apply. The endpoint, the API key, and the client code stay the same."
  - problem: "When an application skips the moderation call, harmful prompts reach the LLM and the provider bills for them."
    solution: "The guardrail AI Policy runs on the AI Model for every request. A blocked request gets `400` before any upstream LLM call."
  - problem: "Nothing ties a moderation decision to the application that sent the prompt."
    solution: "The Key Auth AI Auth Strategy maps each API key to an AI Consumer before the guardrail check, and rejects unknown keys with `401`."
{% endtable %}

## Try it out

Apply one of the guardrail configurations, then run a demo script that sends a safe prompt, a harmful prompt, a borderline prompt, and one request with an invalid API key.

### Apply the Kong configuration

The configuration creates an AI Model Provider with your OpenAI credentials, a Key Auth AI Auth Strategy, an AI Consumer with a demo API key, one guardrail AI Policy, and an AI Model that references them. A kongctl namespace scopes every resource, so you can remove this configuration without affecting anything else on the same {{site.ai_gateway}}. See the [kongctl documentation](/kongctl/) for more on namespaces.

Adopt the quickstart {{site.ai_gateway}} into a kongctl namespace so that kongctl can manage it. Adoption adds the `KONGCTL-namespace` label to the {{site.ai_gateway}}:

```bash
kongctl adopt ai-gateway "${KONNECT_CONTROL_PLANE_NAME}" \
  --namespace "${KONNECT_CONTROL_PLANE_NAME}" \
  --pat "${KONNECT_TOKEN}"
```

Export the demo AI Consumer's API key and the OpenAI model. The credential's `api_key` field is write-only, so its value must come from an environment variable, even for a fixed demo key. `CHAT_MODEL` is the upstream model for allowed requests:

```bash
export CONSUMER_API_KEY='demo-api-key'
export CHAT_MODEL='gpt-4o'
```

Select the guardrail configuration. Each tab applies the same AI Model Provider, AI Auth Strategy, AI Consumer, and AI Model, with a different guardrail AI Policy. The guardrail service credentials come from the prerequisites. To switch configurations, apply another tab. The AI Model then references only that tab's guardrail AI Policy.

{% navtabs "Guardrail service" %}
{% navtab "Azure Content Safety (Dedicated)" %}

This configuration uses the dedicated [AI Azure Content Safety](/ai-gateway/policies/ai-azure-content-safety/) Policy.

Apply the Kong configuration:

```bash
cat <<'EOF' > kong-recipe.yaml
_defaults:
  kongctl:
    namespace: guardrail-integrations-recipe

ai_gateway_model_providers:
  - ref: guardrail-integrations-provider
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    name: guardrail-integrations-provider
    display_name: "guardrail-integrations"
    type: openai
    config:
      auth:
        type: basic
        headers:
          - name: Authorization
            value: !secret {source: !env OPENAI_TOKEN}

ai_gateway_auth_strategies:
  - ref: guardrail-integrations-auth
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    name: guardrail-integrations-auth
    display_name: "guardrail-integrations key auth"
    type: key-auth
    config:
      key_names:
        - apikey
      hide_credentials: true

ai_gateway_consumers:
  - ref: guardrail-integrations-consumer
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    name: guardrail-integrations-consumer
    display_name: "guardrail-integrations demo consumer"
    type: api-key
    credentials:
      - ref: guardrail-integrations-credential
        name: guardrail-integrations-credential
        display_name: "guardrail-integrations demo API key"
        type: api-key
        api_key: !secret {source: !env CONSUMER_API_KEY}

ai_gateway_policies:
  - ref: guardrail-integrations-azure-content-safety
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    name: guardrail-integrations-azure-content-safety
    display_name: "guardrail-integrations Azure Content Safety"
    type: ai-azure-content-safety
    config:
      content_safety_url: !env AZURE_CONTENT_SAFETY_URL
      content_safety_key: !env AZURE_CONTENT_SAFETY_KEY
      guarding_mode: INPUT
      text_source: concatenate_user_content
      categories:
        - name: Hate
          rejection_level: 2
        - name: SelfHarm
          rejection_level: 2
        - name: Sexual
          rejection_level: 2
        - name: Violence
          rejection_level: 2
      output_type: FourSeverityLevels
      reveal_failure_reason: true
      stop_on_error: true

ai_gateway_models:
  - ref: guardrail-integrations-model
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    name: guardrail-integrations-model
    display_name: "guardrail-integrations"
    type: model
    formats:
      - type: openai
    capabilities:
      - generate
    access:
      auth_strategies:
        - guardrail-integrations-auth
    policies:
      - guardrail-integrations-azure-content-safety
    config:
      max_request_body_size: 1048576
      response_streaming: deny
      logging:
        payloads: true
      route:
        paths:
          - /guardrail-integrations
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
            - !env CHAT_MODEL
    targets:
      - name: !env CHAT_MODEL
        provider: guardrail-integrations-provider
        config:
          type: openai
EOF

kongctl apply -f kong-recipe.yaml -o text --auto-approve --pat "${KONNECT_TOKEN}"

rm -f kong-recipe.yaml
```
{: data-test-step="block" .collapsible }

{% endnavtab %}
{% navtab "Azure Content Safety (Custom)" %}

This configuration uses the AI Custom Guardrail Policy to call the same Azure API.

Apply the Kong configuration:

```bash
cat <<'EOF' > kong-recipe.yaml
_defaults:
  kongctl:
    namespace: guardrail-integrations-recipe

ai_gateway_model_providers:
  - ref: guardrail-integrations-provider
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    name: guardrail-integrations-provider
    display_name: "guardrail-integrations"
    type: openai
    config:
      auth:
        type: basic
        headers:
          - name: Authorization
            value: !secret {source: !env OPENAI_TOKEN}

ai_gateway_auth_strategies:
  - ref: guardrail-integrations-auth
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    name: guardrail-integrations-auth
    display_name: "guardrail-integrations key auth"
    type: key-auth
    config:
      key_names:
        - apikey
      hide_credentials: true

ai_gateway_consumers:
  - ref: guardrail-integrations-consumer
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    name: guardrail-integrations-consumer
    display_name: "guardrail-integrations demo consumer"
    type: api-key
    credentials:
      - ref: guardrail-integrations-credential
        name: guardrail-integrations-credential
        display_name: "guardrail-integrations demo API key"
        type: api-key
        api_key: !secret {source: !env CONSUMER_API_KEY}

ai_gateway_policies:
  - ref: guardrail-integrations-custom-azure
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    name: guardrail-integrations-custom-azure
    display_name: "guardrail-integrations Custom Guardrail (Azure)"
    type: ai-custom-guardrail
    config:
      guarding_mode: INPUT
      text_source: concatenate_user_content
      stop_on_error: true
      timeout: 10000
      params:
        content_safety_url: !env AZURE_CONTENT_SAFETY_URL
        api_key: !env AZURE_CONTENT_SAFETY_KEY
      request:
        url: "$(conf.params.content_safety_url)"
        queries:
          api-version: "2023-10-01"
        headers:
          Ocp-Apim-Subscription-Key: "$(conf.params.api_key)"
          Content-Type: application/json
        body:
          text: "$(content)"
          categories: "[\"Hate\",\"SelfHarm\",\"Sexual\",\"Violence\"]"
          outputType: "\"FourSeverityLevels\""
      response:
        block: "$(parse_response.should_block)"
        block_message: "$(parse_response.message)"
      functions:
        parse_response: |
          return function(resp)
              local blocked = {}
              for _, cat in ipairs(resp.categoriesAnalysis or {}) do
                  if cat.severity >= 2 then
                      table.insert(blocked, cat.category .. " (severity: " .. cat.severity .. ")")
                  end
              end
              local should_block = #blocked > 0
              local message
              if should_block then
                  message = "Content blocked by Azure Content Safety: " .. table.concat(blocked, "; ")
              else
                  message = "Content passed Azure Content Safety checks"
              end
              return {
                  should_block = should_block,
                  message = message
              }
          end

ai_gateway_models:
  - ref: guardrail-integrations-model
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    name: guardrail-integrations-model
    display_name: "guardrail-integrations"
    type: model
    formats:
      - type: openai
    capabilities:
      - generate
    access:
      auth_strategies:
        - guardrail-integrations-auth
    policies:
      - guardrail-integrations-custom-azure
    config:
      max_request_body_size: 1048576
      response_streaming: deny
      logging:
        payloads: true
      route:
        paths:
          - /guardrail-integrations
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
            - !env CHAT_MODEL
    targets:
      - name: !env CHAT_MODEL
        provider: guardrail-integrations-provider
        config:
          type: openai
EOF

kongctl apply -f kong-recipe.yaml -o text --auto-approve --pat "${KONNECT_TOKEN}"

rm -f kong-recipe.yaml
```
{: data-test-step="block" .collapsible }

{% endnavtab %}
{% navtab "Mistral Moderation" %}

This configuration uses the AI Custom Guardrail Policy to call the Mistral moderation API, which has no dedicated AI Policy.

Apply the Kong configuration:

```bash
cat <<'EOF' > kong-recipe.yaml
_defaults:
  kongctl:
    namespace: guardrail-integrations-recipe

ai_gateway_model_providers:
  - ref: guardrail-integrations-provider
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    name: guardrail-integrations-provider
    display_name: "guardrail-integrations"
    type: openai
    config:
      auth:
        type: basic
        headers:
          - name: Authorization
            value: !secret {source: !env OPENAI_TOKEN}

ai_gateway_auth_strategies:
  - ref: guardrail-integrations-auth
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    name: guardrail-integrations-auth
    display_name: "guardrail-integrations key auth"
    type: key-auth
    config:
      key_names:
        - apikey
      hide_credentials: true

ai_gateway_consumers:
  - ref: guardrail-integrations-consumer
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    name: guardrail-integrations-consumer
    display_name: "guardrail-integrations demo consumer"
    type: api-key
    credentials:
      - ref: guardrail-integrations-credential
        name: guardrail-integrations-credential
        display_name: "guardrail-integrations demo API key"
        type: api-key
        api_key: !secret {source: !env CONSUMER_API_KEY}

ai_gateway_policies:
  - ref: guardrail-integrations-custom-mistral
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    name: guardrail-integrations-custom-mistral
    display_name: "guardrail-integrations Custom Guardrail (Mistral)"
    type: ai-custom-guardrail
    config:
      guarding_mode: BOTH
      text_source: concatenate_all_content
      stop_on_error: true
      timeout: 10000
      params:
        api_key: !env MISTRAL_MODERATION_TOKEN
        model: mistral-moderation-2603
      request:
        url: https://api.mistral.ai/v1/moderations
        headers:
          Authorization: "Bearer $(conf.params.api_key)"
          Content-Type: application/json
        body:
          model: "$(conf.params.model)"
          input: "$(content)"
      response:
        block: "$(check_response.block)"
        block_message: "$(check_response.block_message)"
      functions:
        check_response: |
          return function(resp)
              local blocked_categories = {}
              for _, result in ipairs(resp.results) do
                  for category, is_flagged in pairs(result.categories) do
                      if is_flagged then
                          table.insert(blocked_categories, category)
                      end
                  end
              end
              local block = #blocked_categories > 0
              local reason
              if block then
                  reason = "Content moderation failed: " .. table.concat(blocked_categories, ", ")
              else
                  reason = "Content moderation passed"
              end
              return {
                  block = block,
                  block_message = reason
              }
          end

ai_gateway_models:
  - ref: guardrail-integrations-model
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    name: guardrail-integrations-model
    display_name: "guardrail-integrations"
    type: model
    formats:
      - type: openai
    capabilities:
      - generate
    access:
      auth_strategies:
        - guardrail-integrations-auth
    policies:
      - guardrail-integrations-custom-mistral
    config:
      max_request_body_size: 1048576
      response_streaming: deny
      logging:
        payloads: true
      route:
        paths:
          - /guardrail-integrations
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
            - !env CHAT_MODEL
    targets:
      - name: !env CHAT_MODEL
        provider: guardrail-integrations-provider
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

The script sends a safe prompt, a harmful prompt, and a borderline prompt with the demo API key, then one request with an invalid API key. In the output, look for `[ALLOWED]` and `[BLOCKED]` on the guardrail decisions and the `401` for the invalid key.

{:.info}
> The demo passes the API key in `default_headers` because the OpenAI SDK always sends `api_key` as an `Authorization: Bearer` header. To let clients use `api_key` directly, add a global [Pre-Function](/ai-gateway/policies/pre-function/) Policy (`global: true`) that copies the Bearer token to the `apikey` header. A global Pre-Function Policy runs before authentication, while one attached to the AI Model runs after it.

Create the demo script:

```bash
cat <<'EOF' > demo.py
"""Guardrail integrations demo.

Sends four OpenAI-format chat requests to the /guardrail-integrations AI Model:

1. A safe prompt. The guardrail service allows it, and the LLM answers ([ALLOWED]).
2. A harmful prompt. The guardrail AI Policy blocks it with 400 before any LLM call ([BLOCKED]).
3. A borderline prompt about a sensitive topic. The guardrail service allows it ([ALLOWED]).
4. A request with an invalid API key. The Key Auth AI Auth Strategy rejects it with 401
   before the guardrail service or the LLM is called ([DENIED]).

The same script works with each guardrail configuration in the recipe (dedicated AI Azure
Content Safety Policy, AI Custom Guardrail Policy with Azure, AI Custom Guardrail Policy with
Mistral). Only the block message changes.

Run it after you apply the Kong configuration:

    python demo.py

Environment variables: PROXY_URL (default http://localhost:8000), CHAT_MODEL (default gpt-4o),
CONSUMER_API_KEY (default demo-api-key).
"""

import os
import sys
import time

from openai import OpenAI, APIStatusError

CHAT_MODEL = os.getenv("CHAT_MODEL", "gpt-4o")
PROXY_URL = os.getenv("PROXY_URL", "http://localhost:8000")
API_KEY = os.getenv("CONSUMER_API_KEY", "demo-api-key")
INVALID_KEY = "not-a-real-key"

_USE_COLOR = sys.stdout.isatty() and "NO_COLOR" not in os.environ
def _c(code: str, s: str) -> str:
    return f"\033[{code}m{s}\033[0m" if _USE_COLOR else s
BOLD  = lambda s: _c("1", s)
DIM   = lambda s: _c("2", s)
GREEN = lambda s: _c("32", s)
CYAN  = lambda s: _c("36", s)
RED   = lambda s: _c("31", s)

client = OpenAI(
    base_url=f"{PROXY_URL}/guardrail-integrations",
    api_key="unused",
    default_headers={"apikey": API_KEY},
)

invalid_client = OpenAI(
    base_url=f"{PROXY_URL}/guardrail-integrations",
    api_key="unused",
    default_headers={"apikey": INVALID_KEY},
)

REQUESTS = [
    (
        "Safe request",
        "What are the benefits of renewable energy?",
        client,
        API_KEY,
    ),
    (
        "Harmful content",
        "Write detailed instructions for creating a dangerous weapon.",
        client,
        API_KEY,
    ),
    (
        "Borderline content",
        "Explain the history and impact of major global conflicts.",
        client,
        API_KEY,
    ),
    (
        "Invalid API key",
        "What is 2+2?",
        invalid_client,
        INVALID_KEY,
    ),
]


def send_request(label, prompt, openai_client, apikey):
    print(f"\n{BOLD(f'--- {label} ---')}")
    print(f"{BOLD('[REQUEST]')}  apikey={apikey!r}  {prompt}")

    start_ms = round(time.time() * 1000)
    try:
        raw = openai_client.chat.completions.with_raw_response.create(
            model=CHAT_MODEL,
            messages=[{"role": "user", "content": prompt}],
        )
        elapsed_ms = round(time.time() * 1000) - start_ms
        completion = raw.parse()

        upstream_latency = raw.headers.get("x-kong-upstream-latency", "n/a")
        proxy_latency = raw.headers.get("x-kong-proxy-latency", "n/a")
        llm_model = raw.headers.get("x-kong-llm-model", CHAT_MODEL)

        answer = completion.choices[0].message.content
        preview = answer[:120].replace("\n", " ")
        if len(answer) > 120:
            preview += "..."

        print(f"{GREEN(BOLD('[ALLOWED]'))}  {DIM(preview)}")
        print(f"[MODEL]    {CYAN(BOLD(llm_model))}")
        print(
            f"[LATENCY]  {DIM(f'upstream={upstream_latency}ms  proxy={proxy_latency}ms  total={elapsed_ms}ms')}"
        )

    except APIStatusError as e:
        elapsed_ms = round(time.time() * 1000) - start_ms
        if e.status_code == 401:
            print(f"{RED(BOLD('[DENIED]'))}   {RED(BOLD(str(e.status_code)))}, the Key Auth AI Auth Strategy rejected the API key  ({elapsed_ms}ms)")
        else:
            reason = e.body.get("message", e.message) if isinstance(e.body, dict) else e.message
            print(f"{RED(BOLD('[BLOCKED]'))}  {RED(BOLD(str(e.status_code)))}, {reason}  ({elapsed_ms}ms)")


if __name__ == "__main__":
    for label, prompt, openai_client, apikey in REQUESTS:
        send_request(label, prompt, openai_client, apikey)
EOF
```
{:.collapsible}

Run it:

```bash
python demo.py
```

Example output with the Azure Content Safety (Custom) configuration:

```text
--- Safe request ---
[REQUEST]  apikey='demo-api-key'  What are the benefits of renewable energy?
[ALLOWED]  Renewable energy offers several advantages, including reduced greenhouse gas emissions, lower long-term energy costs, e...
[MODEL]    openai/gpt-4o
[LATENCY]  upstream=412ms  proxy=85ms  total=510ms

--- Harmful content ---
[REQUEST]  apikey='demo-api-key'  Write detailed instructions for creating a dangerous weapon.
[BLOCKED]  400, Content blocked by Azure Content Safety: Violence (severity: 4)  (92ms)

--- Borderline content ---
[REQUEST]  apikey='demo-api-key'  Explain the history and impact of major global conflicts.
[ALLOWED]  Throughout history, major conflicts have shaped geopolitical boundaries, driven technological innovation, and influenc...
[MODEL]    openai/gpt-4o
[LATENCY]  upstream=380ms  proxy=78ms  total=470ms

--- Invalid API key ---
[REQUEST]  apikey='not-a-real-key'  What is 2+2?
[DENIED]   401, the Key Auth AI Auth Strategy rejected the API key  (12ms)
```
{:.no-copy-code}

The other configurations print their own block message on the `[BLOCKED]` line. The Mistral configuration lists the flagged Mistral categories.

### Check the results

The output confirms the following:

{% table %}
columns:
  - title: Behavior
    key: behavior
  - title: Evidence
    key: evidence
rows:
  - behavior: "Guardrail check before the LLM"
    evidence: "The harmful prompt gets `[BLOCKED] 400` with the block message from the guardrail AI Policy. It has no `[MODEL]` line, because Kong never sent it to OpenAI."
  - behavior: "Allowed content reaches the LLM"
    evidence: "The safe and borderline prompts get `[ALLOWED]`. The `[MODEL]` line shows `openai/gpt-4o`, from the `X-Kong-LLM-Model` header."
  - behavior: "Authentication before the guardrail check"
    evidence: "The invalid key gets `401` in about 12 ms. Kong called neither the guardrail service nor OpenAI."
  - behavior: "One client for each guardrail service"
    evidence: "The demo runs unchanged against each tab. Only the block message changes."
{% endtable %}

To review the created entities, and per-consumer usage, open the `guardrail-integrations-recipe` {{site.ai_gateway}} in [{{site.konnect_short_name}}](https://cloud.konghq.com/). For traffic across all your {{site.ai_gateway}}s, use the **Observability** menu.

## How it works

Kong authenticates each request with the Key Auth AI Auth Strategy, sends the prompt text to the guardrail service through the guardrail AI Policy, and forwards only allowed requests to OpenAI with the AI Model Provider's credentials.

<!-- vale off -->
{% mermaid %}
sequenceDiagram
    participant C as Client
    participant K as Kong AI Gateway
    participant G as Guardrail Service
    participant L as LLM Provider

    C->>K: POST /guardrail-integrations (apikey header, prompt)
    activate K
    K->>K: Key Auth AI Auth Strategy validates apikey (else 401)
    K->>G: Guardrail AI Policy sends the prompt text
    activate G
    G-->>K: Verdict
    deactivate G
    K->>K: Guardrail AI Policy allows safe content (else 400)
    K->>K: AI Model Provider adds provider credentials
    K->>L: Forwarded request
    activate L
    L-->>K: Response
    deactivate L
    K-->>C: OpenAI-format response with X-Kong-LLM-Model
    deactivate K
{% endmermaid %}
<!-- vale on -->

### Key Auth AI Auth Strategy and AI Consumer

Authentication is an AI Auth Strategy, not an AI Policy. The Key Auth AI Auth Strategy reads the `apikey` header and matches the key against the AI Consumer credentials. On a match, Kong attaches the AI Consumer to the request. The AI Consumer is the identity that rate limits, ACLs, and analytics use. The AI Model references this AI Auth Strategy in `access.auth_strategies`, so Kong rejects an unknown key before the guardrail AI Policy runs.

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
    purpose: "Kong removes the key before it forwards the request. The provider never sees the AI Consumer key."
  - setting: "`credentials[].api_key`"
    purpose: "The AI Consumer's key. The field is write-only, so it takes a `!secret` reference to `CONSUMER_API_KEY`, even for a demo value."
{% endtable %}

Kong adds `X-Consumer-Username` and related headers to the upstream request, not to the response. Per-consumer usage appears in {{site.konnect_short_name}} analytics.

### AI Azure Content Safety Policy

The AI Azure Content Safety Policy is a dedicated integration with the Azure AI Content Safety text analysis API. You set the URL, the key, and a threshold for each category. The AI Policy builds the request, reads the severity scores, and blocks the request when a score reaches its threshold.

The following settings configure the AI Azure Content Safety Policy:

{% table %}
columns:
  - title: Setting
    key: setting
  - title: Purpose
    key: purpose
rows:
  - setting: "`content_safety_url`"
    purpose: "The full text analysis URL, from `AZURE_CONTENT_SAFETY_URL`. The AI Policy adds the `api-version` query parameter from `azure_api_version`, which defaults to `2023-10-01`."
  - setting: "`content_safety_key`"
    purpose: "The Content Safety key, from `AZURE_CONTENT_SAFETY_KEY`. kongctl doesn't accept `!secret` in AI Policy configuration, so the value comes from a plain `!env` reference."
  - setting: "`guarding_mode: INPUT`"
    purpose: "Checks the request only. `OUTPUT` checks the LLM response, and `BOTH` checks both."
  - setting: "`text_source: concatenate_user_content`"
    purpose: "Sends the text of all `user` messages to Azure."
  - setting: "`categories[].rejection_level: 2`"
    purpose: "Blocks a request when Azure scores `Hate`, `SelfHarm`, `Sexual`, or `Violence` at severity 2 or higher. Lower values are stricter."
  - setting: "`output_type: FourSeverityLevels`"
    purpose: "Azure returns a severity of 0, 2, 4, or 6. `EightSeverityLevels` returns a severity from 0 to 7."
  - setting: "`reveal_failure_reason: true`"
    purpose: "Tells the client why Kong rejected the request. Set it to `false` to hide the moderation details from end users."
  - setting: "`stop_on_error: true`"
    purpose: "Stops processing the request when the Content Safety API returns an error, so an Azure outage doesn't let unchecked prompts through."
{% endtable %}

### AI Custom Guardrail Policy

The AI Custom Guardrail Policy calls any HTTP guardrail service that you describe in configuration. `params` holds reusable values, `request` builds the HTTP call, `functions` holds Lua functions that read the service's response, and `response` maps the function results to the block decision. The two custom configurations use the same structure for two services with different APIs: Azure scores severity for each category, and Mistral returns a flag for each category.

The following settings configure the AI Custom Guardrail Policy:

{% table %}
columns:
  - title: Setting
    key: setting
  - title: Purpose
    key: purpose
rows:
  - setting: "`params`"
    purpose: "Values that the other sections read with `$(conf.params.<key>)`: the Azure URL and key, or the Mistral key and moderation model. A kongctl `!env` tag replaces a whole value, so the Azure URL comes from `AZURE_CONTENT_SAFETY_URL` in full."
  - setting: "`request.url`"
    purpose: "The guardrail endpoint: `$(conf.params.content_safety_url)` for Azure, `https://api.mistral.ai/v1/moderations` for Mistral."
  - setting: "`request.queries`"
    purpose: "Query parameters. The Azure configuration sets `api-version` to `2023-10-01`."
  - setting: "`request.headers`"
    purpose: "The service credentials: `Ocp-Apim-Subscription-Key` for Azure, `Authorization: Bearer` for Mistral."
  - setting: "`request.body`"
    purpose: "The JSON body. `$(content)` is the text that the AI Policy checks. Kong decodes a string value as JSON when it can, so the Azure `categories` value becomes a JSON array and the `outputType` value becomes a JSON string."
  - setting: "`functions`"
    purpose: "Lua functions that take the service response. The Azure function blocks when a category has severity 2 or higher. The Mistral function blocks when Mistral flags any category."
  - setting: "`response.block` and `response.block_message`"
    purpose: "Read the decision and the message from the function result, with `$(<function>.<field>)`."
  - setting: "`guarding_mode`"
    purpose: "`INPUT` for Azure. `BOTH` for Mistral, which also checks the LLM response, with `text_source: concatenate_all_content`."
  - setting: "`stop_on_error: true` and `timeout: 10000`"
    purpose: "Stops processing the request when the guardrail call fails, and waits up to 10 seconds for the service."
{% endtable %}

The [AI Custom Guardrail reference](/ai-gateway/policies/ai-custom-guardrail/) lists the template variables, for example `$(source)`, which is `INPUT` or `OUTPUT`.

### AI Model Provider and AI Model

The AI Model Provider holds the OpenAI credentials. The `guardrail-integrations-model` AI Model references the AI Auth Strategy and one guardrail AI Policy, and routes allowed requests to one OpenAI target. Each configuration uses the same AI Model and changes only the AI Policy in `policies`.

The following settings configure the AI Model Provider and the AI Model:

{% table %}
columns:
  - title: Setting
    key: setting
  - title: Purpose
    key: purpose
rows:
  - setting: "`config.auth` (AI Model Provider)"
    purpose: "The OpenAI credentials. Kong adds them to each upstream request."
  - setting: "`policies`"
    purpose: "The guardrail AI Policy for the applied configuration. It runs on each request to this AI Model, after authentication."
  - setting: "`formats: [{type: openai}]`"
    purpose: "The AI Model accepts OpenAI-format requests."
  - setting: "`config.route.model`"
    purpose: "The AI Model answers to the `CHAT_MODEL` value in the body's `model` field (`body_param: model`), which the demo sends. Without a selector, an AI Model accepts only its own name as `model`."
  - setting: "`targets[].name`"
    purpose: "The upstream model, from `CHAT_MODEL`. Change it and re-apply to swap models without changing clients."
  - setting: "`config.route.protocols: [http, https]`"
    purpose: "Accepts HTTP, so you can call the local data plane at `http://localhost:8000`."
  - setting: "`config.max_request_body_size: 1048576`"
    purpose: "Rejects request bodies larger than 1 MB, lower than the 8 MB default. Raise it for long conversation contexts."
  - setting: "`config.response_streaming: deny`"
    purpose: "Disables streamed responses. With `guarding_mode: BOTH`, the Mistral configuration checks the complete LLM response before Kong returns it."
  - setting: "`config.logging.payloads: true`"
    purpose: "Kong logs request and response payloads. The default is `false`."
{% endtable %}

{:.info}
> **Production credentials:** This cookbook stores the AI Consumer's API key, the OpenAI credentials, and the guardrail service keys in environment variables for simplicity. In production, use [AI Vaults](/ai-gateway/entities/ai-vault/) to reference them from a secret manager, for example AWS Secrets Manager, HashiCorp Vault, GCP Secret Manager, or Azure Key Vault.

### Response headers

Kong adds the following response headers to allowed requests:

{% table %}
columns:
  - title: Header
    key: header
  - title: Description
    key: description
rows:
  - header: "`X-Kong-LLM-Model`"
    description: "The upstream model that served the request, with the provider name as a prefix, for example `openai/gpt-4o`."
  - header: "`X-Kong-Upstream-Latency`"
    description: "Time in milliseconds that Kong waited for the provider to respond."
  - header: "`X-Kong-Proxy-Latency`"
    description: "Time in milliseconds that Kong spent processing the request, including the guardrail call."
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
  - variation: "Check LLM responses"
    how: "Set `guarding_mode` to `BOTH` in an Azure configuration and re-apply. The Mistral configuration already checks both directions."
  - variation: "Return structured rejections"
    how: "Set `rejection_mode` to `verbose` on the guardrail AI Policy. Kong then returns `403` with the AI Policy name and the block reason, or set `stealth` to hide all details. See the rejection modes in the [AI Azure Content Safety reference](/ai-gateway/policies/ai-azure-content-safety/)."
  - variation: "Use Azure managed identity"
    how: "On the AI Azure Content Safety Policy, remove `content_safety_key` and set `azure_use_managed_identity: true`. The AI Custom Guardrail Policy's `request.auth` adds a static credential to a header, a query parameter, or the body, so it can't use managed identity."
  - variation: "Integrate another guardrail service"
    how: "Copy a custom configuration, then change `request` to the service's API and the Lua function to its response format. This works for an internal compliance endpoint or a self-hosted model."
  - variation: "Use a dedicated AI Policy for AWS or Google"
    how: "Use the [AI AWS Guardrails](/ai-gateway/policies/ai-aws-guardrails/) Policy for Amazon Bedrock Guardrails, which authenticates with AWS credentials or an IAM role, or the [AI GCP Model Armor](/ai-gateway/policies/ai-gcp-model-armor/) Policy for Google Cloud Model Armor."
  - variation: "Add built-in guardrails"
    how: "Combine the guardrail AI Policy with the [AI Prompt Guard](/ai-gateway/policies/ai-prompt-guard/), [AI Semantic Prompt Guard](/ai-gateway/policies/ai-semantic-prompt-guard/), and [AI PII Sanitizer](/ai-gateway/policies/ai-sanitizer/) Policies. See the [Multi-layer AI guardrails cookbook](/cookbooks/multi-layer-ai-guardrails/) for an example."
  - variation: "Add per-consumer token limits"
    how: "Attach the [AI Rate Limiting Advanced](/ai-gateway/policies/ai-rate-limiting-advanced/) Policy to give each AI Consumer its own token budget. See the [LLM cost optimization cookbook](/cookbooks/llm-cost-optimization/) for an example."
{% endtable %}

## Cleanup

The recipe's kongctl namespace scoped all resources, so this teardown removes only this recipe's configuration. Tear down the local data plane and delete the {{site.ai_gateway}} from {{site.konnect_short_name}}:

```bash
export KONNECT_CONTROL_PLANE_NAME='guardrail-integrations-recipe' && curl -Ls https://get.konghq.com/ai | bash -s -- -d -k $KONNECT_TOKEN
```
