---
title: Map {{site.observability}} reports in Catalog
permalink: /how-to/map-analytics-resources/
content_type: how_to
description: Learn how to map {{site.konnect_short_name}} {{site.observability}} resources in {{site.konnect_catalog}} to visualize {{site.observability}} Reports.
products:
  - catalog
works_on:
  - konnect
entities: []
search_aliases:
  - service catalog
  - konnect analytics
tldr:
  q: How do I map {{site.observability}} reports in {{site.konnect_catalog}}?
  a: Create a {{site.konnect_catalog}} service and associate it with your {{site.konnect_short_name}} Analytics resources to visualize {{site.observability}} Reports.
prereqs:
  inline:
    - title: "{{site.observability}} reports"
      content: |
        You'll need a [{{site.observability}} report](https://cloud.konghq.com/analytics/reports) to ingest in {{site.konnect_catalog}} as resources.
      icon_url: /assets/icons/analytics.svg
related_resources:
  - text: "{{site.observability}} integration"
    url: /catalog/integrations/observability/
  - text: "{{site.konnect_catalog}}"
    url: /catalog/
  - text: "{{site.konnect_catalog}} integrations"
    url: /catalog/integrations/
---

## Create a service in {{site.konnect_catalog}}

In this tutorial, you'll map Reports from {{site.observability}} to a service in {{site.konnect_catalog}}. Because the {{site.observability}} integration is built-in, you don't need to install or authorize it like other {{site.konnect_catalog}} integrations. 

Create a service that you'll map to your {{site.observability}} resources:

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

## List {{site.observability}} resources

Before you can map a resource to {{site.konnect_catalog}}, you first need to find the resources that are pulled in from {{site.observability}}:

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

## Map resources to a {{site.konnect_catalog}} service

Now, you can map the {{site.observability}} resource to the service:

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

To confirm that the {{site.observability}} resource is now mapped to the intended service, list the service’s mapped resources:

<!--vale off-->
{% konnect_api_request %}
url: /v1/catalog-services/$SERVICE_ID/resources
method: GET
status_code: 200
region: global
{% endkonnect_api_request %}
<!--vale on-->