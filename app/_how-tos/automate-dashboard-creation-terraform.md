---
title: Automate dashboard creation with Terraform
description: Learn how to create a custom dashboard in {{site.konnect_short_name}} Analytics with Terraform
content_type: how_to
automated_tests: false
products:
    - konnect-platform
    - advanced-analytics
works_on:
    - konnect
tools:
    - konnect-api
    - terraform
tags:
    - custom-dashboards


tldr:
  q: How do I automate dashboard creation using Terraform?
  a: |
    Create the following resources using Terraform:

    * `konnect_api`
    * `konnect_api_document`
    * `konnect_api_version`
    * `konnect_api_implementation`
    * `konnect_api_publication`


prereqs:
  skip_product: true
  inline:
    - title: Terraform
      include_content: prereqs/terraform
      icon_url: /assets/icons/terraform.svg
    - title: "{{site.konnect_product_name}}"
      include_content: prereqs/products/konnect-terraform
      icon_url: /assets/icons/gateway.svg
related_resources:
  - text: Custom Dashboards
    url: /advanced-analytics/custom-dashboards/
---


## Create an API

In this tutorial, you'll automate your API catalog by creating an API along with a document and spec, associating it with a Gateway Service, and finally publishing it to a Dev Portal. 

First, create an API:

```hcl
echo '
resource "konnect_api" "my_api" {
  provider = konnect-beta
  description = "...my_description..."
  labels = {
    key = "value"
  }
  name         = "MyAPI"
}
' >> main.tf
```

## Create and associate an API spec and version

[Create and associate a spec and version](https://github.com/Kong/terraform-provider-konnect-beta/blob/main/examples/resources/konnect_api_version/resource.tf) with your API:

```hcl
echo '
resource "konnect_api_version" "my_api_spec" {
  provider = konnect-beta
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

An [API document](/dev-portal/apis/#documentation) is Markdown documentation for your API that displays in the Dev Portal. You can link multiple API Documents to each other with a [parent document and child documents](https://github.com/Kong/terraform-provider-konnect-beta/blob/main/examples/resources/konnect_api_document/resource.tf).

Create and associate an API document:

```hcl
echo '
resource "konnect_api_document" "my_apidocument" {
  provider = konnect-beta
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
  provider = konnect-beta
  api_id = konnect_api.my_api.id
  service = {
    control_plane_id = konnect_gateway_control_plane.my_cp.id
    id               = konnect_gateway_service.httpbin.id
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
  provider = konnect-beta
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