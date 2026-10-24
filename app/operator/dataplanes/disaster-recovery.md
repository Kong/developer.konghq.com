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

Recover a self-hosted Gateway in a replacement Kubernetes cluster by reinstalling {{site.operator_product_name}} and reapplying its desired resources. The operator creates new data plane workloads and Services from those resources.

This walkthrough assumes the original cluster is unavailable. It does not copy generated Deployments or depend on a gateway retaining its old configuration. For data planes connected to Konnect, use the [Konnect walkthrough](/gateway/disaster-recovery/kubernetes/konnect/).

## Starting deployment

Use the self-hosted deployment from [Provision a Gateway](/operator/get-started/gateway-api/deploy-gateway/) and [Configure a route and service](/operator/get-started/gateway-api/create-route/):

* Operator Helm release `kong-operator` in namespace `kong-system`, using chart `kong/kong-operator`.
* GatewayConfiguration `kong-configuration`, Gateway `kong`, and HTTPRoute `echo` in namespace `kong`.
* GatewayClass `kong`, with controller name `konghq.com/gateway-operator`.
* An HTTP listener on port `80` routing `/echo` to the echo Service.

Use an Operator version with the embedded controller described in the [architecture reference](/operator/reference/architecture/). Keep the same Operator, Gateway, chart, and CRD versions during recovery.

Set `PRIMARY_CONTEXT` and `RECOVERY_CONTEXT` to distinct original and replacement kubeconfig contexts. The replacement cluster must support LoadBalancer Services and reach the required registries.

## Save the recovery files

Create a protected directory outside the cluster:

```bash
mkdir -p recovery/operator
```

Save the effective Operator Helm values:

```bash
helm get values kong-operator -n kong-system --kube-context "$PRIMARY_CONTEXT" \
  --all -o yaml > recovery/operator/values.yaml
```

Read the installed chart version:

```bash
helm list -n kong-system --kube-context "$PRIMARY_CONTEXT"
```

Set `OPERATOR_CHART_VERSION` to the version after `kong-operator-` in the `CHART` column, then save that chart:

```bash
helm pull kong/kong-operator --version "$OPERATOR_CHART_VERSION" \
  --destination recovery/operator
```

The recommended source for these manifests is a Git repository deployed through CD or GitOps; see [Manage configuration as code](/gateway/disaster-recovery/kubernetes/prepare/#manage-configuration-as-code). Record the revision you will restore. If they aren't in a repository, [export them from the running cluster](#export-gateway-resources-without-a-repository).

Copy these desired manifests from the deployment repository into the recovery directory:

| File | Resources |
| --- | --- |
| `gateway-api-crds.yaml` | The Gateway API CRD bundle used by the original installation |
| `gateway-configuration.yaml` | GatewayConfiguration `kong-configuration`, including the pinned Gateway image |
| `gateway-class.yaml` | GatewayClass `kong` and its parameters reference |
| `gateway.yaml` | Gateway `kong` and its listeners |
| `application.yaml` | The echo Deployment and Service |
| `routes.yaml` | HTTPRoute `echo` and any referenced Kong resources |

Use authored manifests without old UIDs, owner references, or `.status`. The generated DataPlane, Deployment, and Service are outputs of reconciliation; the operator will recreate them.

The example uses the chart-managed CA and recreates all workloads that use it. If your Helm values reference an external CA, an issuer, registry credentials, or a license Secret, add those dependencies and their restoration commands to the recovery set. Restore them before installing the chart. An old workload that survives elsewhere will not automatically trust a new CA.

### Export Gateway resources without a repository

Use this fallback only if the manifests aren't in source control. It captures the cluster's current state, including changes that were applied by hand. Save the Gateway API CRD bundle and application manifests from their release or source, and export only the resources you authored, not the generated DataPlane, Deployment, or Service.

Export the namespaced resources into the files the restore uses:

```bash
kubectl --context "$PRIMARY_CONTEXT" -n kong get gatewayconfiguration \
  -o yaml > recovery/operator/gateway-configuration.yaml
kubectl --context "$PRIMARY_CONTEXT" -n kong get gateway \
  -o yaml > recovery/operator/gateway.yaml
kubectl --context "$PRIMARY_CONTEXT" -n kong get httproute \
  -o yaml > recovery/operator/routes.yaml
```

Add any Kong resources that the routes reference to `routes.yaml`. Export the cluster-scoped GatewayClass separately:

```bash
kubectl --context "$PRIMARY_CONTEXT" get gatewayclass kong \
  -o yaml > recovery/operator/gateway-class.yaml
```

Remove the fields that Kubernetes and the operator generate for the original objects, including the operator's cleanup finalizers on the Gateway. With [`yq`](https://github.com/mikefarah/yq) installed, run:

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

Record the original response from `/echo` and the Gateway's address before the drill.

## Reinstall the operator

Confirm the destination:

```bash
kubectl --context "$RECOVERY_CONTEXT" cluster-info
```

Restore the saved Gateway API CRDs before creating any Gateway resources:

```bash
kubectl --context "$RECOVERY_CONTEXT" apply \
  -f recovery/operator/gateway-api-crds.yaml
```

Install the saved Operator chart:

```bash
helm install kong-operator "recovery/operator/kong-operator-${OPERATOR_CHART_VERSION}.tgz" \
  --kube-context "$RECOVERY_CONTEXT" -n kong-system --create-namespace \
  -f recovery/operator/values.yaml --wait --timeout 5m
```

The new installation must provide the Operator CRDs used by the saved resources. If your original installation disabled chart-managed CRD installation or used cert-manager, restore those separately using the same versions before proceeding.

Create the Gateway namespace:

```bash
kubectl --context "$RECOVERY_CONTEXT" create namespace kong
```

## Restore the Gateway and routes

Apply the configuration first:

```bash
kubectl --context "$RECOVERY_CONTEXT" apply \
  -f recovery/operator/gateway-configuration.yaml
```

Restore the class that references it:

```bash
kubectl --context "$RECOVERY_CONTEXT" apply \
  -f recovery/operator/gateway-class.yaml
```

Restore the Gateway:

```bash
kubectl --context "$RECOVERY_CONTEXT" apply \
  -f recovery/operator/gateway.yaml
```

Restore the backend and route:

```bash
kubectl --context "$RECOVERY_CONTEXT" -n kong apply \
  -f recovery/operator/application.yaml -f recovery/operator/routes.yaml
```

Wait for the operator to program the Gateway:

```bash
kubectl --context "$RECOVERY_CONTEXT" -n kong wait \
  --for=condition=Programmed gateway/kong --timeout=300s
```

Expect `condition met`. If this times out, inspect the Gateway's conditions and events before moving traffic:

```bash
kubectl --context "$RECOVERY_CONTEXT" -n kong describe gateway kong
```

Resolve missing parameters, certificate failures, or image pull failures. Applying old generated Deployments does not fix a failed Gateway reconciliation.

## Verify the new workloads serve the saved route

Read the recovered address:

```bash
kubectl --context "$RECOVERY_CONTEXT" -n kong get gateway kong
```

Set `RECOVERY_ADDRESS` to the Gateway's address and test it:

```bash
curl --fail-with-body "http://${RECOVERY_ADDRESS}/echo"
```

Expect HTTP `200` and an echo response identifying a pod in the recovery cluster. A programmed Gateway with a `404` response still needs its route fixed. A `503` requires checking backend readiness and Service endpoints.

In `routes.yaml`, add a second HTTPRoute path match for `/echo-recovered` to the same rule, then apply the file again:

```bash
kubectl --context "$RECOVERY_CONTEXT" -n kong apply \
  -f recovery/operator/routes.yaml
```

Request `http://${RECOVERY_ADDRESS}/echo-recovered` and expect the echo response. This checks that the embedded controller processes new configuration after recovery. Remove the temporary match and reapply the file.

This HTTP example tests workload and routing recovery. For a deployment with TLS or authentication, restore its referenced Secrets and repeat its HTTPS, authorized, and unauthorized baseline requests before accepting traffic.

## Move traffic and fail back

Update the external DNS or load balancer entry for the application to point to the recovered Gateway address. Request `/echo` through that normal hostname and compare it with the direct-address result.

The operator owns its newly generated Services. If the original deployment used a separately managed Service, restore that Service's desired configuration and verify that its selector matches the new data plane pods. Recreating a Gateway does not transfer ownership of that external Service or load balancer.

To fail back, repeat the restore against the rebuilt original environment, validate its new address, and update the client entry point again. Keep the accepted Gateway and route files in the deployment repository so that GitOps preserves the recovered state.

Record the source revision, new Gateway address, traffic recovery time, and successful route update in the [drill record](/gateway/disaster-recovery/kubernetes/test/#record-the-results).
