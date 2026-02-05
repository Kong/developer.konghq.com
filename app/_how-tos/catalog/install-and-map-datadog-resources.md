---
title: Install and map Datadog resources in Catalog
permalink: /how-to/install-and-map-datadog-resources/
content_type: how_to
description: Learn how to connect Datadog monitors and dashboards to your {{site.konnect_catalog}} service in {{site.konnect_short_name}}.
products:
  - catalog
works_on:
  - konnect
tools:
  - konnect-api
automated_tests: false
search_aliases:
  - service catalog
related_resources:
  - text: "{{site.konnect_catalog}}"
    url: /catalog/
  - text: Integrations
    url: /catalog/integrations/
  - text: Datadog reference
    url: /catalog/integrations/datadog/
tldr:
  q: How do I view Datadog monitors and dashboards in {{site.konnect_catalog}}?
  a: Install the Datadog integration in {{site.konnect_short_name}} and authorize it using your API and app keys. Create a {{site.konnect_catalog}} service and associate it with your Datadog resources to display metadata and enable event tracking.
prereqs:
  inline:
    - title: "{{site.konnect_short_name}} roles"
      include_content: prereqs/service-catalog-integration-role
      icon_url: /assets/icons/kogo-white.svg
    - title: Datadog API access
      content: |
        You'll need [Datadog API and application keys](https://docs.datadoghq.com/account_management/api-app-keys/) and must select your Datadog region to authenticate the integration. Your Datadog region must be in a format similar to `US_5`.

        Your Datadog instance application key must either have no scopes or the following [scopes](https://docs.datadoghq.com/api/latest/scopes/):
        * `monitors_read`
        * `dashboards_read`
        * `create_webhooks`
        * `integrations_read`
        * `manage_integrations`

        Additionally, you'll need a Datadog monitor or dashboard to ingest in {{site.konnect_short_name}} as resources.

        Export your Datadog authentication credentials:

        ```sh
        export DATADOG_API_KEY='YOUR-API-KEY'
        export DATADOG_APPLICATION_KEY='YOUR-APP-KEY'
        export DATADOG_REGION='YOUR-REGION'
        ```
      icon_url: /assets/icons/datadog.svg
---

## Install and authorize the Datadog integration

Before you can ingest resources from Datadog, you must first install and authorize the Datadog integration.

First, install the Datadog integration:

<!--vale off-->
{% konnect_api_request %}
url: /v1/integration-instances
method: POST
status_code: 201
region: us
body:
  integration_name: datadog
  name: datadog
  display_name: Datadog
  config:
    datadog_region: $DATADOG_REGION
    datadog_webhook_name: konnect-service-catalog
{% endkonnect_api_request %}
<!--vale on-->

Export the ID of your Datadog integration:

```sh
export DATADOG_INTEGRATION_ID='YOUR-INTEGRATION-ID'
```

Next, authorize the Datadog integration with your Datadog API key and application key:

<!--vale off-->
{% konnect_api_request %}
url: /v1/integration-instances/$DATADOG_INTEGRATION_ID/auth-credential
method: POST
status_code: 201
region: us
body:
  type: multi_key_auth
  config:
    headers:
      - name: DD-API-KEY
        key: $DATADOG_API_KEY
      - name: DD-APPLICATION-KEY
        key: $DATADOG_APPLICATION_KEY
{% endkonnect_api_request %}
<!--vale on-->

Once authorized, monitor and dashboard resources from your Datadog account will be discoverable in the UI.

## Create a service in {{site.konnect_catalog}}

Create a service that you'll map to your Datadog resources:

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
export DATADOG_SERVICE_ID='YOUR-SERVICE-ID'
```

## List Datadog resources

Before you can map your Datadog resources to a service in {{site.konnect_catalog}}, you first need to find the resources that are pulled in from Datadog:

<!--vale off-->
{% konnect_api_request %}
url: /v1/resources?filter%5Bintegration.name%5D=datadog
method: GET
region: us
status_code: 200
{% endkonnect_api_request %}
<!--vale on-->

{:.info}
> You might need to manually sync your Datadog integration for resources to appear. From the {{site.konnect_short_name}} UI by navigating to the Datadog integration you just installed and selecting **Sync Now** from the **Actions** dropdown menu.

Export the resource ID you want to map to the service:

```sh
export DATADOG_RESOURCE_ID='YOUR-RESOURCE-ID'
```

## Map resources to a service

Now, you can map the Datadog resource to the service:

<!--vale off-->
{% konnect_api_request %}
url: /v1/resource-mappings
method: POST
status_code: 201
region: us
body:
  service: billing
  resource: $DATADOG_RESOURCE_ID
{% endkonnect_api_request %}
<!--vale on-->


## Validate the mapping

To confirm that the Datadog resource is now mapped to the intended service, list the service’s mapped resources:

<!--vale off-->
{% konnect_api_request %}
url: /v1/catalog-services/$DATADOG_SERVICE_ID/resources
method: GET
status_code: 200
region: us
headers:
  - 'Accept: application/json'
{% endkonnect_api_request %}
<!--vale on-->

