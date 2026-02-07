---
title: Map Gateway Manager Services in Catalog
permalink: /how-to/map-gateway-manager-resources/
content_type: how_to
description: Learn how to map Gateway Services from {{site.konnect_short_name}} Gateway Manager in {{site.konnect_catalog}} to visualize services across multiple Control Planes.
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
  a: Create a {{site.konnect_catalog}} service and associate it with your Gateway Manager resources to visualize Services across multiple Control Planes.
prereqs:
  entities:
    services:
        - example-service
related_resources:
  - text: Gateway Manager integration
    url: /catalog/integrations/gateway-manager/
  - text: "{{site.konnect_catalog}}"
    url: /catalog/
  - text: "{{site.konnect_catalog}} integrations"
    url: /catalog/integrations/
---

## Create a service in {{site.konnect_catalog}}

In this tutorial, you'll map Gateway Services from Gateway Manager to a service in {{site.konnect_catalog}}. Because the Gateway Manager integration is built-in, you don't need to install or authorize it like other {{site.konnect_catalog}} integrations. 

Create a service that you'll map to your Gateway Manager resources:

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

## List Gateway Manager resources

Before you can map a resource to {{site.konnect_catalog}}, you first need to find the resources that are pulled in from Gateway Manager:

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

Now, you can map the Gateway Manager resource to the service:

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

To confirm that the Gateway Manager resource is now mapped to the intended service, list the service’s mapped resources:

<!--vale off-->
{% konnect_api_request %}
url: /v1/catalog-services/$SERVICE_ID/resources
method: GET
status_code: 200
region: global
{% endkonnect_api_request %}
<!--vale on-->
