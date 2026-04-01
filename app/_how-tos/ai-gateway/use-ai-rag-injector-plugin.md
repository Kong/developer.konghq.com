---
title: Ensure chatbots adhere to compliance policies with the AI RAG Injector plugin
permalink: /how-to/use-ai-rag-injector-plugin/
content_type: how_to
related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/
  - text: AI RAG Injector
    url: /plugins/ai-rag-injector/
  - text: AI Proxy Advanced
    url: /plugins/ai-proxy-advanced/

description: Learn how to configure the AI RAG Injector plugin.

products:
  - gateway
  - ai-gateway

works_on:
  - on-prem

min_version:
  gateway: '3.6'

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
  q: How do I use the AI RAG Injector plugin to ensure that my company chatbot responds with relevant questions regarding compliance policies?
  a: Use the AI RAG Injector plugin to integrate your company’s compliance policy documents as retrieval-augmented knowledge. Configure the plugin to inject context from these documents into chatbot prompts, ensuring it can generate relevant, accurate compliance-related questions dynamically during conversations.


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
    - title: Langchain splitters
      include_content: prereqs/langchain
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

## Configure the AI RAG Injector plugin

Next, configure the AI RAG Injector plugin to inject precise, context-specific instructions and relevant knowledge from a company's private compliance data into the AI prompt. This configuration ensures the AI answers employee questions accurately using only approved information through retrieval-augmented generation (RAG).

{% entity_examples %}
entities:
  plugins:
  - name: ai-rag-injector
    id: b924e3e8-7893-4706-aacb-e75793a1d2e9
    config:
      inject_template: |
        You are an AI assistant designed to answer employee questions using only the approved compliance content provided between the <RAG></RAG> tags.
        Do not use external or general knowledge, and do not answer if the information is not available in the RAG content.
        <RAG><CONTEXT></RAG>
        User'\''s question: <PROMPT>
        Respond only with information found in the <RAG> section. If the answer is not clearly present, reply with:
        "I'\''m sorry, I cannot answer that based on the available compliance information."
      embeddings:
        auth:
          header_name: Authorization
          header_value: Bearer ${openai_api_key}
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

{:.info}
> If your Redis instance runs in a separate Docker container from Kong, use `host.docker.internal` for `vectordb.redis.host`.
>
> If you're using a model other than `text-embedding-3-large`, be sure to update the `vectordb.dimensions` value to match the model’s embedding size.

## Split input data before ingestion

Before sending data to the {{site.ai_gateway}}, split your input into manageable chunks using a text splitting tool like `langchain_text_splitters`. This helps optimize downstream processing and improves semantic retrieval performance.

Refer to [langchain text_splitters documents](https://python.langchain.com/docs/concepts/text_splitters/) if your documents
are structured data other than plain texts.

The following Python script demonstrates how to split text using `RecursiveCharacterTextSplitter` and ingest the resulting chunks into the {{site.ai_gateway}}. This script uses the AI RAG Injector plugin ID we set in the previous step, so be sure to replace it if your plugin has a different ID.

<!-- vale off -->
{% validation custom-command %}
command: |
  cat <<EOF > inject_policy.py
  from langchain_text_splitters import RecursiveCharacterTextSplitter
  import requests

  TEXT = ["""
  Acme Corp. Travel Policy
  1. Purpose
  This policy outlines the guidelines for employees traveling on company business to ensure efficient, cost-effective, and accountable use of company funds.
  1. Scope
  This policy applies to all employees traveling on company business, including domestic and international travel.
  1. Travel Approval

      All travel must be pre-approved by the employee's supervisor and, if applicable, by higher management, based on business need and cost-effectiveness.
      Travel requests should be submitted at least [Number] weeks/days in advance, including destination, purpose, dates, and estimated costs.
      Travel requests should be submitted using the designated travel request form.

  2. Transportation

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
          "http://localhost:8001/ai-rag-injector/b924e3e8-7893-4706-aacb-e75793a1d2e9/ingest_chunk", # Replace the placeholder with your AI RAG Injector plugin ID
          data={'content': doc.page_content}
      )
      print(response.json())
  EOF
expected:
  return_code: 0
render_output: false
{% endvalidation %}
<!-- vale on -->

{:.info}
> You can replace `print(response.json())` with `print(response.text)` to view the raw HTTP response body as a plain string instead of a parsed JSON object. This is useful for debugging cases where:
>
> * The response isn't valid JSON (e.g., plain text error message or HTML).
> * You want to inspect the exact response content without triggering a JSON parse error.
>
> Use `response.text` when troubleshooting unexpected server responses or plugin misconfigurations.


Run the `inject_policy.py` script in your terminal:

{% validation custom-command %}
command: python3 ./inject_policy.py
expected:
  return_code: 0
render_output: false
{% endvalidation %}

This will output the number of chunks created and display the response from the injector endpoint for each chunk:

```text
Injecting 4 chunks...
{"metadata":{"ingest_duration":1476,"embeddings_tokens_count":157,"chunk_id":"a1b2c3d4-e5f6-7890-ab12-34567890abcd"}}
{"metadata":{"ingest_duration":1323,"embeddings_tokens_count":140,"chunk_id":"b2c3d4e5-f678-9012-bc34-567890abcdef"}}
{"metadata":{"ingest_duration":1286,"embeddings_tokens_count":141,"chunk_id":"c3d4e5f6-7890-1234-cd56-7890abcdef12"}}
{"metadata":{"ingest_duration":2892,"embeddings_tokens_count":168,"chunk_id":"d4e5f678-9012-3456-de78-90abcdef1234"}}
```
{:.no-copy-code}


### Ingest content to the vector database

Now, you can feed the split chunks into {{site.ai_gateway}} using the Kong Admin API.

The following example shows how to ingest content to the vector database for building the knowledge base. The AI RAG Injector plugin uses the OpenAI `text-embedding-3-large` model to generate embeddings for the content and stores them in Redis.

<!--vale off-->
{% control_plane_request %}
url: /ai-rag-injector/b924e3e8-7893-4706-aacb-e75793a1d2e9/ingest_chunk
method: POST
status_code: 200
headers:
    - 'Accept: application/json'
    - 'Content-Type: application/json'
body:
    content: <chunk>
{% endcontrol_plane_request %}
<!--vale on-->
This will return something like the following:

```sh
{"metadata":{"embeddings_tokens_count":3,"chunk_id": "3fa85f64-5717-4562-b3fc-2c963fabcdef","ingest_duration":550}}
```
{:.no-copy-code}

## Test RAG configuration

Now you can send various questions to the AI to verify that RAG is working correctly.

### In-scope questions

Use the following in-scope questions to verify that the AI responds accurately based on the approved compliance content and doesn't rely on external knowledge.

{% navtabs "In scope" %}
{% navtab "Basic questions" %}

  Use simple user questions that map directly to travel policy clauses:

  {% validation request-check %}
  url: /anything
  method: POST
  status_code: 200
  headers:
    - 'Content-Type: application/json'
    - 'Authorization: Bearer $DECK_OPENAI_API_KEY'
  body:
    messages:
      - role: user
        content: Are alcoholic beverages reimbursable?
  {% endvalidation %}

  You can also ask this question:

  {% validation request-check %}
  url: /anything
  method: POST
  status_code: 200
  headers:
    - 'Content-Type: application/json'
    - 'Authorization: Bearer $DECK_OPENAI_API_KEY'
  body:
    messages:
      - role: user
        content: What documentation is required for travel reimbursement?
  {% endvalidation %}

{% endnavtab %}
{% navtab "Intermediate questions" %}

  Use slightly more complex prompts involving multi-step policy logic or multiple clauses:

{% validation request-check %}
url: /anything
method: POST
status_code: 200
headers:
  - 'Content-Type: application/json'
  - 'Authorization: Bearer $DECK_OPENAI_API_KEY'
body:
  messages:
    - role: user
      content: Can I get reimbursed for internet charges during a business trip?
{% endvalidation %}

  Also, you can ask a more complex query about booking a hotel:

{% validation request-check %}
url: /anything
method: POST
status_code: 200
headers:
  - 'Content-Type: application/json'
  - 'Authorization: Bearer $DECK_OPENAI_API_KEY'
body:
  messages:
    - role: user
      content: Do I need to book my hotel in advance for business travel?
{% endvalidation %}

{% endnavtab %}
{% navtab "Edge cases" %}

  Use prompts that test boundaries of the compliance language:

{% validation request-check %}
url: /anything
method: POST
status_code: 200
headers:
  - 'Content-Type: application/json'
  - 'Authorization: Bearer $DECK_OPENAI_API_KEY'
body:
  messages:
    - role: user
      content: Am I allowed to share a hotel room with another employee?
{% endvalidation %}

  Or ask about public transportation:

{% validation request-check %}
url: /anything
method: POST
status_code: 200
headers:
  - 'Content-Type: application/json'
  - 'Authorization: Bearer $DECK_OPENAI_API_KEY'
body:
  messages:
    - role: user
      content: What’s the policy on using public transportation during travel?
{% endvalidation %}
{% endnavtab %}
{% endnavtabs %}

### Out-of-scope questions

Use the following out-of-scope questions to confirm that the AI correctly refuses to answer queries that fall outside the ingested compliance content. AI should return the following response to these requests:

```json
"message": {
    "role": "assistant",
    "content": "I'm sorry, I cannot answer that based on the available compliance information.",
  }
```
{:.no-copy-code}

{% navtabs "test" %}
{% navtab "General company info" %}

  These questions ask about Acme Corp. in general, not about the travel policy:

{% validation request-check %}
url: /anything
method: POST
status_code: 200
headers:
  - 'Content-Type: application/json'
  - 'Authorization: Bearer $DECK_OPENAI_API_KEY'
body:
  messages:
    - role: user
      content: What does Acme Corp. do?
{% endvalidation %}

{% validation request-check %}
url: /anything
method: POST
status_code: 200
headers:
  - 'Content-Type: application/json'
  - 'Authorization: Bearer $DECK_OPENAI_API_KEY'
body:
  messages:
    - role: user
      content: Where is Acme Corp. headquartered?
{% endvalidation %}

{% endnavtab %}
{% navtab "External knowledge" %}

  These questions require general or external knowledge that is not included in the ingested content:

{% validation request-check %}
url: /anything
method: POST
status_code: 200
headers:
  - 'Content-Type: application/json'
  - 'Authorization: Bearer $DECK_OPENAI_API_KEY'
body:
  messages:
    - role: user
      content: Who is the CEO of OpenAI?
{% endvalidation %}

{% validation request-check %}
url: /anything
method: POST
status_code: 200
headers:
  - 'Content-Type: application/json'
  - 'Authorization: Bearer $DECK_OPENAI_API_KEY'
body:
  messages:
    - role: user
      content: How does Redis handle vector storage?
{% endvalidation %}
{% endnavtab %}
{% navtab "Other HR policies" %}

These prompts reference company policies that aren't part of the travel policy content:

{% validation request-check %}
url: /anything
method: POST
status_code: 200
headers:
  - 'Content-Type: application/json'
  - 'Authorization: Bearer $DECK_OPENAI_API_KEY'
body:
  messages:
    - role: user
      content: How much vacation time do I get per year?
{% endvalidation %}

{% validation request-check %}
url: /anything
method: POST
status_code: 200
headers:
  - 'Content-Type: application/json'
  - 'Authorization: Bearer $DECK_OPENAI_API_KEY'
body:
  messages:
    - role: user
      content: What’s the parental leave policy at Acme Corp.?
{% endvalidation %}

{% endnavtab %}
{% navtab "Ambiguous or unsupported topics" %}

These prompts are vague, outside compliance scope, or might encourage hallucination if guardrails aren't working:

{% validation request-check %}
url: /anything
method: POST
status_code: 200
headers:
  - 'Content-Type: application/json'
  - 'Authorization: Bearer $DECK_OPENAI_API_KEY'
body:
  messages:
    - role: user
      content: What is the best destination for international travel?
{% endvalidation %}

{% validation request-check %}
url: /anything
method: POST
status_code: 200
headers:
  - 'Content-Type: application/json'
  - 'Authorization: Bearer $DECK_OPENAI_API_KEY'
body:
  messages:
    - role: user
      content: What should I pack for an international trip?
{% endvalidation %}

{% endnavtab %}
{% endnavtabs %}


### Debug the retrieval of the knowledge base

To evaluate which documents are retrieved for a specific prompt, use the following command:

<!--vale off-->
{% control_plane_request %}
url: /ai-rag-injector/b924e3e8-7893-4706-aacb-e75793a1d2e9/lookup_chunks
method: POST
status_code: 200
headers:
    - 'Accept: application/json'
    - 'Content-Type: application/json'
body:
    prompt: Am I allowed to share a hotel room with another employee?
    exclude_contents: false
{% endcontrol_plane_request %}
<!--vale on-->

This will return which content in the compliance policy AI is using to answer the user question.

{:.info}
> To omit the chunk content and only return the chunk ID, set `exclude_contents` to true.

## Update content for ingesting

If you are running {{site.base_gateway}} in traditional mode, you can update content for ingesting by sending a request to the `/ai-rag-injector/{pluginId}/ingest_chunk` endpoint.

However, this won't work in hybrid mode or {{site.konnect_short_name}} because the control plane can't access the plugin's backend storage.

To update content for ingesting in hybrid mode or {{site.konnect_short_name}}, you can use the below Lua script for splitting content into chunks:

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
         vectordb_driver, err = vectordb.new(conf.vectordb.strategy, conf.vectordb_namespace, conf.vectordb, true)
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

3. Run the script from your Kong instance. This uses your AI RAG Injector plugin ID and the content you want to update. Here's an example:

   ```sh
   kong runner ingest_api.lua b924e3e8-7893-4706-aacb-e75793a1d2e9 ./inject_policy.py
   ```