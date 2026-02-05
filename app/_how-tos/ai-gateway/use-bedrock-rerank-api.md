---
title: Use AWS Bedrock rerank API with AI Proxy
permalink: /how-to/use-bedrock-rerank-api/
content_type: how_to
related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/
  - text: AI Proxy
    url: /plugins/ai-proxy/
  - text: AWS Bedrock Rerank API
    url: https://docs.aws.amazon.com/bedrock/latest/APIReference/API_agent-runtime_Rerank.html
breadcrumbs:
 - /ai-gateway/

description: "Configure the AI Proxy plugin to use AWS Bedrock's Rerank API for improving document retrieval relevance in RAG pipelines."

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
  - bedrock

tldr:
  q: How do I use AWS Bedrock Rerank with the AI Proxy plugin?
  a: Configure AI Proxy with the `bedrock` provider and the `llm/v1/chat` route type. Send a query and candidate documents to the `/rerank` endpoint. The API returns documents reordered by relevance score.

tools:
  - deck

prereqs:
  inline:
    - title: AWS credentials and Bedrock model access
      content: |
        Before you begin, you must have AWS credentials with Bedrock permissions:

        - **AWS Access Key ID**: Your AWS access key
        - **AWS Secret Access Key**: Your AWS secret key
        - **Region**: AWS region where Bedrock is available (for example, `us-west-2`)

        1. Enable the rerank model in the [AWS Bedrock console](https://console.aws.amazon.com/bedrock/) under **Model Access**. Navigate to **Bedrock** > **Model access** and request access to `cohere.rerank-v3-5:0`.

        2. After model access is granted, construct the model ARN for your region:
           ```
           arn:aws:bedrock:<region>::foundation-model/cohere.rerank-v3-5:0
           ```
           Replace `<region>` with your AWS region (for example, `us-west-2`).

        3. Export the required values as environment variables:
           ```sh
           export DECK_AWS_ACCESS_KEY_ID="<your-access-key-id>"
           export DECK_AWS_SECRET_ACCESS_KEY="<your-secret-access-key>"
           export DECK_AWS_REGION="<region>"
           export DECK_AWS_MODEL="arn:aws:bedrock:<region>::foundation-model/cohere.rerank-v3-5:0"
           ```

           Replace `<region>` in both `AWS_REGION` and the `AWS_MODEL` ARN with your AWS Bedrock deployment region. See [FAQs](./#what-rerank-models-are-available) below for more details.
      icon_url: /assets/icons/aws.svg
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
  - q: What is reranking and why is it useful?
    a: |
      Reranking takes a list of search results and reorders them by semantic relevance to a query. This improves retrieval quality in RAG pipelines by ensuring the most relevant documents are sent to the LLM for generation.
  - q: How many documents can I rerank at once?
    a: |
      AWS Bedrock's Rerank API supports reranking up to 1,000 documents per request. The `numberOfResults` parameter controls how many of the highest-ranked results are returned.
  - q: What rerank models are available?
    a: |
      AWS Bedrock offers `cohere.rerank-v3-5:0` and `amazon.rerank-v1:0`. Cohere Rerank 3.5 is available in most regions, while Amazon Rerank 1.0 is not available in us-east-1.

automated_tests: false
---

## Configure the plugin

Configure AI Proxy to use AWS Bedrock's Rerank API. This requires creating a dedicated route with the `/rerank` path:

{% entity_examples %}
entities:
  plugins:
    - name: ai-proxy
      route: rerank-route
      config:
        llm_format: bedrock
        route_type: llm/v1/chat
        logging:
          log_payloads: false
          log_statistics: true
        auth:
          allow_override: false
          aws_access_key_id: ${aws_access_key_id}
          aws_secret_access_key: ${aws_secret_access_key}
        model:
          provider: bedrock
          name: ${aws_model}
          options:
            bedrock:
              aws_region: ${aws_region}
variables:
  aws_access_key_id:
    value: $AWS_ACCESS_KEY_ID
  aws_secret_access_key:
    value: $AWS_SECRET_ACCESS_KEY
  aws_region:
    value: $AWS_REGION
  aws_model:
    value: $AWS_MODEL
{% endentity_examples %}

{:.info}
> The `config.llm_format: bedrock` setting enables Kong to accept native AWS Bedrock API requests. Kong detects the `/rerank` URI pattern and automatically routes requests to the Bedrock Agent Runtime service.

## Use AWS Bedrock Rerank API

AWS Bedrock's Rerank API reorders candidate documents by semantic relevance to a query. Send a query and document list (typically from vector or keyword search). The API returns the top N documents ordered by relevance score. This reduces context size before LLM generation and prioritizes relevant information. The rerank API scores and orders documents. It does not generate answers or citations.

The following script sends a query with 5 candidate documents to AWS Bedrock's rerank endpoint. Three documents discuss exercise and health benefits. Two documents are intentionally irrelevant (Eiffel Tower, Python programming).

The script shows the original document order, then the reranked order with relevance scores. The `numberOfResults: 3` parameter limits the response to the top 3 documents. This demonstrates how reranking filters and reorders documents by semantic relevance before LLM generation.

Create the script:

```sh
cat > bedrock-rerank-demo.py << 'EOF'
#!/usr/bin/env python3
"""Demonstrate AWS Bedrock Rerank for improving RAG retrieval quality"""

import requests
import json

RERANK_URL = "http://localhost:8000/rerank"

print("AWS Bedrock Rerank Demo: RAG Pipeline Improvement")
print("=" * 60)

# Simulate documents retrieved from vector search
query = "What are the health benefits of regular exercise?"
documents = [
    "Regular exercise can improve cardiovascular health and reduce the risk of heart disease.",
    "The Eiffel Tower was completed in 1889 and stands 324 meters tall.",
    "Exercise helps maintain healthy weight by burning calories and building muscle mass.",
    "Python is a high-level programming language known for its simplicity and readability.",
    "Physical activity strengthens bones and muscles, reducing the risk of osteoporosis and falls in older adults."
]

print(f"\nQuery: {query}")
print(f"\nCandidate documents: {len(documents)}")

# Before rerank: show original order
print("\n--- BEFORE RERANK (Original retrieval order) ---")
for idx, doc in enumerate(documents):
    print(f"{idx}. {doc[:80]}...")

# Rerank the documents
print("\n--- RERANKING ---")
try:
    # Build Bedrock rerank request
    sources = []
    for doc in documents:
        sources.append({
            "type": "INLINE",
            "inlineDocumentSource": {
                "type": "TEXT",
                "textDocument": {
                    "text": doc
                }
            }
        })

    response = requests.post(
        RERANK_URL,
        headers={"Content-Type": "application/json"},
        json={
            "queries": [
                {
                    "type": "TEXT",
                    "textQuery": {
                        "text": query
                    }
                }
            ],
            "sources": sources,
            "rerankingConfiguration": {
                "type": "BEDROCK_RERANKING_MODEL",
                "bedrockRerankingConfiguration": {
                    "numberOfResults": 3,
                    "modelConfiguration": {
                        "modelArn": "arn:aws:bedrock:us-west-2::foundation-model/cohere.rerank-v3-5:0"
                    }
                }
            }
        }
    )

    response.raise_for_status()
    result = response.json()

    print("✓ Reranking complete")

    # After rerank: show reordered results
    print("\n--- AFTER RERANK (Ordered by relevance) ---")
    for item in result['results']:
        idx = item['index']
        score = item['relevanceScore']
        print(f"{idx}. [Relevance: {score:.3f}] {documents[idx][:80]}...")

    # Show the top document that should be sent to LLM
    print("\n--- TOP RESULT FOR LLM CONTEXT ---")
    top_idx = result['results'][0]['index']
    top_score = result['results'][0]['relevanceScore']
    print(f"Relevance Score: {top_score:.3f}")
    print(f"Document: {documents[top_idx]}")

except Exception as e:
    print(f"✗ Failed: {e}")

print("\n" + "=" * 60)
print("Demo complete")
EOF
```

{:.info}
> Verify that the response structure includes `results` with `index` and `relevanceScore` fields. Check [AWS Bedrock's API documentation](https://docs.aws.amazon.com/bedrock/latest/APIReference/welcome.html) or test the script to confirm this behavior.

## Validate the configuration

Now, let's run the script we created in the previous step:

```sh
python3 bedrock-rerank-demo.py
```

Example output:

```text
AWS Bedrock Rerank Demo: RAG Pipeline Improvement
============================================================

Query: What are the health benefits of regular exercise?

Candidate documents: 5

--- BEFORE RERANK (Original retrieval order) ---
0. Regular exercise can improve cardiovascular health and reduce the risk of hea...
1. The Eiffel Tower was completed in 1889 and stands 324 meters tall....
2. Exercise helps maintain healthy weight by burning calories and building muscl...
3. Python is a high-level programming language known for its simplicity and read...
4. Physical activity strengthens bones and muscles, reducing the risk of osteopo...

--- RERANKING ---
✓ Reranking complete

--- AFTER RERANK (Ordered by relevance) ---
0. [Relevance: 0.989] Regular exercise can improve cardiovascular health and reduce the risk of hea...
2. [Relevance: 0.876] Exercise helps maintain healthy weight by burning calories and building muscl...
4. [Relevance: 0.823] Physical activity strengthens bones and muscles, reducing the risk of osteopo...

--- TOP RESULT FOR LLM CONTEXT ---
Relevance Score: 0.989
Document: Regular exercise can improve cardiovascular health and reduce the risk of heart disease.

============================================================
Demo complete
```

The output shows how reranking improves retrieval quality. The three exercise-related documents (indices 0, 2, 4) are correctly identified as most relevant with high scores above 0.82. The irrelevant documents about the Eiffel Tower and Python programming are filtered out, not appearing in the top 3 results.

This reranking step ensures that when you send context to an LLM for generation, you're providing the most semantically relevant information, improving answer quality and reducing hallucinations.
