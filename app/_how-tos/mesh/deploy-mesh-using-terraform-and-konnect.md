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
    plane. Provision zone credentials with the API, install the zone with Helm, and
    configure the demo mesh with kongctl.
prereqs:
  inline:
    - title: Terraform
      content: |
        Terraform and `kong/konnect-beta` 0.22.0, whose control plane resource supports `version`.
    - title: kubectl and Helm
      content: |
        A Kubernetes cluster and Helm.
    - title: Network access
      content: |
        Confirm your zone's network allows outbound access on port 443 to its regional {{site.konnect_short_name}} KDS endpoint, `$KONNECT_REGION.mesh.sync.konghq.com`.
related_resources:
- text: Installation options
  url: "/mesh/konnect/"
- text: Terraform control plane resource
  url: https://registry.terraform.io/providers/kong/konnect-beta/0.22.0/docs/resources/mesh_control_plane
cleanup:
  inline:
    - title: Remove the zone and destroy the control plane
      content: |
        Remove the test workloads and the zone installed by Helm before destroying its global control plane:

        ```sh
        kubectl delete namespace kong-mesh-demo
        helm uninstall kong-mesh --namespace kong-mesh-system
        cd "$MESH_TERRAFORM_DIR"
        terraform plan -destroy
        terraform destroy
        ```

        Destroying the global control plane also removes its mesh configuration, including resources
        created with `kongctl`. Revoke the zone token and delete its system account through {{site.konnect_short_name}}.
        Delete the `cp-token` Secret and `kong-mesh-system` namespace only if they were created solely
        for this test. Remove local credential files after reviewing their contents and ownership.
min_version:
  mesh: '3.0'
---

This guide uses Terraform to create a **new {{site.mesh_product_name}} 3.x global control plane** in {{site.konnect_short_name}}. It then
uses the {{site.konnect_short_name}} API for zone credentials, Helm to install a Kubernetes zone, and `kongctl`
to configure and test a secured mesh. Terraform owns only the global control plane in this
example; the remaining resources have explicit setup and cleanup steps.

Unlike the 2.x example, it does not configure `Mesh.mtls`, an allow-all `from` policy, or shared
zone ingress and egress. Workload security uses `MeshIdentity` and identity-based permissions.

## Create the global control plane

Create a dedicated working directory:

```sh
export MESH_TERRAFORM_DIR=$(mktemp -d)
cd "$MESH_TERRAFORM_DIR"
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
defaults to `v2`. Keep `version = "v3"` explicit. This setting is not a substitute for the
migration procedure when managing an existing control plane.

Review the plan, then apply it:

```sh
terraform init
terraform plan
terraform apply
export CONTROL_PLANE_ID=$(terraform output -raw control_plane_id)
```

Protect Terraform state and do not commit credentials. Keep this directory for later cleanup.

## Give the zone credentials to connect

{% include md/mesh/how-tos/give-zone-credentials.md %}

## Check the global control plane version

{% include md/mesh/how-tos/check-control-plane-version.md %}

## Deploy the zone control plane

{% include md/mesh/how-tos/deploy-zone-control-plane.md platform="kubernetes" %}

## Verify the zone connection

{% include md/mesh/how-tos/verify-zone-connection.md %}

## Create a mesh and secure the test traffic

{% include md/mesh/how-tos/create-mesh-and-permission.md %}

## Deploy the test applications

{% include md/mesh/how-tos/deploy-test-applications.md %}

## Verify an allowed and a denied call

{% include md/mesh/how-tos/verify-allowed-and-denied-request.md %}
