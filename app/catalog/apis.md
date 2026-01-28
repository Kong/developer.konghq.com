---
title: API catalog
content_type: reference
layout: reference

products:
    - catalog
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
  - konnect-application-auth
  - service catalog
description: | 
    An API is the interface that you publish to your end customer. Developers register applications for use with specific API.
related_resources:
  - text: Automate your API catalog with the Konnect API
    url: /how-to/automate-api-catalog/
  - text: Developer self-service and app registration
    url: /dev-portal/self-service/
  - text: Package APIs with Dev Portal
    url: /how-to/package-apis-with-dev-portal/
  - text: API packages reference
    url: /catalog/api-packaging/
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
    a: |
      [API Products](/api-products/) were used to create and publish APIs to classic (v2) Dev Portals. When the new (v3) Dev Portal was released, the API Products menu item was removed from the sidebar navigation of any {{site.konnect_short_name}} organization that didn't have an existing API product. If you want to create and publish APIs, you can create a new (v3) Dev Portal. To get started, see [Automate your API catalog with the Konnect API](/how-to/automate-api-catalog/).
  - q: My team has a Dev Portal, why can't I see APIs?
    a: You need additional permissions to see APIs. See the [Catalog APIs roles](/konnect-platform/teams-and-roles/#catalog-apis) for more information.
---

{:.success}
> This is a reference guide, you can also follow along with our tutorials: 
>* [Automate your API catalog with the Konnect API](/how-to/automate-api-catalog/)
>* [Automate your API catalog with Terraform](/how-to/automate-api-catalog-with-terraform/)

An API is the interface that you publish to your end customer. They can, and should, include an OpenAPI or AsyncAPI specification or additional documentation to help users get started with your API. 

Additionally, you can link your API to a Gateway Service to allow developers to register [applications](/dev-portal/self-service/) for your specific APIs.

To create an API, do one of the following:
{% navtabs "create-api" %}
{% navtab "{{site.konnect_short_name}} UI" %}
Navigate to **Catalog > APIs** in the sidebar, and then click [**New API**](https://cloud.konghq.com/apis/create).
{% endnavtab %}
{% navtab "{{site.konnect_short_name}} API" %}
Send a POST request to the [`/apis` endpoint](/api/konnect/api-builder/v3/#/operations/create-api):
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
{% endnavtab %}
{% navtab "Terraform" %}
Use the [`konnect_api` resource](https://github.com/Kong/terraform-provider-konnect/blob/main/examples/resources/konnect_api.tf):
```hcl
echo '
resource "konnect_api" "my_api" {
  attributes  = "{ \"see\": \"documentation\" }"
  description = "...my_description..."
  labels = {
    key = "value"
  }
  name         = "MyAPI"
  slug         = "my-api-v1"
  spec_content = "...my_spec_content..."
  version      = "...my_version..."
}
' >> main.tf
```
{% endnavtab %}
{% endnavtabs %}

## API versions

When you create an API, you can optionally specify the version as a free text string.

While you can use any version style, we recommend the following:
* Semantic versioning (for example `1.0.0`, `2.1.0`) is best supported for default ordering
* Create a unique API for each major version, since APIs must be unique based on the combination of `name` + `version`

The API `slug` determines Dev Portal URL routing in your [list of APIs](/api/konnect/api-builder/v3/#/operations/list-apis), which defaults to a name and version (major version if semantic versioning) in slug form. For example, if your API is named `my-test-api` and the version is `3`, this will default to `my-test-api-3`. If a version isn't specified, then `name` is used as the unique identifier. 

### API specification versions

If you upload OpenAPI or AsyncAPI specifications when you create the API, the API version will default to and be constrained by the version in the specification. You can specify multiple versions of API specifications in the API entity. Ideally, use multiple versions of API specs for minor versions of an API. When multiple `versions` are specified, a selector displays in the generated API reference to switch between versions of the API specification.

The API entity's `version` property is treated as "current", meaning it is the version that will be listed in your [list of APIs](/api/konnect/api-builder/v3/#/operations/list-apis). 


To version an API, do one of the following:
{% navtabs "api-version" %}
{% navtab "{{site.konnect_short_name}} UI" %}
1. In the {{site.konnect_short_name}} sidebar, click [**{{site.konnect_catalog}}**](https://cloud.konghq.com/service-catalog/).
1. Click [**New API**](https://cloud.konghq.com/apis/create).
1. Enter a version in the **API version** field, or upload an API specification, which will set the version to match the API spec version. 

You can also add versions to existing APIs when you edit them if they aren't associated with an API specification. To manage multiple versions of the API specification, do the following:
1. In the {{site.konnect_short_name}} sidebar, click [**{{site.konnect_catalog}}**](https://cloud.konghq.com/service-catalog/). 
1. Click your API. 
1. Click the **API specification** tab.
1. From the Actions dropdown menu, select "Add or update API spec". 
1. If a newer version is in the API specification, you will be prompted to add a new `version` and set the current version.
{% endnavtab %}
{% navtab "{{site.konnect_short_name}} API" %}
Send a POST request to the [`/apis/{apiId}/versions` endpoint](/api/konnect/api-builder/v3/#/operations/create-api-version):
{% konnect_api_request %}
url: /v3/apis/$API_ID/versions
status_code: 201
method: POST
body:
    version: 1.0.0
    spec:
        content: '{"openapi":"3.0.3","info":{"title":"Example API","version":"1.0.0"},"paths":{"/example":{"get":{"summary":"Example endpoint","responses":{"200":{"description":"Successful response"}}}}}}'
{% endkonnect_api_request %}
{% endnavtab %}
{% navtab "Terraform" %}
Use the [`konnect_api_version` resource](https://github.com/Kong/terraform-provider-konnect/blob/main/examples/resources/konnect_api_version.tf):
```hcl
echo '
resource "konnect_api_version" "my_apiversion" {
  api_id = "9f5061ce-78f6-4452-9108-ad7c02821fd5"
  spec = {
    content = "{\"openapi\":\"3.0.3\",\"info\":{\"title\":\"Example API\",\"version\":\"1.0.0\"},\"paths\":{\"/example\":{\"get\":{\"summary\":\"Example endpoint\",\"responses\":{\"200\":{\"description\":\"Successful response\"}}}}}}"
  }
  version = "1.0.0"
}
' >> main.tf
```
{% endnavtab %}
{% endnavtabs %}


### API spec validation

All API specification files are validated during upload, although invalid specifications are permitted. If specifications are invalid, features like generated documentation and search may be degraded. 

{{site.konnect_short_name}} looks for the following during spec validation:

* Specs must be valid JSON or YAML.
* Spec should be valid according to the [OpenAPI 2.x or 3.x specification](https://spec.openapis.org/) or the [AsyncAPI 2.x or 3.0.0 specification](https://www.asyncapi.com/docs/reference/specification/v3.0.0).
    * OAS validation is performed using [Spectral](https://github.com/stoplightio/spectral).
    * To replicate validation in your own CI/CD pipeline, run `spectral lint [spec.yaml] .spectral.yaml`, where `.spectral.yaml` should contain the following: 
        * OpenAPI `spectral.yaml`: Should contain `extends: "spectral:oas"`.
        * AsyncAPI `spectral.yaml`: Should contain `extends: "spectral:asyncapi"`.
* Invalid specs are permitted (with potential degraded experience), and `validation_messages` captures any validation issues.

## API documentation

API documentation is content in Markdown that you can use to provide additional information about your API.

While you are creating or editing an API document, you can also choose to publish it and make it available in your [Dev Portal](/dev-portal/) (assuming all parent pages are published as well). Keep the following in mind:
* The visibility of an API document is inherited from the API's visibility and access controls. 
* If a parent page is unpublished, all child pages will also be unpublished. 
* If no parent pages are published, no API documentation will be visible, and the APIs list will navigate directly to generated specifications.

To create a new API document, do one of the following:
{% navtabs "link-service" %}
{% navtab "{{site.konnect_short_name}} UI" %}
Navigate to [**Catalog > APIs**](https://cloud.konghq.com/apis) in the sidebar and click your API. Click the **Documentation** tab, and then click **New document**. You can either upload your documentation as an existing a Markdown file or create a new document.
{% endnavtab %}
{% navtab "{{site.konnect_short_name}} API" %}
Send a POST request to the [`/apis/{apiId}/documents` endpoint](/api/konnect/api-builder/v3/#/operations/create-api-document):
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
{% endnavtab %}
{% navtab "Terraform" %}
Use the [`konnect_api_document` resource](https://github.com/Kong/terraform-provider-konnect/blob/main/examples/resources/konnect_api_document.tf):
```hcl
echo '
resource "konnect_api_document" "my_apidocument" {
  api_id             = "9f5061ce-78f6-4452-9108-ad7c02821fd5"
  content            = "...my_content..."
  parent_document_id = "b689d9da-f357-4687-8303-ec1c14d44e37"
  slug               = "api-document"
  status             = "published"
  title              = "API Document"
}
' >> main.tf
```
{% endnavtab %}
{% endnavtabs %}

### Page structure

The `slug` and `parent` fields create a tree of documents, and build the URL based on the slug/parent relationship. 
This document structure lives under a given API:

* **Page name**: The name used to populate the `title` in the front matter of the Markdown document
* **Page slug**: The `slug` used to build the URL for the document within the document structure
* **Parent page**: When creating a document, selecting a parent page creates a tree of relationships between the pages. This allows for effectively creating categories of documentation.

For example, if you had a document configured like the following:

* **API slug**: `routes`
* **API version**: `v3`
* **Page 1:** `about`, parent `null`
* **Page 2:** `info`, parent `about`

Based on this data, you get the following generated URLs:
* Generated URL for `about` page: `/apis/routes-v3/docs/about`
* Generated URL for `info` page: `/apis/routes-v3/docs/about/info`

## Allow developers to consume your API

You can link to a {{site.konnect_short_name}} [Gateway Service](/gateway/entities/service/) to allow developers to create applications and generate credentials or API keys. This is available to data planes running {{site.base_gateway}} 3.6 or later.

When you link a service with an API, {{site.konnect_short_name}} automatically adds the {{site.konnect_short_name}} Application Auth (KAA) plugin on that Service. The KAA plugin is responsible for applying authentication and authorization on the Service. The [authentication strategy](/dev-portal/auth-strategies/) that you select for the API defines how clients authenticate. While you can't directly modify the KAA plugin as it's managed by {{site.konnect_short_name}}, you can modify the plugin's behavior by adding JSON to the advanced configuration of your application auth strategy. 

The following diagram shows how the KAA plugin manages authorization and authentication on the linked Service:

<!--vale off-->
{% mermaid %}
sequenceDiagram
    actor Client
    Client->> Kong:
    Kong->>Konnect Application Auth: Send request
    Konnect Application Auth->>Konnect Application Auth: Authenticate the request based on the auth strategy

    rect rgb(191, 223, 255)
    note right of Konnect Application Auth: OIDC Strategy.
    Konnect Application Auth-->> OIDC Plugin: 
    OIDC Plugin->> IdP: Sends credentials request
    IdP ->> OIDC Plugin: return JWT token
    OIDC Plugin-->>Konnect Application Auth:
    end
    rect rgb(191, 223, 255)
    note right of Konnect Application Auth: Key Auth Strategy.
    Konnect Application Auth->>Konnect Application Auth: Authenticate Api Key
    end

    Konnect Application Auth->>Konnect Application Auth: Authorize the request with the authenticated client
    Konnect Application Auth->>Kong:
    Kong->>Client:
 {% endmermaid %}
 <!--vale on-->

If you want the Gateway Service to restrict access to the API, [configure developer and application registration for your Dev Portal](/dev-portal/self-service/).

To link your API to a Gateway Service, do one of the following:
{% navtabs "link-service" %}
{% navtab "{{site.konnect_short_name}} UI" %}
Navigate to [**Catalog > APIs**](https://cloud.konghq.com/apis) in the sidebar and click your API. Click the **Gateway Service** tab, and then click **Link Gateway Service**.
{% endnavtab %}
{% navtab "{{site.konnect_short_name}} API" %}
Send a POST request to the [`/apis/{apiId}/implementations` endpoint](/api/konnect/api-builder/v3/#/operations/create-api-implementation):
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
{% endnavtab %}
{% navtab "Terraform" %}
Use the [`konnect_api_implementation` resource](https://github.com/Kong/terraform-provider-konnect/blob/main/examples/resources/konnect_api_implementation.tf):
```hcl
echo '
resource "konnect_api_implementation" "my_apiimplementation" {
  api_id = "9f5061ce-78f6-4452-9108-ad7c02821fd5"
  service = {
    control_plane_id = "9f5061ce-78f6-4452-9108-ad7c02821fd5"
    id               = "7710d5c4-d902-410b-992f-18b814155b53"
  }
}
' >> main.tf
```
{% endnavtab %}
{% endnavtabs %}

{:.info}
> Currently, you APIs can only have a 1:1 mapping with a Gateway Service.

## Publish your API to Dev Portal

Publishing an API makes it available to one or more [Dev Portals](/dev-portal/). Publishing an API in the Dev Portal involves several steps:

1. Create a new API, including the [API version](#api-versioning).
2. Upload an OpenAPI spec and/or markdown documentation (one of these is required to generate API docs).
3. If you want developers to consume the API in a self-serve way, link the API to a [Gateway Service](#allow-developers-to-consume-your-api).
4. Publish the API to a Portal and apply an [auth strategy](/dev-portal/auth-strategies/). 
   Publishing an API requires you to have the [`Product Publisher` {{site.konnect_short_name}} role](/konnect-platform/teams-and-roles/#dev-portal).

{:.info}
> * The visibility of [pages](/dev-portal/pages-and-content/) and [menus](/dev-portal/customizations/dev-portal-customizations/) is configured independently from APIs, maximizing your flexibility.
> * {% new_in 3.6 %} An API must be linked to a {{site.konnect_short_name}} Gateway Service to be able to restrict access to your API with authentication strategies.

With the appropriate [security](/dev-portal/security-settings/) and [access and approval](/dev-portal/self-service/) settings, you can publish an API securely to the appropriate audience. The following table describes various Dev Portal access control scenarios and their settings:

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

To publish your API, do one of the following:
{% navtabs "link-service" %}
{% navtab "{{site.konnect_short_name}} UI" %}
Navigate to [**Catalog > APIs**](https://cloud.konghq.com/apis) in the sidebar and click your API. Click the **Portals** tab, and then click **Publish API**.
{% endnavtab %}
{% navtab "{{site.konnect_short_name}} API" %}
Send a PUT request to the [`/apis/{apiId}/publications/{portalId}` endpoint](/api/konnect/api-builder/v3/#/operations/publish-api-to-portal):
<!--vale off-->
{% konnect_api_request %}
url: /v3/apis/$API_ID/publications/$PORTAL_ID
status_code: 201
method: PUT
{% endkonnect_api_request %}
<!--vale on-->
{% endnavtab %}
{% navtab "Terraform" %}
Use the [`konnect_api_publication` resource](https://github.com/Kong/terraform-provider-konnect/blob/main/examples/resources/konnect_api_publication.tf):
```hcl
echo '
resource "konnect_api_publication" "my_apipublication" {
  api_id = "9f5061ce-78f6-4452-9108-ad7c02821fd5"
  auth_strategy_ids = [
    "9c3bed4d-0322-4ea0-ba19-a4bd65d821f6"
  ]
  auto_approve_registrations = true
  portal_id                  = "f32d905a-ed33-46a3-a093-d8f536af9a8a"
  visibility                 = "private"
}
' >> main.tf
```
{% endnavtab %}
{% endnavtabs %}

Once published, the API appears in the selected Dev Portal. If [user authentication](/dev-portal/security-settings/) is enabled, developers can register, create applications, generate credentials, and begin using the API. If [RBAC](/dev-portal/security-settings/) is enabled, approved developers must be assigned to a team to access the API.

### Allow developers to try requests from the Dev Portal spec renderer

When you upload a spec for your API to Dev Portal, you can use the **Try it!** feature to allow developers to try your API right from Dev Portal. **Try it!** enables developers to add their authentication credentials, path parameters, and request body from the spec renderer in Dev Portal and send the request with their configuration. 

The **Try it!** feature is enabled by default for published APIs. You can disable it by sending a PATCH request to the [`/v3/portals/{portalId}/customization` endpoint](/api/konnect/portal-management/v3/#/operations/update-portal-customization). 


You may need to enable the CORS plugin for this feature to work. Use the table below to determine the appropriate CORS configuration based on the Routes associated with your APIs:

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

When using OAuth2 flows, some IdPs may require including additional parameters for token requests. You can include the `x-kong-client-credentials-config` property in `oauth2` type `securitySchemes` to allow users to input specific values for predefined parameters.

For example, this configuration allows spec renderer users to specify a custom audience value that is specific to their request:

```yaml
components:
  securitySchemes:
    oauth2:
      type: oauth2
      x-kong-client-credentials-config:
        extraTokenRequestParameters:
          - name: audience
            label: Audience
            description: The audience of the authorization server to scope tokens to
            omitIfEmpty: true
            required: true
      flows:
        clientCredentials:
          tokenUrl: 'https://example.com/oauth/token'
```

### Filtering published APIs in Dev Portal

You can filter and categorize published APIs on your Dev Portals with custom attributes. By assigning attributes to an API, this allows users to filter APIs in the Dev Portal sidebar. For an API, you can define one or more custom attributes, and each attribute can have one or more values. For example, if you had a Billing API, you could label it with `"visibility": ["Internal"]` and `"platform": ["Web", "Mobile"]`.

For more information about how to use custom attributes for filtering APIs displayed in your Dev Portal, see the [MDC documentation](https://portaldocs.konghq.com/components/apis-list).
