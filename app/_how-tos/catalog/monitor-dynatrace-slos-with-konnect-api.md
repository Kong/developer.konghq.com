---
title: Monitor Dynatrace classic SLOs in Catalog with the Konnect API
permalink: /how-to/monitor-dynatrace-slos-with-konnect-api/
content_type: how_to
description: Learn how to connect a Dynatrace classic SLO to your {{site.konnect_catalog}} service in {{site.konnect_short_name}} using the API.
products:
  - catalog
works_on:
  - konnect
tools:
  - konnect-api
tags:
  - integrations
  - dynatrace
search_aliases:
  - classic service-level object
  - SLO
  - service catalog
related_resources:
  - text: "{{site.konnect_catalog}}"
    url: /catalog/
  - text: Integrations
    url: /catalog/integrations/
  - text: Dynatrace reference
    url: /catalog/integrations/dynatrace/
  - text: "Monitor Dynatrace classic SLOs {{site.konnect_catalog}} with the {{site.konnect_short_name}} UI"
    url: /how-to/monitor-dynatrace-slos-with-konnect-ui/
  - text: Set up Dynatrace with OpenTelemetry
    url: /how-to/set-up-dynatrace-with-otel/
automated_tests: false
tldr:
  q: How do I monitor Dynatrace classic service-level objects in {{site.konnect_short_name}}?
  a: Install the Dynatrace integration in {{site.konnect_short_name}} and authorize access with your Dynatrace URL and personal access token (with `slo.read` permissions), then link an SLO to your {{site.konnect_catalog}} service.
prereqs:
  inline:
    - title: "{{site.konnect_short_name}} roles"
      include_content: prereqs/service-catalog-integration-role
      icon_url: /assets/icons/kogo-white.svg
    - title: Dynatrace
      content: |
        You need to configure the following in Dynatrace SaaS:
        * A [classic service-level object in Dynatrace](https://docs.dynatrace.com/docs/deliver/service-level-objectives-classic/configure-and-monitor-slo). This will be ingested by {{site.konnect_short_name}}.
        * Your Dynatrace URL. For example: `https://whr42363.apps.dynatrace.com`
        * A [Dynatrace personal access token](https://docs.dynatrace.com/docs/manage/identity-access-management/access-tokens-and-oauth-clients/access-tokens/personal-access-token) with read SLO (`slo.read`) permissions.

        Export your Dynatrace URL and personal access token:
        ```sh
        export DYNATRACE_URL='YOUR DYNATRACE URL'
        export DYNATRACE_PAT='YOUR DYNATRACE PERSONAL ACCESS TOKEN'
        ```

        {:.warning}
        > Dynatrace ActiveGate isn't supported.
      icon_url: /assets/icons/third-party/dynatrace.png
---

## Configure the Dynatrace integration

Before you can discover SLOs in {{site.konnect_catalog}}, you must configure the Dynatrace integration.

First, install the Dynatrace integration:

<!--vale off-->
{% konnect_api_request %}
url: /v1/integration-instances
method: POST
status_code: 201
region: us
body:
  integration_name: dynatrace
  name: dynatrace
  display_name: Dynatrace
  config:
    base_url: $DYNATRACE_URL
{% endkonnect_api_request %}
<!--vale on-->

Export the ID of your Dynatrace integration:

```sh
export DYNATRACE_INTEGRATION_ID='YOUR-INTEGRATION-ID'
```

Next, authorize the Dynatrace integration with your Dynatrace personal access token:

<!--vale off-->
{% konnect_api_request %}
url: /v1/integration-instances/$DYNATRACE_INTEGRATION_ID/auth-credential
method: POST
status_code: 201
region: us
body:
  type: multi_key_auth
  config:
    headers:
      - name: authorization
        key: $DYNATRACE_PAT
{% endkonnect_api_request %}
<!--vale on-->

Once authorized, resources from your Dynatrace account will be discoverable in the UI.

## Create a service in {{site.konnect_catalog}}

Create a service that you'll map to your Dynatrace resources:

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
export DYNATRACE_SERVICE_ID='YOUR-SERVICE-ID'
```

## List Dynatrace resources

Before you can map your Dynatrace resources to a service in {{site.konnect_catalog}}, you first need to find the resources that are pulled in from Dynatrace:

<!--vale off-->
{% konnect_api_request %}
url: /v1/resources?filter%5Bintegration.name%5D=dynatrace
method: GET
region: us
status_code: 200
{% endkonnect_api_request %}
<!--vale on-->

{:.info}
> You might need to manually sync your Dynatrace integration for resources to appear. From the {{site.konnect_short_name}} UI by navigating to the Dynatrace integration you just installed and selecting **Sync Now** from the **Actions** dropdown menu.

Export the resource ID you want to map to the service:

```sh
export DYNATRACE_RESOURCE_ID='YOUR-RESOURCE-ID'
```

## Map resources to a service

Now, you can map the Dynatrace resource to the service:

<!--vale off-->
{% konnect_api_request %}
url: /v1/resource-mappings
method: POST
status_code: 201
region: us
body:
  service: billing
  resource: $DYNATRACE_RESOURCE_ID
{% endkonnect_api_request %}
<!--vale on-->


## Validate the mapping

To confirm that the Dynatrace resource is now mapped to the intended service, list the service’s mapped resources:

<!--vale off-->
{% konnect_api_request %}
url: /v1/catalog-services/$DYNATRACE_SERVICE_ID/resources
method: GET
status_code: 200
region: us
{% endkonnect_api_request %}
<!--vale on-->
