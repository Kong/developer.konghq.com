---
title: Deploy {{site.mesh_product_name}} using Terraform and {{site.konnect_short_name}}
content_type: how_to
permalink: "/mesh/deploy-mesh-using-terraform-and-konnect/"
breadcrumbs:
- "/mesh/"
- "/mesh/konnect/"
description: Create a {{site.mesh_product_name}} 3.x global control plane with Terraform, then connect a Kubernetes
  zone with Helm and verify identity-based traffic permissions.
products:
- mesh
works_on:
- konnect
tools:
- terraform
- kongctl
tags:
- terraform
- automation
- kubernetes
- zones
tldr:
  q: How do I start a {{site.mesh_product_name}} 3.x deployment with Terraform and {{site.konnect_short_name}}?
  a: Use the konnect-beta provider with version = "v3" to create the global control
    plane. Provision zone credentials with the API, install the zone with Helm, create
    the demo mesh with kongctl, and apply its traffic permission to the zone with kubectl.
prereqs:
  inline:
    - title: Terraform
      content: |
        Terraform and `kong/konnect-beta` 0.22.0, whose control plane resource supports `version`.
    - title: kubectl and Helm
      content: |
        A Kubernetes cluster and Helm.
related_resources:
- text: Installation options
  url: "/mesh/konnect/"
- text: Terraform control plane resource
  url: https://registry.terraform.io/providers/kong/konnect-beta/0.22.0/docs/resources/mesh_control_plane
cleanup:
  inline:
    - title: Remove the zone and destroy the control plane
      content: |
        Delete the zone traffic permission:

        ```sh
        kubectl delete meshtrafficpermission client-to-server --namespace kong-mesh-system
        ```

        Delete the test namespace:

        ```sh
        kubectl delete namespace kong-mesh-demo
        ```

        Uninstall the zone release:

        ```sh
        helm uninstall kong-mesh --namespace kong-mesh-system
        ```

        Delete the zone namespace and the `cp-token` Secret in it:

        ```sh
        kubectl delete namespace kong-mesh-system
        ```

        Change to the Terraform working directory:

        ```sh
        cd "$MESH_TERRAFORM_DIR"
        ```

        Review the destroy plan:

        ```sh
        terraform plan -destroy
        ```

        Destroy the global control plane. This also removes its mesh configuration:

        ```sh
        terraform destroy
        ```

        Delete the `mesh-zone-1` system account:

        ```sh
        curl --fail-with-body -sS -X DELETE \
          "https://global.api.konghq.com/v3/system-accounts/$ACCOUNT_ID" \
          -H "Authorization: Bearer $KONNECT_TOKEN"
        ```
min_version:
  mesh: '3.0'
---

This guide uses Terraform to create a {{site.mesh_product_name}} 3.x global control plane in {{site.konnect_short_name}}, then connects a Kubernetes zone and verifies identity-based traffic permissions.

## Create the global control plane

Create a working directory and change to it:

```sh
export MESH_TERRAFORM_DIR=$(mktemp -d)
cd "$MESH_TERRAFORM_DIR"
```

Set the region and pass your {{site.konnect_short_name}} credentials to Terraform:

```sh
export KONNECT_REGION='us'
export TF_VAR_konnect_token="$KONNECT_TOKEN"
export TF_VAR_region="$KONNECT_REGION"
```

Save the following as `main.tf`:

```hcl
terraform {
  required_providers {
    konnect-beta = {
      source  = "kong/konnect-beta"
      version = "0.22.0"
    }
  }
}

variable "konnect_token" {
  type      = string
  sensitive = true
}

variable "region" {
  type = string
}

provider "konnect-beta" {
  personal_access_token = var.konnect_token
  server_url            = "https://${var.region}.api.konghq.com"
}

resource "konnect_mesh_control_plane" "demo" {
  provider    = konnect-beta
  name        = "example-cp"
  description = "Mesh 3 installation example"
  version     = "v3"
}

output "control_plane_id" {
  value = konnect_mesh_control_plane.demo.id
}
```

The [provider's control plane resource](https://registry.terraform.io/providers/kong/konnect-beta/0.22.0/docs/resources/mesh_control_plane)
defaults to `v2`, so set `version = "v3"` explicitly.

Initialize the working directory:

```sh
terraform init
```

Review the plan:

```sh
terraform plan
```

Apply the plan:

```sh
terraform apply
```

Export the control plane ID from the Terraform output:

```sh
export CONTROL_PLANE_ID=$(terraform output -raw control_plane_id)
```

Protect Terraform state and don't commit credentials. Keep this directory for later cleanup.

## Give the zone credentials to connect

{% include md/mesh/v3/how-tos/give-zone-credentials.md %}

## Deploy the zone control plane

{% include md/mesh/v3/how-tos/deploy-zone-control-plane.md platform="kubernetes" %}

## Verify the zone connection

{% include md/mesh/v3/how-tos/verify-zone-connection.md %}

## Create a mesh and secure the test traffic

{% include md/mesh/v3/how-tos/create-mesh-and-permission.md %}

## Deploy the test applications

{% include md/mesh/v3/how-tos/deploy-test-applications.md %}

## Validate

{% include md/mesh/v3/how-tos/verify-allowed-and-denied-request.md %}
