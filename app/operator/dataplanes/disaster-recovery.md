---
title: "Disaster recovery for Gateways managed by {{site.operator_product_name}}"
description: "Learn what to save to recover self-hosted Gateways managed by {{site.operator_product_name}} after a Kubernetes cluster loss, the order to restore them in, and how to adapt the recovery to your deployment."
content_type: reference
layout: reference
breadcrumbs:
  - /operator/
  - index: operator
    group: Gateway Deployment
products:
  - operator
  - gateway
works_on:
  - on-prem
tags:
  - kubernetes
  - backup
  - restore
  - failover
related_resources:
  - text: "Recover a Gateway managed by {{site.operator_product_name}} after a cluster loss"
    url: /operator/dataplanes/how-to/recover-from-cluster-loss/
  - text: Kubernetes disaster recovery guides
    url: /gateway/disaster-recovery/kubernetes/
  - text: Prepare for disaster recovery
    url: /gateway/disaster-recovery/kubernetes/prepare/
  - text: Test disaster recovery
    url: /gateway/disaster-recovery/kubernetes/test/
  - text: "{{site.operator_product_name}} architecture"
    url: /operator/reference/architecture/
  - text: Version compatibility
    url: /operator/reference/version-compatibility/
---

{{site.operator_product_name}} creates the data plane workloads and Services of a self-hosted Gateway from the Gateway API resources that you write.
To recover a Gateway after a cluster loss, you reinstall {{site.operator_product_name}} and reapply those resources, and {{site.operator_product_name}} creates new workloads from them.
You don't copy the generated Deployments, and you don't depend on a data plane that kept its old configuration.

For data planes connected to {{site.konnect_short_name}}, see [Recover {{site.konnect_short_name}}-managed data planes on Kubernetes](/gateway/disaster-recovery/kubernetes/konnect/).

{:.success}
> To run the full procedure end to end in a local cluster, see [Recover a Gateway managed by {{site.operator_product_name}} after a cluster loss](/operator/dataplanes/how-to/recover-from-cluster-loss/).

## What to save

Save the following items while the original deployment works.
We recommend that you keep the manifests in a Git repository that you deploy through CD or GitOps, because recovery is then a normal deployment of a known revision.
For more information, see [Manage configuration as code](/gateway/disaster-recovery/kubernetes/prepare/#manage-configuration-as-code).

{% table %}
columns:
  - title: Item
    key: item
  - title: Why you need it
    key: why
rows:
  - item: Helm values from `helm get values --all`, and the chart archive from `helm pull`
    why: Lets you install the same {{site.operator_product_name}} version with the same settings. Keep the same {{site.operator_product_name}}, {{site.base_gateway}}, chart, and CRD versions during recovery.
  - item: GatewayConfiguration
    why: Holds the data plane settings, including the pinned {{site.base_gateway}} image.
  - item: GatewayClass and Gateway
    why: The GatewayClass references the GatewayConfiguration, and the Gateway defines the listeners.
  - item: HTTPRoutes and Kong resources
    why: HTTPRoutes and the Kong resources that they reference, such as KongPlugins.
  - item: Application manifests
    why: The Deployments and Services that the HTTPRoutes send traffic to.
  - item: License and other Secrets
    why: "The KongLicense, and any external CA, issuer, registry credentials, or TLS Secrets that the Helm values or the resources reference."
{% endtable %}

Save the manifests that you wrote, without old UIDs, owner references, or `.status`.
Don't save the `DataPlane`, Deployments, and Services that {{site.operator_product_name}} generates.
They're outputs of reconciliation, and {{site.operator_product_name}} recreates them.

## Restore order

In the replacement cluster, restore the Gateway in the following order:

1. Restore the Secrets and the dependencies that the Helm values reference, such as an external CA, an issuer, or registry credentials.
1. Install the saved {{site.operator_product_name}} chart with the saved values.
   The chart installs the {{site.operator_product_name}} CRDs and the Gateway API CRDs.
   If your original installation turned off chart-managed CRD installation or used cert-manager, restore those separately with the same versions first.
1. Restore the license.
1. Apply the GatewayConfiguration, then the GatewayClass that references it, then the Gateway.
1. Apply the application and the routes.
1. Wait for the Gateway to report the `Programmed` condition.

## Export Gateway resources without a repository

Use this fallback only if the manifests aren't in source control.
The export captures the current state of the cluster, including changes that someone applied manually.
Save the application manifests from their release or source.
Export only the resources that you wrote, not the generated `DataPlane`, Deployment, or Service.

Run the export against the original cluster.
Export the namespaced resources:

```bash
kubectl -n kong get gatewayconfiguration -o yaml > recovery/gateway-configuration.yaml
kubectl -n kong get gateway -o yaml > recovery/gateway.yaml
kubectl -n kong get httproute -o yaml > recovery/routes.yaml
```

Add any Kong resources that the routes reference to `routes.yaml`.

Export the cluster-scoped GatewayClass separately:

```bash
kubectl get gatewayclass kong -o yaml > recovery/gateway-class.yaml
```

Use [`yq`](https://github.com/mikefarah/yq) to remove the fields that Kubernetes and {{site.operator_product_name}} generated for the original objects, including the cleanup finalizers on the Gateway:

```bash
STRIP='del(.status) | del(.metadata.uid, .metadata.resourceVersion,
  .metadata.creationTimestamp, .metadata.generation, .metadata.managedFields,
  .metadata.finalizers, .metadata.ownerReferences,
  .metadata.annotations."kubectl.kubernetes.io/last-applied-configuration")'
for f in gateway-configuration gateway routes; do
  yq -i ".items[] |= ($STRIP)" "recovery/$f.yaml"
done
yq -i "$STRIP" recovery/gateway-class.yaml
```

Review the files, then commit them to a repository so that the next recovery starts from source control.

## Troubleshoot the recovered Gateway

If the Gateway doesn't report `Programmed`, inspect its conditions and events:

```bash
kubectl -n kong describe gateway kong
```

Fix any missing parameters, certificate failures, or image pull failures.
Applying old generated Deployments doesn't fix a failed Gateway reconciliation.

If a request through the recovered Gateway fails, check the response:

* `404`: The Gateway is programmed, but the request doesn't match the HTTPRoute. Check the HTTPRoute rules and its parent reference.
* `503`: The data plane can't reach the backend. Check the backend readiness and the Service endpoints.

If your deployment uses TLS or authentication, repeat the HTTPS, authorized, and unauthorized requests that you recorded before the failure.

## Separately managed Services and CAs

{{site.operator_product_name}} owns the Services that it generates.
If the original deployment used a separately managed Service, restore the desired configuration of that Service, and make sure that its selector matches the new data plane pods.
Recreating a Gateway doesn't transfer ownership of that external Service or load balancer.

When the chart manages the CA, the replacement installation creates a new CA and recreates all workloads that use it.
An old workload that survives elsewhere doesn't automatically trust the new CA.

## Move traffic and fail back

The recovered Gateway gets a new address.
Update the external DNS or load balancer entry of the application to point to it.
Then send a request through the normal hostname, and compare the result with a request to the address directly.

To fail back, repeat the restore against the rebuilt original environment, validate its new address, and update the client entry point again.
Keep the accepted Gateway and HTTPRoute files in the deployment repository, so that GitOps keeps the recovered state.
