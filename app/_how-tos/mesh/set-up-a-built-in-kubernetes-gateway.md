---
title: Set up a built-in Kubernetes gateway with {{site.mesh_product_name}}
permalink: /how-to/set-up-a-built-in-kubernetes-gateway/
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
  - text: Kubernetes built-in gateways with {{site.mesh_product_name}}
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

To get traffic from outside your mesh with {{site.mesh_product_name}}, you can use a built-in gateway.

With the [demo configuration](#install-kong-mesh-with-demo-configuration), traffic can only get in the mesh by port-forwarding to an instance of an app inside the mesh.
In production, you typically set up a gateway to receive traffic external to the mesh.
In this guide we'll use the [Kubernetes Gateway API](/mesh/kubernetes-gateway-api/) to add a [built-in gateway](/mesh/built-in-gateway/) in front of the demo-app service and expose it publicly.

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
   
1. Export the gateway's public IP: 

   ```sh
   export PROXY_IP=$(kubectl get svc -n kong-mesh-demo built-in-gateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
   echo $PROXY_IP
   ```

1. Send a request to the gateway to validate that it's running:

   ```sh
   curl -i $PROXY_IP:8080
   ```
   
   Since we haven't configured any Routes, you should see the following result:

   ```sh
   HTTP/1.1 404 Not Found
   content-length: 62
   content-type: text/plain
   vary: Accept-Encoding
   date: Tue, 06 Jan 2026 14:36:29 GMT
   server: Kuma Gateway
   
   This is a Kuma MeshGateway. No routes match this MeshGateway!
   ```
   {:.no-copy-code}

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

1. Send a request to the gateway:

   ```sh
   curl -i $PROXY_IP:8080
   ```

   Now the Route exists, but the gateway can't access the demo app service because of the permissions applied in the [demo configuration](#install-kong-mesh-with-demo-configuration):   
   ```sh
   HTTP/1.1 403 Forbidden
   content-length: 19
   content-type: text/plain
   date: Tue, 06 Jan 2026 14:37:19 GMT
   server: Kuma Gateway
   x-envoy-upstream-service-time: 0
   
   RBAC: access denied%      
   ```
   {:.no-copy-code}

1. Add a `MeshTrafficPermission` resource to allow traffic to the Service:
   
   ```sh
   echo "apiVersion: kuma.io/v1alpha1
   kind: MeshTrafficPermission
   metadata:
     namespace: kong-mesh-demo 
     name: demo-app
   spec:
     targetRef:
       kind: Dataplane
       labels:
         app: demo-app
     from:
       - targetRef:
           kind: MeshSubset
           tags: 
             kuma.io/service: built-in-gateway_kong-mesh-demo_svc 
         default:
           action: Allow" | kubectl apply -f -
   ```
   
1. Send a request to the Route:

   ```sh
   curl -XPOST -i $PROXY_IP:8080/api/counter
   ```

   You should get the following result:
   
   ```json
   {"counter":1,"zone":""}
   ```
   {:.no-copy-code}


## Secure your endpoint

With the gateway, we exposed the application to a public endpoint. To secure it, we'll add TLS to our endpoint.

1. Create a self-signed certificate:

   ```sh
   openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout tls.key -out tls.crt -subj "/CN=$PROXY_IP"
   ```

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

1. Send a request to the gateway:   
   ```sh
   curl -X POST -v --insecure "https://$PROXY_IP:8080/api/counter"
   ```
   
   {:.info}
   > Since we're using a self-signed certificate for testing purposes, we need the `--insecure` flag.
   
   You should see a successful request with a TLS handshake:

   ```sh
   *   Trying 127.0.0.0:8080...
   * Connected to 127.0.0.0 (127.0.0.0) port 8080
   * ALPN: curl offers h2,http/1.1
   * (304) (OUT), TLS handshake, Client hello (1):
   * (304) (IN), TLS handshake, Server hello (2):
   * (304) (IN), TLS handshake, Unknown (8):
   * (304) (IN), TLS handshake, Certificate (11):
   * (304) (IN), TLS handshake, CERT verify (15):
   * (304) (IN), TLS handshake, Finished (20):
   * (304) (OUT), TLS handshake, Finished (20):
   * SSL connection using TLSv1.3 / AEAD-CHACHA20-POLY1305-SHA256 / [blank] / UNDEF
   * ALPN: server accepted h2
   * Server certificate:
   *  subject: CN=127.0.0.0
   *  start date: Jan  6 14:38:19 2026 GMT
   *  expire date: Jan  6 14:38:19 2027 GMT
   *  issuer: CN=127.0.0.0
   *  SSL certificate verify result: self signed certificate (18), continuing anyway.
   * using HTTP/2
   * [HTTP/2] [1] OPENED stream for https://127.0.0.0:8080/api/counter
   * [HTTP/2] [1] [:method: POST]
   * [HTTP/2] [1] [:scheme: https]
   * [HTTP/2] [1] [:authority: 127.0.0.0:8080]
   * [HTTP/2] [1] [:path: /api/counter]
   * [HTTP/2] [1] [user-agent: curl/8.7.1]
   * [HTTP/2] [1] [accept: */*]
   > POST /api/counter HTTP/2
   > Host: 127.0.0.0:8080
   > User-Agent: curl/8.7.1
   > Accept: */*
   > 
   * Request completely sent off
   < HTTP/2 200 
   < content-type: application/json; charset=utf-8
   < x-demo-app-version: v1
   < date: Tue, 06 Jan 2026 15:01:35 GMT
   < content-length: 24
   < x-envoy-upstream-service-time: 25
   < server: Kuma Gateway
   < strict-transport-security: max-age=31536000; includeSubDomains
   < 
   {"counter":2,"zone":""}
   ```
   {:.no-copy-code}