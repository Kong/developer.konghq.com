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
  - konnect

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
  a: Answer

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
       To complete this tutorial, you'll need Python and `pip` installed on your machine.

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
        dimensions: 76
variables:
  openai_api_key:
    value: $OPENAI_API_KEY
  redis_host:
    value: $REDIS_HOST
{% endentity_examples %}

## Split input data before ingestion

Before sending data to the AI Gateway, split your input into manageable chunks using a text splitting tool like `langchain_text_splitters`. This helps optimize downstream processing and improves semantic retrieval performance.

The following Python script demonstrates how to split text using `RecursiveCharacterTextSplitter` and ingest the resulting chunks into the AI Gateway:

```python
from langchain_text_splitters import RecursiveCharacterTextSplitter
import requests

TEXT = ["Your long input document goes here."]

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

Now, you can feed the split chunks into AI Gateway using the Kong Admin API.

### Ingest content to the vector database

The following example shows how to ingest content to the vector database for building the knowledge base. The AI RAG Injector plugin uses the OpenAI `text-embedding-3-large` model to generate embeddings for the content and stores them in Redis.

```bash
curl localhost:8001/ai-rag-injector/3194f12e-60c9-4cb6-9cbc-c8fd7a00cff1/ingest_chunk \
  -H "Content-Type: application/json" \
  -d '{
    "content": "<chunk>"
  }'
```


## Make an AI request to the AI Proxy Advanced plugin

Once vector database has ingested data and built a knowledge base, you can make requests to it.
For example:

```bash
curl  --http1.1 localhost:8000/chat \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -d '{
     "messages": [{"role": "user", "content": "What is kong"}]
   }' | jq
```

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