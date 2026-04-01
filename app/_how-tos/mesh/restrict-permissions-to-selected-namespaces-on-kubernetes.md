---
title: Restrict {{site.mesh_product_name}} permissions to selected namespaces on Kubernetes
description: "This guide explains how to limit {{site.mesh_product_name}} to specific namespaces, giving you greater control over security and resource management."
content_type: how_to
permalink: /mesh/restrict-permissions-to-selected-namespaces-on-kubernetes/
bread-crumbs: 
  - /mesh/
related_resources: 
  - text: Manage control plane permissions on Kubernetes
    url: /mesh/manage-control-plane-permissions-on-kubernetes/
min_version:
    mesh: '2.11'
products:
  - mesh


tldr:
  q: How can I configure {{site.mesh_product_name}} to only manage specific namespaces?
  a: Create a namespace, then set `kuma.namespaceAllowList` to the name of the namespace to use when installing {{site.mesh_product_name}}.

prereqs:
  inline:
    - title: Helm
      include_content: prereqs/helm
    - title: A running Kubernetes cluster
      include_content: prereqs/kubernetes/mesh-cluster

cleanup:
  inline:
    - title: Clean up Mesh
      include_content: cleanup/products/mesh
      icon_url: /assets/icons/gateway.svg
---


## Install {{site.mesh_product_name}} which manages a single namespace

By default, {{site.mesh_product_name}} deployed on Kubernetes has permissions to observe and react to events from resources across the entire cluster. While this behavior simplifies initial setup and testing, it might be too permissive for production environments. Limiting {{site.mesh_product_name}}'s access to only necessary namespaces helps enhance security and prevents potential impact on unrelated applications.

Run the following commands to create a first namespace and install an instance of {{site.mesh_product_name}} restricted to that namespace.

1. Create and label the namespace:
   ```bash
   kubectl create namespace first-namespace
   kubectl label namespace first-namespace kuma.io/sidecar-injection=enabled
   ```

1. Install {{site.mesh_product_name}}:
   ```bash
   helm upgrade \
     --install \
     --create-namespace \
     --namespace {{ site.mesh_namespace }} \
     --set "{{ site.set_flag_values_prefix }}namespaceAllowList={first-namespace}" \
     {{ site.mesh_helm_install_name }} {{ site.mesh_helm_repo }}
   ```

1. Deploy a test workload:
   ```bash
   kubectl run nginx --image=nginx --port=80 --namespace first-namespace
   ```

## Verify that the first namespace is working

1. Check that the control plane is managing the workload:
   ```bash
   kubectl get dataplanes --namespace first-namespace
   ```

   Expected output:
   ```
   NAME    KUMA.IO/SERVICE             KUMA.IO/SERVICE
   nginx   nginx_first-namespace_svc
   ```
   {:.no-copy-code}

1. Check that the pod has the sidecar injected:

   {:.info}
   > You may need to wait a few minutes for the pods to initialize.

   ```bash
   kubectl get pods --namespace first-namespace
   ```

   Expected output:
   ```
   NAME    READY   STATUS    RESTARTS   AGE
   nginx   2/2     Running   0          2m5s
   ```
   {:.no-copy-code}

1. Verify the required RoleBinding:

   ```bash
   kubectl get rolebindings --namespace first-namespace
   ```

   Expected output:
   ```
   NAME                                ROLE                                            AGE
   kong-mesh-control-plane-workloads   ClusterRole/kong-mesh-control-plane-workloads   3m46s
   ```
   {:.no-copy-code}

This confirms that:

* A `Dataplane` was created.
* The pod includes the `kuma-sidecar`.
* A `RoleBinding` named `kong-mesh-control-plane-workloads` grants elevated access to the control plane.

## Create a second namespace in which {{site.mesh_product_name}} doesn't run

1. Create and label the namespace:
   ```bash
   kubectl create namespace second-namespace
   kubectl label namespace second-namespace kuma.io/sidecar-injection=enabled
   ```

1. Deploy the same test workload in the second namespace:
   ```bash
   kubectl run nginx --image=nginx --port=80 --namespace second-namespace
   ```

## Verify the second namespace is not working

Check that the control plane is **not** managing resources in `second-namespace`.

1. Check the data planes in the second namespace:
   ```bash
   kubectl get dataplanes --namespace second-namespace
   ```

   Expected output:
   ```
   No resources found in second-namespace namespace.
   ```
   {:.no-copy-code}

1. Check the pods: 
   ```bash
   kubectl get pods --namespace second-namespace
   ```

   Expected output:
   ```
   NAME    READY   STATUS    RESTARTS   AGE
   nginx   1/1     Running   0          42s
   ```
   {:.no-copy-code}

   This indicates the pod is running without the `kuma-sidecar`.

1. Check the role bindings:
   ```bash
   kubectl get rolebindings --namespace second-namespace
   ```

   Expected output:
   ```
   No resources found in second-namespace namespace.
   ```
   {:.no-copy-code}

This confirms that:
* The control plane does not have permission to manage this namespace.
* The pod was started without sidecar injection.
* No `RoleBinding` was created to grant control plane access.

## Update {{site.mesh_product_name}} to also manage the second namespace

1. Update {{site.mesh_product_name}} to include `second-namespace`:
   ```bash
   helm upgrade \
     --install \
     --create-namespace \
     --namespace {{ site.mesh_namespace }} \
     --set "{{ site.set_flag_values_prefix }}namespaceAllowList={first-namespace,second-namespace}" \
     {{ site.mesh_helm_install_name }} {{ site.mesh_helm_repo }}
   ```

1. Delete the old pod and recreate it to trigger sidecar injection:
   ```bash
   kubectl delete pod --namespace second-namespace --all
   kubectl run nginx --image=nginx --port=80 --namespace second-namespace
   ```

## Verify the second namespace is now working

1. Check that the control plane is now managing the workload in `second-namespace`:
   ```bash
   kubectl get dataplanes --namespace second-namespace
   ```

   Expected output:
   ```
   NAME    KUMA.IO/SERVICE              KUMA.IO/SERVICE
   nginx   nginx_second-namespace_svc   
   ```
   {:.no-copy-code}

1. Verify that the pod now includes a sidecar:

   {:.info}
   > You may need to wait a few minutes for the pods to initialize.

   ```bash
   kubectl get pods --namespace second-namespace
   ```

   Expected output:
   ```
   NAME    READY   STATUS    RESTARTS   AGE
   nginx   2/2     Running   0          30s
   ```
   {:.no-copy-code}

1. Check that the required `RoleBinding` has been created:
   ```bash
   kubectl get rolebindings --namespace second-namespace
   ```

   Expected output:
   ```
   NAME                                ROLE                                            AGE
   kong-mesh-control-plane-workloads   ClusterRole/kong-mesh-control-plane-workloads   30s
   ```
   {:.no-copy-code}

This confirms that:

* The control plane has the correct permissions in `second-namespace`
* The pod was injected with the `kuma-sidecar`
* The namespace is now fully integrated with the mesh
