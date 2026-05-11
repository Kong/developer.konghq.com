---
title: Configure inbound traffic with the rules API
description: Apply policies to data plane inbounds using the rules API with Dataplane targetRef kind.
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
  - text: "{{site.mesh_product_name}} concepts"
    url: /mesh/concepts/

tldr:
  q: How do I configure inbound traffic with the rules API?
  a: Use the rules API with the Dataplane targetRef kind to apply policies like MeshTimeout to data plane inbounds.

prereqs:
  inline:
    - title: Helm
      include_content: prereqs/helm
    - title: A running Kubernetes cluster
      include_content: prereqs/kubernetes/mesh-cluster
    - title: Install {{site.mesh_product_name}} with demo configuration
      include_content: prereqs/kubernetes/mesh-quickstart
---

## Set up the basic environment

To make sure that traffic works in the examples, configure MeshTrafficPermission to allow all traffic:

```shell
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

To finish the setup, create an additional namespace with [sidecar injection](/mesh/concepts/#data-plane-proxy--sidecar) for the client you will use to communicate with the demo app:

```shell
echo "apiVersion: v1
kind: Namespace
metadata:
  name: consumer
  labels:
    kuma.io/sidecar-injection: enabled" | kubectl apply -f -
```

Create a deployment to communicate with the demo app from the `consumer` namespace:

```shell
kubectl run consumer --image nicolaka/netshoot --labels="app=consumer" -n consumer --command -- /bin/bash -c "ping -i 60 localhost"
```

Send a request to the demo app to check that everything is working:

```shell
kubectl exec -n consumer consumer -- curl -s -XPOST demo-app.kong-mesh-demo:5050/api/counter
```

You should see something similar to:

```json
{"counter":"1","zone":""}
```
{:.no-copy-code}

## Configure inbound traffic with the rules API

Now that the setup is complete, use the rules API for inbound policies with the Dataplane kind.
Create a simple inbound [MeshTimeout](/mesh/policies/meshtimeout/) policy in the `kong-mesh-demo` namespace:

```shell
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

To verify the policy is working, send a request to the demo app:

```shell
kubectl exec -n consumer consumer -- curl -s -XPOST demo-app.kong-mesh-demo:5050/api/counter -H "x-set-response-delay-ms: 2000"
```

Example output:

```
upstream request timeout
```
{:.no-copy-code}

### Select Dataplane resources

The policy selects only `Dataplane` resources that contain the label `app=demo-app`. You can select data planes in multiple ways.

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

When your application exposes multiple named inbounds, you can select a single inbound from your data plane using the `sectionName` field:

```yaml
targetRef:
  kind: Dataplane
  name: demo-app
  sectionName: http-port
```

### Configure incoming traffic with the rules API

The policy above uses the `rules` field to configure all incoming traffic to your data plane:

```yaml
rules:
  - default:
      http:
        requestTimeout: 1s
```

This example applies a **request timeout of 1 second** to incoming requests. The rules API applies configuration to all incoming traffic and doesn't support filtering by a subset of traffic, so it doesn't yet support MeshTrafficPermission or MeshFaultInjection.
