---
title: Gateway Services
content_type: reference
entities:
  - service

description: A Gateway Service represents your actual backend API or microservice.

related_resources:
  - text: Routes entity
    url: /gateway/entities/route/
  - text: Enable rate limiting on a Gateway Service
    url: /how-to/add-rate-limiting-to-a-service-with-kong-gateway/
  - text: Plugins that can be enabled on Gateway Services
    url: /gateway/entities/plugin/#supported-scopes-by-plugin

tools:
    - admin-api
    - konnect-api
    - kic
    - deck
    - terraform

schema:
    api: gateway/admin-ee
    path: /schemas/Service

api_specs:
    - gateway/admin-oss
    - gateway/admin-ee
    - konnect/control-planes-config

---

## What is a Gateway Service?

A Gateway Service represents your actual backend API or microservice.

For simple deployments, the upstream URL can be provided directly in the Service. For sophisticated traffic management needs, a Service can point at an [Upstream](/gateway/entities/upstream/).

Gateway Services, in conjunction with [Routes](/gateway/entities/route/), let you expose your services to clients with {{site.base_gateway}}.

[Plugins](/gateway/entities/plugin/) can be attached to a Service, and will run against every request that triggers a request to the Service that they're attached to.

<!--vale off -->

{% mermaid %}
flowchart LR
  A(API client)
  B("`Route 
  (/mock)`")
  C("`Gateway Service
  (example-service)`")
  D(Upstream 
  application)
  
  A <--requests
  responses--> B
  subgraph id1 ["`
  **KONG GATEWAY**`"]
    B <--requests
    responses--> C
  end
  C <--requests
  responses--> D

  style id1 rx:10,ry:10
  
{% endmermaid %}

<!--vale on -->

## Schema

{% entity_schema %}

## Set up a Gateway Service

{% entity_example %}
type: service
data:
  name: example-service
  url: "http://httpbin.konghq.com"
{% endentity_example %}
