---
title: Dev Portal APIs
content_type: reference
layout: reference

products:
    - dev-portal

breadcrumbs: 
  - /dev-portal/
tags:
  - api-catalog

works_on:
    - konnect
api_specs:
  - konnect/api-builder
search_aliases:
  - postman
  - publish API specs
description: | 
    An API is the interface that you publish to your end customer. Developers register applications for use with specific API.
related_resources:
  - text: Automate your API catalog with Dev Portal
    url: /how-to/automate-api-catalog/
  - text: Publishing
    url: /dev-portal/publishing/
  - text: Developer self-service and app registration
    url: /dev-portal/self-service/
faqs:
  - q: I'm using the Try it feature in the spec renderer to send requests from Dev Portal, but I'm getting a `401`. How do I fix it?
    a: If the published API has an [authentication strategy](/dev-portal/auth-strategies/) configured for it, you must include your key in the request. All requests without a key to the Service linked to the API are blocked if it is published with an auth strategy.
  - q: I just edited or deleted my spec, document, page, or snippet. Why don't I immediately see these changes live in the Dev Portal?
    a: If you recently viewed the related content, your browser might be serving a cached version of the page. To fix this, you can clear your browser cache and refresh the page. 
  - q: How do I allow developers to view multiple versions of an API in the Dev Portal?
    a: |
      Use the [`/apis/{apiId}/versions` endpoint](/api/konnect/api-builder/v3/#/operations/create-api-version) to publish multiple versions of an API. Developers can then select which API version to view in the Dev Portal spec renderer. Each version reflects how the endpoints were documented at a specific time. It doesn’t reflect the actual implementation, which will usually align with the latest version. Changing the version in the dropdown only changes the specs you see. It **does not** change the requests made with application credentials or app registration.
      
      There are two exceptions when the underlying implementation should match the selected version:
      * With [Dev Portal app registration](/dev-portal/self-service/): If non-current versions have Route configurations that allow requests to specify the version in some way, each version must document how to modify the request to access the given version (for example, using a header). 
      * Without Dev Portal app registration: If the version can be accessed separately from other versions of the same API, each version must document how to modify the request to access the given version.
  - q: Why don't I see API Products in my {{site.konnect_short_name}} sidebar?
    a: API Products were used to create and publish APIs to classic (v2) Dev Portals. When the new (v3) Dev Portal was released, the API Products menu item was removed from the sidebar navigation of any {{site.konnect_short_name}} organization that didn't have an existing API product. If you want to create and publish APIs, you can create a new (v3) Dev Portal. To get started, see [Automate your API catalog with Dev Portal](/how-to/automate-api-catalog/).
---

An API is the interface that you publish to your end customer. Developers register [applications](/dev-portal/self-service/) for use with specific APIs.

As an API Producer, you [publish an OpenAPI or AsyncAPI specification](/dev-portal/publishing) and additional documentation to help users get started with your API.

## Validation

All API specification files are validated during upload, although invalid specifications are permitted. If specifications are invalid, features like generated documentation and search may be degraded.

{{site.konnect_short_name}} looks for the following during spec validation:

* Specs must be valid JSON or YAML.
* Spec should be valid according to the [OpenAPI 2.x or 3.x specification](https://spec.openapis.org/) or the [AsyncAPI 2.x or 3.0.0 specification](https://www.asyncapi.com/docs/reference/specification/v3.0.0).
    * OAS validation is performed using [Spectral](https://github.com/stoplightio/spectral).
    * To replicate validation in your own CI/CD pipeline, run `spectral lint [spec.yaml] .spectral.yaml`, where `.spectral.yaml` should contain the following: 
        * OpenAPI `spectral.yaml`: Should contain `extends: "spectral:oas"`.
        * AsyncAPI `spectral.yaml`: Should contain `extends: "spectral:asyncapi"`.
* Invalid specs are permitted (with potential degraded experience), and `validation_messages` captures any validation issues.

## Documentation

Learn how to manage documents for your APIs in Dev Portal.

### Create a new API document

1. Navigate to a specific API from [APIs](https://cloud.konghq.com/portals/apis/) or [Published APIs](/dev-portal/publishing).
2. Select the **Documentation** tab.
3. Click **New Document**.
4. Select **Start with a file** then **Upload a Markdown document**, or **Start with an empty document** and provide the Markdown content.

### Page structure

The `slug` and `parent` fields create a tree of documents, and build the URL based on the slug/parent relationship. 
This document structure lives under a given API.

* **Page name**: The name used to populate the `title` in the front matter of the Markdown document
* **Page slug**: The `slug` used to build the URL for the document within the document structure
* **Parent page**: When creating a document, selecting a parent page creates a tree of relationships between the pages. This allows for effectively creating categories of documentation.

#### Example

* **API slug**: `routes`
* **API version**: `v3`
* **Page 1:** `about`, parent `null`
* **Page 2:** `info`, parent `about`

Based on this data, you get the following generated URLs:
* Generated URL for `about` page: `/apis/routes-v3}/docs/about`
* Generated URL for `info` page: `/apis/routes-v3}/docs/about/info`

## Publishing and visibility

When the document is complete, toggle **Published** to **on** to make the page available in your Portal, assuming all parent pages are in **Published** status as well.

* The visibility of an API document is inherited from the API's visibility and access controls. 
* If a parent page is unpublished, all child pages will also be unpublished. 
* If no parent pages are published, no API documentation will be visible, and the APIs list will navigate directly to generated specifications.

As an API Producer, you can [publish an OpenAPI specification](/dev-portal/publishing) and additional documentation to help users get started with your API.

## Versioning

The API entity allows you to set a `version` for your APIs. Each API is identified using the combination of `name+version`. If `version` is not specified, then `name` will be used as the unique identifier. 

### Unversioned APIs

If you have an existing unversioned API, you can create an `API` by providing a name only:

```bash
curl -X POST https://us.api.konghq.com/v3/apis \
  -H 'Content-Type: application/json' \
  -d '{"name": "My Test API"}'
```

This API will be accessible as `my-test-api` in your Portal.

### Versioned APIs

To create a versioned API, specify the `version` field when creating an API:

```bash
curl -X POST https://us.api.konghq.com/v3/apis \
  -H 'Content-Type: application/json' \
  -d '{"name": "My Test API", "version": "v3"}'
```

This API will be accessible as `my-test-api-v3` in your list of APIs. The API will not be visible in a portal until you [publish](/dev-portal/publishing).

The `version` field is a free text string. This allows you to follow semantic versioning (e.g. `v1`, `v2`), date based versioning (e.g. `2024-05-10`, `2024-10-22`) or any custom naming scheme (e.g. `a1b2c3-internal-xxyyzz00`)

## Publishing 

Publishing an API in the Dev Portal involves several steps:

1. Create a new API, including the [API version](/dev-portal/apis/#versioning).
2. Upload an OpenAPI spec and/or markdown documentation (one of these is required to generate API docs).
3. Link the API to a [Gateway Service](/dev-portal/#gateway-service-link).
4. [Publish the API to a Portal](/dev-portal/publishing/).

Once published, the API appears in the selected Portal. If [user authentication](/dev-portal/security-settings/) is enabled, developers can register, create applications, generate credentials, and begin using the API.

If [RBAC](/dev-portal/security-settings/) is enabled, approved developers must be assigned to a [Team](/konnect-platform/teams-and-roles/#teams) to access the API.

## Allow developers to try requests from the Dev Portal spec renderer

When you upload a spec for your API to Dev Portal, you can use the **Try it!** feature to allow developers to try your API right from Dev Portal. **Try it!** enables developers to add their authentication credentials, path parameters, and request body from the spec renderer in Dev Portal and send the request with their configuration. 

The **Try it!** feature is enabled by default for published APIs. You can disable it by sending a PATCH request to the [`/v3/portals/{portalId}/customization` endpoint](/api/konnect/portal-management/v3/#/operations/update-portal-customization). You must also enable the CORS plugin for this feature to work. Use the table below to determine the appropriate CORS configuration based on the Routes associated with your APIs:

{% feature_table %} 
item_title: Use case
columns:
  - title: Headers used
    key: headers
  - title: Route configuration
    key: route
  - title: CORS configuration
    key: cors

features:
  - title: "[Simple request](https://developer.mozilla.org/en-US/docs/Web/HTTP/Guides/CORS#simple_requests)"
    headers: None
    route: No special configuration needed
    cors: No CORS configuration required
  - title: Requests with any headers
    headers: Any header
    route: "Add [`methods: OPTIONS`](/gateway/entities/route/#schema-route-methods) to any associated Routes that use the headers."
    cors: "[Enable Try it in Dev Portal for requests with any header](/plugins/cors/examples/try-it-headers/)"
  - title: Routes configured with a header to match
    headers: Any header that is required by the request
    route: |
      Do one of the following:
      * Add a new Route at the same path with [`methods: OPTIONS`](/gateway/entities/route/#schema-route-methods) configured.
      * Add a global Route (a Route that isn't associated with a Service) at the Control Plane-level with [`methods: OPTIONS`](/gateway/entities/route/#schema-route-methods) configured (no path needs to be specified).
    cors: "[Enable Try it in Dev Portal for requests with any header](/plugins/cors/examples/try-it-headers/)"
{% endfeature_table %}


## Filtering published APIs in Dev Portal

You can filter and categorize published APIs on your Dev Portals with custom attributes. By assigning attributes to an API, this allows users to filter APIs in the Dev Portal sidebar. For an API, you can define one or more custom attributes, and each attribute can have one or more values. For example, if you had a Billing API, you could label it with `"visibility": ["Internal"]` and `"platform": ["Web", "Mobile"]`.

For more information about how to use custom attributes for filtering APIs displayed in your Dev Portal, see the [MDC documentation](https://portaldocs.konghq.com/components/apis-list).

## Gateway service link

{{site.konnect_short_name}} APIs support linking to a {{site.konnect_short_name}} Gateway Service to enable Developer self-service and generate credentials or API keys. This is available to Data Planes running {{site.base_gateway}} 3.6 or later.
This link will install the {{site.konnect_short_name}} Application Auth (KAA) plugin on that Service. The KAA plugin can only be configured from the associated Dev Portal and its published APIs.

{:.info}
> When linking an **API** to a **Gateway Service**, it is currently a 1:1 mapping.

1. Browse to a **APIs**, or **Published APIs** for a specific Dev Portal, and select a specific API
1. Click on the **Gateway Service** tab
1. Click **Link Gateway Service**
1. Select the appropriate Control Plane and Gateway Service
1. Click **Submit**

If you want the Gateway Service to restrict access to the API, [configure developer & application registration for your Dev Portal](/dev-portal/self-service/).
