---
title: Migrate {{site.mesh_product_name}} Services to mTLS
description: Progressively roll in mutual TLS with the MeshTLS policy in {{site.mesh_product_name}} without disrupting traffic.
    
content_type: how_to
permalink: /how-to/migrate-services-to-mtls/

bread-crumbs: 
  - /mesh/

related_resources:
  - text: MeshTLS policy
    url: /mesh/policies/meshtls/
  - text: Resource sizing guidelines
    url: /mesh/resource-sizing-guidelines/
  - text: Version compatibility
    url: /mesh/version-compatibility/

min_version:
  mesh: '2.9'

products:
  - mesh

tldr:
  q: TODO
  a: |
    TODO

prereqs:
  inline:
    - title: Helm
      include_content: prereqs/helm
    - title: A running Kubernetes cluster
      include_content: prereqs/kubernetes/mesh-cluster
    - title: Install {{site.mesh_product_name}} with demo configuration
      include_content: prereqs/kubernetes/mesh-quickstart
    - title: Deploy a second demo Service
      include_content: prereqs/mesh-migration-service
   
---

## Allow traffic on the mesh

Run the following command to add a `MeshTrafficPermission` policy that allows all traffic from inside the mesh:

```sh
echo "apiVersion: kuma.io/v1alpha1
kind: MeshTrafficPermission
metadata:
  namespace: kong-mesh-system
  name: mtp
spec:
  targetRef:
    kind: Mesh
  from:
    - targetRef:
        kind: Mesh
      default:
        action: Allow" | kubectl apply -f -
```

## Port-forward the two Services

In order to interact with the two `demo-app` Services we created in the prerequisites, we need to enable port-forwarding.

1. Run the following command to port-forward the [first Service](#install-kong-mesh-with-demo-configuration):
   ```sh
   kubectl port-forward svc/demo-app -n kong-mesh-demo 5051:5050
   ```

1. Go to <http://localhost:5051/> to access the demo app's UI and select the **Auto-increment** checkbox to automatically send requests to the Service.

1. In a new terminal window, run the following command to port-forward the [second Service](#deploy-a-second-demo-service):
   ```sh
   kubectl port-forward svc/demo-app -n kong-mesh-demo-migration 5052:5050
   ```

1. Go to <http://localhost:5052/> and select the **Auto-increment** checkbox.


## Enable MeshTLS in permissive mode

Run the following command to enable the [`MeshTLS`](/mesh/policies/meshtls/) policy in permissive mode for the `kv` app in the `kong-mesh-demo-migration` namespace:

```sh
echo "apiVersion: kuma.io/v1alpha1
kind: MeshTLS
metadata:
  name: kv
  namespace: kong-mesh-demo-migration
  labels:
    kuma.io/mesh: default
spec:
  targetRef:
    kind: Dataplane
    labels:
      app: kv
  rules:
  - default:
      mode: Permissive" | kubectl apply -f -
```

## Add the second Service to the mesh

1. Run the following command to enable sidecar injection and add the `kv` Service from the `kong-mesh-demo-migration` namespace to the mesh:

   ```sh
   kubectl label namespace kong-mesh-demo-migration kuma.io/sidecar-injection=enabled --overwrite
   ```

1. Restart the `kv` Service to apply the changes:

   ```sh
   kubectl rollout restart deployment kv -n kong-mesh-demo-migration
   ```

## Check that the Service is receiving traffic

1. Enable port-forwarding for the control plane:

   ```sh
   kubectl port-forward svc/kong-mesh-control-plane -n kong-mesh-system 5681:5681
   ```

1. Export the name of the data plane proxy for the `kv` Service:
   ```sh
   export KV_DPP_NAME=$(curl -s http://localhost:5681/meshes/default/dataplanes/_overview\?name\=kv | jq -r '.items[0].name')
   ```

1. Run the following command to get the request metrics for the `kv` Service:

   ```sh
   for i in {1..5}; do
    curl -s http://localhost:5681/meshes/default/dataplanes/$KV_DPP_NAME/stats | grep cluster.localhost_5050.upstream_rq_2xx
    sleep 10
   done
   ```

   You should see something similar to this:

   ```
   ```

## Migrate the demo app client to the mesh


```sh
kubectl rollout restart deployment demo-app -n kong-mesh-demo-migration
```

```sh
kubectl port-forward svc/demo-app -n kong-mesh-demo-migration 5052:5050
```

```sh
curl -s http://localhost:5681/meshes/default/dataplanes/$KV_DPP_NAME/stats | grep http.localhost_5050.rbac.allowed
```

## Remove MeshTLS in permissive mode

```sh
kubectl delete meshtlses -n kong-mesh-demo-migration kv
```