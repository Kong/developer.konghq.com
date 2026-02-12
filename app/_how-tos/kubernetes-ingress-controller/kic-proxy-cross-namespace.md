---
title: Configure Gateway API resources across namespaces

description: "Route traffic to a Service in a different namespace using ReferenceGrant"
content_type: how_to

permalink: /kubernetes-ingress-controller/routing/cross-namespace/
breadcrumbs:
  - /kubernetes-ingress-controller/
  - index: kubernetes-ingress-controller
    section: Routing

products:
  - kic

works_on:
  - on-prem
  - konnect

entities: []

tldr:
  q: How do I route HTTP traffic to a Service in a different namespace?
  a: |
    Set `allowedRoutes: All` on your `Gateway` resource and create a `ReferenceGrant` that allows `HTTPRoute` instances from a specific namespace to access Services in the current namespace.

prereqs:
  kubernetes:
    gateway_api:
      allowed_routes: "Same"

cleanup:
  inline:
    - title: Uninstall KIC from your cluster
      include_content: cleanup/products/kic
      icon_url: /assets/icons/kubernetes.svg
---

## Create namespaces and allow references

1. Create separate namespaces to hold the `HTTPRoute` and target Service:

   ```bash
   kubectl create namespace test-source
   kubectl create namespace test-destination
   ```
1. Create a [`ReferenceGrant` resource](https://gateway-api.sigs.k8s.io/api-types/referencegrant/)
   in the destination namespace:

   ```bash
   echo 'kind: ReferenceGrant
   apiVersion: gateway.networking.k8s.io/v1beta1    
   metadata:                                    
     name: test-grant
     namespace: test-destination
   spec:                        
     from:
     - group: gateway.networking.k8s.io
       kind: HTTPRoute                 
       namespace: test-source
     to:                     
     - group: ""
       kind: Service
   ' | kubectl apply -f -
   ```

ReferenceGrants allow namespaces to opt in to references from other resources. They reside in the namespace of the target resource and list resources and namespaces that can talk to specific resources in the ReferenceGrant's namespace. 

In this case, the example configuration allows HTTPRoutes in the `test-source` namespace to reference Services in the `test-destination` namespace.

## Using a Gateway resource in a different namespace

Gateway resources may also allow references from resources (`HTTPRoute`,
`TCPRoute`, etc.) in other namespaces. However, these references _do not_ use
ReferenceGrants, as they are defined per listener in the Gateway resource, not for the entire Gateway.
A listener's [`allowedRoutes` field](https://gateway-api.sigs.k8s.io/concepts/security-model/#1-route-binding)
lets you define which routing resources can bind to that listener.

The default Gateway in this guide only allows Routes from its same namespace
(`kong`). You'll need to expand its scope to allow Routes from the
`test-source` namespace:

```bash
kubectl patch -n kong --type=json gateways.gateway.networking.k8s.io kong -p='[{"op":"replace","path": "/spec/listeners/0/allowedRoutes/namespaces/from","value":"All"}]'
```

This results in a `Gateway` resource with the following configuration:

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: kong
  namespace: kong
spec:
  gatewayClassName: kong
  listeners:
  - name: proxy
    port: 80
    protocol: HTTP
    allowedRoutes:
      namespaces:
        from: All
```
{:.no-copy-code}

Listeners can allow Routes in their own namespace (`from: Same`), all namespaces (`from: All`), or a
labeled set of namespaces (`from: Selector`).

## Deploy a Service and HTTPRoute

1. Deploy an echo Service to the `test-destination` resource.

   ```bash
   kubectl apply -f {{ site.links.web }}/manifests/kic/echo-service.yaml -n test-destination
   ```

1. Deploy an HTTPRoute that sends traffic to the Service:

   ```bash
   echo 'apiVersion: gateway.networking.k8s.io/v1
   kind: HTTPRoute
   metadata:
     name: echo
     namespace: test-source
     annotations:
       konghq.com/strip-path: "true"
   spec:
     parentRefs:
     - name: kong
       namespace: kong
     rules:
     - matches:
       - path:
           type: PathPrefix
           value: /echo
       backendRefs:
       - name: echo
         kind: Service
         port: 1027
         namespace: test-destination
   ' | kubectl apply -f -
   ```

   Note the `namespace` fields in both the parent and backend references. By
   default, entries here attempt to use the same namespace as the HTTPRoute if
   you don't specify a namespace.

1. Validate the configuration by sending requests through the Route:

   ```bash
   curl -s "$PROXY_IP/echo"
   ```

   The results should look like this:

   ```text
   Welcome, you are connected to node kind-control-plane.
   Running on Pod echo-965f7cf84-z9jv2.
   In namespace test-destination.
   With IP address 10.244.0.6.
   ```
   {:.no-copy-code}