---
title: Filter knowledge base queries with the AI RAG Injector plugin
content_type: how_to
related_resources:
  - text: AI Gateway
    url: /ai-gateway/
  - text: AI RAG Injector
    url: /plugins/ai-rag-injector/
  - text: AI Proxy Advanced
    url: /plugins/ai-proxy-advanced/

description: Learn how to use metadata filtering to refine search results within knowledge base collections.

products:
  - gateway
  - ai-gateway

works_on:
  - on-prem
  - konnect

min_version:
  gateway: '3.13'

plugins:
  - ai-proxy-advanced
  - ai-rag-injector

entities:
  - service
  - route
  - plugin

tags:
  - ai
  - openai

tldr:
  q: How do I refine search results to only include specific types of content from my knowledge base?
  a: Use metadata filters in your query requests to narrow results by tags, dates, sources, or other metadata fields. Filters apply within authorized collections and support exact matches, comparisons, and array operations.

tools:
  - deck

prereqs:
  inline:
    - title: OpenAI
      include_content: prereqs/openai
      icon_url: /assets/icons/openai.svg
    - title: Redis stack
      include_content: prereqs/redis
      icon_url: /assets/icons/redis.svg
  entities:
    services:
        - example-service
    routes:
        - example-route

cleanup:
  inline:
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg

search_aliases:
  - ai-semantic-cache
  - ai
  - llm
  - rag
  - intelligence
  - language
  - model

automated_tests: false
---

## Configure the AI Proxy Advanced plugin

Configure the AI Proxy Advanced plugin to proxy prompt requests to your model provider:

{% entity_examples %}
entities:
  plugins:
    - name: ai-proxy-advanced
      config:
        targets:
          - route_type: llm/v1/chat
            auth:
              header_name: Authorization
              header_value: Bearer ${openai_api_key}
            model:
              provider: openai
              name: gpt-4o
              options:
                max_tokens: 512
                temperature: 1.0
variables:
  openai_api_key:
    value: $OPENAI_API_KEY
{% endentity_examples %}

## Configure the AI RAG Injector plugin

Configure the AI RAG Injector plugin with a vector database for storing and retrieving knowledge base content:

{% entity_examples %}
entities:
  plugins:
  - name: ai-rag-injector
    id: b924e3e8-7893-4706-aacb-e75793a1d2e9
    config:
      embeddings:
        auth:
          header_name: Authorization
          header_value: Bearer ${openai_api_key}
        model:
          provider: openai
          name: text-embedding-3-large
      vectordb:
        strategy: redis
        dimensions: 3072
        distance_metric: cosine
        redis:
          host: ${redis_host}
          port: 6379
      inject_template: |
        Use the following context to answer the question. If the context doesnt contain relevant information, say so.
        Context:
        <CONTEXT>
        Question: <PROMPT>
      inject_as_role: system
variables:
  openai_api_key:
    value: $OPENAI_API_KEY
  redis_host:
    value: $REDIS_HOST
{% endentity_examples %}

{:.info}
> If your Redis instance runs in a separate Docker container from Kong, use `host.docker.internal` for `vectordb.redis.host`.

## Ingest content with metadata

Ingest financial documents with metadata. Each chunk includes tags, dates, and sources that you can filter on. Use the Admin API to send ingestion requests with the metadata fields you'll use for filtering later.

### Current quarterly reports

<!--vale off-->
{% control_plane_request %}
url: /ai-rag-injector/b924e3e8-7893-4706-aacb-e75793a1d2e9/ingest_chunk
status_code: 201
headers:
    - 'Content-Type: application/json'
body:
    content: "Q4 2024 Financial Results: Revenue increased 15% year-over-year to $2.3B. Operating margin improved to 24%, up from 21% in Q3. Key drivers included strong enterprise sales and improved operational efficiency."
    metadata:
      collection: finance-reports
      source: internal
      date: "2024-10-14T00:00:00Z"
      report_type: quarterly
      tags:
        - finance
        - quarterly
        - q4
        - "2024"
        - current
{% endcontrol_plane_request %}
<!--vale on-->

<!--vale off-->
{% control_plane_request %}
url: /ai-rag-injector/b924e3e8-7893-4706-aacb-e75793a1d2e9/ingest_chunk
status_code: 201
headers:
    - 'Content-Type: application/json'
body:
    content: "Q3 2024 Financial Results: Revenue reached $2.0B with 12% year-over-year growth. Operating margin held steady at 21%. International markets contributed 35% of total revenue."
    metadata:
      collection: finance-reports
      source: internal
      date: "2024-07-15T00:00:00Z"
      report_type: quarterly
      tags:
        - finance
        - quarterly
        - q3
        - "2024"
        - current
{% endcontrol_plane_request %}
<!--vale on-->

### Annual reports

<!--vale off-->
{% control_plane_request %}
url: /ai-rag-injector/b924e3e8-7893-4706-aacb-e75793a1d2e9/ingest_chunk
status_code: 201
headers:
    - 'Content-Type: application/json'
body:
    content: "2024 Annual Report: Full-year revenue totaled $8.7B, representing 20% growth. The company expanded into five new markets and launched seven major product updates. Board approved $600M share buyback program."
    metadata:
      collection: finance-reports
      source: internal
      date: "2024-12-31T00:00:00Z"
      report_type: annual
      tags:
        - finance
        - annual
        - "2024"
        - current
{% endcontrol_plane_request %}
<!--vale on-->

<!--vale off-->
{% control_plane_request %}
url: /ai-rag-injector/b924e3e8-7893-4706-aacb-e75793a1d2e9/ingest_chunk
status_code: 201
headers:
    - 'Content-Type: application/json'
body:
    content: "2023 Annual Report: Full-year revenue totaled $7.8B, representing 18% growth. The company expanded into three new markets and launched five major product updates. Board approved $500M share buyback program."
    metadata:
      collection: finance-reports
      source: internal
      date: "2023-12-31T00:00:00Z"
      report_type: annual
      tags:
        - finance
        - annual
        - "2023"
{% endcontrol_plane_request %}
<!--vale on-->

### External analyst reports

<!--vale off-->
{% control_plane_request %}
url: /ai-rag-injector/b924e3e8-7893-4706-aacb-e75793a1d2e9/ingest_chunk
status_code: 201
headers:
    - 'Content-Type: application/json'
body:
    content: "Morgan Stanley Analyst Report (Oct 2024): Maintains 'Overweight' rating with $145 price target. Cites strong execution, market expansion, and operating leverage as key positives. Recommends Buy."
    metadata:
      collection: finance-reports
      source: external
      date: "2024-10-20T00:00:00Z"
      report_type: analyst
      tags:
        - analyst
        - external
        - "2024"
        - recommendation
{% endcontrol_plane_request %}
<!--vale on-->

<!--vale off-->
{% control_plane_request %}
url: /ai-rag-injector/b924e3e8-7893-4706-aacb-e75793a1d2e9/ingest_chunk
status_code: 201
headers:
    - 'Content-Type: application/json'
body:
    content: "Goldman Sachs Sector Analysis (Sep 2024): Software sector shows resilient growth despite macro headwinds. Enterprise software spending expected to grow 12-15% in 2025. Cloud migration remains primary driver."
    metadata:
      collection: finance-reports
      source: external
      date: "2024-09-15T00:00:00Z"
      report_type: analyst
      tags:
        - analyst
        - external
        - sector
        - "2024"
{% endcontrol_plane_request %}
<!--vale on-->

### Historical archive data

<!--vale off-->
{% control_plane_request %}
url: /ai-rag-injector/b924e3e8-7893-4706-aacb-e75793a1d2e9/ingest_chunk
status_code: 201
headers:
    - 'Content-Type: application/json'
body:
    content: "Historical Data Archive: Q2 2022 revenue was $1.5B with 8% growth. This data is retained for historical analysis but may not reflect current business conditions or reporting standards."
    metadata:
      collection: finance-reports
      source: archive
      date: "2022-06-15T00:00:00Z"
      report_type: quarterly
      tags:
        - finance
        - quarterly
        - q2
        - "2022"
        - archive
{% endcontrol_plane_request %}
<!--vale on-->

## Validate metadata filtering

Send queries with different filter combinations to demonstrate how metadata filtering refines results.

### Filter by date range

Query for recent reports (2024 only). This filter excludes older historical data and the results should include Q3 2024, Q4 2024, and 2024 annual report data, but exclude 2022 and 2023 data.

{% validation request-check %}
url: /anything
headers:
  - 'Content-Type: application/json'
body:
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
message: |
  The context provides financial results for Q3 and Q4 2024, as well as the annual results for 2024:\n\n- **Q3 2024:** Revenue was $2.0 billion with 12% year-over-year growth. Operating margin was 21%. International markets contributed 35% of total revenue.\n\n- **Q4 2024:** Revenue increased 15% year-over-year to $2.3 billion. Operating margin improved to 24%. Key drivers were strong enterprise sales and improved operational efficiency.\n\n- **2024 Annual Report:** Full-year revenue totaled $8.7 billion, representing 20% growth. The company expanded into five new markets and launched seven major product updates. The board approved a $600 million share buyback program.
{% endvalidation %}

### Filter by source

Query for internal reports only, excluding external analyst reports. The results should include internal quarterly and annual reports, but exclude analyst reports from Morgan Stanley and Goldman Sachs

{% validation request-check %}
url: /anything
headers:
  - 'Content-Type: application/json'
body:
  messages:
    - role: user
      content: Summarize our financial performance
  ai-rag-injector:
    filters:
      equals:
        key: source
        value: internal
status_code: 200
message: |
  Based on the provided context, our financial performance shows solid growth across the board. In Q4 2024, revenue increased by 15% year-over-year to $2.3 billion, with an improved operating margin of 24%. The key drivers for this performance included strong enterprise sales and improved operational efficiency. For the full year of 2024, revenue totaled $8.7 billion, indicating a 20% growth. The company expanded into five new markets and launched seven major product updates. Additionally, the board approved a $600 million share buyback program.\n\nCompared to 2023, where the full-year revenue was $7.8 billion with 18% growth, the company showed continued strong performance and strategic expansion efforts in 2024.
{% endvalidation %}

### Filter by report type

Query for quarterly reports only. The results should include Q3 and Q4 2024 quarterly reports, but exclude annual reports and analyst reports.

{% validation request-check %}
url: /anything
headers:
  - 'Content-Type: application/json'
body:
  messages:
    - role: user
      content: Show quarterly performance trends
  ai-rag-injector:
    filters:
      equals:
        key: report_type
        value: quarterly
status_code: 200
message: |
  The provided context contains data on quarterly and annual financial performance for the years 2023 and 2024, but it does not provide a detailed breakdown of quarterly performance trends for 2023. However, it does give insights into the quarterly performance of 2024:\n\n1. **Q3 2024:**\n   - Revenue: $2.0B\n   - Year-over-year growth: 12%\n   - Operating margin: 21%\n   - International markets contributed 35% of total revenue.\n\n2. **Q4 2024:**\n   - Revenue: $2.3B\n   - Year-over-year growth: 15%\n   - Operating margin improved to 24% (up from 21% in Q3).\n\nThe trends observed indicate a growth in revenue and operating margin in Q4 2024 compared to Q3 2024. There's a notable increase in both revenue and operating efficiency, primarily driven by strong enterprise sales and improved operational efficiency. For a comprehensive quarterly trend analysis, more data points from other quarters would be necessary, which are not provided in the current context.
{% endvalidation %}

### Filter by tags

Query for current (non-archived) data only using tag filtering. The results should include 2024 quarterly reports and annual report, but exclude 2022 archived data:

{% validation request-check %}
url: /anything
headers:
  - 'Content-Type: application/json'
body:
  messages:
    - role: user
      content: What are the latest financial metrics?
  ai-rag-injector:
    filters:
      in:
        key: tags
        value:
          - current
status_code: 200
message: |
  The latest financial metrics provided in the context are from Q4 2024, where the revenue increased by 15% year-over-year to reach $2.3 billion. The operating margin improved to 24%. For the full year of 2024, the revenue totaled $8.7 billion, representing a 20% growth."
{% endvalidation %}

### Combine multiple filters

Query for internal quarterly reports from 2024. The results should include only Q3 and Q4 2024 internal quarterly reports. Annual reports, analyst reports, and 2022/2023 data should be excluded in the response:

{% validation request-check %}
url: /anything
headers:
  - 'Content-Type: application/json'
body:
  messages:
    - role: user
      content: Compare our quarterly results this year
  ai-rag-injector:
    filters:
      andAll:
        - equals:
            key: source
            value: internal
        - equals:
            key: report_type
            value: quarterly
        - greaterThanOrEquals:
            key: date
            value: "2024-01-01"
status_code: 200
message: |
  The latest financial metrics are from Q4 2024, where the revenue increased by 15% year-over-year to $2.3 billion, and the operating margin improved to 24% from 21% in Q3 2024. Additionally, the full-year revenue for 2024 totaled $8.7 billion, representing a 20% growth. The company expanded into five new markets and launched seven major product updates. The board also approved a $600 million share buyback program.
{% endvalidation %}

### Filter for external analyst perspectives

Query for external analyst reports only. The results should include only Morgan Stanley and Goldman Sachs analyst reports, excluding all internal company reports:

{% validation request-check %}
url: /anything
headers:
  - 'Content-Type: application/json'
body:
  messages:
    - role: user
      content: What do analysts say about our company?
  ai-rag-injector:
    filters:
      andAll:
        - equals:
            key: source
            value: external
        - in:
            key: tags
            value:
              - analyst
              - recommendation
status_code: 200
message: |
  The context provided does not contain information specific to your company. It includes a Morgan Stanley report maintaining an Overweight rating with a $145 price target for an unnamed company and a Goldman Sachs analysis of the software sector.
{% endvalidation %}

## Validate filter modes

The AI RAG Injector plugin supports two filter modes that control how chunks with no metadata are handled.

### Compatible mode

Use `filter_mode: compatible` to include chunks that match the filter OR have no metadata. This mode is useful when your knowledge base contains both tagged and untagged content:

{% validation request-check %}
url: /anything
headers:
  - 'Content-Type: application/json'
body:
  messages:
    - role: user
      content: Show me quarterly reports
  ai-rag-injector:
    filters:
      equals:
        key: report_type
        value: quarterly
    filter_mode: compatible
status_code: 200
message: |
  The context provided does not contain specific quarterly reports, but it does include some quarterly financial results and key performance highlights:\n\n- Q2 2022: Revenue was $1.5 billion with 8% growth.\n- Q3 2024: Revenue was $2.0 billion with 12% year-over-year growth. The operating margin was steady at 21%, and international markets contributed 35% of total revenue.\n- Q4 2024: Revenue increased 15% year-over-year to $2.3 billion. The operating margin improved to 24%.\n\nIf you need detailed quarterly reports beyond what is summarized here, please check the company's official filings or financial statements.
{% endvalidation %}

### Strict mode

Use `filter_mode: strict` to include only chunks that match the filter. This mode excludes chunks with no metadata:

{% validation request-check %}
url: /anything
headers:
  - 'Content-Type: application/json'
body:
  messages:
    - role: user
      content: Show me quarterly reports
  ai-rag-injector:
    filters:
      andAll:
        - in:
            key: tags
            value:
              - quarterly
    filter_mode: strict
status_code: 200
message: |
  The context provided includes quarterly financial data for two specific quarters:\n\n1. **Q3 2024 Financial Results**:\n   - Revenue: $2.0 billion\n   - Year-over-year growth: 12%\n   - Operating margin: 21%\n   - Contribution of international markets to total revenue: 35%\n\n2. **Q4 2024 Financial Results**:\n   - Revenue: $2.3 billion\n   - Year-over-year growth: 15%\n   - Operating margin: 24%\n   - Key growth drivers: Strong enterprise sales and improved operational efficiency\n\nThere is also a historical data point mentioned for Q2 2022, with revenue of $1.5 billion and 8% growth. However, this may not reflect current business conditions or standards. \n\nIf you have a specific question about these reports or require more detailed information, please feel free to ask!
{% endvalidation %}

## Validate error handling

Control how the plugin handles filter parsing errors with the `stop_on_filter_error` parameter.

### Continue on error

When `stop_on_filter_error` is `false` (default), the plugin logs filter errors and continues without filters:

{% validation request-check %}
url: /anything
headers:
  - 'Content-Type: application/json'
body:
  messages:
    - role: user
      content: Show me reports
  ai-rag-injector:
    filters:
      invalidOperator:
        key: report_type
        value: quarterly
    stop_on_filter_error: false
status_code: 200
message: The query succeeds but returns unfiltered results. The plugin logs the filter parsing error.
{% endvalidation %}

### Fail on error

When `stop_on_filter_error` is `true`, the plugin returns an error if filter parsing fails:

{% validation request-check %}
url: /anything
headers:
  - 'Content-Type: application/json'
body:
  messages:
    - role: user
      content: Show me reports
  ai-rag-injector:
    filters:
      invalidOperator:
        key: report_type
        value: quarterly
    stop_on_filter_error: true
status_code: 400
message: |
  Invalid metadata filter: filter must contain 'andAll' wrapper
{% endvalidation %}
