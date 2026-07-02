---
title: 'AI RAG Injector'
name: 'AI RAG Injector'

content_type: policy

publisher: kong-inc
description: 'Create RAG pipelines by automatically injecting content from a vector database'


products:
    - ai-gateway

works_on:
    - konnect

min_version:
    ai-gateway: '2.0'

topologies:
  konnect_deployments:
    - hybrid
    - cloud-gateways
    - serverless

icon: ai-rag-injector.png

categories:
  - ai
related_resources:
  - text: All {{site.ai_gateway}} AI Policies
    url: /ai-gateway/policies/
  - text: About {{site.ai_gateway}}
    url: /ai-gateway/
  - text: AI Semantic Cache Policy
    url: /ai-gateway/policies/ai-semantic-cache/
  - text: Ensure chatbots adhere to compliance policies with the AI RAG Injector Policy
    url: /how-to/use-ai-rag-injector-plugin/
  - text: Control access to knowledge base collections with the AI RAG Injector Policy
    url: /how-to/use-ai-rag-injector-acls/
  - text: Filter knowledge base queries with the AI RAG Injector Policy
    url: /how-to/filter-knowledge-based-queries-with-rag-injector/
tags:
  - ai
search_aliases:
  - ai-semantic-cache
  - ai
  - llm
  - artificial
  - intelligence
  - language
  - model

faqs:
  - q: What embedding dimension should I use in my `vectordb` config?
    a: The [embedding dimension](/ai-gateway/policies/ai-rag-injector/reference/#schema--config-vectordb-dimensions) you use depends on your model and use case. More dimensions improve accuracy but increase cost. `1536` is a balanced default if you use the OpenAI `text-embedding-3-large` model.

  - q: Can I reduce embedding dimensions to save resources?
    a: Yes. Use PCA, t-SNE, or UMAP to keep key features while lowering memory and latency.

  - q: What chunk size should I use for RAG?
    a: Common sizes are 200–1000 tokens. Smaller chunks give precision; larger ones preserve context.

  - q: Should I add chunk overlap?
    a: Yes. Overlap helps maintain context between chunks and improves retrieval quality.

  - q: How should I split text into chunks?
    a: Use token-, sentence-, or semantic-based chunking based on your data and query type.

  - q: Which distance metric works best with embeddings?
    a: Cosine similarity is the best [distance metric](/ai-gateway/policies/ai-rag-injector/reference/#schema--config-vectordb-distance-metric) for text. Use Euclidean only for coordinate-based data.

  - q: Where should I inject RAG context in the prompt?
    a: |
      It depends on your priorities:
      * `system` offers strong guidance, but carries higher prompt injection risk
      * `user` is safer for untrusted content
      * `assistant` offers moderate influence
      You can set this via the [`inject_as_role`](/ai-gateway/policies/ai-rag-injector/reference/#schema--config-inject-as-role) setting.
  - q: |
      How do I resolve the MemoryDB error `Number of indexes exceeds the limit`?
    a: |
      If you see the following error in the logs:

      ```sh
      failed to create memorydb instance failed to create index: LIMIT Number of indexes (11) exceeds the limit (10)
      ```

      This means that the hardcoded MemoryDB instance limit has been reached.
      To resolve this, create more MemoryDB instances to handle multiple {{page.name}} policy instances.
  - q: Does the AI RAG Injector Policy work with GCP Memorystore Redis clusters?
    a: |
      No. GCP Memorystore Redis clusters do not support the AI RAG Injector Policy. The Redis JSON module required for vector operations is not available in GCP's managed Redis service.

      Attempting to ingest chunks with GCP Redis results in the following error:
---

## What is Retrieval Augmented Generation (RAG)?

Retrieval-Augmented Generation (RAG) is a technique that improves the accuracy and relevance of language model responses by enriching prompts with external data at runtime. Instead of relying solely on what the model was trained on, RAG retrieves contextually relevant information such as documents, support articles, or internal knowledge from connected data sources like vector databases.

This retrieved context is then automatically injected into the prompt before the model generates a response. RAG is a critical safeguard in specialized or high-stakes applications, where factual accuracy matters. LLMs are prone to hallucinations, plausible-sounding but factually incorrect or fabricated responses. RAG helps mitigate this by grounding the model’s output in real, verifiable data.

The following table describes the different use cases for RAG based on industry:

<!-- vale off -->
{% table %}
columns:
  - title: Industry
    key: industry
  - title: Use case
    key: use_case
rows:
  - industry: Healthcare
    use_case: |
      RAG can help surface up-to-date clinical guidelines or patient records in a timely manner, critical when treatment decisions depend on the most current information.
  - industry: Legal
    use_case: |
      Lawyers can use RAG-powered assistants to instantly retrieve relevant case law, legal precedents, or compliance documentation during client consultations.
  - industry: Finance
    use_case: |
      In fast-moving markets, RAG enables models to deliver financial insights based on current data, avoiding outdated or misleading responses driven by stale training snapshots.
{% endtable %}
<!-- vale on -->

## Why use the AI RAG Injector Policy

The AI RAG Injector Policy automates the retrieval and injection of contextual data for RAG pipelines without doing manual prompt engineering or retrieval logic. Integrated at the gateway level, it handles embedding generation, vector search, and context injection transparently for each request.

* **Simplifies RAG workflows:** Automatically embeds prompts, queries the vector DB, and injects relevant context without custom retrieval logic.
* **Platform-level control:** Shifts RAG logic from app code to infrastructure, allowing platform teams to enforce global policies, update configurations centrally, and reduce developer overhead.
* **Improved security:** Vector DB access is limited to the {{site.ai_gateway}}, eliminating the need to expose it to individual dev teams or AI agents.
* **Enables RAG in restricted environments:** Supports RAG even where direct access to the vector database is not possible, such as external-facing or isolated services.
* **Developer productivity:** Developers can focus on building AI features without needing to manage embeddings, similarity search, or context handling.
* **Save LLM costs:** When using the AI RAG Injector Policy with the AI Prompt Compressor, you can wrap specific prompt parts in `<LLMLINGUA>` tags within your template to target only those sections for compression, preserving the rest of the prompt unchanged.

{% include md/ai-gateway/v2/policies/ai-policy-note.md %}

## How the AI RAG Injector Policy works

When a user sends a prompt, the AI RAG Injector Policy queries a configured vector database for relevant context and injects that information into the request before passing it to the language model.

1. You attach the AI RAG Injector Policy to an [AI Model](/ai-gateway/entities/ai-model/) via the Konnect API, configuring vector database connection and embedding settings.
1. When a request reaches the {{site.ai_gateway}}, the AI Policy generates embeddings for request prompts, then queries the vector database for the top-k most similar embeddings.
1. The AI Policy injects the retrieved content from the vector search result into the request body, and forwards the request to the upstream service.

The following diagram is a simplified overview of how the AI Policy works.  See the [following section](#rag-generation-process) for a more detailed description.

<!-- vale off -->
{% mermaid %}
sequenceDiagram
    participant User
    participant AIGateway as AI Gateway (AI RAG Injector Policy)
    participant VectorDB as Vector DB (Knowledge store)
    participant Upstream as Upstream Service

    User->>AIGateway: Send request with prompt
    AIGateway->>VectorDB: Query for similar embeddings
    VectorDB-->>AIGateway: Return relevant context
    AIGateway->>Upstream: Inject context and forward enriched request
    Upstream-->>User: Return response
{% endmermaid %}
<!-- vale on -->

### RAG Generation process

The RAG workflow consists of two critical phases:
1. **Data preparation**: Processes and embeds unstructured data into a vector index for efficient semantic search
1. **Retrieval and generation**: The system uses similarity search to dynamically assemble contextual prompts that guide the language model’s output.


#### Phase 1: Data Preparation

This phase sets up the foundation for semantic retrieval by converting raw data into a format that can be indexed and searched efficiently.

**Step breakdown:**

1. A document loader pulls content from various sources, such as PDFs, websites, emails, or internal systems.
2. The system breaks the unstructured data into smaller, semantically meaningful chunks to support precise retrieval.
3. Each chunk is transformed into a vector embedding (a numeric representation that captures its semantic content).
4. These embeddings are saved to a vector database, enabling a fast, similarity-based search during query time.

#### Phase 2: Retrieval and Generation

This phase runs in real time, taking user input and producing a context-aware response using the indexed data.

**Step breakdown:**

1. The user’s query is converted into an embedding using the same model used during data preparation.
1. A semantic similarity search locates the most relevant content chunks in the vector database.
1. The system builds a custom prompt by combining the retrieved chunks with the original query.
1. The LLM generates a contextually accurate response using both the retrieved context and its own internal knowledge.

The diagram below shows how data flows through both phases of the RAG pipeline, from ingestion and embedding to real-time query handling and response generation:

<!-- vale off -->
{% mermaid %}
sequenceDiagram
    autonumber
    actor User
    participant RawData as Raw Data
    participant EmbeddingModel as Embedding Model
    participant VectorDB as Vector Database
    participant LLM

    par Data preparation
        activate RawData
        RawData->>EmbeddingModel: Load and chunk documents, generate embeddings
        deactivate RawData

        activate EmbeddingModel
        EmbeddingModel->>VectorDB: Store embeddings
        deactivate EmbeddingModel

        activate VectorDB
        deactivate VectorDB
    end

    par Retrieval & generation
        activate User
        User->>EmbeddingModel: (1) Submit query and generate query embedding

        activate EmbeddingModel
        EmbeddingModel->>VectorDB: (2) Search vector DB
        deactivate EmbeddingModel

        activate VectorDB
        VectorDB-->>EmbeddingModel: Return relevant chunks
        deactivate VectorDB

        activate EmbeddingModel
        EmbeddingModel->>LLM: (3) Assemble prompt and send
        deactivate EmbeddingModel

        activate LLM
        LLM-->>User: (4) Generate and return response
        deactivate LLM
        deactivate User
    end
{% endmermaid %}
<!-- vale on -->


Rather than guessing from memory, the LLM paired with the RAG pipeline now has the ability to look up the information it needs in real time, which reduces hallucinations and increases the accuracy of the AI output.

## Vector databases

{% include_cached /plugins/ai-vector-db.md name=page.name %}

### Using cloud authentication with Redis

{% include_cached md/ai-gateway/v2/redis-cloud-auth.md tier=page.tier %}

{% include_cached md/ai-gateway/v2/redis-cloud-providers.md name=page.name heading_level=3 %}

## Access control and metadata filtering

Once you've configured your vector database and ingested content, you can control which [AI Consumers](/gateway/entities/consumer/) access specific knowledge base articles and refine query results using metadata filters.

### Collections

A collection is a logical grouping of knowledge base articles with independent access control rules. When you ingest content via the Konnect API, assign it to a collection using the `collection` field in the metadata.

Example metadata structure:

```json
{
  "content": "Quarterly revenue increased 15%...",
  "metadata": {
    "collection": "finance-reports",
    "date": "2023-10-14",
    "tags": ["finance", "quarterly"],
    "source": "internal"
  }
}
```

### Configuration

Two independent mechanisms control which results consumers receive:

- **ACL filtering**: Server restricts collections based on [AI Consumer Groups](/gateway/entities/consumer-group/)
- **Metadata filtering**: Clients specify criteria (tags, dates, sources) to narrow results within authorized collections

<!-- vale off -->
{% table %}
columns:
  - title: Field
    key: field
  - title: Description
    key: description
rows:
  - field: |
      [`consumer_identifier`](/#schema--config-consumer-identifier)
    description: |
      Determines which consumer attribute is matched against ACL rules. Options: `consumer_group`, `username`, `custom_id`, or `consumer_id`
  - field: |
      [`global_acl_config.allow[]`](/#schema--config-global-acl-config-allow)
    description: |
      Group names with access to all collections (unless overridden)
  - field: |
      [`global_acl_config.deny[]`](/#schema--config-global-acl-config-deny)
    description: |
      Group names explicitly denied access to all collections
  - field: |
      [`collection_acl_config.<name>.allow[]`]()
    description: |
      Group names with access to this specific collection. Empty list means allow all
  - field: |
      [`collection_acl_config.<name>.deny[]`](/#schema--config-collection-acl-config)
    description: |
      Group names explicitly denied access to this specific collection
{% endtable %}
<!-- vale on -->

This configuration creates the following access rules:
- `finance-reports`: Accessible only to AI Consumers in the `finance` or `admin` groups. Contractors are explicitly denied.
- `public-docs`: Accessible to all AI Consumers (empty allow and deny lists).
- Other collections: No access (empty global ACL means deny by default).

{:.info}
> This example assumes you have already created [AI Consumer Groups](/ai-gateway/entities/ai-consumer-groups) (`finance`, `admin`, `contractor`) and configured the [Key Authentication Policy](/ai-gateway/policies/key-auth) for your AI Consumers.

### Environment variables

Set the following environment variables before deploying:

* `OPENAI_API_KEY`: Your OpenAI API key
* `DB_PASSWORD`: Your PostgreSQL database password

{:.warning}
> Never hardcode credentials in your policy configuration. Always use environment variables or secrets.

{% entity_example %}
type: policy
data:
  type: ai-rag-injector
  name: finance-db
  display_name: Finance DB
  config:
    consumer_identifier: consumer_group
    global_acl_config:
      allow: []
      deny: []
    collection_acl_config:
      finance-reports:
        allow:
          - finance
          - admin
        deny:
          - contractor
      public-docs:
        allow: []
        deny: []
    embeddings:
      model:
        name: text-embedding-3-small
        provider: openai
      auth:
        header_name: Authorization
        header_value: Bearer ${OPENAI_API_KEY}
    vectordb:
      strategy: pgvector
      dimensions: 1536
      distance_metric: cosine
      pgvector:
        host: localhost
        port: 5432
        user: postgres
        password: ${DB_PASSWORD}
        database: kong-pgvector
formats:
  - konnect-api
{% endentity_example %}

In this configuration, collections with their own ACL in `collection_acl_config` ignore `global_acl_config` entirely. They must explicitly list all allowed subjects.

### ACL evaluation

The AI Policy checks access in this order:

1. **Deny list**: If subject matches, deny access
2. **Allow list**: If list exists and subject doesn't match, deny access
3. **Empty ACL**: If both lists are empty, allow access

{:.info}
> Collections with their own ACL in `collection_acl_config` ignore `global_acl_config` entirely. They must explicitly list all allowed subjects.

### Metadata filtering

LLM clients can refine search results by specifying filter criteria in the query request. Filters apply within the collections. The AI RAG Injector Policy uses a Bedrock-compatible filter grammar with the following operators:

- `equals`: Exact match
- `greaterThan`: Greater than (>)
- `greaterThanOrEquals`: Greater than or equal to (>=)
- `lessThan`: Less than (<)
- `lessThanOrEquals`: Less than or equal to (<=)
- `in`: Match any value in array
- `andAll`: Combine multiple filter clauses

You can combine multiple conditions with `andAll`:

<!-- vale off -->
```json
{
  "andAll": [
    {"equals": {"key": "source", "value": "internal"}},
    {"in": {"key": "tags", "value": ["finance", "quarterly"]}},
    {"greaterThanOrEquals": {"key": "date", "value": "2023-01-01"}}
  ]
}
```
<!-- vale on -->

Filter parameters:

<!-- vale off -->
{% table %}
columns:
  - title: Parameter
    key: parameter
  - title: Description
    key: description
rows:
  - parameter: |
      `filters`
    description: |
      JSON object with filter clauses using the grammar above
  - parameter: |
      `filter_mode`
    description: |
      Controls how chunks with no metadata are handled:<br/>
      • `"compatible"`: Includes chunks matching filter OR chunks with no metadata<br/>
      • `"strict"`: Includes only chunks matching filter
  - parameter: |
      `stop_on_filter_error`
    description: |
      Fail query on filter parse error (default: `false`)
{% endtable %}
<!-- vale on -->

You can include filters in the `ai_rag_injector` parameter of your request:

<!-- vale off -->
```json
curl "http://localhost:8000/" \
     -H "Content-Type: application/json" \
     --json '{
       "messages": [
         {
           "role": "user",
           "content": "What were Q4 results?"
         }
       ],
       "ai-rag-injector": {
         "filters": {
           "andAll": [
             {
               "equals": {
                 "key": "source",
                 "value": "internal"
               }
             },
             {
               "in": {
                 "key": "tags",
                 "value": [
                   "q4",
                   "quarterly"
                 ]
               }
             }
           ]
         },
         "filter_mode": "strict",
         "stop_on_filter_error": false
       }
     }'
```
<!-- vale on -->

### Query flow

The following diagram shows how ACL and metadata filtering work together during query processing:

{% mermaid %}
flowchart TB
    Start([Query Request]) --> Auth[Authenticate Consumer]
    Auth --> CheckACL{Authorized<br/>Collections?}
    CheckACL -->|No| Deny[❌ Access Denied]
    CheckACL -->|Yes| HasFilter{Metadata<br/>Filters<br/>Specified?}
    HasFilter -->|No| SearchAll[Search all chunks<br/>in authorized collections]
    HasFilter -->|Yes| FilterMode{filter_mode<br/>setting?}
    FilterMode -->|compatible| SearchCompat[Return chunks matching filter<br/>OR chunks with no metadata]
    FilterMode -->|strict| SearchStrict[Return only chunks<br/>matching filter]
    SearchAll --> Return[✓ Return Results]
    SearchCompat --> Return
    SearchStrict --> Return
{% endmermaid %}

### Konnect API

Use the [Konnect API](/ai-gateway/policies/ai-rag-injector/api/) to ingest content with metadata and collection assignments.

- Ingest chunk:

  ```bash
  POST /ai-rag-injector/{pluginID}/ingest_chunk
  {"content": "...", "metadata": {"collection": "finance-reports", ...}}
  ```

- Lookup chunks:

  ```bash
  POST /ai-rag-injector/{pluginID}/lookup_chunks
  {"prompt": "...", "collection": "finance-reports", "filters": {...}}
  ```
{% include_cached md/ai-gateway/v2/ai-vector-db.md %}
