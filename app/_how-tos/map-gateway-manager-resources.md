---
title: Map Gateway Services to Gateway Manager
content_type: how_to
description: Learn how to map Gateway Services from {{site.konnect_short_name}} Gateway Manager to visualize services across multiple Control Planes
permalink: /service-catalog/integration/map-gateway-manager-resources/
products:
  - gateway
  - service-catalog
works_on:
  - konnect
automated_tests: false
entities: []
tldr:
  q: How do I map Gateway Services using the Gateway Manager Service Catalog integration
  a: Install the Datadog integration in {{site.konnect_short_name}}, authorize it using your API and app keys, and link Datadog resources to your Service Catalog service.
prereqs:
  entities:
    services:
        - example-service
    routes:
        - example-route
related_resources:
  - text: Service Catalog
    url: /service-catalog/
  - text: Service Catalog integrations
    url: /service-catalog/integrations/

---

## Create a service in Service Catalog

Create a service to map to your resources

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

## List resources

Before you can map a Gateway Manager Service to a Service Catalog service, you have to obtain the UUID for the Gateway Manager Service: 



## List resources

Before you can map a resource to Gateway Manager, you need to obtain the `id` of the resource from [Analytics](/service-catalog/integrations/konnect-analytics/):

<!--vale off-->
{% konnect_api_request %}
url: /v1/service-catalog/resources?filter%5Bintegration.name%5D=analytics
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
export ANALYTICS_RESOURCE_ID='YOUR-RESOURCE-ID'
```

## Map resources to a service

Now, you can map a resource to the service you created

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
