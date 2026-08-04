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
        access_key_id: ${key_id}
        secret_access_key: ${access_key}
variables:
  key_id:
    value: $AWS_ACCESS_KEY_ID
    description: Your AWS access key ID.
  access_key:
    value: $AWS_SECRET_ACCESS_KEY
    description: Your AWS secret access key.
{% endentity_example %}

## Authentication with AWS

For {{ provider.name }}, set `auth` to `sagemaker` and provide static IAM user credentials under `aws`, or omit them to fall back to the default AWS credentials provider chain (EC2 instance profiles, environment variables, and so on):

* **`access_key_id`** (optional): AWS access key ID for static IAM user credentials. Overrides the `AWS_ACCESS_KEY_ID` environment variable.
* **`secret_access_key`** (optional): AWS secret access key paired with `access_key_id`. Overrides the `AWS_SECRET_ACCESS_KEY` environment variable.
* **`session_token`** (optional): AWS session token for temporary credentials. Overrides the `AWS_SESSION_TOKEN` environment variable.

{{ provider.name }} can also use `basic` auth instead. See [Outbound authentication](/ai-gateway/entities/ai-model-provider/#outbound-authentication) on the AI Model Provider entity page for the full list of `auth` types.

## Configure a model target for {{ provider.name }}

{:.info}
> Only the `generate` capability is supported for {{ provider.name }} targets.

A [target](/ai-gateway/entities/ai-model/#targets) is an entry in the `targets` array on the AI Model entity, not the AI Model Provider. The target `name` is the name of your SageMaker endpoint. Beyond the common target options (`name`, `provider`, `weight`), a target routing to {{ provider.name }} supports these `config` fields, grouped under `aws` and `target`:

{% table %}
columns:
  - title: Field
    key: field
  - title: Description
    key: description
rows:
  - field: "`aws.region`"
    description: "The AWS region hosting the SageMaker endpoint. Overrides the `AWS_REGION` environment variable."
  - field: "`aws.assume_role_arn`"
    description: "IAM role ARN to assume for temporary credentials. Requires `aws.role_session_name`."
  - field: "`aws.role_session_name`"
    description: "Session name for the assumed role. Required if `aws.assume_role_arn` is set."
  - field: "`aws.sts_endpoint_url`"
    description: "Custom STS endpoint used when assuming a role."
  - field: "`target.model`"
    description: "The model artifact to invoke on a multi-model endpoint. Sets the `X-Amzn-SageMaker-Target-Model` header."
  - field: "`target.variant`"
    description: "The production variant to invoke on a multi-variant endpoint. Sets the `X-Amzn-SageMaker-Target-Variant` header."
  - field: "`target.container_hostname`"
    description: "The container hostname to invoke on a multi-container endpoint. Sets the `X-Amzn-SageMaker-Target-Container-Hostname` header."
{% endtable %}

All fields in this table are optional.

```yaml
targets:
  - name: my-sagemaker-endpoint
    provider: my-sagemaker-account
    config:
      type: sagemaker
      aws:
        region: us-east-1
      target:
        model: my-model.tar.gz
        variant: production-variant-1
        container_hostname: container-1
```
