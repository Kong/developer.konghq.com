---
title: "AI Models in {{site.konnect_catalog}}"
content_type: reference
layout: reference

products:
    - catalog
    - ai-gateway

breadcrumbs:
  - /catalog/

works_on:
  - konnect

search_aliases:
  - LLM
  - model

description: An AI Model is an interface in {{site.konnect_catalog}} that represents the providers and target models your organization routes requests to. Learn how to create and manage AI Models.

related_resources:
  - text: "{{site.konnect_catalog}}"
    url: /catalog/
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/
---

An AI Model is an interface in {{site.konnect_catalog}} that represents the providers and target models your organization routes requests to, along with the OpenAPI spec that describes how to call it.

You can create an AI Model in two ways:
* Add it manually by defining its providers and target models yourself.
* Import it from {{site.ai_gateway}}, by linking an existing {{site.ai_gateway}} AI Model as the source. This allows teams to discover, understand, and use it securely.

## Create an AI Model

{% navtabs "create-ai-model" %}
{% navtab "{{site.konnect_short_name}} UI" %}
1. In the {{site.konnect_short_name}} sidebar, click **Catalog**.
1. Click the **AI models** tab.
1. From the **New** dropdown menu, select "AI model".
1. Under **Data source**, do one of the following:
   1. To manually define providers and models, select **Add manually**.
   1. To import an existing gateway-defined model, select **Import from AI gateway**, then:
      1. From the **AI gateway** dropdown menu, select your {{site.ai_gateway}} control plane.
      1. From the **Model from AI gateway** dropdown menu, select the model you want to import.
1. (Optional) Under **Target models**, add the providers and models this AI Model routes to:
   1. From the **Provider** dropdown menu, select a provider, for example "OpenAI".
   1. From the **Target model** dropdown menu, select a model, for example "gpt-3.5-turbo".
   1. (Optional) Click **Add target model** to add another provider and target model pair.
1. In the **Display name** field, enter a name for your AI Model, for example `My AI Model`.
1. In the **Name** field, enter a unique identifier for the AI Model, for example `my-ai-model`. This must contain only lowercase letters, numbers, hyphens, and periods.
1. (Optional) In the **Version** field, enter a version for your AI Model.
1. (Optional) In the **Description** field, describe the purpose of your AI Model.
1. (Optional) Click **Show labels**, and do the following:
   1. In the **Key** field, enter a label key.
   1. In the **Value** field, enter a label value.
   1. (Optional) Click **Add another label** to add more labels.
1. Click **Create**.


You can also link AI Models that you've manually created in {{site.konnect_catalog}} to a model on {{site.ai_gateway}} by clicking the **Gateway** tab on a {{site.konnect_catalog}} AI Model's details page and clicking **Link AI gateway**.
{% endnavtab %}
{% navtab "{{site.konnect_short_name}} API" %}
Send a POST request to the `/ai-models` endpoint to create an empty AI Model:
<!--vale off-->
{% konnect_api_request %}
url: /v1/ai-models
status_code: 201
method: POST
body:
    name: my-ai-model
    display_name: My AI Model
    description: Customer support triage model
extract_body:
    - name: 'id'
      variable: AI_MODEL_ID
capture:
  - variable: AI_MODEL_ID
    jq: ".id"
{% endkonnect_api_request %}
<!--vale on-->

Add the providers and target models that this AI Model routes to by sending a POST request to the `/ai-models/{aiModelId}/versions` endpoint:
<!--vale off-->
{% konnect_api_request %}
url: /v1/ai-models/$AI_MODEL_ID/versions
status_code: 201
method: POST
body:
    target_models:
      - provider: openai
        name: gpt-4o
{% endkonnect_api_request %}
<!--vale on-->

Link the AI Model to a model on {{site.ai_gateway}} by sending a POST request to the `/ai-models/{aiModelId}/implementations` endpoint:
<!--vale off-->
{% konnect_api_request %}
url: /v1/ai-models/$AI_MODEL_ID/implementations
status_code: 201
method: POST
body:
    gateway_control_plane_id: $CONTROL_PLANE_ID
    gateway_model_id: $GATEWAY_MODEL_ID
{% endkonnect_api_request %}
<!--vale on-->
{% endnavtab %}
{% endnavtabs %}

## AI Model analytics

When you create an AI Model in {{site.konnect_catalog}}, you can see analytics for that model in addition to the details you configured. 
The analytics you can see are:
* Number of requests
* Error rate
* Token usage
* Estimated cost

These analytics are collected for the past 30 days.