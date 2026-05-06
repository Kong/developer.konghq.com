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
canonical: true
works_on:
  - konnect
min_version:
  gateway: "3.14"
categories:
  - cost-optimization
featured: false
popular: false

# Machine-readable fields for AI agent setup
plugins:
  - key-auth
  - ai-proxy-advanced
  - ai-semantic-cache
  - ai-prompt-compressor
  - ai-rate-limiting-advanced
requires_embeddings: true
providers:
  - openai
  - bedrock

hint: "Requires API credentials for your chosen LLM provider, a Redis Stack instance, the LLMLingua compressor service, and Python 3.11+."
prereqs:
  skip_product: true
  skip_tool: true
  inline:
    - title: Kong Konnect
      content: |
        This tutorial uses {{site.konnect_product_name}}. You will provision a recipe-scoped Control Plane and local Data Plane via the [quickstart script](https://get.konghq.com/quickstart).

        1. Create a new personal access token by opening the [Konnect PAT page](https://cloud.konghq.com/global/account/tokens) and selecting **Generate Token**.
        1. Export your token. The same token is reused later for kongctl commands:

           ```bash
           export KONNECT_TOKEN='YOUR_KONNECT_PAT'
           ```

        1. Set the recipe-scoped Control Plane name and run the quickstart script:

           ```bash
           export KONNECT_CONTROL_PLANE_NAME='llm-cost-optimization-recipe'
           curl -Ls https://get.konghq.com/quickstart | \
             bash -s -- -k $KONNECT_TOKEN \
               -e KONG_NGINX_WORKER_PROCESSES=1 \
               --deck-output
           ```

           This provisions a Konnect Control Plane named `llm-cost-optimization-recipe`, a local Data Plane connected to it, and prints `export` lines for the rest of the session vars. Paste those into your shell when prompted.
    - title: kongctl + decK
      content: |
        This tutorial uses [kongctl](/kongctl/) and [decK](/deck/) to manage Kong configuration.

        1. Install **kongctl** from [developer.konghq.com/kongctl](https://developer.konghq.com/kongctl/).
        1. Install **decK** version 1.43 or later from [docs.konghq.com/deck](https://docs.konghq.com/deck/).
        1. Verify both are installed:

           ```bash
           kongctl version
           deck version
           ```
    - title: AI Credentials
      content: |
        Pick the provider you want to route to and export its credentials. The same credentials are reused by every apply tab below.

        {% navtabs "Providers" %}
        {% navtab "OpenAI" %}
        This tutorial uses OpenAI:

        1. [Create an OpenAI account](https://auth.openai.com/create-account).
        1. [Get an API key](https://platform.openai.com/api-keys).
        1. Create a decK variable with the API key:

           ```sh
           export DECK_OPENAI_TOKEN='Bearer sk-YOUR-KEY'
           ```
        {% endnavtab %}
        {% navtab "AWS Bedrock" %}
        This tutorial uses AWS Bedrock:

        1. Ensure you have an AWS account with [Bedrock model access](https://docs.aws.amazon.com/bedrock/latest/userguide/model-access.html) enabled for both the chat and embeddings models you plan to use.
        1. Create decK variables with your AWS credentials:

           ```sh
           export DECK_AWS_ACCESS_KEY_ID='your-access-key'
           export DECK_AWS_SECRET_ACCESS_KEY='your-secret-key'
           export DECK_AWS_REGION='us-east-1'
           ```
        {% endnavtab %}
        {% endnavtabs %}
    - title: Redis Stack
      icon_url: /assets/icons/redis.svg
      content: |
        The [ai-semantic-cache](/plugins/ai-semantic-cache/) and [ai-proxy-advanced](/plugins/ai-proxy-advanced/) Plugins use Redis as the vector database for both cache lookups and semantic routing.

        1. Run [Redis Stack](https://redis.io/docs/latest/) locally:

           ```bash
           docker run -d --name redis-stack -p 6379:6379 redis/redis-stack-server:latest
           ```

        1. Export the Redis host so the Plugins can connect from inside the Data Plane container:

           ```sh
           export DECK_REDIS_HOST='host.docker.internal'
           ```
    - title: LLMLingua Prompt Compressor
      content: |
        The [ai-prompt-compressor](/plugins/ai-prompt-compressor/) Plugin requires an external LLMLingua compression service. Kong provides a Docker image hosted on a private Cloudsmith registry.

        1. Obtain registry credentials from your Kong account team or support.
        1. Log in to the registry:

           ```bash
           docker login docker.cloudsmith.io
           ```

        1. Start the compressor service:

           ```bash
           docker run -d \
             --name llmlingua-compressor \
             -p 8080:8080 \
             -e LLMLINGUA_DEVICE_MAP=cpu \
             --memory=2g \
             docker.cloudsmith.io/kong/ai-compress/service:v0.0.3
           ```

           The service requires at least 2 GB of RAM. CPU is sufficient for development; GPU-backed deployment improves latency under load.

        1. Set the compressor URL:

           ```sh
           export DECK_COMPRESSOR_URL='http://host.docker.internal:8080'
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
  This recipe configures {{site.ai_gateway_name}} to reduce LLM infrastructure costs through four
  independent, stackable techniques: semantic routing to direct queries to the cheapest adequate
  model, semantic caching to eliminate redundant LLM calls entirely, prompt compression to reduce
  token counts before they reach the provider, and cost-based rate limiting to enforce dollar
  budgets per Consumer tier. By the end of this tutorial, you will have a single gateway endpoint
  that applies all four techniques to every request, with no application code changes required.

  The recipe uses five Kong Plugins working together:
  [key-auth](/plugins/key-auth/) for Consumer identification,
  [ai-proxy-advanced](/plugins/ai-proxy-advanced/) for semantic model routing,
  [ai-semantic-cache](/plugins/ai-semantic-cache/) for embedding-based response caching,
  [ai-prompt-compressor](/plugins/ai-prompt-compressor/) for LLMLingua-powered token reduction, and
  [ai-rate-limiting-advanced](/plugins/ai-rate-limiting-advanced/) for cost-based budget caps per
  Consumer Group.
---

## The problem

Most organizations deploying LLMs operate with a single model endpoint and no cost intelligence
at the infrastructure layer. This leads to several compounding inefficiencies:

- **Every query gets the same model, regardless of complexity.** A question like "What is 2+2?"
  hits the same model as "Design a distributed database architecture." The cheap model answers the
  simple question just as well, but the expensive model gets every request because there is no
  routing logic. Teams either overspend on a premium model for everything, or underserve complex
  queries by defaulting to the cheapest option.

- **Semantically identical questions re-hit the LLM.** When five users ask "What is the capital of
  France?" with slightly different phrasing, that is five separate LLM calls with five separate
  bills. Traditional exact-match caching does not help because the queries are worded differently.
  Embedding-based semantic comparison catches these near-duplicates, but building that into each
  application requires a vector database, an embeddings pipeline, and cache management logic per
  service.

- **Verbose prompts waste tokens on redundancy.** RAG pipelines, few-shot examples, and long
  system prompts often contain significant linguistic redundancy. The LLM is billed for every
  token, including the filler words and repeated phrasing that a compression model can strip
  without changing the semantic meaning. Without compression, token counts are inflated by 20-40%
  on verbose inputs.

- **Rate limiting counts requests or raw tokens, not dollars.** A limit of "10,000 tokens per
  hour" sounds precise, but the cost of 10,000 tokens varies dramatically by model. Pennies on a
  budget model become dollars on a frontier model. When organizations set token-based rate limits, the
  actual dollar exposure per user depends on which model they happen to use, making budgets
  unpredictable. True cost control requires tracking `(tokens x price)`, not just tokens.

- **No per-user or per-tier budget differentiation.** Without Consumer identity at the gateway
  layer, every user shares the same limits. There is no way to say "the free tier gets $10/hour,
  the enterprise tier gets $100/hour." Rate limits apply uniformly regardless of who is making
  the request.

The underlying issue is that cost optimization decisions, such as which model to use, whether to cache,
whether to compress, and how much budget to allocate, are being pushed to each application team
instead of being enforced centrally at the infrastructure layer.

## The solution

{{site.ai_gateway_name}} applies all four cost optimization techniques at the proxy layer, transparently
to every request. Each technique addresses one of the problems above:

- **Semantic routing replaces "one model for everything."** Kong embeds each incoming prompt and
  compares it against target descriptions in a vector database. Simple queries (high similarity
  to the `CATCHALL` target) route to a cheap model. Complex queries (matching the "detailed
  reasoning" target description) route to a premium model. The routing decision is automatic,
  requiring no application logic and no rules to maintain.

- **Semantic caching eliminates redundant LLM calls.** Before a request reaches the LLM, Kong
  embeds the prompt and searches Redis for a semantically similar cached response. If the
  similarity exceeds the threshold, Kong returns the cached response immediately with zero tokens
  consumed and sub-100ms latency. The cache operates across all users, so one user's question
  benefits everyone asking the same thing.

- **Prompt compression reduces token counts before billing.** Kong routes the prompt through an
  LLMLingua service that strips redundant tokens while preserving meaning. A 200-token verbose
  prompt becomes a 120-token compressed prompt. The LLM processes the compressed version, and
  the token bill reflects the smaller count. Compression activates only for prompts above a
  configurable threshold. Short prompts pass through unchanged.

- **Cost-based rate limiting enforces dollar budgets, not token counts.** Kong computes the
  actual cost of each response using per-model `input_cost` and `output_cost` values configured
  on each target, then deducts that cost from the Consumer's budget. Standard-tier users get a
  $10/hour budget; premium-tier users get $100/hour. When the budget is exhausted, Kong returns
  `429 Too Many Requests`, preventing billing surprises.

<!-- vale off -->
{% mermaid %}
sequenceDiagram
    participant C as Client
    participant K as Kong AI Gateway
    participant LC as LLMLingua Compressor
    participant L as LLM Provider

    C->>K: POST /llm-cost-optimization (apikey, prompt)
    activate K
    K->>K: key-auth — Consumer → standard or premium tier
    alt ai-semantic-cache: hit
        K-->>C: Cached response (no LLM call)
    else ai-semantic-cache: miss
        K->>LC: ai-prompt-compressor — compress prompt
        activate LC
        LC-->>K: Compressed prompt
        deactivate LC
        K->>K: ai-proxy-advanced — embed query, route to cheap or expensive model by similarity
        K->>L: Forwarded request
        activate L
        L-->>K: Native response
        deactivate L
        K->>K: ai-rate-limiting-advanced — deduct $cost from tier budget
        K-->>C: OpenAI-format response (stored in semantic cache)
    end
    deactivate K
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
    responsibility: "Sends OpenAI-format chat requests with an `apikey` header that identifies the Consumer tier"
  - component: Key Auth Plugin
    responsibility: "Looks up the API key, attaches the matching Kong Consumer to the request, and binds the request to the Consumer's tier"
  - component: AI Semantic Cache Plugin
    responsibility: "Embeds prompts, searches Redis for cached responses, short-circuits on cache hit"
  - component: AI Prompt Compressor Plugin
    responsibility: "Compresses verbose prompts via LLMLingua before they reach the LLM"
  - component: AI Proxy Advanced Plugin
    responsibility: "Semantic routing to cheap or expensive model, provider auth injection"
  - component: AI Rate Limiting Advanced Plugin
    responsibility: "Computes per-request cost and enforces dollar-based budget caps per Consumer Group"
  - component: Redis Stack
    responsibility: "Vector search for both semantic caching and semantic routing"
  - component: LLMLingua service
    responsibility: "Token-level prompt compression using a small language model"
  - component: LLM provider
    responsibility: "Model inference (cheap and expensive targets)"
{% endtable %}

## How it works

A request flowing through Kong is processed in five stages: authentication, cache check, prompt
compression, semantic routing to a model, and cost-based rate limiting.

1. A client sends a chat completion request (OpenAI format) to `/llm-cost-optimization` with an
   `apikey` header carrying their tier's static API key.
2. The Key Auth Plugin looks up the key against registered Consumer credentials. If the key is
   missing or unknown, Kong short-circuits with `401` before any upstream call. On a match, the
   Plugin attaches the matching Consumer (`standard-user` or `premium-user`) to the request,
   which determines which Consumer Group's rate limit applies later.
3. The AI Semantic Cache Plugin embeds the latest user message and searches Redis for a
   semantically similar cached response. On a hit (similarity above `0.8`), Kong returns the
   cached response immediately and no further Plugins run. On a miss, the request continues.
4. The AI Prompt Compressor Plugin sends prompts above the configured token threshold to the
   LLMLingua service, which returns a compressed version with redundant tokens removed. Short
   prompts pass through unchanged.
5. The AI Proxy Advanced Plugin embeds the prompt and computes cosine similarity against each
   target's `description` embedding. The closest match wins. The Plugin then strips the client's
   `apikey` header, injects the upstream provider's credentials, and (if the upstream uses a
   different format) translates the OpenAI-format body to the provider's native format.
6. Kong forwards the request to the LLM provider's API endpoint, normalizes the response back to
   OpenAI format, and stores it in the semantic cache for future similar prompts.
7. The AI Rate Limiting Advanced Plugin computes the dollar cost of the response from token
   counts and the target's `input_cost` / `output_cost` values, then deducts that cost from the
   Consumer Group's window. Response headers carry the remaining budget so clients can monitor
   their spend.

### Key Auth: API key authentication and Consumer mapping

The Key Auth Plugin sits at the front of the chain and gates every request. Each Consumer is
registered with one or more API keys in the `keyauth_credentials` block. When a request arrives,
the Plugin reads the configured header (`apikey`), looks the key up in Kong's Consumer credential
store, and attaches the matching Consumer to the request. The matched Consumer is what binds the
request to a Consumer Group for cost rate limiting. Two Consumers (`standard-user` and
`premium-user`) belong to two Consumer Groups (`standard-tier` at $10/hour and `premium-tier` at
$100/hour), so the API key the client sends determines the tier the request runs against.

#### Configuration details

```yaml
- name: key-auth
  config:
    key_names:
      - apikey
    hide_credentials: true
```
{:.no-copy-code}

**`key_names: [apikey]`**. The headers (or query parameters) the Plugin looks in for the API key. The recipe uses `apikey` because the Key Auth Plugin performs an exact string match on the header value and does not inspect `Authorization` for Bearer tokens. The OpenAI SDK's `api_key` field always serializes as `Authorization: Bearer <key>`, which Kong would read as the literal string `Bearer <key>` and fail to match against any stored credential. The "Try it out" section below points at a pre-function pattern that bridges the SDK's Bearer token to the `apikey` header server-side; the [Authenticate OpenAI SDK clients with Key Auth](https://developer.konghq.com/how-to/authenticate-openai-sdk-clients-with-key-auth/) guide has the full pattern.

**`hide_credentials: true`**. Strips the API key from the request before forwarding upstream. The provider never sees the Consumer's API key. This is a 3.14 default but the recipe sets it explicitly for clarity and to remain portable to older Gateway versions.

**Anonymous fallback.** Set `anonymous: <consumer-id>` to let unauthenticated requests fall through to a designated "anonymous" Consumer with their own restricted Consumer Group budget, instead of returning `401`. Useful for public/free-tier endpoints. See the [key-auth reference](/plugins/key-auth/) for the full set of options.

**Scaling to a real IdP.** When the platform is ready for end-user identity (instead of static API keys), swap key-auth for [openid-connect](/plugins/openid-connect/) and map JWT claims to Consumer Groups. Application code only changes the auth header it sends; the rest of this recipe (semantic cache, compression, ai-proxy-advanced, ai-rate-limiting-advanced) stays put. See the [basic-llm-routing recipe](/cookbooks/basic-llm-routing/) for the JWT pattern, or the [claude-code-sso recipe](/cookbooks/claude-code-sso/) for an end-to-end Okta integration.

### AI Semantic Cache: embedding-based response caching

The AI Semantic Cache Plugin intercepts requests before they reach the LLM, embeds the latest
user message, and searches Redis for a cached response to a semantically similar question. On a
match, Kong returns the cached response immediately. The cache is shared across all Consumers,
so one user's question benefits every later user asking something similar. The default threshold
is conservative enough that paraphrased duplicates ("What is machine learning?" vs "Explain
machine learning to me") match while topically related but distinct questions ("What is the
capital of France?" vs "What is the capital of Germany?") do not.

#### Configuration details

{%- raw %}
```yaml
- name: ai-semantic-cache
  config:
    cache_ttl: 300
    message_countback: 1
    stop_on_failure: false
    embeddings:
      auth:
        header_name: Authorization
        header_value: ${{ env "DECK_OPENAI_TOKEN" }}
      model:
        provider: openai
        name: ${{ env "DECK_EMBEDDINGS_MODEL" }}
    vectordb:
      dimensions: ${{ env "DECK_EMBEDDINGS_DIMENSIONS" }}
      distance_metric: cosine
      strategy: redis
      threshold: 0.3
      redis:
        host: ${{ env "DECK_REDIS_HOST" }}
        port: 6379
```
{% endraw -%}
{:.no-copy-code}

**`threshold: 0.3`**. The maximum cosine **distance** between the incoming prompt's embedding and a cached prompt for a hit to register (lower is stricter). With `text-embedding-3-small`, paraphrased questions like `"What is machine learning?"` and `"Explain machine learning to me"` typically sit around 0.20–0.28 distance, so `0.3` admits legitimate paraphrases. Distinct prompts (e.g. `"Say hello"` vs an ML question) sit at distance ≥ 0.75 and are correctly excluded. Tighten toward `0.2` if you see semantically distinct prompts colliding; loosen toward `0.4` to catch broader rephrasings at the risk of incorrect cache hits.

**`cache_ttl: 300`**. Cached responses expire after 5 minutes (300 seconds). This balances cost savings with freshness. For factual queries that do not change often, increase this to `3600` (1 hour) or higher. For rapidly changing data, reduce it.

**`message_countback: 1`**. Only the latest user message is vectorized for cache lookup. Set this to `2` or `3` for multi-turn conversations where the preceding messages provide important context that changes the expected response.

**`stop_on_failure: false`**. If Redis is unreachable or the embeddings call fails, the request falls through to the LLM instead of returning an error. The cache layer is purely additive and never blocks requests.

On a cache hit, Kong returns the stored response with `X-Cache-Status: Hit` and no `X-Kong-Upstream-Latency` header (no LLM call was made). On a miss, the request continues to the next Plugin, and Kong caches the response for future requests.

**Cache hits are model-agnostic.** Because the AI Semantic Cache Plugin runs _before_ the AI Proxy Advanced Plugin, the routing decision is skipped on a hit. The cached response is returned regardless of which target the request would otherwise have selected. A simple paraphrased query that would route to the cheap model can therefore receive a cached response originally generated by the expensive model, and vice versa. The cache key is the prompt embedding alone; it carries no model affinity. If you need per-model caches (e.g. to avoid serving a `gpt-4o` answer to a `gpt-4o-mini` request), partition by Route or by Consumer rather than relying on the single shared cache.

### AI Prompt Compressor: token reduction via LLMLingua

The AI Prompt Compressor Plugin sends prompts to a sidecar LLMLingua service that removes
redundant tokens while preserving semantic meaning. The LLM processes the compressed prompt and
the bill reflects the smaller count. Short prompts pass through unchanged because they do not
benefit from compression and risk losing critical information.

#### Configuration details

{%- raw %}
```yaml
- name: ai-prompt-compressor
  ordering:
    before:
      access:
        - ai-proxy-advanced
  config:
    compressor_type: rate
    compressor_url: ${{ env "DECK_COMPRESSOR_URL" }}
    stop_on_error: false
    compression_ranges:
      - min_tokens: 100
        max_tokens: 1000000
        value: 0.6
```
{% endraw -%}
{:.no-copy-code}

**`ordering.before.access: [ai-proxy-advanced]`**. Uses [dynamic plugin ordering](/gateway/entities/plugin/#dynamic-plugin-ordering) to run the compressor before `ai-proxy-advanced` in the access phase. The compressor operates on prompts in OpenAI format, so running it before `ai-proxy-advanced` ensures the proxy receives the compressed prompt and then handles any provider-specific request translation. This recipe sets the ordering explicitly so the same configuration works across every provider.

**`compressor_type: rate`**. The `value` in `compression_ranges` is a retention ratio. A value of `0.6` retains 60% of tokens, a 40% reduction. Aggressive but effective for verbose RAG contexts or long system prompts. The alternative `target_token` mode compresses to a fixed token count, useful when you need to guarantee staying under a specific context window size. See the [ai-prompt-compressor reference](/plugins/ai-prompt-compressor/) for the full list of supported compressor types and tag-based selective compression.

**`compression_ranges`**. Only prompts between `min_tokens` and `max_tokens` are compressed. You can define multiple ranges with different retention ratios so medium-length prompts get light compression and long prompts get aggressive compression.

**`stop_on_error: false`**. If the LLMLingua service is unreachable, the uncompressed prompt is forwarded to the LLM. Like the cache, compression is purely additive.

The compression round-trip adds latency (several hundred milliseconds on CPU hardware). This appears in `X-Kong-Proxy-Latency`. For latency-sensitive workloads, consider GPU-backed LLMLingua deployment.

### AI Proxy Advanced: semantic model routing and provider translation

The AI Proxy Advanced Plugin handles everything from the model-selection decision through the
upstream call. The recipe configures two targets, each with a `description` field that captures
the kinds of queries it should serve. When a request arrives, the Plugin embeds the prompt,
computes cosine similarity against each target's description embedding (stored in Redis), and
routes to the closest match. The `CATCHALL` target handles simple or off-topic queries; the
"detailed reasoning" target handles complex work that warrants the premium model.

#### Configuration details

{%- raw %}
```yaml
- name: ai-proxy-advanced
  config:
    max_request_body_size: 10485760
    response_streaming: allow
    balancer:
      algorithm: semantic
    embeddings:
      auth:
        header_name: Authorization
        header_value: ${{ env "DECK_OPENAI_TOKEN" }}
      model:
        provider: openai
        name: ${{ env "DECK_EMBEDDINGS_MODEL" }}
    vectordb:
      dimensions: ${{ env "DECK_EMBEDDINGS_DIMENSIONS" }}
      distance_metric: cosine
      strategy: redis
      threshold: ${{ env "DECK_PROXY_THRESHOLD" }}
      redis:
        host: ${{ env "DECK_REDIS_HOST" }}
        port: 6379
    targets:
      - route_type: llm/v1/chat
        description: CATCHALL
        model:
          model_alias: auto
          name: ${{ env "DECK_CHAT_MODEL_1" }}
          options:
            input_cost: ${{ env "DECK_INPUT_COST_1" }}
            output_cost: ${{ env "DECK_OUTPUT_COST_1" }}
      - route_type: llm/v1/chat
        description: Software architecture, system design, and complex code generation.
        model:
          model_alias: auto
          name: ${{ env "DECK_CHAT_MODEL_2" }}
          options:
            input_cost: ${{ env "DECK_INPUT_COST_2" }}
            output_cost: ${{ env "DECK_OUTPUT_COST_2" }}
```
{% endraw -%}
{: .no-copy-code .collapsible }

**`balancer.algorithm: semantic`**. Selects semantic similarity as the routing strategy. The Plugin embeds the prompt, computes cosine similarity against each target's `description` embedding, and routes to the highest-similarity target above the threshold. Other balancing algorithms (round-robin, lowest-latency, lowest-usage, priority) are documented in the [ai-proxy-advanced reference](/plugins/ai-proxy-advanced/).

**`threshold` (env var `DECK_PROXY_THRESHOLD`)**. The maximum cosine **distance** between the incoming prompt's embedding and a target's `description` embedding for that target to be eligible (lower is stricter, same convention as the AI Semantic Cache Plugin). The right value depends on which embedding model you're using. Different models live on different absolute distance scales for the same content. The recipe ships with `0.75` for OpenAI's `text-embedding-3-small` and `0.85` for Bedrock's `amazon.titan-embed-text-v2:0`; both values were measured against the demo prompts so the COMPLEX prompt routes to the expensive target while simple prompts fall to CATCHALL. If you swap the embedding model, expect to retune. Measure cosine distance from your representative prompts to each target description and pick a value above the legitimate matches but below the false-positive zone.

**`model.model_alias: auto`**. Both targets share the same alias so clients can send a single, stable `model` value (`"auto"`) and let Kong choose the upstream model. Without an alias, the Plugin enforces strict equality between the request's `model` field and the target's configured `model.name` and rejects mismatches with `400`. With identical aliases on every target, alias matching admits every target and the configured `balancer.algorithm` (`semantic` here) makes the final choice.

**`description: CATCHALL`**. Designates this target as the fallback. Simple, general, or off-topic queries that do not exceed the similarity threshold for any other target land here. Point this at your cheapest model.

**`description: "Software architecture, system design, and complex code generation."`**. Short anchor phrases produce sharper embeddings than long prose. The centroid concentrates rather than averaging across many concepts. Tune this to a single concise phrase that captures the kind of query that warrants the premium model. Avoid multi-sentence descriptions; they dilute similarity scores and route on-topic prompts to CATCHALL.

**`input_cost`** and **`output_cost`**. Cost per 1 million tokens, in dollars. These values are used by the AI Rate Limiting Advanced Plugin to compute the actual dollar cost of each request. Set them to match your provider's current pricing. The cost formula is: `cost = (prompt_tokens x input_cost + completion_tokens x output_cost) / 1,000,000`.

**`max_request_body_size`** and **`response_streaming`**. The recipe sets a 10 MB request limit (large enough for typical conversation contexts and modest RAG injections) and allows streaming responses. Tighten or relax both based on the workload you expect.

This recipe uses the default `llm_format: openai`, which accepts OpenAI-format requests and normalizes provider responses back to OpenAI format. Set `llm_format` to a provider's native format to pass requests through without transformation when you already have code using a provider's SDK. See the [ai-proxy-advanced reference](/plugins/ai-proxy-advanced/) for the supported native formats.

### AI Rate Limiting Advanced: dollar-based budget caps

The AI Rate Limiting Advanced Plugin enforces dollar-based budget caps per Consumer Group. Each
Consumer Group gets its own Plugin instance with a different `limit`. Because the budget is
expressed in dollars and computed from the cost values on the AI Proxy Advanced targets, a
$10/hour budget lasts much longer on the cheap model than on the expensive one, the right
incentive structure for cost optimization.

#### Configuration details

```yaml
consumer_groups:
  - name: standard-tier
    plugins:
      - name: ai-rate-limiting-advanced
        config:
          tokens_count_strategy: cost
          llm_providers:
            - name: openai
              limit:
                - 1
              window_size:
                - 3600
          window_type: sliding
          strategy: local
  - name: premium-tier
    plugins:
      - name: ai-rate-limiting-advanced
        config:
          tokens_count_strategy: cost
          llm_providers:
            - name: openai
              limit:
                - 5
              window_size:
                - 3600
          window_type: sliding
          strategy: local
```
{:.no-copy-code}

**`tokens_count_strategy: cost`**. Instead of counting raw tokens, Kong computes the dollar cost of each response using the `input_cost` and `output_cost` values from the AI Proxy Advanced target that served the request. See the [ai-rate-limiting-advanced reference](/plugins/ai-rate-limiting-advanced/) for the full set of counting strategies (request count, prompt tokens, completion tokens, total tokens, cost).

**`limit: [1]`** and **`limit: [5]`**. Dollar amounts per window. Standard tier gets $1/hour, premium gets $5/hour. The recipe uses small budgets so a single demo run produces visible debits in both tiers; production limits are typically much higher (e.g. `[10]` standard / `[100]` premium). You can define multiple windows for the same provider, e.g. `limit: [0.25, 1]` with `window_size: [60, 3600]` caps spending at $0.25/minute AND $1/hour.

{:.info}
> **Cost is reflected on the next request.** The rate limiting Plugin computes cost from the
> LLM response, which means the cost of a request is deducted on the *following* request. The
> current request always completes. The limit is checked before the request is sent.

**`window_type: sliding`**. Uses a sliding window that considers the previous window's rate when evaluating the current one. This prevents burst spending at window boundaries. Use `fixed` for simpler, bucket-based limiting.

**`strategy: local`**. Counters are stored in Kong's in-memory dictionary on each node. For multi-node deployments, use `redis` to share counters across nodes, and set `decrease_by_fractions_in_redis: true` since cost values are fractional.

Kong sets response headers on every request so clients can track their remaining budget: `X-AI-RateLimit-Limit-hour-openai: 1` and `X-AI-RateLimit-Remaining-hour-openai: 0.987`. When the budget is exhausted, Kong returns `429 Too Many Requests` with a `Retry-After` header. The window label in the header (`hour`, `minute`, etc.) is derived from the configured `window_size`: `3600` becomes `hour`, `60` becomes `minute`, and non-standard sizes use the raw seconds value. Both targets in the recipe use `name: openai`, so a single bucket tracks total tier spend across `gpt-4o` and `gpt-4o-mini` together; to split budgets per model, add separate `llm_providers` entries with distinct `name` values or break each model onto its own Route.

For simplicity, this recipe stores Consumer API keys directly in Plugin config and provider credentials in environment variables. In production, reference both through [Kong Vaults](/gateway/latest/kong-enterprise/secrets-management/) instead, backed by your preferred secret manager (AWS Secrets Manager, HashiCorp Vault, GCP Secret Manager, or Azure Key Vault).

### Example response

The same OpenAI-format request goes through Kong. The headers prove what each Plugin layer did:
which model semantic routing selected (`X-Kong-LLM-Model`), whether the cache served the response
(`X-Cache-Status`), and how much budget remains (`X-AI-RateLimit-Remaining-hour-*`).

Request body (a simple factual question):

```json
{
  "messages": [{ "role": "user", "content": "What is the capital of France?" }]
}
```
{:.no-copy-code}

Response headers from the first call (cache miss, routed to the cheap model):

```text
HTTP/1.1 200 OK
X-Kong-LLM-Model: openai/gpt-4o-mini
X-Cache-Status: Miss
X-AI-RateLimit-Limit-hour-openai: 10
X-AI-RateLimit-Remaining-hour-openai: 9.999
X-Kong-Upstream-Latency: 845
X-Kong-Proxy-Latency: 120
```
{:.no-copy-code}

Response headers from a paraphrased follow-up call (cache hit, no upstream call):

```text
HTTP/1.1 200 OK
X-Cache-Status: Hit
X-Kong-Proxy-Latency: 45
X-AI-RateLimit-Remaining-hour-openai: 9.999
```
{:.no-copy-code}

Kong adds the following response headers:

{% table %}
columns:
  - title: Header
    key: header
  - title: Description
    key: description
rows:
  - header: "`X-Kong-LLM-Model`"
    description: "Upstream model that served the request, prefixed with the provider name and resolved by semantic routing"
  - header: "`X-Cache-Status`"
    description: "`Hit` or `Miss`. On a hit, no upstream LLM call was made"
  - header: "`X-AI-RateLimit-Limit-hour-<provider>`"
    description: "Dollar budget per 1-hour window for this Consumer's tier (window label derived from `window_size: 3600`)"
  - header: "`X-AI-RateLimit-Remaining-hour-<provider>`"
    description: "Dollars remaining in the current window. Reflects cost of all completed requests"
  - header: "`X-Kong-Upstream-Latency`"
    description: "Time (ms) Kong spent waiting for the provider to respond. Absent on cache hits (no upstream call)"
  - header: "`X-Kong-Proxy-Latency`"
    description: "Time (ms) Kong spent processing the request. Includes embedding lookups and compression round-trip"
{% endtable %}

Kong attaches `X-Consumer-Username` to the upstream request (so the LLM provider sees who is calling) but does not echo it back to the downstream client. Per-Consumer attribution shows up in Konnect's analytics views. See "Explore in Konnect" below.

## Apply the Kong configuration

The configuration below creates a {{site.base_gateway}} Service and Route at `/llm-cost-optimization`,
attaches the [key-auth](/plugins/key-auth/) Plugin to identify Consumers via the `apikey` header,
and chains [ai-semantic-cache](/plugins/ai-semantic-cache/),
[ai-prompt-compressor](/plugins/ai-prompt-compressor/), and
[ai-proxy-advanced](/plugins/ai-proxy-advanced/) for cache, compression, and routing. Two
Consumer Groups (`standard-tier` and `premium-tier`) each carry an
[ai-rate-limiting-advanced](/plugins/ai-rate-limiting-advanced/) Plugin with a different dollar
budget. All resources are scoped using `select_tags` and a kongctl `namespace` so they can be
cleanly torn down. See the [kongctl documentation](/kongctl/) for more on federated configuration
management.

First, adopt the quickstart Control Plane into a kongctl namespace so the apply commands below can manage it:

```bash
kongctl adopt control-plane "${KONNECT_CONTROL_PLANE_NAME}" \
  --namespace "${KONNECT_CONTROL_PLANE_NAME}" \
  --pat "${KONNECT_TOKEN}"
```

Adoption stamps the `KONGCTL-namespace` label on the Control Plane.

Provider credentials, the Redis host, and the compressor URL are exported once during
Prerequisites. Each tab below sets only the per-provider model and cost env vars and runs the
apply.

{% navtabs "Providers" %}
{% tab OpenAI %}

Export the per-provider env vars:

```bash
export DECK_CHAT_MODEL_1='gpt-4o-mini'         # cheap: general queries
export DECK_CHAT_MODEL_2='gpt-4o'              # expensive: complex tasks
export DECK_INPUT_COST_1='0.15'                # gpt-4o-mini: $0.15 per 1M input tokens
export DECK_OUTPUT_COST_1='0.60'               # gpt-4o-mini: $0.60 per 1M output tokens
export DECK_INPUT_COST_2='2.50'                # gpt-4o: $2.50 per 1M input tokens
export DECK_OUTPUT_COST_2='10.00'              # gpt-4o: $10.00 per 1M output tokens
export DECK_EMBEDDINGS_MODEL='text-embedding-3-small'
export DECK_EMBEDDINGS_DIMENSIONS='1536'
export DECK_PROXY_THRESHOLD='0.75'             # max cosine distance, tuned for text-embedding-3-small
```

Apply the Kong configuration:

```bash
{%- raw %}
cat <<'EOF' > kong-recipe.yaml
_format_version: '3.0'
_info:
  select_tags:
  - llm-cost-optimization-recipe
services:
- name: llm-cost-optimization
  url: http://localhost
  routes:
  - name: llm-cost-optimization
    paths:
    - /llm-cost-optimization
    protocols:
    - http
    - https
    methods:
    - POST
    - OPTIONS
    strip_path: true
  plugins:
  - name: key-auth
    instance_name: llm-cost-optimization-auth
    config:
      key_names:
      - apikey
      hide_credentials: true
  - name: ai-semantic-cache
    instance_name: llm-cost-optimization-cache
    config:
      cache_ttl: 300
      message_countback: 1
      stop_on_failure: false
      embeddings:
        auth:
          header_name: Authorization
          header_value: ${{ env "DECK_OPENAI_TOKEN" }}
        model:
          provider: openai
          name: ${{ env "DECK_EMBEDDINGS_MODEL" }}
      vectordb:
        dimensions: ${{ env "DECK_EMBEDDINGS_DIMENSIONS" }}
        distance_metric: cosine
        strategy: redis
        threshold: 0.3
        redis:
          host: ${{ env "DECK_REDIS_HOST" }}
          port: 6379
  - name: ai-prompt-compressor
    instance_name: llm-cost-optimization-compressor
    ordering:
      before:
        access:
        - ai-proxy-advanced
    config:
      compressor_type: rate
      compressor_url: ${{ env "DECK_COMPRESSOR_URL" }}
      stop_on_error: false
      compression_ranges:
      - min_tokens: 100
        max_tokens: 1000000
        value: 0.6
  - name: ai-proxy-advanced
    instance_name: llm-cost-optimization-proxy
    config:
      max_request_body_size: 10485760
      response_streaming: allow
      balancer:
        algorithm: semantic
      embeddings:
        auth:
          header_name: Authorization
          header_value: ${{ env "DECK_OPENAI_TOKEN" }}
        model:
          provider: openai
          name: ${{ env "DECK_EMBEDDINGS_MODEL" }}
      vectordb:
        dimensions: ${{ env "DECK_EMBEDDINGS_DIMENSIONS" }}
        distance_metric: cosine
        strategy: redis
        threshold: ${{ env "DECK_PROXY_THRESHOLD" }}
        redis:
          host: ${{ env "DECK_REDIS_HOST" }}
          port: 6379
      targets:
      - route_type: llm/v1/chat
        description: CATCHALL
        auth:
          header_name: Authorization
          header_value: ${{ env "DECK_OPENAI_TOKEN" }}
        model:
          model_alias: auto
          provider: openai
          name: ${{ env "DECK_CHAT_MODEL_1" }}
          options:
            input_cost: ${{ env "DECK_INPUT_COST_1" }}
            output_cost: ${{ env "DECK_OUTPUT_COST_1" }}
        logging:
          log_payloads: true
          log_statistics: true
      - route_type: llm/v1/chat
        description: Software architecture, system design, and complex code generation.
        auth:
          header_name: Authorization
          header_value: ${{ env "DECK_OPENAI_TOKEN" }}
        model:
          model_alias: auto
          provider: openai
          name: ${{ env "DECK_CHAT_MODEL_2" }}
          options:
            input_cost: ${{ env "DECK_INPUT_COST_2" }}
            output_cost: ${{ env "DECK_OUTPUT_COST_2" }}
        logging:
          log_payloads: true
          log_statistics: true
consumers:
- username: standard-user
  keyauth_credentials:
  - key: standard-api-key
- username: premium-user
  keyauth_credentials:
  - key: premium-api-key
consumer_groups:
- name: standard-tier
  consumers:
  - username: standard-user
  plugins:
  - name: ai-rate-limiting-advanced
    config:
      tokens_count_strategy: cost
      llm_providers:
      - name: openai
        limit:
        - 1
        window_size:
        - 3600
      window_type: sliding
      strategy: local
- name: premium-tier
  consumers:
  - username: premium-user
  plugins:
  - name: ai-rate-limiting-advanced
    config:
      tokens_count_strategy: cost
      llm_providers:
      - name: openai
        limit:
        - 5
        window_size:
        - 3600
      window_type: sliding
      strategy: local
EOF
{% endraw -%}

echo "
_defaults:
  kongctl:
    namespace: llm-cost-optimization-recipe
control_planes:
  - ref: recipe-cp
    name: \"${KONNECT_CONTROL_PLANE_NAME}\"
    _deck:
      files:
        - kong-recipe.yaml
      flags:
        - --no-mask-deck-env-vars-value
" | kongctl sync -f - -o text --auto-approve --pat "${KONNECT_TOKEN}"

rm -f kong-recipe.yaml
```
{: data-test-step="block" .collapsible }

{% endtab %}
{% tab AWS Bedrock %}

Export the per-provider env vars:

```bash
export DECK_CHAT_MODEL_1='amazon.nova-lite-v1:0'                            # cheap: general queries
export DECK_CHAT_MODEL_2='global.anthropic.claude-sonnet-4-5-20250929-v1:0' # expensive: complex tasks (uses cross-region inference profile — required for Claude 4.5)
export DECK_INPUT_COST_1='0.06'                # Nova Lite: $0.06 per 1M input tokens
export DECK_OUTPUT_COST_1='0.24'               # Nova Lite: $0.24 per 1M output tokens
export DECK_INPUT_COST_2='3.00'                # Claude Sonnet: $3.00 per 1M input tokens
export DECK_OUTPUT_COST_2='15.00'              # Claude Sonnet: $15.00 per 1M output tokens
export DECK_EMBEDDINGS_MODEL='amazon.titan-embed-text-v2:0'
export DECK_EMBEDDINGS_DIMENSIONS='1024'
export DECK_PROXY_THRESHOLD='0.85'             # max cosine distance, tuned for amazon.titan-embed-text-v2:0
```

Apply the Kong configuration:

```bash
{%- raw %}
cat <<'EOF' > kong-recipe.yaml
_format_version: '3.0'
_info:
  select_tags:
  - llm-cost-optimization-recipe
services:
- name: llm-cost-optimization
  url: http://localhost
  routes:
  - name: llm-cost-optimization
    paths:
    - /llm-cost-optimization
    protocols:
    - http
    - https
    methods:
    - POST
    - OPTIONS
    strip_path: true
  plugins:
  - name: key-auth
    instance_name: llm-cost-optimization-auth
    config:
      key_names:
      - apikey
      hide_credentials: true
  - name: ai-semantic-cache
    instance_name: llm-cost-optimization-cache
    config:
      cache_ttl: 300
      message_countback: 1
      stop_on_failure: false
      embeddings:
        auth:
          aws_access_key_id: ${{ env "DECK_AWS_ACCESS_KEY_ID" }}
          aws_secret_access_key: ${{ env "DECK_AWS_SECRET_ACCESS_KEY" }}
        model:
          provider: bedrock
          name: ${{ env "DECK_EMBEDDINGS_MODEL" }}
          options:
            bedrock:
              aws_region: ${{ env "DECK_AWS_REGION" }}
      vectordb:
        dimensions: ${{ env "DECK_EMBEDDINGS_DIMENSIONS" }}
        distance_metric: cosine
        strategy: redis
        threshold: 0.3
        redis:
          host: ${{ env "DECK_REDIS_HOST" }}
          port: 6379
  - name: ai-prompt-compressor
    instance_name: llm-cost-optimization-compressor
    ordering:
      before:
        access:
        - ai-proxy-advanced
    config:
      compressor_type: rate
      compressor_url: ${{ env "DECK_COMPRESSOR_URL" }}
      stop_on_error: false
      compression_ranges:
      - min_tokens: 100
        max_tokens: 1000000
        value: 0.6
  - name: ai-proxy-advanced
    instance_name: llm-cost-optimization-proxy
    config:
      max_request_body_size: 10485760
      response_streaming: allow
      balancer:
        algorithm: semantic
      embeddings:
        auth:
          aws_access_key_id: ${{ env "DECK_AWS_ACCESS_KEY_ID" }}
          aws_secret_access_key: ${{ env "DECK_AWS_SECRET_ACCESS_KEY" }}
        model:
          provider: bedrock
          name: ${{ env "DECK_EMBEDDINGS_MODEL" }}
          options:
            bedrock:
              aws_region: ${{ env "DECK_AWS_REGION" }}
      vectordb:
        dimensions: ${{ env "DECK_EMBEDDINGS_DIMENSIONS" }}
        distance_metric: cosine
        strategy: redis
        threshold: ${{ env "DECK_PROXY_THRESHOLD" }}
        redis:
          host: ${{ env "DECK_REDIS_HOST" }}
          port: 6379
      targets:
      - route_type: llm/v1/chat
        description: CATCHALL
        auth:
          aws_access_key_id: ${{ env "DECK_AWS_ACCESS_KEY_ID" }}
          aws_secret_access_key: ${{ env "DECK_AWS_SECRET_ACCESS_KEY" }}
        model:
          model_alias: auto
          provider: bedrock
          name: ${{ env "DECK_CHAT_MODEL_1" }}
          options:
            bedrock:
              aws_region: ${{ env "DECK_AWS_REGION" }}
            input_cost: ${{ env "DECK_INPUT_COST_1" }}
            output_cost: ${{ env "DECK_OUTPUT_COST_1" }}
        logging:
          log_payloads: true
          log_statistics: true
      - route_type: llm/v1/chat
        description: Software architecture, system design, and complex code generation.
        auth:
          aws_access_key_id: ${{ env "DECK_AWS_ACCESS_KEY_ID" }}
          aws_secret_access_key: ${{ env "DECK_AWS_SECRET_ACCESS_KEY" }}
        model:
          model_alias: auto
          provider: bedrock
          name: ${{ env "DECK_CHAT_MODEL_2" }}
          options:
            bedrock:
              aws_region: ${{ env "DECK_AWS_REGION" }}
            input_cost: ${{ env "DECK_INPUT_COST_2" }}
            output_cost: ${{ env "DECK_OUTPUT_COST_2" }}
        logging:
          log_payloads: true
          log_statistics: true
consumers:
- username: standard-user
  keyauth_credentials:
  - key: standard-api-key
- username: premium-user
  keyauth_credentials:
  - key: premium-api-key
consumer_groups:
- name: standard-tier
  consumers:
  - username: standard-user
  plugins:
  - name: ai-rate-limiting-advanced
    config:
      tokens_count_strategy: cost
      llm_providers:
      - name: bedrock
        limit:
        - 1
        window_size:
        - 3600
      window_type: sliding
      strategy: local
- name: premium-tier
  consumers:
  - username: premium-user
  plugins:
  - name: ai-rate-limiting-advanced
    config:
      tokens_count_strategy: cost
      llm_providers:
      - name: bedrock
        limit:
        - 5
        window_size:
        - 3600
      window_type: sliding
      strategy: local
EOF
{% endraw -%}

echo "
_defaults:
  kongctl:
    namespace: llm-cost-optimization-recipe
control_planes:
  - ref: recipe-cp
    name: \"${KONNECT_CONTROL_PLANE_NAME}\"
    _deck:
      files:
        - kong-recipe.yaml
      flags:
        - --no-mask-deck-env-vars-value
" | kongctl sync -f - -o text --auto-approve --pat "${KONNECT_TOKEN}"

rm -f kong-recipe.yaml
```
{: data-test-step="block" .collapsible }

{% endtab %}
{% endnavtabs %}

## Try it out

The demo script exercises all five Plugins in sequence: simple and complex queries to demonstrate
semantic routing, a paraphrased follow-up to trigger a cache hit, a verbose prompt to show
compression in action, parallel calls from both tiers to compare rate limit budgets, and a final
invalid-API-key call to confirm Kong rejects unauthorized requests before any upstream call.

{:.info}
> The demo passes the API key via `default_headers` because the OpenAI SDK reserves `api_key` for the `Authorization: Bearer` header. To let clients pass the key through `api_key` directly, attach a [pre-function](/plugins/pre-function/) Plugin that copies the Bearer token to the `apikey` header server-side. See [Authenticate OpenAI SDK clients with Key Auth](https://developer.konghq.com/how-to/authenticate-openai-sdk-clients-with-key-auth/) for the pattern.

Create the demo script:

```bash
cat <<'EOF' > demo.py
"""LLM cost optimization demo. See README for context."""

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
CHAT_MODEL = "auto"  # shared model_alias on both ai-proxy-advanced targets
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
MAGENTA= lambda s: _c("35", s)


def make_client(api_key: str) -> OpenAI:
    """Construct an OpenAI client that sends the given API key in the apikey header."""
    return OpenAI(
        base_url=BASE_URL,
        api_key="unused",  # required by the SDK; Kong reads the apikey header instead
        default_headers={"apikey": api_key},
    )


standard_client = make_client("standard-api-key")
premium_client = make_client("premium-api-key")


def chat(client: OpenAI, prompt: str, label: str = "", original_tokens: int | None = None,
         max_tokens: int = 250) -> float:
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
        print(f"\n  [{BOLD(label)}] {status} {e.message}  ({elapsed:.2f}s)")
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
        # Highlight the reduction — that's the headline of this section.
        print(f"    Tokens:   pre-compression~{original_tokens} -> "
              f"billed={MAGENTA(BOLD(str(usage.prompt_tokens)))} "
              f"({MAGENTA(BOLD(f'{reduction_pct:.0f}% reduction'))}), "
              f"completion={usage.completion_tokens}")
    else:
        print(f"    Tokens:   prompt={usage.prompt_tokens}, "
              f"completion={usage.completion_tokens}, total={usage.total_tokens}")
    print(f"    Latency:  {elapsed:.2f}s ({DIM(latency_extra)})")
    print(f"    Response: {DIM(text)}{DIM('...') if len(text) >= 120 else ''}")

    # Highlight the rate-limit remaining — that's the headline for section 4.
    for k in sorted(h.keys()):
        if "ai-ratelimit" in k.lower():
            value = h[k]
            if "remaining" in k.lower():
                print(f"    {k}: {BLUE(BOLD(value))}")
            else:
                print(f"    {k}: {value}")

    return elapsed


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
    print("    Each consumer sends a unique prompt to bypass the cache and trigger a")
    print("    real upstream call so the per-tier budget visibly debits.")

    print(f"\n  {BOLD('Standard user')} ($1/hour budget):")
    chat(standard_client, "Say hello in one sentence.", "STANDARD")

    print(f"\n  {BOLD('Premium user')} ($5/hour budget):")
    chat(premium_client, "Tell me an interesting fact about octopuses in one sentence.", "PREMIUM")

    section("5. AUTH BOUNDARY. Invalid API key rejected before upstream call")
    bad_key = "not-a-real-key"
    print(f"    Sending request with apikey='{RED(bad_key)}' (not registered with any Consumer)...")
    bad_client = make_client(bad_key)
    chat(bad_client, "Hello", "BLOCKED")
    print(f"    {DIM('Kong rejected the request before any upstream call (no provider quota consumed).')}")

    section("DONE. Four cost optimization layers active simultaneously:")
    print(f"  {GREEN('Semantic routing')}:    cheap model for simple, expensive for complex")
    print(f"  {GREEN('Semantic caching')}:    instant $0 responses for similar questions")
    print(f"  {GREEN('Prompt compression')}:  fewer tokens sent to the LLM")
    print(f"  {GREEN('Cost rate limiting')}:  per-consumer dollar-based budget caps")
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

Example output (using the OpenAI tab's model env vars):

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
    x-ai-ratelimit-limit-hour-openai: 1
    x-ai-ratelimit-remaining-hour-openai: 1

  [COMPLEX] 'Design a Python FastAPI application with OAuth2 JWT authentication, ...'
    Model:    openai/gpt-4o
    Cache:    Miss
    Tokens:   prompt=40, completion=250, total=290
    Latency:  3.40s (upstream: 2870ms)
    Response: Designing a Python FastAPI application with OAuth2 JWT authentication, PostgreSQL integration...
    x-ai-ratelimit-limit-hour-openai: 1
    x-ai-ratelimit-remaining-hour-openai: 0.9999937

=================================================================
2. SEMANTIC CACHING. Cache Hits for Similar Questions
=================================================================

  [MISS] 'What is machine learning?'
    Model:    openai/gpt-4o-mini
    Cache:    Miss
    Tokens:   prompt=12, completion=250, total=262
    Latency:  3.20s (upstream: 2810ms)
    Response: Machine learning is a subset of artificial intelligence (AI) that focuses on the development...

  [HIT] 'Explain machine learning to me'
    Model:    (served from cache)
    Cache:    Hit
    Tokens:   prompt=12, completion=250, total=262
    Latency:  0.45s (cache hit, no upstream call)
    Response: Machine learning is a subset of artificial intelligence (AI) that focuses on the development...

    Cache speedup: 7.1x faster

=================================================================
3. PROMPT COMPRESSION. Reduced Token Usage on Long Prompts
=================================================================

  [COMPRESSED] 'I would really like you to provide me with a very detailed and comprehen...'
    Model:    openai/gpt-4o-mini
    Cache:    Miss
    Tokens:   pre-compression~138 -> billed=87 (37% reduction), completion=250
    Latency:  4.10s (upstream: 3580ms)
    Response: Photosynthesis is a vital biochemical process that occurs in green plants, algae, and some...
    (LLMLingua compressed the prompt server-side before reaching the LLM.
     'billed' is the post-compression token count the provider charged for.)

=================================================================
4. COST-BASED RATE LIMITING. Tiered Budget Caps
=================================================================
    Each consumer sends a unique prompt to bypass the cache and trigger a
    real upstream call so the per-tier budget visibly debits.

  Standard user ($1/hour budget):

  [STANDARD] 'Say hello in one sentence.'
    Model:    openai/gpt-4o-mini
    Cache:    Miss
    Tokens:   prompt=13, completion=9, total=22
    Latency:  0.96s (upstream: 438ms)
    Response: Hello! How can I assist you today?
    x-ai-ratelimit-limit-hour-openai: 1
    x-ai-ratelimit-remaining-hour-openai: 0.9858

  Premium user ($5/hour budget):

  [PREMIUM] 'Tell me an interesting fact about octopuses in one sentence.'
    Model:    openai/gpt-4o-mini
    Cache:    Miss
    Tokens:   prompt=15, completion=27, total=42
    Latency:  1.08s (upstream: 612ms)
    Response: Octopuses have three hearts and blue blood, with two hearts pumping blood to the gills...
    x-ai-ratelimit-limit-hour-openai: 5
    x-ai-ratelimit-remaining-hour-openai: 4.9999858

=================================================================
5. AUTH BOUNDARY. Invalid API key rejected before upstream call
=================================================================
    Sending request with apikey='not-a-real-key' (not registered with any Consumer)...

  [BLOCKED] 401 Error code: 401 - {'message': 'Unauthorized'}  (0.01s)
    Kong rejected the request before any upstream call (no provider quota consumed).

=================================================================
DONE. Four cost optimization layers active simultaneously:
  Semantic routing:    cheap model for simple, expensive for complex
  Semantic caching:    instant $0 responses for similar questions
  Prompt compression:  fewer tokens sent to the LLM
  Cost rate limiting:  per-consumer dollar-based budget caps
=================================================================
```
{: .no-copy-code .collapsible }

### What happened

1. **Semantic routing** selected `openai/gpt-4o-mini` for the simple factual question and `openai/gpt-4o` for the complex architecture design prompt. The `X-Kong-LLM-Model` header confirms which model served each request. The simple query cost fractions of a cent; the complex query cost more but was routed to a model capable of handling it.

2. **Semantic caching** returned the cached response for `"Explain machine learning to me"` because it was semantically close to `"What is machine learning?"`. The `X-Cache-Status: Hit` header and absence of `X-Kong-Upstream-Latency` confirm no LLM call was made. Response time dropped from ~6.1s to ~0.9s. Note that `Model:` shows `(served from cache)` rather than a specific model. The AI Semantic Cache Plugin runs _before_ the AI Proxy Advanced Plugin, so the routing decision is skipped entirely on a hit. A cached response can serve a prompt that would otherwise have routed to a different model than the one that originally produced it (see "How it works" for cross-model cache details).

3. **Prompt compression** reduced the original ~138-token photosynthesis prompt to 87 billed tokens before reaching the LLM (a 37% reduction at `value: 0.6`). The script counts the original tokens locally with `tiktoken` so the delta is visible in the output; the LLM was billed only for the compressed count.

4. **Cost-based rate limiting** showed different budget headers for each tier: `x-ai-ratelimit-limit-hour-openai: 1` for standard ($/hour) versus `5` for premium. Each tier's `remaining` value decremented by the computed cost of that Consumer's request, tracking actual dollar spend rather than raw token counts. The recipe sets these intentionally low (production deployments typically run `[10]` / `[100]`) so the debit is visible in both tiers within a single demo run; bump them up when you adapt the recipe for production.

5. **Auth boundary** rejected the invalid API key in roughly 10 ms, well below normal upstream latency. The script printed the offending `apikey='not-a-real-key'` value before sending so the test condition is visible. The provider was never contacted, no provider quota was consumed, and the failure surfaced as a clean `401` to the client.

### Explore in Konnect

Open [Konnect](https://cloud.konghq.com/) and navigate to **API Gateway** → **Gateways** → **llm-cost-optimization-recipe**. The recipe created the following resources on this Control Plane:

- **Gateway services** → **llm-cost-optimization**: the Service the recipe registered. Its detail page has tabs for Configuration, Routes, Plugins, and Analytics.
  - **Routes** tab: the `/llm-cost-optimization` Route, scoped by the `llm-cost-optimization-recipe` `select_tags` you used at apply time.
  - **Plugins** tab: four Plugin instances on the Route, in priority order: `llm-cost-optimization-auth` (key-auth), `llm-cost-optimization-cache` (ai-semantic-cache), `llm-cost-optimization-compressor` (ai-prompt-compressor), and `llm-cost-optimization-proxy` (ai-proxy-advanced). Open the AI Proxy Advanced Plugin to see the two targets and their `description` fields.
- **Consumers** → **standard-user** and **premium-user**: the two Consumers identified by the API keys.
- **Consumer Groups** → **standard-tier** and **premium-tier**: each carries its own `ai-rate-limiting-advanced` Plugin instance with the per-tier dollar budget.

The **Analytics** tab on the Gateway service shows analytics tied to this recipe, including request counts, error rates, average latency, and a request-over-time chart. For a deeper dive into these analytics, plus per-Consumer cost attribution and platform-wide analytics across every Control Plane, head to the **Observability** L1 menu in Konnect.

## Cleanup

The recipe scoped all resources with `select_tags` and a kongctl `namespace`, so this teardown removes only this recipe's configuration. Tear down the local Data Plane and delete the Control Plane from Konnect:

```bash
export KONNECT_CONTROL_PLANE_NAME='llm-cost-optimization-recipe' && curl -Ls https://get.konghq.com/quickstart | bash -s -- -d -k $KONNECT_TOKEN
```

Stop and remove the Redis and LLMLingua containers if you started them locally:

```bash
docker rm -f redis-stack llmlingua-compressor 2>/dev/null
```

## Variations and next steps

**Switch models without code changes.** Update `DECK_CHAT_MODEL_1`, `DECK_CHAT_MODEL_2`, and the corresponding `DECK_INPUT_COST_*` and `DECK_OUTPUT_COST_*` env vars, then re-apply. Kong handles the rest. Check your provider's pricing page for current per-token costs. For example, switching the expensive target from `gpt-4o` to `o3` changes both the capability profile and the cost structure.

**Tune semantic routing descriptions for your workload.** The target `description` field determines which queries route to the expensive model. Replace the generic "complex analysis" description with descriptions specific to your use case, e.g. "Code generation, debugging, and refactoring tasks" or "Legal document analysis requiring precise citation." More specific descriptions improve routing accuracy. You can add additional targets at different price points for finer-grained routing, and multiple targets with identical descriptions receive round-robin distribution.

**Add more Consumer tiers with different budgets.** The recipe defines two tiers, but you can create additional Consumer Groups, such as a free tier with $1/hour and a team tier with $50/hour, each with its own [ai-rate-limiting-advanced](/plugins/ai-rate-limiting-advanced/) instance. Add multiple rate limit windows per tier (e.g. `limit: [5, 50]` with `window_size: [60, 3600]`) to cap both burst spending and sustained spending.

**Replace key-auth with OpenID Connect for production identity.** This recipe uses static API keys for simplicity, but production deployments should integrate with your identity provider using the [openid-connect](/plugins/openid-connect/) Plugin. JWT claims can map users to Consumer Groups automatically based on roles or team membership. See the [basic-llm-routing recipe](/cookbooks/basic-llm-routing/) for a self-contained JWT pattern, or the [claude-code-sso recipe](/cookbooks/claude-code-sso/) for an end-to-end example with Okta.

**Adapt for Azure OpenAI.** Azure uses deployment-specific endpoints, so each model target requires a different `azure_deployment_id`. To use this recipe with Azure, hand-edit the deck config to set `azure_deployment_id`, `azure_api_version`, and `azure_instance` on each target's options block. The rest of the recipe (semantic routing, caching, compression, rate limiting) works identically.
