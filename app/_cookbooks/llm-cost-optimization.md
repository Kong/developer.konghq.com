---
title: LLM Cost Optimization
description: Reduce LLM infrastructure costs using semantic routing, caching, prompt compression, and tiered cost-based rate limiting.
url: "/cookbooks/llm-cost-optimization/"
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
  - cost-optimization
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
           export KONNECT_CONTROL_PLANE_NAME='llm-cost-optimization-recipe'
           curl -Ls https://get.konghq.com/ai | bash -s -- -k $KONNECT_TOKEN
           ```

           This provisions an {{site.ai_gateway}} named `llm-cost-optimization-recipe`, a local data plane connected to it, and prints `export` lines for the rest of the session vars, including `AI_GATEWAY_ID`. Paste those into your shell when prompted.
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
        Pick the provider you want to route to and export its credentials. The same provider serves chat and embeddings. The provider's tab in [Apply the Kong configuration](#apply-the-kong-configuration) reads these variables.

        {% navtabs "Providers" %}
        {% navtab "OpenAI" %}
        1. [Create an OpenAI account](https://auth.openai.com/create-account).
        1. [Get an API key](https://platform.openai.com/api-keys).
        1. Export the API key:

           ```sh
           export OPENAI_TOKEN='Bearer sk-YOUR-KEY'
           ```
        {% endnavtab %}
        {% navtab "AWS Bedrock" %}
        1. Get an AWS account with [Bedrock model access](https://docs.aws.amazon.com/bedrock/latest/userguide/model-access.html) enabled for two chat models and for Amazon Titan Text Embeddings V2.
        1. Export your AWS credentials and region:

           ```sh
           export AWS_ACCESS_KEY_ID='your-access-key'
           export AWS_SECRET_ACCESS_KEY='your-secret-key'
           export AWS_REGION='us-east-1'
           ```
        {% endnavtab %}
        {% endnavtabs %}
    - title: Redis Stack
      icon_url: /assets/icons/redis.svg
      content: |
        The [AI Semantic Cache](/ai-gateway/policies/ai-semantic-cache/) Policy stores cached responses in Redis, and the AI Model's semantic balancer stores the embeddings of its target descriptions there.

        1. Run [Redis Stack](https://redis.io/docs/latest/) locally:

           ```bash
           docker run -d --name redis-stack -p 6379:6379 redis/redis-stack-server:latest
           ```

        1. Export the host so the data plane container can reach Redis:

           ```sh
           export REDIS_HOST='host.docker.internal'
           ```
    - title: LLMLingua compressor service
      content: |
        The [AI Prompt Compressor](/ai-gateway/policies/ai-prompt-compressor/) Policy sends prompts to Kong's [LLMLingua compressor service](/ai-gateway/policies/ai-prompt-compressor/#llmlingua-compressor-service). Kong publishes the service as a public Docker image.

        1. Run the service locally. The service loads its model on the first request, so the first compression takes a few seconds:

           ```bash
           docker run -d --name ai-compress-service -p 8080:8080 kong/ai-compress-service:v0.0.6
           ```

        1. Export the URL so the data plane container can reach the service:

           ```sh
           export COMPRESSOR_URL='http://host.docker.internal:8080'
           ```
    - title: Python 3.11+
      icon_url: /assets/icons/python.svg
      content: |
        The demo script requires Python 3.11 or later. Set up an isolated environment:

        ```bash
        python3 -m venv .venv
        source .venv/bin/activate
        pip install 'openai>=1.0.0' 'tiktoken>=0.7.0'
        ```
overview: |
  Cut LLM spend on one {{site.ai_gateway_name}} endpoint with four techniques that need no application code changes. You'll set up:

  * Semantic routing that sends simple prompts to a cheap model and complex prompts to a capable one
  * A semantic cache that answers similar questions without an LLM call
  * Prompt compression that removes low-value tokens before the LLM bills for them
  * Dollar budgets for two AI Consumer tiers, enforced with cost-based rate limiting
---

## What this cookbook solves

Most teams send every request to one model and track cost only on the provider invoice, which causes the following problems:

{% table %}
columns:
  - title: Problem
    key: problem
  - title: Solution
    key: solution
rows:
  - problem: "Every prompt goes to the same model, so simple questions cost as much as complex tasks."
    solution: "The AI Model's semantic balancer compares each prompt with a description of each target, and sends simple prompts to the cheap target."
  - problem: "Users ask the same question in different words, and each wording is a new, billed LLM call."
    solution: "The [AI Semantic Cache](/ai-gateway/policies/ai-semantic-cache/) Policy returns the cached response for a similar prompt, with `X-Cache-Status: Hit` and no LLM call."
  - problem: "Long prompts with redundant text bill every token."
    solution: "The [AI Prompt Compressor](/ai-gateway/policies/ai-prompt-compressor/) Policy compresses long prompts with LLMLingua before the request reaches the provider."
  - problem: "Token limits don't map to money, because a token costs a different amount on each model."
    solution: "The [AI Rate Limiting Advanced](/ai-gateway/policies/ai-rate-limiting-advanced/) Policy counts the dollar cost of each request, from the prices set on each target."
  - problem: "Every application shares one budget, so a busy team can use up the spend of another."
    solution: "Two AI Consumer Groups each get their own dollar budget. The Key Auth AI Auth Strategy maps each API key to an AI Consumer in a tier, and rejects unknown keys with `401`."
{% endtable %}

## Try it out

Apply the configuration, then run a demo script that sends simple and complex prompts, a paraphrased question, a long prompt, one request from each tier, and one request with an invalid API key.

### Apply the Kong configuration

The configuration creates an AI Model Provider with your provider's credentials, a Key Auth AI Auth Strategy, two AI Consumers in two AI Consumer Groups, an AI Rate Limiting Advanced Policy for each AI Consumer Group, an AI Semantic Cache Policy, an AI Prompt Compressor Policy, and one AI Model with two targets and a semantic balancer. A kongctl namespace scopes every resource, so you can remove this configuration without affecting anything else on the same {{site.ai_gateway}}. See the [kongctl documentation](/kongctl/) for more on namespaces.

Adopt the quickstart {{site.ai_gateway}} into a kongctl namespace so that kongctl can manage it. Adoption adds the `KONGCTL-namespace` label to the {{site.ai_gateway}}:

```bash
kongctl adopt ai-gateway "${KONNECT_CONTROL_PLANE_NAME}" \
  --namespace "${KONNECT_CONTROL_PLANE_NAME}" \
  --pat "${KONNECT_TOKEN}"
```

Export the API keys of the two demo AI Consumers. `STANDARD_API_KEY` belongs to the standard tier, and `PREMIUM_API_KEY` to the premium tier. The credential's `api_key` field is write-only, so its value must come from an environment variable, even for a fixed demo key:

```bash
export STANDARD_API_KEY='standard-api-key'
export PREMIUM_API_KEY='premium-api-key'
```

Select your provider. Each tab exports `CHAT_MODEL_1`, the cheap model for general prompts, `CHAT_MODEL_2`, the capable model for complex prompts, and `EMBEDDINGS_MODEL`, then applies the configuration. Each tab's configuration sets the embedding dimensions, the routing threshold, and example prices for that tab's models. Provider credentials, the Redis host, and the compressor URL come from the prerequisites.

{% navtabs "Providers" %}
{% navtab "OpenAI" %}

Export the model env vars:

```bash
export CHAT_MODEL_1='gpt-4o-mini'
export CHAT_MODEL_2='gpt-4o'
export EMBEDDINGS_MODEL='text-embedding-3-small'
```

Apply the Kong configuration:

```bash
cat <<'EOF' > kong-recipe.yaml
_defaults:
  kongctl:
    namespace: llm-cost-optimization-recipe
ai_gateway_model_providers:
- ref: llm-cost-optimization-provider
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: llm-cost-optimization-provider
  display_name: llm-cost-optimization
  type: openai
  config:
    auth:
      type: basic
      headers:
      - name: Authorization
        value: !secret {source: !env 'OPENAI_TOKEN'}
ai_gateway_auth_strategies:
- ref: llm-cost-optimization-auth
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: llm-cost-optimization-auth
  display_name: llm-cost-optimization key auth
  type: key-auth
  config:
    key_names:
    - apikey
    hide_credentials: true
ai_gateway_consumers:
- ref: llm-cost-optimization-standard-consumer
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: llm-cost-optimization-standard-consumer
  display_name: llm-cost-optimization standard-tier consumer
  type: api-key
  credentials:
  - ref: llm-cost-optimization-standard-credential
    name: llm-cost-optimization-standard-credential
    display_name: llm-cost-optimization standard API key
    type: api-key
    api_key: !secret {source: !env 'STANDARD_API_KEY'}
- ref: llm-cost-optimization-premium-consumer
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: llm-cost-optimization-premium-consumer
  display_name: llm-cost-optimization premium-tier consumer
  type: api-key
  credentials:
  - ref: llm-cost-optimization-premium-credential
    name: llm-cost-optimization-premium-credential
    display_name: llm-cost-optimization premium API key
    type: api-key
    api_key: !secret {source: !env 'PREMIUM_API_KEY'}
ai_gateway_consumer_groups:
- ref: llm-cost-optimization-standard-tier
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: llm-cost-optimization-standard-tier
  display_name: llm-cost-optimization standard tier
  consumers:
  - llm-cost-optimization-standard-consumer
  policies:
  - llm-cost-optimization-standard-limit
- ref: llm-cost-optimization-premium-tier
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: llm-cost-optimization-premium-tier
  display_name: llm-cost-optimization premium tier
  consumers:
  - llm-cost-optimization-premium-consumer
  policies:
  - llm-cost-optimization-premium-limit
ai_gateway_policies:
- ref: llm-cost-optimization-compressor
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: llm-cost-optimization-compressor
  display_name: llm-cost-optimization prompt compressor
  type: ai-prompt-compressor
  config:
    compressor_type: rate
    compressor_url: !env 'COMPRESSOR_URL'
    stop_on_error: false
    compression_ranges:
    - min_tokens: 100
      max_tokens: 1000000
      value: 0.6
- ref: llm-cost-optimization-standard-limit
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: llm-cost-optimization-standard-limit
  display_name: llm-cost-optimization standard tier rate limit
  type: ai-rate-limiting-advanced
  config:
    policies:
    - window_type: sliding
      limits:
      - limit: 1
        window_size: 3600
    identifier: consumer-group
    tokens_count_strategy: cost
    strategy: local
- ref: llm-cost-optimization-premium-limit
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: llm-cost-optimization-premium-limit
  display_name: llm-cost-optimization premium tier rate limit
  type: ai-rate-limiting-advanced
  config:
    policies:
    - window_type: sliding
      limits:
      - limit: 5
        window_size: 3600
    identifier: consumer-group
    tokens_count_strategy: cost
    strategy: local
- ref: llm-cost-optimization-cache
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: llm-cost-optimization-cache
  display_name: llm-cost-optimization semantic cache
  type: ai-semantic-cache
  config:
    cache_ttl: 300
    message_countback: 1
    stop_on_failure: false
    embeddings:
      auth:
        header_name: Authorization
        header_value: !env 'OPENAI_TOKEN'
      model:
        provider: openai
        name: !env 'EMBEDDINGS_MODEL'
    vectordb:
      dimensions: 1536
      distance_metric: cosine
      strategy: redis
      threshold: 0.3
      redis:
        host: !env 'REDIS_HOST'
ai_gateway_models:
- ref: llm-cost-optimization-model
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: llm-cost-optimization-model
  display_name: llm-cost-optimization
  type: model
  formats:
  - type: openai
  capabilities:
  - generate
  access:
    auth_strategies:
    - llm-cost-optimization-auth
  policies:
  - llm-cost-optimization-cache
  - llm-cost-optimization-compressor
  config:
    max_request_body_size: 10485760
    response_streaming: allow
    logging:
      payloads: true
    route:
      paths:
      - /llm-cost-optimization
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
    balancer:
      algorithm: semantic
      embeddings:
        provider: llm-cost-optimization-provider
        name: !env 'EMBEDDINGS_MODEL'
        config:
          type: openai
      vectordb:
        type: redis
        dimensions: 1536
        distance_metric: cosine
        threshold: 0.75
        host: !env 'REDIS_HOST'
        port: 6379
        ssl: false
  targets:
  - name: !env 'CHAT_MODEL_1'
    provider: llm-cost-optimization-provider
    semantic_description: CATCHALL
    config:
      type: openai
      input_cost: 0.15
      output_cost: 0.6
  - name: !env 'CHAT_MODEL_2'
    provider: llm-cost-optimization-provider
    semantic_description: Software architecture, system design, and complex code generation.
    config:
      type: openai
      input_cost: 2.5
      output_cost: 10.0
EOF

kongctl apply -f kong-recipe.yaml -o text --auto-approve --pat "${KONNECT_TOKEN}"

rm -f kong-recipe.yaml
```
{: data-test-step="block" .collapsible }

{% endnavtab %}
{% navtab "AWS Bedrock" %}

Export the model env vars:

```bash
export CHAT_MODEL_1='amazon.nova-lite-v1:0'
export CHAT_MODEL_2='global.anthropic.claude-sonnet-4-5-20250929-v1:0'
export EMBEDDINGS_MODEL='amazon.titan-embed-text-v2:0'
```

Apply the Kong configuration:

```bash
cat <<'EOF' > kong-recipe.yaml
_defaults:
  kongctl:
    namespace: llm-cost-optimization-recipe
ai_gateway_model_providers:
- ref: llm-cost-optimization-provider
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: llm-cost-optimization-provider
  display_name: llm-cost-optimization
  type: bedrock
  config:
    auth:
      type: aws
      access_key_id: !env 'AWS_ACCESS_KEY_ID'
      secret_access_key: !secret {source: !env 'AWS_SECRET_ACCESS_KEY'}
ai_gateway_auth_strategies:
- ref: llm-cost-optimization-auth
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: llm-cost-optimization-auth
  display_name: llm-cost-optimization key auth
  type: key-auth
  config:
    key_names:
    - apikey
    hide_credentials: true
ai_gateway_consumers:
- ref: llm-cost-optimization-standard-consumer
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: llm-cost-optimization-standard-consumer
  display_name: llm-cost-optimization standard-tier consumer
  type: api-key
  credentials:
  - ref: llm-cost-optimization-standard-credential
    name: llm-cost-optimization-standard-credential
    display_name: llm-cost-optimization standard API key
    type: api-key
    api_key: !secret {source: !env 'STANDARD_API_KEY'}
- ref: llm-cost-optimization-premium-consumer
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: llm-cost-optimization-premium-consumer
  display_name: llm-cost-optimization premium-tier consumer
  type: api-key
  credentials:
  - ref: llm-cost-optimization-premium-credential
    name: llm-cost-optimization-premium-credential
    display_name: llm-cost-optimization premium API key
    type: api-key
    api_key: !secret {source: !env 'PREMIUM_API_KEY'}
ai_gateway_consumer_groups:
- ref: llm-cost-optimization-standard-tier
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: llm-cost-optimization-standard-tier
  display_name: llm-cost-optimization standard tier
  consumers:
  - llm-cost-optimization-standard-consumer
  policies:
  - llm-cost-optimization-standard-limit
- ref: llm-cost-optimization-premium-tier
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: llm-cost-optimization-premium-tier
  display_name: llm-cost-optimization premium tier
  consumers:
  - llm-cost-optimization-premium-consumer
  policies:
  - llm-cost-optimization-premium-limit
ai_gateway_policies:
- ref: llm-cost-optimization-compressor
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: llm-cost-optimization-compressor
  display_name: llm-cost-optimization prompt compressor
  type: ai-prompt-compressor
  config:
    compressor_type: rate
    compressor_url: !env 'COMPRESSOR_URL'
    stop_on_error: false
    compression_ranges:
    - min_tokens: 100
      max_tokens: 1000000
      value: 0.6
- ref: llm-cost-optimization-standard-limit
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: llm-cost-optimization-standard-limit
  display_name: llm-cost-optimization standard tier rate limit
  type: ai-rate-limiting-advanced
  config:
    policies:
    - window_type: sliding
      limits:
      - limit: 1
        window_size: 3600
    identifier: consumer-group
    tokens_count_strategy: cost
    strategy: local
- ref: llm-cost-optimization-premium-limit
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: llm-cost-optimization-premium-limit
  display_name: llm-cost-optimization premium tier rate limit
  type: ai-rate-limiting-advanced
  config:
    policies:
    - window_type: sliding
      limits:
      - limit: 5
        window_size: 3600
    identifier: consumer-group
    tokens_count_strategy: cost
    strategy: local
- ref: llm-cost-optimization-cache
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: llm-cost-optimization-cache
  display_name: llm-cost-optimization semantic cache
  type: ai-semantic-cache
  config:
    cache_ttl: 300
    message_countback: 1
    stop_on_failure: false
    embeddings:
      auth:
        aws_access_key_id: !env 'AWS_ACCESS_KEY_ID'
        aws_secret_access_key: !env 'AWS_SECRET_ACCESS_KEY'
      model:
        provider: bedrock
        name: !env 'EMBEDDINGS_MODEL'
        options:
          bedrock:
            aws_region: !env 'AWS_REGION'
    vectordb:
      dimensions: 1024
      distance_metric: cosine
      strategy: redis
      threshold: 0.3
      redis:
        host: !env 'REDIS_HOST'
ai_gateway_models:
- ref: llm-cost-optimization-model
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: llm-cost-optimization-model
  display_name: llm-cost-optimization
  type: model
  formats:
  - type: openai
  capabilities:
  - generate
  access:
    auth_strategies:
    - llm-cost-optimization-auth
  policies:
  - llm-cost-optimization-cache
  - llm-cost-optimization-compressor
  config:
    max_request_body_size: 10485760
    response_streaming: allow
    logging:
      payloads: true
    route:
      paths:
      - /llm-cost-optimization
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
    balancer:
      algorithm: semantic
      embeddings:
        provider: llm-cost-optimization-provider
        name: !env 'EMBEDDINGS_MODEL'
        config:
          region: !env 'AWS_REGION'
          type: bedrock
      vectordb:
        type: redis
        dimensions: 1024
        distance_metric: cosine
        threshold: 0.85
        host: !env 'REDIS_HOST'
        port: 6379
        ssl: false
  targets:
  - name: !env 'CHAT_MODEL_1'
    provider: llm-cost-optimization-provider
    semantic_description: CATCHALL
    config:
      region: !env 'AWS_REGION'
      type: bedrock
      input_cost: 0.06
      output_cost: 0.24
  - name: !env 'CHAT_MODEL_2'
    provider: llm-cost-optimization-provider
    semantic_description: Software architecture, system design, and complex code generation.
    config:
      region: !env 'AWS_REGION'
      type: bedrock
      input_cost: 3.0
      output_cost: 15.0
EOF

kongctl apply -f kong-recipe.yaml -o text --auto-approve --pat "${KONNECT_TOKEN}"

rm -f kong-recipe.yaml
```
{: data-test-step="block" .collapsible }

{% endnavtab %}
{% endnavtabs %}

### Run the demo

The script runs five sections: semantic routing, semantic caching, prompt compression, the budget of each tier, and an invalid API key. It counts the tokens of the long prompt locally with `tiktoken`, so you can compare them with the tokens that the provider billed. In the output, look for the `Model`, `Cache`, and `Tokens` lines and the `x-ai-ratelimit-remaining` headers.

{:.info}
> The demo passes the API key in `default_headers` because the OpenAI SDK always sends `api_key` as an `Authorization: Bearer` header. To let clients use `api_key` directly, add a global [Pre-Function](/ai-gateway/policies/pre-function/) Policy (`global: true`) that copies the Bearer token to the `apikey` header. A global Pre-Function Policy runs before authentication, while one attached to the AI Model runs after it.

Create the demo script:

```bash
cat <<'EOF' > demo.py
"""LLM cost optimization demo.

Exercises all four cost-optimization layers the recipe's AI Model and Policies apply on
every request: semantic routing (cheap vs. expensive target), semantic caching (skip the
LLM call entirely on a paraphrased repeat), prompt compression (fewer billed tokens on a
verbose prompt), and cost-based rate limiting (a dollar budget for each AI Consumer Group). A final
call with an invalid API key confirms that the Key Auth AI Auth Strategy rejects it with 401
before any upstream call.

Run it after you apply the Kong configuration:

    python demo.py

Environment variables: PROXY_URL (default http://localhost:8000), STANDARD_API_KEY (default
standard-api-key), PREMIUM_API_KEY (default premium-api-key).
"""

import os
import sys
import time

from openai import APIStatusError, OpenAI

try:
    import tiktoken
    _ENC = tiktoken.encoding_for_model("gpt-4o")
except Exception:
    _ENC = None

PROXY_URL = os.getenv("PROXY_URL", "http://localhost:8000")
STANDARD_API_KEY = os.getenv("STANDARD_API_KEY", "standard-api-key")
PREMIUM_API_KEY = os.getenv("PREMIUM_API_KEY", "premium-api-key")
# The semantic balancer picks the target, so Kong ignores this value. The SDK requires one.
CHAT_MODEL = "auto"
BASE_URL = f"{PROXY_URL}/llm-cost-optimization"

# ANSI color codes. Disabled when stdout isn't a TTY or NO_COLOR is set.
_USE_COLOR = sys.stdout.isatty() and "NO_COLOR" not in os.environ
def _c(code: str, s: str) -> str:
    return f"\033[{code}m{s}\033[0m" if _USE_COLOR else s
BOLD   = lambda s: _c("1", s)
DIM    = lambda s: _c("2", s)
GREEN  = lambda s: _c("32", s)
YELLOW = lambda s: _c("33", s)
BLUE   = lambda s: _c("34", s)
CYAN   = lambda s: _c("36", s)
RED    = lambda s: _c("31", s)


def make_client(api_key: str) -> OpenAI:
    """Construct an OpenAI client that sends the given API key in the apikey header."""
    return OpenAI(
        base_url=BASE_URL,
        api_key="unused",  # required by the SDK; Kong reads the apikey header instead
        default_headers={"apikey": api_key},
    )


standard_client = make_client(STANDARD_API_KEY)
premium_client = make_client(PREMIUM_API_KEY)


def chat(client: OpenAI, prompt: str, label: str = "", original_tokens: int | None = None,
         max_tokens: int = 250, show_budget: bool = False) -> float:
    """Send a chat request and print response details with Kong headers.

    `max_tokens` caps the LLM's response length so the demo runs quickly. The full
    answer doesn't matter for the demonstration; what matters is which model served
    it, whether the cache hit, and the resulting token / cost accounting.
    """
    start = time.time()
    try:
        response = client.chat.completions.with_raw_response.create(
            model=CHAT_MODEL,
            messages=[{"role": "user", "content": prompt}],
            max_tokens=max_tokens,
        )
    except APIStatusError as e:
        elapsed = time.time() - start
        status = RED(BOLD(f"{e.status_code}"))
        detail = "" if e.status_code == 401 else f" {e.message}"
        print(f"\n  [{BOLD(label)}] {status}{detail}  ({elapsed:.2f}s)")
        return elapsed

    elapsed = time.time() - start
    completion = response.parse()
    h = response.headers

    model = h.get("x-kong-llm-model", "(served from cache)")
    cache = h.get("x-cache-status", ".")
    upstream = h.get("x-kong-upstream-latency")
    text = (completion.choices[0].message.content or "")[:120]
    usage = completion.usage

    if upstream and upstream != "0":
        latency_extra = f"upstream: {upstream}ms"
    else:
        latency_extra = "cache hit, no upstream call"

    short = prompt[:70] + ("..." if len(prompt) > 70 else "")
    cache_color = GREEN if cache.lower() == "hit" else YELLOW
    print(f"\n  [{BOLD(label)}] '{short}'")
    print(f"    Model:    {CYAN(BOLD(model))}")
    print(f"    Cache:    {cache_color(BOLD(cache))}")
    if original_tokens is not None and original_tokens > 0:
        reduction_pct = 100 * (original_tokens - usage.prompt_tokens) / original_tokens
        # Highlight the reduction, that's the headline of this section.
        print(f"    Tokens:   pre-compression~{original_tokens} -> "
              f"billed={GREEN(BOLD(str(usage.prompt_tokens)))} "
              f"({GREEN(BOLD(f'{reduction_pct:.0f}% reduction'))}), "
              f"completion={usage.completion_tokens}")
    else:
        print(f"    Tokens:   prompt={usage.prompt_tokens}, "
              f"completion={usage.completion_tokens}, total={usage.total_tokens}")
    print(f"    Latency:  {elapsed:.2f}s ({DIM(latency_extra)})")
    print(f"    Response: {DIM(text)}{DIM('...') if len(text) >= 120 else ''}")

    if show_budget:
        print_budget(h)

    return elapsed


def print_budget(h) -> None:
    """Print the AI Rate Limiting Advanced headers, with the remaining budget highlighted."""
    for k in sorted(h.keys()):
        if "ai-ratelimit" in k.lower():
            value = h[k]
            if "remaining" in k.lower():
                print(f"    {k}: {BLUE(BOLD(value))}")
            else:
                print(f"    {k}: {value}")


def count_tokens(text: str) -> int | None:
    if _ENC is None:
        return None
    return len(_ENC.encode(text))


def section(title: str) -> None:
    bar = "=" * 65
    print(f"\n{bar}\n{BOLD(title)}\n{bar}")


def main() -> None:
    section("1. SEMANTIC ROUTING. Cheap vs Expensive Model Selection")

    chat(standard_client, "What is the capital of France?", "SIMPLE")
    chat(
        standard_client,
        "Design a Python FastAPI application with OAuth2 JWT authentication, "
        "PostgreSQL integration, WebSocket support, and comprehensive error "
        "handling. Include the service architecture and key implementation.",
        "COMPLEX",
    )

    section("2. SEMANTIC CACHING. Cache Hits for Similar Questions")

    t_miss = chat(standard_client, "What is machine learning?", "MISS")
    time.sleep(1)
    t_hit = chat(standard_client, "Explain machine learning to me", "HIT")
    if t_hit > 0:
        print(f"\n    Cache speedup: {GREEN(BOLD(f'{t_miss / t_hit:.1f}x faster'))}")

    section("3. PROMPT COMPRESSION. Reduced Token Usage on Long Prompts")

    verbose_prompt = (
        "I would really like you to provide me with a very detailed and "
        "comprehensive explanation of the process of photosynthesis in plants. "
        "Please include information about the light-dependent reactions that "
        "occur in the thylakoid membranes of the chloroplasts, as well as the "
        "light-independent reactions, also known as the Calvin cycle, that take "
        "place in the stroma. Additionally, please describe the role of "
        "chlorophyll and other photosynthetic pigments in capturing light energy, "
        "and explain how water molecules are split during photolysis to release "
        "oxygen as a byproduct. I would also appreciate it if you could discuss "
        "the importance of photosynthesis for life on Earth and its relationship "
        "to the carbon cycle and atmospheric oxygen levels."
    )
    original = count_tokens(verbose_prompt)
    if original is None:
        print("    (Install `tiktoken` to see the original-vs-billed token comparison.)")
    chat(standard_client, verbose_prompt, "COMPRESSED", original_tokens=original)
    print(DIM("    (LLMLingua compressed the prompt server-side before reaching the LLM."))
    print(DIM("     'billed' is the post-compression token count the provider charged for.)"))

    section("4. COST-BASED RATE LIMITING. Tiered Budget Caps")
    print("    Each AI Consumer sends a unique prompt to bypass the cache and trigger a")
    print("    real upstream call so the per-tier budget visibly debits.")

    print(f"\n  {BOLD('Standard user')} ($1/hour shared budget):")
    chat(standard_client, "Say hello in one sentence.", "STANDARD", show_budget=True)

    print(f"\n  {BOLD('Premium user')} ($5/hour shared budget):")
    chat(premium_client, "Tell me an interesting fact about octopuses in one sentence.", "PREMIUM",
         show_budget=True)

    section("5. AUTH BOUNDARY. Invalid API key rejected before upstream call")
    bad_key = "not-a-real-key"
    print(f"    Sending request with apikey='{RED(bad_key)}' (not registered with any AI Consumer)...")
    bad_client = make_client(bad_key)
    chat(bad_client, "Hello", "BLOCKED")
    print(f"    {DIM('Kong rejected the request before any upstream call (no provider quota consumed).')}")

    section("DONE. Four cost optimization layers active simultaneously:")
    print(f"  {GREEN('Semantic routing')}:    cheap model for simple, expensive for complex")
    print(f"  {GREEN('Semantic caching')}:    no LLM call for similar questions")
    print(f"  {GREEN('Prompt compression')}:  fewer tokens sent to the LLM")
    print(f"  {GREEN('Cost rate limiting')}:  per-tier dollar-based budget caps")
    print("=" * 65)


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

Example output with the OpenAI tab:

```text
=================================================================
1. SEMANTIC ROUTING. Cheap vs Expensive Model Selection
=================================================================

  [SIMPLE] 'What is the capital of France?'
    Model:    openai/gpt-4o-mini
    Cache:    Miss
    Tokens:   prompt=14, completion=7, total=21
    Latency:  1.48s (upstream: 589ms)
    Response: The capital of France is Paris.

  [COMPLEX] 'Design a Python FastAPI application with OAuth2 JWT authentication, Po...'
    Model:    openai/gpt-4o
    Cache:    Miss
    Tokens:   prompt=40, completion=250, total=290
    Latency:  3.40s (upstream: 2870ms)
    Response: Designing a Python FastAPI application with OAuth2 JWT authentication, PostgreSQL integration, WebSocket support, and co...

=================================================================
2. SEMANTIC CACHING. Cache Hits for Similar Questions
=================================================================

  [MISS] 'What is machine learning?'
    Model:    openai/gpt-4o-mini
    Cache:    Miss
    Tokens:   prompt=12, completion=250, total=262
    Latency:  3.20s (upstream: 2810ms)
    Response: Machine learning is a subset of artificial intelligence (AI) that focuses on the development of algorithms that let comp...

  [HIT] 'Explain machine learning to me'
    Model:    (served from cache)
    Cache:    Hit
    Tokens:   prompt=12, completion=250, total=262
    Latency:  0.45s (cache hit, no upstream call)
    Response: Machine learning is a subset of artificial intelligence (AI) that focuses on the development of algorithms that let comp...

    Cache speedup: 7.1x faster

=================================================================
3. PROMPT COMPRESSION. Reduced Token Usage on Long Prompts
=================================================================

  [COMPRESSED] 'I would really like you to provide me with a very detailed and compreh...'
    Model:    openai/gpt-4o-mini
    Cache:    Miss
    Tokens:   pre-compression~138 -> billed=87 (37% reduction), completion=250
    Latency:  4.10s (upstream: 3580ms)
    Response: Photosynthesis is a vital biochemical process that occurs in green plants, algae, and some bacteria, converting light en...
    (LLMLingua compressed the prompt server-side before reaching the LLM.
     'billed' is the post-compression token count the provider charged for.)

=================================================================
4. COST-BASED RATE LIMITING. Tiered Budget Caps
=================================================================
    Each AI Consumer sends a unique prompt to bypass the cache and trigger a
    real upstream call so the per-tier budget visibly debits.

  Standard user ($1/hour shared budget):

  [STANDARD] 'Say hello in one sentence.'
    Model:    openai/gpt-4o-mini
    Cache:    Miss
    Tokens:   prompt=13, completion=9, total=22
    Latency:  0.96s (upstream: 438ms)
    Response: Hello! How can I assist you today?
    x-ai-ratelimit-limit-3600-policy-1: 1
    x-ai-ratelimit-remaining-3600-policy-1: 0.9970789

  Premium user ($5/hour shared budget):

  [PREMIUM] 'Tell me an interesting fact about octopuses in one sentence.'
    Model:    openai/gpt-4o-mini
    Cache:    Miss
    Tokens:   prompt=15, completion=27, total=42
    Latency:  1.08s (upstream: 612ms)
    Response: Octopuses have three hearts and blue blood, with two hearts pumping blood to the gills and one to the rest of the body.
    x-ai-ratelimit-limit-3600-policy-1: 5
    x-ai-ratelimit-remaining-3600-policy-1: 5

=================================================================
5. AUTH BOUNDARY. Invalid API key rejected before upstream call
=================================================================
    Sending request with apikey='not-a-real-key' (not registered with any AI Consumer)...

  [BLOCKED] 401  (0.01s)
    Kong rejected the request before any upstream call (no provider quota consumed).

=================================================================
DONE. Four cost optimization layers active simultaneously:
=================================================================
  Semantic routing:    cheap model for simple, expensive for complex
  Semantic caching:    no LLM call for similar questions
  Prompt compression:  fewer tokens sent to the LLM
  Cost rate limiting:  per-tier dollar-based budget caps
=================================================================
```
{: .no-copy-code .collapsible }

### Check the results

The output confirms the following:

{% table %}
columns:
  - title: Behavior
    key: behavior
  - title: Evidence
    key: evidence
rows:
  - behavior: "Semantic routing"
    evidence: "The simple question shows `openai/gpt-4o-mini` and the architecture prompt shows `openai/gpt-4o`, from the `X-Kong-LLM-Model` header. The client sent `model: auto` both times."
  - behavior: "Semantic caching"
    evidence: "The paraphrased question shows `Cache: Hit`, from `X-Cache-Status`, with no upstream latency and no model header. It returns several times faster than the original question."
  - behavior: "Prompt compression"
    evidence: "The long prompt has about 138 tokens before compression, and the provider billed 87 prompt tokens."
  - behavior: "Dollar budgets for each tier"
    evidence: "The standard tier shows a `$1` limit with less than `$1` remaining, because the earlier standard requests cost money. The premium tier shows a `$5` limit and its full budget, because Kong deducts a request's cost on the next request."
  - behavior: "Authentication before any upstream call"
    evidence: "The invalid key gets `401` in about 10 ms. Kong never called the compressor, the embeddings model, or the LLM."
{% endtable %}

To review the created entities, and per-consumer usage, open the `llm-cost-optimization-recipe` {{site.ai_gateway}} in [{{site.konnect_short_name}}](https://cloud.konghq.com/). For traffic across all your {{site.ai_gateway}}s, use the **Observability** menu.

## How it works

Kong authenticates each request, checks the budget of the AI Consumer's tier, compresses long prompts, and looks up the semantic cache. On a cache miss, the AI Model's semantic balancer picks a target, and Kong forwards the request with the AI Model Provider's credentials.

<!-- vale off -->
{% mermaid %}
sequenceDiagram
    participant C as Client
    participant K as Kong AI Gateway
    participant LC as LLMLingua Compressor
    participant L as LLM Provider

    C->>K: POST /llm-cost-optimization (apikey header, prompt)
    activate K
    K->>K: Key Auth AI Auth Strategy validates apikey (else 401)
    K->>K: AI Rate Limiting Advanced Policy checks the tier budget (else 429)
    K->>LC: AI Prompt Compressor Policy sends long prompts
    activate LC
    LC-->>K: Compressed prompt
    deactivate LC
    K->>K: AI Semantic Cache Policy searches Redis for a similar prompt
    alt Cache hit
        K-->>C: Cached response with X-Cache-Status Hit
    else Cache miss
        K->>K: Semantic balancer picks the cheap or the capable target
        K->>L: Request with provider credentials
        activate L
        L-->>K: Response with token usage
        deactivate L
        K->>K: AI Rate Limiting Advanced Policy records the request cost
        K-->>C: OpenAI-format response with X-Kong-LLM-Model
    end
    deactivate K
{% endmermaid %}
<!-- vale on -->

The AI Policies run in their built-in [priority](/ai-gateway/entities/ai-policy/#ai-policy-priority) order: the AI Rate Limiting Advanced Policy (905), the AI Prompt Compressor Policy (769), then the AI Semantic Cache Policy (765). Thus Kong compresses a prompt before the cache lookup, also when the lookup is a hit. Compression keeps the meaning of the prompt, so similar prompts still match in the cache. This cookbook hasn't confirmed against a live {{site.ai_gateway}} whether the semantic balancer picks the target before or after the cache lookup.

### Key Auth AI Auth Strategy and AI Consumers

Authentication is an AI Auth Strategy, not an AI Policy. The Key Auth AI Auth Strategy reads the `apikey` header and matches the key against the AI Consumer credentials. On a match, Kong attaches the AI Consumer to the request. The AI Consumer is the identity that rate limits, ACLs, and analytics use. The recipe has two AI Consumers, `llm-cost-optimization-standard-consumer` and `llm-cost-optimization-premium-consumer`, so the key that the client sends selects the tier.

The following settings configure the Key Auth AI Auth Strategy and the AI Consumers:

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
    purpose: "Each AI Consumer's key. The field is write-only, so it takes a `!secret` reference to `STANDARD_API_KEY` or `PREMIUM_API_KEY`, even for a demo value."
{% endtable %}

Kong adds `X-Consumer-Username` and related headers to the upstream request, not to the response. Per-consumer usage appears in {{site.konnect_short_name}} analytics.

### AI Rate Limiting Advanced Policies and AI Consumer Groups

Each AI Consumer Group, `llm-cost-optimization-standard-tier` and `llm-cost-optimization-premium-tier`, has one AI Consumer and lists its own AI Rate Limiting Advanced Policy in `policies`. The policy counts the dollar cost of each request, so a budget lasts longer on the cheap model than on the capable one. When a tier uses up its budget, Kong returns `429 Too Many Requests` until the window allows requests again.

The following settings configure the AI Consumer Groups and the AI Rate Limiting Advanced Policies:

{% table %}
columns:
  - title: Setting
    key: setting
  - title: Purpose
    key: purpose
rows:
  - setting: "`ai_gateway_consumer_groups[].consumers`"
    purpose: "Adds each AI Consumer to its tier."
  - setting: "`ai_gateway_consumer_groups[].policies`"
    purpose: "Attaches the tier's AI Rate Limiting Advanced Policy to each request from the AI Consumer Group. This attachment hasn't been confirmed against a live {{site.ai_gateway}}."
  - setting: "`identifier: consumer-group`"
    purpose: "Counts usage for each AI Consumer Group, so the AI Consumers of a tier share one budget. The policy must be attached to an AI Consumer Group."
  - setting: "`tokens_count_strategy: cost`"
    purpose: "Counts the cost of each request, from its token usage and the `input_cost` and `output_cost` of the target that served it. See [Model cost management](/ai-gateway/model-cost-management/) for the calculation. In a test on runtime 2.3.1, the policy deducted the request's total tokens instead of its cost, so the `$1` budget ran out after the first request. Check the deduction on your runtime before you rely on these budgets."
  - setting: "`config.policies[].limits`"
    purpose: "The budget and the window size in seconds: `1` dollar in `3600` seconds for the standard tier, `5` for the premium tier. The demo uses small budgets so the change is visible."
  - setting: "`window_type: sliding`"
    purpose: "Weighs the current window against the previous one, which smooths spending at window boundaries."
  - setting: "`strategy: local`"
    purpose: "Keeps the counters in memory on each data plane node. For several nodes, use `redis` so that the nodes share the counters."
{% endtable %}

Kong deducts the cost of a request on the next request, so the request that uses up the budget always completes. Each response has `X-AI-RateLimit-Limit-<window>-<label>` and `X-AI-RateLimit-Remaining-<window>-<label>` headers. The label is `policy-1` because the policy entry has no `match` conditions.

### AI Prompt Compressor Policy

The AI Prompt Compressor Policy sends long prompts to the LLMLingua compressor service, which removes low-value tokens and keeps the meaning. The provider then bills only the compressed tokens. Short prompts pass through unchanged.

The following settings configure the AI Prompt Compressor Policy:

{% table %}
columns:
  - title: Setting
    key: setting
  - title: Purpose
    key: purpose
rows:
  - setting: "`compressor_url`"
    purpose: "The address of the compressor service, from `COMPRESSOR_URL`."
  - setting: "`compressor_type: rate`"
    purpose: "Reads each range's `value` as the share of the prompt to keep. `target_token` reads it as a token count instead."
  - setting: "`compression_ranges`"
    purpose: "Compresses prompts of 100 tokens or more and keeps 60% of them (`value: 0.6`). Add ranges to compress long prompts more than medium ones."
  - setting: "`stop_on_error: false`"
    purpose: "Forwards the uncompressed prompt when the compressor service fails, so an outage doesn't block requests."
{% endtable %}

### AI Semantic Cache Policy

The AI Semantic Cache Policy embeds the latest message and searches Redis for a cached prompt within the distance threshold. On a hit, Kong returns the cached response with `X-Cache-Status: Hit` and doesn't call the LLM. On a miss, Kong caches the new response. The cache doesn't separate responses by AI Consumer, so a response cached for one tier can answer a similar prompt from the other tier.

The following settings configure the AI Semantic Cache Policy:

{% table %}
columns:
  - title: Setting
    key: setting
  - title: Purpose
    key: purpose
rows:
  - setting: "`embeddings.auth` and `embeddings.model`"
    purpose: "The embeddings credentials and model, from the AI Credentials prerequisite and `EMBEDDINGS_MODEL`. The policy calls the provider directly and doesn't use the AI Model Provider, so each provider tab has its own auth fields."
  - setting: "`vectordb.dimensions`"
    purpose: "The vector size of the embeddings model: `1536` for `text-embedding-3-small`, `1024` for `amazon.titan-embed-text-v2:0`. If you change `EMBEDDINGS_MODEL`, change this value."
  - setting: "`vectordb.threshold: 0.3`"
    purpose: "The maximum cosine distance for a cache hit. Lower values are stricter. See [Embedding-based similarity matching](/ai-gateway/semantic-similarity/)."
  - setting: "`cache_ttl: 300`"
    purpose: "Keeps cached responses for 300 seconds."
  - setting: "`message_countback: 1`"
    purpose: "Embeds only the latest message. Raise it when earlier messages change the expected answer."
  - setting: "`stop_on_failure: false`"
    purpose: "Sends the request to the LLM when Redis or the embeddings call fails, instead of failing the request."
{% endtable %}

### AI Model Provider and AI Model

The AI Model Provider holds the provider credentials. The `llm-cost-optimization-model` AI Model has two targets and a semantic balancer. The balancer embeds the prompt and compares it with each target's `semantic_description`. The capable target answers prompts close to its description, and the `CATCHALL` target answers everything else.

The following settings configure the AI Model Provider and the AI Model:

{% table %}
columns:
  - title: Setting
    key: setting
  - title: Purpose
    key: purpose
rows:
  - setting: "`config.auth` (AI Model Provider)"
    purpose: "The provider credentials. Kong adds them to each upstream request. The fields depend on the provider tab."
  - setting: "`config.balancer.algorithm: semantic`"
    purpose: "Picks the target by meaning. The client's `model` field doesn't select the target. See the [AI Model reference](/ai-gateway/entities/ai-model/) for the other balancer algorithms."
  - setting: "`config.balancer.embeddings`"
    purpose: "The embeddings model for routing. It references the AI Model Provider by name and uses its credentials."
  - setting: "`config.balancer.vectordb.ssl: false` and `port: 6379`"
    purpose: "The balancer connects to Redis without TLS on port 6379. The balancer's Redis connection uses TLS by default, which a local Redis Stack doesn't accept, so the balancer would never start and every request would fail with `500`."
  - setting: "`config.balancer.vectordb.threshold`"
    purpose: "The maximum cosine distance between a prompt and a target description: `0.75` for `text-embedding-3-small`, `0.85` for `amazon.titan-embed-text-v2:0`. Retune it when you change the embeddings model."
  - setting: "`config.route.model`"
    purpose: "The AI Model answers to the alias `auto` in the body's `model` field (`body_param: model`). The demo sends `auto`, and the semantic balancer chooses the target. Without a selector, an AI Model accepts only its own name as `model`."
  - setting: "`targets[].semantic_description`"
    purpose: "`CATCHALL` on the cheap target makes it the fallback. The capable target's description is \"Software architecture, system design, and complex code generation.\" A short, specific phrase routes more precisely than a long one."
  - setting: "`targets[].config.input_cost` and `output_cost`"
    purpose: "Prices per 1 million tokens, which the AI Rate Limiting Advanced Policy uses. The values are examples for each tab's default models. Replace them with the current [OpenAI](https://developers.openai.com/api/docs/pricing) or [Amazon Bedrock](https://aws.amazon.com/bedrock/pricing/) prices."
  - setting: "`policies`"
    purpose: "The AI Semantic Cache and AI Prompt Compressor Policies. The AI Rate Limiting Advanced Policies attach to the AI Consumer Groups instead."
  - setting: "`config.route.protocols: [http, https]`"
    purpose: "Accepts HTTP, so you can call the local data plane at `http://localhost:8000`."
  - setting: "`config.max_request_body_size: 10485760`"
    purpose: "Accepts request bodies up to 10 MB, instead of the 8 MB default, for long prompts."
  - setting: "`config.response_streaming: allow`"
    purpose: "Clients can request streamed responses, for interactive chat."
  - setting: "`config.logging.payloads: true`"
    purpose: "Kong logs request and response payloads. The default is `false`."
{% endtable %}

{:.info}
> **Production credentials:** This cookbook stores the AI Consumers' API keys and the provider credentials in environment variables for simplicity. In production, use [AI Vaults](/ai-gateway/entities/ai-vault/) to reference them from a secret manager, for example AWS Secrets Manager, HashiCorp Vault, GCP Secret Manager, or Azure Key Vault.

### Response headers

Kong adds the following response headers:

{% table %}
columns:
  - title: Header
    key: header
  - title: Description
    key: description
rows:
  - header: "`X-Kong-LLM-Model`"
    description: "The upstream model that served the request, with the provider name as a prefix, for example `openai/gpt-4o-mini`. The demo output shows no model on a cache hit."
  - header: "`X-Cache-Status`"
    description: "`Hit` when the AI Semantic Cache Policy returned a cached response, `Miss` when Kong called the LLM."
  - header: "`X-AI-RateLimit-Limit-<window>-<label>`"
    description: "The tier's budget for a window of `<window>` seconds."
  - header: "`X-AI-RateLimit-Remaining-<window>-<label>`"
    description: "The budget left in the window, after the cost of earlier requests."
  - header: "`X-Kong-Upstream-Latency`"
    description: "Time in milliseconds that Kong waited for the provider to respond."
  - header: "`X-Kong-Proxy-Latency`"
    description: "Time in milliseconds that Kong spent processing the request, including the compression and embeddings calls."
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
    how: "Change `CHAT_MODEL_1` or `CHAT_MODEL_2`, update the `input_cost` and `output_cost` of that target, and re-apply. Clients don't change."
  - variation: "Tune routing for your workload"
    how: "Replace the capable target's `semantic_description` with a short phrase for your complex tasks, for example \"Legal document analysis with citations\", and retune the balancer threshold."
  - variation: "Add tiers or windows"
    how: "Add an AI Consumer Group with its own AI Rate Limiting Advanced Policy for each tier. Add a second entry to `limits`, for example a 60-second window, to cap burst spending as well as hourly spending."
  - variation: "Share counters across nodes"
    how: "Set `strategy: redis` and the `redis` connection fields on the AI Rate Limiting Advanced Policies. Run `kongctl explain ai_gateway_policies --extended` for all options."
  - variation: "Compress selected text only"
    how: "Wrap parts of a prompt in `<LLMLINGUA>` tags. The AI Prompt Compressor Policy then compresses only the tagged text. See the [AI Prompt Compressor reference](/ai-gateway/policies/ai-prompt-compressor/)."
  - variation: "Use Azure OpenAI"
    how: "Azure binds each deployment to one model, so each target and the balancer's embeddings need their own `deployment_id`. The AI Policies, AI Consumers, and AI Consumer Groups don't change."
  - variation: "Authenticate users with an identity provider"
    how: "Replace the Key Auth AI Auth Strategy with an [OpenID Connect AI Auth Strategy](/ai-gateway/openid-connect/) and map JWT claims to AI Consumer Groups. See the [Claude Code SSO cookbook](/cookbooks/claude-code-sso/) for an example with Okta."
{% endtable %}

## Cleanup

The recipe's kongctl namespace scoped all resources, so this teardown removes only this recipe's configuration. Tear down the local data plane and delete the {{site.ai_gateway}} from {{site.konnect_short_name}}:

```bash
export KONNECT_CONTROL_PLANE_NAME='llm-cost-optimization-recipe' && curl -Ls https://get.konghq.com/ai | bash -s -- -d -k $KONNECT_TOKEN
```

Remove the Redis Stack and compressor containers:

```bash
docker rm -f redis-stack ai-compress-service
```
