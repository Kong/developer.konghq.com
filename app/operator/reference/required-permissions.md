---
title: "Permissions required for {{ site.operator_product_name }}"

description: |
  Reference for the Kubernetes permissions required to install and run {{ site.operator_product_name }}.

content_type: reference
layout: reference

products:
  - operator

breadcrumbs:
  - /operator/

related_resources:
  - text: Install {{ site.operator_product_name }}
    url: /operator/get-started/gateway-api/install/
  - text: Custom resource definitions
    url: /operator/reference/custom-resources/
  - text: "{{ site.operator_product_name }} architecture"
    url: /operator/reference/architecture/
---

Installing {{ site.operator_product_name }} creates cluster-scoped resources, such as CRDs and RBAC rules, so a namespace-scoped account isn't enough.
This page lists the permissions you need to install {{ site.operator_product_name }} and manage its resources, and the permissions {{ site.operator_product_name }} itself needs.

## Installing {{ site.operator_product_name }}

You need write access to the following resources to install {{ site.operator_product_name }}:

<!--vale off-->
{% table %}
columns:
  - title: Resource Kind
    key: kind
  - title: Resource APIVersion
    key: apiVersion
  - title: Resource scope
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
    usage: Grant {{ site.operator_product_name }} access to the resources it manages

  - kind: "`ClusterRoleBinding`"
    apiVersion: "`rbac.authorization.k8s.io/v1`"
    scope: Cluster
    usage: Bind the RBAC rules to the {{ site.operator_product_name }} ServiceAccount

  - kind: "`Role`"
    apiVersion: "`rbac.authorization.k8s.io/v1`"
    scope: Namespaced
    usage: Enable leader election

  - kind: "`RoleBinding`"
    apiVersion: "`rbac.authorization.k8s.io/v1`"
    scope: Namespaced
    usage: Bind the leader election role to the {{ site.operator_product_name }} ServiceAccount

  - kind: "`Deployment`"
    apiVersion: "`apps/v1`"
    scope: Namespaced
    usage: Run {{ site.operator_product_name }}

  - kind: "`Service`"
    apiVersion: "`v1`"
    scope: Namespaced
    usage: Expose the webhook and metrics endpoints

  - kind: "`ServiceAccount`"
    apiVersion: "`v1`"
    scope: Namespaced
    usage: Provide an identity for the {{ site.operator_product_name }} Pods

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

The following resources are optional.
You need write access to them only when you use cert-manager for webhook certificates:

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
    usage: Issue the TLS certificates when using cert-manager for webhook certificates{% endtable %}
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
    purpose: Deploy and manage {{ site.base_gateway }} instances in-cluster (for example, `GatewayConfiguration`, `ControlPlane`, `DataPlane`)

  - group: "`konnect.konghq.com`"
    purpose: Configure {{ site.konnect_short_name }} resources from Kubernetes (for example, `KonnectGatewayControlPlane`, `KonnectAPIAuthConfiguration`)

  - group: "`configuration.konghq.com`"
    purpose: Configure Kong entities and policies (for example, `KongService`, `KongRoute`, `KongPlugin`, `KongConsumer`)

  - group: "`aiconfiguration.konghq.com`"
    purpose: Configure {{ site.ai_gateway }} resources

  - group: "`aigateway.konghq.com`"
    purpose: Deploy {{ site.ai_gateway }} instances

  - group: "`eventgateway.konghq.com`"
    purpose: Deploy {{ site.event_gateway }} resources

  - group: "`mcp.konghq.com`"
    purpose: Deploy MCP Server resources

  - group: "`gateway.networking.k8s.io`"
    purpose: Standard Gateway API resources (`Gateway`, `HTTPRoute`){% endtable %}
<!--vale on-->

For the complete list of Custom Resources, see [Custom resource definitions](/operator/reference/custom-resources/).

## {{ site.operator_product_name }} ServiceAccount permissions

The {{ site.operator_product_name }} ServiceAccount needs a set of permissions to reconcile the resources it manages.
The Helm chart creates the required `ClusterRole` and `ClusterRoleBinding` automatically, so you don't need to manage them manually.

The rules are generated from the {{ site.operator_product_name }} source.
They change between releases as new features are added.
The following table summarizes the access patterns:

<!--vale off-->
{% table %}
columns:
  - title: Access
    key: access
  - title: Resources
    key: resources
rows:
  - access: "`create`, `delete`, `get`, `list`, `patch`, `update`, `watch`"
    resources: Core resources (`ConfigMap`, `Secret`, `Service`, and `ServiceAccount`), `Deployment`, Gateway API `Gateway` and `HTTPRoute`, the Kong Custom Resources that {{ site.operator_product_name }} manages, `Certificate`, `HorizontalPodAutoscaler`, `PodDisruptionBudget`, `NetworkPolicy`, `Role`, `RoleBinding`, and `Lease`

  - access: "`get`, `list`, `watch`"
    resources: Reference and discovery resources such as `Pod`, `Namespace`, `Node`, `Ingress`, `GatewayClass`, and Kong Custom Resources consumed as inputs

  - access: "`patch`, `update` on `status` and `finalizers` subresources"
    resources: All the Custom Resources that {{ site.operator_product_name }} manages
{% endtable %}
<!--vale on-->

{{ site.operator_product_name }} also creates namespace-scoped RBAC rules itself so that the Gateways it deploys can access the resources they need.

For the complete set of rules, see the [ClusterRole template](https://github.com/Kong/kong-operator/blob/main/charts/kong-operator/templates/cluster-role.yaml) in the {{ site.operator_product_name }} chart.
