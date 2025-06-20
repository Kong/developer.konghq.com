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
      icon_url: /assets/icons/datadog.png
---

## Authorize the Datadog integration

1. In {{site.konnect_short_name}}, go to **Service Catalog > Integrations**.
2. Click **Datadog**, then **Install Datadog**.
3. Select your Datadog region.
4. Enter your [Datadog API key and application key](https://docs.datadoghq.com/account_management/api-app-keys/).
5. Click **Authorize** to complete the connection.

Once authorized, monitors and dashboards from your Datadog account will be discoverable in the UI.

To import a resource discovered by the Datadog integration and map it to a service, use the following steps.

## Initialize a Datadog resource

Create a placeholder resource using the Datadog integration instance. The resource will be hydrated automatically by the integration.

<!--vale off-->
{% konnect_api_request %}
url: /v1/integration-instances/{integrationInstanceId}/resources
method: POST
status_code: 201
region: us
headers:
  - 'Accept: application/json'
  - 'Content-Type: application/json'
body:
  type: datadog???
  config:
    id: ???
{% endkonnect_api_request %}
<!--vale on-->

* Replace `{integrationInstanceId}` with the ID of your Datadog integration instance.
* The `type` value must match the Datadog-defined resource type.
* The `config` object must include the identifying metadata for the resource (e.g., `monitor_id`).

## Confirm the Datadog resource

After initialization, you can fetch the resource by ID and confirm the `attributes` field is no longer null:

<!--vale off-->
{% konnect_api_request %}
url: /v1/resources/{resourceId}
method: GET
status_code: 200
region: us
headers:
  - 'Accept: application/json'
{% endkonnect_api_request %}
<!--vale on-->

## Map the resource to a service

Once the resource is activated, map it to an existing service in the Service Catalog.

<!--vale off-->
{% konnect_api_request %}
url: /v1/resource-mappings
method: POST
status_code: 201
region: global
headers:
  - 'Accept: application/json'
  - 'Content-Type: application/json'
body:
  service: my-service-name
  resource:
    integration_instance: datadog-prod
    type: datadog_monitor
    config:
      monitor_id: 112233
{% endkonnect_api_request %}
<!--vale on-->

* You can also use the resource's `id` directly instead of providing the config again.


### Validate the mapping

To confirm that the Datadog monitor is now mapped to the intended service, list the service’s mapped resources:

<!--vale off-->
{% konnect_api_request %}
url: /v1/services/{serviceId}/resources
method: GET
status_code: 200
region: global
headers:
  - 'Accept: application/json'
{% endkonnect_api_request %}
<!--vale on-->

