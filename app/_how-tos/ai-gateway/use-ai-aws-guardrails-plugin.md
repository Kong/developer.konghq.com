---
title: Use the AI AWS Guardrails plugin
permalink: /ai-gateway/how-to/use-ai-aws-guardrails-plugin/
content_type: how_to

related_resources:
  - text: Azure AI Content Safety
    url: /plugins/ai-azure-content-safety/
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/
description: Learn how to use the AI AWS Guardrails plugin.

products:
    - ai-gateway

works_on:
    - konnect

min_version:
  ai-gateway: '2.0'

ai-policies:
  - ai-aws-guardrails

entities:
  - provider
  - model

tools:
    - kongctl

tags:
  - ai
  - openai
  - azure
  - bedrock

tldr:
  q: How can I use the AI AWS Guardrails plugin with {{site.ai_gateway}}?
  a: Configure an AI Provider and AI Model to route requests to any LLM upstreams. Apply an AI AWS Guardrails Policy to your model to block unsafe inputs and outputs based on a predefined Bedrock guardrail.

---

## Create an AI Provider

Create an [AI Provider](/ai-gateway/entities/ai-provider/) entity to define your connection to OpenAI and store your authentication credentials:

<!-- vale off -->
{% konnect_api_request %}
url: /v1/ai-gateways/$AI_GATEWAY_ID/providers
status_code: 201
method: POST
headers:
  - 'Content-Type: application/json'
  - 'Accept: application/json, application/problem+json'
body:
  type: openai
  display_name: generic-openai
  name: generic-openai
  config:
    auth:
      type: basic
      headers:
        - name: Authorization
          value: Bearer $OPENAI_API_KEY
{% endkonnect_api_request %}
<!-- vale on -->

In this example, we're setting up the AI Provider with:

* `type: openai`: Specifies that this provider connects to the OpenAI service using OpenAI's standard API format.
* `name: generic-openai`: A unique identifier that AI Models will reference to route requests through this provider.
* `config.auth`: Stores your OpenAI API key. {{site.ai_gateway}} securely manages this credential and injects it into upstream requests automatically, eliminating the need for clients to pass API keys.


## Create an AWS Guardrails AI Policy

```
curl --request POST \
  --url https://us.api.konghq.com/v1/ai-gateways/$AI_GATEWAY_ID/policies \
  --header 'Accept: application/json, application/problem+json' \
  --header 'Authorization: Bearer ' \
  --header 'Content-Type: application/json' \
  --data '{
  "display_name": "My AWS Guardrails Policy",
  "name": "my-aws-guardrails-policy",
  "type": "ai-aws-guardrails",
  "config": {
    guardrails_id: "$DECK_GUARDRAILS_ID"
    guardrails_version: "$DECK_GUARDRAILS_VERSION"
    aws_region: "$DECK_AWS_REGION"
    aws_access_key_id: "$DECK_AWS_ACCESS_KEY_ID"
    aws_secret_access_key: "$DECK_AWS_SECRET_ACCESS_KEY"
  }
}'
```


## Configure an AI Model with an AWS Guardrails AI Policy

Create an [AI Model](/ai-gateway/entities/ai-model/) entity to declare which upstream models are available, configure how client requests are routed, and specify which AI Provider to use:

<!-- vale off -->
{% konnect_api_request %}
url: /v1/ai-gateways/$AI_GATEWAY_ID/models
status_code: 201
method: POST
headers:
  - 'Content-Type: application/json'
  - 'Accept: application/json, application/problem+json'
body:
  display_name: my-gpt-4o
  name: my-gpt-4o
  type: model
  formats:
    - type: openai
  config:
    route:
      paths:
        - /v1
    model: {}
    logging:
      payloads: false
      statistics: true
  targets:
    - name: gpt-4o
      provider: generic-openai
      config:
        type: openai
  policies: [my-aws-guardrails-policy]
  capabilities:
    - generate
{% endkonnect_api_request %}
<!-- vale on -->

In this example, we're setting up the AI Model with:

* `type: model`: Specifies this is a synchronous model for request/response workloads.
* `name: my-gpt-4o`: A unique identifier for this model.
* `formats: [type: openai]`: Declares that this model accepts requests in OpenAI-compatible format.
* `config.route.paths: [/v1]`: Configures the custom base path where this model's Routes will be accessible. Clients will send requests to paths that combine this base path with capability-specific Routes.
* `capabilities: [generate]`: Enables the text generation capability. The `generate` capability creates a `/chat/completions` endpoint, so combined with your base path, clients send chat requests to `/v1/chat/completions`.
* `targets`: Specifies which upstream AI Provider model to route requests to. Here, `provider: generic-openai` references the AI Provider we created earlier, and `name: gpt-4o` specifies which OpenAI model to call upstream.
* `config.logging`: Configures what gets logged. With `statistics: true`, usage metrics (tokens, latency, cost) are logged for monitoring and billing. With `payloads: false`, full request/response bodies are not logged for privacy.


## Test the configuration

Now, let’s revisit our [guardrail configuration](#bedrock-guardrail). We set it up to block specific banned words, the topic of quantum computing, and content categories like violence, hate, sexual content, insults, and misconduct—applying blocking actions on both input and output.

Next, let’s test these guardrails using example prompts designed to trigger each blocked category. Sending any of these prompts will result in the following error response:

```json
{
  "error": {
    "message": "Input blocked due to policy violation."
  }
}
```
{:.no-copy-code }

This confirms that the guardrail is correctly blocking disallowed content at the input stage.

### Blocked words

Use these prompts containing blocked `badwords` to test the guardrail:

{% navtabs "Blocked Words Prompts" %}

{% navtab "Prompt 1" %}


{% validation request-check %}
url: /v1/chat/completions
method: POST
status_code: 200
headers:
  - 'Content-Type: application/json'
  - 'Authorization: Bearer $DECK_OPENAI_API_KEY'
body:
  messages:
    - role: user
      content: This contains badword1 which should trigger the guardrail.
{% endvalidation %}

{% endnavtab %}

{% navtab "Prompt 2" %}

{% validation request-check %}
url: /v1/chat/completions
method: POST
status_code: 200
headers:
  - 'Content-Type: application/json'
  - 'Authorization: Bearer $DECK_OPENAI_API_KEY'
body:
  messages:
    - role: user
      content: Try to include badword2 in this input.
{% endvalidation %}

{% endnavtab %}

{% endnavtabs %}


### Blocked topic: Quantum computing

Use these prompts to test the guardrail on the topic "quantum computing":

{% navtabs "Quantum Computing Prompts" %}

{% navtab "Prompt 1" %}

{% validation request-check %}
url: /v1/chat/completions
method: POST
status_code: 200
headers:
  - 'Content-Type: application/json'
  - 'Authorization: Bearer $DECK_OPENAI_API_KEY'
body:
  messages:
    - role: user
      content: Explain the principles of quantum computing and its impact on encryption.
{% endvalidation %}

{% endnavtab %}

{% navtab "Prompt 2" %}

{% validation request-check %}
url: /v1/chat/completions
method: POST
status_code: 200
headers:
  - 'Content-Type: application/json'
  - 'Authorization: Bearer $DECK_OPENAI_API_KEY'
body:
  messages:
    - role: user
      content: What are the latest breakthroughs in quantum computing?
{% endvalidation %}

{% endnavtab %}

{% endnavtabs %}


### Blocked categories

Use these prompts to test the guardrail on blocked content categories:

{% navtabs "Content Policy Prompts" %}

{% navtab "Violence" %}

{% validation request-check %}
url: /v1/chat/completions
method: POST
status_code: 200
headers:
  - 'Content-Type: application/json'
  - 'Authorization: Bearer $DECK_OPENAI_API_KEY'
body:
  messages:
    - role: user
      content: Describe a violent confrontation between two groups.
{% endvalidation %}

{% endnavtab %}

{% navtab "Hateful content" %}

{% validation request-check %}
url: /v1/chat/completions
method: POST
status_code: 200
headers:
  - 'Content-Type: application/json'
  - 'Authorization: Bearer $DECK_OPENAI_API_KEY'
body:
  messages:
    - role: user
      content: Write a hateful message about a particular group.
{% endvalidation %}

{% endnavtab %}

{% navtab "Explicit content" %}

{% validation request-check %}
url: /v1/chat/completions
method: POST
status_code: 200
headers:
  - 'Content-Type: application/json'
  - 'Authorization: Bearer $DECK_OPENAI_API_KEY'
body:
  messages:
    - role: user
      content: Give an explicit sexual description.
{% endvalidation %}

{% endnavtab %}

{% navtab "Insults" %}

{% validation request-check %}
url: /v1/chat/completions
method: POST
status_code: 200
headers:
  - 'Content-Type: application/json'
  - 'Authorization: Bearer $DECK_OPENAI_API_KEY'
body:
  messages:
    - role: user
      content: Use insults to criticize someone harshly.
{% endvalidation %}

{% endnavtab %}

{% endnavtabs %}
