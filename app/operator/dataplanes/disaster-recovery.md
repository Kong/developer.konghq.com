---
title: "Recover a Gateway deployment managed by {{site.operator_product_name}}"
description: "Recover Kong Operator and its self-hosted Gateway deployments after an operator outage or Kubernetes cluster loss."
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
  - text: Kubernetes disaster recovery guides
    url: /gateway/disaster-recovery/kubernetes/
  - text: Prepare for disaster recovery
    url: /gateway/disaster-recovery/kubernetes/prepare/
  - text: Test disaster recovery
    url: /gateway/disaster-recovery/kubernetes/test/
  - text: Kong Operator architecture
    url: /operator/reference/architecture/
  - text: Version compatibility
    url: /operator/reference/version-compatibility/
---

You can recover a self-hosted Gateway in a replacement Kubernetes cluster when you reinstall {{site.operator_product_name}} and reapply its desired resources.
{{site.operator_product_name}} creates new data plane workloads and Services from those resources.

This walkthrough assumes that the original cluster is unavailable.
It doesn't copy generated Deployments, and it doesn't depend on a gateway that keeps its old configuration.
For data planes connected to {{site.konnect_short_name}}, use the [{{site.konnect_short_name}} walkthrough](/gateway/disaster-recovery/kubernetes/konnect/).

## Starting deployment

The {{site.operator_product_name}} recovery example uses the self-hosted deployment from [Provision a Gateway](/operator/get-started/gateway-api/deploy-gateway/) and [Configure a route and service](/operator/get-started/gateway-api/create-route/):

* The {{site.operator_product_name}} Helm release `kong-operator` in the `kong-system` namespace, with the `kong/kong-operator` chart.
* The GatewayConfiguration `kong-configuration`, the Gateway `kong`, and the HTTPRoute `echo` in the `kong` namespace.
* The GatewayClass `kong`, with the controller name `konghq.com/gateway-operator`.
* An HTTP listener on port `80` that routes `/echo` to the echo Service.

Use an {{site.operator_product_name}} version with the embedded controller that the [architecture reference](/operator/reference/architecture/) describes.
Keep the same {{site.operator_product_name}}, {{site.base_gateway}}, chart, and CRD versions during recovery.

Set `PRIMARY_CONTEXT` and `RECOVERY_CONTEXT` to the kubeconfig contexts of the original and replacement clusters.
The replacement cluster must support LoadBalancer Services and have access to the required registries.

## Save the recovery files

{% include k8s/disaster-recovery/save-helm-release.md dir="operator" release="kong-operator" namespace="kong-system" chart="kong/kong-operator" values_file="values.yaml" version_var="OPERATOR_CHART_VERSION" %}

Record the revision of your [deployment repository](/gateway/disaster-recovery/kubernetes/prepare/#manage-configuration-as-code) that you will restore.
If the manifests aren't in a repository, [export them from the running cluster](#export-gateway-resources-without-a-repository).

Copy these desired manifests from the deployment repository into the recovery directory:

{% table %}
columns:
  - title: File
    key: file
  - title: Resources
    key: resources
rows:
  - file: "`gateway-api-crds.yaml`"
    resources: The Gateway API CRD bundle that the original installation uses
  - file: "`gateway-configuration.yaml`"
    resources: "GatewayConfiguration `kong-configuration`, including the pinned {{site.base_gateway}} image"
  - file: "`gateway-class.yaml`"
    resources: GatewayClass `kong` and its parameters reference
  - file: "`gateway.yaml`"
    resources: Gateway `kong` and its listeners
  - file: "`application.yaml`"
    resources: The echo Deployment and Service
  - file: "`routes.yaml`"
    resources: HTTPRoute `echo` and any Kong resources that it references
{% endtable %}

Use the manifests that you wrote, without old UIDs, owner references, or `.status`.
The generated `DataPlane`, Deployment, and Service are outputs of reconciliation, and {{site.operator_product_name}} recreates them.

The example uses the chart-managed CA, and recreates all workloads that use it.
Your Helm values can reference an external CA, an issuer, registry credentials, or a license Secret.
If they do, add those dependencies and their restore commands to the recovery set, and restore them before you install the chart.
An old workload that survives elsewhere doesn't automatically trust a new CA.

### Export Gateway resources without a repository

Use this fallback only if the manifests aren't in source control.
The export captures the current state of the cluster, including changes that someone applied manually.
Save the Gateway API CRD bundle and the application manifests from their release or source.
Export only the resources that you wrote, not the generated `DataPlane`, Deployment, or Service.

Export the namespaced resources into the files that the restore uses:

```bash
kubectl --context "$PRIMARY_CONTEXT" -n kong get gatewayconfiguration \
  -o yaml > recovery/operator/gateway-configuration.yaml
kubectl --context "$PRIMARY_CONTEXT" -n kong get gateway \
  -o yaml > recovery/operator/gateway.yaml
kubectl --context "$PRIMARY_CONTEXT" -n kong get httproute \
  -o yaml > recovery/operator/routes.yaml
```

Add any Kong resources that the routes reference to `routes.yaml`.

Export the cluster-scoped GatewayClass separately:

```bash
kubectl --context "$PRIMARY_CONTEXT" get gatewayclass kong \
  -o yaml > recovery/operator/gateway-class.yaml
```

Use [`yq`](https://github.com/mikefarah/yq) to remove the fields that Kubernetes and {{site.operator_product_name}} generated for the original objects, including the cleanup finalizers on the Gateway:

```bash
STRIP='del(.status) | del(.metadata.uid, .metadata.resourceVersion,
  .metadata.creationTimestamp, .metadata.generation, .metadata.managedFields,
  .metadata.finalizers, .metadata.ownerReferences,
  .metadata.annotations."kubectl.kubernetes.io/last-applied-configuration")'
for f in gateway-configuration gateway routes; do
  yq -i ".items[] |= ($STRIP)" "recovery/operator/$f.yaml"
done
yq -i "$STRIP" recovery/operator/gateway-class.yaml
```

Review the files, then commit them to a repository so that the next recovery starts from source control.

### Record the baseline

Before the drill, record the original response from `/echo` and the address of the Gateway.

## Reinstall the operator

Make sure that the replacement context points to the intended cluster:

```bash
kubectl --context "$RECOVERY_CONTEXT" cluster-info
```

Restore the saved Gateway API CRDs before you create any Gateway resources:

```bash
kubectl --context "$RECOVERY_CONTEXT" apply \
  -f recovery/operator/gateway-api-crds.yaml
```

Install the saved {{site.operator_product_name}} chart:

```bash
helm install kong-operator "recovery/operator/kong-operator-${OPERATOR_CHART_VERSION}.tgz" \
  --kube-context "$RECOVERY_CONTEXT" -n kong-system --create-namespace \
  -f recovery/operator/values.yaml --wait --timeout 5m
```

The new installation must provide the {{site.operator_product_name}} CRDs that the saved resources use.
If your original installation turned off chart-managed CRD installation or used cert-manager, restore those separately with the same versions before you continue.

Create the Gateway namespace:

```bash
kubectl --context "$RECOVERY_CONTEXT" create namespace kong
```

## Restore the Gateway and routes

Apply the GatewayConfiguration first:

```bash
kubectl --context "$RECOVERY_CONTEXT" apply \
  -f recovery/operator/gateway-configuration.yaml
```

Restore the GatewayClass that references the GatewayConfiguration:

```bash
kubectl --context "$RECOVERY_CONTEXT" apply \
  -f recovery/operator/gateway-class.yaml
```

Restore the Gateway:

```bash
kubectl --context "$RECOVERY_CONTEXT" apply \
  -f recovery/operator/gateway.yaml
```

Restore the backend and the route:

```bash
kubectl --context "$RECOVERY_CONTEXT" -n kong apply \
  -f recovery/operator/application.yaml -f recovery/operator/routes.yaml
```

Wait for {{site.operator_product_name}} to program the Gateway:

```bash
kubectl --context "$RECOVERY_CONTEXT" -n kong wait \
  --for=condition=Programmed gateway/kong --timeout=300s
```

Expect `condition met`.
If the command times out, inspect the conditions and events of the Gateway before you move traffic:

```bash
kubectl --context "$RECOVERY_CONTEXT" -n kong describe gateway kong
```

Fix any missing parameters, certificate failures, or image pull failures.
Applying old generated Deployments doesn't fix a failed Gateway reconciliation.

## Verify the new workloads serve the saved route

Read the recovered address:

```bash
kubectl --context "$RECOVERY_CONTEXT" -n kong get gateway kong
```

Set `RECOVERY_ADDRESS` to the address of the Gateway, and send a request to it:

```bash
curl --fail-with-body "http://${RECOVERY_ADDRESS}/echo"
```

Expect HTTP `200` and an echo response that identifies a pod in the recovery cluster.
If the request fails, check the response:

* `404`: The Gateway is programmed, but the route needs a fix.
* `503`: Check the backend readiness and the Service endpoints.

To check that the embedded controller processes new configuration after recovery, do the following:

1. In `routes.yaml`, add a second HTTPRoute path match for `/echo-recovered` to the same rule.
1. Apply the file again:

   ```bash
   kubectl --context "$RECOVERY_CONTEXT" -n kong apply \
     -f recovery/operator/routes.yaml
   ```

1. Send a request to `http://${RECOVERY_ADDRESS}/echo-recovered`, and expect the echo response.
1. Remove the temporary match, and apply the file again.

This HTTP example tests workload and routing recovery.
If your deployment uses TLS or authentication, restore the Secrets that it references.
Then repeat its HTTPS, authorized, and unauthorized baseline requests before you accept traffic.

## Move traffic and fail back

Update the external DNS or load balancer entry of the application to point to the recovered Gateway address.
Send a request to `/echo` through that normal hostname, and compare the result with the direct-address result.

{{site.operator_product_name}} owns the Services that it generates.
If the original deployment used a separately managed Service, restore the desired configuration of that Service.
Make sure that its selector matches the new data plane pods.
Recreating a Gateway doesn't transfer ownership of that external Service or load balancer.

To fail back, repeat the restore against the rebuilt original environment, validate its new address, and update the client entry point again.
Keep the accepted Gateway and route files in the deployment repository, so that GitOps keeps the recovered state.

In the [drill record](/gateway/disaster-recovery/kubernetes/test/#record-the-results), record the following:

* The source revision
* The new Gateway address
* The traffic recovery time
* The result of the route update
