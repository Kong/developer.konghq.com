---
title: "Recover {{site.konnect_short_name}}-managed data planes on Kubernetes"
description: "Recover customer-managed Kubernetes data planes connected to Konnect, including Operator-managed configuration resources."
content_type: reference
layout: reference
breadcrumbs:
  - /gateway/
  - /gateway/disaster-recovery/kubernetes/
products:
  - gateway
  - konnect
  - operator
works_on:
  - konnect
tags:
  - kubernetes
  - restore
  - failover
related_resources:
  - text: Prepare for disaster recovery
    url: /gateway/disaster-recovery/kubernetes/prepare/
  - text: Test disaster recovery
    url: /gateway/disaster-recovery/kubernetes/test/
  - text: Control plane outage management
    url: /gateway/cp-outage/
  - text: Adopt existing Konnect entities
    url: /operator/konnect/crd/adoption/gateway/
---

Reconnect replacement Kubernetes data planes to the same {{site.konnect_short_name}} control plane after losing their cluster. The control plane and its configuration survive; the data plane pods, Helm release, and Kubernetes Secrets do not.

This walkthrough uses Helm-managed data planes. It also includes a separate recovery step for Gateway entities managed by Operator. An unavailable Konnect control plane and failover to another geo require a different drill; this procedure needs the original control plane to be reachable.

## Starting deployment

Use the [Konnect Kubernetes installation](/gateway/install/kubernetes/konnect/): release `kong`, chart `kong/kong`, namespace `kong`, and client certificate Secret `kong-cluster-cert`.

Before the drill, configure a Route named `dr-check` with path `/dr-check` to an upstream available from the recovery cluster. Record its successful application response and any authentication checks.

Set these variables from your installation:

| Variable | Value |
| --- | --- |
| `PRIMARY_CONTEXT` | Original Kubernetes context |
| `RECOVERY_CONTEXT` | Replacement Kubernetes context |
| `CONTROL_PLANE_ID` | Existing Konnect control plane UUID |
| `KONNECT_API_URL` | Geo API URL, such as `https://us.api.konghq.com` |
| `KONNECT_TOKEN` | Token authorized to read the control plane; entity recovery also requires write access |
| `GATEWAY_CHART_VERSION` | Original `kong/kong` chart version |

The replacement cluster needs access to Konnect, the upstream, container registries, and any plugin dependencies. Use a distinct cluster and client endpoint for a drill.

## Save the deployment and identities

Create a protected directory outside the cluster:

```bash
mkdir -p recovery/konnect
```

Save the effective Helm values:

```bash
helm get values kong -n kong --kube-context "$PRIMARY_CONTEXT" \
  --all -o yaml > recovery/konnect/values-dp.yaml
```

Read the chart version with `helm list -n kong --kube-context "$PRIMARY_CONTEXT"`, then save that chart:

```bash
helm pull kong/kong --version "$GATEWAY_CHART_VERSION" \
  --destination recovery/konnect
```

Save the control plane identity:

```bash
curl --fail-with-body -H "Authorization: Bearer $KONNECT_TOKEN" \
  "$KONNECT_API_URL/v2/control-planes/$CONTROL_PLANE_ID" \
  -o recovery/konnect/control-plane.json
```

Preserve the client certificate and key from your secret store as `recovery/konnect/tls.crt` and `tls.key`. These must be the pair registered with this control plane and mounted by the saved values. Include any separately configured license or plugin secrets.

For Operator-managed entities, also save their authored manifests and remote IDs. For example, read a Service's identity from the original cluster:

```bash
kubectl --context "$PRIMARY_CONTEXT" -n kong get kongservice dr-check \
  -o jsonpath='{.status.konnect.id}'
```

Save this as `SERVICE_ID` in the protected recovery inventory, and record `ROUTE_ID` from the corresponding KongRoute in the same way. Preserve both objects' specifications and their original Kubernetes UID tags. Do not rely on retrieving these from the lost cluster.

Keep the recovery files protected outside the cluster. The existing control plane remains the configuration source during this recovery; do not sync an old configuration export over its current state.

## Reconnect the replacement data plane

Confirm the saved control plane still exists:

```bash
curl --fail-with-body -H "Authorization: Bearer $KONNECT_TOKEN" \
  "$KONNECT_API_URL/v2/control-planes/$CONTROL_PLANE_ID"
```

Expect HTTP `200` and the saved control plane ID. Verify its endpoints against `values-dp.yaml`. A missing control plane is outside this walkthrough.

Confirm that `RECOVERY_CONTEXT` selects the replacement cluster, then create the namespace:

```bash
kubectl --context "$RECOVERY_CONTEXT" create namespace kong
```

Restore the client certificate Secret:

```bash
kubectl --context "$RECOVERY_CONTEXT" -n kong create secret tls kong-cluster-cert \
  --cert=recovery/konnect/tls.crt --key=recovery/konnect/tls.key
```

If this certificate has expired or been revoked, register a replacement with the same control plane using the [certificate setup procedure](/gateway/install/kubernetes/konnect/) before installing the data plane. Recreating a Secret does not register its certificate in Konnect.

Install the saved release:

```bash
helm install kong "recovery/konnect/kong-${GATEWAY_CHART_VERSION}.tgz" \
  --kube-context "$RECOVERY_CONTEXT" -n kong \
  -f recovery/konnect/values-dp.yaml --wait --timeout 5m
```

Verify that the replacement appears as connected under the original control plane in Konnect. Inspect the new pod's proxy logs if it does not connect; check certificate validity, endpoints, network access, and image or plugin compatibility.

Read the proxy address:

```bash
kubectl --context "$RECOVERY_CONTEXT" -n kong get service kong-kong-proxy
```

Set `RECOVERY_ADDRESS` to its external IP or hostname and test the saved Route:

```bash
curl --fail-with-body "http://${RECOVERY_ADDRESS}/dr-check"
```

Expect the application response recorded before the failure. Use the Route's hostname, TLS, and authentication settings if applicable. If traffic works, data plane recovery can finish even while you separately recover the configuration management tool.

## Recover Operator-managed Konnect resources

Use this section only if Operator managed the surviving Service and Route. It assumes Operator 2.1 or later, an existing remote control plane, and saved KongService and KongRoute manifests. It does not adopt every kind of Konnect resource.

Reinstall the same Operator chart and restore its token Secret and KonnectAPIAuthConfiguration using the [Operator installation](/operator/get-started/konnect-crds/install/) and [authentication procedure](/operator/get-started/konnect-crds/authentication/). Keep automated application of the entity manifests paused.

### Reference the existing control plane

In the saved KonnectGatewayControlPlane manifest, use `source: Mirror` with the original ID:

```yaml
spec:
  source: Mirror
  mirror:
    konnect:
      id: <CONTROL_PLANE_ID>
  konnect:
    authRef:
      name: konnect-api-auth
```

Replace `<CONTROL_PLANE_ID>` with the actual UUID and save the complete resource as `recovery/konnect/control-plane.yaml`. Retain its original name and namespace so that the saved Service references still resolve. Apply it:

```bash
kubectl --context "$RECOVERY_CONTEXT" apply \
  -f recovery/konnect/control-plane.yaml
```

Verify that its status reports the original remote ID. Mirroring the control plane does not adopt its Services or Routes.

### Release stale ownership for one entity

{:.warning}
> Before changing ownership tags, ensure the original operator cannot resume reconciliation. Pause its GitOps application and stop or isolate the original controller if it survives. Revoking the Konnect token it uses isolates it; deleting its token Secret does not, because Operator holds that Secret with a finalizer while resources reference it. Two controllers must not manage the same remote entity.

A new Kubernetes object has a new UID. Operator rejects adoption when the remote entity still carries another object's `k8s-uid` tag, even when its configuration matches. The KongService reports `Adopted` as `False` with reason `UIDConflict`, and Operator does not create a duplicate.

Fetch the surviving Service by its recorded ID:

```bash
curl --fail-with-body -H "Authorization: Bearer $KONNECT_TOKEN" \
  "$KONNECT_API_URL/v2/control-planes/$CONTROL_PLANE_ID/core-entities/services/$SERVICE_ID" \
  -o recovery/konnect/service.json
```

Inspect the response and compare its ID, configuration, and tags with the inventory. Set `OLD_SERVICE_UID_TAG` to the exact tag belonging to the lost object, including the `k8s-uid:` prefix. Do not remove a tag belonging to a different or active owner.

The entity endpoint accepts `PUT` but not `PATCH`, and `PUT` replaces the whole entity. With `jq` installed, prepare a copy of the complete saved Service that removes that single tag and retains every other field and tag:

```bash
jq --arg old "$OLD_SERVICE_UID_TAG" \
  'del(.created_at, .updated_at) | .tags |= map(select(. != $old))' \
  recovery/konnect/service.json > recovery/konnect/service-update.json
```

Compare `service-update.json` with `service.json` and confirm that the only difference is the removed tag, then apply the update:

```bash
curl --fail-with-body --request PUT \
  -H "Authorization: Bearer $KONNECT_TOKEN" -H "Content-Type: application/json" \
  --data @recovery/konnect/service-update.json \
  "$KONNECT_API_URL/v2/control-planes/$CONTROL_PLANE_ID/core-entities/services/$SERVICE_ID"
```

Do this only for a verified stale owner. Repeat the same single-entity process for the Route using `routes/$ROUTE_ID`, its own saved response and update file, and its own original UID tag. Do not remove every Kubernetes tag or edit unrelated entities.

### Adopt the Service, then the Route

Add this block to the saved KongService's `spec`, retaining its original configuration and control plane reference:

```yaml
adopt:
  from: konnect
  mode: match
  konnect:
    id: <SERVICE_ID>
```

Replace `<SERVICE_ID>` with the recorded UUID, save the complete resource as `recovery/konnect/service.yaml`, and apply it:

```bash
kubectl --context "$RECOVERY_CONTEXT" apply -f recovery/konnect/service.yaml
```

Check its conditions and remote ID:

```bash
kubectl --context "$RECOVERY_CONTEXT" -n kong get kongservice dr-check -o yaml
```

Expect successful reconciliation and `status.konnect.id` equal to `SERVICE_ID`. If matching fails, compare the saved specification with the surviving Service. Do not switch to overwrite mode merely to make recovery pass.

Add the same adoption block to the saved KongRoute, using `ROUTE_ID` and retaining the Service reference. Apply that file only after the Service has reconciled, then verify the Route's remote ID and conditions. See [entity adoption](/operator/konnect/crd/adoption/gateway/) for resource-specific fields and restrictions.

Retrieve the Service and Route through the API again. Confirm their IDs and relationship are unchanged, their configuration is correct, and subsequent reconciliation does not produce duplicate entities. Adoption in `match` mode doesn't write a `k8s-uid` tag for the new object; Operator adds it the next time it updates the entity. Put the recovery manifests into the managed repository before resuming synchronization.

## Verify configuration updates and move traffic

Choose a temporary path that the Route doesn't already match, such as `/dr-verify`. Route paths are prefixes, so `/dr-check` already matches `/dr-check-recovered`. Request `/dr-verify` through the replacement data plane and expect `404`. Through the tool that now owns the Route, add the temporary path, request it again, and expect the same application response. Then remove the path and confirm that it returns `404`. For Operator, update the adopted KongRoute manifest.

Update the application's DNS record or load balancer target to the replacement proxy address. Repeat the application's baseline requests through the normal client endpoint and record traffic recovery.

For failback, reconnect the rebuilt original data planes to the same control plane and validate them before moving traffic back. Keep a single active owner for each remote entity; do not restart the former operator against stale manifests.

Record the control plane, Service, and Route IDs before and after recovery, the certificate used, and the times at which traffic and configuration updates worked in the [drill record](/gateway/disaster-recovery/kubernetes/test/#record-the-results).
