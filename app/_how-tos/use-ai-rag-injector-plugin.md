---
title: Use AI RAG Injector plugin
content_type: how_to
related_resources:
  - text: AI Gateway
    url: /ai-gateway/
  - text: AI RAG Injector
    url: /plugins/ai-rag-injector/
  - text: AI Proxy Advanced
    url: /plugins/ai-proxy-advanced/

description: Configure the AI RAG Injector plugin.

products:
  - gateway
  - ai-gateway

works_on:
  - on-prem

min_version:
  gateway: '3.6'

plugins:
  - ai-proxy-advanced

entities:
  - service
  - route
  - plugin

tags:
  - ai
  - openai

tldr:
  q: How do I use the AI RAG Injector plugin to safeguard that my company chatbot responds with relevant questions regarding compliance policies?
  a: Use the AI RAG Injector plugin to integrate your company’s compliance policy documents as retrieval-augmented knowledge. Configure the plugin to inject context from these documents into chatbot prompts, ensuring it can generate relevant, accurate compliance-related questions dynamically during conversations.


tools:
  - deck

prereqs:
  inline:
    - title: OpenAI
      include_content: prereqs/openai
      icon_url: /assets/icons/openai.svg
    - title: Redis stack
      content: |
          To complete this task, you must have a Redis stack configured in your environment. Check [Redis website](https://redis.io/docs/latest/) to learn more.
      icon_url: /assets/icons/redis.svg
    - title: PgVector (optionally)
      content: |
        Test
      icon_url: /assets/icons/database.svg
    - title: Langchain splitters
      content: |
        To complete this tutorial, you'll need **Python (version 3.7 or later)** and `pip` installed on your machine. You can verify it by running:

        ```bash
        python --version
        pip --version
         ```

        Once that's set up, install the required packages by running the following command in your terminal:
        ```
        pip install langchain langchain_text_splitters requests
        ```
      icon_url: /assets/icons/python.svg
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
---

## Configure the AI Proxy Advanced plugin

First, you'll need to configure the AI Proxy Advanced plugin:

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

Then, configure the AI RAG Injector plugin

{% entity_examples %}
entities:
  plugins:
  - name: ai-rag-injector
    id: 3194f12e-60c9-4cb6-9cbc-c8fd7a00cff1
    config:
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
          header_value: Bearer ${openai_key}
        model:
          provider: openai
          name: text-embedding-3-large
      vectordb:
        strategy: redis
        redis:
          host: ${redis_host}
          port: 6379
        distance_metric: cosine
        dimensions: 3072
variables:
  openai_api_key:
    value: $OPENAI_API_KEY
  redis_host:
    value: $REDIS_HOST
{% endentity_examples %}

## Split input data before ingestion

Before sending data to the AI Gateway, split your input into manageable chunks using a text splitting tool like `langchain_text_splitters`. This helps optimize downstream processing and improves semantic retrieval performance.

Refer to [langchain text_splitters documents](https://python.langchain.com/docs/concepts/text_splitters/) if your documents
are structured data other than plain texts.

The following Python script demonstrates how to split text using `RecursiveCharacterTextSplitter` and ingest the resulting chunks into the AI Gateway:

```python
from langchain_text_splitters import RecursiveCharacterTextSplitter
import requests

TEXT = ["""
Acme Corp. Travel Policy
1. Purpose
This policy outlines the guidelines for employees traveling on company business to ensure efficient, cost-effective, and accountable use of company funds.
2. Scope
This policy applies to all employees traveling on company business, including domestic and international travel.
3. Travel Approval

    All travel must be pre-approved by the employee's supervisor and, if applicable, by higher management, based on business need and cost-effectiveness.
    Travel requests should be submitted at least [Number] weeks/days in advance, including destination, purpose, dates, and estimated costs.
    Travel requests should be submitted using the designated travel request form.

4. Transportation

    Air Travel:

    Employees should book the most cost-effective airfare, considering time and cost.

Business class or first-class travel is only permitted with prior approval and for exceptional circumstances.
Employees should choose direct flights whenever possible.

Ground Transportation:

    For travel to and from airports or within the destination, employees should use cost-effective options such as shuttles, public transportation, or car services.

Personal vehicle use is permitted for business travel, with reimbursement at the standard IRS mileage rate.
Parking and tolls: are reimbursable when necessary.

Train Travel:

    Train travel is considered an appropriate mode of transportation for certain destinations and will be reimbursed if the cost is less than other means of transportation.

5. Lodging

    Employees should choose lodging that is cost-effective and meets the needs of the business trip.
    Hotel selection: should be based on location, proximity to meeting venues, and cost.
    Employees should book accommodations in advance to secure the best rates.
    Travelers should share hotel rooms with other employees when feasible and appropriate.

6. Meals

    Meals are reimbursable during business travel, but expenses should be kept reasonable and appropriate.
    Employees should present receipts for all meal expenses.
    Alcoholic beverages: are not reimbursable.
    When attending business functions with meals provided, expenses for meals purchased elsewhere are not reimbursed unless specifically authorized in advance.

7. Other Expenses

    Entertainment expenses: are generally not reimbursable, except for business-related entertainment that is necessary for client relations.
    Telephone expenses: are reimbursable when necessary for business travel, but should be kept to a minimum.
    Internet access: is reimbursable when necessary for business travel.

8. Reimbursement

    Employees should submit all travel expenses for reimbursement within 27 days of the trip.
    Employees should submit receipts for all travel expenses.
    Reimbursement will be made in accordance with company policy.

9. Compliance

    All employees are expected to comply with this travel policy.
    Violation of this policy may result in disciplinary action.

10. Policy Updates

    This policy may be updated from time to time as needed.
    Employees will be notified of any changes to this policy.
"""]

text_splitter = RecursiveCharacterTextSplitter(chunk_size=1000, chunk_overlap=100)
docs = text_splitter.create_documents(TEXT)

print("Injecting %d chunks..." % len(docs))

for doc in docs:
    response = requests.post(
        "http://localhost:8001/ai-rag-injector/3194f12e-60c9-4cb6-9cbc-c8fd7a00cff1/ingest_chunk",
        data={'content': doc.page_content}
    )
    print(response.json())
```

Save the script as `inject_policy.py`, then run it:

```bash
python ./inject_policy.py
```

This will output the number of chunks created and display the response from the injector endpoint for each chunk.

### Ingest content to the vector database

Now, you can feed the split chunks into AI Gateway using the Kong Admin API.

The following example shows how to ingest content to the vector database for building the knowledge base. The AI RAG Injector plugin uses the OpenAI `text-embedding-3-large` model to generate embeddings for the content and stores them in Redis.

```bash
curl localhost:8001/ai-rag-injector/3194f12e-60c9-4cb6-9cbc-c8fd7a00cff1/ingest_chunk \
  -H "Content-Type: application/json" \
  -d '{
    "content": "<chunk>"
  }'
```

## Test RAG configuration

### In-scope questions

Use the following in-scope questions to verify that the AI responds accurately based on the approved compliance content and does not rely on external knowledge.

{% navtabs "In scope" %}
{% navtab "Basic" %}

  Use simple user questions that map directly to travel policy clauses:

  ```bash
  curl --http1.1 localhost:8000/chat \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $OPENAI_API_KEY" \
    -d '{
      "messages": [{"role": "user", "content": "Are alcoholic beverages reimbursable?"}]
    }' | jq
  ````

  You can also ask this question:

  ```bash
  curl --http1.1 localhost:8000/chat \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $OPENAI_API_KEY" \
    -d '{
      "messages": [{"role": "user", "content": "What documentation is required for travel reimbursement?"}]
    }' | jq
  ```

{% endnavtab %}
{% navtab "Intermediate" %}

  Use slightly more complex prompts involving multi-step policy logic or multiple clauses:

  ```bash
  curl --http1.1 localhost:8000/chat \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $OPENAI_API_KEY" \
    -d '{
      "messages": [{"role": "user", "content": "Can I get reimbursed for internet charges during a business trip?"}]
    }' | jq
  ```

  Also, you can ask a more complex query about booking a hotel:

  ```bash
  curl --http1.1 localhost:8000/chat \
    -H "Content-Type: application/json" \
    -d '{
      "messages": [{"role": "user", "content": "Do I need to book my hotel in advance for business travel?"}]
    }' | jq
  ```

{% endnavtab %}
{% navtab "Edge Cases" %}

  Use prompts that test boundaries of the compliance language:

  ```bash
  curl --http1.1 localhost:8000/chat \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $OPENAI_API_KEY" \
    -d '{
      "messages": [{"role": "user", "content": "Am I allowed to share a hotel room with another employee?"}]
    }' | jq
  ```

  Or ask about public transportation:

  ```bash
  curl --http1.1 localhost:8000/chat \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $OPENAI_API_KEY" \
    -d '{
      "messages": [{"role": "user", "content": "What’s the policy on using public transportation during travel?"}]
    }' | jq
  ```
{% endnavtab %}
{% endnavtabs %}

### Out-of-scope questions

Use the following out-of-scope questions to confirm that the AI correctly refuses to answer queries that fall outside the ingested compliance content.

{% navtabs "test" %}
{% navtab "General Company Info" %}

  These questions ask about Acme Corp. in general, not about the travel policy:

  ```bash
  curl --http1.1 localhost:8000/chat \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $OPENAI_API_KEY" \
    -d '{
      "messages": [{"role": "user", "content": "What does Acme Corp. do?"}]
    }' | jq
  ````

  ```bash
  curl --http1.1 localhost:8000/chat \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $OPENAI_API_KEY" \
    -d '{
      "messages": [{"role": "user", "content": "Where is Acme Corp. headquartered?"}]
    }' | jq
  ```

{% endnavtab %}
{% navtab "External Knowledge" %}

  These questions require general or external knowledge that is not included in the ingested content:

  ```bash
  curl --http1.1 localhost:8000/chat \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $OPENAI_API_KEY" \
    -d '{
      "messages": [{"role": "user", "content": "Who is the CEO of OpenAI?"}]
    }' | jq
  ```

  ```bash
  curl --http1.1 localhost:8000/chat \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $OPENAI_API_KEY" \
    -d '{
      "messages": [{"role": "user", "content": "How does Redis handle vector storage?"}]
    }' | jq
  ```
{% endnavtab %}
{% navtab "Other HR Policies" %}

These prompts reference company policies that are not part of the travel policy content:

  ```bash
  curl --http1.1 localhost:8000/chat \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $OPENAI_API_KEY" \
    -d '{
      "messages": [{"role": "user", "content": "How much vacation time do I get per year?"}]
    }' | jq
  ```

  ```bash
  curl --http1.1 localhost:8000/chat \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $OPENAI_API_KEY" \
    -d '{
      "messages": [{"role": "user", "content": "What’s the parental leave policy at Acme Corp.?"}]
    }' | jq
  ```

{% endnavtab %}
{% navtab "Ambiguous or Unsupported Topics" %}

These prompts are vague, outside compliance scope, or might encourage hallucination if guardrails aren't working:

  ```bash
  curl --http1.1 localhost:8000/chat \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $OPENAI_API_KEY" \
    -d '{
      "messages": [{"role": "user", "content": "Can you give me general tips for business travel?"}]
    }' | jq
  ```

  ```bash
  curl --http1.1 localhost:8000/chat \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $OPENAI_API_KEY" \
    -d '{
      "messages": [{"role": "user", "content": "What should I pack for an international trip?"}]
    }' | jq
  ```

{% endnavtab %}
{% endnavtabs %}



### Debug the retrieval of the knowledge base

To evaluate which documents are retrieved for a specific prompt, use the following command:

```bash
curl localhost:8001/ai-rag-injector/3194f12e-60c9-4cb6-9cbc-c8fd7a00cff1/lookup_chunks \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "the prompt to debug",
    "exclude_contents": false
  }'
```

{:.info}
> To omit the chunk content and only return the chunk ID, set `exclude_contents` to true.

## Update content for ingesting

If you are running {{site.base_gateway}} in traditional mode, you can update content for ingesting by sending a request to the `/ai-rag-injector/:plugin_id/ingest_chunk` endpoint.

However, this won't work in hybrid mode or {{site.konnect_short_name}} because the control plane can't access the plugin's backend storage.

To update content for ingesting in hybrid mode or {{site.konnect_short_name}}, you can use a script:

1. Retrieve the ID of the AI RAG Injector plugin that you want to update.
2. Copy and paste the following script to a local file, for example `ingest_update.lua`:

   ```lua
   local embeddings = require("kong.llm.embeddings")
   local uuid = require("kong.tools.utils").uuid
   local vectordb = require("kong.llm.vectordb")

   local function get_plugin_by_id(id)
     local row, err = kong.db.plugins:select(
       {id = id},
       { workspace = ngx.null, show_ws_id = true, expand_partials = true }
     )

     if err then
         return nil, err
     end

     return row
   end

   local function ingest_chunk(conf, content)
     local err
     local metadata = {
         ingest_duration = ngx.now(),
     }
     -- vectordb driver init
     local vectordb_driver
     do
         vectordb_driver, err = vectordb.new(conf.vectordb.strategy, conf.vectordb_namespace, conf.  vectordb)
         if err then
             return nil, "Failed to load the '" .. conf.vectordb.strategy .. "' vector database   driver: " .. err
         end
     end

     -- embeddings init
     local embeddings_driver, err = embeddings.new(conf.embeddings, conf.vectordb.dimensions)
     if err then
         return nil, "Failed to instantiate embeddings driver: " .. err
     end

     local embeddings_vector, embeddings_tokens_count, err = embeddings_driver:generate(content)
     if err then
         return nil, "Failed to generate embeddings: " .. err
     end

     metadata.embeddings_tokens_count = embeddings_tokens_count
     if #embeddings_vector ~= conf.vectordb.dimensions then
       return nil, "Embedding dimensions do not match the configured vector database. Embeddings were   " ..
         #embeddings_vector .. " dimensions, but the vector database is configured for " ..
         conf.vectordb.dimensions .. " dimensions.", "Embedding dimensions do not match the   configured vector database"
     end

     metadata.chunk_id = uuid()
     -- ingest chunk
     local _, err = vectordb_driver:insert(embeddings_vector, content, metadata.chunk_id)
     if err then
         return nil, "Failed to insert chunk: " .. err
     end

     return true
   end

   assert(#args == 3, "2 arguments expected")
   local plugin_id, content = args[2], args[3]

   local plugin, err = get_plugin_by_id(plugin_id)
   if err then
     ngx.log(ngx.ERR, "Failed to get plugin: " .. err)
     return
   end

   if not plugin then
     ngx.log(ngx.ERR, "Plugin not found")
     return
   end

   local _, err = ingest_chunk(plugin.config, content)
   if err then
     ngx.log(ngx.ERR, "Failed to ingest: " .. err)
     return
   end

   ngx.log(ngx.INFO, "Update completed")

   ```

3. Run the script from your Kong instance:

   ```sh
   kong runner ingest_api.lua <plugin_id> <content_to_update>
   ```