---
title: LLM Cost Optimization
description: Reduce LLM infrastructure costs using semantic routing, caching, prompt compression, and tiered cost-based rate limiting.
url: "/kong-cookbooks/llm-cost-optimization/"
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
  - cost-optimization
featured: false
popular: false

# Machine-readable fields for AI agent setup
agent_setup_url: "/kong-cookbooks/agent-setup/?recipe=/kong-cookbooks/llm-cost-optimization/"
plugins:
  - key-auth
  - ai-proxy-advanced
  - ai-semantic-cache
  - ai-prompt-compression
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
        This tutorial uses Kong Konnect. You will provision a recipe-scoped Control Plane and local Data Plane via the [quickstart script](https://get.konghq.com/quickstart).

        1. Create a new personal access token by opening the [Konnect PAT page](https://cloud.konghq.com/global/account/tokens) and selecting **Generate Token**.
        1. Export your token. The same token is reused later for kongctl commands:

           ```bash
           export KONNECT_TOKEN='YOUR_KONNECT_PAT'
           ```

        1. Set the recipe-scoped Control Plane name and run the quickstart script:

           ```bash
           export KONNECT_CONTROL_PLANE_NAME='llm-cost-optimization-recipe'
           curl -Ls https://get.konghq.com/quickstart | bash -s -- -k $KONNECT_TOKEN --deck-output
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
        The [ai-prompt-compression](/plugins/ai-prompt-compression/) Plugin requires an external LLMLingua compression service. Kong provides a Docker image hosted on a private Cloudsmith registry.

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
             docker.cloudsmith.io/kong/ai-compress/service:v0.0.2
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
        pip install 'openai>=1.0.0'
        ```

overview: |
  This recipe configures Kong AI Gateway to reduce LLM infrastructure costs through four
  independent, stackable techniques: semantic routing to direct queries to the cheapest adequate
  model, semantic caching to eliminate redundant LLM calls entirely, prompt compression to reduce
  token counts before they reach the provider, and cost-based rate limiting to enforce dollar
  budgets per Consumer tier. By the end of this tutorial, you will have a single gateway endpoint
  that applies all four techniques to every request, with no application code changes required.

  The recipe uses five Kong Plugins working together:
  [key-auth](/plugins/key-auth/) for Consumer identification,
  [ai-proxy-advanced](/plugins/ai-proxy-advanced/) for semantic model routing,
  [ai-semantic-cache](/plugins/ai-semantic-cache/) for embedding-based response caching,
  [ai-prompt-compression](/plugins/ai-prompt-compression/) for LLMLingua-powered token reduction, and
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

Kong AI Gateway applies all four cost optimization techniques at the proxy layer, transparently
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

```text
Client Application                 Kong AI Gateway                          External Services
──────────────────                 ────────────────                         ─────────────────
OpenAI SDK
  │
  └──► POST /llm-cost-optimization
       apikey: standard-api-key      key-auth Plugin
       messages: [...]                 • Looks up the API key
                                       • Maps to Consumer
                                       • standard-user → standard-tier ($10/hr)
                                       • premium-user → premium-tier ($100/hr)
                                       │
                                       ▼
                                     ai-semantic-cache Plugin
                                       • Embeds prompt → vector search in Redis
                                       • HIT → return cached response ─ ─ ─► instant response
                                       │
                                       ▼ (MISS)
                                     ai-prompt-compression Plugin              LLMLingua
                                       • Sends prompt to compressor ─────────► Compressor
                                       • Replaces with compressed prompt ◄───  Service
                                       │
                                       ▼
                                     ai-proxy-advanced Plugin
                                       • Embeds prompt → cosine similarity
                                       • Simple query → cheap model ─────────► Model 1 (cheap)
                                       • Complex query → expensive model ────► Model 2 (expensive)
                                       │
                                       ▼
                                     ai-rate-limiting-advanced                (on Consumer Group)
                                       • cost = tokens × price / 1M
                                       • Deducts from tier budget
                                                                              Response
                                                                                │
  ◄─── OpenAI-format response ◄──────── cache stores response ◄───────────────┘
```
{:.no-copy-code}

| Component | Responsibility |
|-----------|---------------|
| Client application | Sends OpenAI-format chat requests with an `apikey` header that identifies the Consumer tier |
| Key Auth Plugin | Looks up the API key, attaches the matching Kong Consumer to the request, and binds the request to the Consumer's tier |
| AI Semantic Cache Plugin | Embeds prompts, searches Redis for cached responses, short-circuits on cache hit |
| AI Prompt Compression Plugin | Compresses verbose prompts via LLMLingua before they reach the LLM |
| AI Proxy Advanced Plugin | Semantic routing to cheap or expensive model, provider auth injection |
| AI Rate Limiting Advanced Plugin | Computes per-request cost and enforces dollar-based budget caps per Consumer Group |
| Redis Stack | Vector search for both semantic caching and semantic routing |
| LLMLingua service | Token-level prompt compression using a small language model |
| LLM provider | Model inference (cheap and expensive targets) |

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
   cached response immediately and no further plugins run. On a miss, the request continues.
4. The AI Prompt Compression Plugin sends prompts above the configured token threshold to the
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

### key-auth — API key authentication and Consumer mapping

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

**`key_names: [apikey]`**. The headers (or query parameters) the Plugin will look in for the API key. The recipe uses `apikey` because it is the convention the OpenAI SDK plays nicely with via `default_headers={"apikey": "..."}`. The Plugin also accepts standard names like `Authorization` if you want a `Bearer <key>` flow.

**`hide_credentials: true`**. Strips the API key from the request before forwarding upstream. The provider never sees the Consumer's API key. This is a 3.14 default but the recipe sets it explicitly for clarity and to remain portable to older Gateway versions.

**Anonymous fallback.** Set `anonymous: <consumer-id>` to let unauthenticated requests fall through to a designated "anonymous" Consumer with their own restricted Consumer Group budget, instead of returning `401`. Useful for public/free-tier endpoints. See the [key-auth reference](/plugins/key-auth/) for the full set of options.

**Scaling to a real IdP.** When the platform is ready for end-user identity (instead of static API keys), swap key-auth for [openid-connect](/plugins/openid-connect/) and map JWT claims to Consumer Groups. Application code only changes the auth header it sends; the rest of this recipe (semantic cache, compression, ai-proxy-advanced, ai-rate-limiting-advanced) stays put. See the [basic-llm-routing recipe](/kong-cookbooks/basic-llm-routing/) for the JWT pattern, or the [claude-code-sso recipe](/kong-cookbooks/claude-code-sso/) for an end-to-end Okta integration.

### ai-semantic-cache — embedding-based response caching

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
      threshold: 0.8
      redis:
        host: ${{ env "DECK_REDIS_HOST" }}
        port: 6379
```
{% endraw -%}
{:.no-copy-code}

**`threshold: 0.8`**. Controls how similar two prompts must be to produce a cache hit. Higher values require closer phrasing (fewer hits, higher quality); lower values accept broader matches (more hits, risk of incorrect responses). Start here and adjust based on your cache hit rate and accuracy requirements.

**`cache_ttl: 300`**. Cached responses expire after 5 minutes (300 seconds). This balances cost savings with freshness. For factual queries that do not change often, increase this to `3600` (1 hour) or higher. For rapidly changing data, reduce it.

**`message_countback: 1`**. Only the latest user message is vectorized for cache lookup. Set this to `2` or `3` for multi-turn conversations where the preceding messages provide important context that changes the expected response.

**`stop_on_failure: false`**. If Redis is unreachable or the embeddings call fails, the request falls through to the LLM instead of returning an error. The cache layer is purely additive and never blocks requests.

On a cache hit, Kong returns the stored response with `X-Cache-Status: Hit` and `X-Kong-Upstream-Latency: 0` (no LLM call was made). On a miss, the request continues to the next Plugin, and Kong caches the response for future requests.

### ai-prompt-compression — token reduction via LLMLingua

The AI Prompt Compression Plugin sends prompts to a sidecar LLMLingua service that removes
redundant tokens while preserving semantic meaning. The LLM processes the compressed prompt and
the bill reflects the smaller count. Short prompts pass through unchanged because they do not
benefit from compression and risk losing critical information.

#### Configuration details

{%- raw %}
```yaml
- name: ai-prompt-compression
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

**`compressor_type: rate`**. The `value` in `compression_ranges` is a retention ratio. A value of `0.6` retains 60% of tokens, a 40% reduction. Aggressive but effective for verbose RAG contexts or long system prompts. The alternative `target_token` mode compresses to a fixed token count, useful when you need to guarantee staying under a specific context window size. See the [ai-prompt-compression reference](/plugins/ai-prompt-compression/) for the full list of supported compressor types and tag-based selective compression.

**`compression_ranges`**. Only prompts between `min_tokens` and `max_tokens` are compressed. You can define multiple ranges with different retention ratios so medium-length prompts get light compression and long prompts get aggressive compression.

**`stop_on_error: false`**. If the LLMLingua service is unreachable, the uncompressed prompt is forwarded to the LLM. Like the cache, compression is purely additive.

The compression round-trip adds latency (several hundred milliseconds on CPU hardware). This appears in `X-Kong-Proxy-Latency`. For latency-sensitive workloads, consider GPU-backed LLMLingua deployment.

### ai-proxy-advanced — semantic model routing and provider translation

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
      threshold: 0.7
      redis:
        host: ${{ env "DECK_REDIS_HOST" }}
        port: 6379
    targets:
      - route_type: llm/v1/chat
        description: CATCHALL
        model:
          name: ${{ env "DECK_CHAT_MODEL_1" }}
          options:
            input_cost: ${{ env "DECK_INPUT_COST_1" }}
            output_cost: ${{ env "DECK_OUTPUT_COST_1" }}
      - route_type: llm/v1/chat
        description: >
          Generate complete software solutions, perform complex analysis,
          detailed reasoning, code review, architecture design...
        model:
          name: ${{ env "DECK_CHAT_MODEL_2" }}
          options:
            input_cost: ${{ env "DECK_INPUT_COST_2" }}
            output_cost: ${{ env "DECK_OUTPUT_COST_2" }}
```
{% endraw -%}
{:.no-copy-code}

**`balancer.algorithm: semantic`**. Selects semantic similarity as the routing strategy. The Plugin embeds the prompt, computes cosine similarity against each target's `description` embedding, and routes to the highest-similarity target above the threshold. Other balancing algorithms (round-robin, lowest-latency, lowest-usage, priority) are documented in the [ai-proxy-advanced reference](/plugins/ai-proxy-advanced/).

**`description: CATCHALL`**. Designates this target as the fallback. Simple, general, or off-topic queries that do not match any specific description land here. Point this at your cheapest model.

**`description: "Generate complete software solutions..."`**. Describes the kinds of queries that warrant the expensive model. Tune this description to match the types of queries your users send that genuinely require the premium model.

**`input_cost`** and **`output_cost`**. Cost per 1 million tokens, in dollars. These values are used by the AI Rate Limiting Advanced Plugin to compute the actual dollar cost of each request. Set them to match your provider's current pricing. The cost formula is: `cost = (prompt_tokens x input_cost + completion_tokens x output_cost) / 1,000,000`.

**`max_request_body_size`** and **`response_streaming`**. The recipe sets a 10 MB request limit (large enough for typical conversation contexts and modest RAG injections) and allows streaming responses. Tighten or relax both based on the workload you expect.

This recipe uses the default `llm_format: openai`, which accepts OpenAI-format requests and normalizes provider responses back to OpenAI format. Set `llm_format` to a provider's native format (`anthropic`, `bedrock`, `gemini`, `cohere`, `huggingface`) to pass requests through without transformation when you already have code using a provider's SDK.

### ai-rate-limiting-advanced — dollar-based budget caps

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
                - 10
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
                - 100
              window_size:
                - 3600
          window_type: sliding
          strategy: local
```
{:.no-copy-code}

**`tokens_count_strategy: cost`**. Instead of counting raw tokens, Kong computes the dollar cost of each response using the `input_cost` and `output_cost` values from the AI Proxy Advanced target that served the request. See the [ai-rate-limiting-advanced reference](/plugins/ai-rate-limiting-advanced/) for the full set of counting strategies (request count, prompt tokens, completion tokens, total tokens, cost).

**`limit: [10]`** and **`limit: [100]`**. Dollar amounts per window. Standard tier gets $10/hour, premium gets $100/hour. You can define multiple windows for the same provider, e.g. `limit: [5, 50]` with `window_size: [60, 3600]` caps spending at $5/minute AND $50/hour.

**`window_type: sliding`**. Uses a sliding window that considers the previous window's rate when evaluating the current one. This prevents burst spending at window boundaries. Use `fixed` for simpler, bucket-based limiting.

**`strategy: local`**. Counters are stored in Kong's in-memory dictionary on each node. For multi-node deployments, use `redis` to share counters across nodes, and set `decrease_by_fractions_in_redis: true` since cost values are fractional.

Kong sets response headers on every request so clients can track their remaining budget: `X-AI-RateLimit-Limit-3600-openai: 10` and `X-AI-RateLimit-Remaining-3600-openai: 9.997`. When the budget is exhausted, Kong returns `429 Too Many Requests` with a `Retry-After` header.

{:.info}
> **Cost is reflected on the next request.** The rate limiting Plugin computes cost from the
> LLM response, which means the cost of a request is deducted on the *following* request. The
> current request always completes. The limit is checked before the request is sent.

{:.info}
> **Production credentials.** This recipe stores the API keys directly in Plugin config and the LLM provider credentials in environment variables for simplicity. In production, use [Kong Vaults](/gateway/latest/kong-enterprise/secrets-management/) to reference both from your preferred secret manager (AWS Secrets Manager, HashiCorp Vault, GCP Secret Manager, Azure Key Vault) instead.

### Example response

The same OpenAI-format request goes through Kong. The headers prove what each Plugin layer did:
which model semantic routing selected (`X-Kong-LLM-Model`), whether the cache served the response
(`X-Cache-Status`), and how much budget remains (`X-AI-RateLimit-Remaining-3600-*`).

Request body (a simple factual question):

```json
{
  "messages": [
    {"role": "user", "content": "What is the capital of France?"}
  ]
}
```
{:.no-copy-code}

Response headers from the first call (cache miss, routed to the cheap model):

```text
HTTP/1.1 200 OK
X-Kong-LLM-Model: openai/gpt-4o-mini
X-Cache-Status: Miss
X-AI-RateLimit-Limit-3600-openai: 10
X-AI-RateLimit-Remaining-3600-openai: 9.999
X-Kong-Upstream-Latency: 845
X-Kong-Proxy-Latency: 120
```
{:.no-copy-code}

Response headers from a paraphrased follow-up call (cache hit, no upstream call):

```text
HTTP/1.1 200 OK
X-Cache-Status: Hit
X-Kong-Upstream-Latency: 0
X-Kong-Proxy-Latency: 45
X-AI-RateLimit-Remaining-3600-openai: 9.999
```
{:.no-copy-code}

Kong adds the following response headers:

| Header                                   | Description                                                                                              |
| ---------------------------------------- | -------------------------------------------------------------------------------------------------------- |
| `X-Kong-LLM-Model`                       | Upstream model that served the request, prefixed with the provider name and resolved by semantic routing |
| `X-Cache-Status`                         | `Hit` or `Miss`. On a hit, no upstream LLM call was made                                                 |
| `X-AI-RateLimit-Limit-3600-<provider>`   | Dollar budget per 3600-second window for this Consumer's tier                                            |
| `X-AI-RateLimit-Remaining-3600-<provider>` | Dollars remaining in the current window. Reflects cost of all completed requests                       |
| `X-Kong-Upstream-Latency`                | Time (ms) Kong spent waiting for the provider to respond. Always `0` on a cache hit                      |
| `X-Kong-Proxy-Latency`                   | Time (ms) Kong spent processing the request. Includes embedding lookups and compression round-trip       |

Kong attaches `X-Consumer-Username` to the upstream request (so the LLM provider sees who is calling) but does not echo it back to the downstream client. Per-Consumer attribution shows up in Konnect's analytics views. See "Explore in Konnect" below.

## Apply the Kong configuration

The configuration below creates a Kong Gateway Service and Route at `/llm-cost-optimization`,
attaches the [key-auth](/plugins/key-auth/) Plugin to identify Consumers via the `apikey` header,
and chains [ai-semantic-cache](/plugins/ai-semantic-cache/),
[ai-prompt-compression](/plugins/ai-prompt-compression/), and
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
        threshold: 0.8
        redis:
          host: ${{ env "DECK_REDIS_HOST" }}
          port: 6379
  - name: ai-prompt-compression
    instance_name: llm-cost-optimization-compression
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
        threshold: 0.7
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
          provider: openai
          name: ${{ env "DECK_CHAT_MODEL_1" }}
          options:
            input_cost: ${{ env "DECK_INPUT_COST_1" }}
            output_cost: ${{ env "DECK_OUTPUT_COST_1" }}
        logging:
          log_payloads: true
          log_statistics: true
      - route_type: llm/v1/chat
        description: 'Generate complete software solutions, perform complex analysis,
          detailed reasoning, code review, architecture design, and tasks requiring
          deep understanding or multi-step problem solving.

          '
        auth:
          header_name: Authorization
          header_value: ${{ env "DECK_OPENAI_TOKEN" }}
        model:
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
        - 10
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
        - 100
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
" | kongctl apply -f - -o text --auto-approve --pat "${KONNECT_TOKEN}"

rm -f kong-recipe.yaml
```
{: data-test-step="block" .collapsible }

{% endtab %}
{% tab AWS Bedrock %}

Export the per-provider env vars:

```bash
export DECK_CHAT_MODEL_1='amazon.nova-lite-v1:0'                            # cheap: general queries
export DECK_CHAT_MODEL_2='anthropic.claude-sonnet-4-5-20250929-v1:0'        # expensive: complex tasks
export DECK_INPUT_COST_1='0.06'                # Nova Lite: $0.06 per 1M input tokens
export DECK_OUTPUT_COST_1='0.24'               # Nova Lite: $0.24 per 1M output tokens
export DECK_INPUT_COST_2='3.00'                # Claude Sonnet: $3.00 per 1M input tokens
export DECK_OUTPUT_COST_2='15.00'              # Claude Sonnet: $15.00 per 1M output tokens
export DECK_EMBEDDINGS_MODEL='amazon.titan-embed-text-v2:0'
export DECK_EMBEDDINGS_DIMENSIONS='1024'
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
        threshold: 0.8
        redis:
          host: ${{ env "DECK_REDIS_HOST" }}
          port: 6379
  - name: ai-prompt-compression
    instance_name: llm-cost-optimization-compression
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
        threshold: 0.7
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
        description: 'Generate complete software solutions, perform complex analysis,
          detailed reasoning, code review, architecture design, and tasks requiring
          deep understanding or multi-step problem solving.

          '
        auth:
          aws_access_key_id: ${{ env "DECK_AWS_ACCESS_KEY_ID" }}
          aws_secret_access_key: ${{ env "DECK_AWS_SECRET_ACCESS_KEY" }}
        model:
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
        - 10
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
        - 100
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
" | kongctl apply -f - -o text --auto-approve --pat "${KONNECT_TOKEN}"

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
"""
LLM Cost Optimization. demo script
==================================
Demonstrates four cost optimization techniques composed on a single Kong AI
Gateway Route:

  1. Semantic routing. The ai-proxy-advanced Plugin runs the prompt through an
     embedding model and routes to the target whose `description` is closest
     in vector space. Simple prompts land on the cheap model, complex prompts
     land on the expensive one.
  2. Semantic caching. The ai-semantic-cache Plugin checks recent prompts for
     a near-duplicate embedding before calling the LLM. A cache hit returns
     instantly with no upstream cost.
  3. Prompt compression. The ai-prompt-compression Plugin sends the prompt
     through an LLMLingua compressor before forwarding to the LLM, reducing
     input tokens.
  4. Cost-based rate limiting. The ai-rate-limiting-advanced Plugin tracks
     dollar cost (input_cost + output_cost) per Consumer tier and enforces
     per-tier hourly budgets. The two demo Consumers are mapped to consumer
     groups with different budgets via API keys.

Authentication uses the key-auth Plugin: each Consumer has an API key that
identifies them and binds the request to the correct Consumer Group budget.

Expected output:
  Section 1 prints two requests landing on different upstream models, visible
  in the X-Kong-LLM-Model header. Section 2 prints a cache MISS followed by a
  HIT for a paraphrased question, with a latency speedup. Section 3 prints a
  compressed long prompt with reduced prompt_tokens. Section 4 prints rate
  limit headers for the standard and premium tiers showing different budgets.
  A final section sends an invalid API key and shows Kong rejecting it with
  401 before any upstream call.

How to run:
  1. Apply the recipe config (see README for the full kongctl apply command).
  2. Start Redis Stack and the LLMLingua compressor sidecars (see Prerequisites).
  3. Run:
       python demo.py
"""

import os
import sys
import time

from openai import APIStatusError, OpenAI

PROXY_URL = os.getenv("PROXY_URL", "http://localhost:8000")
CHAT_MODEL = os.getenv("CHAT_MODEL", "gpt-4o")
BASE_URL = f"{PROXY_URL}/llm-cost-optimization"


def make_client(api_key: str) -> OpenAI:
    """Construct an OpenAI client that sends the given API key in the apikey header."""
    return OpenAI(
        base_url=BASE_URL,
        api_key="unused",  # required by the SDK; Kong reads the apikey header instead
        default_headers={"apikey": api_key},
    )


standard_client = make_client("standard-api-key")
premium_client = make_client("premium-api-key")


def chat(client: OpenAI, prompt: str, label: str = "") -> float:
    """Send a chat request and print response details with Kong headers."""
    start = time.time()
    try:
        response = client.chat.completions.with_raw_response.create(
            model=CHAT_MODEL,
            messages=[{"role": "user", "content": prompt}],
        )
    except APIStatusError as e:
        elapsed = time.time() - start
        print(f"\n  [{label}] {e.status_code} {e.message}  ({elapsed:.2f}s)")
        return elapsed

    elapsed = time.time() - start
    completion = response.parse()
    h = response.headers

    model = h.get("x-kong-llm-model", "N/A")
    cache = h.get("x-cache-status", ".")
    upstream = h.get("x-kong-upstream-latency", ".")
    text = (completion.choices[0].message.content or "")[:120]
    usage = completion.usage

    short = prompt[:70] + ("..." if len(prompt) > 70 else "")
    print(f"\n  [{label}] '{short}'")
    print(f"    Model:    {model}")
    print(f"    Cache:    {cache}")
    print(f"    Tokens:   prompt={usage.prompt_tokens}, "
          f"completion={usage.completion_tokens}, total={usage.total_tokens}")
    print(f"    Latency:  {elapsed:.2f}s (upstream: {upstream}ms)")
    print(f"    Response: {text}{'...' if len(text) >= 120 else ''}")

    for k in sorted(h.keys()):
        if "ai-ratelimit" in k.lower():
            print(f"    {k}: {h[k]}")

    return elapsed


def main() -> None:
    print("=" * 65)
    print("1. SEMANTIC ROUTING. Cheap vs Expensive Model Selection")
    print("=" * 65)

    chat(standard_client, "What is the capital of France?", "SIMPLE")
    chat(
        standard_client,
        "Design a Python FastAPI application with OAuth2 JWT authentication, "
        "PostgreSQL integration, WebSocket support, and comprehensive error "
        "handling. Include the service architecture and key implementation.",
        "COMPLEX",
    )

    print(f"\n{'=' * 65}")
    print("2. SEMANTIC CACHING. Cache Hits for Similar Questions")
    print("=" * 65)

    t_miss = chat(standard_client, "What is machine learning?", "MISS")
    time.sleep(1)
    t_hit = chat(standard_client, "Explain machine learning to me", "HIT")
    if t_hit > 0:
        print(f"\n    Cache speedup: {t_miss / t_hit:.1f}x faster")

    print(f"\n{'=' * 65}")
    print("3. PROMPT COMPRESSION. Reduced Token Usage on Long Prompts")
    print("=" * 65)

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
    chat(standard_client, verbose_prompt, "COMPRESSED")
    print("    (Prompt was compressed by LLMLingua before reaching the LLM.")
    print("     prompt_tokens reflects the compressed count, not the original.)")

    print(f"\n{'=' * 65}")
    print("4. COST-BASED RATE LIMITING. Tiered Budget Caps")
    print("=" * 65)

    print("\n  Standard user ($10/hour budget):")
    chat(standard_client, "Say hello in one sentence.", "STANDARD")

    print("\n  Premium user ($100/hour budget):")
    chat(premium_client, "Say hello in one sentence.", "PREMIUM")

    print(f"\n{'=' * 65}")
    print("5. AUTH BOUNDARY. Invalid API key rejected before upstream call")
    print("=" * 65)
    bad_client = make_client("not-a-real-key")
    chat(bad_client, "Hello", "BLOCKED")

    print(f"\n{'=' * 65}")
    print("DONE. Four cost optimization layers active simultaneously:")
    print("  Semantic routing:    cheap model for simple, expensive for complex")
    print("  Semantic caching:    instant $0 responses for similar questions")
    print("  Prompt compression:  fewer tokens sent to the LLM")
    print("  Cost rate limiting:  per-consumer dollar-based budget caps")
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
    Tokens:   prompt=8, completion=12, total=20
    Latency:  0.85s (upstream: 710ms)
    Response: The capital of France is Paris.
    x-ai-ratelimit-limit-3600-openai: 10
    x-ai-ratelimit-remaining-3600-openai: 9.999

  [COMPLEX] 'Design a Python FastAPI application with OAuth2 JWT authentication, ...'
    Model:    openai/gpt-4o
    Cache:    Miss
    Tokens:   prompt=35, completion=280, total=315
    Latency:  3.20s (upstream: 3050ms)
    Response: Here's a FastAPI application architecture with OAuth2 JWT authentication...
    x-ai-ratelimit-limit-3600-openai: 10
    x-ai-ratelimit-remaining-3600-openai: 9.996

=================================================================
2. SEMANTIC CACHING. Cache Hits for Similar Questions
=================================================================

  [MISS] 'What is machine learning?'
    Model:    openai/gpt-4o-mini
    Cache:    Miss
    Tokens:   prompt=7, completion=95, total=102
    Latency:  1.10s (upstream: 920ms)
    Response: Machine learning is a subset of artificial intelligence...

  [HIT] 'Explain machine learning to me'
    Model:    openai/gpt-4o-mini
    Cache:    Hit
    Tokens:   prompt=7, completion=95, total=102
    Latency:  0.08s (upstream: 0ms)
    Response: Machine learning is a subset of artificial intelligence...

    Cache speedup: 13.8x faster

=================================================================
3. PROMPT COMPRESSION. Reduced Token Usage on Long Prompts
=================================================================

  [COMPRESSED] 'I would really like you to provide me with a very detailed and comprehen...'
    Model:    openai/gpt-4o-mini
    Cache:    Miss
    Tokens:   prompt=77, completion=210, total=287
    Latency:  2.50s (upstream: 1800ms)
    Response: Photosynthesis is the process by which plants convert light energy...
    (Prompt was compressed by LLMLingua before reaching the LLM.
     prompt_tokens reflects the compressed count, not the original.)

=================================================================
4. COST-BASED RATE LIMITING. Tiered Budget Caps
=================================================================

  Standard user ($10/hour budget):

  [STANDARD] 'Say hello in one sentence.'
    Model:    openai/gpt-4o-mini
    Cache:    Miss
    Tokens:   prompt=7, completion=10, total=17
    Latency:  0.65s (upstream: 520ms)
    Response: Hello, it's great to meet you!
    x-ai-ratelimit-limit-3600-openai: 10
    x-ai-ratelimit-remaining-3600-openai: 9.997

  Premium user ($100/hour budget):

  [PREMIUM] 'Say hello in one sentence.'
    Model:    openai/gpt-4o-mini
    Cache:    Hit
    Tokens:   prompt=7, completion=10, total=17
    Latency:  0.06s (upstream: 0ms)
    Response: Hello, it's great to meet you!
    x-ai-ratelimit-limit-3600-openai: 100
    x-ai-ratelimit-remaining-3600-openai: 99.999

=================================================================
5. AUTH BOUNDARY. Invalid API key rejected before upstream call
=================================================================

  [BLOCKED] 401 Error code: 401 - {'message': 'No credentials found for given apikey'}  (0.02s)

=================================================================
DONE. Four cost optimization layers active simultaneously:
  Semantic routing:    cheap model for simple, expensive for complex
  Semantic caching:    instant $0 responses for similar questions
  Prompt compression:  fewer tokens sent to the LLM
  Cost rate limiting:  per-consumer dollar-based budget caps
=================================================================
```
{:.no-copy-code}

### What happened

1. **Semantic routing** selected `openai/gpt-4o-mini` for the simple factual question and `openai/gpt-4o` for the complex architecture design prompt. The `X-Kong-LLM-Model` header confirms which model served each request. The simple query cost fractions of a cent; the complex query cost more but was routed to a model capable of handling it.

2. **Semantic caching** returned the cached response for "Explain machine learning to me" because it was semantically similar to "What is machine learning?", even though the wording was different. The `X-Cache-Status: Hit` header and `X-Kong-Upstream-Latency: 0ms` confirm no LLM call was made. Response time dropped from ~1.1s to ~0.08s and the cost was zero. The premium user's "Say hello" also hit the cache because the standard user had already asked the same question, so the cached response served both tiers.

3. **Prompt compression** reduced the verbose 130-word photosynthesis prompt before it reached the LLM. The `prompt_tokens: 77` in the response reflects the compressed token count. The original prompt was approximately 130 tokens before compression (40% reduction at `value: 0.6`). The LLM was billed for the compressed count.

4. **Cost-based rate limiting** showed different budget headers for each tier: `x-ai-ratelimit-limit-3600-openai: 10` for standard ($/hour) versus `100` for premium. The `remaining` values decreased by the computed cost of each request, tracking actual dollar spend rather than raw token counts.

5. **Auth boundary** rejected the invalid API key in roughly 20 ms, well below normal upstream latency. The provider was never contacted, no provider quota was consumed, and the failure surfaced as a clean `401` to the client.

### Explore in Konnect

Open [Konnect](https://cloud.konghq.com/) and navigate to **API Gateway** → **Gateways** → **llm-cost-optimization-recipe**. The recipe created the following resources on this Control Plane:

- **Gateway services** → **llm-cost-optimization**: the Service the recipe registered. Its detail page has tabs for Configuration, Routes, Plugins, and Analytics.
  - **Routes** tab: the `/llm-cost-optimization` Route, scoped by the `llm-cost-optimization-recipe` `select_tags` you used at apply time.
  - **Plugins** tab: four Plugin instances on the Route, in priority order: `llm-cost-optimization-auth` (key-auth), `llm-cost-optimization-cache` (ai-semantic-cache), `llm-cost-optimization-compression` (ai-prompt-compression), and `llm-cost-optimization-proxy` (ai-proxy-advanced). Open the AI Proxy Advanced Plugin to see the two targets and their `description` fields.
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

**Replace key-auth with OpenID Connect for production identity.** This recipe uses static API keys for simplicity, but production deployments should integrate with your identity provider using the [openid-connect](/plugins/openid-connect/) Plugin. JWT claims can map users to Consumer Groups automatically based on roles or team membership. See the [basic-llm-routing recipe](/kong-cookbooks/basic-llm-routing/) for a self-contained JWT pattern, or the [claude-code-sso recipe](/kong-cookbooks/claude-code-sso/) for an end-to-end example with Okta.

**Adapt for Azure OpenAI.** Azure uses deployment-specific endpoints, so each model target requires a different `azure_deployment_id`. To use this recipe with Azure, hand-edit the deck config to set `azure_deployment_id`, `azure_api_version`, and `azure_instance` on each target's options block. The rest of the recipe (semantic routing, caching, compression, rate limiting) works identically.
