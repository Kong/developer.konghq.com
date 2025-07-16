---
title: Map {{site.konnect_short_name}} Analytics reports in Service Catalog
content_type: how_to
description: Learn how to map {{site.konnect_short_name}} Analytics resources in Service Catalog to visualize Analytics Reports.
products:
  - gateway
  - service-catalog
works_on:
  - konnect
entities: []
tldr:
  q: How do I map {{site.konnect_short_name}} Analytics reports in Service Catalog?
  a: Create a Service Catalog service and associate it with your {{site.konnect_short_name}} Analytics resources to visualize Analytics Reports.
prereqs:
  inline:
    - title: "{{site.konnect_short_name}} Analytics reports"
      content: |
        You'll need a [{{site.konnect_short_name}} Analytics report](https://cloud.konghq.com/analytics/reports) to ingest in Service Catalog as resources.
      icon_url: /assets/icons/analytics.svg
related_resources:
  - text: "{{site.konnect_short_name}} Analytics integration"
    url: /service-catalog/integrations/konnect-analytics/
  - text: Service Catalog
    url: /service-catalog/
  - text: Service Catalog integrations
    url: /service-catalog/integrations/
---

## Create a service in Service Catalog

In this tutorial, you'll map Reports from {{site.konnect_short_name}} Analytics to a service in Service Catalog. Because the {{site.konnect_short_name}} Analytics integration is built-in, you don't need to install or authorize it like other Service Catalog integrations. 

Create a service that you'll map to your {{site.konnect_short_name}} Analytics resources:

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

## List {{site.konnect_short_name}} Analytics resources

Before you can map a resource to Service Catalog, you first need to find the resources that are pulled in from {{site.konnect_short_name}} Analytics:

<!--vale off-->
{% konnect_api_request %}
url: /v1/resources?filter%5Bintegration.name%5D=analytics
method: GET
region: us
status_code: 200
{% endkonnect_api_request %}
<!--vale on-->

Export the resource ID you want to map to the service:

```sh
export ANALYTICS_RESOURCE_ID='YOUR-RESOURCE-ID'
```

## Map resources to a Service Catalog service

Now, you can map the {{site.konnect_short_name}} Analytics resource to the service:

<!--vale off-->
{% konnect_api_request %}
url: /v1/resource-mappings
method: POST
status_code: 201
region: us
body:
  service: $SERVICE_ID
  resource: $ANALYTICS_RESOURCE_ID
{% endkonnect_api_request %}
<!--vale on-->

## Validate the mapping

To confirm that the {{site.konnect_short_name}} Analytics resource is now mapped to the intended service, list the service’s mapped resources:

<!--vale off-->
{% konnect_api_request %}
url: /v1/catalog-services/$SERVICE_ID/resources
method: GET
status_code: 200
region: global
{% endkonnect_api_request %}
<!--vale on-->