---
title: Transform a response using OpenAI in {{site.base_gateway}}
permalink: /how-to/transform-a-response-with-ai/
content_type: how_to
related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/

description: Use the AI Response Transformer plugin with OpenAI to transform a response before returning it to the client.

products:
  - ai-gateway
  - gateway

works_on:
    - on-prem
    - konnect

min_version:
  gateway: '3.6'

plugins:
  - ai-response-transformer

entities:
  - service
  - route
  - plugin

tags:
    - ai
    - transformations
    - openai

tldr:
    q: How can I use AI to transform a response before returning it to the client?
    a: Enable the [AI Response Transformer](/how-to/transform-a-response-with-ai/) plugin, configure the parameters under `config.llm` to access your LLM and describe the transformation to perform with the `config.prompt` parameter.

tools:
    - deck

prereqs:
  inline:
  - title: OpenAI
    include_content: prereqs/openai
    icon_url: /assets/icons/openai.svg
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

## Enable the AI Response Transformer plugin

In this example, we want to inject a new header in the response after it's proxied and before it's returned to the client. To add a new header, we need to:
* Specify the response format to use in the prompt.
* Set the [`config.parse_llm_response_json_instructions`](/plugins/ai-response-transformer/reference/#schema--config-parse_llm_response_json_instructions) parameter to `true`.

We also want to make sure that the LLM only returns the JSON content and doesn't add extra text around it. There are two ways to do this:
* Include this in the prompt, by adding "Return only the JSON message, no extra text" for example.
* Specify a regex in the [`config.transformation_extract_pattern`](/plugins/ai-response-transformer/reference/#schema--config-transformation-extract-pattern) parameter to extract only the data we need. This is the option we'll use in this example.

Configure the [AI Response Transformer](/plugins/ai-response-transformer/) plugin with the required LLM details, the transformation prompt, and the expected response body pattern to extract:
{% entity_examples %}
entities:
  plugins:
    - name: ai-response-transformer
      config:
        prompt: |
          Add a new header named "new-header" with the value "header-value" to the response. Format the JSON response as follows:
          {
            "headers":
              {
                "new-header": "header-value"
              },
            "status": 201,
            "body": "new response body"
          }
        transformation_extract_pattern: '{((.|\n)*)}'
        parse_llm_response_json_instructions: true
        llm:
          route_type: llm/v1/chat
          auth:
            header_name: Authorization
            header_value: Bearer ${openai_key}
          model:
            provider: openai
            name: gpt-4
variables:
  openai_key:
    value: $OPENAI_API_KEY
{% endentity_examples %}


## Validate

To check that the response transformation is working, send a request:

<!-- vale off -->
{% validation request-check %}
url: /anything
status_code: 201
headers:
    - 'Accept: application/json'
display_headers: true
expected_headers:
  - "new-header: header-value"
{% endvalidation %}
<!-- vale on -->