---
title: Configure inbound traffic with the rules API
description: Apply policies to data plane inbounds using the rules API with the Dataplane targetRef kind.
content_type: how_to
permalink: /mesh/configure-inbound-traffic-rules-api/
bread-crumbs:
  - /mesh/

products:
  - mesh

works_on:
  - on-prem

tags:
  - policy
  - traffic-control

related_resources:
  - text: MeshTimeout policy
    url: /mesh/policies/meshtimeout/
  - text: MeshTrafficPermission policy
    url: /mesh/policies/meshtrafficpermission/

tldr:
  q: How do I configure inbound traffic with the rules API?
  a: Use the rules API with the `Dataplane` targetRef kind to apply policies like `MeshTimeout` to data plane inbounds.

faqs:
  - q: How do I select `Dataplane` resources?
    a: |
      The example policy in this guide selects only `Dataplane` resources that contain the label `app=demo-app`. You can select data planes in multiple ways.

      Select all data planes:

      ```yaml
      targetRef:
        kind: Dataplane
      ```

      Select a data plane by name and namespace:

      ```yaml
      targetRef:
        kind: Dataplane
        name: demo-app
        namespace: kong-mesh-demo
      ```

      Select a data plane by labels:

      ```yaml
      targetRef:
        kind: Dataplane
        labels:
          app: demo-app
      ```

      When your application exposes multiple named inbounds, select a single inbound from your data plane using the `sectionName` field:

      ```yaml
      targetRef:
        kind: Dataplane
        name: demo-app
        sectionName: http-port
      ```
  - q: How does the rules API apply to incoming traffic?
    a: |
      Use the `rules` field to configure all incoming traffic to your data plane:

      ```yaml
      rules:
        - default:
            http:
              requestTimeout: 1s
      ```

      The example above applies a request timeout of 1 second to incoming requests. The rules API applies configuration to all incoming traffic and doesn't support filtering by a subset of traffic, so it doesn't yet support `MeshTrafficPermission` or `MeshFaultInjection`.

prereqs:
  inline:
    - title: Helm
      include_content: prereqs/helm
    - title: A running Kubernetes cluster
      include_content: prereqs/kubernetes/mesh-cluster
    - title: Install {{site.mesh_product_name}} with demo configuration
      include_content: prereqs/kubernetes/mesh-quickstart
---

## Allow all traffic in the mesh

Configure [`MeshTrafficPermission`](/mesh/policies/meshtrafficpermission/) to allow all traffic so the examples in this guide work:

```sh
echo "apiVersion: kuma.io/v1alpha1
kind: MeshTrafficPermission
metadata:
  namespace: kong-mesh-demo
  name: mtp
spec:
  from:
    - targetRef:
        kind: Mesh
      default:
        action: Allow" | kubectl apply -f -
```

## Set up a consumer client

1. Create a namespace with [sidecar injection](/mesh/concepts/#data-plane-proxy-sidecar) for the client that communicates with the demo app:

   ```sh
   echo "apiVersion: v1
   kind: Namespace
   metadata:
     name: consumer
     labels:
       kuma.io/sidecar-injection: enabled" | kubectl apply -f -
   ```

1. Create a deployment in the `consumer` namespace to communicate with the demo app:

   ```sh
   kubectl run consumer --image nicolaka/netshoot --labels="app=consumer" -n consumer --command -- /bin/bash -c "ping -i 60 localhost"
   kubectl wait -n consumer --for=condition=ready pod --selector=app=consumer --timeout=90s
   ```

1. Send a request to the demo app to check that everything is working:

   ```sh
   kubectl exec -n consumer consumer -- curl -s -XPOST demo-app.kong-mesh-demo:5050/api/counter
   ```

   You should get the following response:

   ```json
   {"counter":"1","zone":""}
   ```
   {:.no-copy-code}

## Apply a MeshTimeout policy

Create an inbound [`MeshTimeout`](/mesh/policies/meshtimeout/) policy in the `kong-mesh-demo` namespace with the `Dataplane` targetRef kind:

```sh
echo "apiVersion: kuma.io/v1alpha1
kind: MeshTimeout
metadata:
  name: mtimeout
  namespace: kong-mesh-demo
  labels:
    kuma.io/mesh: default
    kuma.io/origin: zone
spec:
  targetRef:
    kind: Dataplane
    labels: 
      app: demo-app
  rules:
    - default:
        http:
          requestTimeout: 1s" | kubectl apply -f -
```

## Validate

Wait a few seconds for the policy to be applied, then send a request that takes longer than the configured timeout to confirm the policy is enforced:

```sh
kubectl exec -n consumer consumer -- curl -s -XPOST demo-app.kong-mesh-demo:5050/api/counter -H "x-set-response-delay-ms: 2000"
```

You should get the following output:

```
upstream request timeout
```
{:.no-copy-code}

{:.info}
> If you get the response `{"counter":2,"zone":""}`, wait a few seconds and try again.
