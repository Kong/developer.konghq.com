---
title: "{{site.base_gateway}} as a delegated gateway with {{site.mesh_product_name}}"

description: 'Set up {{site.base_gateway}} as a delegated gateway for {{site.base_product}} to expose internal services to external traffic.'

content_type: how_to

permalink: /mesh/gateway-delegated/

bread-crumbs: 
  - /mesh/

related_resources:
  - text: Set up a built-in gateway with {{site.mesh_product_name}}
    url: /how-to/set-up-a-built-in-mesh-gateway/
  - text: Set up a built-in gateway on Kubernetes with {{site.mesh_product_name}}
    url: /how-to/set-up-a-built-in-kubernetes-gateway/
  - text: Deploy {{site.mesh_product_name}} on Kubernetes
    url: /mesh/kubernetes/
  - text: "{{site.kic_product_name}}"
    url: /kubernetes-ingress-controller/

min_version:
    mesh: '2.6'

products:
  - mesh
  - kic

works_on:
  - on-prem

tldr:
  q: "How can I use {{site.base_gateway}} to export internal {{site.mesh_product_name}} services to external traffic?"
  a: "Enable the Gateway API, [install {{site.kic_product_name}}](/kubernetes-ingress-controller/install/), enable sidecar injection on the namespace associated with {{site.kic_product_name_short}}, and restart the {{site.kic_product_name_short}} and {{site.base_gateway}} pods. Make sure that your mesh is configured to allow external traffic using a `MeshTrafficPermission` policy."

prereqs:
  skip_product: true
  inline:
    - title: Helm
      include_content: prereqs/helm
    - title: A running Kubernetes cluster with LoadBalancer support
      include_content: prereqs/kubernetes/mesh-cluster-lb
    - title: Install {{site.mesh_product_name}} with demo configuration
      include_content: prereqs/kubernetes/mesh-quickstart
---

## Enable the Gateway API

In this example, we'll use [{{site.kic_product_name}}](/kubernetes-ingress-controller/) to manage {{site.base_gateway}}. Before installing {{site.kic_product_name_short}}, we need to enable the Kubernetes Gateway API.

1. Install the Gateway API CRDs:

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

## Install {{site.kic_product_name}}

Use the following command to install {{site.kic_product_name}} in a new `kong` namespace:

```sh
helm install kong kong/ingress -n kong --create-namespace
```

## Enable sidecar injection

Since {{site.kic_product_name}} is installed outside of the mesh, we need to enable sidecar injection.

1. Add the sidecar injection label to the `kong` namespace:

   ```sh
   kubectl label namespace kong kuma.io/sidecar-injection=enabled
   ```

1. Restart the {{site.kic_product_name}} and {{site.base_gateway}} pods:

   ```sh
   kubectl rollout restart -n kong deployment kong-gateway kong-controller
   kubectl wait -n kong --for=condition=ready pod --selector=app=kong-gateway --timeout=90s
   ```

1. Check the pods' information:
   
   ```sh
   kubectl get pods -n kong
   ```
   
   You should see two containers for each pod, one for the application and one for the sidecar:
   
   ```sh
   NAME                             READY   STATUS    RESTARTS      AGE
   kong-controller-78d5486d98-7wqm6   2/2     Running   1 (46s ago)   49s
   kong-gateway-5d697cd486-4h55p      2/2     Running   0             49s
   ```

1. Export the gateway's public URL to your environment:

   ```sh
   export PROXY_IP=$(kubectl get svc -n kong kong-gateway-proxy -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
   echo $PROXY_IP
   ```

## Add a Route

Use the `HTTPRoute` resource to add a [Route](/gateway/entities/route/) to your gateway:

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

The demo configuration we set in the [prerequisites](#install-kong-mesh-with-demo-configuration) applies restrictive permissions, so the gateway can't access the demo service. We need to add a `MeshTrafficPermission` policy to allow traffic from the `kong` namespace:

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

## Validate

Send a request to the proxy URL:

<!--vale off -->
{% validation request-check %}
url: '/api/counter'
on_prem_url: $PROXY_IP
status_code: 200
display_headers: true
method: POST
{% endvalidation %}
<!--vale on -->

You should get the following response:
```sh
{
    "counter": 1,
    "zone": ""
}
```

{:.info}
> If you get an `RBAC: access denied` error, you may need to wait for the configuration to be applied. Wait a few seconds and try again.