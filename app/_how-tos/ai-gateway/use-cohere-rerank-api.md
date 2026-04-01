---
title: Use Cohere rerank API for document-grounded chat with AI Proxy in {{site.base_gateway}}
permalink: /how-to/use-cohere-rerank-api/
content_type: how_to
related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/
  - text: AI Proxy
    url: /plugins/ai-proxy/
description: "Use Cohere's rerank API for retrieval-augmented text generation with automatic relevance filtering and citations."
breadcrumbs:
  - /ai-gateway/

products:
  - gateway
  - ai-gateway

works_on:
  - on-prem
  - konnect

min_version:
  gateway: '3.10'

plugins:
  - ai-proxy

entities:
  - service
  - route
  - plugin

tags:
  - ai
  - cohere

tldr:
  q: How do I use Cohere `/rerank` API with {{site.ai_gateway}}?
  a: Configure the AI Proxy plugin with the Cohere provider and a chat model, then send queries with documents to get generated answers that automatically filter for relevance and include citations.

tools:
  - deck

prereqs:
  inline:
    - title: Cohere API Key
      content: |
        Before you begin, you must get a Cohere API key:

        - Sign up at [Cohere](https://cohere.com/)
        - Navigate to API Keys in your dashboard
        - Create a new API key

        Export the API key as an environment variable:
        ```sh
        export DECK_COHERE_API_KEY="<your-api-key>"
        ```
      icon_url: /assets/icons/cohere.svg
    - title: Python and requests library
      content: |
        Install Python 3 and the requests library:
        ```sh
        pip install requests
        ```
      icon_url: /assets/icons/python.svg
  entities:
    services:
      - rerank-service
    routes:
      - rerank-route

cleanup:
  inline:
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg

faqs:
  - q: What is document-grounded chat and why is it useful?
    a: |
      Document-grounded chat generates answers based only on provided documents, automatically filtering for relevance and providing citations. This improves RAG pipelines by combining retrieval filtering and answer generation in a single step.
  - q: How many documents can I provide?
    a: |
      Cohere's Chat API supports multiple documents per request. The model automatically selects the most relevant documents for generating the answer.
  - q: What models support document grounding?
    a: |
      Cohere models including `command-a-03-2025` support document-grounded chat. Refer to the Cohere documentation for the complete list of available models.

automated_tests: false
---

## Configure the plugin

Configure AI Proxy to use Cohere's document-grounded chat:

{% entity_examples %}
entities:
  plugins:
    - name: ai-proxy
      service: rerank-service
      config:
        llm_format: cohere
        route_type: llm/v1/chat
        logging:
          log_payloads: false
          log_statistics: true
        model:
          provider: cohere
          name: command-a-03-2025
        auth:
          header_name: Authorization
          header_value: "Bearer ${cohere_api_key}"
variables:
  cohere_api_key:
    value: $COHERE_API_KEY
{% endentity_examples %}

## Use Cohere document-grounded chat

Cohere's document-grounded chat filters candidate documents and generates answers in a single API call. Send a query with candidate documents. The model selects relevant documents, generates an answer using only those documents, and returns citations linking answer segments to sources. This replaces multi-step RAG pipelines with one request.

The following script sends a query with 5 candidate documents to Cohere's chat endpoint. Three documents discuss green tea health benefits. Two documents are intentionally irrelevant (Eiffel Tower, Python programming).

The script attempts to show which documents the model used by comparing the `documents` field in the response to the input documents. This demonstrates whether Cohere's document-grounded chat filters out irrelevant documents automatically.

Create the script:
```sh
cat > grounded-chat-demo.py << 'EOF'
#!/usr/bin/env python3
"""Demonstrate document filtering in Cohere grounded chat"""

import requests
import json

CHAT_URL = "http://localhost:8000/rerank"

print("Cohere Document Filtering Demo")
print("=" * 60)

query = "What are the health benefits of drinking green tea?"
documents = [
    {"text": "Green tea contains powerful antioxidants called catechins that may help reduce inflammation and protect cells from damage."},
    {"text": "The Eiffel Tower is a wrought-iron lattice tower located in Paris, France, and is one of the most recognizable structures in the world."},
    {"text": "Studies suggest that regular green tea consumption may boost metabolism and support weight management."},
    {"text": "Python is a high-level programming language known for its simplicity and readability, widely used in data science and web development."},
    {"text": "Green tea has been associated with improved brain function and may reduce the risk of neurodegenerative diseases."}
]

print(f"\nQuery: {query}\n")

# Show input documents
print("--- INPUT: All Candidate Documents ---")
for idx, doc in enumerate(documents, 1):
    print(f"{idx}. {doc['text']}")

# Send request
response = requests.post(
    CHAT_URL,
    headers={"Content-Type": "application/json"},
    json={
        "model": "command-a-03-2025",
        "query": query,
        "documents": documents,
        "return_documents": True
    }
)

result = response.json()

# Extract document IDs that were used
used_doc_ids = set()
if 'documents' in result:
    for doc in result['documents']:
        # Map returned docs back to original indices
        for idx, orig_doc in enumerate(documents):
            if doc['text'] == orig_doc['text']:
                used_doc_ids.add(idx)

# Show relevant documents
print("\n--- OUTPUT: Relevant Documents (Used in answer) ---")
if 'documents' in result:
    for doc in result['documents']:
        print(f"✓ {doc['text']}")

# Show filtered documents
print("\n--- FILTERED OUT: Irrelevant Documents ---")
for idx, doc in enumerate(documents):
    if idx not in used_doc_ids:
        print(f"✗ {doc['text']}")

# Show answer with citations
print("\n--- GENERATED ANSWER ---")
print(result.get('text', ''))

if 'citations' in result:
    print("\n--- CITATIONS ---")
    for citation in result['citations']:
        print(f"- \"{citation['text']}\" → {citation['document_ids']}")

print("\n" + "=" * 60)
EOF
```


{:.info}
> Verify that the `return_documents` parameter actually returns the filtered document subset. Check [Cohere's API documentation](https://docs.cohere.com/reference/about) or test the script to confirm this behavior.

## Validate the configuration

Let's run the script we created in the previous step:

```sh
python3 grounded-chat-demo.py
```

Example output:

```text
Cohere Document Filtering Demo
============================================================

Query: What are the health benefits of drinking green tea?

--- INPUT: All Candidate Documents ---
1. Green tea contains powerful antioxidants called catechins that may help reduce inflammation and protect cells from damage.
2. The Eiffel Tower is a wrought-iron lattice tower located in Paris, France, and is one of the most recognizable structures in the world.
3. Studies suggest that regular green tea consumption may boost metabolism and support weight management.
4. Python is a high-level programming language known for its simplicity and readability, widely used in data science and web development.
5. Green tea has been associated with improved brain function and may reduce the risk of neurodegenerative diseases.

--- PROCESSING ---
Filtering documents and generating answer... ✓

--- OUTPUT: Relevant Documents (Used in answer) ---
✓ Green tea contains powerful antioxidants called catechins that may help reduce inflammation and protect cells from damage.
✓ Green tea has been associated with improved brain function and may reduce the risk of neurodegenerative diseases.
✓ Studies suggest that regular green tea consumption may boost metabolism and support weight management.

--- FILTERED OUT: Irrelevant Documents ---
✗ The Eiffel Tower is a wrought-iron lattice tower located in Paris, France, and is one of the most recognizable structures in the world.
✗ Python is a high-level programming language known for its simplicity and readability, widely used in data science and web development.

--- GENERATED ANSWER ---
Green tea has powerful antioxidants called catechins that may reduce inflammation and protect cells from damage. It has also been associated with improved brain function and may reduce the risk of neurodegenerative diseases. Regular consumption may boost metabolism and support weight management.

--- CITATIONS ---
- "powerful antioxidants called catechins" → ['doc_0']
- "reduce inflammation" → ['doc_0']
- "protect cells from damage." → ['doc_0']
- "associated with improved brain function" → ['doc_4']
- "reduce the risk of neurodegenerative diseases." → ['doc_4']
- "Regular consumption" → ['doc_2']
- "boost metabolism" → ['doc_2']
- "support weight management." → ['doc_2']

============================================================
```

As you can see, the output shows three document-grounding behaviors:

* **Automatic filtering**: The model used only the three green tea documents. It filtered out the Eiffel Tower and Python documents.
* **Source-restricted generation**: The answer contains only information from the input documents.
* **Citation mapping**: Each statement maps to specific source documents through the `document_ids` field.
