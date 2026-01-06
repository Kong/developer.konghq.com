---
title: Set up a built-in gateway with {{site.mesh_product_name}}
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
  q: TODO
  a: |
    TODO

prereqs:
  inline:
    - title: Helm
      include_content: prereqs/helm
    - title: A running Kubernetes cluster with LoadBalancer support
      include_content: prereqs/kubernetes/mesh-cluster-lb
    - title: Install {{site.mesh_product_name}} with demo configuration
      include_content: prereqs/kubernetes/mesh-quickstart

---

```sh
echo "apiVersion: kuma.io/v1alpha1
kind: MeshGatewayInstance
metadata:
  name: edge-gateway
  namespace: kong-mesh-demo
spec:
  replicas: 1
  serviceType: LoadBalancer" | kubectl apply -f -
```

```sh
echo "apiVersion: kuma.io/v1alpha1
kind: MeshGateway
mesh: default
metadata:
  name: edge-gateway
  namespace: kong-mesh-demo
spec:
  conf:
    listeners:
      - port: 8080
        protocol: HTTP
  selectors:
    - match:
        kuma.io/service: edge-gateway_kong-mesh-demo_svc" | kubectl apply -f -
```

```sh
kubectl get pods -n kong-mesh-demo
```

```sh
demo-app-84d96db569-26hdl       2/2     Running   0          58s
edge-gateway-5d5ddc8cf9-7lv7s   1/1     Running   0          12s
kv-648747567c-7ddb4             2/2     Running   0          58s
```
{:.no-copy-code}

```sh
export PROXY_IP=$(kubectl get svc -n kong-mesh-demo edge-gateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo $PROXY_IP
```

```sh
curl -i $PROXY_IP:8080
```

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

```sh
echo "apiVersion: kuma.io/v1alpha1
kind: MeshHTTPRoute
metadata:
  name: demo-app-edge-gateway
  namespace: kong-mesh-system
spec:
  targetRef:
    kind: MeshGateway
    name: edge-gateway
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

```sh
curl -i $PROXY_IP:8080
```

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
          kuma.io/service: edge-gateway_kong-mesh-demo_svc 
      default:
        action: Allow" | kubectl apply -f -
```

```sh
curl -XPOST -i $PROXY_IP:8080/api/counter
```

```json
{"counter":1,"zone":""}
```
{:.no-copy-code}

```sh
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout tls.key -out tls.crt -subj "/CN=$PROXY_IP"
```

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

```sh
echo "apiVersion: kuma.io/v1alpha1
kind: MeshGateway
mesh: default
metadata:
  name: edge-gateway
spec:
  selectors:
    - match:
        kuma.io/service: edge-gateway_kong-mesh-demo_svc
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

```sh
curl -X POST -i --insecure "https://$PROXY_IP:8080/api/counter"
```

```sh
{"counter":2,"zone":""}
```
{:.no-copy-code}
