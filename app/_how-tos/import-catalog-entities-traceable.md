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
  name: traceable-auth-service
  type: traceable
  metadata:
    service_id: svc-auth-123
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
  traceable_service_id: svc-auth-123
{% endkonnect_api_request %}
<!--vale on-->

## Validate

After mapping, return to your {{site.konnect_catalog}} service in the UI. You should see:

- The linked Traceable service name
- Grouped API endpoint metadata from Traceable
- A verified connection to enhance your service’s security context
