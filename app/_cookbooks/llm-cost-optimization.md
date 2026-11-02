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
  gateway: '3.14'
  ai-gateway: '2.0'
categories:
  - cost-optimization
featured: false
popular: false

# Machine-readable fields for AI agent setup
plugins:
  - ai-model
  - ai-model-provider
  - key-auth
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

           The script provisions an {{site.ai_gateway}} named `llm-cost-optimization-recipe`, a local data plane connected to it, and prints `export` lines for the rest of the session vars, including `AI_GATEWAY_ID`. Paste those into your shell when prompted.
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
        Pick the provider you want to route to and export its credentials. Every apply tab below reuses the same credentials.

        {% navtabs "Providers" %}
        {% navtab "OpenAI" %}
        This tutorial uses OpenAI:

        1. [Create an OpenAI account](https://auth.openai.com/create-account).
        1. [Get an API key](https://platform.openai.com/api-keys).
        1. Export the API key as an environment variable:

           ```sh
           export DECK_OPENAI_TOKEN='Bearer sk-YOUR-KEY'
           ```
        {% endnavtab %}
        {% navtab "AWS Bedrock" %}
        This tutorial uses AWS Bedrock:

        1. Ensure you have an AWS account with [Bedrock model access](https://docs.aws.amazon.com/bedrock/latest/userguide/model-access.html) enabled for both the chat and embeddings models you plan to use.
        1. Export your AWS credentials:

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
        The [AI Semantic Cache](/ai-gateway/policies/ai-semantic-cache/) Policy and the AI Model's semantic balancer both use Redis as the vector database, for cache lookups and for routing decisions.

        1. Run [Redis Stack](https://redis.io/docs/latest/) locally:

           ```bash
           docker run -d --name redis-stack -p 6379:6379 redis/redis-stack-server:latest
           ```

        1. Export the Redis host so the AI Policies can connect from inside the data plane container:

           ```sh
           export DECK_REDIS_HOST='host.docker.internal'
           ```
    - title: LLMLingua Prompt Compressor
      content: |
        The [AI Prompt Compressor](/ai-gateway/policies/ai-prompt-compressor/) Policy requires an external LLMLingua compression service. Kong provides a Docker image hosted on a private Cloudsmith registry.

        1. Get registry credentials from your Kong account team or support.
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
  budgets per AI Consumer tier. By the end of this tutorial, you'll have a single AI Model endpoint
  that applies all four techniques to every request, with no application code changes required.

  The recipe combines a Key Auth AI Auth Strategy for AI Consumer identification, one AI Model
  load-balanced across two targets by semantic similarity, and three AI Policies working
  together: the [AI Semantic Cache](/ai-gateway/policies/ai-semantic-cache/) Policy for
  embedding-based response caching, the [AI Prompt Compressor](/ai-gateway/policies/ai-prompt-compressor/)
  policy for LLMLingua-powered token reduction, and the
  [AI Rate Limiting Advanced](/ai-gateway/policies/ai-rate-limiting-advanced/) Policy for
  cost-based budget caps per AI Consumer Group.
---

## The problem

Most organizations deploying LLMs operate with a single model endpoint and no cost intelligence
at the infrastructure layer. This setup leads to several compounding inefficiencies:

- **Every query gets the same model, regardless of complexity.** A question like "What is 2+2?"
  hits the same model as "Design a distributed database architecture." The cheap model answers the
  simple question just as well, but the expensive model gets every request because there is no
  routing logic. Teams either overspend on a premium model for everything, or underserve complex
  queries by defaulting to the cheapest option.

- **Semantically identical questions re-hit the LLM.** When five users ask "What is the capital of
  France?" with slightly different phrasing, that's five separate LLM calls with five separate
  bills. Traditional exact-match caching doesn't help because the queries are worded differently.
  Embedding-based semantic comparison catches these near-duplicates, but building that into each
  application requires a vector database, an embeddings pipeline, and cache management logic per
  service.

- **Verbose prompts waste tokens on redundancy.** RAG pipelines, few-shot examples, and long
  system prompts often contain significant linguistic redundancy. The provider bills for every
  token, including the filler words and repeated phrasing that a compression model can strip
  without changing the semantic meaning. Without compression, verbose inputs inflate token counts
  by 20-40%.

- **Rate limiting counts requests or raw tokens, not dollars.** A limit of "10,000 tokens per
  hour" sounds precise, but the cost of 10,000 tokens varies dramatically by model. Pennies on a
  budget model become dollars on a frontier model. When organizations set token-based rate limits,
  the actual dollar exposure per user depends on which model they happen to use, making budgets
  unpredictable. True cost control requires tracking `(tokens x price)`, not just tokens.

- **No per-user or per-tier budget differentiation.** Without AI Consumer identity at the gateway
  layer, every user shares the same limits. There is no way to say "the free tier gets $10/hour,
  the enterprise tier gets $100/hour." Rate limits apply uniformly regardless of who is making the
  request.

The underlying issue is that each application team ends up owning cost optimization decisions,
such as which model to use, whether to cache, whether to compress, and how much budget to
allocate, instead of the infrastructure layer enforcing them centrally.

## The solution

{{site.ai_gateway_name}} applies all four cost optimization techniques at the AI Model layer,
transparently to every request. Each technique addresses one of the problems above:

- **Semantic routing replaces "one model for everything."** Kong embeds each incoming prompt and
  compares it against a `semantic_description` on each of the AI Model's targets. Simple queries
  (matching the catchall target) route to a cheap model. Complex queries (matching a "detailed
  reasoning" description) route to a premium model. The routing decision is automatic, requiring
  no application logic and no rules to maintain.

- **Semantic caching eliminates redundant LLM calls.** Before a request reaches the LLM, Kong
  embeds the prompt and searches Redis for a semantically similar cached response. If the
  similarity exceeds the threshold, Kong returns the cached response immediately with zero tokens
  consumed and sub-100ms latency. The cache operates across all AI Consumers, so one user's question
  benefits everyone asking the same thing.

- **Prompt compression reduces token counts before billing.** Kong routes the prompt through an
  LLMLingua service that strips redundant tokens while preserving meaning. A 200-token verbose
  prompt becomes a 120-token compressed prompt. The LLM processes the compressed version, and the
  token bill reflects the smaller count. Compression activates only for prompts above a
  configurable threshold. Short prompts pass through unchanged.

- **Cost-based rate limiting enforces dollar budgets, not token counts.** Kong computes the actual
  cost of each response using per-target `input_cost` and `output_cost` values configured on the
  AI Model, then deducts that cost from the AI Consumer Group's budget. Standard-tier users share a
  $1/hour budget; premium-tier users share a $5/hour budget. When a tier exhausts its budget, Kong
  returns `429 Too Many Requests`, preventing billing surprises.

<!-- vale off -->
{% mermaid %}
sequenceDiagram
    participant C as Client
    participant K as Kong AI Gateway
    participant LC as LLMLingua Compressor
    participant L as LLM Provider

    C->>K: POST /llm-cost-optimization (apikey, prompt)
    activate K
    K->>K: key-auth Auth Strategy. Validate apikey, attach Consumer (else 401)
    K->>K: AI Rate Limiting Advanced Policy. Check the Consumer Group's budget (else 429)
    K->>LC: AI Prompt Compressor Policy. Compress the prompt
    activate LC
    LC-->>K: Compressed prompt
    deactivate LC
    K->>K: AI Semantic Cache Policy. Embed prompt, check Redis for a similar cached response
    alt cache hit
        K-->>C: Cached response (no LLM call)
    else cache miss
        K->>K: AI Model balancer. Embed prompt, route to cheap or expensive target by similarity
        K->>L: Forwarded request (provider auth injected, format translated)
        activate L
        L-->>K: Native response
        deactivate L
        K->>K: AI Rate Limiting Advanced Policy. Deduct this response's cost from the budget
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
    responsibility: "Sends OpenAI-format chat requests with an `apikey` header that identifies the AI Consumer tier"
  - component: Key Auth AI Auth Strategy
    responsibility: "Looks up the API key, attaches the matching AI Consumer to the request, and binds the request to the AI Consumer's tier"
  - component: AI Semantic Cache Policy
    responsibility: "Embeds prompts, searches Redis for cached responses, short-circuits on a cache hit"
  - component: AI Prompt Compressor Policy
    responsibility: "Compresses verbose prompts through LLMLingua before they reach the LLM"
  - component: AI Model
    responsibility: "Semantic load balancing to a cheap or expensive target; the target's AI Model Provider injects credentials and translates formats"
  - component: AI Rate Limiting Advanced Policy
    responsibility: "Computes per-request cost and enforces dollar-based budget caps per AI Consumer Group"
  - component: Redis Stack
    responsibility: "Vector search for both semantic caching and semantic routing"
  - component: LLMLingua service
    responsibility: "Token-level prompt compression using a small language model"
  - component: LLM provider
    responsibility: "Model inference for the cheap and expensive targets"
{% endtable %}

## How it works

A request flowing through Kong passes through five stages: authentication, budget check,
compression, cache check, and (on a miss) semantic routing and billing.

1. A client sends a chat completion request (OpenAI format) to `/llm-cost-optimization` with an
   `apikey` header carrying their tier's static API key.
2. The Key Auth AI Auth Strategy looks up the key against registered AI Consumer credentials. If the key
   is missing or unknown, Kong short-circuits with `401` before any upstream call. On a match, it
   attaches the matching AI Consumer (`standard-user` or `premium-user`) to the request, which
   determines which AI Consumer Group's budget applies.
3. The AI Rate Limiting Advanced Policy checks whether the AI Consumer's tier has already exhausted
   its budget for the current window. If so, Kong returns `429` before any further processing.
4. The AI Prompt Compressor Policy sends prompts above the configured token threshold to the
   LLMLingua service, which returns a compressed version with redundant tokens removed. Short
   prompts pass through unchanged.
5. The AI Semantic Cache Policy embeds the (possibly compressed) prompt and searches Redis for a
   semantically similar cached response. On a hit, Kong returns the cached response immediately
   and the request ends here. On a miss, the request continues.
6. The AI Model's semantic balancer embeds the prompt again and compares it against each target's
   `semantic_description`. The closest match wins. The target's AI Model Provider then injects the
   upstream provider's credentials and, if the upstream uses a different wire format, translates
   the request.
7. Kong forwards the request to the LLM provider, normalizes the response back to OpenAI format,
   and stores it in the semantic cache for future similar prompts. The AI Rate Limiting Advanced
   policy computes the dollar cost of this response from its token usage and the target's
   `input_cost`/`output_cost`, then deducts that cost from the AI Consumer Group's budget. The
   tier's *next* request reflects this deduction, not the current one.

### Key Auth: API key authentication and AI Consumer mapping

Authentication in {{site.ai_gateway_name}} 2.0 is an AI Auth Strategy, not a policy. AI Policies
handle AI-specific behavior like caching, compression, and rate limiting. The Key Auth AI Auth Strategy
sits in front of everything else and gates every request. Each AI Consumer has one or more API key
credentials. When a request arrives, the strategy reads the configured header (`apikey`), looks
the key up in Kong's AI Consumer credential store, and attaches the matching AI Consumer to the
request. The matched AI Consumer binds the request to an AI Consumer Group for cost rate limiting. Two AI Consumers (`standard-user` and `premium-user`) belong to two AI Consumer
Groups (`standard-tier` sharing $1/hour, `premium-tier` sharing $5/hour), so the API key the
client sends determines the tier the request runs against.

#### Configuration details

{%- raw %}
```yaml
ai_gateway_auth_strategies:
  - ref: llm-cost-optimization-auth
    type: key-auth
    display_name: "llm-cost-optimization key auth"
    config:
      key_names:
        - apikey
      hide_credentials: true

ai_gateway_consumers:
  - ref: llm-cost-optimization-standard-consumer
    name: llm-cost-optimization-standard-consumer
    display_name: "llm-cost-optimization standard-tier consumer"
    type: api-key
    credentials:
      - ref: llm-cost-optimization-standard-credential
        name: llm-cost-optimization-standard-credential
        display_name: "llm-cost-optimization standard API key"
        type: api-key
        api_key: !secret {source: !env DECK_STANDARD_API_KEY}
```
{% endraw -%}
{:.no-copy-code}

**`key_names: [apikey]`**. The headers (or query parameters) checked for the API key. The recipe
uses `apikey` because this check performs an exact string match on the header value and doesn't
inspect `Authorization` for Bearer tokens. The OpenAI SDK's `api_key` field always serializes as
`Authorization: Bearer <key>`, which Kong would read as the literal string `Bearer <key>` and fail
to match against any stored credential. The [Try it out](#try-it-out) section points at a pre-function
pattern that bridges the SDK's Bearer token to the `apikey` header server-side.

**`hide_credentials: true`**. Strips the API key from the request before forwarding upstream. The
provider never sees the AI Consumer's API key.

**`api_key` is write-only.** An AI Consumer credential's `api_key` field must be a `!secret`
reference. Kong rejects a plain string here, even for a demo value like this recipe's. The
premium-tier AI Consumer follows the identical shape with `DECK_PREMIUM_API_KEY`.

**Anonymous fallback.** Set `anonymous: <consumer-id>` on the Key Auth AI Auth Strategy to let
unauthenticated requests fall through to a designated "anonymous" AI Consumer with their own
restricted tier, instead of returning `401`. This fallback is useful for public or free-tier endpoints.

**Scaling to a real IdP.** When the platform is ready for end-user identity instead of static API
keys, swap the Key Auth AI Auth Strategy for an OpenID Connect strategy and map JWT claims to AI Consumers and
AI Consumer Groups. Application code only changes the auth header it sends; the rest of this recipe
(semantic cache, compression, semantic routing, rate limiting) stays put. See the
[Basic LLM Routing recipe](/cookbooks/basic-llm-routing/) for the JWT pattern, or the
[Claude Code SSO recipe](/cookbooks/claude-code-sso/) for an end-to-end Okta integration.

### AI Semantic Cache: embedding-based response caching

The AI Semantic Cache Policy intercepts requests before they reach the LLM, embeds the latest
user message, and searches Redis for a cached response to a semantically similar question. On a
match, Kong returns the cached response immediately. All AI Consumers share the cache, so
one user's question benefits every later user asking something similar. The default threshold is
conservative enough that paraphrased duplicates ("What is machine learning?" vs "Explain machine
learning to me") match while topically related but distinct questions ("What is the capital of
France?" vs "What is the capital of Germany?") don't.

#### Configuration details

The OpenAI tab's configuration (the Bedrock tab differs only in `embeddings.auth` and
`embeddings.model`):

{%- raw %}
```yaml
ai_gateway_policies:
  - ref: llm-cost-optimization-cache
    type: ai-semantic-cache
    display_name: "llm-cost-optimization semantic cache"
    config:
      cache_ttl: 300
      message_countback: 1
      stop_on_failure: false
      embeddings:
        auth:
          header_name: Authorization
          header_value: !secret {source: !env DECK_OPENAI_TOKEN}
        model:
          provider: openai
          name: !env EMBEDDINGS_MODEL
      vectordb:
        dimensions: !env EMBEDDINGS_DIMENSIONS
        distance_metric: cosine
        strategy: redis
        threshold: 0.3
        redis:
          host: !env DECK_REDIS_HOST
```
{% endraw -%}
{:.no-copy-code}

**`embeddings.auth`**. Unlike the AI Model Provider's `config.auth` (a single reusable credential
block resolved once for the whole entity), this policy's embeddings call carries its own inline
credential: `header_name`/`header_value` for OpenAI, or `aws_access_key_id`/`aws_secret_access_key`
for Bedrock. The policy makes its own embeddings call independent of any AI Model Provider entity,
so it needs its own copy of the credential.

**`threshold: 0.3`**. The maximum cosine **distance** between the incoming prompt's embedding and
a cached prompt for a hit to register (lower is stricter). With `text-embedding-3-small`,
paraphrased questions like `"What is machine learning?"` and `"Explain machine learning to me"`
typically sit around 0.20-0.28 distance, so `0.3` admits legitimate paraphrases. Distinct prompts
sit at distance 0.75 or higher, so the cache correctly excludes them. Tighten toward `0.2` if you see
semantically distinct prompts colliding; loosen toward `0.4` to catch broader rephrasings at the
risk of incorrect cache hits.

**`cache_ttl: 300`**. Cached responses expire after 5 minutes (300 seconds). This TTL balances cost
savings with freshness. For factual queries that don't change often, increase this to `3600`
(1 hour) or higher. For rapidly changing data, reduce it.

**`message_countback: 1`**. Kong embeds only the latest user message for cache lookup. Set this
to `2` or `3` for multi-turn conversations where the preceding messages provide important context
that changes the expected response.

**`stop_on_failure: false`**. If Redis is unreachable or the embeddings call fails, the request
falls through to the LLM instead of returning an error. The cache layer is purely additive and
never blocks requests.

On a cache hit, Kong returns the stored response with `X-Cache-Status: Hit` and no
`X-Kong-Upstream-Latency` header (Kong makes no LLM call). On a miss, the request continues, and
Kong caches the response for future requests.

**Cache hits are model-agnostic.** Because the AI Semantic Cache Policy runs before the AI
Model's semantic balancer makes a routing decision, Kong skips that decision entirely on a hit.
Kong returns the cached response regardless of which target the request would otherwise have
selected. A simple paraphrased query that would route to the cheap model can therefore receive a
cached response originally generated by the expensive model, and vice versa. The cache key is the
prompt embedding alone; it carries no model affinity. If you need per-model caches, for example to
avoid serving a `gpt-4o` answer to a `gpt-4o-mini` request, partition by path or by AI Consumer
rather than relying on the single shared cache.

**AI Policy execution order isn't configurable in 2.0.** There is no `ordering` field on an AI
Policy (unlike 1.0's `ai-proxy-advanced` plugin, which supported `ordering.before.access`). Kong
runs AI Policies attached to an AI Model in the order determined by each policy type's built-in
priority, not by declaration order. On {{site.base_gateway}} 3.14, the AI Prompt Compressor
policy's priority runs before the AI Semantic Cache Policy's, so compression happens on every
request, including ones that turn out to be cache hits. This order doesn't affect correctness,
since compression preserves the prompt's meaning and the embeddings still cluster the same way,
but it means Kong doesn't skip the compression round-trip on a cache hit.

### AI Prompt Compressor: token reduction through LLMLingua

The AI Prompt Compressor Policy sends prompts to a sidecar LLMLingua service that removes
redundant tokens while preserving semantic meaning. The LLM processes the compressed prompt and
the bill reflects the smaller count. Short prompts pass through unchanged because they don't
benefit from compression and risk losing critical information.

#### Configuration details

{%- raw %}
```yaml
ai_gateway_policies:
  - ref: llm-cost-optimization-compressor
    type: ai-prompt-compressor
    display_name: "llm-cost-optimization prompt compressor"
    config:
      compressor_type: rate
      compressor_url: !env DECK_COMPRESSOR_URL
      stop_on_error: false
      compression_ranges:
        - min_tokens: 100
          max_tokens: 1000000
          value: 0.6
```
{% endraw -%}
{:.no-copy-code}

**`compressor_type: rate`**. The `value` in `compression_ranges` is a retention ratio. A value of
`0.6` retains 60% of tokens, a 40% reduction. This ratio is aggressive but effective for verbose
RAG contexts or long system prompts. The alternative `target_token` mode compresses to a fixed token count, useful
when you need to guarantee staying under a specific context window size. See the [AI Prompt
Compressor reference](/ai-gateway/policies/ai-prompt-compressor/) for the full list of supported
compressor types and tag-based selective compression.

**`compression_ranges`**. Kong compresses only prompts between `min_tokens` and `max_tokens`. You
can define multiple ranges with different retention ratios so medium-length prompts get light
compression and long prompts get aggressive compression.

**`stop_on_error: false`**. If the LLMLingua service is unreachable, Kong forwards the
uncompressed prompt to the LLM. Like the cache, compression is purely additive.

The compression round-trip adds latency (several hundred milliseconds on CPU hardware). The added
latency appears in `X-Kong-Proxy-Latency`. For latency-sensitive workloads, consider GPU-backed LLMLingua
deployment.

### AI Model: semantic load balancing and cost accounting

The AI Model handles everything from the model-selection decision through the upstream call. The
recipe configures one AI Model whose two targets share a single route, with
`config.balancer.algorithm: semantic` load-balancing between them, rather than the alias-per-Model pattern other recipes in
this cookbook use for tiered routing. Each target carries a `semantic_description` capturing the
kinds of queries it should serve. When a request arrives, the balancer embeds the prompt, computes
cosine similarity against each target's `semantic_description` embedding, and routes to the
closest match. The `CATCHALL` target handles simple or off-topic queries; the "detailed reasoning"
target handles complex work that warrants the premium model.

#### Configuration details

The OpenAI tab's configuration (the Bedrock tab additionally sets `region` on the
balancer's embeddings config and on each target, since Bedrock's target config carries region):

{%- raw %}
```yaml
ai_gateway_models:
  - ref: llm-cost-optimization-model
    type: model
    display_name: "llm-cost-optimization"
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
      balancer:
        algorithm: semantic
        embeddings:
          provider: llm-cost-optimization-provider
          name: !env EMBEDDINGS_MODEL
          config:
            type: openai
        vectordb:
          type: redis
          dimensions: !env EMBEDDINGS_DIMENSIONS
          distance_metric: cosine
          threshold: !env DECK_PROXY_THRESHOLD
          host: !env DECK_REDIS_HOST
    targets:
      - name: !env CHAT_MODEL_1
        provider: llm-cost-optimization-provider
        semantic_description: "CATCHALL"
        config:
          type: openai
          input_cost: !env DECK_INPUT_COST_1
          output_cost: !env DECK_OUTPUT_COST_1
      - name: !env CHAT_MODEL_2
        provider: llm-cost-optimization-provider
        semantic_description: "Software architecture, system design, and complex code generation."
        config:
          type: openai
          input_cost: !env DECK_INPUT_COST_2
          output_cost: !env DECK_OUTPUT_COST_2
```
{% endraw -%}
{: .no-copy-code .collapsible }

**`balancer.algorithm: semantic`**. Selects semantic similarity as the load-balancing strategy for
this Model's targets. The [AI Model entity reference](/ai-gateway/entities/ai-model/) documents
other algorithms (round-robin, lowest-latency, lowest-usage, priority, consistent-hashing).

**`balancer.embeddings`**. Unlike the AI Semantic Cache Policy's `embeddings` block, this one
references the AI Model Provider entity directly by name (`provider: llm-cost-optimization-provider`)
rather than carrying its own inline credential. Kong reuses the AI Model Provider's already-configured
`config.auth` for the balancer's embeddings call.

**`balancer.vectordb.threshold`** (env var `DECK_PROXY_THRESHOLD`). The maximum cosine
**distance** between the incoming prompt's embedding and a target's `semantic_description`
embedding for that target to be eligible (lower is stricter, same convention as the AI Semantic
Cache Policy). The right value depends on which embeddings model you're using; different models
live on different absolute distance scales for the same content. The recipe ships with `0.75` for
OpenAI's `text-embedding-3-small` and `0.85` for Bedrock's `amazon.titan-embed-text-v2:0`; the
recipe tunes both values against the demo prompts so the complex prompt routes to the expensive target
while simple prompts fall to the catchall. If you swap the embeddings model, expect to retune.

**`targets[].semantic_description`**. Replaces what an alias-routed AI Model would use
`route.model.values` for. `"CATCHALL"` designates the fallback target; simple, general, or
off-topic queries that don't exceed the similarity threshold for any other target land here.
Point this target at your cheapest model. Short anchor phrases on the other target produce sharper
embeddings than long prose, so keep each `semantic_description` to a single concise phrase rather
than multiple sentences.

**`targets[].config.input_cost`** and **`output_cost`**. Cost per 1 million tokens, in dollars.
The AI Rate Limiting Advanced Policy uses these values to compute the actual dollar cost of each
request. Set them to match your provider's current pricing. The cost formula is:
`cost = (prompt_tokens x input_cost + completion_tokens x output_cost) / 1,000,000`.

**`max_request_body_size`** and **`response_streaming`**. The recipe sets a 10 MB request limit
(large enough for typical conversation contexts and modest RAG injections) and allows streaming
responses. Tighten or relax both based on the workload you expect.

**No client-side model selection.** This recipe's AI Model has one route with no `route.model`
alias matching, unlike the per-alias Models in the [Basic LLM Routing recipe](/cookbooks/basic-llm-routing/).
The balancer ignores the request body's `model` field for target selection and decides
server-side regardless of what the client sends. The demo below sends `model="auto"` purely to
satisfy the OpenAI SDK's required parameter.

This recipe uses the default `formats: [{type: openai}]`, which accepts OpenAI-format requests and
normalizes provider responses back to OpenAI format. See the [AI Model entity
reference](/ai-gateway/entities/ai-model/) for the supported native formats.

### AI Rate Limiting Advanced: dollar-based tiered budgets

The AI Rate Limiting Advanced Policy enforces dollar-based budget caps per AI Consumer Group. Each
AI Consumer Group gets its own policy instance with a different limit. Because the policy
expresses the budget in dollars and computes it from the `input_cost`/`output_cost` values on the AI Model's
targets, a $1/hour budget lasts much longer on the cheap model than on the expensive one, the
right incentive structure for cost optimization.

#### Configuration details

{%- raw %}
```yaml
ai_gateway_policies:
  - ref: llm-cost-optimization-standard-limit
    type: ai-rate-limiting-advanced
    display_name: "llm-cost-optimization standard tier rate limit"
    config:
      policies:
        - window_type: sliding
          limits:
            - limit: 1
              window_size: 3600
      identifier: consumer-group
      tokens_count_strategy: cost
      strategy: local

ai_gateway_consumer_groups:
  - ref: llm-cost-optimization-standard-tier
    name: llm-cost-optimization-standard-tier
    display_name: "llm-cost-optimization standard tier"
    consumers:
      - llm-cost-optimization-standard-consumer
    policies:
      - llm-cost-optimization-standard-limit
```
{% endraw -%}
{:.no-copy-code}

**`config.policies`**. The current schema scopes rate limits through one or more inline policy
entries, each with its own `window_type` and `limits`, rather than the flat `llm_providers` list
older {{site.ai_gateway}} versions used. This recipe attaches each policy directly to one AI Consumer Group
(below) and defines no `match` conditions, so each policy acts as the catchall for all traffic
reaching that AI Consumer Group. See the [AI Rate Limiting Advanced
reference](/ai-gateway/policies/ai-rate-limiting-advanced/) for `match` conditions that narrow
further, for example by model or by provider, within a single policy.

**`identifier: consumer-group`**. Scopes the budget to the whole AI Consumer Group rather than the
default per-consumer scoping. Every AI Consumer in `standard-tier` draws from the same $1/hour pool,
matching the "the tier gets a shared budget" framing this recipe uses. This setting requires
attaching the policy to an AI Consumer Group entity, which this recipe does through the group's own
`policies` list.

**`tokens_count_strategy: cost`**. Instead of counting raw tokens, Kong computes the dollar cost of
each response using the `input_cost` and `output_cost` values from the AI Model target that served
the request. See the [AI Rate Limiting Advanced
reference](/ai-gateway/policies/ai-rate-limiting-advanced/) for the full set of counting strategies
(total tokens, prompt tokens, completion tokens, cost).

**`limit: 1`** and **`limit: 5`** (on the premium policy). Dollar amounts per window. The standard
tier shares $1/hour; the premium tier shares $5/hour. The recipe uses small budgets so a single
demo run produces visible debits in both tiers; production limits are typically much higher (for
example `10` standard / `100` premium). Add a second entry to `limits` for a second window, for
example `{limit: 0.25, window_size: 60}` alongside the hourly limit, to cap both burst spending and
sustained spending.

{:.info}
> **Cost is reflected on the next request.** The rate limiting policy computes cost from the LLM
> response, so Kong deducts the cost of a request on the *following* request. The current
> request always completes.

**`window_type: sliding`**. Uses a sliding window that considers the previous window's rate when
evaluating the current one. The sliding window prevents burst spending at window boundaries. Use `fixed` for
simpler, bucket-based limiting.

**`strategy: local`**. Kong stores counters in its in-memory dictionary on each node. For
multi-node deployments, use `redis` to share counters across nodes.

Kong sets response headers on every request so clients can track their remaining budget, for
example `X-AI-RateLimit-Limit-3600-policy-1` and `X-AI-RateLimit-Remaining-3600-policy-1`. The
numeric segment is the window size in seconds; the trailing label reflects the policy's `match`
configuration (a provider or model name when `match` narrows the policy, or a positional
`policy-N` label when it doesn't, as here). When a tier exhausts its budget, Kong returns
`429 Too Many Requests` with a `Retry-After` header.

For simplicity, this recipe stores AI Consumer API keys and provider credentials in environment
variables.

{:.info}
> In production, store credentials in [AI Vaults](/ai-gateway/entities/ai-vault/)
> instead, backed by your preferred secret manager (AWS Secrets Manager, HashiCorp Vault, GCP
> Secret Manager, or Azure Key Vault).

### Example response

The same OpenAI-format request goes through Kong. The headers prove what each layer did: whether
the cache served the response (`X-Cache-Status`), which model semantic routing selected
(`X-Kong-LLM-Model`), and how much budget remains (`X-AI-RateLimit-Remaining-*`).

Request body (a simple factual question):

```json
{
  "messages": [{ "role": "user", "content": "What is the capital of France?" }]
}
```
{:.no-copy-code}

Response headers from the first call (cache miss, routed to the cheap target):

```text
HTTP/1.1 200 OK
X-Kong-LLM-Model: openai/gpt-4o-mini
X-Cache-Status: Miss
X-AI-RateLimit-Limit-3600-policy-1: 1
X-AI-RateLimit-Remaining-3600-policy-1: 0.999
X-Kong-Upstream-Latency: 845
X-Kong-Proxy-Latency: 120
```
{:.no-copy-code}

Response headers from a paraphrased follow-up call (cache hit, no upstream call):

```text
HTTP/1.1 200 OK
X-Cache-Status: Hit
X-Kong-Proxy-Latency: 45
X-AI-RateLimit-Remaining-3600-policy-1: 0.999
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
    description: "Upstream model that served the request, prefixed with the provider name and resolved by semantic routing. Absent on a cache hit"
  - header: "`X-Cache-Status`"
    description: "`Hit` or `Miss`. On a hit, Kong makes no upstream LLM call"
  - header: "`X-AI-RateLimit-Limit-<window>-<label>`"
    description: "Dollar budget for this AI Consumer's tier for a window of `<window>` seconds"
  - header: "`X-AI-RateLimit-Remaining-<window>-<label>`"
    description: "Dollars remaining in the current window. Reflects the cost of already-completed requests"
  - header: "`X-Kong-Upstream-Latency`"
    description: "Time (ms) Kong spent waiting for the provider to respond. Absent on cache hits"
  - header: "`X-Kong-Proxy-Latency`"
    description: "Time (ms) Kong spent processing the request. Includes embedding lookups and the compression round-trip"
{% endtable %}

Kong attaches `X-Consumer-Username` to the upstream request (so the LLM provider sees who is
calling) but doesn't echo it back to the downstream client. Per-consumer attribution shows up in
{{site.konnect_short_name}}'s analytics views. See "Explore in {{site.konnect_short_name}}" below.

## Apply the Kong configuration

The following configuration creates an AI Model Provider holding your chosen provider's credentials, a
Key Auth AI Auth Strategy with two AI Consumers, two AI Consumer Groups each carrying an AI Rate
Limiting Advanced Policy, an AI Semantic Cache Policy, an AI Prompt Compressor Policy, and one AI
Model load-balanced across two targets by semantic similarity. A kongctl namespace scopes every
resource so you can tear it down cleanly without affecting other configurations on the
same {{site.ai_gateway}}.

First, adopt the quickstart {{site.ai_gateway}} into a kongctl namespace so the following apply commands can
manage it.

```bash
kongctl adopt ai-gateway "${KONNECT_CONTROL_PLANE_NAME}" \
  --namespace "${KONNECT_CONTROL_PLANE_NAME}" \
  --pat "${KONNECT_TOKEN}"
```

Adoption stamps the `KONGCTL-namespace` label on the {{site.ai_gateway}}.

Export the two tiers' demo API keys. AI Consumer credential `api_key` fields are write-only and must
come from an env var, even for these fixed demo values:

```bash
export DECK_STANDARD_API_KEY='standard-api-key'
export DECK_PREMIUM_API_KEY='premium-api-key'
```

You already exported the provider credentials, the Redis host, and the compressor URL in the
prerequisites. Each tab below sets only the per-provider model, cost, and threshold env vars and
runs the apply.

{% navtabs "Providers" %}
{% tab OpenAI %}

Export the per-provider env vars:

```bash
export CHAT_MODEL_1='gpt-4o-mini'         # cheap: general queries
export CHAT_MODEL_2='gpt-4o'              # expensive: complex tasks
export DECK_INPUT_COST_1='0.15'                # gpt-4o-mini: $0.15 per 1M input tokens
export DECK_OUTPUT_COST_1='0.60'               # gpt-4o-mini: $0.60 per 1M output tokens
export DECK_INPUT_COST_2='2.50'                # gpt-4o: $2.50 per 1M input tokens
export DECK_OUTPUT_COST_2='10.00'              # gpt-4o: $10.00 per 1M output tokens
export EMBEDDINGS_MODEL='text-embedding-3-small'
export EMBEDDINGS_DIMENSIONS='1536'
export DECK_PROXY_THRESHOLD='0.75'             # max cosine distance, tuned for text-embedding-3-small
```

Apply the Kong configuration:

```bash
{%- raw %}
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
        value: !secret {source: !env 'DECK_OPENAI_TOKEN'}
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
    api_key: !secret {source: !env 'DECK_STANDARD_API_KEY'}
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
    api_key: !secret {source: !env 'DECK_PREMIUM_API_KEY'}
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
    compressor_url: !env 'DECK_COMPRESSOR_URL'
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
        header_value: !secret {source: !env 'DECK_OPENAI_TOKEN'}
      model:
        provider: openai
        name: !env 'EMBEDDINGS_MODEL'
    vectordb:
      dimensions: !env 'EMBEDDINGS_DIMENSIONS'
      distance_metric: cosine
      strategy: redis
      threshold: 0.3
      redis:
        host: !env 'DECK_REDIS_HOST'
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
    balancer:
      algorithm: semantic
      embeddings:
        provider: llm-cost-optimization-provider
        name: !env 'EMBEDDINGS_MODEL'
        config:
          type: openai
      vectordb:
        type: redis
        dimensions: !env 'EMBEDDINGS_DIMENSIONS'
        distance_metric: cosine
        threshold: !env 'DECK_PROXY_THRESHOLD'
        host: !env 'DECK_REDIS_HOST'
  targets:
  - name: !env 'CHAT_MODEL_1'
    provider: llm-cost-optimization-provider
    semantic_description: CATCHALL
    config:
      type: openai
      input_cost: !env 'DECK_INPUT_COST_1'
      output_cost: !env 'DECK_OUTPUT_COST_1'
  - name: !env 'CHAT_MODEL_2'
    provider: llm-cost-optimization-provider
    semantic_description: Software architecture, system design, and complex code generation.
    config:
      type: openai
      input_cost: !env 'DECK_INPUT_COST_2'
      output_cost: !env 'DECK_OUTPUT_COST_2'
EOF
{% endraw -%}

kongctl apply -f kong-recipe.yaml -o text --auto-approve --pat "${KONNECT_TOKEN}"

rm -f kong-recipe.yaml
```
{: data-test-step="block" .collapsible }

{% endtab %}
{% tab AWS Bedrock %}

Export the per-provider env vars:

```bash
export CHAT_MODEL_1='amazon.nova-lite-v1:0'                            # cheap: general queries
export CHAT_MODEL_2='global.anthropic.claude-sonnet-4-5-20250929-v1:0' # expensive: complex tasks (uses cross-region inference profile, required for Claude 4.5)
export DECK_INPUT_COST_1='0.06'                # Nova Lite: $0.06 per 1M input tokens
export DECK_OUTPUT_COST_1='0.24'               # Nova Lite: $0.24 per 1M output tokens
export DECK_INPUT_COST_2='3.00'                # Claude Sonnet: $3.00 per 1M input tokens
export DECK_OUTPUT_COST_2='15.00'              # Claude Sonnet: $15.00 per 1M output tokens
export EMBEDDINGS_MODEL='amazon.titan-embed-text-v2:0'
export EMBEDDINGS_DIMENSIONS='1024'
export DECK_PROXY_THRESHOLD='0.85'             # max cosine distance, tuned for amazon.titan-embed-text-v2:0
```

Apply the Kong configuration:

```bash
{%- raw %}
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
      access_key_id: !env 'DECK_AWS_ACCESS_KEY_ID'
      secret_access_key: !secret {source: !env 'DECK_AWS_SECRET_ACCESS_KEY'}
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
    api_key: !secret {source: !env 'DECK_STANDARD_API_KEY'}
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
    api_key: !secret {source: !env 'DECK_PREMIUM_API_KEY'}
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
    compressor_url: !env 'DECK_COMPRESSOR_URL'
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
        aws_access_key_id: !env 'DECK_AWS_ACCESS_KEY_ID'
        aws_secret_access_key: !secret {source: !env 'DECK_AWS_SECRET_ACCESS_KEY'}
      model:
        provider: bedrock
        name: !env 'EMBEDDINGS_MODEL'
        options:
          bedrock:
            aws_region: !env 'DECK_AWS_REGION'
    vectordb:
      dimensions: !env 'EMBEDDINGS_DIMENSIONS'
      distance_metric: cosine
      strategy: redis
      threshold: 0.3
      redis:
        host: !env 'DECK_REDIS_HOST'
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
    balancer:
      algorithm: semantic
      embeddings:
        provider: llm-cost-optimization-provider
        name: !env 'EMBEDDINGS_MODEL'
        config:
          region: !env 'DECK_AWS_REGION'
          type: bedrock
      vectordb:
        type: redis
        dimensions: !env 'EMBEDDINGS_DIMENSIONS'
        distance_metric: cosine
        threshold: !env 'DECK_PROXY_THRESHOLD'
        host: !env 'DECK_REDIS_HOST'
  targets:
  - name: !env 'CHAT_MODEL_1'
    provider: llm-cost-optimization-provider
    semantic_description: CATCHALL
    config:
      region: !env 'DECK_AWS_REGION'
      type: bedrock
      input_cost: !env 'DECK_INPUT_COST_1'
      output_cost: !env 'DECK_OUTPUT_COST_1'
  - name: !env 'CHAT_MODEL_2'
    provider: llm-cost-optimization-provider
    semantic_description: Software architecture, system design, and complex code generation.
    config:
      region: !env 'DECK_AWS_REGION'
      type: bedrock
      input_cost: !env 'DECK_INPUT_COST_2'
      output_cost: !env 'DECK_OUTPUT_COST_2'
EOF
{% endraw -%}

kongctl apply -f kong-recipe.yaml -o text --auto-approve --pat "${KONNECT_TOKEN}"

rm -f kong-recipe.yaml
```
{: data-test-step="block" .collapsible }

{% endtab %}
{% endnavtabs %}

## Try it out

The demo script exercises all four cost-optimization layers in sequence: simple and complex
queries to demonstrate semantic routing, a paraphrased follow-up to trigger a cache hit, a verbose
prompt to show compression in action, calls from both tiers to compare rate limit budgets, and a
final invalid-API-key call to confirm Kong rejects unauthorized requests before any upstream call.

{:.info}
> The demo passes the API key through `default_headers` because the OpenAI SDK reserves `api_key`
> for the `Authorization: Bearer` header. To let clients pass the key through `api_key` directly,
> attach a [Pre-Function](/ai-gateway/policies/pre-function/) Policy that copies the Bearer token to the
> `apikey` header server-side.

Create the demo script:

```bash
cat <<'EOF' > demo.py
"""LLM cost optimization demo.

Exercises all four cost-optimization layers the recipe's AI Model and Policies apply on
every request: semantic routing (cheap vs. expensive target), semantic caching (skip the
LLM call entirely on a paraphrased repeat), prompt compression (fewer billed tokens on a
verbose prompt), and cost-based rate limiting (a dollar budget per Consumer Group). A final
call with an invalid API key confirms the key-auth AI Auth Strategy rejects it before any
upstream call.

Run with `python demo.py` after applying the recipe's Kong configuration (see README).
Expects the two Consumers' API keys to be `standard-api-key` and `premium-api-key` (the
recipe's default `DECK_STANDARD_API_KEY` / `DECK_PREMIUM_API_KEY` values).
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
# Placeholder value only. The recipe's AI Model has one route with no `route.model` alias
# matching, so the request body's `model` field isn't used for target selection, Kong's
# semantic balancer picks the target server-side by comparing the prompt's embedding
# against each target's `semantic_description`. The OpenAI SDK still requires some value
# in `model=`, so this satisfies the SDK without implying Kong reads it.
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
        # Highlight the reduction, that's the headline of this section.
        print(f"    Tokens:   pre-compression~{original_tokens} -> "
              f"billed={MAGENTA(BOLD(str(usage.prompt_tokens)))} "
              f"({MAGENTA(BOLD(f'{reduction_pct:.0f}% reduction'))}), "
              f"completion={usage.completion_tokens}")
    else:
        print(f"    Tokens:   prompt={usage.prompt_tokens}, "
              f"completion={usage.completion_tokens}, total={usage.total_tokens}")
    print(f"    Latency:  {elapsed:.2f}s ({DIM(latency_extra)})")
    print(f"    Response: {DIM(text)}{DIM('...') if len(text) >= 120 else ''}")

    # Highlight the rate-limit remaining, that's the headline for section 4.
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

    print(f"\n  {BOLD('Standard user')} ($1/hour shared budget):")
    chat(standard_client, "Say hello in one sentence.", "STANDARD")

    print(f"\n  {BOLD('Premium user')} ($5/hour shared budget):")
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
    x-ai-ratelimit-limit-3600-policy-1: 1
    x-ai-ratelimit-remaining-3600-policy-1: 1

  [COMPLEX] 'Design a Python FastAPI application with OAuth2 JWT authentication, ...'
    Model:    openai/gpt-4o
    Cache:    Miss
    Tokens:   prompt=40, completion=250, total=290
    Latency:  3.40s (upstream: 2870ms)
    Response: Designing a Python FastAPI application with OAuth2 JWT authentication, PostgreSQL integration...
    x-ai-ratelimit-limit-3600-policy-1: 1
    x-ai-ratelimit-remaining-3600-policy-1: 0.9999937

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

  Standard user ($1/hour shared budget):

  [STANDARD] 'Say hello in one sentence.'
    Model:    openai/gpt-4o-mini
    Cache:    Miss
    Tokens:   prompt=13, completion=9, total=22
    Latency:  0.96s (upstream: 438ms)
    Response: Hello! How can I assist you today?
    x-ai-ratelimit-limit-3600-policy-1: 1
    x-ai-ratelimit-remaining-3600-policy-1: 0.9858

  Premium user ($5/hour shared budget):

  [PREMIUM] 'Tell me an interesting fact about octopuses in one sentence.'
    Model:    openai/gpt-4o-mini
    Cache:    Miss
    Tokens:   prompt=15, completion=27, total=42
    Latency:  1.08s (upstream: 612ms)
    Response: Octopuses have three hearts and blue blood, with two hearts pumping blood to the gills...
    x-ai-ratelimit-limit-3600-policy-1: 5
    x-ai-ratelimit-remaining-3600-policy-1: 4.9999858

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
  Cost rate limiting:  per-tier dollar-based budget caps
=================================================================
```
{: .no-copy-code .collapsible }

### What happened

1. **Semantic routing** selects `openai/gpt-4o-mini` for the simple factual question and
   `openai/gpt-4o` for the complex architecture design prompt. The `X-Kong-LLM-Model` header
   confirms which target served each request. The simple query costs fractions of a cent; the
   complex query costs more but routes to a target capable of handling it.

2. **Semantic caching** returns the cached response for `"Explain machine learning to me"`
   because it's semantically close to `"What is machine learning?"`. The `X-Cache-Status: Hit`
   header and absence of `X-Kong-Upstream-Latency` confirm that Kong made no LLM call. Response
   time drops from about 6.1s to about 0.9s. `Model:` shows `(served from cache)` rather than a
   specific model because the AI Semantic Cache Policy runs before the AI Model's semantic
   balancer, so Kong skips the routing decision entirely on a hit. A cached response can serve a
   prompt that would otherwise have routed to a different target than the one that originally
   produced it (see [AI Semantic Cache: embedding-based response caching](#ai-semantic-cache-embedding-based-response-caching)
   for cross-model cache details).

3. **Prompt compression** reduces the original ~138-token photosynthesis prompt to 87 billed
   tokens before reaching the LLM (a 37% reduction at `value: 0.6`). The script counts the
   original tokens locally with `tiktoken` so the delta is visible in the output; the provider
   bills only for the compressed count.

4. **Cost-based rate limiting** shows different budget headers for each tier:
   `x-ai-ratelimit-limit-3600-policy-1: 1` for standard ($/hour) versus `5` for premium. Each
   tier's `remaining` value decrements by the computed cost of that AI Consumer's request, tracking
   actual dollar spend rather than raw token counts. The recipe sets these intentionally low
   (production deployments typically run `10` / `100`) so the debit is visible in both tiers
   within a single demo run; increase them when you adapt the recipe for production.

5. **Auth boundary** rejects the invalid API key in about 10 ms, well below normal upstream
   latency. The script prints the offending `apikey='not-a-real-key'` value before sending so the
   test condition is visible. Kong never contacts the provider, consumes no provider quota, and
   returns a clean `401` to the client.

### Explore in {{site.konnect_short_name}}

Open [{{site.konnect_short_name}}](https://cloud.konghq.com/) and find the {{site.ai_gateway}} named
`llm-cost-optimization-recipe`. The recipe created the following resources on this {{site.ai_gateway}}, all
scoped by the kongctl namespace applied above:

- **AI Model Providers** → **llm-cost-optimization-provider**: the credential set the recipe
  registered for your chosen provider.
- **AI Models** → **llm-cost-optimization-model**: its two targets and their `semantic_description`
  fields, plus the `key-auth` AI Auth Strategy and the cache/compressor AI Policies attached to it.
- **AI Policies** → **llm-cost-optimization-cache**, **llm-cost-optimization-compressor**,
  **llm-cost-optimization-standard-limit**, **llm-cost-optimization-premium-limit**: the four
  AI Policies this recipe applies.
- **Consumers** → **llm-cost-optimization-standard-consumer** and
  **llm-cost-optimization-premium-consumer**: the two AI Consumers identified by the API keys.
- **Consumer Groups** → **llm-cost-optimization-standard-tier** and
  **llm-cost-optimization-premium-tier**: each carries its own rate-limiting AI Policy with the
  per-tier dollar budget.

For platform-wide traffic analysis, including per-consumer cost attribution across every
{{site.ai_gateway}}, head to the **Observability** L1 menu in {{site.konnect_short_name}}.

## Variations and next steps

**Switch models without code changes.** Update `CHAT_MODEL_1`, `CHAT_MODEL_2`, and the
corresponding `DECK_INPUT_COST_*` and `DECK_OUTPUT_COST_*` env vars, then re-apply. Kong handles
the rest. Check your provider's pricing page for current per-token costs. For example, switching
the expensive target from `gpt-4o` to `o3` changes both the capability profile and the cost
structure.

**Tune semantic routing descriptions for your workload.** The target's `semantic_description`
field determines which queries route to the expensive model. Replace the generic "complex
analysis" description with descriptions specific to your use case, for example "Code generation,
debugging, and refactoring tasks" or "Legal document analysis requiring precise citation." More
specific descriptions improve routing accuracy.

**Add more AI Consumer tiers with different budgets.** The recipe defines two tiers, but you can
create additional AI Consumer Groups, such as a free tier sharing $1/hour and a team tier sharing
$50/hour, each with its own [AI Rate Limiting Advanced](/ai-gateway/policies/ai-rate-limiting-advanced/)
policy. Add a second entry to a policy's `limits` list to cap both burst spending and sustained
spending in the same policy.

**Replace Key Auth with OpenID Connect for production identity.** This recipe uses static API
keys for simplicity, but production deployments should integrate with your identity provider
using the [OpenID Connect](/ai-gateway/policies/openid-connect/) AI Auth Strategy. JWT claims can map
users to AI Consumer Groups automatically based on roles or team membership. See the
[Basic LLM Routing recipe](/cookbooks/basic-llm-routing/) for a self-contained JWT pattern, or the
[Claude Code SSO recipe](/cookbooks/claude-code-sso/) for an end-to-end example with Okta.

**Adapt for Azure OpenAI.** Azure uses deployment-specific endpoints, so each target requires a
different `deployment_id`. To use this recipe with Azure, adapt each target's `config` to set
`deployment_id`, `api_version`, and the provider's `instance`. The rest of the recipe (semantic
routing, caching, compression, rate limiting) works identically.

## Cleanup

The recipe's kongctl namespace scopes all resources, so the teardown removes only this recipe's
configuration. Tear down the local data plane and delete the {{site.ai_gateway}} from {{site.konnect_short_name}}:

```bash
export KONNECT_CONTROL_PLANE_NAME='llm-cost-optimization-recipe' && curl -Ls https://get.konghq.com/ai | bash -s -- -d -k $KONNECT_TOKEN
```

Stop and remove the Redis and LLMLingua containers if you started them locally:

```bash
docker rm -f redis-stack llmlingua-compressor 2>/dev/null
```
