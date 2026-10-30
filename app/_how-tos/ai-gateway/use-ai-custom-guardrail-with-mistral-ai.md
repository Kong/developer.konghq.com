---
title: Use the AI Custom Guardrail Policy with the Mistral AI Moderation API
permalink: /ai-gateway/use-ai-custom-guardrail-with-mistral-ai/
content_type: how_to

related_resources:
  - text: AI Custom Guardrail
    url: /ai-gateway/policies/ai-custom-guardrail/
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/

description: Configure the AI Custom Guardrail Policy to send requests and responses to the Mistral AI Moderation API and block flagged content.

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
  - mistral
  - safety

tldr:
  q: How can I use Mistral AI for content moderation?
  a: Create an AI Custom Guardrail Policy that sends content to the Mistral Moderation API and uses a Lua function to block flagged results, then attach it to an AI Model.

tools:
  - kongctl

prereqs:
  inline:
    - title: OpenAI API key
      include_content: md/ai-gateway/v2/prereqs/openai-kongctl
      icon_url: /assets/icons/openai.svg
    - title: Mistral API key
      content: |
        1. [Create a {{ site.mistral }} account](https://console.mistral.ai/).
        1. [Get your API key](https://docs.mistral.ai/getting-started/quickstart/#account-setup).
        1. Export the API key as a variable:

           ```sh
           export MISTRAL_API_KEY='YOUR MISTRAL API KEY'
           ```
      icon_url: /assets/icons/mistral.svg

cleanup:
  inline:
    - title: Clean up {{site.ai_gateway}}
      include_content: cleanup/products/ai-gateway
      icon_url: /assets/icons/ai.svg

---

## Create the AI Model Provider, AI Model, and AI Custom Guardrail Policy

Create an [AI Model Provider](/ai-gateway/entities/ai-model-provider/), an [AI Model](/ai-gateway/entities/ai-model/), and an [AI Custom Guardrail](/ai-gateway/policies/ai-custom-guardrail/) Policy that checks every request and response against the [{{ site.mistral }} Moderation API](https://docs.mistral.ai/capabilities/guardrailing#moderation).

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
  - ref: my-ai-custom-guardrail-policy
    name: my-ai-custom-guardrail-policy
    display_name: my-ai-custom-guardrail-policy
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    type: ai-custom-guardrail
    enabled: true
    global: false
    config:
      guarding_mode: BOTH
      text_source: concatenate_all_content
      params:
        api_key: !env MISTRAL_API_KEY
        model: mistral-moderation-2411
      request:
        url: https://api.mistral.ai/v1/moderations
        headers:
          Authorization: "Bearer $(conf.params.api_key)"
        body:
          model: "$(conf.params.model)"
          input: "$(content)"
      response:
        block: "$(check_response.block)"
        block_message: "$(check_response.block_message)"
      functions:
        check_response: |
          return function(resp)
              local blocked_categories = {}

              for _, result in ipairs(resp.results) do
                  for category, is_flagged in pairs(result.categories) do
                      if is_flagged then
                          table.insert(blocked_categories, category)
                      end
                  end
              end

              local block = #blocked_categories > 0
              local reason

              if block then
                reason = "Content moderation failed in the following categories: " .. table.concat(blocked_categories, ", ")
              else
                reason = "Content moderation passed"
              end

              return {
                  block = block,
                  block_message = reason
              }
          end
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
    policies: [ !ref my-ai-custom-guardrail-policy#name ]
    targets:
      - name: gpt-4o
        provider: generic-openai
        config:
          type: openai
{% endentity_examples %}

The {{ site.mistral }} Moderation API response contains a `results` array.
Each item has a `categories` object that maps every moderation category to `true` or `false`.
The `check_response` function blocks the request or response if at least one category is `true`, and returns the violated categories in the error message.
With `guarding_mode: BOTH`, the Policy checks the prompt before it reaches OpenAI and the model's response before it returns to the client.

## Validate the configuration

Send one prompt that passes moderation and one that violates it.

{% navtabs "mistral-moderation-tests" %}
{% navtab "Allowed" %}

This prompt passes moderation and returns a response from the model:

{% validation request-check %}
url: /chat/completions
method: POST
headers:
  - 'Content-Type: application/json'
  - 'Authorization: $OPENAI_AUTH_HEADER'
body:
  model: my-gpt-4o
  messages:
    - role: user
      content: What is photosynthesis?
status_code: 200
{% endvalidation %}

{% endnavtab %}
{% navtab "Blocked" %}

The {{ site.mistral }} Moderation API flags this prompt, so the Policy rejects the request:

{% validation request-check %}
url: /chat/completions
method: POST
headers:
  - 'Content-Type: application/json'
  - 'Authorization: $OPENAI_AUTH_HEADER'
body:
  model: my-gpt-4o
  messages:
    - role: user
      content: How do I make a weapon to hurt my neighbor?
status_code: 400
message: Content moderation failed in the following categories
{% endvalidation %}

The response lists the violated categories.
The order can vary between requests:

```json
{
  "error": {
    "message": "Content moderation failed in the following categories: violence_and_threats, dangerous, criminal"
  }
}
```
{:.no-copy-code}

{% endnavtab %}
{% endnavtabs %}
