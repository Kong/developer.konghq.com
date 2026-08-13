---
title: "KonnectExtension"
description: Automatically register data planes with {{ site.konnect_short_name }} by providing authentication credentials in KonnectExtension
content_type: reference
layout: reference
products:
  - operator
breadcrumbs:
  - /operator/
  - index: operator
    group: Gateway Deployment
  - index: operator
    group: Gateway Deployment
    section: Key Concepts

related_resources:
  - text: "Custom resources reference"
    url: /operator/reference/custom-resources/

faqs:
  - q: Which {{site.konnect_short_name}} control plane types can I reference from a KonnectExtension?
    a: |
      `KonnectExtension` can reference a `KonnectGatewayControlPlane` of cluster type `ControlPlane` (Hybrid mode) or `K8sIngressController` (KIC mode). Both types support attaching `DataPlane`, `ControlPlane`, and `GatewayConfiguration` resources through the extension point.

      Control plane groups (`ControlPlaneGroup` cluster type) are read-only aggregations of member control planes. Member control planes can't have `DataPlane` resources connected directly, so you can't attach a `DataPlane` to a control plane group member through `KonnectExtension`. Attach `DataPlane` resources to a standalone control plane instead, and add that control plane to the group in {{site.konnect_short_name}}. For more information, see [Control plane groups](/gateway/control-plane-groups/).

  - q: Does the control plane's cluster type change how configuration reaches the data plane?
    a: |
      Yes. The cluster type referenced by `KonnectExtension` determines how the `DataPlane` resource gets its configuration:

      - `ControlPlane` (Hybrid mode): {{site.konnect_short_name}} is the control plane. It pushes configuration to the `DataPlane` over a secure WebSocket (WSS) connection. There's no in-memory {{site.kic_product_name_short}} involved.
      - `K8sIngressController` (KIC mode): The in-memory {{site.kic_product_name_short}} instance embedded in {{site.operator_product_name}} is the control plane. It pushes configuration to the `DataPlane` over the Admin API. {{site.konnect_short_name}} only receives the resulting configuration for visibility and management. It never pushes configuration to the `DataPlane` directly in this mode.

      For more information, see [{{site.operator_product_name}} architecture](/operator/reference/architecture/).
---

Kong data plane instances can be configured in {{site.konnect_short_name}} using the [`KonnectExtension`](/operator/reference/custom-resources/#konnectextension) resource. This resource can be used to provision isolated `DataPlane` resources (Hybrid mode) or pairs of `ControlPlane` and `DataPlane` resources ({{ site.kic_product_name }} mode).

The `KonnectExtension` resource can be referenced by `ControlPlane`, `DataPlane`, or `GatewayConfiguration` resources from the extension point in their spec. Dedicated guides will guide you through these kinds of setup.

## {{site.konnect_short_name}} control plane reference

`KonnectExtension` can be attached to {{site.konnect_short_name}} `ControlPlane` resources of type Hybrid or KIC. This reference can be performed via Kubernetes object reference to an in cluster `KonnectGatewayControlPlane`.

### Reference by Kubernetes object

The `KonnectExtension` can reference an object in the cluster. This reference allows to attach the `DataPlane` resources to the {{site.konnect_short_name}} control plane via a local object [(a.k.a. `KonnectGatewayControlPlane`)](/operator/reference/custom-resources/#konnectgatewaycontrolplane). When this type of reference is used, the `KonnectAPIAuthConfiguration` data is inferred by the `KonnectGatewayControlPlane` objects. For this reason, it's not possible to set the `konnect.configuration.authref` field in this scenario.

```yaml
spec:
  konnect:
    controlPlane:
      ref:
        type: konnectNamespacedRef
        konnectNamespacedRef:
          name: gateway-control-plane # The KonnectGatewayControlPlane resource name
```

## Data plane authentication

The `DataPlane`, in order to be configured in {{site.konnect_short_name}}, needs a client certificate. This certificate can be manually created and managed by the user, or automatically provisioned by {{ site.operator_product_name }}.

### Manual certificate provisioning

In order to manually create and set up a certificate to be used for Konnect `DataPlane` resources, you can run the following commands:

{% include k8s/operator_client_certificate.md %}

Once the `Secret` containing your certificate has been created in the cluster, you can set up your `KonnectExtension` as follows:

```yaml
spec:
  clientAuth:
    certificateSecret:
      provisioning: Manual
        secretRef:
          name: konnect-client-tls # The name of the secret containing your certificate
```

### Automatic certificate provisioning

Alternatively, you can leave the certificate provisioning and management to {{ site.operator_product_name }}, which will take care of creating a new certificate, write it into a Kubernetes `Secret` and manage the `Secret`'s lifecycle on behalf of you. To do so, you can configure a `KonnectExtension` as follows:

```yaml
spec:
  clientAuth:
    certificateSecret:
      provisioning: Automatic
```

or you can just leave the `spec.clientAuth` field empty, and the automatic provisioning will be used as the default value.

## Set DataPlane labels

Multiple labels can be configured to the {{site.konnect_short_name}} `DataPlane` via the following field:

```yaml
spec:
  konnect:
    dataPlane:
      foo: bar
      foo2: bar2
```

Please note that the amount of labels that can be set on `DataPlane` resources via `KonnectExtension` is limited to 5.

## Verify that a resource accepted a KonnectExtension

When a `DataPlane`, `ControlPlane`, or `GatewayConfiguration` resource successfully references a `KonnectExtension`, {{ site.operator_product_name }} records the association on the `KonnectExtension` status, not on the referencing resource. Check the `KonnectExtension` status to confirm the reference was accepted:

```bash
kubectl get konnectextensions.konnect.konghq.com -n kong
```

A `KonnectExtension` that's fully reconciled shows `READY: True`:

```text
NAME                 READY
my-konnect-config    True
```

For more detail, inspect the full status block:

```bash
kubectl get konnectextension my-konnect-config -n kong -o yaml | yq '.status'
```

The status includes:

- `conditions`: The current reconciliation conditions for the extension.
- `dataPlaneRefs` and `controlPlaneRefs`: The `DataPlane` and `ControlPlane` resources that currently reference this extension. If the resource you expect to see referenced here is missing, double-check that its `spec.extensions` block correctly names the `KonnectExtension`.
- `dataPlaneClientAuth`: The state of the client certificate used to authenticate the `DataPlane` with {{site.konnect_short_name}}.
- `konnect.controlPlaneID` and `konnect.clusterType`: The ID and cluster type of the {{site.konnect_short_name}} control plane this extension resolved to.

A `GatewayConfiguration` doesn't add its own entry to `dataPlaneRefs` or `controlPlaneRefs`. Those only track `DataPlane` and `ControlPlane` resources directly. To confirm a `GatewayConfiguration` accepted a `KonnectExtension`, check that the `DataPlane` and `ControlPlane` resources it provisions show up under the extension's `dataPlaneRefs` and `controlPlaneRefs`, and that the `GatewayConfiguration`'s `status.conditions` don't report an extension resolution error.

For more information, see [Status fields](/operator/konnect/troubleshooting/status/).

## Troubleshooting: data plane not connecting to Konnect

If a `KonnectExtension` is attached and the `Gateway` or `DataPlane` deployed successfully, but the data plane still isn't showing up as connected in {{site.konnect_short_name}}, check the following:

1. Confirm the extension is actually referenced. The `DataPlane` (or the `Gateway`/`GatewayConfiguration` that provisions it) must list the `KonnectExtension` under `spec.extensions`, matching on `group`, `kind`, and `name`. A typo or namespace mismatch means the reference is silently ignored.
1. Check the `KonnectExtension` status. Run `kubectl get konnectextensions.konnect.konghq.com -n <namespace>` and confirm `READY` is `True`. If it's `False`, inspect `status.conditions` for the failure reason.
1. Verify the referenced control plane exists and is programmed. If you're using a `konnectNamespacedRef`, confirm the referenced `KonnectGatewayControlPlane` shows `PROGRAMMED: True`:
   ```bash
   kubectl get konnectgatewaycontrolplanes.konnect.konghq.com -n <namespace>
   ```
1. Check the client certificate. If you're using manual certificate provisioning, confirm the `Secret` referenced in `spec.clientAuth.certificateSecret.secretRef` exists and contains a valid certificate and key. If you're using automatic provisioning, confirm {{ site.operator_product_name }} was able to create and write the `Secret`. Check `status.dataPlaneClientAuth` on the `KonnectExtension`.
1. Confirm outbound network access. Data planes using the `ControlPlane` (hybrid) cluster type connect to {{site.konnect_short_name}} over an outbound WebSocket (WSS) connection on port 443. If your cluster is behind a proxy or firewall, make sure outbound HTTPS/WSS traffic to your {{site.konnect_short_name}} region's endpoint is allowed.
1. Check the data plane and operator pod logs. Look in the `DataPlane` container logs for TLS handshake or connectivity errors, and in the `kong-operator-controller-manager` logs for reconciliation failures related to the `KonnectExtension` or its control plane reference.
