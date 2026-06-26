---
title: Install {{site.mesh_product_name}} in multi-zone mode and configure meshes with mTLS
description: "Install {{site.mesh_product_name}} in multi-zone mode and configure two isolated meshes with mTLS and traffic permissions."
content_type: how_to
permalink: /how-to/enable-cross-mesh-communication/configure-meshes/
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
  position: 1

related_resources:
  - text: "Cross-mesh communication"
    url: /mesh/mesh-to-mesh/
  - text: "Built-in gateways"
    url: /mesh/built-in-gateway/

tldr:
  q: How do I install {{site.mesh_product_name}} in multi-zone mode and configure meshes with mTLS?
  a: |
    Install a global control plane and two zone control planes with Helm, then apply `Mesh` resources with mTLS backends and `MeshTrafficPermission` policies to the global CP.

prereqs:
  skip_product: true
  inline:
    - title: Helm
      include_content: prereqs/helm
---

This series uses the built-in `MeshGateway` to connect `mesh1` and `mesh2` across two Kubernetes clusters. `MeshGateway` is the native {{site.mesh_product_name}} option: it requires no additional components and preserves mesh-level context across the boundary. If you're running {{site.base_gateway}} ({{site.operator_product_name}}) and want a unified ingress for both North-South and cross-mesh traffic, see [Cross-mesh communication](/mesh/mesh-to-mesh/) for the {{site.base_gateway}} pattern instead.

## Create three Kubernetes clusters

This series requires three Kubernetes clusters: one for the global control plane and one for each zone. 

1. Create a shared Docker network: 

   ```sh
   docker network create kong-mesh --subnet 192.168.200.0/24
   ```

1. Start each minikube profile with a unique static IP on that network so nodes from different clusters can reach each other directly:

   ```sh
   minikube start -p mesh-global --network kong-mesh --static-ip 192.168.200.10
   minikube start -p mesh-c1 --network kong-mesh --static-ip 192.168.200.11
   minikube start -p mesh-c2 --network kong-mesh --static-ip 192.168.200.12
   ```

1. Export the context names and node IPs for use throughout this series:

   ```sh
   export GLOBAL_CONTEXT=mesh-global
   export C1_CONTEXT=mesh-c1
   export C2_CONTEXT=mesh-c2
   export GLOBAL_NODE_IP=192.168.200.10
   export C1_NODE_IP=192.168.200.11
   ```

## Install {{site.mesh_product_name}} in multi-zone mode

1. Add the Helm chart repository:

   ```sh
   helm repo add kong-mesh https://kong.github.io/kong-mesh-charts
   helm repo update
   ```

1. Install the global control plane on `mesh-global`. Skip default mesh creation since we'll create `mesh1` and `mesh2` in this series:

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

1. Get the KDS NodePort from the global control plane:

   ```sh
   export KDS_PORT=$(kubectl get svc kong-mesh-global-zone-sync \
     -n kong-mesh-system --context $GLOBAL_CONTEXT \
     -o jsonpath='{.spec.ports[?(@.port==5685)].nodePort}')
   echo "KDS: $GLOBAL_NODE_IP:$KDS_PORT"
   ```

1. Install the zone control plane on `mesh-c1` and connect it to the global control plane:

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

1. Install the zone control plane on `mesh-c2`:

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

1. Verify both zones have registered. The global control plane creates a zone object automatically when a zone control plane connects via KDS, so their existence confirms the connection is working:

   ```sh
   until kubectl get zone zone-c1 zone-c2 \
     --context $GLOBAL_CONTEXT 2>/dev/null; do
     echo "Waiting for zones to register..."
     sleep 5
   done
   ```

## Configure meshes with mTLS

Apply `Mesh` resources to the global control plane using `kubectl`. Each mesh gets its own Certificate Authority, which isolates its trust domain. It's required for the gateway to bridge security boundaries.

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
