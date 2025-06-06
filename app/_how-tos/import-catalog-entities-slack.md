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
  name: platform-ops
  type: slack
  metadata:
    channel_id: C01A2BC3D4E
    channel_name: platform-ops
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
  slack_channel_id: C01A2BC3D4E
{% endkonnect_api_request %}
<!--vale on-->

## Validate

After mapping, return to your {{site.konnect_catalog}} service in the UI. You should see:

- The associated Slack channel name and ID
- A clear indication of who owns or operates the service
- An easy path for other users to contact the responsible team
