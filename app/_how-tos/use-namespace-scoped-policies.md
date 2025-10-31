---
title: Use namespace-scoped {{site.mesh_product_name}} policies
description: "Learn how to define namespace-scoped producer and consumer policies in {{site.mesh_product_name}} using a demo application."
content_type: how_to
permalink: /mesh/consumer-producer-policies/
bread-crumbs: 
  - /mesh/
related_resources:
  - text: "{{site.mesh_product_name}} policies"
    url: /mesh/policies-introduction/

products:
  - mesh

works_on:
  - on-prem

min_version:
  mesh: "2.9"

tldr:
  q: "How can I scope a {{site.mesh_product_name}} policy to a specific consumer?"
  a: "Create a deploy a consumer namespace with sidecar injection enabled, then create your policy within that consumer namespace."

prereqs:
  inline:
    - title: Helm
      include_content: prereqs/helm
    - title: A running Kubernetes cluster
      include_content: prereqs/kubernetes/mesh-cluster
    - title: Install {{site.mesh_product_name}} with demo configuration
      include_content: prereqs/kubernetes/mesh-quickstart

cleanup:
  inline:
    - title: Clean up Mesh
      include_content: cleanup/products/mesh
      icon_url: /assets/icons/gateway.svg
---

## Add MeshTrafficPermission

Add a [MeshTrafficPermission](/mesh/policies/meshtrafficpermission/) policy to allow access to the mesh we created in the [prerequisites](#install-kong-mesh-with-demo-configuration):

```sh
echo "apiVersion: kuma.io/v1alpha1
kind: MeshTrafficPermission
metadata:
  namespace: kong-mesh-demo
  name: mtp
spec:
  targetRef:
    kind: Mesh
  from:
    - targetRef:
        kind: Mesh
      default:
        action: Allow" | kubectl apply -f -
```

## Create consumer namespaces

In this example, we'll create two different consumer namespaces, and apply different policies to them.

1. Create the first consumer namespace:

   ```sh
   echo "apiVersion: v1
   kind: Namespace
   metadata:
     name: first-consumer
     labels:
       kuma.io/sidecar-injection: enabled" | kubectl apply -f -
   ```

1. Deploy the first namespace:

   ```sh
   kubectl run consumer --image nicolaka/netshoot -n first-consumer --command -- /bin/bash -c "ping -i 60 localhost"
   ```


1. Create the second consumer namespace:
   ```sh
   echo "apiVersion: v1
   kind: Namespace
   metadata:
     name: second-consumer
     labels:
       kuma.io/sidecar-injection: enabled" | kubectl apply -f -
   ```

1. Deploy the second namespace:

    ```sh
    kubectl run consumer --image nicolaka/netshoot -n second-consumer --command -- /bin/bash -c "ping -i 60 localhost"
    ```

1. Send a request to the first consumer to validate that it's working:

   ```sh
   kubectl exec -n first-consumer consumer -- curl -s -XPOST demo-app.kong-mesh-demo:5050/api/counter
   ```
   
   You should get the following response:

   ```sh
   {
       "counter": 1,
       "zone": ""
   }
   ```
   {:.no-copy-code}

   {:.info}
   > If you get a `container not found` error, it may be because the consumer pod takes a few seconds to initialize. Wait a few seconds and try again.

## Add a MeshTimeout producer policy

1. Add a [MeshTimeout](/mesh/policies/meshtimeout/) producer policy with a one second timeout:

   ```sh
   echo "apiVersion: kuma.io/v1alpha1
   kind: MeshTimeout
   metadata:
     name: producer-timeout
     namespace: kong-mesh-demo
     labels:
       kuma.io/mesh: default
       kuma.io/origin: zone
   spec:
     to:
       - targetRef:
           kind: MeshService
           name: demo-app
         default:
           http:
             requestTimeout: 1s" | kubectl apply -f -
   ```

1. Run the following command to inspect the policy labels:

   ```sh
   kubectl get meshtimeout -n kong-mesh-demo producer-timeout -o jsonpath='{.metadata.labels}'
   ```

   You should get the following result:

   ```sh
   {
       "k8s.kuma.io/namespace": "kong-mesh-demo",
       "kuma.io/env": "kubernetes",
       "kuma.io/mesh": "default",
       "kuma.io/origin": "zone",
       "kuma.io/policy-role": "producer",
       "kuma.io/zone": "default"
   }
   ```
   {:.no-copy-code}

   {{site.mesh_product_name}} adds custom labels to the policy. The `kuma.io/policy-role` label set to `producer` indicates that the policy applies to the same namespace as the MeshService it targets in `spec.to`. In this example the targeted MeshService is `demo-app`, which is associated with the `kong-mesh-demo` namespace.

## Validate the MeshTimeout policy

Send requests to the demo app using both consumer namespaces with the `x-set-response-delay-ms` header to simulate delays:

```sh
kubectl exec -n first-consumer consumer -- curl -s -XPOST demo-app.kong-mesh-demo:5050/api/counter -H "x-set-response-delay-ms: 2000"
```

```sh
kubectl exec -n second-consumer consumer -- curl -s -XPOST demo-app.kong-mesh-demo:5050/api/counter -H "x-set-response-delay-ms: 2000"
```

You should get the following response for both:
```sh
upstream request timeout
```
{:.no-copy-code}

## Add a MeshTimeout consumer policy

1. Add a MeshTimeout consumer policy with a three second timeout, scoped to the first consumer:

   ```sh
   echo "apiVersion: kuma.io/v1alpha1
   kind: MeshTimeout
   metadata:
    name: consumer-timeout
    namespace: first-consumer
    labels:
        kuma.io/mesh: default
        kuma.io/origin: zone
   spec:
     to:
       - targetRef:
           kind: MeshService
           labels:
             k8s.kuma.io/service-name: demo-app
         default:
           http:
             requestTimeout: 3s" | kubectl apply -f -
    ```

1. Run the following command to inspect the policy labels:

   ```sh
   kubectl get meshtimeout -n first-consumer consumer-timeout -o jsonpath='{.metadata.labels}'
   ```

   You should get the following result:

   ```sh
   {
       "k8s.kuma.io/namespace": "first-consumer",
       "kuma.io/env": "kubernetes",
       "kuma.io/mesh": "default",
       "kuma.io/origin": "zone",
       "kuma.io/policy-role": "consumer",
       "kuma.io/zone": "default"
   }
   ```
   {:.no-copy-code}

   The `kuma.io/policy-role` label set to `consumer` indicates the policy applies to the consumer namespace, `first-consumer` in this example. This overrides the producer policy.

1. Send a request to the demo app using the first consumer namespace:

   ```sh
   kubectl exec -n first-consumer consumer -- curl -s -XPOST demo-app.kong-mesh-demo:5050/api/counter -H "x-set-response-delay-ms: 2000"
   ```
   
   Since we've increased the timeout for the first consumer, you should get this response:

   ```sh
   {
       "counter": 2,
       "zone": ""
   }
   ```
   {:.no-copy-code}

   If you send a request to the second consumer, you should still get a timeout:

   ```sh
   kubectl exec -n second-consumer consumer -- curl -s -XPOST demo-app.kong-mesh-demo:5050/api/counter -H "x-set-response-delay-ms: 2000"
   ```

   