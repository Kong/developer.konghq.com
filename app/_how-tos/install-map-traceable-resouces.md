---
title: Import and map Traceable entities
content_type: how_to
description: Learn how to connect Traceable services to your {{site.konnect_catalog}} service in {{site.konnect_short_name}}.
permalink: /service-catalog/import-map-traceable-entities
products:
  - service-catalog
  - gateway
works_on:
  - konnect
tags:
  - integrations
  - traceable
related_resources:
  - text: Catalog
    url: /service-catalog/
  - text: Traceable plugin
    url: /plugins/traceable/
  - text: Traceable reference
    url: /service-catalog/integrations/traceable/
tldr:
  q: How do I connect Traceable services to my {{site.konnect_catalog}} service?
  a: Install the Traceable integration in {{site.konnect_short_name}}, authorize it, and link Traceable services to your {{site.konnect_catalog}} service to improve visibility.
prereqs:
  inline:
    - title: Traceable access
      content: |
        You must have an active Traceable account and valid API access to connect Traceable services to your {{site.konnect_catalog}} service.
      icon_url: /assets/icons/traceable.svg
---

## Authorize the Traceable integration

1. In {{site.konnect_short_name}}, go to **{{site.konnect_catalog}} > Integrations**.
2. Click **Traceable**, then **Install Traceable**.
3. Click **Authorize**.

Once authorized, Traceable services will be discoverable in the UI.

## Initialize a Traceable resource

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
  type: Traceable???
  config:
    id: ???
{% endkonnect_api_request %}
<!--vale on-->

* Replace `{integrationInstanceId}` with the ID of your Datadog integration instance.
* The `type` value must match the Datadog-defined resource type.
* The `config` object must include the identifying metadata for the resource (e.g., `monitor_id`).

## Confirm the Traceable resource

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
    integration_instance: Traceable???
    type: Traceable??
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

