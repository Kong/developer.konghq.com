---
title: Services
name: Service
entities:
  - service

description: In Kong Gateway, a service is an abstraction of an existing upstream application.

related_resources:
  - text: Routes entity
    url: /gateway/entities/route/
  - text: Enable rate limiting on a service with Kong Gateway
    url: /how-tos/add-rate-limiting-to-a-service-with-kong-gateway/

tools:
    - admin-api
    - konnect-api
    - kic
    - deck
    - ui
    - terraform
---

## What is a service?

{{ page.description }} Services can store collections of objects like plugin configurations, and policies, and they can be associated with routes.

When defining a service, the administrator provides a name and the upstream application connection information. The connection details can be provided in the url field as a single string, or by providing individual values for protocol, host, port, and path individually.

Services have a one-to-many relationship with upstream applications, which allows administrators to create sophisticated traffic management behaviors.

Services, in conjunction with [routes](/gateway/entities/route/), let you expose your services to clients with {{site.base_gateway}}. {{site.base_gateway}} abstracts the service from the clients by using routes. Since the client always calls the route, changes to the services (like versioning) don’t impact how clients make the call. Routes also allow the same service to be used by multiple clients and apply different policies based on the route used.

{% mermaid %}
flowchart LR
  A(API client)
  B("`Route 
  (/mock)`")
  C("`Service
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

{% contentfor setup_entity %}
{% entity_example %}
type: service
data:
  name: example-service
  url: "http://httpbin.org"
{% endentity_example %}
{% endcontentfor %}
