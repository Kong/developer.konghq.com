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

When you lose the Kubernetes cluster that runs your {{site.konnect_short_name}} data planes, you can reconnect replacement data planes to the same {{site.konnect_short_name}} control plane.
The control plane and its configuration survive.
The data plane pods, the Helm release, and the Kubernetes Secrets don't.

This walkthrough uses Helm-managed data planes.
It also includes a separate recovery step for Gateway entities that {{site.operator_product_name}} manages.
This procedure needs the original control plane to be reachable.
If the {{site.konnect_short_name}} control plane is unavailable, or if you fail over to another geo, you need a different drill.

## Starting deployment

The {{site.konnect_short_name}} recovery example uses the [{{site.konnect_short_name}} Kubernetes installation](/gateway/install/kubernetes/konnect/) with the following values:

* Release: `kong`
* Chart: `kong/kong`
* Namespace: `kong`
* Client certificate Secret: `kong-cluster-cert`

Before the drill, configure a Route named `dr-check` with the path `/dr-check`.
The Route must point to an upstream that the recovery cluster can reach.
Record its successful application response and any authentication checks.

Set these variables from your installation:

{% table %}
columns:
  - title: Variable
    key: variable
  - title: Value
    key: value
rows:
  - variable: "`PRIMARY_CONTEXT`"
    value: Original Kubernetes context
  - variable: "`RECOVERY_CONTEXT`"
    value: Replacement Kubernetes context
  - variable: "`CONTROL_PLANE_ID`"
    value: UUID of the existing {{site.konnect_short_name}} control plane
  - variable: "`KONNECT_API_URL`"
    value: "Geo API URL, such as `https://us.api.konghq.com`"
  - variable: "`KONNECT_TOKEN`"
    value: Token that can read the control plane. Entity recovery also needs write access.
{% endtable %}

The replacement cluster needs access to {{site.konnect_short_name}}, the upstream, the container registries, and any plugin dependencies.
For a drill, use a distinct cluster and client endpoint.

## Save the deployment and identities

{% include k8s/disaster-recovery/save-helm-release.md dir="konnect" release="kong" namespace="kong" chart="kong/kong" values_file="values-dp.yaml" version_var="GATEWAY_CHART_VERSION" %}

Save the identity of the control plane from the [Control Planes API](/api/konnect/control-planes/v2/):

```bash
curl --fail-with-body -H "Authorization: Bearer $KONNECT_TOKEN" \
  "$KONNECT_API_URL/v2/control-planes/$CONTROL_PLANE_ID" \
  -o recovery/konnect/control-plane.json
```

Copy the client certificate and key from your secret store to `recovery/konnect/tls.crt` and `recovery/konnect/tls.key`.
They must be the pair that's registered with this control plane and mounted by the saved values.
Include any license or plugin secrets that you configured separately.

If {{site.operator_product_name}} manages your entities, also save their manifests and remote IDs.
For example, read the remote ID of a KongService from the original cluster:

```bash
kubectl --context "$PRIMARY_CONTEXT" -n kong get kongservice dr-check \
  -o jsonpath='{.status.konnect.id}'
```

Save this value as `SERVICE_ID` in the protected recovery inventory.
Record `ROUTE_ID` from the matching KongRoute in the same way.
Save the specifications of both objects and their original Kubernetes UID tags.
Don't rely on the lost cluster to retrieve them later.

During this recovery, the existing control plane remains the configuration source.
Don't sync an old configuration export over its current state.

## Reconnect the replacement data plane

Make sure that the saved control plane still exists:

```bash
curl --fail-with-body -H "Authorization: Bearer $KONNECT_TOKEN" \
  "$KONNECT_API_URL/v2/control-planes/$CONTROL_PLANE_ID"
```

Expect HTTP `200` and the saved control plane ID.
Compare its endpoints with the endpoints in `values-dp.yaml`.
If the control plane is missing, this walkthrough doesn't apply.

Make sure that `RECOVERY_CONTEXT` selects the replacement cluster, then create the namespace:

```bash
kubectl --context "$RECOVERY_CONTEXT" create namespace kong
```

Restore the client certificate Secret:

```bash
kubectl --context "$RECOVERY_CONTEXT" -n kong create secret tls kong-cluster-cert \
  --cert=recovery/konnect/tls.crt --key=recovery/konnect/tls.key
```

If this certificate is expired or revoked, register a replacement with the same control plane before you install the data plane.
Use the [certificate setup procedure](/gateway/install/kubernetes/konnect/) to do this.
Recreating a Secret doesn't register its certificate in {{site.konnect_short_name}}.

Install the saved release:

```bash
helm install kong "recovery/konnect/kong-${GATEWAY_CHART_VERSION}.tgz" \
  --kube-context "$RECOVERY_CONTEXT" -n kong \
  -f recovery/konnect/values-dp.yaml --wait --timeout 5m
```

In {{site.konnect_short_name}}, make sure that the replacement data plane shows as connected under the original control plane.
If it doesn't connect, inspect the proxy logs of the new pod.
Check the certificate validity, the endpoints, the network access, and the image or plugin compatibility.

Read the proxy address:

```bash
kubectl --context "$RECOVERY_CONTEXT" -n kong get service kong-kong-proxy
```

Set `RECOVERY_ADDRESS` to its external IP or hostname, and send a request to the saved Route:

```bash
curl --fail-with-body "http://${RECOVERY_ADDRESS}/dr-check"
```

Expect the application response that you recorded before the failure.
If the Route uses a hostname, TLS, or authentication, add them to the request.
When traffic works, data plane recovery is complete, even if you're still recovering the configuration management tool.

## Recover Operator-managed Konnect resources

Use this section only if {{site.operator_product_name}} managed the surviving Gateway Service and Route.
This section requires the following:

* {{site.operator_product_name}} 2.1 or later
* An existing remote control plane
* Saved KongService and KongRoute manifests

This procedure doesn't adopt every kind of {{site.konnect_short_name}} resource.

Reinstall the same {{site.operator_product_name}} chart.
Then restore its token Secret and KonnectAPIAuthConfiguration with the [{{site.operator_product_name}} installation](/operator/get-started/konnect-crds/install/) and [authentication procedure](/operator/get-started/konnect-crds/authentication/).
Keep automated application of the entity manifests paused.

### Reference the existing control plane

In the saved KonnectGatewayControlPlane manifest, set `source` to `Mirror` and set the original control plane ID:

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

Replace `<CONTROL_PLANE_ID>` with the UUID of the control plane, and save the complete resource as `recovery/konnect/control-plane.yaml`.
Keep its original name and namespace so that the saved Service references still resolve.

Apply the KonnectGatewayControlPlane manifest:

```bash
kubectl --context "$RECOVERY_CONTEXT" apply \
  -f recovery/konnect/control-plane.yaml
```

Make sure that its status reports the original remote ID.
Mirroring the control plane doesn't adopt its Gateway Services or Routes.

### Release stale ownership for one entity

{:.warning}
> Before you change ownership tags, make sure that the original {{site.operator_product_name}} cannot resume reconciliation. Pause its GitOps application, and stop or isolate the original controller if it survives. To isolate the controller, revoke the {{site.konnect_short_name}} token that it uses. Deleting its token Secret does not isolate it, because {{site.operator_product_name}} adds a finalizer to that Secret while resources reference it. Two controllers must not manage the same remote entity.

A new Kubernetes object has a new UID.
{{site.operator_product_name}} rejects adoption when the remote entity still has the `k8s-uid` tag of another object, even when its configuration matches.
In that case, the KongService reports `Adopted` as `False` with the reason `UIDConflict`, and {{site.operator_product_name}} doesn't create a duplicate.

Fetch the surviving Gateway Service by its recorded ID:

```bash
curl --fail-with-body -H "Authorization: Bearer $KONNECT_TOKEN" \
  "$KONNECT_API_URL/v2/control-planes/$CONTROL_PLANE_ID/core-entities/services/$SERVICE_ID" \
  -o recovery/konnect/service.json
```

Inspect the response, and compare its ID, configuration, and tags with the inventory.
Set `OLD_SERVICE_UID_TAG` to the exact tag of the lost object, including the `k8s-uid:` prefix.
Don't remove a tag that belongs to a different or active owner.

The entity endpoint accepts `PUT` but not `PATCH`, and `PUT` replaces the whole entity.
Use [`jq`](https://jqlang.org/) to create a copy of the complete saved Gateway Service that removes only that tag and keeps every other field and tag:

```bash
jq --arg old "$OLD_SERVICE_UID_TAG" \
  'del(.created_at, .updated_at) | .tags |= map(select(. != $old))' \
  recovery/konnect/service.json > recovery/konnect/service-update.json
```

Compare `service-update.json` with `service.json`, and make sure that the only difference is the removed tag.

Send the updated Gateway Service to {{site.konnect_short_name}}:

```bash
curl --fail-with-body --request PUT \
  -H "Authorization: Bearer $KONNECT_TOKEN" -H "Content-Type: application/json" \
  --data @recovery/konnect/service-update.json \
  "$KONNECT_API_URL/v2/control-planes/$CONTROL_PLANE_ID/core-entities/services/$SERVICE_ID"
```

Do this only for a verified stale owner.
Repeat the same process for the Route with `routes/$ROUTE_ID`, its own saved response and update file, and its own original UID tag.
Don't remove every Kubernetes tag, and don't edit unrelated entities.

### Adopt the Gateway Service, then the Route

Add the following adoption block to the `spec` of the saved KongService.
Keep its original configuration and control plane reference.

```yaml
adopt:
  from: konnect
  mode: match
  konnect:
    id: <SERVICE_ID>
```

Replace `<SERVICE_ID>` with the recorded UUID, and save the complete resource as `recovery/konnect/service.yaml`.

Apply the KongService manifest:

```bash
kubectl --context "$RECOVERY_CONTEXT" apply -f recovery/konnect/service.yaml
```

Check the conditions and remote ID of the KongService:

```bash
kubectl --context "$RECOVERY_CONTEXT" -n kong get kongservice dr-check -o yaml
```

Expect successful reconciliation, and a `status.konnect.id` value equal to `SERVICE_ID`.
If matching fails, compare the saved specification with the surviving Gateway Service.
Don't switch to overwrite mode only to make the recovery pass.

Add the same adoption block to the saved KongRoute with `ROUTE_ID`, and keep its Service reference.
Apply that file only after the KongService reconciles, then make sure that the Route has the correct remote ID and conditions.
For resource-specific fields and restrictions, see [entity adoption](/operator/konnect/crd/adoption/gateway/).

Retrieve the Gateway Service and Route through the API again.
Make sure that their IDs and relationship didn't change, that their configuration is correct, and that the next reconciliation doesn't create duplicate entities.
In `match` mode, adoption doesn't write a `k8s-uid` tag for the new object.
{{site.operator_product_name}} adds the tag the next time it updates the entity.
Put the recovery manifests in the managed repository before you resume synchronization.

## Verify configuration updates and move traffic

{% include k8s/disaster-recovery/verify-config-update.md owner="with the tool that now owns the Route" %}

If {{site.operator_product_name}} owns the Route, add and remove the path in the adopted KongRoute manifest.

Update the DNS record or load balancer target of the application to the address of the replacement proxy.
Repeat the baseline requests of the application through the normal client endpoint, and record when traffic recovered.

For failback, reconnect the rebuilt original data planes to the same control plane, and validate them before you move traffic back.
Keep a single active owner for each remote entity.
Don't restart the former {{site.operator_product_name}} with stale manifests.

In the [drill record](/gateway/disaster-recovery/kubernetes/test/#record-the-results), record the following:

* The control plane, Gateway Service, and Route IDs before and after recovery
* The certificate that you used
* The times when traffic and configuration updates worked
