---
title: Import and map PagerDuty entities
content_type: how_to
description: Learn how to connect PagerDuty services to your {{site.konnect_catalog}} service in {{site.konnect_short_name}}.
permalink: /service-catalog/import-map-pagerduty-entities
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
  q: How do I connect PagerDuty services to my {{site.konnect_catalog}} service?
  a: Install the PagerDuty integration in {{site.konnect_short_name}}, authorize it with both read and write scopes, and link PagerDuty services to your {{site.konnect_catalog}} service to display incident and on-call information.
prereqs:
  inline:
    - title: PagerDuty access
      content: |
        You must grant both **Read** and **Write** scopes to {{site.konnect_short_name}} when authorizing the PagerDuty integration.
      icon_url: /assets/icons/pagerduty.svg
---

## Authorize the PagerDuty integration

1. In {{site.konnect_short_name}}, go to **{{site.konnect_catalog}} > Integrations**.
2. Click **PagerDuty**, then **Install PagerDuty**.
3. Click **Authorize**.

When prompted by PagerDuty, grant access to {{site.konnect_short_name}} with both **Read** and **Write** scopes.

Once authorized, PagerDuty services will be discoverable in the UI.

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
  name: core-api-pagerduty
  type: pagerduty
  metadata:
    service_id: PQ7D123
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
  pagerduty_service_id: PQ7D123
{% endkonnect_api_request %}
<!--vale on-->

## Validate

After mapping, return to your {{site.konnect_catalog}} service in the UI. You should see:

- Current unresolved incidents from the linked PagerDuty service
- The active on-call user for the service
- Incident alerting context for consumers of your service directory
