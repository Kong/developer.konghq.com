---
title: Model-Based Routing
description: Dynamically route requests across OpenAI and AWS Bedrock based on prompt complexity analysis.
url: "/cookbooks/model-based-routing/"
content_type: cookbook
layout: cookbook
products:
  - ai-gateway
tools:
  - deck
canonical: true
works_on:
  - konnect
min_version:
  gateway: '3.14'
categories:
  - llm
  - cost-optimization
featured: true
popular: false

# Machine-readable fields for AI agent setup
plugins:
  - key-auth
  - ai-prompt-decorator
  - ai-proxy-advanced
  - datakit
requires_embeddings: false
providers:
  - openai
  - bedrock

hint: "Konnect account, decK, OpenAI API key and AWS credentials"
prereqs:
  skip_product: true
  skip_tool: true
  inline:
    - title: "{{site.konnect_product_name}}"
      content: |
        This tutorial uses {{site.konnect_product_name}}. The [quickstart script](https://get.konghq.com/quickstart) provisions a recipe-scoped Control Plane and local Data Plane.

        1. Create a new personal access token by opening the [Konnect PAT page](https://cloud.konghq.com/global/account/tokens) and selecting **Generate Token**.
        1. Export your token. The same token is reused later for deck commands:

           ```bash
           export KONNECT_TOKEN='YOUR_KONNECT_PAT'
           ```

        1. Set the recipe-scoped Control Plane name and run the quickstart script:

           ```bash
           export KONNECT_CONTROL_PLANE_NAME='model-based-routing-recipe'
           curl -Ls https://get.konghq.com/quickstart | bash -s -- -k $KONNECT_TOKEN --deck-output
           ```

           This provisions a Konnect Control Plane named `model-based-routing-recipe`, a local Data Plane connected to it, and prints `export` lines for the rest of the session vars. Paste those into your shell when prompted.

    - title: decK
      content: |
        This tutorial uses [decK](/deck/) to manage Kong configuration.

        1. Install **decK** version 1.43 or later from [docs.konghq.com/deck](https://docs.konghq.com/deck/).
        1. Verify it's installed:

           ```bash
           deck version
           ```

    - title: AI Credentials
      content: |
        This tutorial uses both OpenAI (for model selection and fast-tier routing) and AWS Bedrock (for smart-tier routing with Claude):

        1. **OpenAI:** [Create an account](https://auth.openai.com/create-account) and [get an API key](https://platform.openai.com/api-keys).
        2. **AWS Bedrock:** [Enable Claude models](https://docs.aws.amazon.com/bedrock/latest/userguide/model-access.html) in your AWS account and [create IAM credentials](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_access-keys.html).
        3. Export credentials:

           ```sh
           export DECK_OPENAI_TOKEN='Bearer sk-YOUR-KEY'
           export DECK_AWS_ACCESS_KEY_ID='YOUR-AWS-ACCESS-KEY'
           export DECK_AWS_SECRET_ACCESS_KEY='YOUR-AWS-SECRET-KEY'
           export DECK_AWS_REGION='us-east-1'
           ```
overview: |
  This recipe demonstrates intelligent cross-provider routing where {{site.ai_gateway_name}} analyzes each prompt and dynamically routes it to the optimal provider based on complexity. Simple prompts are routed to OpenAI for speed and cost efficiency, while complex tasks requiring deep reasoning are routed to AWS Bedrock (Claude).

  By the end of this tutorial, you'll have a running system that optimizes both cost and quality by matching workload complexity to the right provider.
---

## The problem

LLM applications face a fundamental tradeoff between cost, speed, and capability across providers:

- **Single-provider lock-in:** Routing all traffic to one provider limits your ability to optimize per-request. OpenAI excels at fast, simple tasks but costs more for deep reasoning. AWS Bedrock (hosting Claude) excels at complex reasoning but is overkill for greetings or basic questions.
- **Manual provider selection:** Requiring developers to hardcode provider choice per endpoint or forcing end users to pick providers in a UI adds friction, leads to misconfiguration, and doesn't adapt as prompts evolve.
- **Over-provisioning with complex models:** Routing everything to Claude Opus or GPT-4 wastes money on simple tasks. Organizations report 60-80% of their LLM costs come from requests that could have been served by cheaper alternatives.
- **Static routing rules:** Keyword-based routing (`if prompt.contains("code")`) breaks down quickly. Real prompts don't follow templates, and maintaining brittle rule sets across providers becomes unmaintainable.
- **No cost-per-request optimization:** Without dynamic routing, teams either overspend for consistency or underspend and accept quality degradation. There's no middle ground that optimizes each request individually.

Teams need a system that analyzes each prompt in real time, routes it to the right provider, and learns from patterns to minimize redundant analysis.

## The solution

{{site.ai_gateway_name}} solves this by placing an intelligent router between your application and multiple LLM providers. Every incoming request flows through a model selection stage that analyzes prompt complexity and returns a provider recommendation, which {{site.base_gateway}} then uses to dispatch the request to either OpenAI (fast tier) or AWS Bedrock (smart tier).

The solution uses two Routes working in tandem:

1. **Model selection Route:** Receives prompts, analyzes complexity via OpenAI o3-mini, and returns a tier recommendation ("fast" or "smart").

2. **Default LLM Route:** Your application's main chat endpoint. The Datakit plugin intercepts requests, calls the model selection Route, extracts the tier recommendation, modifies the request body to specify the recommended tier, and forwards it to the AI Proxy Advanced plugin. The plugin has two targets — one for OpenAI (fast tier) and one for AWS Bedrock (smart tier) — and routes based on the tier field.

This architecture provides:

- **Zero application changes:** Your client code sends standard OpenAI SDK requests. All routing logic lives in {{site.base_gateway}}.
- **Request-level optimization:** Every prompt is individually analyzed and routed to the optimal provider based on its actual complexity, not static rules.
- **Best-of-breed per tier:** Use OpenAI for speed on simple tasks, AWS Bedrock (Claude) for deep reasoning on complex ones.
- **Transparent observability:** {{site.konnect_product_name}} Analytics shows which provider each request used and per-provider token consumption.

<!-- vale off -->
{% mermaid %}
sequenceDiagram
    participant Client
    participant Kong as Kong AI Gateway
    participant Model Selector as Model Selection Route<br/>(OpenAI o3-mini)
    participant OpenAI
    participant Bedrock as AWS Bedrock<br/>(Claude)

    Client->>Kong: POST /chat (with prompt)
    Note over Kong: DataKit plugin intercepts

    Kong->>Model Selector: Call /model-selection (with prompt)
    Model Selector->>OpenAI: Analyze prompt complexity (o3-mini)
    OpenAI-->>Model Selector: Return tier recommendation
    Model Selector-->>Kong: Return tier ("fast" or "smart")
    Note over Kong: DataKit updates request body model field

    alt Fast Tier
        Kong->>OpenAI: Forward to OpenAI (simple prompt)
        OpenAI-->>Kong: Response
    else Smart Tier
        Kong->>Bedrock: Forward to AWS Bedrock (complex prompt)
        Bedrock-->>Kong: Response
    end

    Kong-->>Client: Response (with X-Kong-LLM-Model header)
{% endmermaid %}
<!-- vale on -->

{% table %}
columns:
  - title: "Component"
  - title: "Responsibility"
rows:
  - columns:
      - "Client application"
      - "Sends standard chat completion requests to `/chat`. No routing logic required."
  - columns:
      - "DataKit plugin (default-llm)"
      - "Extracts prompt, calls `/model-selection`, modifies request body with tier recommendation."
  - columns:
      - "Model selection Route"
      - "Analyzes prompt complexity using OpenAI o3-mini, returns `\"fast\"` or `\"smart\"`."
  - columns:
      - "AI Proxy Advanced (default-llm)"
      - "Routes to OpenAI (fast) or AWS Bedrock (smart) based on `model` field in request body. Handles provider auth and format translation."
{% endtable %}

## How it works

When a chat request arrives at the `/chat` Route, the DataKit plugin intercepts it before reaching the AI Proxy Advanced plugin. DataKit calls the `/model-selection` Route with the same prompt, receives a tier recommendation ("fast" or "smart"), and updates the original request body's `model` field to that value. The request then continues to AI Proxy Advanced, which matches the model field to one of its two targets via `model_alias` and routes to either OpenAI or AWS Bedrock.

The model selection Route has two plugins in sequence:

1. **AI Prompt Decorator** prepends a system message instructing OpenAI o3-mini to analyze the prompt and return only "fast" or "smart".
2. **AI Proxy Advanced** routes the analysis request to OpenAI o3-mini.

### Key Auth: API key authentication and Consumer mapping

The Key Auth plugin enforces authentication on both Routes using a shared `apikey` header. Without a valid API key, {{site.base_gateway}} returns `401 Unauthorized` before any LLM call. This prevents unauthenticated access to your provider credentials.

#### Configuration details

{%- raw %}
```yaml
- name: key-auth
  instance_name: model-selection-auth
  config:
    hide_credentials: true
    key_names:
      - apikey
```
{% endraw -%}
{:.no-copy-code}

- **`hide_credentials: true`:** Strips the `apikey` header before forwarding requests to the LLM provider, so API keys never leave {{site.base_gateway}}.
- **`key_names`:** Defines which header carries the key. The demo uses `apikey` via the OpenAI SDK's `default_headers` parameter.

The same Key Auth configuration applies to both the `model-selection` and `default-llm` Routes. The recipe defines one Consumer (`demo-consumer`) with key `demo-consumer-key` that authenticates to both.

When the DataKit plugin on the default-llm Route calls the model-selection Route internally, it extracts the `apikey` header from the incoming client request and forwards it, so the internal call also passes authentication.

For production deployments, use [{{site.base_gateway}} Vaults](/gateway/latest/kong-enterprise/secrets-management/) to store API keys:

{:.info}
> In production, store credentials in [{{site.base_gateway}} Vaults](/gateway/latest/kong-enterprise/secrets-management/) using {%raw%}`{vault://backend/key}`{%endraw%} references rather than environment variables. {{site.base_gateway}} supports HashiCorp Vault, AWS Secrets Manager, GCP Secret Manager, and the {{site.konnect_product_name}} Config Store.

### AI Prompt Decorator: Inject routing instructions

The [AI Prompt Decorator](/plugins/ai-prompt-decorator/) plugin prepends a hidden system message to the model selection Route, instructing OpenAI o3-mini to analyze the incoming prompt and return only one of two values: "fast" or "smart". This message is invisible to the end user — clients see only their original prompt, but the LLM receives the decorator message first.

The decorator establishes the classification rules that define what makes a task simple versus complex.

#### Configuration details

{%- raw %}
```yaml
- name: ai-prompt-decorator
  instance_name: model-selection-decorator
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

- **`llm_format: openai`:** Ensures the decorator uses OpenAI message structure.
- **`prompts.prepend`:** The system message is inserted at the beginning of the message array before the user's prompt. The LLM sees this instruction first, then the user's original message.

The decorator's classification rules can be tuned to fit your use case. For example, you might add "translation" to the fast category or "multi-step reasoning" to the smart category. The key is that the LLM's output is constrained to just "fast" or "smart", which the DataKit plugin parses cleanly.

### AI Proxy Advanced (model-selection): Analyze prompt complexity

The [AI Proxy Advanced](/plugins/ai-proxy-advanced/) plugin on the model-selection Route routes decorated prompts to OpenAI o3-mini for classification. This model is fast and cost-effective — the prompt decorator constrains the output to one word, so deep reasoning capability is not required.

#### Configuration details

{%- raw %}
```yaml
- name: ai-proxy-advanced
  instance_name: model-selection-proxy
  config:
    max_request_body_size: 5242880  # 5 MB
    response_streaming: deny
    targets:
      - route_type: llm/v1/chat
        auth:
          header_name: Authorization
          header_value: ${{ env "DECK_OPENAI_TOKEN" }}
        logging:
          log_statistics: true
          log_payloads: false
        model:
          provider: openai
          name: ${{ env "DECK_OPENAI_SELECTOR_SLM" }}
```
{% endraw -%}
{:.no-copy-code}

- **`max_request_body_size: 5242880`:** Allows prompts up to 5 MB. Model selection prompts are typically small (the decorator message plus the user's prompt), so this limit is generous.
- **`response_streaming: deny`:** The DataKit plugin needs the full response body to extract the tier decision, so streaming is disabled.
- **`logging.log_statistics: true`:** Logs token counts and latency for cost tracking. Set `log_payloads: true` in development to see request/response bodies, but never in production (exposes user prompts and tier decisions in logs).
- **`model.name`:** References `{% raw %}${{ env "DECK_OPENAI_SELECTOR_SLM" }}{% endraw %}`, which defaults to `o3-mini`.

The model responds with a single word ("fast" or "smart").

### Datakit: Route selection orchestration

The [Datakit](/plugins/datakit/) plugin on the default-llm Route orchestrates the model selection flow. It extracts the prompt from the client request, calls the `/model-selection` Route, parses the tier recommendation from the response, and modifies the request body's `model` field before the request reaches the AI Proxy Advanced plugin.

Datakit operates as a workflow engine with node-based processing. Each node performs one transformation, and nodes connect by referencing each other's outputs.

#### Configuration details

{%- raw %}
```yaml
- name: datakit
  instance_name: default-llm-router
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
        jq: '{apikey: (.apikey // .Apikey)}'

      - name: CALL_MODEL_SELECTOR
        type: call
        url: http://localhost:8000/model-selection
        method: POST
        inputs:
          body: EXTRACT_PROMPT.prompt_data
          headers: EXTRACT_AUTH.auth_header

      - name: EXTRACT_MODEL
        type: jq
        input: CALL_MODEL_SELECTOR.body
        output: tier
        jq: .choices[0].message.content | rtrimstr("\n") | ltrimstr("\"")

      - name: UPDATE_REQUEST
        type: jq
        inputs:
          original: request.body
          selected: EXTRACT_MODEL.tier
        output: modified_body
        jq: .original | .model = (.selected | gsub("\""; ""))

      - name: service_request
        inputs:
          body: UPDATE_REQUEST.modified_body
```
{% endraw -%}
{:.no-copy-code}

The workflow executes these nodes in dependency order:

1. **`EXTRACT_PROMPT`:** Extracts the `messages` array from the client request body. The `output: prompt_data` field makes the result available as `EXTRACT_PROMPT.prompt_data`.
2. **`EXTRACT_AUTH`:** Extracts the `apikey` header (case-insensitive) from the request. The `output: auth_header` field makes the result available as `EXTRACT_AUTH.auth_header` for forwarding to the model-selection Route.
3. **`CALL_MODEL_SELECTOR`:** Makes an HTTP POST to `http://localhost:8000/model-selection` with the extracted prompt and API key. This calls the model-selection Route as if it were an external API. The response body contains the tier recommendation in OpenAI chat completion format.
4. **`EXTRACT_MODEL`:** Parses the response body to extract the tier string. The jq filter `.choices[0].message.content` reads the first message's content, then `rtrimstr("\n")` and `ltrimstr("\"")` strip trailing newlines and leading quotes, yielding just "fast" or "smart". The result is stored as `EXTRACT_MODEL.tier`.
5. **`UPDATE_REQUEST`:** Merges the original request body with the selected tier, setting `.model` to the tier value. The result is stored as `UPDATE_REQUEST.modified_body`.
6. **`service_request`:** A reserved node name that modifies the upstream request. Setting `inputs.body` to `UPDATE_REQUEST.modified_body` replaces the request body with the modified version before proxying.

DataKit does not modify the response to the client. The AI Proxy Advanced plugin on the default-llm Route handles the response, including the `X-Kong-LLM-Model` header that shows which provider served the request.

### AI Proxy Advanced (default-llm): Cross-provider routing

The [AI Proxy Advanced](/plugins/ai-proxy-advanced/) plugin on the default-llm Route is configured with two targets — OpenAI (fast tier) and AWS Bedrock (smart tier) — each with a `model_alias` matching the tier names ("fast" and "smart"). When the request arrives from the DataKit plugin with `.model` set to "fast" or "smart", the plugin matches it to the corresponding target and routes to the appropriate provider.

#### Configuration details

{%- raw %}
```yaml
- name: ai-proxy-advanced
  instance_name: default-llm-proxy
  config:
    max_request_body_size: 10485760  # 10 MB
    response_streaming: allow
    targets:
      # Fast tier - OpenAI for simple prompts
      - route_type: llm/v1/chat
        auth:
          header_name: Authorization
          header_value: ${{ env "DECK_OPENAI_TOKEN" }}
        logging:
          log_statistics: true
          log_payloads: false
        model:
          model_alias: fast
          provider: openai
          name: ${{ env "DECK_OPENAI_FAST_MODEL" }}

      # Smart tier - AWS Bedrock (Claude) for complex prompts
      - route_type: llm/v1/chat
        auth:
          aws_access_key_id: ${{ env "DECK_AWS_ACCESS_KEY_ID" }}
          aws_secret_access_key: ${{ env "DECK_AWS_SECRET_ACCESS_KEY" }}
        logging:
          log_statistics: true
          log_payloads: false
        model:
          model_alias: smart
          provider: bedrock
          name: ${{ env "DECK_BEDROCK_SMART_MODEL" }}
          options:
            bedrock:
              aws_region: ${{ env "DECK_AWS_REGION" }}
```
{% endraw -%}
{:.no-copy-code}

- **`max_request_body_size: 10485760`:** Allows request bodies up to 10 MB, which accommodates large conversation histories or RAG-injected context.
- **`response_streaming: allow`:** Enables streaming responses for interactive chat applications. The client can receive tokens as they're generated.
- **`model.model_alias`:** Maps the tier name to this target. When the DataKit plugin sets `.model = "fast"`, the plugin routes to OpenAI. When `.model = "smart"`, it routes to AWS Bedrock.
- **Fast target (OpenAI):** Uses `{% raw %}${{ env "DECK_OPENAI_FAST_MODEL" }}{% endraw %}` (defaults to `gpt-4o-mini`) with Bearer token authentication.
- **Smart target (AWS Bedrock):** Uses `{% raw %}${{ env "DECK_BEDROCK_SMART_MODEL" }}{% endraw %}` (defaults to `anthropic.claude-3-5-sonnet-20241022-v2:0`) with AWS IAM credentials and region configuration.

The plugin adds an `X-Kong-LLM-Model` response header showing which model served the request. The demo script reads this header to confirm the provider routing decision.

## Apply the Kong configuration

Export your environment variables:

```bash
export DECK_OPENAI_SELECTOR_SLM='o3-mini'                # Model selection (SLM)
export DECK_OPENAI_FAST_MODEL='gpt-4o-mini'              # Fast tier
export DECK_BEDROCK_SMART_MODEL='anthropic.claude-3-5-sonnet-20241022-v2:0'  # Smart tier (Claude on Bedrock)

# Also export your provider credentials
export DECK_OPENAI_TOKEN='Bearer sk-...'
export DECK_AWS_ACCESS_KEY_ID='your-access-key-id'
export DECK_AWS_SECRET_ACCESS_KEY='your-secret-access-key'
export DECK_AWS_REGION='us-east-1'
```

Create a file named `multi-provider.yaml` with the configuration below, then sync it to your Control Plane using decK:

```bash
deck gateway sync recipes/model-based-routing/kong-config/deck/multi-provider.yaml \
  --konnect-token "${KONNECT_TOKEN}" \
  --konnect-control-plane-name "${KONNECT_CONTROL_PLANE_NAME}"
```
{: data-test-step="block" .collapsible }

The `multi-provider.yaml` file contents:

{%- raw %}

```yaml
_format_version: '3.0'
_info:
  select_tags:
    - model-based-routing-recipe

# Consumer for authentication
consumers:
  - username: demo-consumer
    keyauth_credentials:
      - key: demo-consumer-key

# Model selection service - analyzes prompts using OpenAI o3-mini
services:
  - name: model-selection
    url: http://httpbin.konghq.com/anything
    routes:
      - name: model-selection
        paths:
          - /model-selection
        protocols:
          - http
          - https
        methods:
          - POST
          - OPTIONS
        strip_path: true
    plugins:
      - name: key-auth
        instance_name: model-selection-auth
        config:
          hide_credentials: true
          key_names:
            - apikey

      - name: ai-prompt-decorator
        instance_name: model-selection-decorator
        config:
          llm_format: openai
          prompts:
            prepend:
              - role: system
                content: >
                  You are a model router. Analyze the user's prompt and recommend the most appropriate model tier.

                  Return ONLY ONE of these values:
                  - "fast" for simple tasks (greetings, basic questions, straightforward requests)
                  - "smart" for complex tasks (reasoning, analysis, coding, creative writing)

                  Respond with just the single word "fast" or "smart", nothing else.

      - name: ai-proxy-advanced
        instance_name: model-selection-proxy
        config:
          max_request_body_size: 5242880
          response_streaming: deny
          targets:
            - route_type: llm/v1/chat
              auth:
                header_name: Authorization
                header_value: ${{ env "DECK_OPENAI_TOKEN" }}
              logging:
                log_statistics: true
                log_payloads: false
              model:
                provider: openai
                name: ${{ env "DECK_OPENAI_SELECTOR_SLM" }}

# Default LLM service - routes to OpenAI (fast) or Anthropic (smart)
  - name: default-llm
    url: http://httpbin.konghq.com/anything
    routes:
      - name: default-llm
        paths:
          - /chat
        protocols:
          - http
          - https
        methods:
          - POST
          - OPTIONS
        strip_path: true
    plugins:
      - name: key-auth
        instance_name: default-llm-auth
        config:
          hide_credentials: true
          key_names:
            - apikey

      - name: datakit
        instance_name: default-llm-router
        ordering:
          before:
            access:
            - ai-proxy-advanced
        config:
          debug: true
          nodes:
            # Extract prompt messages for model selection
            - name: EXTRACT_PROMPT
              type: jq
              input: request.body
              jq: |
                ({"messages": .messages})

            # Extract API key from request headers for internal call
            - name: EXTRACT_AUTH
              type: jq
              input: request.headers
              output: service_request.headers
              jq: |
                {
                  apikey: (.apikey // .Apikey // .APIKey)
                }


            # Call model-selection route to get recommendation
            - name: CALL_MODEL_SELECTOR
              type: call
              url: http://localhost:8000/model-selection
              method: POST
              inputs:
                body: EXTRACT_PROMPT
                headers: EXTRACT_AUTH

            # Extract recommended tier from response
            - name: EXTRACT_MODEL
              type: jq
              inputs:
                body: CALL_MODEL_SELECTOR.body
              jq: |
                .body.choices[0].message.content | gsub("^\\s+|\\s+$"; "")


            # Update request body with recommended tier
            - name: UPDATE_REQUEST
              type: jq
              inputs:
                original: request.body
                selected: EXTRACT_MODEL
              output: service_request.body
              jq: |
                . as $in | $in.original | .model = $in.selected

      - name: ai-proxy-advanced
        instance_name: default-llm-proxy
        config:
          max_request_body_size: 10485760
          response_streaming: allow
          targets:
            # Fast tier - OpenAI for simple prompts
            - route_type: llm/v1/chat
              auth:
                header_name: Authorization
                header_value: ${{ env "DECK_OPENAI_TOKEN" }}
              logging:
                log_statistics: true
                log_payloads: false
              model:
                model_alias: fast
                provider: openai
                name: ${{ env "DECK_OPENAI_FAST_MODEL" }}

            # Smart tier - AWS Bedrock (Claude) for complex prompts
            - route_type: llm/v1/chat
              auth:
                aws_access_key_id: ${{ env "DECK_AWS_ACCESS_KEY_ID" }}
                aws_secret_access_key: ${{ env "DECK_AWS_SECRET_ACCESS_KEY" }}
              logging:
                log_statistics: true
                log_payloads: false
              model:
                model_alias: smart
                provider: bedrock
                name: ${{ env "DECK_BEDROCK_SMART_MODEL" }}
                options:
                  bedrock:
                    aws_region: ${{ env "DECK_AWS_REGION" }}

            # should never hit this target, but we need to satisfy the model requirement in the request
            - route_type: llm/v1/chat
              auth:
                header_name: Authorization
                header_value: ${{ env "DECK_OPENAI_TOKEN" }}
              logging:
                log_statistics: true
                log_payloads: false
              model:
                provider: openai
                name: ${{ env "DECK_OPENAI_SELECTOR_SLM" }}
```
{% endraw -%}
{:.no-copy-code}

## Try it out

Test the model-based routing with curl by sending requests with varying prompt complexity. Simple prompts like "Hi there!" are routed to OpenAI's fast tier, while complex prompts like "Explain quantum mechanics" are routed to AWS Bedrock's smart tier (Claude).

Create test prompt files:

```bash
cat <<'EOF' > simple_prompt.json
{
  "model": "fast",
  "messages": [
    {
      "role": "user",
      "content": "Hi there! What's 2 + 2?"
    }
  ],
  "max_tokens": 100
}
EOF
```

```bash
cat <<'EOF' > complex_prompt.json
{
  "model": "fast",
  "messages": [
    {
      "role": "user",
      "content": "Write a Python function to implement binary search with detailed comments explaining the algorithm, including time complexity analysis and edge case handling."
    }
  ],
  "max_tokens": 500
}
EOF
```

### Test simple prompt routing

Send a simple prompt (should route to OpenAI fast tier):

```bash
curl -X POST http://localhost:8000/chat \
  -H "Content-Type: application/json" \
  -H "apikey: demo-consumer-key" \
  -d @simple_prompt.json \
  -i
```

Check the `X-Kong-LLM-Model` response header - it should show `gpt-4o-mini`, confirming routing to the OpenAI fast tier.

### Test complex prompt routing

Send a complex prompt (should route to AWS Bedrock smart tier):

```bash
curl -X POST http://localhost:8000/chat \
  -H "Content-Type: application/json" \
  -H "apikey: demo-consumer-key" \
  -d @complex_prompt.json \
  -i
```

Check the `X-Kong-LLM-Model` response header - it should show the model you configured for the smart tier (for example, `anthropic.claude-3-5-sonnet-20241022-v2:0`), confirming routing to the AWS Bedrock smart tier.

Example response for complex prompt (truncated):

```json
HTTP/1.1 200 OK
X-Kong-LLM-Model: global.anthropic.claude-sonnet-4-5-20250929-v1:0
Content-Type: application/json

{
  "id": "msg_01...",
  "object": "chat.completion",
  "created": 1234567890,
  "model": "global.anthropic.claude-sonnet-4-5-20250929-v1:0",
  "choices": [
    {
      "index": 0,
      "message": {
        "role": "assistant",
        "content": "Here's a Python implementation of binary search with detailed comments:\n\n```python\ndef binary_search(arr, target):\n    \"\"\"\n    Performs binary search on a sorted array.\n    Time Complexity: O(log n)\n    Space Complexity: O(1)\n    ...(response continues)"
      },
      "finish_reason": "stop"
    }
  ]
}
```
{:.no-copy-code}

### What happened

1. **Simple prompt routing:** The simple prompt ("Hi there! What's 2 + 2?") routes to OpenAI's fast tier. The Datakit plugin calls the model-selection Route, OpenAI o3-mini analyzes the prompt complexity, returns "fast", Datakit updates the request body, and AI Proxy Advanced routes to the OpenAI target. The `X-Kong-LLM-Model` header shows `gpt-4o-mini`.

2. **Complex prompt routing:** The complex prompt (binary search implementation) routes to AWS Bedrock's smart tier. The model-selection LLM recognizes this as a reasoning-heavy task and returns "smart", which Datakit forwards to the AWS Bedrock target (Claude). The `X-Kong-LLM-Model` header shows `anthropic.claude-3-5-sonnet-20241022-v2:0`.

3. **`X-Kong-LLM-Model` header:** Every response includes this header showing which model served the request. In production, this header enables per-request observability — your application can log it for cost attribution or debugging.

The cross-provider routing combines OpenAI's speed and cost efficiency on simple tasks with AWS Bedrock's (Claude) deep reasoning capability on complex ones, automatically optimizing each request.

### Explore in Konnect

Open [{{site.konnect_product_name}}](https://cloud.konghq.com/) and navigate to **API Gateway** → **Gateways** → **`model-based-routing-recipe`**. The recipe created the following resources on this Control Plane:

- **Gateway services** → **`model-selection`**: the model selection analysis service. Its detail page has tabs for Configuration, Routes, Plugins, and Analytics. The Analytics tab shows request counts and average latency for the model selection Route.
  - **Routes** tab: the `/model-selection` Route, which receives prompts from the DataKit plugin and returns tier recommendations.
  - **Plugins** tab: Key Auth (authentication), AI Prompt Decorator (classification instructions), and AI Proxy Advanced (OpenAI o3-mini routing).
- **Gateway services** → **`default-llm`**: the main chat endpoint your clients call.
  - **Routes** tab: the `/chat` Route, scoped by the `model-based-routing-recipe` `select_tags`.
  - **Plugins** tab: Key Auth (authentication), DataKit (model selection orchestration), and AI Proxy Advanced (cross-provider routing).
- **Consumers** → **`demo-consumer`**: the Consumer that authenticates requests to both Routes using the API key `demo-consumer-key`.

The **Analytics** tab on each Gateway service shows analytics tied to that service, including request counts, error rates, per-provider latency, and token consumption. For a deeper dive into these analytics, plus platform-wide analytics across every Control Plane, head to the **Observability** L1 menu in {{site.konnect_product_name}}.

## Variations and next steps

Once the base recipe is running, consider these extensions:

- **Add more providers:** Add Google Gemini or Azure OpenAI as additional targets on the default-llm Route. Extend the model-selection prompt to return "fast", "smart", or "experimental" tiers, each mapped to a different provider.
- **Tune classification rules:** The AI Prompt Decorator defines what makes a task simple versus complex. Adjust the system message to reflect your application's workload patterns (e.g., classify "translation" as fast, "multi-step reasoning" as smart).
- **Provider failover:** Configure multiple providers per tier (e.g., both OpenAI and Azure OpenAI for the fast tier). Use `balancer.algorithm: priority` to fail over if one provider is down. See the [AI Proxy Advanced reference](/plugins/ai-proxy-advanced/reference/) for balancer configuration.
- **Cost tracking per Consumer:** Attach the [AI Rate Limiting Advanced](/plugins/ai-rate-limiting-advanced/) plugin with token quotas per Consumer. This lets you enforce budgets and observe per-user cost distribution in {{site.konnect_product_name}} Analytics.
- **Langfuse observability:** Attach the [OpenTelemetry](/plugins/opentelemetry/) plugin to export traces to Langfuse, Jaeger, or another OTLP backend. This gives you end-to-end visibility into model selection latency and LLM performance. See the [voice-ai-observability recipe](/cookbooks/voice-ai-observability/) for a worked example.

## Cleanup

The recipe's `select_tags` scoped all resources, so this teardown removes only this recipe's configuration. Tear down the local Data Plane and delete the Control Plane from {{site.konnect_product_name}}:

```bash
export KONNECT_CONTROL_PLANE_NAME='model-based-routing-recipe' && curl -Ls https://get.konghq.com/quickstart | bash -s -- -d -k $KONNECT_TOKEN
```
