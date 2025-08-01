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
  - q: Why don't I see API Products in my {{site.konnect_short_name}} sidebar?
    a: |
      [API Products](/api-products/) were used to create and publish APIs to classic (v2) Dev Portals. When the new (v3) Dev Portal was released, the API Products menu item was removed from the sidebar navigation of any {{site.konnect_short_name}} organization that didn't have an existing API product. If you want to create and publish APIs, you can create a new (v3) Dev Portal. To get started, see [Automate your API catalog with Dev Portal](/how-to/automate-api-catalog/).
---

An API is the interface that you publish to your end customer. They can, and should, include an OpenAPI or AsyncAPI specification or additional documentation to help users get started with your API. 

Additionally, you can link your API to a Gateway Service to allow developers register [applications](/dev-portal/self-service/) for your specific APIs.

To create an API, navigate to **Dev Portal > APIs** in the sidebar, and then click [**New API**](https://cloud.konghq.com/portals/apis/create).

## API specs

All API specification files are validated during upload, although invalid specifications are permitted. If specifications are invalid, features like generated documentation and search may be degraded. 

To upload a spec to an API, navigate to [**Dev Portal > APIs**](https://cloud.konghq.com/portals/apis) in the sidebar and click your API. Click the **API specification** tab, and then click **Upload Spec**.

### API spec validation

{{site.konnect_short_name}} looks for the following during spec validation:

* Specs must be valid JSON or YAML.
* Spec should be valid according to the [OpenAPI 2.x or 3.x specification](https://spec.openapis.org/) or the [AsyncAPI 2.x or 3.0.0 specification](https://www.asyncapi.com/docs/reference/specification/v3.0.0).
    * OAS validation is performed using [Spectral](https://github.com/stoplightio/spectral).
    * To replicate validation in your own CI/CD pipeline, run `spectral lint [spec.yaml] .spectral.yaml`, where `.spectral.yaml` should contain the following: 
        * OpenAPI `spectral.yaml`: Should contain `extends: "spectral:oas"`.
        * AsyncAPI `spectral.yaml`: Should contain `extends: "spectral:asyncapi"`.
* Invalid specs are permitted (with potential degraded experience), and `validation_messages` captures any validation issues.

## Allow developers to consume your API

{{site.konnect_short_name}} APIs support linking to a {{site.konnect_short_name}} Gateway Service to enable Developer self-service and generate credentials or API keys. This is available to data planes running {{site.base_gateway}} 3.6 or later.
This will install the {{site.konnect_short_name}} Application Auth (KAA) plugin on that Service. The KAA plugin can only be configured from the associated Dev Portal and its published APIs.

{:.info}
> When linking an **API** to a **Gateway Service**, it is currently a 1:1 mapping.

To link your API to a Gateway Service, navigate to [**Dev Portal > APIs**](https://cloud.konghq.com/portals/apis) in the sidebar and click your API. Click the **Gateway Service** tab, and then click **Link Gateway Service**. 

If you want the Gateway Service to restrict access to the API, [configure developer & application registration for your Dev Portal](/dev-portal/self-service/).

## API documentation

API documentation is content in Markdown that you can use to provide additional information about your API. 

To create a new API document, navigate to [**Dev Portal > APIs**](https://cloud.konghq.com/portals/apis) in the sidebar and click your API. Click the **Documentation** tab, and then click **New document**. You can either upload your documentation as an existing a Markdown file or create a new document.

### Page structure

The `slug` and `parent` fields create a tree of documents, and build the URL based on the slug/parent relationship. 
This document structure lives under a given API.

* **Page name**: The name used to populate the `title` in the front matter of the Markdown document
* **Page slug**: The `slug` used to build the URL for the document within the document structure
* **Parent page**: When creating a document, selecting a parent page creates a tree of relationships between the pages. This allows for effectively creating categories of documentation.

For example, if you had a document configured like the following:

* **API slug**: `routes`
* **API version**: `v3`
* **Page 1:** `about`, parent `null`
* **Page 2:** `info`, parent `about`

Based on this data, you get the following generated URLs:
* Generated URL for `about` page: `/apis/routes-v3}/docs/about`
* Generated URL for `info` page: `/apis/routes-v3}/docs/about/info`

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

## Publishing and visibility

When the document is complete, toggle **Published** to **on** to make the page available in your Portal, assuming all parent pages are in **Published** status as well.

* The visibility of an API document is inherited from the API's visibility and access controls. 
* If a parent page is unpublished, all child pages will also be unpublished. 
* If no parent pages are published, no API documentation will be visible, and the APIs list will navigate directly to generated specifications.

As an API Producer, you can [publish an OpenAPI specification](/dev-portal/publishing) and additional documentation to help users get started with your API.

Publishing an API makes it available to one or more Dev Portals. 
With the appropriate [security](/dev-portal/security-settings/) and [access and approval](/dev-portal/self-service/) settings, you can publish an API securely to the appropriate audience.

Make sure you have [created APIs](/dev-portal/apis/) before attempting to publish to them your Dev Portals.

### Access control scenarios

Visibility, authentication strategies, and user authentication can be independently configured to maximize flexibility in how you publish your API to a given developer audience. 

{:.info}
> * The visibility of [pages](/dev-portal/pages-and-content/) and [menus](/dev-portal/portal-customization/) is configured independently from APIs, maximizing your flexibility.
> * {% new_in 3.6 %} An API must be linked to a {{site.konnect_short_name}} Gateway Service to be able to restrict access to your API with authentication strategies.

The following table describes various Dev Portal access control scenarios and their settings:

<!--vale off-->
{% table %}
columns:
  - title: Access use case
    key: use-case
  - title: Visibility
    key: visibility
  - title: Authentication strategy
    key: strategy
  - title: User authentication
    key: user-auth
  - title: Description
    key: description
rows:
  - use-case: Viewable by anyone, no self-service credentials
    visibility: Public
    strategy: Disabled
    user-auth: "Disabled in [security settings](/dev-portal/security-settings/)"
    description: Anyone can view the API's specs and documentation, but cannot generate credentials and API keys. No developer registration is required.
  - use-case: Viewable by anyone, self-service credentials
    visibility: Public
    strategy: "`key-auth` (or any other appropriate authentication strategy)"
    user-auth: "Enabled in [security settings](/dev-portal/security-settings/)"
    description: |
      Anyone can view the API's specs and documentation, but must sign up for a developer account and create an Application to generate credentials and API keys. 
      <br><br>
      RBAC is disabled if fine-grained access management is not needed, configured in [security settings](/dev-portal/security-settings/).
  - use-case: Viewable by anyone, self-service credentials with RBAC
    visibility: Public
    strategy: "`key-auth` (or any other appropriate Authentication strategy)"
    user-auth: "Enabled in [security settings](/dev-portal/security-settings/)"
    description: |
      Anyone can view the API's specs and documentation, but must sign up for a developer account and create an Application to generate credentials and API keys. 
        <br><br>
        A {{site.konnect_short_name}} Admin must assign a developer to a Team to provide specific role-based access. RBAC is enabled to allow [Teams](/dev-portal/access-and-approval) assignments for developers, granting credentials with the API Consumer role.
  - use-case: Sign up required to view API specs and/or documentation
    visibility: Private
    strategy: "`key-auth` (or any other appropriate Authentication strategy)"
    user-auth: "Enabled in [security settings](/dev-portal/security-settings/)"
    description: |
      All users must sign up for a Developer account to view APIs. They can optionally create an Application to generate credentials/API keys. 
      <br><br>
      RBAC can be enabled for [Teams](/dev-portal/access-and-approval) assignments for developers, granting credentials with the API Consumer role, configured in [security settings](/dev-portal/security-settings/).
{% endtable %}
<!--vale on-->

### Publish an API to a Dev Portal

There are two methods for publishing an API:
* Click on your Dev Portal, and select **Published APIs**. Click **Publish**
* Click on **APIs**, and select the API you want to publish. Click **Publish**

In both cases, you'll see the same dialog:

1. Select the **Dev Portal** you want to publish the API to.
2. Select an **Authentication Strategy**. 

   The default value for this setting is set in **Settings > Security** for the specific Dev Portal. 
   This determines how developers will generate credentials to call the API.

3. Select the appropriate **Visibility**. 
  
   The default value for this setting is set in **Settings > Security** for the specific Dev Portal. 
   Visibility determines if developers need to register to view the API or generate credentials and API keys. 

### Change a published API

Change the **Visibility** or **Authentication Strategy** of an API that has been published to one or more Dev Portals:

1. Browse to a **Published API**.
2. Select the **Portals** tab to see where the API has been previously published.
3. Click the menu icon next to the appropriate Dev Portal, select **Edit Publication**.
4. Change **Visibility** and **Authentication Strategy** to the appropriate values.
5. Click **Save**.

### Publishing steps

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
