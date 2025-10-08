---
title: Gateway Services
content_type: reference
entities:
  - service

description: |
  Gateway Services represent the upstream services in your system. 
  These applications are the business logic components of your system responsible for responding to requests. 

related_resources:
  - text: Routes entity
    url: /gateway/entities/route/
  - text: Enable rate limiting on a Gateway Service
    url: /how-to/add-rate-limiting-to-a-service-with-kong-gateway/
  - text: Plugins that can be scoped to Gateway Services
    url: /gateway/entities/plugin/#supported-scopes-by-plugin
  - text: Reserved entity names
    url: /gateway/reserved-entity-names/
  - text: "{{site.konnect_short_name}} Control Plane resource limits"
    url: /gateway-manager/control-plane-resource-limits/

tools:
    - admin-api
    - konnect-api
    - kic
    - deck
    - terraform

tags:
  - service-application

search_aliases:
  - upstream service

schema:
    api: gateway/admin-ee
    path: /schemas/Service

api_specs:
    - gateway/admin-ee
    - konnect/control-planes-config

products:
    - gateway

works_on:
  - on-prem
  - konnect
---

## What is a Gateway Service?

Gateway Services represent the upstream services in your system. 
Services are the business logic components of your system that are responsible for processing and responding to requests.
Gateway Services, in conjunction with [Routes](/gateway/entities/route/), let you expose your upstream services to clients with {{site.base_gateway}}.

The configuration of a Gateway Service defines the connectivity details between the {{site.base_gateway}} and the upstream service, along with other metadata. 
Generally, you should map one Gateway Service to each upstream service.

Here's how it works:
1. A client sends a request.
1. A [Route](/gateway/entities/route/) matches the request based on defined rules and sends it to a specific Gateway Service.
1. The Gateway Service receives the request and forwards it to your actual application (the upstream service).
   * For simple deployments, the upstream URL can be provided directly in the Gateway Service.
   * For sophisticated traffic management needs, a Gateway Service can point at an [Upstream](/gateway/entities/upstream/) entity.
1. The upstream service processes the request and sends a response back through {{site.base_gateway}}.

[Plugins](/gateway/entities/plugin/) can also be attached to a Service, and will run against every request that triggers a request to the Service that they're attached to.

<!--vale off -->

{% mermaid %}
flowchart LR
  A(API client)
  B("`Route 
  (/mock)`")
  C("`Gateway Service
  (example-service)`")
  D(Service 
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
 _Figure 1: Diagram showing the request and response flow through {{site.base_gateway}}._

<!--vale on -->

## Gateway Service timeouts

Timeouts are configured at the Service level and influence retry behavior when failures occur.

### Connect timeout

The [`connect_timeout`](#schema-service-connect-timeout) parameter defines the time allowed to establish a TCP connection to the upstream server. If the connection can't be opened, it fails at the socket-setup layer. {{site.base_gateway}} returns a `502 Bad Gateway` response and retries the request up to the number of retries that are configured with the [`retries`](#schema-service-retries) parameter.

### Read timeout

The [`read_timeout`](#schema-service-read-timeout) parameter defines the time that the {{site.base_gateway}} waits for the upstream to send a full response after establishing a connection. If the upstream stalls, {{site.base_gateway}} triggers the timeout once the idle time exceeds the configured value and returns a `504 Gateway Time-out` response. 

{% capture retry %}
The retry behavior depends on the method used:

* Idempotent methods (`GET`, `HEAD`, `PUT`, `DELETE`, `OPTIONS`, and `TRACE`): {{site.base_gateway}} retries the request up to the number of retries configured with the [`retries`](#schema-service-retries) parameter.
* Non-idempotent methods (`POST`, `PATCH`, `LOCK`, `UNLOCK`, `PROPPATCH`, `MKCOL`, `MOVE`, and `COPY`): {{site.base_gateway}} will not retry unless [`proxy_next_upstream non_idempotent`](https://nginx.org/en/docs/http/ngx_http_proxy_module.html#proxy_next_upstream) is set in the NGINX configuration by default.
{% endcapture %}

{{ retry }}

### Write timeout

The [`write_timeout`](#schema-service-write-timeout) parameter defines the idle time between successive write operations when sending a request body to the upstream. It measures gaps in data transmission, not the total upload duration. The timer resets after each successful write. The timeout triggers if the upstream accepts the connection but delays receiving the body at the TCP level. {{site.base_gateway}} returns a `504 Gateway Time-out` response. 

{{ retry }}

## Schema

{% entity_schema %}

## Set up a Gateway Service

{% entity_example %}
type: service
data:
  name: example-service
  url: "http://httpbin.konghq.com"
{% endentity_example %}
