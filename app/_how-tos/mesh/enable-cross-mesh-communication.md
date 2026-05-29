---
title: Enable cross-mesh communication with MeshGateway
permalink: /how-to/enable-cross-mesh-communication/
description: "Set up {{site.mesh_product_name}} across two Kubernetes clusters with multiple meshes and enable secure bidirectional communication between them using MeshGateway."
content_type: how_to
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

related_resources:
  - text: "Cross-mesh communication"
    url: /mesh/mesh-to-mesh/
  - text: "Built-in gateways"
    url: /mesh/built-in-gateway/
  - text: "Configuring built-in routes with MeshHTTPRoute and MeshTCPRoute"
    url: /mesh/gateway-routes/
  - text: "Set up a built-in gateway with {{site.mesh_product_name}}"
    url: /how-to/set-up-a-built-in-mesh-gateway/
  - text: "Federate a zone control plane"
    url: /mesh/federate/

tldr:
  q: How do I connect services in two different meshes?
  a: |
    Deploy a `MeshGateway` in each mesh to expose services, then create a `MeshExternalService` in the calling mesh pointing to the other mesh's gateway using the Cluster 1 node IP and NodePort. Services can then call the `MeshExternalService` DNS name to reach services in the remote mesh.

prereqs:
  skip_product: true
  inline:
    - title: Helm
      include_content: prereqs/helm
    - title: Three Kubernetes clusters
      content: |
        This guide requires three Kubernetes clusters: one for the global control plane and one for each zone. Create a shared Docker network first, then start each minikube profile with a unique static IP on that network so nodes from different clusters can reach each other directly:

        ```sh
        docker network create kong-mesh --subnet 192.168.200.0/24
        minikube start -p mesh-global --network kong-mesh --static-ip 192.168.200.10
        minikube start -p mesh-c1 --network kong-mesh --static-ip 192.168.200.11
        minikube start -p mesh-c2 --network kong-mesh --static-ip 192.168.200.12
        ```

        Export the context names and node IPs for use throughout this guide:

        ```sh
        export GLOBAL_CONTEXT=mesh-global
        export C1_CONTEXT=mesh-c1
        export C2_CONTEXT=mesh-c2
        export GLOBAL_NODE_IP=192.168.200.10
        export C1_NODE_IP=192.168.200.11
        ```
    - title: "Install {{site.mesh_product_name}} in multi-zone mode"
      content: |
        Add the Helm chart repository:

        ```sh
        helm repo add kong-mesh https://kong.github.io/kong-mesh-charts
        helm repo update
        ```

        Install the global control plane on `mesh-global`. We skip default mesh creation because `mesh1` and `mesh2` are created explicitly in this guide:

        ```sh
        helm install \
          --kube-context $GLOBAL_CONTEXT \
          --create-namespace \
          --namespace kong-mesh-system \
          --set kuma.controlPlane.mode=global \
          --set kuma.controlPlane.defaults.skipMeshCreation=true \
          kong-mesh kong-mesh/kong-mesh
        kubectl wait -n kong-mesh-system \
          --for=condition=ready pod \
          --selector=app=kong-mesh-control-plane \
          --timeout=90s \
          --context $GLOBAL_CONTEXT
        ```

        Get the KDS NodePort from the global control plane:

        ```sh
        export KDS_PORT=$(kubectl get svc kong-mesh-global-zone-sync \
          -n kong-mesh-system --context $GLOBAL_CONTEXT \
          -o jsonpath='{.spec.ports[?(@.port==5685)].nodePort}')
        echo "KDS: $GLOBAL_NODE_IP:$KDS_PORT"
        ```

        Install the zone control plane on `mesh-c1` and connect it to the global control plane:

        ```sh
        helm install \
          --kube-context $C1_CONTEXT \
          --create-namespace \
          --namespace kong-mesh-system \
          --set kuma.controlPlane.mode=zone \
          --set kuma.controlPlane.zone=zone-c1 \
          --set kuma.ingress.enabled=true \
          --set kuma.egress.enabled=true \
          --set kuma.controlPlane.kdsGlobalAddress=grpcs://$GLOBAL_NODE_IP:$KDS_PORT \
          --set kuma.controlPlane.tls.kdsZoneClient.skipVerify=true \
          kong-mesh kong-mesh/kong-mesh
        kubectl wait -n kong-mesh-system \
          --for=condition=ready pod \
          --selector=app=kong-mesh-control-plane \
          --timeout=90s \
          --context $C1_CONTEXT
        ```

        Install the zone control plane on `mesh-c2`:

        ```sh
        helm install \
          --kube-context $C2_CONTEXT \
          --create-namespace \
          --namespace kong-mesh-system \
          --set kuma.controlPlane.mode=zone \
          --set kuma.controlPlane.zone=zone-c2 \
          --set kuma.ingress.enabled=true \
          --set kuma.egress.enabled=true \
          --set kuma.controlPlane.kdsGlobalAddress=grpcs://$GLOBAL_NODE_IP:$KDS_PORT \
          --set kuma.controlPlane.tls.kdsZoneClient.skipVerify=true \
          kong-mesh kong-mesh/kong-mesh
        kubectl wait -n kong-mesh-system \
          --for=condition=ready pod \
          --selector=app=kong-mesh-control-plane \
          --timeout=90s \
          --context $C2_CONTEXT
        ```

        Verify both zones have registered. The global control plane creates a Zone object automatically when a zone control plane connects via KDS, so their existence confirms the connection is working:

        ```sh
        until kubectl get zone zone-c1 zone-c2 \
          --context $GLOBAL_CONTEXT 2>/dev/null; do
          echo "Waiting for zones to register..."
          sleep 5
        done
        ```

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

This guide uses the built-in `MeshGateway` to connect `mesh1` and `mesh2` across two Kubernetes clusters. `MeshGateway` is the native {{site.mesh_product_name}} option: it requires no additional components and preserves mesh-level context across the boundary. If you're running {{site.base_gateway}} ({{site.operator_product_name}}) and want a unified ingress for both North-South and cross-mesh traffic, see [Cross-mesh communication](/mesh/mesh-to-mesh/) for the {{site.base_gateway}} pattern instead.

## Configure meshes with mTLS

Apply `Mesh` resources to the global control plane using `kubectl`. Each mesh gets its own Certificate Authority, which isolates its trust domain and is required for the gateway to bridge security boundaries.

1. Apply the `mesh1` configuration:

   ```sh
   echo "apiVersion: kuma.io/v1alpha1
   kind: Mesh
   metadata:
     name: mesh1
   spec:
     meshServices:
       mode: Exclusive
     mtls:
       enabledBackend: ca-1
       backends:
         - name: ca-1
           type: builtin
           dpCert:
             rotation:
               expiration: 1d
           conf:
             caCert:
               RSAbits: 2048
               expiration: 10y" | kubectl apply -f - --context $GLOBAL_CONTEXT
   ```

1. Apply the `mesh2` configuration:

   ```sh
   echo "apiVersion: kuma.io/v1alpha1
   kind: Mesh
   metadata:
     name: mesh2
   spec:
     meshServices:
       mode: Exclusive
     networking:
       outbound:
         passthrough: false
     mtls:
       enabledBackend: ca-1
       backends:
         - name: ca-1
           type: builtin
           dpCert:
             rotation:
               expiration: 1d
           conf:
             caCert:
               RSAbits: 2048
               expiration: 10y" | kubectl apply -f - --context $GLOBAL_CONTEXT
   ```

1. Confirm both meshes are registered on the global control plane:

   ```sh
   kubectl get mesh --context $GLOBAL_CONTEXT
   ```

   You should see `mesh1` and `mesh2` listed.

1. Wait for both meshes to sync to the zone control planes before proceeding:

   ```sh
   until kubectl get mesh mesh1 mesh2 --context $C1_CONTEXT 2>/dev/null; do sleep 3; done
   until kubectl get mesh mesh1 mesh2 --context $C2_CONTEXT 2>/dev/null; do sleep 3; done
   ```

1. Apply a `MeshTrafficPermission` for each mesh on each zone cluster. The default policy is not always propagated automatically, so apply it explicitly:

   ```sh
   for ctx in $C1_CONTEXT $C2_CONTEXT; do
     echo "apiVersion: kuma.io/v1alpha1
   kind: MeshTrafficPermission
   metadata:
     name: allow-all-mesh1
     namespace: kong-mesh-system
     labels:
       kuma.io/mesh: mesh1
       kuma.io/origin: zone
   spec:
     targetRef:
       kind: Mesh
     from:
     - targetRef:
         kind: Mesh
       default:
         action: Allow" | kubectl apply -f - --context $ctx
     echo "apiVersion: kuma.io/v1alpha1
   kind: MeshTrafficPermission
   metadata:
     name: allow-all-mesh2
     namespace: kong-mesh-system
     labels:
       kuma.io/mesh: mesh2
       kuma.io/origin: zone
   spec:
     targetRef:
       kind: Mesh
     from:
     - targetRef:
         kind: Mesh
       default:
         action: Allow" | kubectl apply -f - --context $ctx
   done
   ```

## Configure Cluster 1

The following steps set up namespaces, deploy services, and create both `MeshGateway` resources on Cluster 1. You'll need the gateway IPs from this section when configuring Cluster 2.

{:.info}
> Namespaces and services must be created **after** the `MeshTrafficPermission` steps above. Pods that start before the permission policy is applied will initialise with a deny-all RBAC rule and won't receive updated rules until they are restarted.

### Prepare namespaces

Create and label namespaces to enable sidecar injection and assign each to the correct mesh:

```sh
kubectl create ns c1m1 --context $C1_CONTEXT
kubectl label ns c1m1 kuma.io/sidecar-injection=enabled kuma.io/mesh=mesh1 --context $C1_CONTEXT
```

```sh
kubectl create ns c1m2 --context $C1_CONTEXT
kubectl label ns c1m2 kuma.io/sidecar-injection=enabled kuma.io/mesh=mesh2 --context $C1_CONTEXT
```

### Deploy services

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

### Set up the mesh1 gateway

Deploy a `MeshGateway` in `mesh1` to expose its services to `mesh2`. Apply these directly to the zone cluster — when applied via the global CP, Kong Mesh renames them with a hash suffix and the `MeshGatewayInstance` controller can't find a matching `MeshGateway` by name.

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

### Set up the mesh2 gateway

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

## Configure Cluster 2

With the node IP and both gateway NodePorts exported, switch to Cluster 2 to create namespaces, deploy client workloads, and map both gateways as external services.

### Prepare namespaces

```sh
kubectl create ns c2m1 --context $C2_CONTEXT
kubectl label ns c2m1 kuma.io/sidecar-injection=enabled kuma.io/mesh=mesh1 --context $C2_CONTEXT
```

```sh
kubectl create ns c2m2 --context $C2_CONTEXT
kubectl label ns c2m2 kuma.io/sidecar-injection=enabled kuma.io/mesh=mesh2 --context $C2_CONTEXT
```

### Deploy client workloads

Deploy a client pod in each mesh namespace for use in the validation step.

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

### Map the mesh1 gateway in mesh2

Create a `MeshExternalService` in `mesh2` pointing to the `mesh1` gateway. The `HostnameGenerator` type assigns a stable internal DNS name so workloads don't need to track the address directly.

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

Workloads in `mesh2` can now reach the `echo` service in `mesh1` at `http://echo-mesh-1-http.extsvc.mesh.local:8080/echo`.

### Map the mesh2 gateway in mesh1

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

Workloads in `mesh1` can now reach the `echo` service in `mesh2` at `http://echo-mesh-2-http.extsvc.mesh.local:8080/echo`.

## Validate

1. From the client in `mesh1`, send a request to the `echo` service in `mesh2`:

   ```sh
   kubectl exec -n c2m1 client --context $C2_CONTEXT -- curl -s http://echo-mesh-2-http.extsvc.mesh.local:8080/echo
   ```

   You should receive a response from the `echo` service running in `mesh2` on Cluster 1.

1. From the client in `mesh2`, send a request to the `echo` service in `mesh1`:

   ```sh
   kubectl exec -n c2m2 client --context $C2_CONTEXT -- curl -s http://echo-mesh-1-http.extsvc.mesh.local:8080/echo
   ```

   You should receive a response from the `echo` service running in `mesh1` on Cluster 1.

{:.info}
> If you get a connection error, the `MeshExternalService` hostname may still be propagating. Wait a few seconds and try again.
