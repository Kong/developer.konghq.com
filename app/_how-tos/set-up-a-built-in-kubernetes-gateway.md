---
title: Set up a built-in Kubernetes gateway with {{site.mesh_product_name}}
description: This guide walks through setting up a built-in Kubernetes gateway, defining Routes, securing traffic with TLS, and configuring permissions.
    
content_type: how_to
bread-crumbs: 
  - /mesh/
related_resources:
  - text: Set up a built-in gateway with {{site.mesh_product_name}}
    url: '/how-to/set-up-a-built-in-mesh-gateway/'
  - text: Deploy {{site.mesh_product_name}} in production with Helm
    url: /mesh/production-usage-values/
  - text: Deploy {{site.mesh_product_name}} on Kubernetes
    url: /mesh/kubernetes/
  - text: Kubernetes Gateway API
    url: /mesh/kubernetes-gateway-api/

min_version:
  mesh: '2.9'

products:
  - mesh

tldr:
  q: How can I use a built-in Kubernetes gateway to allow traffic from outside my mesh?
  a: |
    Install the Gateway API CRDs, create a `GatewayClass` and a `Gateway` to configure the built-in gateway, then create an `HTTPRoute` and allow traffic to the gateway with a `MeshTrafficPermission`. To secure your endpoint, generate a certificate and add it to the `Gateway`.

prereqs:
  inline:
    - title: Helm
      include_content: prereqs/helm
    - title: A running Kubernetes cluster with LoadBalancer support
      include_content: prereqs/kubernetes/mesh-cluster-lb
    - title: Install {{site.mesh_product_name}} with demo configuration
      include_content: prereqs/kubernetes/mesh-quickstart

---

{% include /how-tos/steps/mesh-built-in-gateway.md section="intro" %}
In this guide we'll use the [Kubernetes Gateway API](/mesh/kubernetes-gateway-api/) to add a [built-in gateway](/mesh/managing-ingress-traffic/gateway/) in front of the demo-app service and expose it publicly.

## Install the Gateway API CRDs

1. Run the following command to install the Kubernetes Gateway API CRDs:

  ```sh
  kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.3.0/standard-install.yaml
  ```

1. Create a `GatewayClass` resource:
   ```sh
   echo "apiVersion: gateway.networking.k8s.io/v1
   kind: GatewayClass
   metadata:
     name: built-in-gateway
   spec:
     controllerName: gateways.kuma.io/controller" | kubectl apply -f -
   ```

1. Restart the {{site.mesh_product_name}} control plane to apply the changes:
   ```sh
   kubectl rollout restart deployment kong-mesh-control-plane -n kong-mesh-system
   kubectl wait -n kong-mesh-system --for=condition=ready pod --selector=app=kong-mesh-control-plane --timeout=90s
   ```


## Configure the gateway

1. Create a `Gateway` resource to configure the pods that will run the gateway:

   ```sh
   echo "apiVersion: gateway.networking.k8s.io/v1
   kind: Gateway
   metadata:
     name: built-in-gateway
     namespace: kong-mesh-demo
   spec:
     gatewayClassName: built-in-gateway
     listeners:
      - name: proxy
        port: 8080
        protocol: HTTP" | kubectl apply -f -
   ```
   
1. Validate that the pods are running:

   ```sh
   kubectl wait -n kong-mesh-demo --for=condition=ready pod --selector=app=built-in-gateway --timeout=90s
   kubectl get pods -n kong-mesh-demo
   ```
   
   You should see the following result:

   ```sh
   NAME                               READY   STATUS    RESTARTS   AGE
   built-in-gateway-c759dffc8-w7nlt   1/1     Running   0          9s
   demo-app-84d96db569-6t8kx          2/2     Running   0          106s
   kv-648747567c-qhmxj                2/2     Running   0          106s
   ```
   {:.no-copy-code}
   
{% include /how-tos/steps/mesh-built-in-gateway.md section="ip" %}

## Create a Route

1. Create a Route with the `MeshHTTPRoute` resource and associate it with the built-in gateway:

   ```sh
   echo "apiVersion: gateway.networking.k8s.io/v1
   kind: HTTPRoute
   metadata:
     name: echo
     namespace: kong-mesh-demo
   spec:
     parentRefs:
       - group: gateway.networking.k8s.io
         kind: Gateway
         name: built-in-gateway
         namespace: kong-mesh-demo
     rules:
       - backendRefs:
         - kind: Service
           name: demo-app
           port: 5050
           weight: 1
         matches:
           - path:
               type: PathPrefix
               value: /" | kubectl apply -f -
   ```

{% include /how-tos/steps/mesh-built-in-gateway.md section="rbac" %}

{% include /how-tos/steps/mesh-built-in-gateway.md section="traffic" %}

## Secure your endpoint

{% include /how-tos/steps/mesh-built-in-gateway.md section="cert" %}

1. Create a Kubernetes secret containing the certificate and key:   
   ```sh
   echo "apiVersion: v1
   kind: Secret
   metadata:
     name: my-gateway-certificate
     namespace: kong-mesh-demo
   type: kubernetes.io/tls
   data:
     tls.crt: "$(cat tls.crt | base64)"
     tls.key: "$(cat tls.key | base64)"" | kubectl apply -f - 
   ```
   
1. Update the gateway to use the certificate:

   ```sh
   echo "apiVersion: gateway.networking.k8s.io/v1
   kind: Gateway
   metadata:
     name: built-in-gateway
     namespace: kong-mesh-demo
   spec:
     gatewayClassName: built-in-gateway
     listeners:
       - name: proxy
         port: 8080
         protocol: HTTPS
         tls:
           certificateRefs:
             - name: my-gateway-certificate
               namespace: kong-mesh-demo" | kubectl apply -f -
   ```

{% include /how-tos/steps/mesh-built-in-gateway.md section="validate" %}
