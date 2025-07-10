---
title: Map Gateway Manager resources in Service Catalog
content_type: how_to
description: Learn how to map Gateway Services from {{site.konnect_short_name}} Gateway Manager in Service Catalog to visualize services across multiple Control Planes.
products:
  - gateway
  - service-catalog
works_on:
  - konnect
automated_tests: false
entities: []
tldr:
  q: How do I map Gateway Services in Service Catalog?
  a: Create a Service Catalog service and associate it with your Gateway Manager resources to visualize Services across multiple Control Planes.
prereqs:
  entities:
    services:
        - example-service
related_resources:
  - text: Gateway Manager integration
    url: /service-catalog/integrations/gateway-manager/
  - text: Service Catalog
    url: /service-catalog/
  - text: Service Catalog integrations
    url: /service-catalog/integrations/
---

## Create a service in Service Catalog

In this tutorial, you'll map Gateway Services from Gateway Manager to a service in Service Catalog. Because the Gateway Manager integration is built-in, you don't need to install or authorize it like other Service Catalog integrations. 

Create a service that you'll map to your Gateway Manager resources:

<!--vale off-->
{% konnect_api_request %}
url: /v1/service-catalog/services
method: POST
status_code: 201
region: us
headers:
  - 'Accept: application/json, application/problem+json'
  - 'Content-Type: application/json'
body:
  name: billing
  display_name: Billing Service
{% endkonnect_api_request %}
<!--vale on-->

Export the Service Catalog service ID:

```sh
export SERVICE_ID='YOUR-SERVICE-ID'
```

## List Gateway Manager resources

Before you can map a resource to Service Catalog, you first need to find the resources that are pulled in from Gateway Manager:

<!--vale off-->
{% konnect_api_request %}
url: /v1/service-catalog/resources?filter%5Bintegration.name%5D=gateway-manager
method: GET
region: us
status_code: 200
headers:
  - 'Accept: application/json, application/problem+json'
  - 'Content-Type: application/json'
{% endkonnect_api_request %}
<!--vale on-->

Export the resource ID you want to map to the service:

```sh
export GATEWAY_MANAGER_RESOURCE_ID='YOUR-RESOURCE-ID'
```

## Map resources to a Service Catalog service

Now, you can map the Gateway Manager resource to the service:

<!--vale off-->
{% konnect_api_request %}
url: /v1/service-catalog/resource-mappings
method: POST
status_code: 201
region: us
headers:
  - 'Accept: application/json, application/problem+json'
  - 'Content-Type: application/json'
body:
  service: $SERVICE_ID
  resource: $ANALYTICS_RESOURCE_ID
{% endkonnect_api_request %}
<!--vale on-->


## Validate the mapping

To confirm that the Gateway Manager resource is now mapped to the intended service, list the service’s mapped resources:

<!--vale off-->
{% konnect_api_request %}
url: /v1/service-catalog/services/$SERVICE_ID/resources
method: GET
status_code: 200
region: global
headers:
  - 'Accept: application/json'
{% endkonnect_api_request %}
<!--vale on-->
