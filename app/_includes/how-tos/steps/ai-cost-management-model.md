Create an [AI Model Provider](/ai-gateway/entities/ai-model-provider/) to connect {{site.ai_gateway}} to OpenAI and store your credentials, and an [AI Model](/ai-gateway/entities/ai-model/) that routes requests to that provider.
Requests to the model will produce the spend that the budget tracks:

{% entity_examples %}
ai_gateway_model_providers:
  - ref: generic-openai
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    name: generic-openai
    display_name: "generic-openai"
    type: openai
    config:
      auth:
        type: basic
        headers:
          - name: Authorization
            value: !secret {source: !env OPENAI_AUTH_HEADER}
ai_gateway_models:
  - ref: budget-gpt-4o
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    name: budget-gpt-4o
    display_name: "budget-gpt-4o"
    type: model
    formats:
      - type: openai
    capabilities:
      - generate
    config:
      route:
        paths:
          - /v1
        model:
          body_param: model
          values:
            - budget-gpt-4o
    targets:
      - name: gpt-4o
        provider: generic-openai
        config:
          type: openai
    policies: []
{% endentity_examples %}

{:.info}
> `!env AI_GATEWAY_ID` references the {{site.ai_gateway}} that the quickstart script created in the [prerequisites](#prerequisites), instead of creating a new one.
