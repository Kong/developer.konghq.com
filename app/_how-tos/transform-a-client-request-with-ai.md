---
title: Transform a request body using OpenAI in {{site.base_gateway}}
content_type: how_to
related_resources:
  - text: AI Gateway
    url: /ai-gateway/

description: Use the AI Request Transformer plugin with OpenAI to transform a client request body before proxying it.

products:
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
    - ai-gateway

tldr:
    q: How can I use AI to transform a client request before proxying it?
    a: Enable the AI Request Transformer plugin, configure the parameters under `config.llm` to access your LLM and describe the transformation to perform with the `config.prompt` parameter.

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

## 1. Enable the AI Request Transformer plugin

In this example, we expect the client to send requests with a JSON body containing a `city` element. We want to transform this request to add the corresponding `country` before proxying the request to the upstream.

Configure the [AI Request Transformer](/plugins/ai-request-transformer) plugin with the required LLM details and the transformation prompt:
{% entity_examples %}
entities:
  plugins:
    - name: ai-request-transformer
      config:
        prompt: In my JSON message, anywhere there is a JSON tag for a city, also add a country tag with the name of the country that city is in. Return only the JSON message, no extra text.
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
    value: $OPENAI_KEY
{% endentity_examples %}


## 2. Validate

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