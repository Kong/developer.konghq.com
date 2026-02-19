---
title: "Embedding-based similarity matching in Kong AI gateway plugins"
layout: reference
content_type: reference
description: This reference explains how {{site.ai_gateway}} plugins use embedding-based similarity to compare prompts with various inputs—such as cached entries, upstream targets, document chunks, or allow/deny lists.
breadcrumbs:
  - /ai-gateway/

works_on:
 - on-prem
 - konnect

products:
  - ai-gateway
  - gateway

tags:
  - ai
  - load-balancing

plugins:
  - ai-proxy-advanced
  - ai-semantic-cache
  - ai-rag-injector
  - ai-semantic-prompt-guard
  - ai-semantic-response-guard

min_version:
  gateway: '3.10'

related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/
  - text: "{{site.ai_gateway}} plugins"
    url: /plugins/?category=ai
  - text: Use AI Semantic Prompt Guard plugin to govern your LLM traffic
    url: /how-to/use-ai-semantic-prompt-guard-plugin/
  - text: Ensure chatbots adhere to compliance policies with the AI RAG Injector plugin
    url: /how-to/use-ai-rag-injector-plugin/
  - text: Control prompt size with the AI Compressor plugin
    url: /how-to/compress-llm-prompts/
  - text: Semantic processing and vector similarity search with Kong and Redis
    url: https://konghq.com/blog/engineering/semantic-processing-and-vector-similarity-search-with-kong-and-redis
  - text: Vector embeddings
    url: https://redis.io/glossary/vector-embeddings/
    icon: /assets/icons/redis.svg
  - text: Vector databases 101
    url: https://redis.io/blog/vector-databases-101/
    icon: /assets/icons/redis.svg
---

In large language tasks, applications that interact with language models rely on semantic search—not by exact word matches, but by similarity in meaning. This is achieved using vector embeddings, which represent pieces of text as points in a high-dimensional space.

These embeddings enable the concept of semantic similarity, where the “distance” between vectors reflects how closely related two pieces of text are. Similarity can be measured using techniques like cosine similarity or Euclidean distance, forming the quantitative basis for comparing meaning.

![Vector embeddings example](/assets/images/ai-gateway/vectors.svg)
> _**Figure 1:** A simplified representation of vector text embeddings in a three-dimensional space._

For example, in the image, "king" and "emperor" are semantically more similar than a "king" is to an "otter".

Vector embeddings power a range of LLM workflows, including semantic search, document clustering, recommendation systems, anomaly detection, content similarity analysis, and classification via auto-labeling.

## Semantic similarity in {{site.ai_gateway}}

In {{site.ai_gateway}}, several plugins leverage embedding-based similarity:

{% table %}
columns:
  - title: Plugin
    key: plugin
  - title: Description
    key: description
rows:
  - plugin: "[AI Proxy Advanced](/plugins/ai-semantic-prompt-guard/)"
    description: Performs semantic routing by embedding each upstream’s description at config time and storing the results in a selected vector database. At runtime, it embeds the prompt and queries vector database to route requests to the most semantically appropriate upstream.
  - plugin: "[AI Semantic Cache](/plugins/ai-semantic-cache/)"
    description: Indexes previous prompts and responses as embeddings. On each request, it searches for semantically similar inputs and serves cached responses when possible to reduce redundant LLM calls.
  - plugin: "[AI RAG Injector](/plugins/ai-rag-injector/)"
    description: Retrieves semantically relevant chunks from a vector database. It embeds the prompt, performs a similarity search, and injects the results into the prompt to enable retrieval-augmented generation.
  - plugin: "[AI Semantic Prompt Guard](/plugins/ai-semantic-prompt-guard/)"
    description: Compares incoming prompts against allow/deny lists using embedding similarity to detect and block misuse patterns.
  - plugin: |
      [AI Semantic Response Guard](/plugins/ai-semantic-response-guard/) {% new_in 3.12 %}
    description: Filters LLM responses by comparing their semantic content against predefined allow and deny lists. It analyzes the full response body, generates embeddings, and enforces rules to block unsafe or unwanted outputs before returning them to the client.
{% endtable %}

### Vector databases

To compare embeddings efficiently, {{site.ai_gateway}} semantic plugins rely on vector databases. These specialized data stores index high-dimensional embeddings and enable **fast similarity search** based on distance metrics like cosine similarity or Euclidean distance.

When a plugin needs to find semantically similar content—whether it’s a past prompt, an upstream description, or a document chunk—it sends a query to a vector database. The database returns the closest matches, allowing the plugin to make decisions like caching, routing, injecting, or blocking.

Currently, {{site.ai_gateway}} supports the following vector backends:

* Using `redis` as the VectorDB strategy:
  * **[Redis](https://redis.io/docs/latest/stack/search/reference/vectors/)** with Vector Similarity Search (VSS)
  * **[AWS MemoryDB for Redis](https://docs.aws.amazon.com/memorydb/latest/devguide/vector-search-overview.html)** {% new_in 3.12 %}
* Using `pgvector` as the VectorDB strategy:
  * **[PostgreSQL with pgvector](https://github.com/pgvector/pgvector)** {% new_in 3.10 %}

The selected database stores the embeddings generated by the plugin (either at config time or runtime), and determines the accuracy and performance of semantic operations.

### What is compared for similarity?

Each plugin applies similarity search slightly differently depending on its goal. These comparisons determine whether the plugin routes, blocks, reuses, or enriches a prompt based on meaning rather than syntax.

The following table describes how each AI plugin compares embeddings:

<!-- vale off -->
{% table %}
columns:
  - title: Plugin
    key: plugin
  - title: Compared embeddings
    key: comparison
rows:
  - plugin: "AI Proxy Advanced"
    comparison: "Prompt vs. `description` field of each upstream target"
  - plugin: "AI Semantic Prompt Guard"
    comparison: "Prompt vs. allowlist and denylist prompts"
  - plugin: "AI Semantic Cache"
    comparison: "Prompt vs. cached prompt keys"
  - plugin: "AI RAG Injector"
    comparison: "Prompt vs. vectorized document chunks"
{% endtable %}
<!-- vale on -->



## Dimensionality

Embedding models work by converting text into high-dimensional floating-point arrays where mathematical distance reflects semantic relationship. In other words, ingested text data becomes points in a vector space, which enables similarity searches in vector databases, and the dimension of embeddings plays a critical role for this.

Dimensionality determines how many numerical features represent each piece of content—similar to how a detailed profile might have dimensions for age, interests, location, and preferences. Higher dimensions create more detailed "fingerprints" that capture nuanced relationships, with smaller distances between vectors indicating stronger conceptual similarity and larger distances showing weaker associations.

For example, this request to the OpenAI [/embeddings API](/plugins/ai-proxy/examples/embeddings-route-type/) via {{site.ai_gateway}}:

```json
{
    "input": "Tell me, Muse, of the man of many ways, who was driven far journeys, after he had sacked Troy’s sacred citadel.",
    "model": "text-embedding-3-large",
    "dimensions": 20
}
```

Creates the following embedding:

```json
{
	"object": "list",
	"data": [
		{
			"object": "embedding",
			"index": 0,
			"embedding": [
				0.26458353,
				-0.062855035,
				-0.14282244,
				0.18218088,
				-0.41043353,
				0.3704169,
				0.1712553,
				-0.10945333,
				-0.00060006406,
				0.10076551,
				-0.0697658,
				0.1779686,
				-0.3464596,
				0.028745485,
				0.3017042,
				0.2543161,
				-0.20916577,
				-0.06255886,
				-0.21469438,
				0.32934725
			]
		}
	],
	"model": "text-embedding-3-large",
	"usage": {
		"prompt_tokens": 28,
		"total_tokens": 28
	}
}
```

The `embedding` array contains 20 floating-point numbers—each one representing a dimension in the vector space.

{:.info}
> For simplicity, this example uses a reduced dimensionality of 20, though production models typically use `1536` or more.

### Accuracy and performance considerations

If you use embedding models that support defining the dimensionality of the embedding output, you should consider how to balance accuracy and performance based on your use case.

However, dimensionality extremes at the far ends of the spectrum present significant drawbacks:

{% table %}
columns:
  - title: Dimensionality range
    key: range
  - title: Benefits
    key: benefits
  - title: Drawbacks
    key: drawbacks
rows:
  - range: "Lower dimensionality (2–10 dimensions)"
    benefits: |
      * Improves speed and performance
      * Works well for simpler tasks like basic keyword matching or simple images, where hundreds of dimensions may suffice.
    drawbacks: |
      * Can be too simplistic, like calling a movie simply "good" or "bad"
      * Might miss important nuance and lead to less accurate matches
  - range: "Higher dimensionality (10,000+ dimensions)"
    benefits: |
      * Improves the granularity and nuance of similarity searches
      * Useful for complex tasks like semantic text understanding or detailed images, where thousands of dimensions are often required.
    drawbacks: |
      * Increases storage and computation costs
      * Can suffer from the "curse of dimensionality", where differences become less meaningful.
{% endtable %}

{:.success}
> Use moderate dimensionality when possible, and tune it based on both the complexity of your data and the responsiveness required by your application.

### Cosine and Euclidean similarity

{{site.ai_gateway}} supports both cosine similarity and Euclidean distance for vector comparisons, allowing you to choose the method best suited for your use case. You can configure the method using `config.vectordb.distance_metric` setting in the respective plugin.

* Use `cosine` for nuanced semantic similarity (for example, document comparison, text clustering), especially when content length varies or dataset diversity is high.
* Use `euclidean` when magnitude matters (for example, images, sensor data) or you're working with dense, well-aligned feature sets.

#### Cosine similarity

Cosine similarity measures the angle between vectors, ignoring their magnitude. It is well-suited for semantic matching, particularly in text-based scenarios. OpenAI recommends cosine similarity for use with the `text-embedding-3-large` model.

![Cosine similarity example](/assets/images/ai-gateway/cosine-similarity.svg)
> _**Figure 2:** Visualization of cosine similarity as the angle between vector directions._

Cosine tends to perform well across both low and high dimensional space, especially in high-diversity datasets because it captures vector orientation rather than size. This can be useful, for example, when comparing texts about Microsoft, Apple, and Google.

#### Euclidean distance

Euclidean distance measures the straight-line (L2) distance between vectors and is sensitive to magnitude. It works better when comparing objects across broad thematic categories, such as Technology, Fruit, or Musical Instruments, and in domains where absolute distance is important.

![Euclidean similarity example](/assets/images/ai-gateway/euclidean-distance.svg)
> _**Figure 3:** Visualization of Euclidean distance between vector points._


### Differences between `cosine` and `euclidean`

The two graphs below illustrate a key difference between cosine similarity and Euclidean distance: **two vectors can have the same angle** (and thus the same cosine similarity, represented as `γ` below) **while their Euclidean distances may differ significantly**. This happens because cosine similarity measures only the direction of vectors, ignoring their length or magnitude, whereas Euclidean distance reflects the actual straight-line distance between points in space.

![Comparing cosine and Euclidean similarity](/assets/images/ai-gateway/cosine-euclidean.svg)
> _**Figure 4:** Two vectors with equal cosine similarity (γ) but different Euclidean distances._

The following table will help you determine which embedding similarity metric you should use based on your use cases:

<!-- vale off -->
{% table %}
columns:
  - title: Similarity metric
    key: metric
  - title: Recommended use cases
    key: use_cases
rows:
  - metric: "Cosine similarity"
    use_cases: |
      - Find semantically similar news articles regardless of length
      - Recommend products to users with similar taste profiles
      - Identify documents with overlapping topics in large corpora
      - Compare diverse text embeddings (for example, Microsoft vs. Apple)
  - metric: "Euclidean distance"
    use_cases: |
      - Find images with similar color distributions and intensity
      - Detect anomalies in sensor readings where magnitude matters
      - Compare aligned image patches using raw pixel embeddings
{% endtable %}
<!-- vale on -->

## Similarity threshold

The `vectordb.threshold` parameter controls how strictly the vector database evaluates similarity during a query. It is passed directly to the vector engine—such as Redis or PGVector—and defines which results qualify as matches. In Redis, for example, this maps to the `distance_threshold` query parameter. By default, Redis sets this to `0.2`, but you can override it to suit your use case.


The threshold defines how permissive the matching is. **Higher threshold values allow looser matches, while lower values enforce stricter matching.** The threshold range is 0 to 1.

* With **cosine similarity**, Kong uses cosine distance (1 - cosine similarity) as the comparison metric. The threshold sets the maximum allowable distance between embeddings. A value of `0` requires exact matches only (zero distance). A value of `1` allows matches with any similarity level (up to maximum distance). Typical configurations use `0.1–0.2` for strict matching and `0.5–0.8` for broader matching.

* For **Euclidean distance**, the threshold is normalized to a 0–1 range and sets the maximum allowable distance between embedding vectors. A value of `0` requires exact matches (zero distance). A value of `1` permits the broadest possible matches. Typical configurations use `0.1–0.2` for strict matching and `0.5–0.8` for broader matching.

In both cases, if the [{{site.base_gateway}} logs](/gateway/logs/) indicate "no target can be found under threshold X," increase the threshold value to allow more matches.

The optimal threshold depends on the selected distance metric, the embedding model's dimensionality, and the variation in your data. Tuning may be required for best results.

{:.info}
> In Kong's AI semantic plugins, this threshold is **not** post-processed or filtered by the plugin itself. The plugin sends it directly to the vector database, which uses it to determine matching documents based on the configured **distance metric**.

### Threshold sensitivity and cache hit effectiveness

The closer your similarity threshold is to `1`, the more likely you are to get **cache misses** when using plugins like **AI Semantic Cache**. This is because a higher threshold makes the similarity filter more strict, so only embeddings that are nearly identical to the query will qualify as a match. In practice, this means even small variations in phrasing, structure, or context can cause the system to miss otherwise semantically similar entries and fall back to calling the LLM again.

This happens because vector embeddings are not perfectly robust to minor semantic shifts, especially for short or ambiguous prompts. Raising the threshold narrows the match window, so you're effectively demanding a near-exact match in a complex vector space, which is rare unless the input is repeated verbatim.

The chart below illustrates this effect: as the similarity threshold increase (for example, becomes more strict), the cache hit rate typically falls. This reflects the broader acceptance of matches in the embedding space, which helps reduce redundant LLM calls at the cost of some semantic looseness.

![Similarity threshold and cache rate hits](/assets/images/ai-gateway/cache-hit-rate.svg)
> _**Figure 5:** As the similarity threshold decreases (becomes more permissive), cache hit rate increases—illustrating the trade-off between strict semantic matching and LLM efficiency._

This is generally true but not absolute. If you're working in a very narrow domain where inputs are highly repetitive or templated (for example, support FAQs), a low threshold might still yield good cache hit rates. Conversely, in open-ended chat or creative domains, a stricter threshold will almost always increase cache misses due to natural language variability.

### Limitations

While embedding-based similarity is efficient and effective for many use cases, it has important limitations. Embeddings typically do not capture subtle semantic changes or handle long context as well as LLMs.

For example, the following prompts may be considered semantically equivalent by a vector similarity search, even though the latter asks for additional detail:

* `Summarize this article.`
* `Summarize this article. Tell me more.`


To address these edge cases, you can use a smaller LLM model to compare two texts side-by-side, enabling deeper semantic comparison.