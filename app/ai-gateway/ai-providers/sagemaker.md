---
title: "Amazon SageMaker provider"
layout: reference
content_type: reference
description: Reference for supported capabilities for Amazon SageMaker provider
breadcrumbs:
  - /ai-gateway/
  - /ai-gateway/ai-providers/

permalink: /ai-gateway/ai-providers/sagemaker/

works_on:
 - konnect

products:
  - ai-gateway

tools:
  - konnect-api
  - kongctl

tags:
  - ai

min_version:
  ai-gateway: '2.0'

related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/
  - text: "{{site.ai_gateway}} Policies"
    url: /ai-gateway/policies/
  - text: AI Providers
    url: /ai-gateway/ai-providers/
  - text: AI Model Provider entity
    url: /ai-gateway/entities/ai-model-provider/
  - text: AI Model entity
    url: /ai-gateway/entities/ai-model/

---


{% include md/ai-gateway/v2/providers.md providers=site.data.ai-gateway.v2.providers provider_name="Amazon SageMaker" %}

{% include md/ai-gateway/v2/native-routes.md providers=site.data.ai-gateway.v2.providers provider_name="Amazon SageMaker" %}

## Configure {{ provider.name }}

To use {{ provider.name }} with {{site.ai_gateway}}, configure a new [AI Model Provider](/ai-gateway/entities/ai-model-provider/). You can then access supported [AI Models](/ai-gateway/entities/ai-model/) from {{ provider.name }}.

Here's a minimal configuration for chat completions:

{% entity_example %}
type: model-provider
data:
  display_name: SageMaker Production
  name: my-sagemaker-account
  type: sagemaker
  config:
    auth:
      type: sagemaker
      aws:
        access_key_id: $AWS_ACCESS_KEY_ID
        secret_access_key: $AWS_SECRET_ACCESS_KEY
{% endentity_example %}

{% include md/ai-gateway/v2/aws-auth.md %}

## Configure a model target for {{ provider.name }}

Only the `llm/v1/chat` route type is supported for {{ provider.name }} targets.

A [target](/ai-gateway/entities/ai-model/#targets) is an entry in the `targets` array on the AI Model entity, not the AI Model Provider. The target `name` is the name of your SageMaker endpoint. Beyond the common target options (`name`, `provider`, `weight`), a target routing to {{ provider.name }} supports these `config` fields for multi-model, multi-variant, and multi-container endpoints:

* **`region`**: The AWS region hosting the SageMaker endpoint.
* **`target_model`** (optional): The model artifact to invoke on a multi-model endpoint.
* **`target_variant`** (optional): The production variant to invoke on a multi-variant endpoint.
* **`target_container_hostname`** (optional): The container hostname to invoke on a multi-container endpoint.

```yaml
targets:
  - name: my-sagemaker-endpoint
    provider: my-sagemaker-account
    config:
      type: sagemaker
      region: us-east-1
      target_model: my-model.tar.gz
      target_variant: production-variant-1
      target_container_hostname: container-1
```
