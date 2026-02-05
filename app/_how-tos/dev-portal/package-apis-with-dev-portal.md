---
title: "Package APIs with Dev Portal"
permalink: /how-to/package-apis-with-dev-portal/
description: "Learn how to compose existing APIs in Dev Portal into API packages."
content_type: how_to
related_resources:
  - text: About Dev Portal
    url: /dev-portal/
  - text: API packaging reference
    url: /catalog/api-packaging/
automated_tests: false
products:
    - dev-portal
    - gateway
    - catalog
min_version:
  gateway: '3.13'
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
        1. Create an API and attach an OpenAPI spec.
        1. Apply the Access Control Enforcement (ACE) plugin globally on the control plane you want to link.
        1. Link a control plane to the API to allow developer consumption. 
        1. Create an API package by adding operations and package rate limits.
        1. Publish the API package to Dev Portal. 
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
        To complete this guide, you'll need an API in Catalog:
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

           To learn more about entities, you can read our [entities documentation](/gateway/entities/).
    - title: API specification
      content: |
        To complete this guide, you'll need an API specification that matches the Route you created. {{site.konnect_catalog}} uses the spec to add operations to your API package.

        ```sh
        cat > example-api-spec.yaml << 'EOF'
        openapi: 3.0.0
        info:
          title: Example API
          description: Example API service for testing and documentation
          version: 1.0.0

        servers:
          - url: http://httpbin.konghq.com
            description: Backend service (HTTP only, port 80)

        paths:
          /anything:
            get:
              summary: Get anything
              description: Echo back GET request details
              operationId: getAnything
              tags:
                - Echo
              responses:
                '200':
                  description: Successful response
                  content:
                    application/json:
                      schema:
                        $ref: '#/components/schemas/EchoResponse'
                '426':
                  description: Upgrade Required (HTTPS redirect)
                  
            post:
              summary: Post anything
              description: Echo back POST request details
              operationId: postAnything
              tags:
                - Echo
              requestBody:
                content:
                  application/json:
                    schema:
                      type: object
                      additionalProperties: true
              responses:
                '200':
                  description: Successful response
                  content:
                    application/json:
                      schema:
                        $ref: '#/components/schemas/EchoResponse'
                '426':
                  description: Upgrade Required (HTTPS redirect)
                        
            put:
              summary: Put anything
              description: Echo back PUT request details
              operationId: putAnything
              tags:
                - Echo
              requestBody:
                content:
                  application/json:
                    schema:
                      type: object
                      additionalProperties: true
              responses:
                '200':
                  description: Successful response
                  content:
                    application/json:
                      schema:
                        $ref: '#/components/schemas/EchoResponse'
                '426':
                  description: Upgrade Required (HTTPS redirect)
                        
            patch:
              summary: Patch anything
              description: Echo back PATCH request details
              operationId: patchAnything
              tags:
                - Echo
              requestBody:
                content:
                  application/json:
                    schema:
                      type: object
                      additionalProperties: true
              responses:
                '200':
                  description: Successful response
                  content:
                    application/json:
                      schema:
                        $ref: '#/components/schemas/EchoResponse'
                '426':
                  description: Upgrade Required (HTTPS redirect)
                        
            delete:
              summary: Delete anything
              description: Echo back DELETE request details
              operationId: deleteAnything
              tags:
                - Echo
              responses:
                '200':
                  description: Successful response
                  content:
                    application/json:
                      schema:
                        $ref: '#/components/schemas/EchoResponse'
                '426':
                  description: Upgrade Required (HTTPS redirect)

        components:
          schemas:
            EchoResponse:
              type: object
              properties:
                args:
                  type: object
                  description: Query parameters
                data:
                  type: string
                  description: Request body data
                files:
                  type: object
                  description: Uploaded files
                form:
                  type: object
                  description: Form data
                headers:
                  type: object
                  description: Request headers
                json:
                  type: object
                  description: JSON request body
                method:
                  type: string
                  description: HTTP method used
                origin:
                  type: string
                  description: Origin IP address
                url:
                  type: string
                  description: Request URL

        x-kong-service:
          name: example-service
          host: httpbin.konghq.com
          port: 80
          protocol: http
          path: /anything
          retries: 5
          connect_timeout: 60000
          write_timeout: 60000
          read_timeout: 60000

        x-kong-route:
          name: example-route
          protocols: [http, https]
          methods: [GET, POST, PUT, PATCH, DELETE]
          paths: [/anything]
          strip_path: true
          preserve_host: false
          https_redirect_status_code: 426
        EOF
        ```
      icon_url: /assets/icons/dev-portal.svg


cleanup:
  inline:
    - title: Clean up {{site.konnect_short_name}} environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg
---

You can compose [API packages](/catalog/api-packaging/) from existing APIs in Dev Portal. API packages allow you to:
* Create distinct APIs for specific use cases or partners based on existing API operations.
* Link to multiple Gateway Services and/or Routes for developer self-service and application registration.
* Apply rate limiting policies to an API Package, or per operation.
* Manage role-based access control for specific developers and teams.

## Associate a control plane

To allow developers to consume your API, you must first link an API Gateway and control plane to your API.

Operations from your API's OpenAPI spec should overlap with Routes to ensure requests will be routed to the correct Service. Gateway routing configuration isn't directly modified by adding operations.
1. In the {{site.konnect_short_name}} sidebar, click [**Catalog**](https://cloud.konghq.com/apis/).
1. Click **MyAPI**.
1. Click the **Gateway** tab.
1. Click **Link gateway**.
1. From the **Control plane** dropdown menu, select "quickstart".
1. Select **Link to a control plane**.
1. In the Add the Access Control and Enforcement plugin settings, click **Add plugin**.
1. Click **Link gateway**.
1. Click the **API Specification** tab.
1. Click **Upload Spec**.
1. Click **Select file**.
1. Select `example-api-spec.yaml`.
1. Click **Save**.

## Assign operations to API packages

Now, you can create an API package by picking operations from your API. Operations are automatically mapped to Routes using your API's OpenAPI spec. The Gateway configuration isn't directly modified – any unmatched operations will be highlighted to indicate that a user needs Gateway Manager permissions to perform an action.

1. In the {{site.konnect_short_name}} sidebar, click **Catalog**.
1. Click the **API packages** tab.
1. Click **Create API package**.
1. In the **API package name** field, enter `Company package`.
1. Enable the Package rate limit.
1. For the rate limit, enter `5` and select "Minute".
1. In the API operations settings, click **Add operations from APIs**.
1. In the Add API operations pane, click **MyAPI**
1. For GET `/anything`, click **Add**.
1. For PUT `/anything`, click **Add**.
1. For POST `/anything`, click **Add**.
1. Exit the Add API operations pane.
1. Click **Create API package**. 
1. Click the **Specifications** tab.
1. Click **Generate spec from operations**.
1. Click **Save**.

## Publish API packages to Dev Portal
Now you can make the API packages available to developers by publishing them to a Dev Portal.
1. In the {{site.konnect_short_name}} sidebar, click **Catalog**.
1. Click the **API packages** tab.
1. Click **Company package**.
1. Click **Publish API**.
1. From the **Portal** dropdown menu, select your Dev Portal.
1. From the **Authentication strategy** dropdown menu, select "Disabled".
1. Click **Public**.
1. Click **Publish API**. 

Your API package will now be published to your Dev Portal. Published API packages appear the same as published APIs in the Dev Portal, and both allow developers to register applications with them.

## Validate

Now that you've published your API package, you can verify that it was successfully published by navigating to your Dev Portal's URL. You can find your Dev Portal's URL by navigating to the [Dev Portal overview](https://cloud.konghq.com/portals/) in the {{site.konnect_short_name}} UI.