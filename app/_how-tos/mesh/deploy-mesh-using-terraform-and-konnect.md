---
title: 'Deploy {{site.mesh_product_name}} using Terraform and {{site.konnect_short_name}}'
content_type: how_to
permalink: /mesh/deploy-mesh-using-terraform-and-konnect/
breadcrumbs:
  - /mesh/
description: 'Use Terraform to provision a {{site.konnect_short_name}}-managed global control plane, a mesh, and a policy, then deploy a Kubernetes zone control plane.'
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
  q: How do I deploy {{site.mesh_product_name}} with Terraform and {{site.konnect_short_name}}?
  a: Use the `konnect` and `konnect-beta` Terraform providers to create a global control plane, a mesh, and a `MeshTrafficPermission` policy in {{site.konnect_short_name}}, then deploy a Kubernetes zone control plane that authenticates with a system account token.
prereqs:
  inline:
    - title: Terraform
      include_content: prereqs/terraform
    - title: k3d
      content: |
        Install [k3d](https://k3d.io/stable/#installation) to run a local Kubernetes cluster (tested on k3d `v5.8.1`, k3s `v1.31.4-k3s1`).
cleanup:
  inline:
    - title: Destroy the Terraform resources
      content: |
        From the `~/mesh-konnect` working directory, remove all the resources created by this guide:

        ```sh
        terraform destroy
        ```
    - title: Remove the working directory
      content: |
        Delete the working directory and the Terraform files created by this guide:

        ```sh
        cd ../
        rm -rf ~/mesh-konnect
        ```
related_resources:
  - text: "{{site.mesh_product_name}} in {{site.konnect_short_name}}"
    url: /mesh/konnect/
  - text: "Terraform provider (GA)"
    url: https://registry.terraform.io/providers/kong/konnect/latest
  - text: "Terraform provider (Beta)"
    url: https://registry.terraform.io/providers/kong/konnect-beta/latest
  - text: "MeshTrafficPermission"
    url: /mesh/policies/meshtrafficpermission/
faqs:
  - q: What happens if I rename a Terraform resource?
    a: |
      Certain properties, such as the mesh name or policy name, are used as identifiers. Changing them results in a new resource being created and all dependent resources being recreated.

      For example, changing the mesh name to `another-name`:

      ```hcl
      resource "konnect_mesh" "my_mesh" {
        # ...
        name = "another-name"
        # ...
      }
      ```

      forces replacement of both the `konnect_mesh` and `konnect_mesh_traffic_permission` resources:

      ```sh
          # konnect_mesh.my_mesh must be replaced
      -/+ resource "konnect_mesh" "my_mesh" {
            ~ name                           = "mesh1" -> "another-name" # forces replacement
              # (4 unchanged attributes hidden)
          }

        # konnect_mesh_traffic_permission.allow_all must be replaced
      -/+ resource "konnect_mesh_traffic_permission" "allow_all" {
            ~ creation_time     = "2025-03-13T09:53:00.606442Z" -> (known after apply)
            ~ mesh              = "mesh1" -> "another-name" # forces replacement
      ```
      {:.no-copy-code}
---

This guide uses Terraform to provision a {{site.konnect_short_name}}-managed global control plane, a mesh with mTLS, and a `MeshTrafficPermission` policy, and then deploys a Kubernetes zone control plane that connects to it. To learn how {{site.mesh_product_name}} works with {{site.konnect_short_name}}, see [{{site.mesh_product_name}} in {{site.konnect_short_name}}](/mesh/konnect/).

## Set up the Terraform variables

1. Create and enter a working directory for this guide:

   ```sh
   mkdir -p ~/mesh-konnect && cd ~/mesh-konnect
   ```

1. Create a `variables.tf` file:

   ```sh
   cat <<'EOF' > variables.tf
   variable "konnect_personal_access_token" {
       type    = string
   }

   variable "region" {
       type    = string
   }
   EOF
   ```

1. Provide these variables at runtime, or set them as environment variables:

   ```sh
   export TF_VAR_konnect_personal_access_token=$KONNECT_TOKEN
   export TF_VAR_region="us"
   ```

## Configure the providers

This guide uses the `konnect` and `konnect-beta` Terraform providers. The `konnect` provider is the [general availability](/stages-of-software-availability/#general-availability) version, and `konnect-beta` is the [beta](/stages-of-software-availability/#beta) version with the latest features. Features move from the beta provider to the GA provider once they are stable and fully tested.

Mesh resources are currently available only in the beta provider.

1. Create a `providers.tf` file:

   ```sh
   cat <<'EOF' > providers.tf
   terraform {
     required_providers {
       konnect = {
         source = "kong/konnect"
       }
       konnect-beta = {
         source  = "kong/konnect-beta"
       }
     }
   }

   provider "konnect" {
       personal_access_token = var.konnect_personal_access_token
       server_url            = "https://${var.region}.api.konghq.com"
   }

   provider "konnect-beta" {
       personal_access_token = var.konnect_personal_access_token
       server_url            = "https://${var.region}.api.konghq.com"
   }
   EOF
   ```

1. Download the providers:

   ```sh
   terraform init
   ```

   You should see the following message:

   ```sh
   Terraform has been successfully initialized!
   ```
   {:.no-copy-code}

## Create a global control plane in {{site.konnect_short_name}}

1. Create a `main.tf` file that defines a global control plane in {{site.konnect_short_name}}:

   ```sh
   cat <<'EOF' > main.tf
   resource "konnect_mesh_control_plane" "my_meshcontrolplane" {
     provider    = konnect-beta
     name        = "tf-cp"
     description = "A control plane created using terraform"
     labels = {
       "terraform" = "true"
     }
   }
   EOF
   ```

1. Apply the changes to create the resource:

   ```sh
   terraform apply -auto-approve
   ```

   You should see:

   ```sh
   Terraform used the selected providers to generate the following execution plan.
   Resource actions are indicated with the following symbols:
     + create
   
   Terraform will perform the following actions:
   
     # konnect_mesh_control_plane.my_meshcontrolplane will be created
     + resource "konnect_mesh_control_plane" "my_meshcontrolplane" {
         + created_at  = (known after apply)
         + description = "A control plane created using terraform"
         + features    = (known after apply)
         + id          = (known after apply)
         + labels      = {
             + "terraform" = "true"
           }
         + name        = "tf-cp"
         + updated_at  = (known after apply)
       }
   
   Plan: 1 to add, 0 to change, 0 to destroy.
   konnect_mesh_control_plane.my_meshcontrolplane: Creating...
   konnect_mesh_control_plane.my_meshcontrolplane: Creation complete after 1s
   
   Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
   ```
   {:.no-copy-code}

## Create a mesh

Now that a control plane exists, create a mesh with mTLS enabled. The `cp_id` property is set to the ID of the control plane created in the previous step, and `skip_creating_initial_policies` is set to `["*"]` to skip creating the default policies so that all resources in the mesh are tracked by Terraform.

1. Create a `mesh.tf` file:

   ```sh
   cat <<'EOF' > mesh.tf
   resource "konnect_mesh" "my_mesh" {
     provider = konnect-beta

     name     = "my-mesh"
     type     = "Mesh"
     skip_creating_initial_policies = [ "*" ]

     mtls = {
       "backends" = [
         {
           "name" = "ca-1"
           "type" = "builtin"
         }
       ]
       "mode"           = "permissive"
       "enabledBackend" = "ca-1"
     }

     cp_id    = konnect_mesh_control_plane.my_meshcontrolplane.id
   }
   EOF
   ```

1. Apply the changes to create the mesh:

   ```sh
   terraform apply -auto-approve
   ```

For the full schema of the mesh resource, see the [konnect-beta provider documentation](https://github.com/Kong/terraform-provider-konnect-beta/blob/main/docs/resources/mesh.md).

## Add a traffic permission policy

Each {{site.mesh_product_name}} policy example includes a Terraform tab showing a Terraform representation of the policy. This step uses the [allow-all example](/mesh/policies/meshtrafficpermission/#allow-all) from the `MeshTrafficPermission` page.

{:.info}
> {{site.mesh_product_name}} manages reserved `kuma.io/*` labels, such as `kuma.io/mesh` and `kuma.io/origin`, automatically. Don't set them in your Terraform configuration: the `mesh` attribute already associates the policy with its mesh, and setting a reserved label causes a provider plan error.

1. Create a `traffic-permission.tf` file:

   ```sh
   cat <<'EOF' > traffic-permission.tf
   resource "konnect_mesh_traffic_permission" "allow_all" {
    provider = konnect-beta

    type = "MeshTrafficPermission"
    name = "allow-all"
    spec = {
      from = [
        {
          target_ref = {
            kind = "Mesh"
          }
          default = {
            action = "Allow"
          }
        }
      ]
    }

    cp_id    = konnect_mesh_control_plane.my_meshcontrolplane.id
    mesh     = konnect_mesh.my_mesh.name
   }
   EOF
   ```

1. Apply the changes to create the policy:

   ```sh
   terraform apply -auto-approve
   ```

## Deploy a Kubernetes zone

You can deploy a Kubernetes zone to any Kubernetes cluster. This guide uses `k3d` to create a local cluster.

### Create a cluster

1. Create a new k3d cluster:

   ```sh
   k3d cluster create tfmink
   ```

1. Store the `tfmink` cluster configuration in `$KUBECONFIG`:

   ```sh
   export KUBECONFIG=$(k3d kubeconfig write tfmink)
   ```

1. Add a variable pointing to the kubeconfig file and a variable for the zone name to `variables.tf`:

   ```sh
   cat <<'EOF' >> variables.tf
   variable "k8s_cluster_config_path" {
     type        = string
     description = "The location where this cluster's kubeconfig will be saved to."
   }

   variable "zone_name" {
       type    = string
       default = "tfzone1"
   }
   EOF
   ```

1. Set `TF_VAR_k8s_cluster_config_path` to your kubeconfig value:

   ```sh
   export TF_VAR_k8s_cluster_config_path=$KUBECONFIG
   ```

### Configure the Kubernetes and Helm providers

1. Update `providers.tf` to add the `time`, `kubernetes`, and `helm` providers:

   ```sh
   cat <<'EOF' > providers.tf
   terraform {
     required_providers {
       konnect = {
         source = "kong/konnect"
       }
       konnect-beta = {
         source  = "kong/konnect-beta"
       }
       time = {
         source  = "hashicorp/time"
       }
       kubernetes = {
         source  = "hashicorp/kubernetes"
       }
       helm = {
         source  = "hashicorp/helm"
       }
     }
   }

   provider "konnect" {
       personal_access_token = var.konnect_personal_access_token
       server_url            = "https://${var.region}.api.konghq.com"
   }

   provider "konnect-beta" {
       personal_access_token = var.konnect_personal_access_token
       server_url            = "https://${var.region}.api.konghq.com"
   }

   provider "helm" {
       kubernetes = {
           config_path = pathexpand(var.k8s_cluster_config_path)
       }
   }

   provider "kubernetes" {
       config_path = pathexpand(var.k8s_cluster_config_path)
   }
   EOF
   ```

1. Download the new providers:

   ```sh
   terraform init -upgrade
   ```

### Create a system account

1. Create a `system-account.tf` file that defines a system account and a token to authenticate the zone:

   ```sh
   cat <<'EOF' > system-account.tf
   resource "konnect_system_account" "zone_system_account" {
     name            = "mesh_${konnect_mesh_control_plane.my_meshcontrolplane.id}_${var.zone_name}"
     description     = "Terraform generated system account for authentication zone ${var.zone_name} in ${konnect_mesh_control_plane.my_meshcontrolplane.id} control plane."
     konnect_managed = false
   }

   resource "konnect_system_account_role" "zone_system_account_role" {
     account_id       = konnect_system_account.zone_system_account.id
     entity_id        = konnect_mesh_control_plane.my_meshcontrolplane.id
     entity_region    = var.region
     entity_type_name = "Mesh Control Planes"
     role_name        = "Connector"
   }

   resource "time_offset" "one_year_from_now" {
     offset_years = 1
   }

   resource "konnect_system_account_access_token" "zone_system_account_token" {
     account_id = konnect_system_account.zone_system_account.id
     expires_at = time_offset.one_year_from_now.rfc3339
     name       = konnect_system_account.zone_system_account.name
   }
   EOF
   ```

1. Store the token in Kubernetes by creating a `k8s.tf` file:

   ```sh
   cat <<'EOF' > k8s.tf
   resource "kubernetes_namespace" "kong_mesh_system" {
     metadata {
       name = "kong-mesh-system"
       labels = {
         "kuma.io/system-namespace" = "true"
       }
     }
   }

   resource "kubernetes_secret" "mesh_cp_token" {
     metadata {
       name = "cp-token"
       namespace = kubernetes_namespace.kong_mesh_system.metadata.0.name
     }

     data = {
       token = konnect_system_account_access_token.zone_system_account_token.token
     }

     type = "opaque"
   }
   EOF
   ```

### Create the zone

1. Create a `values.tftpl` file with templated values for the zone, address, and control plane ID:

   ```sh
   cat <<'EOF' > values.tftpl
   kuma:
     controlPlane:
       mode: zone
       zone: ${zone_name}
       kdsGlobalAddress: grpcs://${region}.mesh.sync.konghq.com:443
       konnect:
         cpId: ${cp_id}
       secrets:
         - Env: KMESH_MULTIZONE_ZONE_KDS_AUTH_CP_TOKEN_INLINE
           Secret: cp-token
           Key: token
     ingress:
       enabled: true
     egress:
       enabled: true
   EOF
   ```

1. Create a `zone.tf` file that defines the zone:

   ```sh
   cat <<'EOF' > zone.tf
   resource "helm_release" "kong_mesh" {
     name       = "kong-mesh"
     repository = "https://kong.github.io/kong-mesh-charts"
     chart      = "kong-mesh"

     namespace = kubernetes_namespace.kong_mesh_system.metadata.0.name
     upgrade_install = true

     values = [templatefile("values.tftpl", {
       zone_name = var.zone_name,
       region    = var.region,
       cp_id     = konnect_mesh_control_plane.my_meshcontrolplane.id
     })]
   }
   EOF
   ```

1. Apply the changes:

   ```sh
   terraform apply -auto-approve
   ```

   You should see 7 resources created. The `helm_release` can take some time to create:

   ```sh
   helm_release.kong_mesh: Creation complete after 54s [id=kong-mesh]
   ```
   {:.no-copy-code}

## Validate

1. Confirm that the `MeshTrafficPermission` you created earlier is now available in the zone:

   ```sh
   kubectl get meshtrafficpermissions.kuma.io -A
   ```

   You should see:

   ```sh
   NAMESPACE          NAME
   kong-mesh-system   allow-all-wd5xx76vc44b498c
   ```
   {:.no-copy-code}

1. In the {{site.konnect_short_name}} sidebar, click [**Service Mesh**](https://cloud.konghq.com/mesh-manager).
1. Click **tf-cp**.
   You should see the zone and the mesh you created.