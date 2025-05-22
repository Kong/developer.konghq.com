---
title: 'AI RAG Injector'
name: 'AI RAG Injector'

ai_gateway_enterprise: true

content_type: plugin

publisher: kong-inc
description: 'Create RAG pipelines by automatically injecting content from a vector database'


products:
    - gateway
    - ai-gateway

works_on:
    - on-prem
    - konnect

min_version:
    gateway: '3.10'

topologies:
  on_prem:
    - hybrid
    - db-less
    - traditional
  konnect_deployments:
    - hybrid
    - cloud-gateways
    - serverless

icon: ai-rag-injector.png

categories:
  - ai
related_resources:
  - text: All AI Gateway plugins
    url: /plugins/?category=ai
  - text: About AI Gateway
    url: /ai-gateway/
  - text: AI Semantic Cache plugin
    url: /plugins/ai-semantic-cache/
  - text: Configure the AI RAG Injector plugin with OpenAI
    url: /how-to/use-ai-rag-injector-plugin/

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
---

## What is Retrieval Augmented Generation (RAG)?

Retrieval-Augmented Generation (RAG) is a technique that improves the accuracy and relevance of language model responses by enriching prompts with external data at runtime. Instead of relying solely on what the model was trained on, RAG retrieves contextually relevant information—such as documents, support articles, or internal knowledge—from connected data sources like vector databases.

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

## Why use the AI RAG Injector plugin

The **AI RAG Injector** plugin automates the retrieval and injection of contextual data for RAG pipelines without doing manual prompt engineering or retrieval logic. Integrated at the gateway level, it handles embedding generation, vector search, and context injection transparently for each request.

* **Simplifies RAG workflows:** Automatically embeds prompts, queries the vector DB, and injects relevant context without custom retrieval logic.
* **Platform-level control:** Shifts RAG logic from app code to infrastructure, allowing platform teams to enforce global policies, update configurations centrally, and reduce developer overhead.
* **Improved security:** Vector DB access is limited to the AI Gateway, eliminating the need to expose it to individual dev teams or AI agents.
* **Enables RAG in restricted environments:** Supports RAG even where direct access to the vector database is not possible, such as external-facing or isolated services.
* **Developer productivity:** Developers can focus on building AI features without needing to manage embeddings, similarity search, or context handling.

{% include plugins/ai-plugins-note.md %}

## How the AI RAG Injector plugin works

When a user sends a prompt, the RAG Injector plugin queries a configured vector database for relevant context and injects that information into the request before passing it to the language model. 

1. You configure the AI RAG Injector plugin via the Admin API or decK, setting up the RAG content to send to the vector database.
1. When a request reaches the AI Gateway, the plugin generates embeddings for request prompts, then queries the vector database for the top-k most similar embeddings.
1. The plugin injects the retrieved content from the vector search result into the request body, and forwards the request to the upstream service.

The following diagram is a simplified overview of how the plugin works.  See the [following section](#rag-generation-process) for a more detailed description.

<!-- vale off -->
{% mermaid %}
sequenceDiagram
    participant User
    participant LLM
    participant VectorDB as Vector DB (Data Source)

    User->>LLM: Submit prompt
    LLM->>VectorDB: Query for relevant context
    VectorDB-->>LLM: Return relevant context
    LLM-->>User: Generate and return response
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

    par Data Preparation Phase
        activate RawData
        RawData->>EmbeddingModel: Load and chunk documents, generate embeddings
        deactivate RawData

        activate EmbeddingModel
        EmbeddingModel->>VectorDB: Store embeddings
        deactivate EmbeddingModel

        activate VectorDB
        deactivate VectorDB
    end

    par Retrieval & Generation Phase
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


Rather than guessing from memory, the LLM paired with the RAG pipeline now has the ability to look up the information it needs in real time, which will dramatically reduce hallucinations and increase the accuracy of the AI output.
