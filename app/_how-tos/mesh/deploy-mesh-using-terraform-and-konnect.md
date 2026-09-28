---
title: Deploy {{site.mesh_product_name}} using Terraform and {{site.konnect_short_name}}
content_type: how_to
permalink: "/mesh/deploy-mesh-using-terraform-and-konnect/"
breadcrumbs:
- "/mesh/"
- "/mesh/konnect/"
description: Create a Mesh 3 global control plane with Terraform, then connect a Kubernetes
  zone with Helm and verify identity-based traffic permissions.
products:
- mesh
works_on:
- konnect
tools:
- terraform
tags:
- terraform
- automation
- kubernetes
- zones
tldr:
  q: How do I start a Mesh 3 deployment with Terraform and Konnect?
  a: Use the konnect-beta provider with version = "v3" to create the global control
    plane. Provision zone credentials with the API, install the zone with Helm, and
    configure the demo mesh with kongctl.
related_resources:
- text: Installation options
  url: "/mesh/konnect/"
- text: Terraform control plane resource
  url: https://registry.terraform.io/providers/kong/konnect-beta/0.22.0/docs/resources/mesh_control_plane
min_version:
  mesh: '3.0'
---

This guide uses Terraform to create a **new Mesh 3 global control plane** in Konnect. It then
uses the Konnect API for zone credentials, Helm to install a Kubernetes zone, and `kongctl`
to configure and test a secured mesh. Terraform owns only the global control plane in this
example; the remaining resources have explicit setup and cleanup steps.

Unlike the 2.x example, it does not configure `Mesh.mtls`, an allow-all `from` policy, or shared
zone ingress and egress. Workload security uses `MeshIdentity` and identity-based permissions.

## Prerequisites

- Terraform and `kong/konnect-beta` 0.22.0, whose control plane resource supports `version`.
- A Konnect organization with Mesh 3 enabled, permission to create control planes and system
  accounts, and a personal access token in `KONNECT_TOKEN`.
- A Kubernetes cluster, Helm, `kubectl`, `curl`, `jq`, and a kongctl build with Mesh 3 support.
- Outbound network access from the zone to its regional Konnect KDS endpoint on port 443.

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

{% include md/mesh/how-tos/provision-konnect.md %}

{% include md/mesh/how-tos/deploy-konnect-zone.md platform="kubernetes" %}

{% include md/mesh/how-tos/konnect-kubernetes-secure-test.md %}

## Clean up

Remove the test workloads and the zone installed by Helm before destroying its global control plane:

```sh
kubectl delete namespace kong-mesh-demo
helm uninstall kong-mesh --namespace kong-mesh-system
cd "$MESH_TERRAFORM_DIR"
terraform plan -destroy
terraform destroy
```

Destroying the global control plane also removes its mesh configuration, including resources
created with `kongctl`. Revoke the zone token and delete its system account through Konnect.
Delete the `cp-token` Secret and `kong-mesh-system` namespace only if they were created solely
for this test. Remove local credential files after reviewing their contents and ownership.
