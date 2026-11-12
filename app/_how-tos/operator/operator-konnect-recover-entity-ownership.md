---
title: Recover {{site.operator_product_name}} ownership of {{site.konnect_short_name}} entities after a cluster loss
short_title: Recover entity ownership after a cluster loss
description: "Reconnect a new {{site.operator_product_name}} installation to Konnect Gateway Services and Routes that {{site.operator_product_name}} managed in a lost Kubernetes cluster, without creating duplicates."
content_type: how_to

permalink: /operator/konnect/how-to/recover-entity-ownership-after-cluster-loss/
breadcrumbs:
  - /operator/
  - index: operator
    group: Konnect

products:
  - operator

works_on:
  - konnect

min_version:
  operator: '2.1'

entities: []

tags:
  - kubernetes
  - konnect-crd
  - restore
  - failover

tldr:
  q: How do I take back ownership of {{site.konnect_short_name}} entities after I lose the cluster that managed them with {{site.operator_product_name}}?
  a: |
    Before the failure, record the control plane, Service, and Route IDs and the UIDs of the Kubernetes objects that managed them.
    In the replacement cluster, mirror the control plane by ID, remove the stale `k8s-uid` tag from each entity, then adopt the entities in `match` mode.

prereqs:
  inline:
    - title: Create a k3d cluster
      position: before
      icon_url: /assets/icons/kubernetes.svg
      include_content: prereqs/kubernetes/k3d-dr-cluster
    - title: Create a Gateway Service and Route
      icon_url: /assets/icons/kubernetes.svg
      include_content: prereqs/operator/dr-konnect-entities
  operator:
    konnect:
      auth: true
      control_plane: true

related_resources:
  - text: Recover {{site.konnect_short_name}}-managed data planes on Kubernetes
    url: /gateway/disaster-recovery/kubernetes/konnect/
  - text: Adopt existing entities from {{site.konnect_short_name}}
    url: /operator/konnect/crd/adoption/gateway/
  - text: Reconnect {{site.konnect_short_name}} data planes after a Kubernetes cluster loss
    url: /how-to/reconnect-konnect-data-planes-after-cluster-loss/

cleanup:
  inline:
    - title: Delete the {{site.konnect_short_name}} entities and control plane
      icon_url: /assets/icons/gateway.svg
      content: |
        ```bash
        kubectl delete kongroute dr-check -n kong
        kubectl delete kongservice dr-check -n kong
        curl -X DELETE "https://us.api.konghq.com/v2/control-planes/$CONTROL_PLANE_ID" \
          -H "Authorization: Bearer $KONNECT_TOKEN"
        ```
    - title: Delete the k3d cluster and the recovery files
      icon_url: /assets/icons/kubernetes.svg
      content: |
        ```bash
        k3d cluster delete kong-dr
        rm -rf recovery
        ```

automated_tests: false
---

When {{site.operator_product_name}} manages {{site.konnect_short_name}} entities, it tags each entity with the UID of the Kubernetes object that owns it.
If you lose the cluster, the entities stay in {{site.konnect_short_name}}, but their owners are gone.
A new Kubernetes object has a new UID, so {{site.operator_product_name}} rejects adoption while the old `k8s-uid` tag is on the entity.

In this guide, you'll take the Gateway Service and Route that you created with {{site.operator_product_name}} in the prerequisites, delete the cluster, and adopt the same entities from a new cluster.
For the ownership rules and the risks of this procedure, see [Recover {{site.konnect_short_name}}-managed data planes on Kubernetes](/gateway/disaster-recovery/kubernetes/konnect/#recover-operator-ownership-of-konnect-entities).

## Save the recovery set

{% include k8s/disaster-recovery/save-helm-release.md release="kong-operator" namespace="kong-system" chart="kong/kong-operator" values_file="operator-values.yaml" version_var="OPERATOR_CHART_VERSION" %}

1. Record the {{site.konnect_short_name}} IDs of the control plane and entities, and the UIDs of the Kubernetes objects that own them.
   You need the UIDs to find the stale ownership tags after the cluster is gone:

   ```bash
   cat <<EOF > recovery/ids.env
   CONTROL_PLANE_ID=$(kubectl get konnectgatewaycontrolplane gateway-control-plane -n kong -o jsonpath='{.status.id}')
   SERVICE_ID=$(kubectl get kongservice dr-check -n kong -o jsonpath='{.status.konnect.id}')
   ROUTE_ID=$(kubectl get kongroute dr-check -n kong -o jsonpath='{.status.konnect.id}')
   OLD_SERVICE_UID=$(kubectl get kongservice dr-check -n kong -o jsonpath='{.metadata.uid}')
   OLD_ROUTE_UID=$(kubectl get kongroute dr-check -n kong -o jsonpath='{.metadata.uid}')
   EOF
   ```

## Simulate the cluster loss

Delete the cluster:

```bash
k3d cluster delete kong-dr
```

{{site.operator_product_name}} doesn't get a chance to clean up, so the control plane, Service, and Route stay in {{site.konnect_short_name}} with their old ownership tags.

## Create the replacement cluster

Create a new, empty cluster with the same name:

{% include k8s/disaster-recovery/k3d-cluster.md %}

## Reinstall {{site.operator_product_name}}

1. Install the saved chart with the saved values:

   ```bash
   helm install kong-operator "recovery/kong-operator-${OPERATOR_CHART_VERSION}.tgz" \
     -n kong-system --create-namespace \
     -f recovery/operator-values.yaml --wait --timeout 5m
   ```

1. Recreate the KonnectAPIAuthConfiguration that {{site.operator_product_name}} uses to call {{site.konnect_short_name}}:

   {% capture auth_config %}
   <!-- vale off -->
   {% konnect_crd %}
   create_namespace: kong
   kind: KonnectAPIAuthConfiguration
   metadata:
     name: konnect-api-auth
   spec:
     type: token
     token: '$KONNECT_TOKEN'
     serverURL: us.api.konghq.com
   {% endkonnect_crd %}
   <!-- vale on -->
   {% endcapture %}
   {{ auth_config | indent }}

1. Load the recorded IDs into your shell:

   ```bash
   source recovery/ids.env
   ```

## Mirror the existing control plane

1. Create a KonnectGatewayControlPlane that mirrors the existing control plane by ID.
   Keep the original name and namespace, so that the saved KongService still references it:

   ```bash
   cat <<EOF > recovery/control-plane.yaml
   kind: KonnectGatewayControlPlane
   apiVersion: konnect.konghq.com/{{ site.operator_konnectgatewaycontrolplane_api_version }}
   metadata:
     name: gateway-control-plane
     namespace: kong
   spec:
     source: Mirror
     mirror:
       konnect:
         id: $CONTROL_PLANE_ID
     konnect:
       authRef:
         name: konnect-api-auth
   EOF
   ```

1. Apply the KonnectGatewayControlPlane:

   ```bash
   kubectl apply -f recovery/control-plane.yaml
   ```

1. Wait for {{site.operator_product_name}} to resolve the control plane:

   ```bash
   kubectl wait --for=condition=Programmed konnectgatewaycontrolplane/gateway-control-plane \
     -n kong --timeout=120s
   ```

## Release the stale ownership tags

Remove the old `k8s-uid` tag from the Service and the Route, so that the new objects can adopt them.
The entity endpoints accept `PUT` but not `PATCH`, and `PUT` replaces the whole entity.
So you fetch each entity, remove only the stale tag, and send the complete entity back.

1. Fetch the Service:

   ```bash
   curl --fail-with-body -H "Authorization: Bearer $KONNECT_TOKEN" \
     "https://us.api.konghq.com/v2/control-planes/$CONTROL_PLANE_ID/core-entities/services/$SERVICE_ID" \
     -o recovery/service.json
   ```

1. Remove the stale tag with [`jq`](https://jqlang.org/), and keep every other field and tag:

   ```bash
   jq --arg old "k8s-uid:$OLD_SERVICE_UID" \
     'del(.created_at, .updated_at) | .tags |= map(select(. != $old))' \
     recovery/service.json > recovery/service-update.json
   ```

1. Send the updated Service:

   ```bash
   curl --fail-with-body --request PUT \
     -H "Authorization: Bearer $KONNECT_TOKEN" -H "Content-Type: application/json" \
     --data @recovery/service-update.json \
     "https://us.api.konghq.com/v2/control-planes/$CONTROL_PLANE_ID/core-entities/services/$SERVICE_ID"
   ```

1. Fetch the Route:

   ```bash
   curl --fail-with-body -H "Authorization: Bearer $KONNECT_TOKEN" \
     "https://us.api.konghq.com/v2/control-planes/$CONTROL_PLANE_ID/core-entities/routes/$ROUTE_ID" \
     -o recovery/route.json
   ```

1. Remove the stale tag from the Route:

   ```bash
   jq --arg old "k8s-uid:$OLD_ROUTE_UID" \
     'del(.created_at, .updated_at) | .tags |= map(select(. != $old))' \
     recovery/route.json > recovery/route-update.json
   ```

1. Send the updated Route:

   ```bash
   curl --fail-with-body --request PUT \
     -H "Authorization: Bearer $KONNECT_TOKEN" -H "Content-Type: application/json" \
     --data @recovery/route-update.json \
     "https://us.api.konghq.com/v2/control-planes/$CONTROL_PLANE_ID/core-entities/routes/$ROUTE_ID"
   ```

## Adopt the Gateway Service and Route

In `match` mode, {{site.operator_product_name}} takes ownership of an entity without changing it, as long as the manifest matches the entity.

1. Add an `adopt` block in `match` mode to the saved KongService:

   ```bash
   cat <<EOF > recovery/service.yaml
   kind: KongService
   apiVersion: configuration.konghq.com/v1alpha1
   metadata:
     name: dr-check
     namespace: kong
   spec:
     controlPlaneRef:
       type: konnectNamespacedRef
       konnectNamespacedRef:
         name: gateway-control-plane
     adopt:
       from: konnect
       mode: match
       konnect:
         id: $SERVICE_ID
     name: dr-check
     protocol: http
     host: httpbin.konghq.com
   EOF
   ```

1. Apply the KongService:

   ```bash
   kubectl apply -f recovery/service.yaml
   ```

1. Wait for the KongService to reconcile:

   ```bash
   kubectl wait --for=condition=Programmed kongservice/dr-check -n kong --timeout=120s
   ```

1. Add the same block to the saved KongRoute, with the Route ID:

   ```bash
   cat <<EOF > recovery/route.yaml
   kind: KongRoute
   apiVersion: configuration.konghq.com/v1alpha1
   metadata:
     name: dr-check
     namespace: kong
   spec:
     serviceRef:
       type: namespacedRef
       namespacedRef:
         name: dr-check
     adopt:
       from: konnect
       mode: match
       konnect:
         id: $ROUTE_ID
     name: dr-check
     paths:
       - /dr-check
     protocols:
       - http
   EOF
   ```

1. Apply the KongRoute.
   Apply it only after the KongService reconciled, because the Route references the Service:

   ```bash
   kubectl apply -f recovery/route.yaml
   ```

1. Wait for the KongRoute to reconcile:

   ```bash
   kubectl wait --for=condition=Programmed kongroute/dr-check -n kong --timeout=120s
   ```

## Validate

1. Make sure that the KongService manages the original Service:

   ```bash
   kubectl get kongservice dr-check -n kong -o jsonpath='{.status.konnect.id}'
   ```

   You'll see the same ID as `$SERVICE_ID`.

1. Make sure that the KongRoute manages the original Route:

   ```bash
   kubectl get kongroute dr-check -n kong -o jsonpath='{.status.konnect.id}'
   ```

   You'll see the same ID as `$ROUTE_ID`.

1. List the Services in the control plane to make sure that adoption didn't create a duplicate:

   {% capture list_services %}
   <!--vale off-->
   {% konnect_api_request %}
   url: /v2/control-planes/$CONTROL_PLANE_ID/core-entities/services
   status_code: 200
   method: GET
   {% endkonnect_api_request %}
   <!--vale on-->
   {% endcapture %}
   {{ list_services | indent }}

   You'll see one Service named `dr-check`.
