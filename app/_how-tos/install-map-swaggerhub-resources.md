---
title: Import and map SwaggerHub entities
content_type: how_to
description: Learn how to connect SwaggerHub API versions to your {{site.konnect_catalog}} service in {{site.konnect_short_name}}.
permalink: /service-catalog/import-map-swaggerhub-entities
products:
  - service-catalog
  - gateway
works_on:
  - konnect
tags:
  - integrations
  - swaggerhub
related_resources:
  - text: Catalog
    url: /service-catalog/
  - text: SwaggerHub reference
    url: /service-catalog/integrations/swaggerhub/
tldr:
  q: How do I connect SwaggerHub API specs to my {{site.konnect_catalog}} service?
  a: Install the SwaggerHub integration in {{site.konnect_short_name}}, authorize using your SwaggerHub API key, and link API versions to your service.
prereqs:
  inline:
    - title: SwaggerHub API key
      content: |
        You must have a [SwaggerHub API key](https://swagger.io/docs/specification/v3_0/authentication/api-keys/) to authenticate your SwaggerHub account with {{site.konnect_short_name}}.
---

## Authorize the SwaggerHub integration

1. In {{site.konnect_short_name}}, go to **{{site.konnect_catalog}} > Integrations**.
2. Click **SwaggerHub**, then **Install SwaggerHub**.
3. Click **Authorize**.

You'll be prompted to enter your SwaggerHub API key to grant {{site.konnect_short_name}} access to your SwaggerHub account.

Once authorized, both public and private APIs from your SwaggerHub account will be available for discovery.

## Initialize a Swaggerhub resource

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
  type: Swaggerhub???
  config:
    id: ???
{% endkonnect_api_request %}
<!--vale on-->

* Replace `{integrationInstanceId}` with the ID of your Datadog integration instance.
* The `type` value must match the Datadog-defined resource type.
* The `config` object must include the identifying metadata for the resource (e.g., `monitor_id`).

## Confirm the Swaggerhub resource

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
    integration_instance: Swaggerhub???
    type: Swaggerhub??
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

