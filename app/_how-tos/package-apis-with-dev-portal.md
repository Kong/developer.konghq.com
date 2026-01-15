---
title: "Package APIs with Dev Portal"
description: "Learn how to compose existing APIs in Dev Portal into API packages."
content_type: how_to
related_resources:
  - text: About Dev Portal
    url: /dev-portal/
  - text: Dev Portal API packaging reference
    url: /dev-portal/api-catalog-and-packaging/
automated_tests: false
products:
    - gateway
    - catalog
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
  inline:
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
        To complete this guide, you'll need an API in Catalog. 
        1. In the {{site.konnect_short_name}} sidebar, click **Catalog**.
        1. Click [**New API**](https://cloud.konghq.com/apis/create).
        1. In the **API name** field, enter `MyAPI`.
        1. Click **Create**.
      icon_url: /assets/icons/dev-portal.svg
    - title: Required entities
      content: |
        For this tutorial, you’ll need {{site.base_gateway}} entities, like Gateway Services and Routes, pre-configured. These entities are essential for {{site.base_gateway}} to function but installing them isn’t the focus of this guide.

        1. Run the following command:
           ```yaml
           echo '
           _format_version: "3.0"
           services:
             - name: example-service
               url: http://httpbin.konghq.com/anything
           routes:
             - name: example-route
               paths:
               - "/anything"
               methods:
               - GET
               - PUT
               - POST
               - PATCH
               - DELETE
               service:
                 name: example-service
           ' | deck gateway apply -
           ```

           To learn more about entities, you can read our [entities documentation](/gateway/entities).


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

## Associate a control plane

To allow developers to consume your API, you must first link an API Gateway and control plane to your API.

1. In the {{site.konnect_short_name}} sidebar, click [**Catalog**](https://cloud.konghq.com/apis/).
1. Click **MyAPI**.
1. Click the **Gateway** tab.
1. Click **Link gateway**.
1. From the **Control plane** dropdown menu, select "quickstart".
1. Select **Link to a control plane**.
1. In the Add the Access Control and Enforcement plugin settings, click **Add plugin**.
1. Click **Link gateway**.

## Assign operations to API packages

1. In the {{site.konnect_short_name}} sidebar, click **Catalog**.
1. Click the **API packages** tab.
1. Click **Create API package**.
1. In the **API package name** field, enter `Company package`.
1. Enable the Package rate limit.
1. For the rate limit, enter `5` and select "Minute".
1. In the API operations settings, click **Add operations from APIs**.
1. In the Add API operations pane, click **MyAPI**
1. For GET /anything, click **Add**.
1. For PUT /anything, click **Add**.
1. For POST /anything, click **Add**.
1. Exit the Add API operations pane.
1. Click **Create API package**. 

## Publish packages to Dev Portal

1. In the {{site.konnect_short_name}} sidebar, click **Catalog**.
1. Click the **API packages** tab.
1. Click **Company package**.
1. Click **Publish API**.
1. From the **Portal** dropdown menu, select "test".
1. From the **Authentication strategy** dropdown menu, select "Disabled".
1. Click **Public**.
1. Click **Publish API**. 

Your API package will now be published to your Dev Portal. Published API packages appear the same as published APIs in the Dev Portal, and both allow developers to register applications with them.

## Validate

Now that you've published your API package with a rate limit of 5 requests per minute, you can validate that the rate limiting is working correctly.

Run the following command to send 11 GET requests to your API. 
```bash
for _ in {1..11}; do
  curl -i -X GET http://localhost:8000/anything
  echo
done
```

**Expected results:**

* The first 5 requests should return `HTTP/1.1 200 OK`
* Requests 6-11 should return `HTTP/1.1 429 Too Many Requests` with a response body indicating the rate limit has been exceeded:
```json
  {
    "message": "API rate limit exceeded"
  }
```

The ACE plugin enforces the rate limit you configured (5 requests per minute) on the API package, protecting your backend service from excessive requests.

{:.note}
> **Note:** If you don't include the `apikey` header, the request may still succeed if the ACE plugin is configured with `config.enforce_consumer_groups: if_present`. To test unauthenticated access, try the same command without the `-H "apikey: YOUR_API_KEY"` header.