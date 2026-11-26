---
title: Filter knowledge base queries with the AI RAG Injector Policy
permalink: /ai-gateway/filter-knowledge-based-queries-with-rag-injector/
content_type: how_to
related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/
  - text: AI RAG Injector
    url: /ai-gateway/policies/ai-rag-injector/
  - text: Ensure chatbots adhere to compliance policies with the AI RAG Injector Policy
    url: /ai-gateway/use-ai-rag-injector-policy/
  - text: AI Model entity reference
    url: /ai-gateway/entities/ai-model/
  - text: AI Policy entity reference
    url: /ai-gateway/entities/ai-policy/

description: Use metadata filters to refine the results that the AI RAG Injector Policy retrieves from a knowledge base.

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
  q: How do I refine search results to only include specific types of content from my knowledge base?
  a: |
    Write each chunk to Redis with the `source`, `tags`, `date`, and `collection` metadata fields.
    Then add an `ai-rag-injector.filters` object to the request body to narrow the retrieved chunks by source, tag, or date.
    Wrap every filter in `andAll`.

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

search_aliases:
  - ai
  - llm
  - rag
  - metadata filtering
  - knowledge base

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
  - ref: finance-rag
    name: finance-rag
    display_name: finance-rag
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    type: ai-rag-injector
    enabled: true
    global: false
    config:
      vectordb_namespace: finance_reports
      inject_template: |
        Use the following context to answer the question. If the context doesn't contain relevant information, say so.
        Context:
        <CONTEXT>
        Question: <PROMPT>
      inject_as_role: system
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
  - ref: finance-gpt-4o
    display_name: finance-gpt-4o
    name: finance-gpt-4o
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
            - finance-gpt-4o
    capabilities: [generate]
    policies: [ !ref finance-rag#name ]
    targets:
      - name: gpt-4o
        provider: generic-openai
        config:
          type: openai
{% endentity_examples %}

The Policy reads chunks from the Redis keys that start with `finance_reports:`, which come from the `vectordb_namespace` setting.

## Write chunks with metadata to Redis

{{site.ai_gateway}} doesn't expose an endpoint for ingesting content, so you write chunks to Redis with a script.
To filter on metadata, each chunk needs the following fields:

<!-- vale off -->
{% table %}
columns:
  - title: Field
    key: field
  - title: Type
    key: type
  - title: Description
    key: description
rows:
  - field: "`collection`"
    type: String
    description: The [collection](/ai-gateway/policies/ai-rag-injector/#collections) the chunk belongs to.
  - field: "`source`"
    type: String
    description: Where the content comes from, for example `internal` or `external`.
  - field: "`tags`"
    type: Array of strings
    description: Labels that you can match with the `in` operator.
  - field: "`date`"
    type: Unix timestamp
    description: The date of the content. The script stores the date as a number so that you can use comparison operators.
{% endtable %}
<!-- vale on -->

The script stores each chunk as a JSON document in Redis.
The Policy injects `payload.text` into the prompt, and it filters on the top-level `metadata` object.

Create the script:

<!-- vale off -->
{% validation custom-command %}
command: |
  cat <<'EOF' > ingest_filtering.py
  import os
  import uuid
  from datetime import datetime, timezone

  import redis
  import requests

  NAMESPACE = "finance_reports"
  EMBEDDING_MODEL = "text-embedding-3-large"

  CHUNKS = [
      {
          "text": "Q4 2024 Financial Results: Revenue increased 15% year-over-year to $2.3B. Operating margin improved to 24%, up from 21% in Q3. Key drivers included strong enterprise sales and improved operational efficiency.",
          "source": "internal",
          "date": "2024-10-14",
          "tags": ["finance", "quarterly", "2024", "current"],
      },
      {
          "text": "Q3 2024 Financial Results: Revenue reached $2.0B with 12% year-over-year growth. Operating margin held steady at 21%. International markets contributed 35% of total revenue.",
          "source": "internal",
          "date": "2024-07-15",
          "tags": ["finance", "quarterly", "2024", "current"],
      },
      {
          "text": "2024 Annual Report: Full-year revenue totaled $8.7B, representing 20% growth. The company expanded into five new markets and launched seven major product updates. The board approved a $600M share buyback program.",
          "source": "internal",
          "date": "2024-12-31",
          "tags": ["finance", "annual", "2024", "current"],
      },
      {
          "text": "2023 Annual Report: Full-year revenue totaled $7.8B, representing 18% growth. The company expanded into three new markets and launched five major product updates. The board approved a $500M share buyback program.",
          "source": "internal",
          "date": "2023-12-31",
          "tags": ["finance", "annual", "2023"],
      },
      {
          "text": "Morgan Stanley Analyst Report (Oct 2024): Maintains an Overweight rating with a $145 price target. Cites strong execution, market expansion, and operating leverage as key positives.",
          "source": "external",
          "date": "2024-10-20",
          "tags": ["analyst", "2024", "recommendation"],
      },
      {
          "text": "Goldman Sachs Sector Analysis (Sep 2024): The software sector shows resilient growth despite macro headwinds. Enterprise software spending is expected to grow 12-15% in 2025. Cloud migration remains the primary driver.",
          "source": "external",
          "date": "2024-09-15",
          "tags": ["analyst", "2024", "sector"],
      },
      {
          "text": "Historical Data Archive: Q2 2022 revenue was $1.5B with 8% growth. This data is retained for historical analysis but may not reflect current business conditions or reporting standards.",
          "source": "archive",
          "date": "2022-06-15",
          "tags": ["finance", "quarterly", "2022", "archive"],
      },
  ]

  # Generate one embedding for each chunk
  response = requests.post(
      "https://api.openai.com/v1/embeddings",
      headers={"Authorization": "Bearer " + os.environ["OPENAI_API_KEY"]},
      json={"model": EMBEDDING_MODEL, "input": [c["text"] for c in CHUNKS]},
  )
  response.raise_for_status()

  r = redis.Redis(host="localhost", port=6379)

  # Write each chunk to Redis
  for chunk, item in zip(CHUNKS, response.json()["data"]):
      timestamp = int(datetime.strptime(chunk["date"], "%Y-%m-%d").replace(tzinfo=timezone.utc).timestamp())
      r.json().set(
          NAMESPACE + ":" + str(uuid.uuid4()),
          "$",
          {
              "payload": {
                  "text": chunk["text"],
                  "metadata": {
                      "collection": "default",
                      "source": chunk["source"],
                      "tags": chunk["tags"],
                      "date": chunk["date"],
                  },
              },
              "vector": item["embedding"],
              "metadata": {
                  "collection": "default",
                  "source": chunk["source"],
                  "tags": chunk["tags"],
                  "date": timestamp,
              },
          },
      )

  print("Ingested %d chunks" % len(CHUNKS))
  EOF
expected:
  return_code: 0
render_output: false
{% endvalidation %}
<!-- vale on -->

```text
Chunk                              Source    Date        Tags
Q4 2024 Financial Results          internal  2024-10-14  finance, quarterly, 2024, current
Q3 2024 Financial Results          internal  2024-07-15  finance, quarterly, 2024, current
2024 Annual Report                 internal  2024-12-31  finance, annual, 2024, current
2023 Annual Report                 internal  2023-12-31  finance, annual, 2023
Morgan Stanley Analyst Report      external  2024-10-20  analyst, 2024, recommendation
Goldman Sachs Sector Analysis      external  2024-09-15  analyst, 2024, sector
Historical Data Archive            archive   2022-06-15  finance, quarterly, 2022, archive
```
{:.collapsible .no-copy-code}

Run the script:

{% validation custom-command %}
command: python3 ./ingest_filtering.py
expected:
  return_code: 0
render_output: false
{% endvalidation %}

The script prints the number of chunks it wrote:

```text
Ingested 7 chunks
```
{:.no-copy-code}

## Filter by metadata

Add an `ai-rag-injector` object with a `filters` key to the request body.
The Policy applies the filters within the collections that the consumer can access.
Every filter must use the `andAll` wrapper, even when it has a single clause.

The following operators are available: `equals`, `greaterThan`, `greaterThanOrEquals`, `lessThan`, `lessThanOrEquals`, and `in`.
You can filter on the `source`, `tags`, `date`, and `collection` fields.

### Filter by a single field

Use one clause to filter on a date, a source, or a tag:

{% navtabs "single-filter" %}
{% navtab "Date" %}

This request retrieves chunks dated on or after January 1, 2024.
The retrieved chunks cover the 2024 quarterly and annual reports and the analyst reports, and they leave out the 2022 and 2023 content.

<!--vale off-->
{% validation request-check %}
url: /chat/completions
method: POST
headers:
  - 'Content-Type: application/json'
body:
  model: finance-gpt-4o
  messages:
    - role: user
      content: What were our financial results?
  ai-rag-injector:
    filters:
      andAll:
        - greaterThanOrEquals:
            key: date
            value: "2024-01-01"
status_code: 200
{% endvalidation %}
<!--vale on-->

The response looks like the following:

```text
The financial results mentioned in the context include:

- Q3 2024: Revenue of $2.0 billion with 12% year-over-year growth, and an operating margin of 21%.
- Q4 2024: Revenue of $2.3 billion, reflecting a 15% year-over-year increase, and an improved operating margin of 24%.
- Full-year 2024: Revenue of $8.7 billion, representing 20% growth.

Additionally, the company expanded into five new markets, launched seven major product updates, and approved a $600 million share buyback program.
```
{:.no-copy-code}

{% endnavtab %}
{% navtab "Source" %}

This request retrieves chunks from internal sources only, which excludes the external analyst reports and the archive.

<!--vale off-->
{% validation request-check %}
url: /chat/completions
method: POST
headers:
  - 'Content-Type: application/json'
body:
  model: finance-gpt-4o
  messages:
    - role: user
      content: Summarize our financial performance
  ai-rag-injector:
    filters:
      andAll:
        - equals:
            key: source
            value: internal
status_code: 200
{% endvalidation %}
<!--vale on-->

The response looks like the following:

```text
The financial performance for the full year of 2024 showed strong growth, with revenue totaling $8.7 billion, representing a 20% increase. During Q4 2024, revenue increased by 15% year-over-year to $2.3 billion, and the operating margin improved to 24%, up from 21% in Q3. Key factors contributing to these results were strong enterprise sales and improved operational efficiency. Throughout the year, the company expanded into five new markets and introduced seven major product updates. Additionally, the board approved a $600 million share buyback program.
```
{:.no-copy-code}

{% endnavtab %}
{% navtab "Tag" %}

The `in` operator matches chunks that have at least one of the listed tags.
This request retrieves the quarterly reports.

<!--vale off-->
{% validation request-check %}
url: /chat/completions
method: POST
headers:
  - 'Content-Type: application/json'
body:
  model: finance-gpt-4o
  messages:
    - role: user
      content: Show quarterly performance trends
  ai-rag-injector:
    filters:
      andAll:
        - in:
            key: tags
            value:
              - quarterly
status_code: 200
{% endvalidation %}
<!--vale on-->

The response looks like the following:

```text
The context provided gives specific quarterly financial performance data for Q3 2024 and Q4 2024, as well as a historical reference for Q2 2022.

For Q3 2024:
- Revenue was $2.0B.
- 12% year-over-year growth.
- Operating margin was 21%.
- International markets accounted for 35% of total revenue.

For Q4 2024:
- Revenue increased to $2.3B.
- 15% year-over-year growth.
- Operating margin improved to 24%.
- Growth was driven by strong enterprise sales and improved operational efficiency.

In terms of quarterly trends from Q3 to Q4 2024:
- There was a significant revenue increase from $2.0B to $2.3B.
- Year-over-year growth accelerated from 12% in Q3 to 15% in Q4.
- Operating margin improved from 21% to 24%, indicating enhanced profitability and efficiency.

This indicates a positive growth trajectory and improved financial health between these quarters.
```
{:.no-copy-code}

{% endnavtab %}
{% endnavtabs %}

### Combine multiple filters

A chunk must match every clause in `andAll`.
This request retrieves internal chunks that are tagged `quarterly` and dated in 2024, which leaves only the Q3 and Q4 2024 reports.

<!--vale off-->
{% validation request-check %}
url: /chat/completions
method: POST
headers:
  - 'Content-Type: application/json'
body:
  model: finance-gpt-4o
  messages:
    - role: user
      content: Compare our quarterly results for 2024
  ai-rag-injector:
    filters:
      andAll:
        - equals:
            key: source
            value: internal
        - in:
            key: tags
            value:
              - quarterly
        - greaterThanOrEquals:
            key: date
            value: "2024-01-01"
status_code: 200
{% endvalidation %}
<!--vale on-->

The response looks like the following:

```text
The context does not provide detailed information on all quarterly results for 2024, so a full comparison across all quarters cannot be made. However, based on the available information for Q3 and Q4 2024:

- **Revenue**: 
  - Q3 2024: Revenue was $2.0 billion, showing a 12% year-over-year growth.
  - Q4 2024: Revenue increased to $2.3 billion, with a 15% year-over-year growth.

- **Operating Margin**:
  - Q3 2024: The operating margin was 21%.
  - Q4 2024: The operating margin improved to 24%.

Thus, from Q3 to Q4 2024, there was an increase in both revenue and operating margin, indicating improved financial performance in Q4.
```
{:.no-copy-code}

## Control how the Policy handles invalid filters

The `filter_mode` and `stop_on_filter_error` settings control what happens when a filter can't be parsed, for example because it uses an unknown field or has no `andAll` wrapper.
Set them in the Policy configuration, or override them for a single request in the `ai-rag-injector` object.

* `compatible`: The Policy ignores the invalid filter and retrieves chunks without filtering.
  This is the default.
* `strict`: The Policy rejects the request.

This request sets `filter_mode` to `strict` and sends a filter without the `andAll` wrapper:

<!--vale off-->
{% validation request-check %}
url: /chat/completions
method: POST
headers:
  - 'Content-Type: application/json'
body:
  model: finance-gpt-4o
  messages:
    - role: user
      content: Show me reports
  ai-rag-injector:
    filters:
      equals:
        key: source
        value: internal
    filter_mode: strict
status_code: 400
{% endvalidation %}
<!--vale on-->

The Policy rejects the request with the following error:

```json
{
  "message": "Invalid metadata filter: filter must contain 'andAll' wrapper"
}
```
{:.no-copy-code}

Setting `stop_on_filter_error` to `true` has the same effect in `compatible` mode.
