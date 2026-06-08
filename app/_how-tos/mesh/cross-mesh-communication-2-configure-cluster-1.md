---
title: Set up cross-mesh gateways on cluster 1
description: "Deploy services and set up MeshGateway resources on Cluster 1 to expose mesh1 and mesh2 services for cross-mesh communication."
content_type: how_to
permalink: /how-to/enable-cross-mesh-communication/configure-cluster-1/
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
  position: 2

tldr:
  q: How do I configure Cluster 1 as a cross-mesh gateway host?
  a: |
    Create mesh-labeled namespaces, deploy the echo service, then apply `MeshGateway`, `MeshTCPRoute`, and `MeshGatewayInstance` resources directly to the zone cluster for each mesh.
---

The following steps set up namespaces, deploy services, and create `MeshGateway` resources on Cluster 1. You'll need the gateway NodePorts exported at the end of this page when configuring Cluster 2.

{:.info}
> Namespaces and services must be created **after** the `MeshTrafficPermission` steps in the previous guide. Pods that start before the permission policy is applied will initialise with a deny-all RBAC rule and won't receive updated rules until they are restarted.

## Prepare namespaces

Create and label namespaces to enable sidecar injection and assign each to the correct mesh:

```sh
kubectl create ns c1m1 --context $C1_CONTEXT
kubectl label ns c1m1 kuma.io/sidecar-injection=enabled kuma.io/mesh=mesh1 --context $C1_CONTEXT
```

```sh
kubectl create ns c1m2 --context $C1_CONTEXT
kubectl label ns c1m2 kuma.io/sidecar-injection=enabled kuma.io/mesh=mesh2 --context $C1_CONTEXT
```

## Deploy services

Deploy the `echo` service in both mesh namespaces so each gateway has a backend to route to:

```sh
kubectl apply -f https://developer.konghq.com/manifests/kic/echo-service.yaml -n c1m1 --context $C1_CONTEXT
kubectl apply -f https://developer.konghq.com/manifests/kic/echo-service.yaml -n c1m2 --context $C1_CONTEXT
kubectl wait -n c1m1 --for=condition=ready pod --selector=app=echo --timeout=90s --context $C1_CONTEXT
kubectl wait -n c1m2 --for=condition=ready pod --selector=app=echo --timeout=90s --context $C1_CONTEXT
```

The echo service's port 1027 is named `http`, which causes {{site.mesh_product_name}} to generate HTTP-specific Envoy cluster config. Set `appProtocol: tcp` to override this so a plain TCP cluster is generated instead:

```sh
kubectl patch svc echo -n c1m1 --context $C1_CONTEXT \
  --type json \
  -p '[{"op":"add","path":"/spec/ports/2/appProtocol","value":"tcp"}]'
kubectl patch svc echo -n c1m2 --context $C1_CONTEXT \
  --type json \
  -p '[{"op":"add","path":"/spec/ports/2/appProtocol","value":"tcp"}]'
```

## Set up the mesh1 gateway

Deploy a `MeshGateway` in `mesh1` to expose its services to `mesh2`. Apply these directly to the zone cluster — when applied via the global CP, {{site.mesh_product_name}} renames them with a hash suffix and the `MeshGatewayInstance` controller can't find a matching `MeshGateway` by name.

1. Create the `MeshGateway` on the zone cluster to configure the listener on port 8080:

   ```sh
   echo "apiVersion: kuma.io/v1alpha1
   kind: MeshGateway
   mesh: mesh1
   metadata:
     name: cross-mesh-gateway
     namespace: kong-mesh-system
     labels:
       kuma.io/origin: zone
   spec:
     selectors:
       - match:
           kuma.io/service: cross-mesh-gateway_c1m1_svc
     conf:
       listeners:
         - port: 8080
           protocol: TCP" | kubectl apply -f - --context $C1_CONTEXT
   ```

1. Create a TCP route on the zone cluster that forwards all traffic to the `echo` service:

   ```sh
   echo "apiVersion: kuma.io/v1alpha1
   kind: MeshTCPRoute
   metadata:
     name: gw-to-mesh1-echo
     namespace: kong-mesh-system
     labels:
       kuma.io/mesh: mesh1
       kuma.io/origin: zone
   spec:
     targetRef:
       kind: MeshGateway
       name: cross-mesh-gateway
     to:
     - targetRef:
         kind: Mesh
       rules:
       - default:
           backendRefs:
           - kind: MeshService
             name: echo
             namespace: c1m1
             port: 1027
             weight: 1" | kubectl apply -f - --context $C1_CONTEXT
   ```

1. Create the `MeshGatewayInstance` to deploy the gateway pods in the `c1m1` namespace:

   ```sh
   echo "apiVersion: kuma.io/v1alpha1
   kind: MeshGatewayInstance
   metadata:
     name: cross-mesh-gateway
     namespace: c1m1
     labels:
       kuma.io/mesh: mesh1
   spec:
     replicas: 1
     serviceType: LoadBalancer" | kubectl apply -f - --context $C1_CONTEXT
   ```

   {:.info}
   > `serviceType: LoadBalancer` is used here because `NodePort` triggers a Kong Mesh bug where the controller tries to set `nodePort: 8080`, which Kubernetes rejects. A `LoadBalancer` service still gets a NodePort assigned in the valid range, which is what the next step exports.

1. Wait for the service and pod to be ready:

   ```sh
   until kubectl get svc cross-mesh-gateway -n c1m1 --context $C1_CONTEXT 2>/dev/null; do
     sleep 3
   done
   kubectl wait -n c1m1 --for=condition=ready pod \
     --selector=app=cross-mesh-gateway \
     --timeout=120s \
     --context $C1_CONTEXT
   ```

1. Export the mesh1 gateway NodePort:

   ```sh
   export MESH1_GW_PORT=$(kubectl get svc cross-mesh-gateway -n c1m1 --context $C1_CONTEXT \
     -o jsonpath='{.spec.ports[?(@.port==8080)].nodePort}')
   echo "$C1_NODE_IP:$MESH1_GW_PORT"
   ```

## Set up the mesh2 gateway

Deploy a `MeshGateway` in `mesh2` to expose its services to `mesh1`.

1. Create the `MeshGateway` on the zone cluster:

   ```sh
   echo "apiVersion: kuma.io/v1alpha1
   kind: MeshGateway
   mesh: mesh2
   metadata:
     name: mesh2-gateway
     namespace: kong-mesh-system
     labels:
       kuma.io/origin: zone
   spec:
     selectors:
       - match:
           kuma.io/service: mesh2-gateway_c1m2_svc
     conf:
       listeners:
         - port: 8080
           protocol: TCP" | kubectl apply -f - --context $C1_CONTEXT
   ```

1. Create a TCP route on the zone cluster that forwards all traffic to the `echo` service in `mesh2`:

   ```sh
   echo "apiVersion: kuma.io/v1alpha1
   kind: MeshTCPRoute
   metadata:
     name: gw-to-mesh2-echo
     namespace: kong-mesh-system
     labels:
       kuma.io/mesh: mesh2
       kuma.io/origin: zone
   spec:
     targetRef:
       kind: MeshGateway
       name: mesh2-gateway
     to:
     - targetRef:
         kind: Mesh
       rules:
       - default:
           backendRefs:
           - kind: MeshService
             name: echo
             namespace: c1m2
             port: 1027
             weight: 1" | kubectl apply -f - --context $C1_CONTEXT
   ```

1. Create the `MeshGatewayInstance` for `mesh2` in the `c1m2` namespace:

   ```sh
   echo "apiVersion: kuma.io/v1alpha1
   kind: MeshGatewayInstance
   metadata:
     name: mesh2-gateway
     namespace: c1m2
     labels:
       kuma.io/mesh: mesh2
   spec:
     replicas: 1
     serviceType: LoadBalancer" | kubectl apply -f - --context $C1_CONTEXT
   ```

   {:.info}
   > See the note above about why `LoadBalancer` is used instead of `NodePort`.

1. Wait for the service and pod to be ready:

   ```sh
   until kubectl get svc mesh2-gateway -n c1m2 --context $C1_CONTEXT 2>/dev/null; do
     sleep 3
   done
   kubectl wait -n c1m2 --for=condition=ready pod \
     --selector=app=mesh2-gateway \
     --timeout=120s \
     --context $C1_CONTEXT
   ```

1. Export the mesh2 gateway NodePort:

   ```sh
   export MESH2_GW_PORT=$(kubectl get svc mesh2-gateway -n c1m2 --context $C1_CONTEXT \
     -o jsonpath='{.spec.ports[?(@.port==8080)].nodePort}')
   echo "$C1_NODE_IP:$MESH2_GW_PORT"
   ```
