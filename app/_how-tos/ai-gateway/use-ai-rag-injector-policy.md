---
title: Ensure chatbots adhere to compliance policies with the AI RAG Injector Policy
permalink: /ai-gateway/use-ai-rag-injector-policy/
content_type: how_to
related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/
  - text: AI RAG Injector
    url: /ai-gateway/policies/ai-rag-injector/

description: Learn how to configure the AI RAG Injector Policy.

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
  q: How do I use the AI RAG Injector Policy to ensure that my company chatbot responds with relevant questions regarding compliance policies?
  a: Use the AI RAG Injector Policy to integrate your company's compliance policy documents as retrieval-augmented knowledge. Configure the Policy to inject context from these documents into chatbot prompts, ensuring it can generate relevant, accurate compliance-related questions dynamically during conversations.

tools:
  - kongctl

prereqs:
  inline:
    - title: OpenAI
      include_content: md/ai-gateway/v2/prereqs/openai-kongctl
      icon_url: /assets/icons/openai.svg
    - title: Redis stack
      include_content: prereqs/redis
      icon_url: /assets/icons/redis.svg
    - title: Langchain splitters
      include_content: prereqs/langchain
      icon_url: /assets/icons/python.svg

cleanup:
  inline:
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg

---

## Create the AI Model Provider, AI Model, and AI RAG Injector Policy

Create an [AI Model Provider](/ai-gateway/entities/ai-model-provider/), an [AI Model](/ai-gateway/entities/ai-model/), and the [AI RAG Injector](/ai-gateway/policies/ai-rag-injector/) Policy with a single `kongctl` apply command.

The AI RAG Injector Policy generates embeddings for prompts, queries a vector database for relevant context, and injects that context into the request before it reaches the AI Model Provider. This lets your chatbot answer only from your company's approved compliance content, using retrieval-augmented generation (RAG).

Before applying, export your Redis host so `kongctl` can reference it:

```bash
export REDIS_HOST="<YOUR-REDIS-HOST>"
```

{:.info}
> If your Redis instance runs in a separate Docker container from {{site.ai_gateway}}, use `host.docker.internal` for `REDIS_HOST`.
>
> If you use a model other than `text-embedding-3-large`, update `vectordb.dimensions` in the Policy config to match that model's embedding size.

<!--vale off-->
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
  - ref: my-ai-rag-injector-policy
    name: my-ai-rag-injector-policy
    display_name: my-ai-rag-injector-policy
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    type: ai-rag-injector
    enabled: true
    global: false
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
          header_value: !env OPENAI_AUTH_HEADER
        model:
          provider: openai
          name: text-embedding-3-large
      vectordb:
        strategy: redis
        dimensions: 3072
        distance_metric: cosine
        redis:
          host: !env REDIS_HOST
          port: 6379
ai_gateway_models:
  - ref: my-gpt-4o
    display_name: my-gpt-4o
    name: my-gpt-4o
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
            - my-gpt-4o
    capabilities: [generate]
    policies: [ !ref my-ai-rag-injector-policy#name ]
    targets:
      - name: gpt-4o
        provider: generic-openai
        config:
          type: openai
{% endentity_examples %}
<!--vale on-->

In this example, we're setting up the AI RAG Injector Policy with:

* `type: ai-rag-injector`: Specifies that this Policy retrieves relevant context from a vector database and injects it into the prompt before forwarding the request to the AI Model Provider.
* `global: false`: Scopes the Policy to only the AI Models it's explicitly attached to via `policies:`, rather than applying it to every resource on {{site.ai_gateway}}.
* `config.embeddings`: Configures the model and auth used to generate embeddings for incoming prompts and for the content you ingest later in this guide. This example uses OpenAI's `text-embedding-3-large` model. Unlike the AI Model Provider's own `auth.headers[].value`, `config.embeddings.auth.header_value` on this Policy doesn't currently support `!secret` in `kongctl` — use `!env` here instead, or `kongctl apply` rejects the config with `is not a reviewed write-only field`.
* `config.vectordb`: Configures the vector database that stores your ingested compliance content. This example uses Redis with cosine similarity and 3072-dimension embeddings, matching `text-embedding-3-large`. See [Vector databases](/ai-gateway/policies/ai-rag-injector/#vector-databases) for other supported strategies, including pgvector and managed Redis with cloud authentication.
* `policies: [!ref my-ai-rag-injector-policy#name]` on the AI Model: Attaches this Policy so it applies to every request routed through `my-gpt-4o`.

## Split input data before ingestion

Before sending data to {{site.ai_gateway}}, split your input into manageable chunks using a text splitting tool like `langchain_text_splitters`. This helps optimize downstream processing and improves semantic retrieval performance.

Refer to [langchain text_splitters documents](https://python.langchain.com/docs/concepts/text_splitters/) if your documents are structured data other than plain text.

The following Python script demonstrates how to split text using `RecursiveCharacterTextSplitter`, ready to feed the resulting chunks into {{site.ai_gateway}} in the next step.

<!-- vale off -->
{% validation custom-command %}
command: |
  cat <<EOF > inject_policy.py
  from langchain_text_splitters import RecursiveCharacterTextSplitter

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

  print("Split into %d chunks." % len(docs))
  for doc in docs:
      print("---")
      print(doc.page_content)
  EOF
expected:
  return_code: 0
render_output: false
{% endvalidation %}
<!-- vale on -->

## Ingest content into the vector database

<!-- TODO: This section needs engineering/product confirmation before publishing.
     What's missing: the v1 doc ingested content by calling the AI RAG Injector
     plugin's own Admin API endpoint (`/ai-rag-injector/{plugin_id}/ingest_chunk`,
     see app/_how-tos/ai-gateway/v1/use-ai-rag-injector-plugin.md and
     api-specs/plugins/ai-rag-injector/openapi.yaml). That endpoint is explicitly
     scoped to Kong's local Admin API — Konnect users never have Admin API access,
     which is exactly why the v1 doc's own "Update content for ingesting" section
     already had to fall back to a `kong runner` Lua script run directly on a
     self-managed data plane. AI Gateway 2.0 is Konnect-only (no user-accessible
     data planes at all), so neither the Admin API call nor the `kong runner`
     workaround carries over.

     The AI RAG Injector Policy's own content page (app/_ai_gateway_policies/
     ai-rag-injector/index.md) says content is ingested "via the Konnect API" and
     shows the ingested content/metadata JSON shape (content + metadata.collection/
     date/tags/source), but doesn't give the actual endpoint path — and it isn't in
     any local spec copy checked this session (api-specs/plugins/ai-rag-injector/
     openapi.yaml is the v1 Admin-API spec; the local Konnect AI Gateway OpenAPI
     spec at ~/docs/ai-gateway-test-harness/ref/konnect-ai-gateway.json only
     covers 4 unrelated paths; ~/docs/platform-api has no ai-gateway-policy
     definitions at all). The ai-gateway-test-harness's own RAG Injector test
     cases (AI-GW-4.7, AI-GW-4.8) don't exercise ingestion either — both just
     assume Redis is pre-populated externally.

     Before publishing, get the real Konnect API path (and the way to resolve
     an ai_gateway_policies ref to its Policy ID, since kongctl apply has no
     response body to read an ID from) from Fabian Rodriguez / engineering, then
     replace this whole section with a konnect_api_request step per doc,
     following the pattern in app/_how-tos/event-gateway/kong-identity-oauth.md. -->

Once the Konnect API endpoint for AI RAG Injector content ingestion is confirmed, send each chunk from `inject_policy.py` to it, referencing your `my-ai-rag-injector-policy` Policy. This replaces the v1 workflow's `kong runner` Lua script — that approach relied on a self-managed data plane, which doesn't exist in Konnect-only {{site.ai_gateway}} 2.0.

## Test RAG configuration

Now you can send various questions to the AI to verify that RAG is working correctly.

### In-scope questions

Use the following in-scope questions to verify that the AI responds accurately based on the approved compliance content and doesn't rely on external knowledge.

{% navtabs "In scope" %}
{% navtab "Basic questions" %}

Use simple user questions that map directly to travel policy clauses:

{% validation request-check %}
url: /chat/completions
method: POST
status_code: 200
headers:
  - 'Content-Type: application/json'
  - 'Authorization: $OPENAI_AUTH_HEADER'
body:
  model: "my-gpt-4o"
  messages:
    - role: user
      content: Are alcoholic beverages reimbursable?
{% endvalidation %}

You can also ask this question:

{% validation request-check %}
url: /chat/completions
method: POST
status_code: 200
headers:
  - 'Content-Type: application/json'
  - 'Authorization: $OPENAI_AUTH_HEADER'
body:
  model: "my-gpt-4o"
  messages:
    - role: user
      content: What documentation is required for travel reimbursement?
{% endvalidation %}

{% endnavtab %}
{% navtab "Intermediate questions" %}

Use slightly more complex prompts involving multi-step policy logic or multiple clauses:

{% validation request-check %}
url: /chat/completions
method: POST
status_code: 200
headers:
  - 'Content-Type: application/json'
  - 'Authorization: $OPENAI_AUTH_HEADER'
body:
  model: "my-gpt-4o"
  messages:
    - role: user
      content: Can I get reimbursed for internet charges during a business trip?
{% endvalidation %}

Also, you can ask a more complex query about booking a hotel:

{% validation request-check %}
url: /chat/completions
method: POST
status_code: 200
headers:
  - 'Content-Type: application/json'
  - 'Authorization: $OPENAI_AUTH_HEADER'
body:
  model: "my-gpt-4o"
  messages:
    - role: user
      content: Do I need to book my hotel in advance for business travel?
{% endvalidation %}

{% endnavtab %}
{% navtab "Edge cases" %}

Use prompts that test boundaries of the compliance language:

{% validation request-check %}
url: /chat/completions
method: POST
status_code: 200
headers:
  - 'Content-Type: application/json'
  - 'Authorization: $OPENAI_AUTH_HEADER'
body:
  model: "my-gpt-4o"
  messages:
    - role: user
      content: Am I allowed to share a hotel room with another employee?
{% endvalidation %}

Or ask about public transportation:

{% validation request-check %}
url: /chat/completions
method: POST
status_code: 200
headers:
  - 'Content-Type: application/json'
  - 'Authorization: $OPENAI_AUTH_HEADER'
body:
  model: "my-gpt-4o"
  messages:
    - role: user
      content: What's the policy on using public transportation during travel?
{% endvalidation %}
{% endnavtab %}
{% endnavtabs %}

### Out-of-scope questions

Use the following out-of-scope questions to confirm that the AI correctly refuses to answer queries that fall outside the ingested compliance content. The AI should return a response similar to:

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
url: /chat/completions
method: POST
status_code: 200
headers:
  - 'Content-Type: application/json'
  - 'Authorization: $OPENAI_AUTH_HEADER'
body:
  model: "my-gpt-4o"
  messages:
    - role: user
      content: What does Acme Corp. do?
{% endvalidation %}

{% validation request-check %}
url: /chat/completions
method: POST
status_code: 200
headers:
  - 'Content-Type: application/json'
  - 'Authorization: $OPENAI_AUTH_HEADER'
body:
  model: "my-gpt-4o"
  messages:
    - role: user
      content: Where is Acme Corp. headquartered?
{% endvalidation %}

{% endnavtab %}
{% navtab "External knowledge" %}

These questions require general or external knowledge that isn't included in the ingested content:

{% validation request-check %}
url: /chat/completions
method: POST
status_code: 200
headers:
  - 'Content-Type: application/json'
  - 'Authorization: $OPENAI_AUTH_HEADER'
body:
  model: "my-gpt-4o"
  messages:
    - role: user
      content: Who is the CEO of OpenAI?
{% endvalidation %}

{% validation request-check %}
url: /chat/completions
method: POST
status_code: 200
headers:
  - 'Content-Type: application/json'
  - 'Authorization: $OPENAI_AUTH_HEADER'
body:
  model: "my-gpt-4o"
  messages:
    - role: user
      content: How does Redis handle vector storage?
{% endvalidation %}
{% endnavtab %}
{% navtab "Other HR policies" %}

These prompts reference company policies that aren't part of the travel policy content:

{% validation request-check %}
url: /chat/completions
method: POST
status_code: 200
headers:
  - 'Content-Type: application/json'
  - 'Authorization: $OPENAI_AUTH_HEADER'
body:
  model: "my-gpt-4o"
  messages:
    - role: user
      content: How much vacation time do I get per year?
{% endvalidation %}

{% validation request-check %}
url: /chat/completions
method: POST
status_code: 200
headers:
  - 'Content-Type: application/json'
  - 'Authorization: $OPENAI_AUTH_HEADER'
body:
  model: "my-gpt-4o"
  messages:
    - role: user
      content: What's the parental leave policy at Acme Corp.?
{% endvalidation %}

{% endnavtab %}
{% navtab "Ambiguous or unsupported topics" %}

These prompts are vague, outside compliance scope, or might encourage hallucination if guardrails aren't working:

{% validation request-check %}
url: /chat/completions
method: POST
status_code: 200
headers:
  - 'Content-Type: application/json'
  - 'Authorization: $OPENAI_AUTH_HEADER'
body:
  model: "my-gpt-4o"
  messages:
    - role: user
      content: What is the best destination for international travel?
{% endvalidation %}

{% validation request-check %}
url: /chat/completions
method: POST
status_code: 200
headers:
  - 'Content-Type: application/json'
  - 'Authorization: $OPENAI_AUTH_HEADER'
body:
  model: "my-gpt-4o"
  messages:
    - role: user
      content: What should I pack for an international trip?
{% endvalidation %}

{% endnavtab %}
{% endnavtabs %}

## Update content for ingesting

{{site.ai_gateway}} 2.0 is Konnect-only, so update the vector database through the same Konnect API ingestion endpoint used in [Ingest content into the vector database](#ingest-content-into-the-vector-database), referencing your Policy's ID. Don't use the v1 `kong runner` workaround: it depends on shell access to a self-managed data plane, which doesn't exist for {{site.ai_gateway}} 2.0.
