---
title: Import and map SwaggerHub resources in Service Catalog
content_type: how_to
description: Learn how to connect SwaggerHub API versions to your {{site.konnect_catalog}} service in {{site.konnect_short_name}}.
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
url: /v1/service-catalog/integration-instances
method: POST
status_code: 201
region: us
headers:
  - 'Accept: application/json'
  - 'Content-Type: application/json'
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
url: /v1/service-catalog/integration-instances/$SWAGGERHUB_INTEGRATION_ID/auth-credential
method: POST
status_code: 201
region: us
headers:
  - 'Accept: application/json, application/problem+json'
  - 'Content-Type: application/json'
body:
  type: multi_key_auth
  config:
    headers:
      - name: authorization
        key: $SWAGGERHUB_API_KEY
{% endkonnect_api_request %}
<!--vale on-->

Once authorized, resources from your SwaggerHub account will be discoverable in the UI.

## Create a service in Service Catalog

Create a service that you'll map to your SwaggerHub resources:

<!--vale off-->
{% konnect_api_request %}
url: /v1/service-catalog/services
method: POST
status_code: 201
region: us
headers:
  - 'Accept: application/json, application/problem+json'
  - 'Content-Type: application/json'
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

Before you can map your SwaggerHub resources to a service in Service Catalog, you first need to find the resources that are pulled in from SwaggerHub:

<!--vale off-->
{% konnect_api_request %}
url: /v1/service-catalog/resources?filter%5Bintegration.name%5D=swaggerhub
method: GET
region: us
status_code: 200
headers:
  - 'Accept: application/json, application/problem+json'
  - 'Content-Type: application/json'
{% endkonnect_api_request %}
<!--vale on-->

Export the resource ID you want to map to the service:

```sh
export SWAGGERHUB_RESOURCE_ID='YOUR-RESOURCE-ID'
```

## Map resources to a service

Now, you can map the SwaggerHub resource to the service:

<!--vale off-->
{% konnect_api_request %}
url: /v1/service-catalog/resource-mappings
method: POST
status_code: 201
region: us
headers:
  - 'Accept: application/json, application/problem+json'
  - 'Content-Type: application/json'
body:
  service: billing
  resource: $SWAGGERHUB_RESOURCE_ID
{% endkonnect_api_request %}
<!--vale on-->


## Validate the mapping

To confirm that the SwaggerHub resource is now mapped to the intended service, list the service’s mapped resources:

<!--vale off-->
{% konnect_api_request %}
url: /v1/service-catalog/services/$SWAGGERHUB_SERVICE_ID/resources
method: GET
status_code: 200
region: global
headers:
  - 'Accept: application/json'
{% endkonnect_api_request %}
<!--vale on-->
