---
title: Import and map Datadog entities
content_type: how_to
description: Learn how to connect Datadog monitors and dashboards to your {{site.konnect_catalog}} service in {{site.konnect_short_name}}.
permalink: /service-catalog/import-map-datadog-entities
products:
  - service-catalog
  - gateway
works_on:
  - konnect
tags:
  - integrations
  - datadog
related_resources:
  - text: Catalog
    url: /service-catalog/
  - text: Datadog reference
    url: /service-catalog/integrations/datadog/
tldr:
  q: How do I connect Datadog monitors and dashboards to my {{site.konnect_catalog}} service?
  a: Install the Datadog integration in {{site.konnect_short_name}}, authorize it using your API and app keys, and link Datadog resources to your {{site.konnect_catalog}} service.
prereqs:
  inline:
    - title: Datadog API access
      content: |
        You'll need [Datadog API and application keys](https://docs.datadoghq.com/account_management/api-app-keys/) and must select your Datadog region to authenticate the integration.
      icon_url: /assets/icons/datadog.png
---

## Authorize the Datadog integration

1. In {{site.konnect_short_name}}, go to **{{site.konnect_catalog}} > Integrations**.
2. Click **Datadog**, then **Install Datadog**.
3. Select your Datadog region.
4. Enter your [Datadog API key and application key](https://docs.datadoghq.com/account_management/api-app-keys/).
5. Click **Authorize** to complete the connection.

Once authorized, monitors and dashboards from your Datadog account will be discoverable in the UI.

## Import entities

<!--vale off-->
{% konnect_api_request %}
url: /v2/catalog/???
status_code: 201
region: global
method: POST
headers:
  - 'Accept: application/json'
  - 'Content-Type: application/json'
body:
  name: high-cpu-monitor
  type: datadog
  metadata:
    kind: monitor
    id: 112233
{% endkonnect_api_request %}
<!--vale on-->

## Map entities

<!--vale off-->
{% konnect_api_request %}
url: /v2/catalog/???
status_code: 201
region: global
method: POST
headers:
  - 'Accept: application/json'
  - 'Content-Type: application/json'
body:
  catalog_entity: my-service
  datadog_monitor_id: 112233
{% endkonnect_api_request %}
<!--vale on-->

## Validate

After mapping, return to your {{site.konnect_catalog}} service and confirm that Datadog resources are linked. You should see:

- Linked monitors and dashboards
- Metadata from Datadog including names, status, and visualization
- Discovery of resources directly from your connected Datadog account
