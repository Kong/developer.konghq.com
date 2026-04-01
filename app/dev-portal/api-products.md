---
title: API Products
content_type: reference
layout: reference
permalink: /api-products/
products:
    - dev-portal
tags:
  - api-products
works_on:
    - konnect
api_specs:
  - konnect/api-products

search_aliases:
  - Dev Portal v2
  - classic Dev Portal
  - Portal

breadcrumbs:
  - /dev-portal/

description: "Learn about how to use API Products with classic Dev Portals (v2) to create and publish APIs."
faqs:
  - q: Why don't I see API Products in my {{site.konnect_short_name}} sidebar?
    a: API Products were used to create and publish APIs to classic (v2) Dev Portals. When the new (v3) Dev Portal was released, the API Products menu item was removed from the sidebar navigation of any {{site.konnect_short_name}} organization that didn't have an existing API product. If you want to create and publish APIs, you can create a new (v3) Dev Portal. To get started, see [Automate your API catalog with the Konnect API](/how-to/automate-api-catalog/). 
  - q: I have the `API Products Publisher` role for the API product I want to publish, why don't I see any classic Dev Portals that I can publish to?
    a: To publish API products to a classic Dev Portal, you need at least a `Viewer` role for Dev Portal in addition to the `API Products Publisher` role.
related_resources:
  - text: Create and publish APIs in new Dev Portals (v3)
    url: /catalog/apis/
  - text: Migrate your classic Dev Portal (v2) Terraform resource
    url: /dev-portal/migrate-classic-dev-portal-resource-with-terraform/
---

{:.warning}
> **API Products are only available with classic Dev Portals (v2)** <br>
> The new Dev Portal (v3) provides a more modern approach to API creation and publishing. See [Automate your API catalog with the Konnect API](/how-to/automate-api-catalog/) for a complete tutorial about how to create and publish APIs in v3 Dev Portal.

API Products bundles and manages multiple Gateway Services. Each API product consists of at least one API product version, and each API product version is connected to a Gateway Service. You can document your Services and publish API products to a classic Dev Portal (v2) for consumption.

## API product dashboard

The API Product dashboard is the place to manage API products, versions, and documentation. The dashboard is available by clicking any API product from [API Products](https://cloud.konghq.com/api-products/) in the sidebar. 

Here are some of the things you can do from the API Product dashboard: 

* Configure an API product
* Publish an API product to the v2 Dev Portal
* Manage API product versions
* View traffic, error, and latency data

{:.info}
> **Note**: API products can only be published to the v2 Dev Portal in the [geographic region](/konnect-platform/geos/) you currently have selected. To publish to a v2 Dev Portal in a different region, switch geos using the control in the bottom-left corner of {{site.konnect_short_name}}.

## API product versions

A {{site.konnect_short_name}} API product version is linked to a Gateway Service inside a control plane. As such, the configurations or plugins that are associated with the Gateway Service are also associated with the API product version. 

API products can have multiple API product versions, and each version can be linked to a Gateway Service. API products can be made available in multiple environments by linking API product versions to Gateway Services in different control planes. You can also associate an API spec with a product version and make the spec accessible in the v2 Dev Portal.

A common use case is environment specialization.
For example, if you have three control planes for `development`, `staging`, and
`production`, you can manage which environment the API product version is available in by
linking an API product version to a Gateway Service in that control plane. You might have v1 running
in `production`, and be actively working on v2 in `development`. Once it's
ready to test, you'd create v2 in `staging` before finally creating v2 in
`production` alongside v1.

## API product analytics

The analytics dashboard shown in the API product **Overview** is a high level overview of traffic, error, and latency for the API product. These reports are generated automatically based on the traffic to the API product. 

## API product documentation

A core function of the Dev Portal is publishing API product descriptions, documentation, and API specs. Developers can use the v2 Dev Portal to access, consume, and register new applications against your API product.

Manage your API product's documentation directly within the **Documentation** section of the [API Product dashboard](https://cloud.konghq.com/api-products/). After uploading documentation, you can edit it seamlessly from the {{site.konnect_short_name}} dashboard. Documentation is accessible after the API product is published.

You can provide extended descriptions of your API products with a Markdown (`.md`) file. The contents of this file will be displayed as the introduction to your API in the v2 Dev Portal. API product descriptions can be any markdown document that describes your Service such as:

* Release notes
* Support and SLA 
* Business context and use cases
* Deployment workflows

### Interactive markdown renderer

The integrated markdown editor allows you to　create and edit documentation directly within {{site.konnect_short_name}}. It supports:

* Code syntax highlighting for Bash, JSON, Go, and JavaScript
* Rendering UML diagrams and flowcharts via Mermaid and PlantUML
* Emojis

You can insert Mermaid and PlantUML diagrams by using a language-specific identifier immediately following the triple backtick (```) notation that initiates the code block:
* ```mermaid
* ```plantuml

### API specifications

API specifications, or specs, can be uploaded and attached to a specific API product version within API products.
{{site.konnect_short_name}} accepts OpenAPI (Swagger) specs in YAML or JSON.

{:.info}
> **Note:** Supported version fields are `swagger: "2.0"` and those that match `openapi: x.y.z` (for example: `openapi: 3.1.0`). OpenAPI spec versions 2.0 or later are supported.

Once you've uploaded the spec, you can also preview the way the spec will render, including the methods available, endpoint descriptions, and example values. You'll also be able to filter by tag when in full-page view. 

## Publish an API to a classic Dev Portal (v2)

Using API Products, you can create and manage API products to productize your Services. Each API product consists of at least one API product version, and each API product version is connected to a Gateway Service. Creating API products is the first step in making your APIs and their documentation available to developers. API products are geo-specific and are not shared between [geographic regions](/konnect-platform/geos/).

This guide will walk you through creating an API product and productizing it by deploying it to the v2 Dev Portal.

### Prerequisites

* [A Service created](/gateway/entities/service/#set-up-a-gateway-service).
* The [API Products Publisher role](/konnect-platform/teams-and-roles/#api-products) for the API product you want to publish
* At least the [Viewer role](/konnect-platform/teams-and-roles/#dev-portal) for the v2 Dev Portal you want to publish to

### Create an API product 
{% navtabs "create api product" %}
{% navtab "Konnect UI" %}

You can set up an API product and API product version by clicking [**API Products**](https://cloud.konghq.com/api-products) from the {{site.konnect_short_name}} side navigation bar.

1. Select **API Product** from the API products dashboard to add a new API product.

1. Create a new name for your API product, and enter an optional **Description** and any **labels** that you want to associate with the product, then click **Create**. 

You will be greeted by the dashboard for the API product that you just created. You can use this dashboard to manage an API product. 
{% endnavtab %}
{% navtab "API" %}

Create a new API product by issuing a `POST` request to the [`/api-products`](/api/konnect/api-products/v2/#/operations/create-api-product) endpoint. 

<!--vale off-->
{% konnect_api_request %}
url: /v2/api-products
status_code: 201
method: POST
region: us
body:
    name: API Product
{% endkonnect_api_request %}
<!--vale on-->

The response body will include an `id` field, denoting the unique identifier for your newly created API product. Save this identifier because you will need it in subsequent steps. 
{% endnavtab %}
{% endnavtabs %}

### Create an API product version
{% navtabs "api product version" %}
{% navtab "Konnect UI" %}
After creating a new API product, you can attach an API product version to it.

1. In [**API Products**](https://cloud.konghq.com/api-products), click the API product you want to create the version for and then click **Product Versions**, then click **New Version**.

1. Enter a version name. For example `v1`.
     A version name can be any string containing letters, numbers, or characters;
     for example, `1.0.0`, `v1`, or `version#1`. An API product can have multiple
     versions.
1. Click **Create** to finish creating the product version and be taken to the **Product Versions dashboard**.

After creating the new version, you will see **Link with a Gateway Service** as an option in the Product Version Dashboard. You can link a Gateway Service to your product version to enable features like App registration. 

1. Select **Link with a Gateway Service**. 

    Choose the control plane and Gateway Service to
    deploy this API product version to. This lets you deploy your Service across data plane nodes associated with the control plane.
1. Click **Save**.
{% endnavtab %}
{% navtab "API" %}

To create a new API product version, execute a `POST` request to the  [`/product-versions/`](/api/konnect/api-products/v2/#/operations/create-api-product-version) endpoint:
<!--vale off-->
{% konnect_api_request %}
url: /v2/api-products/$API_PRODUCT_ID/product-versions
status_code: 201
method: POST
region: us
body:
    name: v1
{% endkonnect_api_request %}
<!--vale on-->

After creating the new version, you can link a Gateway Service to your product version to enable features like application registration by issuing a `POST` request to the [`/product-versions/`](/api/konnect/api-products/v2/#/operations/create-api-product-version) endpoint. 

<!--vale off-->
{% konnect_api_request %}
url: /v2/api-products/$API_PRODUCT_ID/product-versions
status_code: 201
method: POST
region: us
body:
    name: v1
    gateway_service:
        control_plane_id: $CONTROL_PLANE_ID
        id: $SERVICE_ID
{% endkonnect_api_request %}
<!--vale on-->

{% endnavtab %}
{% endnavtabs %}
### Publish an API product

{% navtabs "publish api product" %}
{% navtab "Konnect UI" %}

1. In [**API Products**](https://cloud.konghq.com/api-products), select the API product that you created in the previous step.
1. Click **Add** on the API Product Overview page and select **Publish to Dev Portals**. You will see a modal prompting you to select which Dev Portals you want to publish your API product to. 
1. Click **Publish** for the Dev Portals you want to publish it to. Then, click **Finish**. 
1. In [**API Products**](https://cloud.konghq.com/api-products), select the API product you added to the Dev Portal. 
1. Click **Product Versions** in the sidebar.
1. Click the product version you created previously and click the **Dev Portals** tab. Click **Publish to Dev Portals** and select the Dev Portals you want to add the product version to.
1. Optional: If you want to require authentication on your API product version, enable **Require Authentication** and select which authentication strategy applications registering to your API should use. 

The API product and product versions you published should now be displayed in the Dev Portals you selected.
{% endnavtab %}
{% navtab "API" %}

Before you publish the API product version, you must first assign the API product to any v2 Dev Portals by issuing a `PATCH` request to the [`/api-products/{id}`](/api/konnect/api-products/v2/#/operations/update-api-product) endpoint:

<!--vale off-->
{% konnect_api_request %}
url: /v2/api-products/$API_PRODUCT_ID
status_code: 201
method: PATCH
region: us
body:
    portal_ids: 
    - $V2_DEV_PORTAL_ID
{% endkonnect_api_request %}
<!--vale on-->

You can publish an API product version by issuing a `POST` request to the [`/api-product-versions/`](/api/konnect/portal-management/v2/#/operations/create-portal-product-version) endpoint. 

<!--vale off-->
{% konnect_api_request %}
url: /v2/portals/$V2_DEV_PORTAL_ID/product-versions
status_code: 201
method: POST
region: us
body:
    product_version_id: $API_PRODUCT_VERSION_ID
    auth_strategy_ids: $AUTH_STRATEGY_ID
    application_registration_enabled: true
    auto_approve_registration: false
    publish_status: published
    deprecated: false
{% endkonnect_api_request %}
<!--vale on-->

{:.info}
> If you need to find your auth strategy ID, you can send a GET request to the [`/application-auth-strategies` endpoint](/api/konnect/application-auth-strategies/v2/#/operations/list-app-auth-strategies).
{% endnavtab %}
{% endnavtabs %}
