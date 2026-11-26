---
title: Ensure chatbots adhere to compliance policies with the AI RAG Injector Policy
permalink: /ai-gateway/use-ai-rag-injector-policy/
content_type: how_to
related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/
  - text: AI RAG Injector
    url: /ai-gateway/policies/ai-rag-injector/
  - text: AI Model entity reference
    url: /ai-gateway/entities/ai-model/
  - text: AI Policy entity reference
    url: /ai-gateway/entities/ai-policy/

description: Learn how to configure the AI RAG Injector Policy and ingest content into Redis so that a chatbot answers compliance questions from approved documents.

products:
  - ai-gateway

works_on:
  - konnect

min_version:
  ai-gateway: '2.0'

entities:
  - ai-model-provider
  - ai-model
  - ai-policy

tags:
  - ai
  - openai

tldr:
  q: How do I use the AI RAG Injector Policy to ensure that my company chatbot answers compliance questions from approved documents?
  a: |
    Create an AI Model with an AI RAG Injector Policy that points to a Redis vector database.
    {{site.ai_gateway}} doesn't expose an ingestion endpoint, so split your documents into chunks, generate embeddings, and write them to Redis with a script.
    Set the same `vectordb_namespace` in the Policy and in the script.

tools:
  - kongctl

prereqs:
  inline:
    - title: OpenAI API key
      include_content: md/ai-gateway/v2/prereqs/openai-kongctl
      icon_url: /assets/icons/openai.svg
    - title: Redis Stack
      include_content: md/ai-gateway/v2/prereqs/redis-stack
      icon_url: /assets/icons/redis.svg
    - title: Python
      include_content: md/ai-gateway/v2/prereqs/rag-ingest-python
      icon_url: /assets/icons/python.svg

cleanup:
  inline:
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg
    - title: Destroy the Redis Stack container
      include_content: cleanup/third-party/redis-stack
      icon_url: /assets/icons/redis.svg

---

## Create the AI Model Provider, AI RAG Injector Policy, and AI Model

Create an [AI Model Provider](/ai-gateway/entities/ai-model-provider/) that stores your OpenAI credentials, an [AI Model](/ai-gateway/entities/ai-model/) that clients send requests to, and an [AI RAG Injector Policy](/ai-gateway/policies/ai-rag-injector/) that adds the retrieved content to each prompt.

{% entity_examples %}
ai_gateway_model_providers:
  - ref: generic-openai
    name: generic-openai
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    type: openai
    config:
      auth:
        type: basic
        headers:
          - name: Authorization
            value: !secret {source: !env OPENAI_AUTH_HEADER}
ai_gateway_policies:
  - ref: compliance-rag
    name: compliance-rag
    display_name: compliance-rag
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    type: ai-rag-injector
    enabled: true
    global: false
    config:
      vectordb_namespace: compliance_policies
      inject_template: |
        You are an AI assistant designed to answer employee questions using only the approved compliance content provided between the <RAG></RAG> tags.
        Do not use external or general knowledge, and do not answer if the information is not available in the RAG content.
        <RAG><CONTEXT></RAG>
        User's question: <PROMPT>
        Respond only with information found in the <RAG> section. If the answer is not clearly present, reply with:
        "I'm sorry, I cannot answer that based on the available compliance information."
      embeddings:
        auth:
          header_name: Authorization
          header_value: !env OPENAI_AUTH_HEADER
        model:
          provider: openai
          name: text-embedding-3-large
      vectordb:
        strategy: redis
        redis:
          host: !env REDIS_HOST
          port: 6379
        distance_metric: cosine
        dimensions: 3072
ai_gateway_models:
  - ref: rag-gpt-4o
    display_name: rag-gpt-4o
    name: rag-gpt-4o
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    type: model
    enabled: true
    formats: [{ type: openai }]
    config:
      route:
        paths:
          - /
        model:
          body_param: model
          values:
            - rag-gpt-4o
    capabilities: [generate]
    policies: [ !ref compliance-rag#name ]
    targets:
      - name: gpt-4o
        provider: generic-openai
        config:
          type: openai
{% endentity_examples %}

In this example, the Policy uses the following settings:

* `vectordb_namespace`: The name of the knowledge base in Redis.
  The Policy searches the Redis index `idx:vss_compliance_policies` and the keys that start with `compliance_policies:`.
* `inject_template`: The prompt that {{site.ai_gateway}} sends to OpenAI.
  {{site.ai_gateway}} replaces `<CONTEXT>` with the retrieved chunks and `<PROMPT>` with the user's question.
* `vectordb.dimensions`: The size of the vectors.
  The value must match the embedding model, and `text-embedding-3-large` produces 3072 dimensions by default.

## Understand how content gets into Redis

The AI RAG Injector Policy reads from the vector database at request time, and it doesn't write to it.
{{site.ai_gateway}} doesn't expose an endpoint for ingesting content, so you write chunks to Redis yourself.

The Policy retrieves your chunks only when the following values on the ingestion side match the Policy configuration:

<!-- vale off -->
{% table %}
columns:
  - title: Ingestion script
    key: script
  - title: Policy setting
    key: policy
rows:
  - script: The Redis host and port
    policy: "`vectordb.redis.host` and `vectordb.redis.port`"
  - script: "The index name `idx:vss_<NAMESPACE>` and the key prefix `<NAMESPACE>:`"
    policy: "`vectordb_namespace`"
  - script: The embedding model
    policy: "`embeddings.model`"
  - script: The vector size and distance metric
    policy: "`vectordb.dimensions` and `vectordb.distance_metric`"
{% endtable %}
<!-- vale on -->

The Policy creates the Redis index the first time it searches, and it indexes any chunks that are already in Redis under the namespace prefix.
If an existing index doesn't match the Policy configuration, for example because the dimensions differ, the Policy drops and recreates it.
The following ingestion script also creates the index, so the index is in place before the first request.

The script stores each chunk as a JSON document with the following fields:

* `payload.text`: The chunk text that the Policy injects into the prompt.
* `vector`: The embedding of the chunk.
* `metadata.collection`: The [collection](/ai-gateway/policies/ai-rag-injector/#collections) the chunk belongs to.
  The default collection is named `default`.

## Ingest content into Redis

Create a script that splits the document into chunks with `langchain_text_splitters`, generates an embedding for each chunk with OpenAI, and writes the chunks to Redis.
If your documents are structured data other than plain text, see the [LangChain text splitters documentation](https://python.langchain.com/docs/concepts/text_splitters/).

<!-- vale off -->
{% validation custom-command %}
command: |
  cat <<'EOF' > ingest_policy.py
  import os
  import uuid

  import redis
  import requests
  from langchain_text_splitters import RecursiveCharacterTextSplitter

  NAMESPACE = "compliance_policies"
  DIMENSIONS = 3072
  EMBEDDING_MODEL = "text-embedding-3-large"

  TEXT = """
  Acme Corp. Travel Policy
  1. Travel approval: All travel must be pre-approved by the employee's supervisor.
  2. Lodging: Travelers should share hotel rooms with other employees when feasible and appropriate. Book accommodations in advance to secure the best rates.
  3. Meals: Meals are reimbursable during business travel, but expenses should be kept reasonable. Alcoholic beverages are not reimbursable. Employees should present receipts for all meal expenses.
  4. Other expenses: Internet access is reimbursable when necessary for business travel. Entertainment expenses are generally not reimbursable.
  5. Reimbursement: Employees should submit all travel expenses for reimbursement within 27 days of the trip, with receipts.
  """

  splitter = RecursiveCharacterTextSplitter(chunk_size=300, chunk_overlap=50)
  chunks = splitter.split_text(TEXT)

  r = redis.Redis(host="localhost", port=6379)

  # Create the index that the AI RAG Injector Policy searches
  index = "idx:vss_" + NAMESPACE
  try:
      r.ft(index).info()
  except redis.exceptions.ResponseError:
      r.execute_command(
          "FT.CREATE", index, "ON", "JSON", "PREFIX", "1", NAMESPACE + ":",
          "SCORE", "1.0", "SCHEMA",
          "$.vector", "AS", "vector", "VECTOR", "FLAT", "6",
          "TYPE", "FLOAT32", "DIM", str(DIMENSIONS), "DISTANCE_METRIC", "COSINE",
          "$.metadata.source", "AS", "source", "TAG",
          "$.metadata.date", "AS", "date", "NUMERIC",
          "$.metadata.tags", "AS", "tags", "TAG", "SEPARATOR", "|",
          "$.metadata.collection", "AS", "collection", "TAG",
      )

  # Generate one embedding for each chunk
  response = requests.post(
      "https://api.openai.com/v1/embeddings",
      headers={"Authorization": "Bearer " + os.environ["OPENAI_API_KEY"]},
      json={"model": EMBEDDING_MODEL, "input": chunks},
  )
  response.raise_for_status()

  # Write each chunk to Redis
  for chunk, item in zip(chunks, response.json()["data"]):
      metadata = {"collection": "default"}
      r.json().set(
          NAMESPACE + ":" + str(uuid.uuid4()),
          "$",
          {
              "payload": {"text": chunk, "metadata": metadata},
              "vector": item["embedding"],
              "metadata": metadata,
          },
      )

  print("Ingested %d chunks" % len(chunks))
  EOF
expected:
  return_code: 0
render_output: false
{% endvalidation %}
<!-- vale on -->

Run the script to create the index and write the chunks to Redis:

{% validation custom-command %}
command: python3 ./ingest_policy.py
expected:
  return_code: 0
render_output: false
{% endvalidation %}

The script prints the number of chunks it wrote:

```text
Ingested 3 chunks
```
{:.no-copy-code}

To add content to the knowledge base later, run the script again with the new text.
The script keeps the existing index.
Running it again with text that you already ingested adds duplicate chunks, so ingest only new content.

## Validate

Send questions to the AI Model to confirm that the Policy injects the ingested content.

{% navtabs "rag-validation" %}
{% navtab "In-scope question" %}

An in-scope question is answered from the travel policy:

{% validation request-check %}
url: /chat/completions
method: POST
headers:
  - 'Content-Type: application/json'
body:
  model: rag-gpt-4o
  messages:
    - role: user
      content: Are alcoholic beverages reimbursable?
status_code: 200
{% endvalidation %}

The response states that alcoholic beverages aren't reimbursable.

{% endnavtab %}
{% navtab "Out-of-scope question" %}

An out-of-scope question returns the refusal from the inject template:

{% validation request-check %}
url: /chat/completions
method: POST
headers:
  - 'Content-Type: application/json'
body:
  model: rag-gpt-4o
  messages:
    - role: user
      content: Who is the CEO of OpenAI?
status_code: 200
{% endvalidation %}

The response contains the following message:

```json
"message": {
    "role": "assistant",
    "content": "I'm sorry, I cannot answer that based on the available compliance information."
}
```
{:.no-copy-code}

{% endnavtab %}
{% endnavtabs %}
