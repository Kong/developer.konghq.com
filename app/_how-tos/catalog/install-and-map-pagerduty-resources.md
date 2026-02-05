---
title: Import and map PagerDuty resources in Catalog
permalink: /how-to/install-and-map-pagerduty-resources/
content_type: how_to
description: Learn how to connect PagerDuty services to your {{site.konnect_catalog}} service in {{site.konnect_short_name}}.
products:
  - catalog
works_on:
  - konnect
tools:
  - konnect-api
tags:
  - integrations
  - pagerduty
search_aliases:
  - service catalog
related_resources:
  - text: "{{site.konnect_catalog}}"
    url: /catalog/
  - text: Integrations
    url: /catalog/integrations/
  - text: PagerDuty reference
    url: /catalog/integrations/pagerduty/
automated_tests: false
tldr:
  q: How do I view PagerDuty services in {{site.konnect_catalog}}?
  a: Install the PagerDuty integration in {{site.konnect_short_name}} and authorize it with both read and write scopes. Create a {{site.konnect_catalog}} service and associate it with your PagerDuty services to display metadata and enable event tracking. 
prereqs:
  inline:
    - title: "{{site.konnect_short_name}} roles"
      include_content: prereqs/service-catalog-integration-role
      icon_url: /assets/icons/kogo-white.svg
    - title: PagerDuty access
      content: |
        You need a [PagerDuty account](https://app.pagerduty.com/) with a PagerDuty service you want to pull in to {{site.konnect_short_name}}.
      icon_url: /assets/icons/pagerduty.svg
---

## Authenticate the PagerDuty integration

1. From the **Catalog** in {{site.konnect_short_name}}, select **[Integrations](https://cloud.konghq.com/us/service-catalog/integrations)**. 
2. Click **PagerDuty**, and then click **Add PagerDuty Instance**.
3. Configure the region, grant authorization, and name the instance. 
   PagerDuty will ask you to grant consent to {{site.konnect_short_name}}. **Both Read and Write scopes are required.**

Once authorized, resources from your PagerDuty account will be discoverable in the UI.

## Create a service in {{site.konnect_catalog}}

Create a service that you'll map to your PagerDuty resources:

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

Export the service ID:

```sh
export PAGERDUTY_SERVICE_ID='YOUR-SERVICE-ID'
```

## List PagerDuty resources

Before you can map your PagerDuty resources to a service in {{site.konnect_catalog}}, you first need to find the resources that are pulled in from PagerDuty:

<!--vale off-->
{% konnect_api_request %}
url: /v1/resources?filter%5Bintegration.name%5D=pagerduty
method: GET
region: us
status_code: 200
{% endkonnect_api_request %}
<!--vale on-->

{:.info}
> You might need to manually sync your PagerDuty integration for resources to appear. From the {{site.konnect_short_name}} UI by navigating to the PagerDuty integration you just installed and selecting **Sync Now** from the **Actions** dropdown menu.

Export the resource ID you want to map to the service:

```sh
export PAGERDUTY_RESOURCE_ID='YOUR-RESOURCE-ID'
```

## Map resources to a service

Now, you can map the PagerDuty resource to the service:

<!--vale off-->
{% konnect_api_request %}
url: /v1/resource-mappings
method: POST
status_code: 201
region: us
body:
  service: billing
  resource: $PAGERDUTY_RESOURCE_ID
{% endkonnect_api_request %}
<!--vale on-->


## Validate the mapping

To confirm that the PagerDuty resource is now mapped to the intended service, list the service’s mapped resources:

<!--vale off-->
{% konnect_api_request %}
url: /v1/catalog-services/$PAGERDUTY_SERVICE_ID/resources
method: GET
status_code: 200
region: us
{% endkonnect_api_request %}
<!--vale on-->
