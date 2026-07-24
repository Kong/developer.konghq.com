---
title: Use the AI Custom Guardrail plugin with the Mistral AI Moderation API
permalink: /ai-gateway/use-ai-custom-guardrail-with-mistral-ai/
content_type: how_to

related_resources:
  - text: AI Custom Guardrail
    url: /ai-gateway//policies/ai-custom-guardrail/
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/
description: Learn how to configure the AI Custom Guardrail plugin to use Mistral AI for content moderation

products:
    - ai-gateway

works_on:
    - konnect

min_version:
  ai-gateway: '2.0'

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

---

## Configure an OpenAI model using the Mistral moderation API

```sh
kongctl apply -f - --auto-approve --pat "$KONNECT_TOKEN" <<EOF
_defaults:
  kongctl: { namespace: ai-gateway-get-started }

ai_gateways:
  - ref: ai-quickstart
    _external:
      selector:
        matchFields:
          name: ai-quickstart

ai_gateway_model_providers:
  - ref: generic-openai
    name: generic-openai
    ai_gateway: ai-quickstart
    type: openai
    config:
      auth:
        type: basic
        headers:
          - name: Authorization
            value: !env OPENAI_AUTH_HEADER

ai_gateway_policies:
  - ref: my-ai-custom-guardrail-policy
    name: my-ai-custom-guardrail-policy
    ai_gateway: ai-quickstart
    type: ai-custom-guardrail
    enabled: true
    global: false
    config:
        guarding_mode: BOTH
        text_source: "concatenate_all_content"
      
        params:
          api_key: !env MISTRAL_API_KEY
          model: mistral-moderation-2411
      
        request:
          url: https://api.mistral.ai/v1/moderations
          headers:
            Authorization: "Bearer $(conf.params.api_key)"
          body:
            model: !env MISTRAL_MODEL
            input: "$(content)"
      
        response:
          block: !env check_response_block
          block_message: !env check_response_block_message
      
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
    ai_gateway: ai-quickstart
    type: model
    enabled: true
    formats: [{ type: openai }]
    config:
      route: { paths: [/] }
      model: { name_header: true }
    capabilities: [generate]
    policies: [ !ref my-ai-custom-guardrail-policy#name ]
    targets:
      - name: gpt-4o
        provider: generic-openai
        config:
          type: openai
EOF
```

Enable the [AI Custom Guardrail](/plugins/ai-custom-guardrail/) with the following data:

* The [{{ site.mistral }} Moderation API](https://docs.mistral.ai/capabilities/guardrailing#moderation) URL
* Your {{ site.mistral }} API key
* The {{ site.mistral }} model to use
* The input content to send to the {{ site.mistral }} Moderation API
* The function that defines how to parse the response

In this example, the {{ site.mistral }} Moderation API response contains a `results` array containing a `categories` object with a list of different moderation categories. If the input matches one of the categories, its value will be `true`. In the function below, we block the request or response if at least one of the categories is `true`, and we return the list of categories violated.

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