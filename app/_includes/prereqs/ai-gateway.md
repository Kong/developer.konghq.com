1. To complete this tutorial, make sure you have an [{{site.ai_gateway}}](/ai-gateway/) instance running in {{site.konnect_short_name}}. If you don't have one set up yet, follow the steps below to configure it using decK:

{% capture entities %}
{% entity_examples %}
entities:
  services:
    - name: llm-service
      url: http://localhost:32000

  routes:
    - name: openai-chat
      service:
        name: llm-service
      paths:
        - /chat

  plugins:
    - name: ai-proxy
      config:
        route_type: llm/v1/chat
        model:
          provider: openai
{% endentity_examples %}
{% endcapture %}
{{ entities | indent: 3 }}

1. To validate, you can send a `POST` request to the `/chat` endpoint, using the correct [input format](/plugins/ai-proxy/#input-formats):

<!--vale off-->
{% validation request-check %}
url: /chat
status_code: 200
method: POST
headers:
    - 'Accept: application/json'
    - 'Content-Type: application/json'
    - 'Authorization: Bearer $DECK_OPENAI_API_KEY'
body:
  model: gpt-4
  messages:
  - role: "user"
    content: "Say this is a test!"
{% endvalidation %}
<!--vale on-->