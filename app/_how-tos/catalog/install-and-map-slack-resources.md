---
title: Import and map Slack resources in Catalog
permalink: /how-to/install-and-map-slack-resources/
content_type: how_to
description: Learn how to connect Slack channels to your {{site.konnect_catalog}} service in {{site.konnect_short_name}}.
products:
  - catalog
works_on:
  - konnect
tools:
  - konnect-api
tags:
  - integrations
  - slack
search_aliases:
  - service catalog
related_resources:
  - text: "{{site.konnect_catalog}}"
    url: /catalog/
  - text: Integrations
    url: /catalog/integrations/
  - text: Traceable plugin
    url: /plugins/traceable/
  - text: Slack reference
    url: /catalog/integrations/slack/
automated_tests: false
tldr:
  q: How do I view a Slack channel in {{site.konnect_catalog}}?
  a: Install the Slack integration in {{site.konnect_short_name}} and authorize it using Slack admin credentials. Create a {{site.konnect_catalog}} service and associate it with your Slack channel to improve visibility and ownership.
prereqs:
  inline:
    - title: "{{site.konnect_short_name}} roles"
      include_content: prereqs/service-catalog-integration-role
      icon_url: /assets/icons/kogo-white.svg
    - title: Slack admin access
      content: |
        You must be a Slack admin to authorize the integration. Both **read** and **write** scopes are required by {{site.konnect_short_name}} to complete the connection.
      icon_url: /assets/icons/third-party/slack.svg
---

## Authorize the Slack integration

1. From the **Catalog** in {{site.konnect_short_name}}, click **[Integrations](https://cloud.konghq.com/us/service-catalog/integrations)**.
2. Click **Slack**, then click **Add Slack instance**.
3. Name your integration `slack` and authorize the Slack instance. Slack will prompt you to grant read and write permissions to {{site.konnect_short_name}}. Only Slack administrators can authorize the integration.

Once authorized, resources from your Slack account will be discoverable in the UI.


## Create a service in {{site.konnect_catalog}}

Create a service that you'll map to your Slack resources:

<!--vale off-->
{% konnect_api_request %}
url: /v1/catalog-services
method: POST
status_code: 201
region: us
body:
  name: billing
  display_name: Billing Service
{% endkonnect_api_request %}
<!--vale on-->

Export the service ID:

```sh
export SLACK_SERVICE_ID='YOUR-SERVICE-ID'
```

## List Slack resources

Before you can map your Slack resources to a service in {{site.konnect_catalog}}, you first need to find the resources that are pulled in from Slack:

<!--vale off-->
{% konnect_api_request %}
url: /v1/resources?filter%5Bintegration.name%5D=slack
method: GET
region: us
status_code: 200
{% endkonnect_api_request %}
<!--vale on-->

{:.info}
> You might need to manually sync your Slack integration for resources to appear. From the {{site.konnect_short_name}} UI by navigating to the Slack integration you just installed and selecting **Sync Now** from the **Actions** dropdown menu.

Export the resource ID you want to map to the service:

```sh
export SLACK_RESOURCE_ID='YOUR-RESOURCE-ID'
```

## Map resources to a service

Now, you can map the Slack resource to the service:

<!--vale off-->
{% konnect_api_request %}
url: /v1/resource-mappings
method: POST
status_code: 201
region: us
body:
  service: billing
  resource: $SLACK_RESOURCE_ID
{% endkonnect_api_request %}
<!--vale on-->


## Validate the mapping

To confirm that the Slack resource is now mapped to the intended service, list the service’s mapped resources:

<!--vale off-->
{% konnect_api_request %}
url: /v1/catalog-services/$SLACK_SERVICE_ID/resources
method: GET
status_code: 200
region: us
{% endkonnect_api_request %}
<!--vale on-->
