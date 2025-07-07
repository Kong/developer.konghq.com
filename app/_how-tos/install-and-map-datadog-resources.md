---
title: Install and map Datadog resources
content_type: how_to
description: Learn how to connect Datadog monitors and dashboards to your Service Catalog service in {{site.konnect_short_name}}.
permalink: /service-catalog/integration/install-map-datadog-entities/
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
        You'll need [Datadog API and application keys](https://docs.datadoghq.com/account_management/api-app-keys/) and must select your Datadog region to authenticate the integration.

        ```sh
        export DATADOG_API_KEY=''
        export DATADOG_APPLICATION_KEY=''
        export DATADOG_REGION=''
        ```
      icon_url: /assets/icons/datadog.png
---

## Authorize the Datadog integration

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

```sh
export DATADOG_INTEGRATION_ID=''
```

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

Once authorized, monitors and dashboards from your Datadog account will be discoverable in the UI.

## Create a service

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
  name: datadog
  display_name: Datadog
{% endkonnect_api_request %}
<!--vale on-->


```sh
export DATADOG_SERVICE_ID=''
```

## Map resources to a service

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
  resource:
    integration_instance: 
    type:
    config:
{% endkonnect_api_request %}
<!--vale on-->

### Validate the mapping

To confirm that the Datadog monitor is now mapped to the intended service, list the service’s mapped resources:

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

