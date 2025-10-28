---
title: "{{site.base_gateway}} as a delegated gateway with {{site.mesh_product_name}}"

description: 'Set up {{site.base_gateway}} as a delegated gateway for {{site.base_product}} to expose internal services to external traffic.'

content_type: how_to

permalink: /mesh/gateway-delegated/

bread-crumbs: 
  - /mesh/

related_resources:
  - text: Add a builtin gateway
    url: '/mesh/add-builtin-gateway/'
  - text: Deploy Kong Mesh on Kubernetes
    url: /mesh/kubernetes/
  - text: About KIC
    url: /kubernetes-ingress-controller/

min_version:
    mesh: '2.6'

products:
  - mesh

works_on:
  - on-prem

tldr:
  q: ""
  a: ""

prereqs:
  inline:
    - title: Helm
      include_content: prereqs/helm
    - title: A running Kubernetes cluster with LoadBalancer support
      include_content: prereqs/kubernetes/mesh-cluster-lb
   # - title: Install {{site.mesh_product_name}} with demo configuration
    #  include_content: prereqs/kubernetes/mesh-quickstart

cleanup:
  inline:
    - title: Clean up Mesh
      include_content: cleanup/products/mesh
      icon_url: /assets/icons/gateway.svg
---

## Enable the Gateway API

1. Install the Gateway API CRDs before installing {{ site.kic_product_name }}:

   ```sh
   kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.3.0/standard-install.yaml
   ```

1. Create a `Gateway` and `GatewayClass` instance to use:

   ```sh
   echo "
   apiVersion: v1
   kind: Namespace
   metadata:
     name: kong
   ---
   apiVersion: gateway.networking.k8s.io/v1
   kind: GatewayClass
   metadata:
     name: kong
     annotations:
       konghq.com/gatewayclass-unmanaged: 'true'
   spec:
     controllerName: konghq.com/kic-gateway-controller
   ---
   apiVersion: gateway.networking.k8s.io/v1
   kind: Gateway
   metadata:
     name: kong
   spec:
     gatewayClassName: kong
     listeners:
     - name: proxy
       port: 80
       protocol: HTTP
       allowedRoutes:
         namespaces:
            from: All
   " | kubectl apply -n kong -f -
   ```

## Install {{ site.kic_product_name }}

```sh
helm install kong kong/ingress -n kong --create-namespace
```

## Enable sidecar injection

1. 

   ```sh
   kubectl label namespace kong kuma.io/sidecar-injection=enabled
   ```

1. 

   ```sh
   kubectl rollout restart -n kong deployment kong-gateway kong-controller
   kubectl wait -n kong --for=condition=ready pod --selector=app=kong-controller --timeout=90s
   ```

1. 
   
   ```sh
   kubectl get pods -n kong
   ```
   

   
   ```sh
   NAME                             READY   STATUS    RESTARTS      AGE
   kong-controller-78d5486d98-7wqm6   2/2     Running   1 (46s ago)   49s
   kong-gateway-5d697cd486-4h55p      2/2     Running   0             49s
   ```

1. 

   ```sh
   export PROXY_IP=$(kubectl get svc -n kong kong-gateway-proxy -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
   echo $PROXY_IP
   ```

## Add an HTTPRoute resource

```sh
echo "apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: demo-app
  namespace: kong-mesh-demo
spec:
  parentRefs:
  - name: kong
    namespace: kong
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /
    backendRefs:
    - name: demo-app
      namespace: kong-mesh-demo
      kind: Service
      port: 5050 " | kubectl apply -f -
```

## Add a MeshTrafficPermission policy

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
          app.kubernetes.io/name: gateway
          k8s.kuma.io/namespace: kong
      default:
        action: Allow" | kubectl apply -f -
```

```sh
curl -i $PROXY_IP/api/counter -XPOST
```

```sh
{
    "counter": 1,
    "zone": ""
}
```

{:.info}
> If you get an `RBAC: access denied` error, it may be due to the configuration taking some time to be applied. Wait a few seconds and try again.