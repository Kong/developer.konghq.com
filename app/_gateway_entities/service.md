---
title: Gateway Services
content_type: reference
entities:
  - service

description: A Gateway Service is an abstraction of an upstream application that services requests.

related_resources:
  - text: Routes entity
    url: /gateway/entities/route/
  - text: Enable rate limiting on a Gateway Service
    url: /how-to/add-rate-limiting-to-a-service-with-kong-gateway/
  - text: Plugins that can be enabled on Gateway Services
    url: /plugins/scopes/

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
    - text: Gateway Admin - EE
      url: '/api/gateway/admin-ee/#/operations/list-service'
      insomnia_link: 'https://insomnia.rest/run/?label=Gateway%20Admin%20Enterprise%20API&uri=https%3A%2F%2Fraw.githubusercontent.com%2FKong%2Fdeveloper.konghq.com%2Fmain%2Fapi-specs%2FGateway-EE%2Flatest%2Fkong-ee.yaml'
    - text: Gateway Admin - OSS
      url: '/api/gateway/admin-oss/#/operations/list-service'
      insomnia_link: 'https://insomnia.rest/run/?label=Gateway%20Admin%20OSS%20API&uri=https%3A%2F%2Fraw.githubusercontent.com%2FKong%2Fdeveloper.konghq.com%2Fmain%2Fapi-specs%2FGateway-OSS%2Flatest%2Fkong-oss.yaml'
    - text: Konnect Control Planes Config
      url: '/api/konnect/control-planes-config/#/operations/list-service'
      insomnia_link: 'https://insomnia.rest/run/?label=Konnect%20Control%20Plane%20Config&uri=https%3A%2F%2Fraw.githubusercontent.com%2FKong%2Fdeveloper.konghq.com%2Fmain%2Fapi-specs%2FKonnect%2Fcontrol-planes-config%2Fcontrol-planes-config.yaml'

---

## What is a Gateway Service?

{{ page.description }} 
Services can store collections of objects like plugin configurations, and policies, and they can be associated with routes.

When defining a Service, the administrator provides a name and the upstream application connection information. 
The connection details can be provided in the URL field as a single string, or by providing individual values for protocol, host, port, and path individually.

Gateway Services have a one-to-many relationship with upstream applications, which allows administrators to create sophisticated traffic management behaviors.

Gateway Services, in conjunction with [Routes](/gateway/entities/route/), let you expose your services to clients with {{site.base_gateway}}. 
{{site.base_gateway}} abstracts the service from the clients by using Routes. 
Since the client always calls the Route, changes to the Services (like versioning) don't impact how clients make the call. 

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

## Schema

{% entity_schema %}

## Set up a Gateway Service

{% entity_example %}
type: service
data:
  name: example-service
  url: "http://httpbin.konghq.com"
{% endentity_example %}
