---
title: Automate your API catalog with Terraform
permalink: /how-to/automate-api-catalog-with-terraform/
description: Learn how to automate your Dev Portal API catalog with Terraform.
content_type: how_to
tags:
    - api-catalog
tools:
  - terraform
works_on:
  - konnect

products:
    - gateway    
    - dev-portal
    - catalog

entities: []

tldr:
  q: How do I automate my API catalog in Catalog and Dev Portal using Terraform?
  a: |
    Create the following resources using Terraform:

    * `konnect_api`
    * `konnect_api_document`
    * `konnect_api_version`
    * `konnect_api_implementation`
    * `konnect_api_publication`

related_resources:
    - text: "{{site.konnect_short_name}} Terraform provider repository"
      url: https://github.com/Kong/terraform-provider-konnect
    - text: Catalog APIs reference
      url: /catalog/apis/
    - text: Self-service developer and application registration
      url: /dev-portal/application-registration/
    - text: Application authentication strategies
      url: /dev-portal/auth-strategies/ 
    - text: Package APIs with Dev Portal
      url: /how-to/package-apis-with-dev-portal/
prereqs:
  skip_product: true
  inline:
    - title: Terraform
      include_content: prereqs/terraform
      icon_url: /assets/icons/terraform.svg
    - title: "{{site.konnect_product_name}}"
      include_content: prereqs/products/konnect-terraform
      icon_url: /assets/icons/gateway.svg
    - title: "{{site.konnect_product_name}} roles"
      include_content: prereqs/dev-portal-automate-api-catalog-roles
      icon_url: /assets/icons/gateway.svg
    - title: Required entities
      content: |
        For this tutorial, you’ll need {{site.base_gateway}} entities, like Gateway Services and Routes, pre-configured. These entities are essential for {{site.base_gateway}} to function but installing them isn’t the focus of this guide.

        1. Before configuring a Service and a Route, you need to create a Control Plane. If you have an existing Control Plane that you'd like to reuse, you can use the [`konnect_gateway_control_plane_list`](https://github.com/Kong/terraform-provider-konnect/blob/main/examples/data/gateway_control_plane.tf) data source.
           ```hcl
           echo '
           resource "konnect_gateway_control_plane" "my_cp" {
             name         = "Terraform Control Plane"
             description  = "Configured using the demo at developer.konghq.com"
             cluster_type = "CLUSTER_TYPE_CONTROL_PLANE"
           }
           ' > main.tf
           ```
        
        1. Our example Service uses `httpbin.org` as the upstream, and matches the `/anything` path which echos the response back to the client. 
           ```hcl
           echo '
           resource "konnect_gateway_service" "httpbin" {
             name             = "example-service"
             protocol         = "https"
             host             = "httpbin.org"
             port             = 443
             path             = "/"
             control_plane_id = konnect_gateway_control_plane.my_cp.id
           }

           resource "konnect_gateway_route" "hello" {
             methods = ["GET"]
             name    = "Anything"
             paths   = ["/anything"]

             strip_path = false

             control_plane_id = konnect_gateway_control_plane.my_cp.id
             service = {
               id = konnect_gateway_service.httpbin.id
           }
           }
           ' >> main.tf
           ```
      icon_url: /assets/icons/widgets.svg
    - title: Dev Portal
      include_content: prereqs/api-catalog-terraform
      icon_url: /assets/icons/dev-portal.svg
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

automated_tests: false
---

## Create an API

In this tutorial, you'll automate your API catalog by creating an API in [Catalog](/service-catalog/) along with a document and spec, associating it with a Gateway Service, and finally publishing it to a [Dev Portal](/dev-portal/). 

First, create an API:

```hcl
echo '
resource "konnect_api" "my_api" {
  description = "...my_description..."
  labels = {
    key = "value"
  }
  name         = "MyAPI"
}
' >> main.tf
```

## Create and associate an API spec and version

[Create and associate a spec and version](https://github.com/Kong/terraform-provider-konnect/blob/main/examples/resources/konnect_api_version.tf) with your API:

```hcl
echo '
resource "konnect_api_version" "my_api_spec" {
  api_id = konnect_api.my_api.id
  spec = {
    content = <<JSON
      {
        "openapi": "3.0.3",
        "info": {
          "title": "Example API",
          "version": "1.0.0"
        },
        "paths": {
          "/example": {
            "get": {
              "summary": "Example endpoint",
              "responses": {
                "200": {
                  "description": "Successful response"
                }
              }
            }
          }
        }
      }
      JSON
  }
  version = "1.0.0"
}
' >> main.tf
```

{:.warning}
> We recommend that APIs have API documents or specs, and APIs can have both. If neither are specified, {{site.konnect_short_name}} can't render documentation.

## Create and associate an API document 

An [API document](/catalog/apis/#documentation) is Markdown documentation for your API that displays in the Dev Portal. You can link multiple API Documents to each other with a [parent document and child documents](https://github.com/Kong/terraform-provider-konnect/blob/main/examples/resources/konnect_api_document.tf).

Create and associate an API document:

```hcl
echo '
resource "konnect_api_document" "my_apidocument" {
  api_id  = konnect_api.my_api.id
  content = "# API Document Header"
  slug               = "api-document"
  status             = "published"
  title              = "API Document"
}
' >> main.tf
```

## Associate the API with a Gateway Service

[Gateway Services](/gateway/entities/service/) represent the upstream services in your system. By associating a Service with an API, this allows developers to generate credentials or API keys for your API. 

Associate the API with a Service:

```hcl
echo '
resource "konnect_api_implementation" "my_api_implementation" {
  api_id = konnect_api.my_api.id
  service_reference = {
    service = {
      control_plane_id = konnect_gateway_control_plane.my_cp.id
      id               = konnect_gateway_service.httpbin.id
    }
  }
  depends_on = [
    konnect_api.my_api,
    konnect_api_version.my_api_spec,
    konnect_gateway_control_plane.my_cp,
    konnect_gateway_service.httpbin
  ]
}
' >> main.tf
```

## Publish the API to Dev Portal

Now you can publish the API to a Dev Portal:

```hcl
echo '
resource "konnect_api_publication" "my_apipublication" {
  api_id = konnect_api.my_api.id
  portal_id                  = konnect_portal.my_portal.id
  visibility                 = "public"

  depends_on = [
    konnect_api_implementation.my_api_implementation,
    konnect_api_document.my_apidocument
  ]
}
' >> main.tf
```

## Create the resources

Create all of the defined resources using Terraform:

```bash
terraform apply -auto-approve
```

You will see five resources created:

```text
Apply complete! Resources: 5 added, 0 changed, 0 destroyed.
```
{:.no-copy-code}

## Validate

To validate that your API was successfully published, you must navigate to your Dev Portal URL and verify that you can see the API. 

First, fetch the Dev Portal URL from the Terraform state:

```sh
PORTAL_URL=$(terraform show -json | jq -r '
  .values.root_module.resources[]
  | select(.address == "konnect_portal.my_portal")
  | .values.default_domain')
```

This exports your Dev Portal URL as an environment variable. 

To validate that the API was created and published in your Dev Portal, navigate to your Dev Portal:

```sh
open https://$PORTAL_URL/apis
```

You should see `MyAPI` in the list of APIs. If an API is published as private, you must enable Dev Portal RBAC and [developers must sign in](/dev-portal/developer-signup/) to see APIs.
