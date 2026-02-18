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

```sh
kubectl port-forward svc/demo-app -n kong-mesh-demo 5051:5050
```

```sh
kubectl port-forward svc/demo-app -n kong-mesh-demo-migration 5052:5050
```

## Enable MeshTLS in permissive mode

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

## Add the data plane proxy to the mesh

```sh
kubectl label namespace kong-mesh-demo-migration kuma.io/sidecar-injection=enabled --overwrite
kubectl rollout restart deployment kv -n kong-mesh-demo-migration
```

## Check that the proxy is receiving traffic

```sh
kubectl port-forward svc/kong-mesh-control-plane -n kong-mesh-system 5681:5681
```

```sh
export KV_DPP_NAME=$(curl -s http://localhost:5681/meshes/default/dataplanes/_overview\?name\=kv | jq -r '.items[0].name')
curl -s http://localhost:5681/meshes/default/dataplanes/$KV_DPP_NAME/stats | grep cluster.localhost_5050.upstream_rq_2xx
```

## Migrate the demo app client to the mesh

```sh
kubectl rollout restart deployment demo-app -n kong-mesh-demo-migration
```

```sh
kubectl port-forward svc/demo-app -n kong-mesh-demo-migration 5052:5050
```