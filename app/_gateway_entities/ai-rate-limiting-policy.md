---
title: AI Rate Limiting Policies
content_type: reference
entities:
  - ai_rate_limiting_policy

products:
  - gateway
  - ai-gateway
  
tags:
  - rate-limiting

description: An AI Rate Limiting Policy object allows you to define reusable policies for the AI Rate Limiting Advanced plugin.

related_resources:
  - text: AI Rate Limiting Advanced Plugin
    url: /plugins/ai-rate-limiting-advanced/

tools:
    - admin-api
    - konnect-api
    - kic
    - deck
    - terraform
api_specs:
    - gateway/admin-ee
    - konnect/control-planes-config
schema:
    api: gateway/admin-ee
    path: /schemas/AIRateLimitingPolicy

works_on:
  - on-prem
  - konnect

min_version:
  gateway: '3.14'
---

## What is an AI Rate Limiting Policy?

AI Rate Limiting Policies allow you to define reusable policies for the [AI Rate Limiting Advanced plugin](/plugins/ai-rate-limiting-advanced/). 

This entity is scoped to a specific [Consumer](/gateway/entities/consumer/), [Consumer Group](/gateway/entities/consumer-group/), or [{{site.ai_gateway}} Service](/gateway/entities/service/) using the [`ref_type`](#schema-ref-type) and [`ref_id`](#schema-ref-id) parameters.

You can define multiple policies in a single entity, and reference this entity in multiple AI Rate Limiting Advanced plugin instances using the entity ID in the plugin's [`config.policies.id`](/plugins/ai-rate-limiting-advanced/reference/#schema--config-policies-id) field.


## Set up an AI Rate Limiting Policy

{% entity_example %}
type: ai_rate_limiting_policy
data:
  name: my-policy
  ref_type: consumer
  ref_id: $CONSUMER_ID
  policies:
    - window_type: fixed
      limits:
        - limit: 100
          window_size: 60
        - limit: 1000
          window_size: 3600
{% endentity_example %}

## Schema

{% entity_schema %}
