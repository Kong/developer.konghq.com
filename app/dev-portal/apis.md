---
title: Dev Portal APIs
content_type: reference
layout: reference

products:
    - dev-portal

breadcrumbs: 
  - /dev-portal/
beta: true
tags:
  - beta

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
  - text: Publishing
    url: /dev-portal/publishing/
  - text: Application registration
    url: /dev-portal/application-registration/
---

An API is the interface that you publish to your end customer. Developers register [applications](/dev-portal/access-and-approval/) for use with specific APIs.

As an API Producer, you [publish an OpenAPI specification](/dev-portal/publishing) and additional documentation to help users get started with your API.

## Validation

All API specification files are validated during upload. Specs much be valid JSON or YAML, and must be valid according to [OpenAPI 3.x spec](https://spec.openapis.org/). This ensures accurate generation of spec documentation.

## Documentation

Learn how to manage documents for your APIs in Dev Portal.

### Create a new API document

1. Navigate to a specific API from [APIs](/dev-portal/apis) or [Published APIs](/dev-portal/publishing).
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

## Validation

All API specification files are validated during upload. Specs much be valid JSON or YAML, and must be valid according to [OpenAPI 3.x spec](https://spec.openapis.org/). This ensures accurate generation of spec documentation.

## Publishing 

Publishing an API in the Dev Portal involves several steps:

1. Create a new API, including the [API version](/dev-portal/apis/#versioning).
2. Upload an OpenAPI spec and/or markdown documentation (one of these is required to generate API docs).
3. Link the API to a [Gateway Service](/dev-portal/#gateway-service-link).
4. [Publish the API to a Portal](/dev-portal/publishing/).

Once published, the API appears in the selected Portal. If [user authentication](/dev-portal/security-settings/) is enabled, developers can register, create applications, generate credentials, and begin using the API.

If [RBAC](/dev-portal/security-settings/) is enabled, approved developers must be assigned to a [Team](/dev-portal/access-and-approval/) to access the API.

## Gateway service link

{{site.konnect_short_name}} APIs support linking to a {{site.konnect_short_name}} Gateway Service to enable Developer self-service and generate credentials or API keys. 
This link will install the {{site.konnect_short_name}} Application Auth (KAA) plugin on that Service. The KAA plugin can only be configured from the associated Dev Portal and its published APIs.

{:.info}
> When linking an **API** to a **Gateway Service**, it is currently a 1:1 mapping.

1. Browse to a **APIs**, or **Published APIs** for a specific Dev Portal, and select a specific API
1. Click on the **Gateway Service** tab
1. Click **Link Gateway Service**
1. Select the appropriate Control Plane and Gateway Service
1. Click **Submit**

If you want the Gateway Service to restrict access to the API, [configure developer & application registration for your Dev Portal](/dev-portal/application-registration/).