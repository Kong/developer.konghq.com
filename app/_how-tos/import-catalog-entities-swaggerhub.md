---
title: Import and map SwaggerHub entities
content_type: how_to
description: Learn how to connect SwaggerHub API versions to your {{site.konnect_catalog}} service in {{site.konnect_short_name}}.
permalink: /service-catalog/import-map-swaggerhub-entities
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
        You must have a [SwaggerHub API key](https://swagger.io/docs/specification/v3_0/authentication/api-keys/) to authenticate your SwaggerHub account with {{site.konnect_short_name}}.
---

## Authorize the SwaggerHub integration

1. In {{site.konnect_short_name}}, go to **{{site.konnect_catalog}} > Integrations**.
2. Click **SwaggerHub**, then **Install SwaggerHub**.
3. Click **Authorize**.

You'll be prompted to enter your SwaggerHub API key to grant {{site.konnect_short_name}} access to your SwaggerHub account.

Once authorized, both public and private APIs from your SwaggerHub account will be available for discovery.

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
  name: my-swaggerhub-api
  type: swaggerhub
  metadata:
    owner: my-org
    api_name: my-api
    version: 1.0.0
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
{% endkonnect_api_request %}
## Validate

After mapping, return to your {{site.konnect_catalog}} service in the UI and confirm that SwaggerHub API details are now associated. You should see:

- API name and version
- Discovery of public and private specs
- Linked metadata reflecting the SwaggerHub source

<!--vale off-->
{% konnect_api_request %}
url: /v2/cloud-gateways/networks/$KONNECT_NETWORK_ID/transit-gateways
status_code: 200
region: global
method: GET
{% endkonnect_api_request %}
<!--vale on-->