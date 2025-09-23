---
title: Map API Gateway Services in Service Catalog
content_type: how_to
description: Learn how to map API Gateway Services from {{site.konnect_short_name}} to a service in Service Catalog to visualize services across multiple control planes.
products:
  - gateway
  - service-catalog
tools:
  - deck
works_on:
  - konnect
entities: 
  - service
tldr:
  q: How do I map Gateway Services in Service Catalog?
  a: Create a Service Catalog service and associate it with your API Gateway resources to visualize Services across multiple control planes.
prereqs:
  entities:
    services:
        - example-service
related_resources:
  - text: API Gateway integration
    url: /service-catalog/integrations/gateway-manager/
  - text: Service Catalog
    url: /service-catalog/
  - text: Service Catalog integrations
    url: /service-catalog/integrations/
---

## Create a service in Service Catalog

In this tutorial, you'll map API Gateway Services from {{site.konnect_short_name}} to a service in Service Catalog. Because the API Gateway integration is built-in, you don't need to install or authorize it like other Service Catalog integrations. 

Create a service that you'll map to your API Gateway resources:

<!--vale off-->
{% konnect_api_request %}
url: /v1/catalog-services
method: POST
status_code: 201
region: us
body:
  name: billing
  display_name: Billing Service
{% endkonnect_api_request %}
<!--vale on-->

Export the Service Catalog service ID:

```sh
export SERVICE_ID='YOUR-SERVICE-ID'
```

## List API Gateway resources

Before you can map a resource to Service Catalog, you first need to find the resources that are pulled in from API Gateway:

<!--vale off-->
{% konnect_api_request %}
url: /v1/resources?filter%5Bintegration.name%5D=gateway-manager
method: GET
region: us
status_code: 200
{% endkonnect_api_request %}
<!--vale on-->

Export the resource ID you want to map to the service:

```sh
export GATEWAY_MANAGER_RESOURCE_ID='YOUR-RESOURCE-ID'
```

## Map resources to a Service Catalog service

Now, you can map the API Gateway resource to the service:

<!--vale off-->
{% konnect_api_request %}
url: /v1/resource-mappings
method: POST
status_code: 201
region: us
body:
  service: $SERVICE_ID
  resource: $GATEWAY_MANAGER_RESOURCE_ID
{% endkonnect_api_request %}
<!--vale on-->


## Validate the mapping

To confirm that the API Gateway resource is now mapped to the intended service, list the service’s mapped resources:

<!--vale off-->
{% konnect_api_request %}
url: /v1/catalog-services/$SERVICE_ID/resources
method: GET
status_code: 200
region: global
{% endkonnect_api_request %}
<!--vale on-->
