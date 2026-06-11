---
title: "Multi-tenancy"
description: "Understand how to run multiple isolated {{ site.base_gateway }} instances on the same Kubernetes cluster using {{ site.operator_product_name }}."
content_type: reference
layout: reference

breadcrumbs:
  - /operator/
  - index: operator
    group: Reference

products:
  - operator

works_on:
  - on-prem

min_version:
  operator: '1.6'

related_resources:
  - text: "Deploy multiple isolated gateways on the same cluster"
    url: /operator/dataplanes/how-to/multi-tenancy/setup/
  - text: "{{site.operator_product_name}} architecture"
    url: /operator/reference/architecture/
  - text: "Limiting namespaces watched by ControlPlane"
    url: /operator/reference/control-plane-watch-namespaces/
  - text: "Gateway configuration"
    url: /operator/dataplanes/gateway-configuration/
  - text: "Managed Gateways"
    url: /operator/dataplanes/managed-gateways/
  - text: "Custom Resources"
    url: /operator/reference/custom-resources/
---

<!-- SOURCE: architecture.md, control-plane-watch-namespaces.md, Baptiste's gist
     https://gist.github.com/bcollard/44caa409cdf7d796506a7a2e61a4a0d5,
     and FEATURES.md https://github.com/Kong/kong-operator/blob/main/FEATURES.md -->

Multi-tenancy in {{ site.operator_product_name }} means running multiple isolated {{ site.base_gateway }} instances — each with their own routing configuration, data plane, and namespace scope — on the same Kubernetes cluster, managed by a single {{ site.operator_product_name }} installation.

Common use cases include separating a public-facing API gateway from an internal one, or giving different teams independent gateway instances without requiring separate clusters.

## How it works

<!-- SOURCE: managed-gateways.md, architecture.md -->

Each tenant is represented by a **Gateway**, provisioned using a triptych of three resources:

```
GatewayConfiguration  ──(parametersRef)──▶  GatewayClass  ──(gatewayClassName)──▶  Gateway
```

For each `Gateway`, {{ site.operator_product_name }} creates:

- One **in-memory KIC instance** embedded inside the {{ site.operator_product_name }} pod (not a separately deployed pod), which watches Gateway API resources and translates them into Kong configuration.
- One **DataPlane deployment** running {{ site.base_gateway }} in DB-less mode.

Multiple `Gateway` resources can coexist in the same cluster. The resulting in-memory KIC instances and DataPlane pods are independent of each other. A single {{ site.operator_product_name }} installation manages them all.

## Namespace isolation

<!-- SOURCE: control-plane-watch-namespaces.md -->

By default, each in-memory KIC instance watches **all namespaces** for Gateway API resources (`HTTPRoute`, `GRPCRoute`, etc.). This means, without additional configuration, one tenant's KIC would also process another tenant's routes. Namespace isolation is therefore required for multi-tenancy.

The `watchNamespaces` field on `GatewayConfiguration.spec.controlPlaneOptions` controls which namespaces the in-memory KIC for each `Gateway` will watch.

<!-- GAP: The control-plane-watch-namespaces.md page documents the ControlPlane CRD field directly,
     but does not explain that it must be set via GatewayConfiguration.spec.controlPlaneOptions
     when using managed Gateways (i.e., the normal Gateway API flow). Users following that page
     alone would not know how to apply the setting in practice. -->

### watchNamespaces types

<!-- SOURCE: control-plane-watch-namespaces.md, custom-resources.md WatchNamespacesType -->

The `watchNamespaces.type` field accepts three values:

{% table %}
columns:
  - title: Type
    key: type
  - title: Behavior
    key: behavior
  - title: Use when
    key: use
rows:
  - type: "`all`"
    behavior: Watches all namespaces (default)
    use: Single-tenant or dev environments
  - type: "`own`"
    behavior: Watches only the `ControlPlane`'s own namespace
    use: One namespace per tenant (recommended)
  - type: "`list`"
    behavior: Watches own namespace plus a specified list
    use: Routes for this tenant span multiple namespaces
{% endtable %}

When using `list`, the ControlPlane's own namespace is automatically included. Each additional namespace in the list requires a `WatchNamespaceGrant` resource in that namespace (see [WatchNamespaceGrant](#watchnamespacegrant)).

{:.info}
> Setting `watchNamespaces` via `GatewayConfiguration.spec.controlPlaneOptions` configures the `CONTROLLER_WATCH_NAMESPACE` environment variable in the managed KIC. If you set this variable manually through `podTemplateSpec`, it will override the `watchNamespaces` field.

## Operator-level namespace scoping {% new_in 2.0 %}

<!-- SOURCE: control-plane-watch-namespaces.md#multi-tenancy-using-watch-namespaces -->

From v2.0, you can scope {{ site.operator_product_name }} itself to watch only specific namespaces. This is separate from the per-`ControlPlane` `watchNamespaces` configuration and is useful when running multiple {{ site.operator_product_name }} instances on the same cluster with strictly disjoint namespace assignments.

Configure operator-level watch namespaces using the `watch_namespace` Helm value:

```yaml
# values.yaml
env:
  watch_namespace: namespace-a,namespace-b
```

Or via environment variable:

```sh
KONG_OPERATOR_WATCH_NAMESPACES='namespace-a,namespace-b'
```

{:.warning}
> If both operator-level and `ControlPlane`-level watch namespaces are configured, they must not conflict. For example, if {{ site.operator_product_name }} watches namespaces A and B, a `ControlPlane` may only define watch namespaces A or B. Using namespace C would cause the `ControlPlane` to receive a failure status condition and stop reconciling.

## WatchNamespaceGrant

<!-- SOURCE: control-plane-watch-namespaces.md, custom-resources.md WatchNamespaceGrant -->

When `watchNamespaces.type` is `list`, a `WatchNamespaceGrant` resource must be created in each additional namespace (beyond the ControlPlane's own). This resource explicitly grants the named `ControlPlane` permission to watch resources in that namespace.

```yaml
apiVersion: gateway-operator.konghq.com/v1alpha1
kind: WatchNamespaceGrant
metadata:
  name: watch-namespace-grant
  namespace: target-namespace       # the namespace being granted access to
spec:
  from:
  - group: gateway-operator.konghq.com
    kind: ControlPlane
    namespace: control-plane-namespace  # the namespace where the ControlPlane lives
```

For the full field reference, see [WatchNamespaceGrant](/operator/reference/custom-resources/#watchnamespacegrant).

## KongLicense

<!-- SOURCE: Baptiste's docx feedback; confirmed by gist showing license applied once to kong-system -->
<!-- GAP: Not explicitly documented anywhere that one KongLicense in kong-system covers all Gateways. -->

A single `KongLicense` applied in the `kong-system` namespace (where {{ site.operator_product_name }} is installed) is shared by all `Gateway` instances managed by that operator. You do not need to create a license per tenant.

```yaml
apiVersion: configuration.konghq.com/v1alpha1
kind: KongLicense
metadata:
  name: kong-license
  namespace: kong-system
rawLicenseString: '<your license JSON>'
```

## Recommended namespace layout

<!-- SOURCE: Baptiste's gist and docx feedback -->

The recommended pattern for namespace-per-tenant isolation:

{% table %}
columns:
  - title: Namespace
    key: namespace
  - title: Contents
    key: contents
rows:
  - namespace: "`kong-system`"
    contents: "{{ site.operator_product_name }} pod, `KongLicense`"
  - namespace: "`kong-gw-public`"
    contents: "`GatewayConfiguration`, `GatewayClass`, `Gateway`, `DataPlane` pod, `HTTPRoute`s, upstream services for the public gateway"
  - namespace: "`kong-gw-private`"
    contents: Same triptych for the private gateway, in isolation
{% endtable %}

Each namespace is an independent routing domain. The in-memory KIC for `kong-gw-public` only sees routes in `kong-gw-public`; the KIC for `kong-gw-private` only sees routes in `kong-gw-private`.

<!-- GAP: There is no guidance on RBAC / NetworkPolicy to further harden tenant boundaries.
     For example, whether teams should have RBAC limited to their own namespace,
     or whether DataPlane pods need NetworkPolicy rules to prevent cross-namespace traffic. -->
