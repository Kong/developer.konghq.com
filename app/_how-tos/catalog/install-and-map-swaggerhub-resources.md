---
title: Import and map SwaggerHub resources in Catalog
permalink: /how-to/install-and-map-swaggerhub-resources/
content_type: how_to
description: Learn how to connect SwaggerHub API versions to your {{site.konnect_catalog}} service in {{site.konnect_short_name}}.
products:
  - catalog
works_on:
  - konnect
tools:
  - konnect-api
tags:
  - integrations
  - swaggerhub
search_aliases:
  - service catalog
related_resources:
  - text: "{{site.konnect_catalog}}"
    url: /catalog/
  - text: Integrations
    url: /catalog/integrations/
  - text: SwaggerHub reference
    url: /catalog/integrations/swaggerhub/
automated_tests: false
tldr:
  q: How do I view SwaggerHub API specs in {{site.konnect_catalog}}?
  a: Install the SwaggerHub integration in {{site.konnect_short_name}} and authorize using your SwaggerHub API key. Create a {{site.konnect_catalog}} service and associate it with your SwaggerHub API versions to display metadata and enable event tracking. 
prereqs:
  inline:
    - title: "{{site.konnect_short_name}} roles"
      include_content: prereqs/service-catalog-integration-role
      icon_url: /assets/icons/kogo-white.svg
    - title: SwaggerHub API key
      content: |
        You must have a [SwaggerHub API key](https://app.swaggerhub.com/settings/apiKey) to authenticate your SwaggerHub account with {{site.konnect_short_name}}. Export it as an environment variable:

        ```sh
        export SWAGGERHUB_API_KEY='YOUR-API-KEY'
        ```

        Additionally, you'll need an [API version](https://support.smartbear.com/swaggerhub/docs/en/manage-apis/versioning.html?sbsearch=API%20Versions0) in SwaggerHub to pull into {{site.konnect_short_name}} as a resource.
---

## Install and authorize the SwaggerHub integration

Before you can ingest resources from SwaggerHub, you must first install and authorize the SwaggerHub integration.

First, install the SwaggerHub integration:

<!--vale off-->
{% konnect_api_request %}
url: /v1/integration-instances
method: POST
status_code: 201
region: us
body:
  integration_name: swaggerhub
  name: swaggerhub
  display_name: SwaggerHub
  config: {}
{% endkonnect_api_request %}
<!--vale on-->

Export the ID of your SwaggerHub integration:

```sh
export SWAGGERHUB_INTEGRATION_ID='YOUR-INTEGRATION-ID'
```

Next, authorize the SwaggerHub integration with your SwaggerHub API key:

<!--vale off-->
{% konnect_api_request %}
url: /v1/integration-instances/$SWAGGERHUB_INTEGRATION_ID/auth-credential
method: POST
status_code: 201
region: us
body:
  type: multi_key_auth
  config:
    headers:
      - name: authorization
        key: $SWAGGERHUB_API_KEY
{% endkonnect_api_request %}
<!--vale on-->

Once authorized, resources from your SwaggerHub account will be discoverable in the UI.

## Create a service in {{site.konnect_catalog}}

Create a service that you'll map to your SwaggerHub resources:

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
export SWAGGERHUB_SERVICE_ID='YOUR-SERVICE-ID'
```

## List SwaggerHub resources

Before you can map your SwaggerHub resources to a service in {{site.konnect_catalog}}, you first need to find the resources that are pulled in from SwaggerHub:

<!--vale off-->
{% konnect_api_request %}
url: /v1/resources?filter%5Bintegration.name%5D=swaggerhub
method: GET
region: us
status_code: 200
{% endkonnect_api_request %}
<!--vale on-->

{:.info}
> You might need to manually sync your SwaggerHub integration for resources to appear. From the {{site.konnect_short_name}} UI by navigating to the SwaggerHub integration you just installed and selecting **Sync Now** from the **Actions** dropdown menu.

Export the resource ID you want to map to the service:

```sh
export SWAGGERHUB_RESOURCE_ID='YOUR-RESOURCE-ID'
```

## Map resources to a service

Now, you can map the SwaggerHub resource to the service:

<!--vale off-->
{% konnect_api_request %}
url: /v1/resource-mappings
method: POST
status_code: 201
region: us
body:
  service: billing
  resource: $SWAGGERHUB_RESOURCE_ID
{% endkonnect_api_request %}
<!--vale on-->


## Validate the mapping

To confirm that the SwaggerHub resource is now mapped to the intended service, list the service’s mapped resources:

<!--vale off-->
{% konnect_api_request %}
url: /v1/catalog-services/$SWAGGERHUB_SERVICE_ID/resources
method: GET
status_code: 200
region: us
{% endkonnect_api_request %}
<!--vale on-->
