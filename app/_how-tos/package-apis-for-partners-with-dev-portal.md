---
title: "Package APIs for partners with Dev Portal"
description: "Learn how to package existing APIs in Dev Portal into API packages for partners."
content_type: how_to
related_resources:
  - text: About Dev Portal
    url: /dev-portal/
  - text: Dev Portal API packaging reference
    url: /dev-portal/api-catalog-and-packaging/
automated_tests: false
products:
    - konnect
    - dev-portal

works_on:
    - konnect
tools:
    - deck
tags:
    - api-catalog
    - api-composition

tldr:
    q: How do I create API packages from existing Dev Portal APIs?
    a: |
        Packaging APIs involves the following steps:
        1. Create an API and attach an OpenAPI spec. Operations from your API's OpenAPI spec should overlap with Routes to ensure requests will be routed to the correct Service. Gateway routing configuration isn't directly modified by adding operations.
        1. Link a control plane to allow developer consumption. 
        1. Apply the Access Control Enforcement (ACE) plugin globally.
        1. Create an API package by adding operations and package rate limits. Operations are automatically mapped to Routes using your API's OpenAPI spec or you can create them manually. The Gateway configuration isn't directly modified– any unmatched operations will be highlighted to indicate that a user Gateway Manager permissions needs to perform an action.
prereqs:
  show_works_on: false
  inline:
    - title: "{{site.konnect_product_name}}"
      include_content: prereqs/products/konnect-account-only
      icon_url: /assets/icons/gateway.svg
    - title: "{{site.konnect_short_name}} roles"
      content: |
        To recover create API packages, you need the following [roles](/konnect-platform/teams-and-roles/):
        * Editor role for APIs
        * Publisher role for the API and API package
        * API Creator
      icon_url: /assets/icons/gateway.svg
    - title: Dev Portal
      include_content: prereqs/dev-portal-create-ui
      icon_url: /assets/icons/dev-portal.svg
    - title: Dev Portal APIs
      content: |
        To complete this guide, you'll need an API in Dev Portal. 
        1. In the {{site.konnect_short_name}} sidebar, click **Catalog**.
        1. Click [**New API**](https://cloud.konghq.com/apis/create).
        1. In the **API name** field, enter `MyAPI`.
        1. Click **Create**.
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
---

You can compose API packages from existing APIs in Dev Portal. API packages allow you to:
* Create distinct APIs for specific use cases or partners based on existing API operations.
* Link to multiple Gateway Services and/or Routes for developer self-service and application registration.
* Apply rate limiting policies to an API Package, or per operation.
* Manage role-based access control to specific developers and teams.

### Associate a control plane

To allow developers to consume your API, you must first link an API Gateway and control plane to your API.

1. In {{site.konnect_short_name}}, click **Catalog**.
1. Click **MyAPI**.
1. Click the **Gateway** tab.
1. Click **Link gateway**.
1. From the **Control plane** dropdown menu, select "quickstart".
1. Select **Link to a control plane**.
1. In the Add the Access Control and Enforcement plugin settings, click **Add plugin**.
1. Click **Link gateway**.

### Assign operations to API packages

1. In {{site.konnect_short_name}}, click **Catalog**.
1. Click the **API packages** tab.
1. Click **Create API package**.
1. In the **API package name** field, enter `Partner package`.
1. Enable the Package rate limit and configure your rate limit.
1. Click **Add operations from APIs** in the API operations settings.
1. In the Add API operations pane, click your API and click **Add** next to the operations you want to package.
1. Click **Create API package**. 

### Publish packages to Dev Portal

1. In {{site.konnect_short_name}}, navigate to **Dev Portal** > **APIs** in the sidebar.
1. Click the **API packages** tab.
1. Click your API package.
1. Click **Publish API**.
1. Select your Dev Portal from the **Portal** dropdown menu.
1. Select an auth strategy from the **Authentication strategy** dropdown menu.
1. Click **Publish API**. 

Your API package will now be published to your Dev Portal. Published API packages appear the same as published APIs in the Dev Portal, and both allow developers to register applications with them.