---
title: Map API Gateway Services in Catalog
content_type: how_to
description: Learn how to map Gateway Services from {{site.konnect_short_name}} API Gateway in {{site.konnect_catalog}} to visualize services across multiple Control Planes.
products:
  - gateway
  - catalog
tools:
  - deck
works_on:
  - konnect
entities: 
  - service
search_aliases:
  - service catalog
tldr:
  q: How do I map Gateway Services in {{site.konnect_catalog}}?
  a: Create a {{site.konnect_catalog}} service and associate it with your API Gateway resources to visualize Services across multiple Control Planes.
prereqs:
  entities:
    services:
        - example-service
related_resources:
  - text: API Gateway integration
    url: /catalog/integrations/api-gateway/
  - text: "{{site.konnect_catalog}}"
    url: /catalog/
  - text: "{{site.konnect_catalog}} integrations"
    url: /catalog/integrations/
---

## Create a service in {{site.konnect_catalog}}

In this tutorial, you'll map Gateway Services from API Gateway to a service in {{site.konnect_catalog}}. Because the API Gateway integration is built-in, you don't need to install or authorize it like other {{site.konnect_catalog}} integrations. 

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

Export the {{site.konnect_catalog}} service ID:

```sh
export SERVICE_ID='YOUR-SERVICE-ID'
```

## List API Gateway resources

Before you can map a resource to {{site.konnect_catalog}}, you first need to find the resources that are pulled in from API Gateway:

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

## Map resources to a {{site.konnect_catalog}} service

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
