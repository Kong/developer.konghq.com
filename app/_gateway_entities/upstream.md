---
title: Upstreams
content_type: reference
entities:
  - upstream

tools:
    - admin-api
    - kic
    - deck
    - terraform

description: An upstream refers to the service applications sitting behind Kong Gateway, to which client requests are forwarded.

schema:
    api: gateway/admin-ee
    path: /schemas/Upstream

---

## What is an upstream?

{{page.description}} In {{site.base_gateway}}, an upstream represents a virtual hostname and can be used to health check, circuit break, and load balance incoming requests over multiple [target](/gateway/entities/target/) backend services.

## Use cases for upstreams

The following are examples of common use cases for upstreams:

## Schema

{% entity_schema %}

## Set up an Upstream

{% entity_example %}
type: upstream
data:
    name: api.example.internal
    tags:
      - user-level
      - low-priority
    algorithm: round-robin
{% endentity_example %}
