---
title: Manage control plane permissions on Kubernetes
description: This guide explains how to manage control plane permissions on Kubernetes
content_type: reference
layout: reference
products:
    - mesh
breadcrumbs:
  - /mesh/

min_version:
  mesh: '2.11'

tags:
  - kubernetes
  - control-plane
  - access-control

works_on:
  - on-prem
  - konnect

related_resources: 
  - text: Restrict permissions to selected namespaces on Kubernetes
    url: /mesh/restrict-permissions-to-selected-namespaces-on-kubernetes/
---

By default, {{site.mesh_product_name}} deployed on Kubernetes reacts to events and observes all resources at the cluster scope. This approach benefits first-time users who want to explore its functionality and simplifies migration. However, in production environments, restricting access to specific resources can enhance security and ensure that {{site.mesh_product_name}} doesn't impact running applications.

## Restrict permissions to selected namespaces

You can define a list of namespaces that the {{site.mesh_product_name}} control plane can access. When this list is set, {{site.mesh_product_name}} will only have permissions in those selected namespaces and in its own system namespace. It won’t be able to access or manage resources in any other namespace.

To restrict {{site.mesh_product_name}} to a specific set of namespaces, set the `kuma.namespaceAllowList` option during installation:

{% cpinstall namespaceAllowList %}
namespaceAllowList={first-namespace,second-namespace}
{% endcpinstall %}

This will create a `RoleBinding` in each listed namespace, binding the `{{site.mesh_cp_name}}-workloads` `ClusterRole` to that namespace. It will also configure {{site.mesh_product_name}}’s mutating and validating webhooks to only work within the specified namespaces.

## Manually manage RBAC resources

If your environment restricts creating cluster-scoped resources (`ClusterRole` or `ClusterRoleBinding`), or if you prefer to manage permissions yourself, you can disable automatic resource creation during installation.

Before installing {{site.mesh_product_name}}, you must manually create the following resources:

* `ClusterRole` and `ClusterRoleBinding` used by the control plane
* `Role` and `RoleBinding` within the control plane namespace
* `RoleBindings` in selected namespaces when using `namespaceAllowList` (optional)

You can find the complete set of required manifests here:

{% rbacresources %}

These manifests include the `{{site.mesh_cp_name}}-workloads` binding, granting the control plane write access to resources across all namespaces.

{:.warning}
> All required resources must be created **before** installing {{site.mesh_product_name}}.

### Disable automatic resource creation

To skip creation of all resources, use `kuma.skipRBAC=true` during installation:

{% cpinstall skipRBAC %}
skipRBAC=true
{% endcpinstall %}

To skip only cluster-scoped resources `kuma.controlPlane.skipClusterRoleCreation=true`:

{% cpinstall skipClusterRoleCreation %}
controlPlane.skipClusterRoleCreation=true
{% endcpinstall %}

{:.warning}
> If you choose to manage {{site.mesh_product_name}}'s RBAC resources yourself, make sure to keep them in sync during upgrades. When a new version of {{site.mesh_product_name}} is released, roles and role bindings may change, and it's your responsibility to update them accordingly.