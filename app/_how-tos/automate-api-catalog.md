---
title: Automate your API catalog with Dev Portal
description: Learn how to automate your API catalog in Dev Portal using Konnect APIs.
content_type: how_to
automated_tests: false
products:
    - gateway
    - dev-portal
works_on:
    - konnect

entities: []
tools:
    - deck
    # - konnect-api
tags:
    - api-catalog
search_aliases:
    - API catalog

tldr:
    q: How do I automate the creation and publication of my API catalog in Dev Portal?
    a: You can automate the creation and publication of APIs to your Dev Portal API catalog using the {{site.konnect_short_name}} API. Create an API (`/v3/apis`), optionally associate a document (`/v3/apis/{apiId}/documents`) or spec (`/v3/apis/{apiId}/versions`) with the API, then associate the API with a Gateway Service (`/v3/apis/{apiId}/implementations`). Finally, publish it by sending a `PUT` request to the `/v3/apis/{apiId}/publications/{portalId}` endpoint.

prereqs:
  inline:
    - title: Dev Portal
      include_content: prereqs/api-catalog
      icon_url: /assets/icons/dev-portal.svg
  entities:
    services:
        - example-service
    routes:
        - example-route

cleanup:
  inline:
    - title: Clean up {{site.konnect_short_name}} environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg

min_version:
    gateway: '3.4'
related_resources:
  - text: Dev Portal APIs reference
    url: /dev-portal/apis/
  - text: Self-service developer and application registration
    url: /dev-portal/application-registration/
  - text: Application authentication strategies
    url: /dev-portal/auth-strategies/
faqs:
  - q: I just edited or deleted my spec, document, page, or snippet. Why don't I immediately see these changes live in the Dev Portal?
    a: If you recently viewed the related content, your browser might be serving a cached version of the page. To fix this, you can clear your browser cache and refresh the page. 
next_steps:
  - text: Apply an authentication strategy to your APIs
    url: /dev-portal/auth-strategies/
---

## Create an API

In this tutorial, you'll automate your API catalog by creating an API along with a document and spec, associating it with a Gateway Service, and finally publishing it to a Dev Portal. 

First, [create an API](/api/konnect/api-builder/v3/#/operations/create-api) using the `/v3/apis` endpoint:

<!--vale off-->
{% konnect_api_request %}
url: /v3/apis
status_code: 201
method: POST
body:
    name: MyAPI
    attributes: {"env":["development"],"domains":["web","mobile"]}
{% endkonnect_api_request %}
<!--vale on-->

Export the ID of your API from the response:

```sh
export API_ID='YOUR-API-ID'
```

## Create and associate an API spec and version

[Create and associate a spec and version](/api/konnect/api-builder/v3/#/operations/create-api-version) with your API using the `/v3/apis/{apiId}/versions` endpoint:

<!--vale off-->
{% konnect_api_request %}
url: /v3/apis/$API_ID/versions
status_code: 201
method: POST
body:
    version: 1.0.0
    spec:
        content: '{"openapi":"3.0.3","info":{"title":"Example API","version":"1.0.0"},"paths":{"/example":{"get":{"summary":"Example endpoint","responses":{"200":{"description":"Successful response"}}}}}}'
{% endkonnect_api_request %}
<!--vale on-->

{:.warning}
> APIs should have API documents or specs, and can have both. If neither are specified, {{site.konnect_short_name}} can't render documentation.

## Create and associate an API document 

An [API document](/dev-portal/apis/#documentation) is Markdown documentation for your API that displays in the Dev Portal. You can link multiple API documents to each other with a parent document and child documents.

[Create and associate an API document](/api/konnect/api-builder/v3/#/operations/create-api-document) using the `/v3/apis/{apiId}/documents` endpoint:

<!--vale off-->
{% konnect_api_request %}
url: /v3/apis/$API_ID/documents
status_code: 201
method: POST
body:
    slug: api-document
    status: published
    title: API Document
    content: '# API Document Header'
{% endkonnect_api_request %}
<!--vale on-->

## Associate the API with a Gateway Service

[Gateway Services](/gateway/entities/service/) represent the upstream services in your system. By associating a Service with an API, this allows developers to generate credentials or API keys for your API. 

Before you can associate the API with the Service, you need the Control Plane ID and the ID of the `example-service` Service you [created in the prerequisites](/how-to/automate-api-catalog/#required-entities). 

First, send a request to the `/v2/control-planes` endpoint to [get the ID of the `quickstart` Control Plane](/api/konnect/control-planes/v2/#/operations/list-control-planes):

<!--vale off-->
{% konnect_api_request %}
url: /v2/control-planes?filter%5Bname%5D%5Bcontains%5D=quickstart
status_code: 201
method: GET
{% endkonnect_api_request %}
<!--vale on-->

Export your Control Plane ID:

```sh
export CONTROL_PLANE_ID='YOUR-CONTROL-PLANE-ID'
```

Next, [list Services](/api/konnect/control-planes-config/v2/#/operations/list-service) by using the `/v2/control-planes/{controlPlaneId}/core-entities/services` endpoint:

<!--vale off-->
{% konnect_api_request %}
url: /v2/control-planes/$CONTROL_PLANE_ID/core-entities/services
status_code: 201
method: GET
{% endkonnect_api_request %}
<!--vale on-->

Export the ID of the `example-service`:

```sh
export SERVICE_ID='YOUR-GATEWAY-SERVICE-ID'
```

[Associate the API with a Service](/api/konnect/api-builder/v3/#/operations/create-api-implementation) using the `/v3/apis/{apiId}/implementations` endpoint:

<!--vale off-->
{% konnect_api_request %}
url: /v3/apis/$API_ID/implementations
status_code: 201
method: POST
body:
    service:
        control_plane_id: $CONTROL_PLANE_ID
        id: $SERVICE_ID
{% endkonnect_api_request %}
<!--vale on-->

## Publish the API to Dev Portal

Now you can [publish the API](/api/konnect/api-builder/v3/#/operations/publish-api-to-portal) to your Dev Portal using the `/v3/apis/{apiId}/publications/{portalId}` endpoint:

<!--vale off-->
{% konnect_api_request %}
url: /v3/apis/$API_ID/publications/$PORTAL_ID
status_code: 201
method: PUT
{% endkonnect_api_request %}
<!--vale on-->

## Validate

To validate that the API was created and published in your Dev Portal, navigate to your Dev Portal:

```sh
open https://$PORTAL_URL/apis
```

You should see `MyAPI` in the list of APIs. If an API is published as private, you must enable Dev Portal RBAC and [developers must sign in](/dev-portal/developer-signup/) to see APIs.

