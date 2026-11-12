---
title: "Recover {{site.konnect_short_name}}-managed data planes on Kubernetes"
description: "Learn what to save to reconnect Kubernetes data planes to a surviving Konnect control plane after a cluster loss, and how to recover {{site.operator_product_name}} ownership of Konnect entities."
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

When you lose the Kubernetes cluster that runs your {{site.konnect_short_name}} data planes, the {{site.konnect_short_name}} control plane and its configuration survive.
The data plane pods, the Helm release, and the Kubernetes Secrets don't.
To recover traffic, you install replacement data planes that connect to the same control plane.
If {{site.operator_product_name}} managed your Gateway entities, you also give the new {{site.operator_product_name}} installation ownership of the surviving entities.

This recovery needs the original control plane to be reachable.
If the {{site.konnect_short_name}} control plane is unavailable, or if you fail over to another geo, you need a different procedure.

{:.success}
> To run the procedures end to end in a local cluster, see:
> * [Reconnect {{site.konnect_short_name}} data planes after a Kubernetes cluster loss](/how-to/reconnect-konnect-data-planes-after-cluster-loss/)
> * [Recover {{site.operator_product_name}} ownership of {{site.konnect_short_name}} entities after a cluster loss](/operator/konnect/how-to/recover-entity-ownership-after-cluster-loss/)

## What to save

Save the following items while the original deployment works:

{% table %}
columns:
  - title: Item
    key: item
  - title: Why you need it
    key: why
rows:
  - item: Helm values from `helm get values --all`, and the chart archive from `helm pull`
    why: Lets you install the same data plane version with the same control plane endpoints.
  - item: Client certificate and key
    why: The replacement data plane must present the pair that's registered with the control plane, and that the saved values mount.
  - item: Control plane ID and geo
    why: Identifies the control plane to reconnect to, and the API URL to call.
  - item: License and plugin Secrets
    why: Any license or plugin Secrets that you configured separately from the control plane.
  - item: "{{site.operator_product_name}} manifests and IDs"
    why: "If {{site.operator_product_name}} manages your entities, save the KongService and KongRoute manifests, the {{site.konnect_short_name}} ID of each entity, and the UID of each Kubernetes object. You can't read them from the lost cluster."
{% endtable %}

You don't need to save the Gateway configuration.
During this recovery, the existing control plane remains the configuration source.
Don't sync an old configuration export over its current state.

## Reconnect data planes

A replacement data plane that uses the saved values and certificate connects to the same control plane, and receives its current configuration.

If the client certificate is expired or revoked, register a replacement certificate with the same control plane before you install the data plane.
For the registration steps, see [Install {{site.base_gateway}} in {{site.konnect_short_name}} with Helm](/gateway/install/kubernetes/konnect/).
Recreating a Secret doesn't register its certificate in {{site.konnect_short_name}}.

If the replacement data plane doesn't connect, inspect the proxy logs of the new pod.
Check the certificate validity, the control plane endpoints in the values, the network access to {{site.konnect_short_name}}, and the image or plugin compatibility.

After traffic works through the replacement data plane, data plane recovery is complete, even if you're still recovering the configuration management tool.

## Recover operator ownership of {{site.konnect_short_name}} entities

{{site.operator_product_name}} tags each {{site.konnect_short_name}} entity that it manages with a `k8s-uid` tag that contains the UID of the Kubernetes object that owns it.
When you lose the cluster, the entities and their tags stay in {{site.konnect_short_name}}.
A new Kubernetes object has a new UID, so {{site.operator_product_name}} rejects adoption while the old tag is on the entity, even when the configuration matches.
In that case, the KongService reports `Adopted` as `False` with the reason `UIDConflict`, and {{site.operator_product_name}} doesn't create a duplicate.

To recover ownership, the new installation:

1. Mirrors the existing control plane with a KonnectGatewayControlPlane that uses `source: Mirror` and the original ID.
   Mirroring the control plane doesn't adopt its Gateway Services or Routes.
1. Removes the stale `k8s-uid` tag from each entity.
1. Adopts each entity in `match` mode: the Gateway Service first, then the Routes that reference it.

{:.warning}
> Before you change ownership tags, make sure that the original {{site.operator_product_name}} cannot resume reconciliation. Pause its GitOps application, and stop or isolate the original controller if it survives. To isolate the controller, revoke the {{site.konnect_short_name}} token that it uses. Deleting its token Secret does not isolate it, because {{site.operator_product_name}} adds a finalizer to that Secret while resources reference it. Two controllers must not manage the same remote entity.

When you remove the stale tags, follow these rules:

* Remove only the tag of the lost object. Don't remove a tag that belongs to a different or active owner, and don't remove every Kubernetes tag.
* The entity endpoints accept `PUT` but not `PATCH`, and `PUT` replaces the whole entity. Send the complete entity back, and compare it with the original before you send it.
* Don't edit unrelated entities.

When you adopt the entities, follow these rules:

* Keep the original name and namespace of the KonnectGatewayControlPlane, so that the saved KongService references still resolve.
* If matching fails, compare the saved specification with the surviving entity. Don't switch to `override` mode only to make the recovery pass.
* Adoption in `match` mode doesn't write a `k8s-uid` tag for the new object. {{site.operator_product_name}} adds the tag the next time it updates the entity.
* Keep automated application of the entity manifests paused until adoption is complete, then put the recovery manifests in the managed repository before you resume synchronization.

This procedure doesn't adopt every kind of {{site.konnect_short_name}} resource.
For resource-specific fields and restrictions, see [Adopt existing entities from {{site.konnect_short_name}}](/operator/konnect/crd/adoption/gateway/).

## Move traffic and fail back

Update the DNS record or load balancer target of the application to the address of the replacement proxy.
Then repeat the baseline requests through the normal client endpoint, and record when traffic recovered.

For failback, reconnect the rebuilt original data planes to the same control plane, and validate them before you move traffic back.
Keep a single active owner for each remote entity.
Don't restart the former {{site.operator_product_name}} with stale manifests.
