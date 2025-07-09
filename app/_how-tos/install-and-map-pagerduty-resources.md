---
title: Import and map PagerDuty resources in Service Catalog
content_type: how_to
description: Learn how to connect PagerDuty services to your {{site.konnect_catalog}} service in {{site.konnect_short_name}}.
products:
  - service-catalog
  - gateway
works_on:
  - konnect
tags:
  - integrations
  - pagerduty
related_resources:
  - text: Catalog
    url: /service-catalog/
  - text: PagerDuty reference
    url: /service-catalog/integrations/pagerduty/
tldr:
  q: How do I view PagerDuty services in Service Catalog?
  a: Install the PagerDuty integration in {{site.konnect_short_name}} and authorize it with both read and write scopes. Create a Service Catalog service and associate it with your PagerDuty services to display metadata and enable event tracking. 
prereqs:
  inline:
    - title: PagerDuty access
      content: |
        You need a [PagerDuty account](https://app.pagerduty.com/) with a PagerDuty service you want to pull in to {{site.konnect_short_name}}.
      icon_url: /assets/icons/pagerduty.svg
---

## Authenticate the PagerDuty integration

1. From the **Service Catalog** in {{site.konnect_short_name}}, select **[Integrations](https://cloud.konghq.com/us/service-catalog/integrations)**. 
2. Click **PagerDuty**, and then click **Add PagerDuty Instance**.
3. Configure the region, grant authorization, and name the instance. 
   PagerDuty will ask you to grant consent to {{site.konnect_short_name}}. **Both Read and Write scopes are required.**

Once authorized, resources from your PagerDuty account will be discoverable in the UI.

## Create a service in Service Catalog

Create a service that you'll map to your PagerDuty resources:

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

Export the service ID:

```sh
export PAGERDUTY_SERVICE_ID='YOUR-SERVICE-ID'
```

## List PagerDuty resources

Before you can map your PagerDuty resources to a service in Service Catalog, you first need to find the resources that are pulled in from PagerDuty:

<!--vale off-->
{% konnect_api_request %}
url: /v1/service-catalog/resources?filter%5Bintegration.name%5D=pagerduty
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
export PAGERDUTY_RESOURCE_ID='YOUR-RESOURCE-ID'
```

## Map resources to a service

Now, you can map the PagerDuty resource to the service:

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
  service: billing
  resource: $PAGERDUTY_RESOURCE_ID
{% endkonnect_api_request %}
<!--vale on-->


## Validate the mapping

To confirm that the PagerDuty resource is now mapped to the intended service, list the service’s mapped resources:

<!--vale off-->
{% konnect_api_request %}
url: /v1/service-catalog/services/$PAGERDUTY_SERVICE_ID/resources
method: GET
status_code: 200
region: global
headers:
  - 'Accept: application/json'
{% endkonnect_api_request %}
<!--vale on-->
