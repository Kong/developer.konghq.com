---
title: Control access to knowledge base collections with the AI RAG Injector plugin
permalink: /how-to/use-ai-rag-injector-acls/
content_type: how_to
related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/
  - text: AI RAG Injector
    url: /plugins/ai-rag-injector/
  - text: AI Proxy Advanced
    url: /plugins/ai-proxy-advanced/

description: Learn how to configure access control and metadata filtering for the AI RAG Injector plugin.

products:
  - ai-gateway
  - gateway

works_on:
  - on-prem
  - konnect

min_version:
  gateway: '3.13'

plugins:
  - ai-proxy-advanced
  - ai-rag-injector
  - key-auth

entities:
  - service
  - route
  - plugin
  - consumer
  - consumer_group

tags:
  - ai
  - openai
  - security

tldr:
  q: How do I restrict access to specific knowledge base collections based on user groups?
  a: Use the AI RAG Injector plugin’s ACL settings to limit which Consumer Groups can access each knowledge-base collection. Set collection-level rules and, if needed, add metadata filters to further restrict what authorized users can see.

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
    - title: Flush Redis database
      include_content: cleanup/third-party/redis
      icon_url: /assets/icons/redis.svg
    - title: Python
      include_content: prereqs/python
      icon_url: /assets/icons/python.svg

search_aliases:
  - ai-semantic-cache
  - ai
  - llm
  - rag
  - intelligence
  - language
  - model
  - acl

automated_tests: false
---
## Configure the AI Proxy Advanced plugin

First, you'll need to configure the AI Proxy Advanced plugin to proxy prompt requests to your model provider, and handle authentication:

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


## Enable key authentication

Next, let's configure authentication so {{site.base_gateway}} can identify each consumer. Use the [Key Auth](/plugins/key-auth/) plugin so each user presents an API key with requests:

{% entity_examples %}
entities:
  plugins:
    - name: key-auth
      config:
        key_names:
          - apikey
        key_in_header: true
        key_in_query: true
        hide_credentials: true
{% endentity_examples %}

## Create Consumer Groups for knowledge base access levels

Configure Consumer Groups that reflect organizational roles. These groups govern access to knowledge base collections:
- `public` - access to public investor relations content
- `finance` - access to financial reports
- `executive` - access to all financial data including confidential information
- `contractor` - external users with restricted access

{% entity_examples %}
entities:
  consumer_groups:
    - name: public
    - name: finance
    - name: executive
    - name: contractor
{% endentity_examples %}

## Create Consumers

Now we can configure individual Consumers and assign them to groups. Each Consumer uses a unique API key and inherits group permissions that govern access to knowledge base collections:

{% entity_examples %}
entities:
  consumers:
    - username: cfo
      custom_id: cfo-001
      groups:
        - name: finance
        - name: executive
      keyauth_credentials:
        - key: cfo-key
    - username: financial-analyst
      custom_id: analyst-001
      groups:
        - name: finance
      keyauth_credentials:
        - key: analyst-key
    - username: contractor-dev
      custom_id: contractor-001
      groups:
        - name: contractor
      keyauth_credentials:
        - key: contractor-key
    - username: public-user
      custom_id: public-001
      groups:
        - name: public
      keyauth_credentials:
        - key: public-key
{% endentity_examples %}

## Configure the AI RAG Injector plugin

Configure the AI RAG Injector plugin to apply access rules at the collection level. The plugin controls which users can access specific knowledge base collections. Access is then determined by Consumer Groups using allow and deny lists. A collection ACL replaces the global rule when present.

The table below shows the effective permissions for the configuration:

<!-- vale off -->
{% table %}
columns:
  - title: Collection
    key: collection
  - title: Executive group
    key: executive
  - title: Finance group
    key: finance
  - title: Public group
    key: public
  - title: Contractor group
    key: contractor

rows:
  - collection: "`public-docs`"
    public: Yes
    finance: Yes
    executive: Yes
    contractor: Yes
  - collection: "`finance-reports`"
    public: No
    finance: Yes
    executive: Yes
    contractor: No
  - collection: "`executive-confidential`"
    public: No
    finance: No
    executive: Yes
    contractor: No
{% endtable %}
<!-- vale on -->

The following plugin configuration applies the ACL rules for the collections shown in the table above:

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
      consumer_identifier: consumer_group
      global_acl_config:
        allow:
          - public
        deny: []
      collection_acl_config:
        public-docs:
          allow: []
          deny: []
        finance-reports:
          allow:
            - finance
            - executive
          deny:
            - contractor
        executive-confidential:
          allow:
            - executive
variables:
  openai_api_key:
    value: $OPENAI_API_KEY
  redis_host:
    value: $REDIS_HOST
{% endentity_examples %}

{:.info}
> If your Redis instance runs in a separate Docker container from Kong, use `host.docker.internal` for `vectordb.redis.host`.

## Ingest content with metadata

Ingest content into different collections with metadata tags. Each chunk specifies its collection, source, date, and tags. Use the Admin API to send ingestion requests with the metadata fields you'll use for filtering later.

### Create ingestion script

Create a Python script to ingest multiple chunks:
```bash
cat > ingest-collection.py << 'EOF'
#!/usr/bin/env python3
import requests
import json

BASE_URL = "http://localhost:8001/ai-rag-injector/b924e3e8-7893-4706-aacb-e75793a1d2e9/ingest_chunk"

chunks = [
    {
        "content": "Public Investor FAQ: Our fiscal year ends December 31st. Quarterly earnings calls occur in January, April, July, and October. All public filings are available on our investor relations website. For questions, contact investor.relations@company.com.",
        "metadata": {
            "collection": "public-docs",
            "source": "website",
            "date": "2024-01-15T00:00:00Z",
            "tags": ["public", "investor-relations", "faq"]
        }
    },
    {
        "content": "Q4 2024 Financial Results: Revenue increased 15% year-over-year to $2.3B. Operating margin improved to 24%, up from 21% in Q3. Key drivers included strong enterprise sales and improved operational efficiency.",
        "metadata": {
            "collection": "finance-reports",
            "source": "internal",
            "date": "2024-10-14T00:00:00Z",
            "tags": ["finance", "quarterly", "q4", "2024"]
        }
    },
    {
        "content": "Q3 2024 Financial Results: Revenue reached $2.0B with 12% year-over-year growth. Operating margin held steady at 21%. International markets contributed 35% of total revenue.",
        "metadata": {
            "collection": "finance-reports",
            "source": "internal",
            "date": "2024-07-15T00:00:00Z",
            "tags": ["finance", "quarterly", "q3", "2024"]
        }
    },
    {
        "content": "2023 Annual Report: Full-year revenue totaled $7.8B, representing 18% growth. The company expanded into three new markets and launched five major product updates. Board approved $500M share buyback program.",
        "metadata": {
            "collection": "finance-reports",
            "source": "internal",
            "date": "2023-12-31T00:00:00Z",
            "tags": ["finance", "annual", "2023"]
        }
    },
    {
        "content": "Historical Data Archive: Q2 2022 revenue was $1.5B with 8% growth. This data is retained for historical analysis but may not reflect current business conditions or reporting standards.",
        "metadata": {
            "collection": "finance-reports",
            "source": "archive",
            "date": "2022-06-15T00:00:00Z",
            "tags": ["finance", "quarterly", "q2", "2022", "archive"]
        }
    },
    {
        "content": "CONFIDENTIAL - M&A Discussion: Preliminary valuation for Target Corp acquisition ranges from $400M-$500M. Due diligence reveals strong synergies in enterprise segment. Board vote scheduled for Q1 2025. Legal counsel: Morrison & Associates. Internal deal code: MA-2024-087.",
        "metadata": {
            "collection": "executive-confidential",
            "source": "internal",
            "date": "2024-11-20T00:00:00Z",
            "tags": ["confidential", "m&a", "executive"]
        }
    }
]

def ingest_chunks():
    headers = {
        "Content-Type": "application/json",
        "apikey": "admin-key"
    }

    for i, chunk in enumerate(chunks, 1):
        try:
            response = requests.post(BASE_URL, json=chunk, headers=headers)
            response.raise_for_status()
            print(f"[{i}/{len(chunks)}] Ingested: {chunk['content'][:50]}...")
            print(response.json())
        except requests.exceptions.RequestException as e:
            print(f"[{i}/{len(chunks)}] Failed: {e}")
            if hasattr(e.response, 'text'):
                print(f"  Response: {e.response.text}")

if __name__ == "__main__":
    ingest_chunks()
EOF
```

Run the script to ingest all chunks:
```bash
python3 ingest-collection.py
```

The script outputs the ingestion status and metadata for each chunk:
```
[1/6] Ingested: Public Investor FAQ: Our fiscal year ends December...
{'metadata': {'embeddings_tokens_count': 49, 'chunk_id': '68ceba6d-0d4f-4506-a4a5-361ba2c813e7', 'ingest_duration': 680, 'collection': 'public-docs'}}
[2/6] Ingested: Q4 2024 Financial Results: Revenue increased 15% y...
{'metadata': {'embeddings_tokens_count': 50, 'chunk_id': 'e0528202-045f-49ac-9cf7-4d009593a7a4', 'ingest_duration': 3177, 'collection': 'finance-reports'}}
[3/6] Ingested: Q3 2024 Financial Results: Revenue reached $2.0B w...
{'metadata': {'embeddings_tokens_count': 42, 'chunk_id': 'fc83226f-154c-4498-880d-c23998ef12a3', 'ingest_duration': 368, 'collection': 'finance-reports'}}
[4/6] Ingested: 2023 Annual Report: Full-year revenue totaled $7.8...
{'metadata': {'embeddings_tokens_count': 45, 'chunk_id': '11067634-4a05-442f-a0c6-cd9b5cba8012', 'ingest_duration': 518, 'collection': 'finance-reports'}}
[5/6] Ingested: Historical Data Archive: Q2 2022 revenue was $1.5B...
{'metadata': {'embeddings_tokens_count': 41, 'chunk_id': '2372438e-a63b-4470-9f3c-ac1ec55a727e', 'ingest_duration': 413, 'collection': 'finance-reports'}}
[6/6] Ingested: CONFIDENTIAL - M&A Discussion: Preliminary valuati...
{'metadata': {'embeddings_tokens_count': 62, 'chunk_id': '3ee8ad00-51ba-45ce-b837-83f69840cbe0', 'ingest_duration': 472, 'collection': 'executive-confidential'}}
```
{:.no-copy-code}

## Test ACL enforcement

Verify that ACL rules correctly restrict access based on consumer group membership.

### CFO access (finance + executive groups)

The CFO belongs to both finance and executive groups, so they can access all collections. The response includes information from both the `finance-reports` and `executive-confidential` collections.

{% validation request-check %}
url: /anything
headers:
  - 'apikey: cfo-key'
  - 'Content-Type: application/json'
body:
  messages:
    - role: user
      content: What were our Q4 2024 results?
status_code: 200
message: In Q4 2024, revenue increased by 15% year-over-year to $2.3 billion, and the operating margin improved to 24%, up from 21% in Q3. Key drivers of this performance included strong enterprise sales and improved operational efficiency.
{% endvalidation %}

Query for M&A information. The response should include confidential M&A information from the `executive-confidential` collection

{% validation request-check %}
url: /anything
headers:
  - 'apikey: cfo-key'
  - 'Content-Type: application/json'
body:
  messages:
    - role: user
      content: What acquisitions are we considering?
status_code: 200
message: The context mentions that there is a consideration of the acquisition of Target Corp, with a preliminary valuation ranging from $400M to $500M. The board vote for this acquisition is scheduled for Q1 2025.
{% endvalidation %}

### Financial analyst access (finance group)

Financial analysts can access financial reports but not executive confidential information. The response should include Q3 and Q4 2024 data from `finance-reports`:

{% validation request-check %}
url: /anything
headers:
  - 'apikey: analyst-key'
  - 'Content-Type: application/json'
body:
  messages:
    - role: user
      content: Show me quarterly reports from Q3 2024
status_code: 200
message: |
    I’m sorry, but I don’t have access to the full quarterly reports from 2024. However, based on the available excerpts:- **Q3 2024:** Revenue was $2.0 billion, with a year-over-year growth of 12%. The operating margin was 21%, and international markets made up 35% of total revenue.- **Q4 2024:** Revenue increased by 15% year-over-year to $2.3 billion. The operating margin improved to 24%, supported by strong enterprise sales and better operational efficiency. For full reports, you may need to visit the company's investor relations website or contact their investor relations department.
{% endvalidation %}

Financial analysts are explicitly denied access to executive data:

{% validation request-check %}
url: /anything
headers:
  - 'apikey: analyst-key'
  - 'Content-Type: application/json'
body:
  messages:
    - role: user
      content: What acquisitions are we considering?
status_code: 200
message: The context does not contain relevant information about acquisitions being considered.
{% endvalidation %}

### Contractor access (contractor group)

Contractors are explicitly denied access to both financial collections:

{% validation request-check %}
url: /anything
headers:
  - 'apikey: contractor-key'
  - 'Content-Type: application/json'
body:
  messages:
    - role: user
      content: What are the latest financial results?
status_code: 200
message: |
    The context does not provide the latest financial results. For the most up-to-date information, you can check the latest quarterly earnings call details or public filings on the company's investor relations website.
{% endvalidation %}


### Public user access (public group)

Public users can access only public documents. The response should information from `public-docs` collection only.

{% validation request-check %}
url: /anything
headers:
  - 'apikey: public-key'
  - 'Content-Type: application/json'
body:
  messages:
    - role: user
      content: How can I contact investor relations?
status_code: 200
message: You can contact investor relations by emailing investor.relations@company.com.
{% endvalidation %}