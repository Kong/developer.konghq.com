---
title: Import and map Slack entities
content_type: how_to
description: Learn how to connect Slack channels to your {{site.konnect_catalog}} service in {{site.konnect_short_name}}.
permalink: /service-catalog/import-map-slack-entities
products:
  - service-catalog
  - gateway
works_on:
  - konnect
tags:
  - integrations
  - slack
related_resources:
  - text: Catalog
    url: /service-catalog/
  - text: Traceable plugin
    url: /plugins/traceable/
  - text: Slack reference
    url: /service-catalog/integrations/slack/
tldr:
  q: How do I connect a Slack channel to my {{site.konnect_catalog}} service?
  a: Install the Slack integration in {{site.konnect_short_name}}, authorize it using Slack admin credentials, and map a Slack channel to the service to improve visibility and ownership.
prereqs:
  inline:
    - title: Slack admin access
      content: |
        You must be a Slack admin to authorize the integration. Both **read** and **write** scopes are required by {{site.konnect_short_name}} to complete the connection.
      icon_url: /assets/icons/slack.svg
---

## Authorize the Slack integration

1. In {{site.konnect_short_name}}, go to **{{site.konnect_catalog}} > Integrations**.
2. Click **Slack**, then **Install Slack**.
3. Click **Authorize**.

Slack will prompt you to grant read and write permissions to {{site.konnect_short_name}}. Only Slack administrators can authorize the integration.


## Initialize a slack resource

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
  type: slack???
  config:
    id: ???
{% endkonnect_api_request %}
<!--vale on-->

* Replace `{integrationInstanceId}` with the ID of your Datadog integration instance.
* The `type` value must match the Datadog-defined resource type.
* The `config` object must include the identifying metadata for the resource (e.g., `monitor_id`).

## Confirm the slack resource

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
    integration_instance: slack???
    type: slack??
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

