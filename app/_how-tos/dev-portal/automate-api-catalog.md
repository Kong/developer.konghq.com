---
title: Automate your API catalog with the Konnect API
permalink: /how-to/automate-api-catalog/
description: Learn how to automate your API catalog in Dev Portal using Konnect APIs.
content_type: how_to
automated_tests: false
products:
    - gateway
    - dev-portal
    - catalog
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
    q: How do I automate the creation and publication of my API catalog in Catalog and Dev Portal?
    a: You can automate the creation and publication of APIs to your Dev Portal API catalog using the {{site.konnect_short_name}} API. Create an API (`/v3/apis`), optionally associate a document (`/v3/apis/{apiId}/documents`) or spec (`/v3/apis/{apiId}/versions`) with the API, then associate the API with a Gateway Service (`/v3/apis/{apiId}/implementations`). Finally, publish it by sending a `PUT` request to the `/v3/apis/{apiId}/publications/{portalId}` endpoint.

prereqs:
  inline:
    - title: "{{site.konnect_product_name}} roles"
      include_content: prereqs/dev-portal-automate-api-catalog-roles
      icon_url: /assets/icons/gateway.svg
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
  - text: Catalog APIs reference
    url: /catalog/apis/
  - text: Self-service developer and application registration
    url: /dev-portal/application-registration/
  - text: Application authentication strategies
    url: /dev-portal/auth-strategies/
  - text: Package APIs with Dev Portal
    url: /how-to/package-apis-with-dev-portal/
faqs:
  - q: I just edited or deleted my spec, document, page, or snippet. Why don't I immediately see these changes live in the Dev Portal?
    a: If you recently viewed the related content, your browser might be serving a cached version of the page. To fix this, you can clear your browser cache and refresh the page.
  - q: How do I allow developers to view multiple versions of an API in the Dev Portal?
    a: |
      Use the [`/apis/{apiId}/versions` endpoint](/api/konnect/api-builder/v3/#/operations/create-api-version) to publish multiple versions of an API. Developers can then select which API version to view in the Dev Portal spec renderer. Each version reflects how the endpoints were documented at a specific time. It doesn’t reflect the actual implementation, which will usually align with the latest version. Changing the version in the dropdown only changes the specs you see. It **does not** change the requests made with application credentials or app registration.
      
      There are two exceptions when the underlying implementation should match the selected version:
      * With [Dev Portal app registration](/dev-portal/self-service/): If non-current versions have Route configurations that allow requests to specify the version in some way, each version must document how to modify the request to access the given version (for example, using a header). 
      * Without Dev Portal app registration: If the version can be accessed separately from other versions of the same API, each version must document how to modify the request to access the given version.
  - q: How does {{site.konnect_short_name}} manage authentication and authorization on Gateway Services that are linked to my APIs?
    a: |
      When a Gateway Service is linked to an API, {{site.konnect_short_name}} automatically adds the [{{site.konnect_short_name}} Application Auth (KAA) plugin](/catalog/apis/#allow-developers-to-consume-your-api) to your Service. The KAA plugin applies authentication and authorization to the Service. This is a {{site.konnect_short_name}}-managed plugin that you can't directly modify, you can only modify it by configuring JSON in the advanced configuration for your [application auth strategy](/dev-portal/auth-strategies/). 
next_steps:
  - text: Apply an authentication strategy to your APIs
    url: /dev-portal/auth-strategies/
  - text: Create API packages
    url: /catalog/api-packaging/
---

## Create an API

In this tutorial, you'll automate your API catalog by creating an API in [Catalog](/service-catalog/) along with a document and spec, associating it with a Gateway Service, and finally publishing it to a [Dev Portal](/dev-portal/). 

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

An [API document](/catalog/apis/#documentation) is Markdown documentation for your API that displays in the Dev Portal. You can link multiple API documents to each other with a parent document and child documents.

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

