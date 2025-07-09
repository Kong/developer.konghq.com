---
title: Import and map Traceable resources in Service Catalog
content_type: how_to
description: Learn how to connect Traceable services to your {{site.konnect_catalog}} service in {{site.konnect_short_name}}.
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
  q: How do I view Traceable services in Service Catalog?
  a: Install the Traceable integration in {{site.konnect_short_name}} and authorize it with your Traceable API key. Create a Service Catalog service and associate it with your Traceable services to display metadata and enable event tracking. 
prereqs:
  inline:
    - title: Traceable access
      content: |
        You must have an active [Traceable account](https://www.traceable.ai/) and valid API access to connect Traceable services to your {{site.konnect_catalog}} service. You also need a [Traceable Service](https://docs.traceable.ai/docs/domains-services-backends) you can pull into {{site.konnect_short_name}}.
        
        Export your Traceable API key:
        ```sh
        export TRACEABLE_API_KEY='YOUR-TRACEABLE-API-KEY'
        ```
      icon_url: /assets/icons/traceable.svg
---

## Install and authorize the Traceable integration

Before you can ingest resources from Traceable, you must first install and authorize the Traceable integration.

First, install the Traceable integration:

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
  integration_name: traceable
  name: traceable
  display_name: Traceable
  config:
    include_inactive: false
{% endkonnect_api_request %}
<!--vale on-->

Export the ID of your Traceable integration:

```sh
export TRACEABLE_INTEGRATION_ID='YOUR-INTEGRATION-ID'
```

Next, authorize the Traceable integration with your Traceable API key:

<!--vale off-->
{% konnect_api_request %}
url: /v1/service-catalog/integration-instances/$TRACEABLE_INTEGRATION_ID/auth-credential
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
        key: $TRACEABLE_API_KEY
{% endkonnect_api_request %}
<!--vale on-->

Once authorized, resources from your Traceable account will be discoverable in the UI.

## Create a service in Service Catalog

Create a service that you'll map to your Traceable resources:

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
export TRACEABLE_SERVICE_ID='YOUR-SERVICE-ID'
```

## List Traceable resources

Before you can map your Traceable resources to a service in Service Catalog, you first need to find the resources that are pulled in from Traceable:

<!--vale off-->
{% konnect_api_request %}
url: /v1/service-catalog/resources?filter%5Bintegration.name%5D=traceable
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
export TRACEABLE_RESOURCE_ID='YOUR-RESOURCE-ID'
```

## Map resources to a service

Now, you can map the Traceable resource to the service:

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
  resource: $TRACEABLE_RESOURCE_ID
{% endkonnect_api_request %}
<!--vale on-->


## Validate the mapping

To confirm that the Traceable resource is now mapped to the intended service, list the service’s mapped resources:

<!--vale off-->
{% konnect_api_request %}
url: /v1/service-catalog/services/$TRACEABLE_SERVICE_ID/resources
method: GET
status_code: 200
region: global
headers:
  - 'Accept: application/json'
{% endkonnect_api_request %}
<!--vale on-->
