---
title: "Embedding-based similarity matching in Kong AI gateway plugins"
layout: reference
content_type: reference
description: This reference explains how Kong AI Gateway plugins use embedding-based similarity to compare prompts with various inputs—such as cached entries, upstream targets, document chunks, or allow/deny lists.
breadcrumbs:
  - /ai-gateway/

works_on:
 - on-prem
 - konnect

products:
  - gateway
  - ai-gateway

tags:
  - ai
  - load-balancing

plugins:
  - ai-proxy-advanced


min_version:
  gateway: '3.10'

related_resources:
  - text: Kong AI Gateway
    url: /ai-gateway/
  - text: Kong AI Gateway plugins
    url: /plugins/?category=ai
---

In large language tasks, applications that interact with language models rely on semantic search—not by exact word matches, but by similarity in meaning. This is achieved using vector embeddings, which represent pieces of text as points in a high-dimensional space.

These embeddings enable the concept of semantic similarity, where the “distance” between vectors reflects how closely related two pieces of text are. Similarity can be measured using techniques like cosine similarity or Euclidean distance, forming the quantitative basis for comparing meaning.

<img src="/assets/images/ai-gateway/vectors.svg" style="display: block; margin: 0 auto; padding-top: 10px; padding-bottom: 10px;" />

Vector embeddings power a range of LLM workflows, including semantic search, document clustering, recommendation systems, anomaly detection, content similarity analysis, and classification via auto-labeling.

## Semantic similarity in Kong AI Gateway

In Kong’s AI Gateway, several plugins leverage embedding-based similarity:

* **AI Semantic Cache** indexes previous prompts and responses as embeddings. On each request, it searches for semantically similar inputs and serves cached responses when possible to reduce redundant LLM calls.
* **RAG Injector** retrieves semantically relevant chunks from a vector database. It embeds the prompt, performs a similarity search, and injects the results into the prompt to enable retrieval-augmented generation.
* **AI Semantic Prompt Guard** compares incoming prompts against allow/deny lists using embedding similarity to detect and block misuse patterns.
* **AI Prompt Compressor** uses similarity-based techniques to identify and retain only the most relevant context from prior messages.
* **AI Proxy Advanced** supports semantic routing by selecting upstream targets based on prompt similarity.

### What is compared for similarity?

Each plugin applies similarity search slightly differently depending on its goal:

<!-- vale off -->

{% table %}
columns:
  - title: Plugin
    key: plugin
  - title: Compared Embeddings
    key: comparison
rows:
  - plugin: "AI Proxy Advanced"
    comparison: "Prompt vs. `description` field of each upstream target"
  - plugin: "Semantic Prompt Guard"
    comparison: "Prompt vs. allowlist and denylist prompts"
  - plugin: "Semantic Cache"
    comparison: "Prompt vs. cached prompt keys"
  - plugin: "RAG Injector"
    comparison: "Prompt vs. vectorized document chunks"
{% endtable %}


<!-- vale on -->

These comparisons determine the plugin’s behavior—whether it routes, blocks, reuses, or enriches a prompt—based on meaning rather than syntax.


## Dimensionality

Embedding models work by converting text into high-dimensional floating-point arrays where mathematical distance reflects semantic relationship. In other words, ingested text data becomes points in a vector space, which enables similarity searches in vector databases, and the dimension of embeddings plays a critical role for this.

Dimensionality determines how many numerical features represent each piece of content—similar to how a detailed profile might have dimensions for age, interests, location, and preferences. Higher dimensions create more detailed "fingerprints" that capture nuanced relationships, with smaller distances between vectors indicating stronger conceptual similarity and larger distances showing weaker associations.

For example, this request to the OpenAI [/embeddings API](/plugins/ai-proxy/examples/embeddings-route-type/) via Kong AI Gateway:

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

The `embedding` array contains 40 floating-point numbers—each one representing a dimension in the vector space. For simplicity, this example uses a reduced dimensionality of 20, though production models typically use `1536` or more.

### Practical considerations

If you use embedding models that support defining the dimensionality of the embedding output, you should consider how to balance accuracy and performance based on your use case.

- **Lower dimensionality** improves speed and performance but might miss important nuance and lead to less accurate matches. This works well for simpler tasks like basic keyword matching or simple images, where hundreds of dimensions may suffice.

-  **Higher dimensionality** improves the granularity and nuance of similarity searches but increases storage and computation costs. This is needed for complex tasks like semantic text understanding or detailed images, where thousands of dimensions are often required.

However, dimensionality extremes at the far ends of the spectrum present significant drawbacks:

{% table %}
columns:
  - title: Dimensionality range
    key: range
  - title: Drawbacks
    key: drawbacks
rows:
  - range: "Very low (2–10 dimensions)"
    drawbacks: "Fast but too simplistic; similarity search loses meaning. Like calling a movie simply 'good' or 'bad.'"
  - range: "Very high (10,000+ dimensions)"
    drawbacks: "Detailed but slow and expensive; can suffer from the 'curse of dimensionality,' where differences become less meaningful."
{% endtable %}

{:.success}
> Use moderate dimensionality when possible, and tune it based on both the complexity of your data and the responsiveness required by your application.

### Cosine and Euclidean similarity

Kong AI Gateway supports both **cosine similarity** and **Euclidean distance** for vector comparisons, allowing you to choose the method best suited for your use case.

**Cosine similarity**—as the name suggests—measures the angle between vectors, ignoring their magnitude. It is well-suited for **semantic matching**, particularly in text-based scenarios. OpenAI recommends cosine similarity for use with the `text-embedding-3-large` model.

<figure>
    <img src="/assets/images/ai-gateway/cosine-similarity.svg" style="display: block; margin: 0 auto;" />
    <figcaption style="text-align: center; font-style: italic; font-size: 12px;">
        Figure 1: Visualization of cosine similarity as the angle between vector directions.
    </figcaption>
</figure>

Cosine tends to perform well across both **low and high dimensional spaces**, especially in **high-diversity datasets**—for example, when comparing texts about Microsoft, Apple, and Google—because it captures vector orientation rather than size.

**Euclidean distance** measures the straight-line (L2) distance between vectors and is sensitive to **magnitude**. It works better when comparing objects across **broad thematic categories**, such as Technology, Fruit, or Musical Instruments, and in domains where **absolute distance** is important.

<figure>
    <img src="/assets/images/ai-gateway/euclidean-distance.svg" style="display: block; margin: 0 auto;" />
    <figcaption style="text-align: center; font-style: italic; margin-top: 0.5em; font-size: 12px;">
        Figure 2: Visualization of Euclidean distance between vector points.
    </figcaption>
</figure>

{:.success}
>Use **cosine** for nuanced semantic similarity (for example, document comparison, text clustering), especially when content length varies or dataset diversity is high.
>
> Use **Euclidean** when **magnitude** matters (for example, images, sensor data) or you're working with **dense, well-aligned feature sets**.

### Cosine similarity versus Euclidean distance

The two graphs below illustrate a key difference between cosine similarity and Euclidean distance: **two vectors can have the same angle** (and thus the same cosine similarity, represented as `γ` below) **while their Euclidean distances may differ significantly**. This happens because cosine similarity measures only the direction of vectors, ignoring their length or magnitude, whereas Euclidean distance reflects the actual straight-line distance between points in space.

<figure>
    <img src="/assets/images/ai-gateway/cosine-euclidean.svg" style="display: block; margin: 0 auto;" />
    <figcaption style="text-align: center; font-style: italic; margin-top: 0.5em; font-size: 12px;">
        Figure 3: Two vectors with equal cosine similarity (γ) but different Euclidean distances.
    </figcaption>
</figure>

{% table %}
columns:
  - title: Similarity Metric
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


<!-- MISSING SECTIONS ON THRESHOLDS AND CAVEATS -->