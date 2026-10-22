---
title: "Permissions required to install {{ site.operator_product_name }}"

description: |
  Learn about the permissions required to install and run {{ site.operator_product_name }}.

content_type: reference
layout: reference

products:
  - operator

breadcrumbs:
  - /operator/
---

To install {{ site.operator_product_name }} with Helm, you need permissions to **write** (create, update, get, list, watch in Kubernetes's RBAC model) the following resources:

* `CustomResourceDefinition` to install the {{ site.operator_product_name }} and Gateway API CRDs.

* `ClusterRole`, `ClusterRoleBinding` (cluster scoped), `Role`, and `RoleBinding` (namespace scoped) to create the RBAC rules that let the operator access the resources it manages.

* `Deployment`, `Service`, `ServiceAccount`, and `Secret` to deploy the operator and expose its webhook and metrics endpoints.

* `ValidatingWebhookConfiguration` to create the webhook that validates managed resources.

* `ValidatingAdmissionPolicy` and `ValidatingAdmissionPolicyBinding` to install the validation policies shipped with the chart. These require Kubernetes 1.30 or later.

## All required resources

You need write access to the following resources to install {{ site.operator_product_name }}:

<!--vale off-->
{% table %}
columns:
  - title: Resource Kind
    key: kind
  - title: Resource APIVersion
    key: apiVersion
  - title: Resource Scope
    key: scope
  - title: Purpose
    key: usage
rows:
  - kind: "`CustomResourceDefinition`"
    apiVersion: "`apiextensions.k8s.io/v1`"
    scope: Cluster
    usage: Install {{ site.operator_product_name }} and Gateway API CRDs

  - kind: "`ClusterRole`"
    apiVersion: "`rbac.authorization.k8s.io/v1`"
    scope: Cluster
    usage: Grant the operator access to the resources it manages

  - kind: "`ClusterRoleBinding`"
    apiVersion: "`rbac.authorization.k8s.io/v1`"
    scope: Cluster
    usage: Bind the RBAC rules to the operator's ServiceAccount

  - kind: "`Role`"
    apiVersion: "`rbac.authorization.k8s.io/v1`"
    scope: Namespaced
    usage: Enable leader election

  - kind: "`RoleBinding`"
    apiVersion: "`rbac.authorization.k8s.io/v1`"
    scope: Namespaced
    usage: Bind the leader election role to the operator's ServiceAccount

  - kind: "`Deployment`"
    apiVersion: "`apps/v1`"
    scope: Namespaced
    usage: Run the operator

  - kind: "`Service`"
    apiVersion: "`v1`"
    scope: Namespaced
    usage: Expose the webhook and metrics endpoints

  - kind: "`ServiceAccount`"
    apiVersion: "`v1`"
    scope: Namespaced
    usage: Provide an identity for the operator Pods

  - kind: "`Secret`"
    apiVersion: "`v1`"
    scope: Namespaced
    usage: Store TLS certificates and configuration

  - kind: "`ValidatingWebhookConfiguration`"
    apiVersion: "`admissionregistration.k8s.io/v1`"
    scope: Cluster
    usage: Configure the validating webhook

  - kind: "`ValidatingAdmissionPolicy`"
    apiVersion: "`admissionregistration.k8s.io/v1`"
    scope: Cluster
    usage: Enforce validation policies on managed resources

  - kind: "`ValidatingAdmissionPolicyBinding`"
    apiVersion: "`admissionregistration.k8s.io/v1`"
    scope: Cluster
    usage: Bind validation policies to the managed resources{% endtable %}
<!--vale on-->

### Optional resources

The following resources are required for specific configurations:

<!--vale off-->
{% table %}
columns:
  - title: Resource Kind
    key: kind
  - title: Resource APIVersion
    key: apiVersion
  - title: Resource Scope
    key: scope
  - title: Purpose
    key: usage
rows:
  - kind: "`Certificate`"
    apiVersion: "`cert-manager.io/v1`"
    scope: Namespaced
    usage: Manage TLS certificates when using cert-manager for webhook certificates

  - kind: "`Issuer`"
    apiVersion: "`cert-manager.io/v1`"
    scope: Namespaced
    usage: Issue the TLS certificates when using cert-manager for webhook certificates

  - kind: "`Lease`"
    apiVersion: "`coordination.k8s.io/v1`"
    scope: Namespaced
    usage: Coordinate leader election between operator replicas{% endtable %}
<!--vale on-->

## Managing {{ site.operator_product_name }} resources

To create and manage {{ site.operator_product_name }} resources, you need write access to the Custom Resources in the following API groups:

<!--vale off-->
{% table %}
columns:
  - title: API group
    key: group
  - title: Purpose
    key: purpose
rows:
  - group: "`gateway-operator.konghq.com`"
    purpose: Deploy and manage Kong Gateways in-cluster (for example, `GatewayConfiguration`, `ControlPlane`, `DataPlane`)

  - group: "`konnect.konghq.com`"
    purpose: Configure Konnect resources from Kubernetes (for example, `KonnectGatewayControlPlane`, `KonnectAPIAuthConfiguration`)

  - group: "`configuration.konghq.com`"
    purpose: Configure Kong entities and policies (for example, `KongService`, `KongRoute`, `KongPlugin`, `KongConsumer`)

  - group: "`aiconfiguration.konghq.com`"
    purpose: Configure AI Gateway resources

  - group: "`aigateway.konghq.com`"
    purpose: Deploy AI Gateway instances

  - group: "`eventgateway.konghq.com`"
    purpose: Deploy Kong Event Gateway resources

  - group: "`mcp.konghq.com`"
    purpose: Deploy MCP Server resources

  - group: "`gateway.networking.k8s.io`"
    purpose: Standard Gateway API resources (`Gateway`, `HTTPRoute`){% endtable %}
<!--vale on-->

For the complete and current list of Custom Resources, see [Custom resource definitions](/operator/reference/custom-resources/), which is generated from the operator source and always up to date.

## Permissions of the operator itself

The operator's ServiceAccount needs a set of permissions to reconcile the resources it manages. The Helm chart creates the required `ClusterRole` and `ClusterRoleBinding` automatically, so you don't need to manage them manually.

The rules are generated from the operator source and change between releases as new features are added. The following table summarizes the access patterns:

<!--vale off-->
{% table %}
columns:
  - title: Access
    key: access
  - title: Resources
    key: resources
rows:
  - access: "`create`, `delete`, `get`, `list`, `patch`, `update`, `watch`"
    resources: Core resources such as `ConfigMap`, `Secret`, `Service`, and `ServiceAccount`; `Deployment`; Gateway API `Gateway` and `HTTPRoute`; the Kong Custom Resources the operator manages; `Certificate`; `HorizontalPodAutoscaler`; `PodDisruptionBudget`; `NetworkPolicy`; `Role` and `RoleBinding`; `Lease`

  - access: "`get`, `list`, `watch`"
    resources: Reference and discovery resources such as `Pod`, `Namespace`, `Node`, `Ingress`, `GatewayClass`, and Kong Custom Resources consumed as inputs

  - access: "`patch`, `update` on `status` and `finalizers` subresources"
    resources: All the Custom Resources the operator manages{% endtable %}
<!--vale on-->

The operator also creates namespace-scoped RBAC rules itself so that the Gateways it deploys can access the resources they need.

For the complete set of rules, see the [ClusterRole template](https://github.com/Kong/kong-operator/blob/main/charts/kong-operator/templates/cluster-role.yaml) in the {{ site.operator_product_name }} chart.
