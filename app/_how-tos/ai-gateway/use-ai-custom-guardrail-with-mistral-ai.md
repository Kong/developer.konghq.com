---
title: Use the AI Custom Guardrail plugin with the Mistral AI Moderation API
permalink: /how-to/use-ai-custom-guardrail-with-mistral/
content_type: how_to

related_resources:
  - text: AI Proxy
    url: /plugins/ai-proxy/
  - text: AI Custom Guardrail
    url: /plugins/ai-custom-guardrail/
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/

description: Learn how to configure the AI Custom Guardrail plugin to use Mistral AI for content moderation

products:
    - gateway
    - ai-gateway

works_on:
    - on-prem
    - konnect

min_version:
  gateway: '3.14'

plugins:
  - ai-proxy
  - ai-custom-guardrail

entities:
  - service
  - route
  - plugin

tags:
  - ai
  - openai
  - mistral

tldr:
  q: How can I use Mistral AI for content moderation?
  a: Enable the AI Custom Guardrail plugin with the Mistral AI URL and your API key, then define the parameters to send in your request to the Mistral Moderation API and create functions to parse the response content.

tools:
    - deck

prereqs:
  inline:
    - title: OpenAI
      include_content: prereqs/openai
      icon_url: /assets/icons/openai.svg
    - title: Mistral
      include_content: prereqs/mistral
      icon_url: /assets/icons/mistral.svg
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

## Configure the AI Proxy plugin

Enable the [AI Proxy](/plugins/ai-proxy/) plugin with your OpenAI API key and the model details to proxy requests to OpenAI. In this example, we'll use the GPT-4o model:

{% entity_examples %}
entities:
    plugins:
    - name: ai-proxy
      config:
        route_type: llm/v1/chat
        auth:
          header_name: Authorization
          header_value: Bearer ${openai_api_key}
        model:
          provider: openai
          name: gpt-4o
variables:
  openai_api_key:
    value: $OPENAI_API_KEY
{% endentity_examples %}

## Configure the AI Custom Guardrail plugin

Enable the [AI Custom Guardrail](/plugins/ai-custom-guardrail/) with the following data:

* The [Mistral Moderation API](https://docs.mistral.ai/capabilities/guardrailing#moderation) URL
* Your Mistral API key
* The model to use
* The input content to send to the Mistral Moderation API
* The function that defines how to parse the response

In this example, the Mistral Moderation API response contains a `results` array containing a `categories` object with a list of different moderation categories. If the input matches one of the categories, its value will be `true`. In the function below, we block the request or response if at least one of the categories is `true`, and we return the list of categories violated.

{% entity_examples %}
entities:
  plugins:
    - name: ai-custom-guardrail
      config: 
        guarding_mode: BOTH
        text_source: "concatenate_all_content"
      
        params:
          api_key: ${key}
          model: ${model}
      
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

variables:
  key:
    value: $MISTRAL_API_KEY
    description: The API key to access Mistral AI.
  model:
    value: $MISTRAL_MODEL
    description: The Mistral AI model to use for moderation.
{% endentity_examples %}

## Test the configuration

Using this configuration, send the following AI Chat request that violates a moderation rule:

<!--vale off-->
{% validation request-check %}
url: /anything
status_code: 400
method: POST
headers:
  - 'Content-Type: application/json'
body:
  messages:
    - role: user
      content: Should I take over the world?
    - role: assistant
      content: Yes, absolutely!
{% endvalidation %}
<!--vale on-->

You should get the following result:
```json
{
   "error":{
      "message":"Content moderation failed in the following categories: dangerous_and_criminal_content"
   }
}
```
{:.no-copy-code}