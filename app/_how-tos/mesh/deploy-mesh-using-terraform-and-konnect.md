---
title: Deploy {{site.mesh_product_name}} using Terraform and {{site.konnect_short_name}}
content_type: how_to
permalink: "/mesh/deploy-mesh-using-terraform-and-konnect/"
breadcrumbs:
- "/mesh/"
- "/mesh/konnect/"
description: Use Terraform to create a {{site.mesh_product_name}} 3.x global control plane in {{site.konnect_short_name}}, connect
  a Kubernetes zone, create a mesh, and verify identity-based traffic permissions.
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
    plane, the mesh, and its MeshIdentity. Use the konnect provider for the zone's system
    account, the helm and kubernetes providers to install the zone, and a kubernetes_manifest
    to apply the traffic permission to the zone.
prereqs:
  inline:
    - title: Terraform
      include_content: prereqs/terraform
related_resources:
- text: Installation options
  url: "/mesh/konnect/"
- text: Terraform control plane resource
  url: https://registry.terraform.io/providers/kong/konnect-beta/0.22.0/docs/resources/mesh_control_plane
- text: Architecture overview
  url: "/mesh/architecture-overview/"
cleanup:
  inline:
    - title: Delete the test applications
      content: |
        Delete the test namespace:

        ```sh
        kubectl delete namespace kong-mesh-demo
        ```
    - title: Destroy the Terraform resources
      content: |
        Review the destroy plan:

        ```sh
        terraform plan -destroy
        ```

        Destroy every resource this guide created with Terraform: the traffic permission, the zone
        control plane and its namespace, the mesh and its identity, the global control plane, and
        the zone's system account:

        ```sh
        terraform destroy
        ```

        Leave the Terraform working directory and delete it:

        ```sh
        cd "$(dirname "$MESH_TERRAFORM_DIR")"
        rm -rf "$MESH_TERRAFORM_DIR"
        ```
min_version:
  mesh: '3.0'
---

This guide uses Terraform to create a {{site.mesh_product_name}} 3.x global control plane in {{site.konnect_short_name}}, connect a Kubernetes zone to it, and create a mesh with a traffic permission. It then deploys two test applications and verifies identity-based traffic permissions.

## Configure Terraform

1. Create a working directory and change to it:

   ```sh
   export MESH_TERRAFORM_DIR="$PWD/mesh-terraform"
   mkdir -p "$MESH_TERRAFORM_DIR"
   cd "$MESH_TERRAFORM_DIR"
   ```

1. Set the region and pass your {{site.konnect_short_name}} credentials to Terraform:

   ```sh
   export KONNECT_REGION='us'
   export TF_VAR_konnect_token="$KONNECT_TOKEN"
   export TF_VAR_region="$KONNECT_REGION"
   ```

1. Create `providers.tf`, which declares the variables and configures every provider this guide uses:

   ```sh
   cat <<'EOF' > providers.tf
   terraform {
     required_providers {
       konnect-beta = {
         source  = "kong/konnect-beta"
         version = "0.22.0"
       }
       konnect = {
         source  = "kong/konnect"
         version = "3.26.0"
       }
       kubernetes = {
         source  = "hashicorp/kubernetes"
         version = "3.2.1"
       }
       helm = {
         source  = "hashicorp/helm"
         version = "3.1.2"
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

   provider "konnect" {
     personal_access_token = var.konnect_token
     server_url            = "https://${var.region}.api.konghq.com"
   }

   provider "kubernetes" {
     config_path = pathexpand("~/.kube/config")
   }

   provider "helm" {
     kubernetes = {
       config_path = pathexpand("~/.kube/config")
     }
   }
   EOF
   ```

   Mesh resources are only available in the `konnect-beta` provider. The `konnect` provider manages
   the zone's system account.

1. Initialize the working directory:

   ```sh
   terraform init
   ```

Protect Terraform state and don't commit credentials: the state holds the zone token. Keep this directory for later cleanup.

## Create the global control plane

1. Create `control-plane.tf`:

   ```sh
   cat <<'EOF' > control-plane.tf
   resource "konnect_mesh_control_plane" "demo" {
     provider    = konnect-beta
     name        = "example-cp"
     description = "Mesh 3 installation example"
     version     = "v3"
   }

   output "control_plane_id" {
     value = konnect_mesh_control_plane.demo.id
   }
   EOF
   ```

   The [provider's control plane resource](https://registry.terraform.io/providers/kong/konnect-beta/0.22.0/docs/resources/mesh_control_plane)
   defaults to `v2`, so set `version = "v3"` explicitly.

1. Review the plan:

   ```sh
   terraform plan
   ```

1. Apply the plan:

   ```sh
   terraform apply
   ```

1. Export the control plane ID from the Terraform output:

   ```sh
   export CONTROL_PLANE_ID=$(terraform output -raw control_plane_id)
   ```

## Give the zone credentials to connect

The zone uses a system account access token with the `Connector` role on this control plane.

1. Set the token to expire in 30 days. Change the number of days if your organization's token policy requires a shorter lifetime:

   ```sh
   export TF_VAR_zone_token_expires_at=$(jq -nr 'now + 30*24*60*60 | todate')
   ```

1. Create `zone-credentials.tf`:

   ```sh
   cat <<'EOF' > zone-credentials.tf
   variable "zone_token_expires_at" {
     type = string
   }

   resource "konnect_system_account" "zone" {
     name            = "mesh-zone-1"
     description     = "Connect zone-1"
     konnect_managed = false
   }

   resource "konnect_system_account_role" "zone_connector" {
     account_id       = konnect_system_account.zone.id
     role_name        = "Connector"
     entity_type_name = "Mesh Control Planes"
     entity_id        = konnect_mesh_control_plane.demo.id
     entity_region    = var.region
   }

   resource "konnect_system_account_access_token" "zone" {
     account_id = konnect_system_account.zone.id
     name       = "zone-1"
     expires_at = var.zone_token_expires_at
   }
   EOF
   ```

1. Apply the configuration:

   ```sh
   terraform apply
   ```

## Deploy the zone control plane

1. Create `zone.tf`, which stores the zone token in a Secret and installs the zone control plane
   with Helm:

   ```sh
   cat <<'EOF' > zone.tf
   resource "kubernetes_namespace_v1" "kong_mesh_system" {
     metadata {
       name = "kong-mesh-system"
     }
   }

   resource "kubernetes_secret_v1" "cp_token" {
     metadata {
       name      = "cp-token"
       namespace = kubernetes_namespace_v1.kong_mesh_system.metadata[0].name
     }

     data = {
       token = konnect_system_account_access_token.zone.token
     }
   }

   resource "helm_release" "kong_mesh" {
     name       = "kong-mesh"
     repository = "https://kong.github.io/kong-mesh-charts"
     chart      = "kong-mesh"
     version    = "{{page.latest_release.version}}"
     namespace  = kubernetes_namespace_v1.kong_mesh_system.metadata[0].name
     timeout    = 300

     values = [yamlencode({
       kuma = {
         controlPlane = {
           mode             = "zone"
           zone             = "zone-1"
           kdsGlobalAddress = "grpcs://${var.region}.mesh.sync.konghq.com:443"
           konnect = {
             cpId = konnect_mesh_control_plane.demo.id
           }
           zoneToken = {
             secretName = kubernetes_secret_v1.cp_token.metadata[0].name
             key        = "token"
           }
         }
       }
     })]
   }
   EOF
   ```

   The zone reads its token from the `cp-token` Secret through `zoneToken`. This single-zone test
   doesn't need zone proxies; add [mesh-scoped zone proxies](/mesh/mesh-scoped-zone-proxies/) when
   connecting zones or using `MeshExternalService`.

1. Apply the configuration. The `helm_release` waits for the zone control plane to be ready, which
   can take a few minutes:

   ```sh
   terraform apply
   ```

## Verify the zone connection

{% include md/mesh/v3/how-tos/verify-zone-connection-kongctl.md %}

## Create a mesh and secure the test traffic

1. Create `mesh.tf`, which creates the `konnect-demo` mesh and a demo identity provider on the
   global control plane:

   ```sh
   cat <<'EOF' > mesh.tf
   resource "konnect_mesh" "demo" {
     provider = konnect-beta
     cp_id    = konnect_mesh_control_plane.demo.id
     name     = "konnect-demo"
     type     = "Mesh"
   }

   resource "konnect_mesh_identity" "demo" {
     provider = konnect-beta
     cp_id    = konnect_mesh_control_plane.demo.id
     mesh     = konnect_mesh.demo.name
     name     = "demo-identity"
     type     = "MeshIdentity"

     spec = {
       selector = {
         dataplane = {}
       }
       spiffe_id = {
         trust_domain = "konnect-demo.mesh.local"
       }
       provider = {
         type = "Bundled"
         bundled = {
           autogenerate = {
             enabled = true
           }
           insecure_allow_self_signed = true
           mesh_trust_creation        = "Enabled"
         }
       }
     }
   }
   EOF
   ```

   [`MeshIdentity`](/mesh/policies/meshidentity/) issues certificates and publishes their CA in
   `MeshTrust`. This example accepts a generated self-signed CA for the demo; review your
   production PKI requirements before reusing it.

1. Apply the configuration:

   ```sh
   terraform apply
   ```

1. Wait for the identity to be ready and for the trust to be generated:

   ```sh
   kongctl get mesh meshidentities demo-identity --mesh konnect-demo -o yaml \
     --control-plane-id "$CONTROL_PLANE_ID" --region "$KONNECT_REGION" \
     --pat "$KONNECT_TOKEN"
   kongctl get mesh meshtrusts --mesh konnect-demo \
     --control-plane-id "$CONTROL_PLANE_ID" --region "$KONNECT_REGION" \
     --pat "$KONNECT_TOKEN"
   ```

1. Confirm that the new mesh has synced to the Kubernetes zone:

   ```sh
   kubectl get mesh konnect-demo
   ```

1. Create `traffic-permission.tf`, which applies a
   [`MeshTrafficPermission`](/mesh/policies/meshtrafficpermission/) to the zone to allow the
   `client` ServiceAccount to call the `server` workload:

   ```sh
   cat <<'EOF' > traffic-permission.tf
   resource "kubernetes_manifest" "client_to_server" {
     manifest = {
       apiVersion = "kuma.io/v1alpha1"
       kind       = "MeshTrafficPermission"
       metadata = {
         name      = "client-to-server"
         namespace = kubernetes_namespace_v1.kong_mesh_system.metadata[0].name
         labels = {
           "kuma.io/mesh"   = konnect_mesh.demo.name
           "kuma.io/origin" = "zone"
         }
       }
       spec = {
         targetRef = {
           kind = "Dataplane"
           labels = {
             app = "server"
           }
         }
         rules = [
           {
             default = {
               allow = [
                 {
                   spiffeID = {
                     type  = "Exact"
                     value = "spiffe://konnect-demo.mesh.local/ns/kong-mesh-demo/sa/client"
                   }
                 }
               ]
             }
           }
         ]
       }
     }

     depends_on = [helm_release.kong_mesh]
   }
   EOF
   ```

   `kubernetes_manifest` reads the `MeshTrafficPermission` CRD from the cluster when Terraform
   plans, so it can only be applied once the zone control plane from the previous section has
   installed the CRDs.

1. Apply the configuration:

   ```sh
   terraform apply
   ```

## Deploy the test applications

{% include md/mesh/v3/how-tos/deploy-test-applications.md %}

## Validate

{% include md/mesh/v3/how-tos/verify-allowed-and-denied-request.md %}
