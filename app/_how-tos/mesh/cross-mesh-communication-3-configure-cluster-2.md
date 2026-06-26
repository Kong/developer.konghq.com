---
title: Map cross-mesh gateways as external services on cluster 2
description: "Deploy client workloads on cluster 2 and map the cluster 1 gateways as external services to enable cross-mesh communication."
content_type: how_to
permalink: /how-to/enable-cross-mesh-communication/configure-cluster-2/
breadcrumbs:
  - /mesh/

products:
  - mesh

works_on:
  - on-prem

tags:
  - zones

min_version:
  mesh: '2.9'

series:
  id: cross-mesh-communication
  position: 3

related_resources:
  - text: "Cross-mesh communication"
    url: /mesh/mesh-to-mesh/
  - text: "MeshExternalService"
    url: /mesh/meshexternalservice/
  - text: "Configuring built-in routes with MeshHTTPRoute and MeshTCPRoute"
    url: /mesh/gateway-routes/
  - text: "Set up a built-in gateway with {{site.mesh_product_name}}"
    url: /how-to/set-up-a-built-in-mesh-gateway/

tldr:
  q: How do I connect Cluster 2 workloads to services in cluster 1's meshes?
  a: |
    Create mesh-labeled namespaces, deploy client workloads, then apply `MeshExternalService` resources pointing to each gateway's node IP and NodePort. Workloads can then reach remote services via the generated `extsvc.mesh.local` DNS name.

cleanup:
  inline:
    - title: Delete the minikube clusters and Docker network
      content: |
        ```sh
        minikube delete -p mesh-global
        minikube delete -p mesh-c1
        minikube delete -p mesh-c2
        docker network rm kong-mesh
        ```
---

With the node IP and both gateway NodePorts exported from the previous guide, switch to cluster 2 to create namespaces, deploy client workloads, and map both gateways as external services.

## Prepare namespaces

Create and label cluster 2 namespaces to enable sidecar injection and assign each to the correct mesh:

```sh
kubectl create ns c2m1 --context $C2_CONTEXT
kubectl label ns c2m1 kuma.io/sidecar-injection=enabled kuma.io/mesh=mesh1 --context $C2_CONTEXT
kubectl create ns c2m2 --context $C2_CONTEXT
kubectl label ns c2m2 kuma.io/sidecar-injection=enabled kuma.io/mesh=mesh2 --context $C2_CONTEXT
```

## Deploy client workloads

Deploy a client Pod in each mesh namespace for use in the validation step.

1. Deploy a client in `mesh1`:

   ```sh
   echo "apiVersion: v1
   kind: Pod
   metadata:
     name: client
     namespace: c2m1
   spec:
     containers:
     - name: client
       image: curlimages/curl:latest
       command: ['sleep', '3600']" | kubectl apply -f - --context $C2_CONTEXT
   ```

1. Deploy a client in `mesh2`:

   ```sh
   echo "apiVersion: v1
   kind: Pod
   metadata:
     name: client
     namespace: c2m2
   spec:
     containers:
     - name: client
       image: curlimages/curl:latest
       command: ['sleep', '3600']" | kubectl apply -f - --context $C2_CONTEXT
   ```

1. Wait for the clients to be ready:

   ```sh
   kubectl wait -n c2m1 --for=condition=ready pod/client --timeout=90s --context $C2_CONTEXT
   kubectl wait -n c2m2 --for=condition=ready pod/client --timeout=90s --context $C2_CONTEXT
   ```

## Map the mesh1 gateway in mesh2

Create a `MeshExternalService` in `mesh2` pointing to the `mesh1` gateway. The `HostnameGenerator` type assigns a stable internal DNS name so workloads don't need to track the address directly:

```sh
echo "apiVersion: kuma.io/v1alpha1
kind: MeshExternalService
metadata:
  name: echo-mesh-1-http
  namespace: kong-mesh-system
  labels:
    kuma.io/mesh: mesh2
    kuma.io/origin: zone
spec:
  match:
    type: HostnameGenerator
    port: 8080
    protocol: tcp
  endpoints:
  - address: $C1_NODE_IP
    port: $MESH1_GW_PORT" | kubectl apply -f - --context $C2_CONTEXT
```

Workloads in `mesh2` can now reach the `echo` service in `mesh1` at `http://echo-mesh-1-http.extsvc.mesh.local:8080/`.

## Map the mesh2 gateway in mesh1

Create a `MeshExternalService` in `mesh1` pointing to the `mesh2` gateway:

```sh
echo "apiVersion: kuma.io/v1alpha1
kind: MeshExternalService
metadata:
  name: echo-mesh-2-http
  namespace: kong-mesh-system
  labels:
    kuma.io/mesh: mesh1
    kuma.io/origin: zone
spec:
  match:
    type: HostnameGenerator
    port: 8080
    protocol: tcp
  endpoints:
  - address: $C1_NODE_IP
    port: $MESH2_GW_PORT" | kubectl apply -f - --context $C2_CONTEXT
```

Workloads in `mesh1` can now reach the `echo` service in `mesh2` at `http://echo-mesh-2-http.extsvc.mesh.local:8080/`.

## Validate

1. From the client in `mesh1`, send a request to the `echo` service in `mesh2`:

   ```sh
   kubectl exec -n c2m1 client --context $C2_CONTEXT -- curl -s http://echo-mesh-2-http.extsvc.mesh.local:8080/
   ```

   You should see a response identifying the echo pod in `c1m2`:

   ```sh
   Welcome, you are connected to node mesh-c1.
   Running on Pod echo-<hash>.
   In namespace c1m2.
   With IP address 10.244.x.x.
   ```
   {:.no-copy-code}

1. From the client in `mesh2`, send a request to the `echo` service in `mesh1`:

   ```sh
   kubectl exec -n c2m2 client --context $C2_CONTEXT -- curl -s http://echo-mesh-1-http.extsvc.mesh.local:8080/
   ```

   You should see a response identifying the echo pod in `c1m1`:

   ```sh
   Welcome, you are connected to node mesh-c1.
   Running on Pod echo-<hash>.
   In namespace c1m1.
   With IP address 10.244.x.x.
   ```
   {:.no-copy-code}
