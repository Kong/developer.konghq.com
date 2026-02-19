---
title: 'AI Semantic Cache'
name: 'AI Semantic Cache'

content_type: plugin

tier: ai_gateway_enterprise
publisher: kong-inc
description: 'Enhance performance for AI providers by caching LLM responses semantically'


products:
  - gateway
  - ai-gateway

works_on:
    - on-prem
    - konnect

min_version:
    gateway: '3.8'

topologies:
  on_prem:
    - hybrid
    - db-less
    - traditional
  konnect_deployments:
    - hybrid
    - cloud-gateways
    - serverless

icon: ai-semantic-cache.png

categories:
  - ai

search_aliases:
  - ai-semantic-cache
  - ai
  - llm
  - artificial
  - intelligence
  - language
  - model
  - caching

related_resources:
  - text: Get started with {{site.ai_gateway}}
    url: /ai-gateway/get-started/
  - text: Embedding-based similarity matching in Kong AI gateway plugins
    url: /ai-gateway/semantic-similarity/
faqs:
  - q: |
      How do I resolve the MemoryDB error `Number of indexes exceeds the limit`?
    a: |
      If you see the following error in the logs:

      ```sh
      failed to create memorydb instance failed to create index: LIMIT Number of indexes (11) exceeds the limit (10)
      ```

      This means that the hardcoded MemoryDB instance limit has been reached.
      To resolve this, create more MemoryDB instances to handle multiple {{page.name}} plugin instances.
---

The AI Semantic Cache plugin stores user requests to an LLM in a vector database based on semantic meaning. When a similar query is made, it uses these embeddings to retrieve relevant cached requests efficiently.

## What is semantic caching?

Semantic caching enhances data retrieval efficiency by focusing on the meaning or context of queries rather than just exact matches. It stores requests based on the underlying intent and semantic similarities between different queries and can then retrieve those cached queries when a similar request is made.

When a new request is made, the system can retrieve and reuse previously cached requests if they are contextually relevant, even if the phrasing is different. This method reduces redundant processing, speeds up response times, and ensures that answers are more relevant to the user’s intent, ultimately improving overall system performance and user experience.

For example, if a user asks, "how to integrate our API with a mobile app" and later asks, "what are the steps for connecting our API to a smartphone application?", the system understands that both questions are asking for the same information. It can then retrieve and reuse previously cached responses, even if the wording is different. This approach reduces processing time and speeds up responses.

The AI Semantic Cache plugin may not be ideal if the following are true:

* You have limited hardware or budget. Storing semantic vectors and running similarity searches require a lot of storage and computing power, which could be an issue.
* Your data doesn’t rely on semantics, or exact matches work fine. In this case, semantic caching may offer little benefit. Traditional or keyword-based caching might be more efficient.

## How it works

Semantic caching with the AI Semantic Cache plugin involves three parts: request handling, embedding generation, and response caching.

First, a user starts a chat request with the LLM. The AI Semantic Cache plugin queries the vector database to see if there are any semantically similar requests that have already been cached. If there is a match, the vector database returns the cached response to the user.

{% mermaid %}
sequenceDiagram
    actor User
    participant {{site.base_gateway}}/AI Semantic Cache plugin
    participant Vector database

    User->>{{site.base_gateway}}/AI Semantic Cache plugin: LLM chat request
    {{site.base_gateway}}/AI Semantic Cache plugin->>Vector database: Query for semantically similar previous requests
    Vector database-->>User: If response, return it or stream it back
{% endmermaid %}

If there isn't a match, the AI Semantic Cache plugin prompts the embeddings LLM to generate an embedding for the response.

{% mermaid %}
sequenceDiagram
    participant {{site.base_gateway}}/AI Semantic Cache plugin
    participant Embeddings LLM

    {{site.base_gateway}}/AI Semantic Cache plugin->>Embeddings LLM: Generate embeddings for `config.message_countback` messages
    Embeddings LLM-->>{{site.base_gateway}}/AI Semantic Cache plugin: Return embeddings
{% endmermaid %}

The AI Semantic Cache plugin uses a vector database and cache to store responses to requests. The plugin can then retrieve a cached response if a new request matches the semantics of a previous request, or it can tell the vector database to store a new response if there are no matches.

{% mermaid %}
sequenceDiagram
    participant {{site.base_gateway}}/AI Semantic Cache plugin
    participant Prompt/Chat LLM
    participant Vector database
    actor User

    {{site.base_gateway}}/AI Semantic Cache plugin->>Prompt/Chat LLM: Make LLM request
    Prompt/Chat LLM-->>{{site.base_gateway}}/AI Semantic Cache plugin: Receive response
    {{site.base_gateway}}/AI Semantic Cache plugin->>Vector database: Store vectors
    {{site.base_gateway}}/AI Semantic Cache plugin->>Vector database: Store response message options
    {{site.base_gateway}}/AI Semantic Cache plugin-->>User: Return realtime response
{% endmermaid %}

### Vector databases

{% include_cached /plugins/ai-vector-db.md name=page.name %}

### Cache management

With the AI Semantic Cache plugin, you can configure a cache of your choice to store the responses from the LLM.

The AI Semantic Cache plugin supports Redis as a cache.

#### Caching mechanisms

The AI Semantic Cache plugin improves how AI systems provide responses by using two kinds of caching mechanisms:

* **Exact Caching:** This stores precise, unaltered responses for specific queries. If a user asks the same question multiple times, the system can quickly retrieve the pre-stored response rather than generating it again each time. This speeds up response times and reduces computational load.
* **Semantic Caching:** This approach is more flexible and involves storing responses based on the meaning or intent behind the queries. Instead of relying on exact matches, the system can understand and reuse information that is conceptually similar. For instance, if a user asks about "Italian restaurants in New York City" and later about "New York City Italian cuisine," semantic caching can help provide relevant information based on their related meanings.

Together, these caching methods enhance the efficiency and relevance of AI responses, making interactions faster and more contextually accurate.

{:.info}
> When Exact Caching is enabled, the AI Semantic Cache plugin may still return results for queries that are similar but not identical. This is expected behavior: the plugin performs similarity-based caching regardless of the Exact Caching setting.

### Headers sent to the client

When the AI Semantic Cache plugin is active, {{site.base_gateway}} sends additional headers
indicating the cache status and other relevant information:

```plaintext
X-Cache-Status: Hit
X-Cache-Status: Miss
X-Cache-Status: Bypass
X-Cache-Status: Refresh
X-Cache-Key: <cache_key>
X-Cache-Ttl: <ttl>
Age: <age>
```
{:.no-copy-code}

These headers help clients understand whether a response was served from the cache,
if the cache key was used, the remaining time-to-live, and the age of the cached response.

### Cache control headers

The plugin respects cache control headers to determine if requests and responses should be cached or not. It supports the following directives:

* `no-store`: Prevents caching of the request or response
* `no-cache`: Forces validation with the origin server before serving the cached response
* `private`: Ensures the response is not cached by shared caches
* `max-age` and `s-maxage`: Sets the maximum age of the cached response. This causes the vector database to drop and delete the cached response message after expiration, so it’s never seen again.

{:.info}
> As most AI services always send `no-cache` in the response headers, setting `cache_control` to `true` will always result in a cache bypass. Only consider setting `no-cache` if you are using self-hosted services and have control over the response Cache Control headers.

{% include plugins/redis-cloud-auth.md %}
