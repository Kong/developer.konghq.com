---
title: Transform a request body using OpenAI in {{site.base_gateway}}
permalink: /how-to/transform-a-client-request-with-ai/
content_type: how_to
related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/

description: Use the AI Request Transformer plugin with OpenAI to transform a client request body before proxying it.

products:
  - ai-gateway
  - gateway

works_on:
    - on-prem
    - konnect

min_version:
  gateway: '3.6'

plugins:
  - ai-request-transformer

entities:
  - service
  - route
  - plugin

tags:
    - ai
    - openai

tldr:
    q: How can I use AI to transform a client request before proxying it?
    a: Enable the [AI Request Transformer](/plugins/ai-request-transformer/) plugin, configure the parameters in `config.llm` to access your LLM and describe the transformation to perform with the `config.prompt` parameter.

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

## Enable the AI Request Transformer plugin

In this example, we expect the client to send requests with a JSON body containing a `city` element. We want to transform this request to add the corresponding `country` before proxying the request to the upstream.

We also want to make sure that the LLM only returns the JSON content and doesn't add extra text around it. There are two ways to do this:
* Include this in the prompt, by adding "Return only the JSON message, no extra text" for example.
* Specify a regex in the [`config.transformation_extract_pattern`](/plugins/ai-request-transformer/reference/#schema--config-transformation-extract-pattern) parameter to extract only the data we need. This is the option we'll use in this example.

Configure the [AI Request Transformer](/plugins/ai-request-transformer) plugin with the required LLM details, the transformation prompt, and the expected request body pattern to extract:
{% entity_examples %}
entities:
  plugins:
    - name: ai-request-transformer
      config:
        prompt: In my JSON message, anywhere there is a JSON tag for a city, also add a country tag with the name of the country that city is in.
        transformation_extract_pattern: '{((.|\n)*)}'
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

To check that the request transformation is working, send a request with a JSON body containing a `city` tag:

{% validation request-check %}
url: /anything
status_code: 200
method: POST
headers:
    - 'Accept: application/json'
    - 'Content-Type: application/json'
body:
  user:
    name: Kong User
    city: London
{% endvalidation %}

In this example, we're using [httpbin.konghq.com/anything](https://httpbin.konghq.com/#/Anything/post_anything) as the upstream. It returns anything that is passed to the request, which means the response contains the transformed request body received by the upstream:
```json
{
   "json":{
      "user":{
         "city":"London",
         "country":"United Kingdom",
         "name":"Kong User"
      }
   }
}
```
{:.no-copy-code}