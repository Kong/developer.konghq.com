---
title: Install and map Datadog resources in Service Catalog
content_type: how_to
description: Learn how to connect Datadog monitors and dashboards to your Service Catalog service in {{site.konnect_short_name}}.
products:
  - service-catalog
  - gateway
works_on:
  - konnect

related_resources:
  - text: Service Catalog
    url: /service-catalog/
  - text: Datadog reference
    url: /service-catalog/integrations/datadog/
tldr:
  q: How do I connect Datadog monitors and dashboards to my Service Catalog service?
  a: Install the Datadog integration in {{site.konnect_short_name}}, authorize it using your API and app keys, and link Datadog resources to your Service Catalog service.
prereqs:
  inline:
    - title: Datadog API access
      content: |
        You'll need [Datadog API and application keys](https://docs.datadoghq.com/account_management/api-app-keys/) and must select your Datadog region to authenticate the integration. Your Datadog region must be in a format similar to `US_5`.

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
url: /v1/service-catalog/integration-instances
method: POST
status_code: 201
region: us
headers:
  - 'Accept: application/json'
  - 'Content-Type: application/json'
body:
  integration_name: datadog
  name: datadog
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
url: /v1/service-catalog/integration-instances/$DATADOG_INTEGRATION_ID/auth-credential
method: POST
status_code: 201
region: us
headers:
  - 'Accept: application/json, application/problem+json'
  - 'Content-Type: application/json'
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

## Create a service in Service Catalog

Create a service that you'll map to your Datadog resources:

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
export DATADOG_SERVICE_ID='YOUR-SERVICE-ID'
```

## List Datadog resources

Before you can map your Datadog resources to a service in Service Catalog, you first need to find the resources that are pulled in from Datadog:

<!--vale off-->
{% konnect_api_request %}
url: /v1/service-catalog/resources?filter%5Bintegration.name%5D=datadog
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
export DATADOG_RESOURCE_ID='YOUR-RESOURCE-ID'
```

## Map resources to a service

Now, you can map the Datadog resource to the service:

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
  service: datadog
  resource: $DATADOG_RESOURCE_ID
{% endkonnect_api_request %}
<!--vale on-->


## Validate the mapping

To confirm that the Datadog resource is now mapped to the intended service, list the service’s mapped resources:

<!--vale off-->
{% konnect_api_request %}
url: /v1/service-catalog/services/$DATADOG_SERVICE_ID/resources
method: GET
status_code: 200
region: global
headers:
  - 'Accept: application/json'
{% endkonnect_api_request %}
<!--vale on-->

