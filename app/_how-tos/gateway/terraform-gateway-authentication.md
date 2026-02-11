---
title: Configure Basic Auth using {{ site.base_gateway }} and Terraform
description: Create a Control Plane, Service, Route, Consumer and Basic Auth plugin using Terraform
content_type: how_to
permalink: /terraform/how-to/gateway-authentication/
breadcrumbs:
  - /terraform/

tools:
  - terraform

works_on:
  - konnect

products:
  - gateway

entities:
  - service
  - route
  - consumer

plugins:
  - basic-auth

tldr:
  q: How to I secure a Service using {{ site.base_gateway }} and Terraform?
  a: |
    Create the following resources using Terraform:

    * konnect_gateway_control_plane
    * konnect_gateway_service
    * konnect_gateway_route
    * konnect_gateway_plugin_basic_auth
    * konnect_gateway_consumer

prereqs:
  skip_product: true
  inline:
    - title: Terraform
      include_content: prereqs/terraform
      icon_url: /assets/icons/terraform.svg
---

## Configure the provider

Create an `auth.tf` file that configures the `kong/konnect` Terraform provider. Change `server_url` if you are using a region other than `us`:

```hcl
echo '
terraform {
  required_providers {
    konnect = {
      source  = "kong/konnect"
    }
  }
}

provider "konnect" {
  server_url            = "https://us.api.konghq.com"
}
' > auth.tf
```

Next, initialize your project and download the provider:

```bash
terraform init
```

The provider automatically uses the `KONNECT_TOKEN` environment variable if it is available. If you would like to use a custom authentication token, set the `personal_access_token` field alongside `server_url` in the `provider` block.

## Create a Control Plane

Before configuring a Service and a Route, you need to create a Control Plane. If you have an existing Control Plane that you'd like to reuse, you can use the [`konnect_gateway_control_plane_list`](https://github.com/Kong/terraform-provider-konnect/blob/main/examples/data/gateway_control_plane_list.tf) data source.

```hcl
echo '
resource "konnect_gateway_control_plane" "my_cp" {
  name         = "Terraform Control Plane"
  description  = "Configured using the demo at developer.konghq.com"
  cluster_type = "CLUSTER_TYPE_CONTROL_PLANE"
}
' > main.tf
```

## Configure a service and a route

After creating a Control Plane, you can configure a Service and a Route.

Our example service uses `httpbin.org` as the upstream, and matches the `/anything` path which echos the response back to the client. 

```hcl
echo '
resource "konnect_gateway_service" "httpbin" {
  name             = "HTTPBin"
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

## Add the basic-auth plugin

The Service and Route are now configured, but they're publicly accessible. Add a `basic-auth` plugin to the `httpbin` Service to require authentication for all routes:

```hcl
echo '
# Secure the service with a basic-auth plugin
resource "konnect_gateway_plugin_basic_auth" "basic_auth" {
  enabled          = true
  control_plane_id = konnect_gateway_control_plane.my_cp.id
  service = {
    id = konnect_gateway_service.httpbin.id
  }
  config = {
    hide_credentials = false
  }
}
' >> main.tf
```

## Create a Consumer and Credential

Now that the Service is secured, create a Consumer and Basic Auth credential that can be used to call the API:

```hcl
echo '
resource "konnect_gateway_consumer" "alice" {
  username         = "alice"
  custom_id        = "alice"
  control_plane_id = konnect_gateway_control_plane.my_cp.id
}

resource "konnect_gateway_basic_auth" "my_basicauth" {
  username = "alice-test"
  password = "demo"

  consumer_id      = konnect_gateway_consumer.alice.id
  control_plane_id = konnect_gateway_control_plane.my_cp.id
}
' >> main.tf
```

## Create the resources

Create all of the defined resources using Terraform:

```bash
terraform apply -auto-approve
```

You will see six resources created:

```text
Apply complete! Resources: 6 added, 0 changed, 0 destroyed.
```
{:.no-copy-code}

## Validate your configuration

Fetch the Control Plane and Plugin IDs from the Terraform state:

```bash
CONTROL_PLANE_ID=$(terraform show -json | jq -r '.values.root_module.resources[] | select(.address == "konnect_gateway_control_plane.my_cp") | .values.id')
PLUGIN_ID=$(terraform show -json | jq -r '.values.root_module.resources[] | select(.address == "konnect_gateway_plugin_basic_auth.basic_auth") | .values.id')
```

Call the Konnect API and ensure that the resources exist:

<!--vale off-->
{% konnect_api_request %}
url: /v2/control-planes/$CONTROL_PLANE_ID/core-entities/plugins/$PLUGIN_ID
status_code: 200
method: GET
{% endkonnect_api_request %}
<!--vale on-->
