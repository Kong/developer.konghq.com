---
title: Set up a built-in {{site.mesh_product_name}} gateway
description: This guide walks through setting up MeshGatewayInstance and MeshGateway resources, defining routes with MeshHTTPRoute, configuring permissions, and securing the gateway with TLS.
    
content_type: how_to
permalink: /mesh/add-builtin-gateway/
bread-crumbs: 
  - /mesh/
related_resources:
  - text: Use Kong as a delegated Gateway
    url: '/mesh/gateway-delegated/'
  - text: Deploy {{site.mesh_product_name}} on Kubernetes
    url: /mesh/kubernetes/

min_version:
  mesh: '2.6'

products:
  - mesh

tldr:
  q: How can I use a built-in gateway to allow traffic from outside my mesh?
  a: |
    Create a `MeshGatewayInstance` and a `MeshGateway` to configure the built-in gateway, then create a `MeshHTTPRoute` and allow traffic to the gateway with a `MeshTrafficPermission`. To secure your endpoint, generate a certificate and add it to the `MeshGateway`.

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
In this guide we'll add a [built-in gateway](/mesh/managing-ingress-traffic/gateway/) in front of the demo-app service and expose it publicly.

## Configure the gateway

1. Create a `MeshGatewayInstance` resource to configure the pods that will run the gateway:

   ```sh
   echo "apiVersion: kuma.io/v1alpha1
   kind: MeshGatewayInstance
   metadata:
     name: built-in-gateway
     namespace: kong-mesh-demo
   spec:
     replicas: 1
     serviceType: LoadBalancer" | kubectl apply -f -
   ```

1. Use the `MeshGateway` resource to define an HTTP listener on port 8080:

   ```sh
   echo "apiVersion: kuma.io/v1alpha1
   kind: MeshGateway
   mesh: default
   metadata:
     name: built-in-gateway
     namespace: kong-mesh-demo
   spec:
     conf:
       listeners:
         - port: 8080
           protocol: HTTP
     selectors:
       - match:
           kuma.io/service: built-in-gateway_kong-mesh-demo_svc" | kubectl apply -f -
   ```
   
1. Validate that the pods are running:

   ```sh
   kubectl get pods -n kong-mesh-demo
   ```
   
   You should see the following result:

   ```sh
   NAME                              READY   STATUS    RESTARTS   AGE
   demo-app-84d96db569-26hdl         2/2     Running   0          58s
   built-in-gateway-5d5ddc8cf9-7lv7s 1/1     Running   0          12s
   kv-648747567c-7ddb4               2/2     Running   0          58s
   ```
   {:.no-copy-code}
   
{% include /how-tos/steps/mesh-built-in-gateway.md section="ip"%}

## Create a Route

1. Create a Route with the `MeshHTTPRoute` resource and associate it with the built-in gateway:

   ```sh
   echo "apiVersion: kuma.io/v1alpha1
   kind: MeshHTTPRoute
   metadata:
     name: demo-app-built-in-gateway
     namespace: kong-mesh-system
   spec:
     targetRef:
       kind: MeshGateway
       name: built-in-gateway
     to:
       - targetRef:
           kind: Mesh
         rules:
           - default:
               backendRefs:
                 - kind: MeshService
                   name: demo-app
                   namespace: kong-mesh-demo
                   port: 5050
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
     namespace: kong-mesh-system 
     labels:
       kuma.io/mesh: default
   data:
     value: "$(cat tls.key tls.crt | base64)"
   type: system.kuma.io/secret" | kubectl apply -f - 
   ```
   
1. Update the gateway to use the certificate:

   ```sh
   echo "apiVersion: kuma.io/v1alpha1
   kind: MeshGateway
   mesh: default
   metadata:
     name: built-in-gateway
   spec:
     selectors:
       - match:
           kuma.io/service: built-in-gateway_kong-mesh-demo_svc
     conf:
       listeners:
         - port: 8080
           protocol: HTTPS
           tls:
             mode: TERMINATE
             certificates:
               - secret: my-gateway-certificate
           tags:
             port: http-8080" | kubectl apply -f -
   ```

{% include /how-tos/steps/mesh-built-in-gateway.md section="validate" %}
