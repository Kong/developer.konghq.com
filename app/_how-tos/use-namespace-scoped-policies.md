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
  q: ""
  a: ""

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

```sh
echo "apiVersion: v1
kind: Namespace
metadata:
  name: first-consumer
  labels:
    kuma.io/sidecar-injection: enabled
---
apiVersion: v1
kind: Namespace
metadata:
  name: second-consumer
  labels:
    kuma.io/sidecar-injection: enabled" | kubectl apply -f -
```

```sh
kubectl run consumer --image nicolaka/netshoot -n first-consumer --command -- /bin/bash -c "ping -i 60 localhost"
```

```sh
kubectl run consumer --image nicolaka/netshoot -n second-consumer --command -- /bin/bash -c "ping -i 60 localhost"
```

Wait a few seconds:

```sh
kubectl exec -n first-consumer consumer -- curl -s -XPOST demo-app.kong-mesh-demo:5050/api/counter
```

```sh
{
    "counter": 1,
    "zone": ""
}
```
{:.no-copy-code}

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

```sh
kubectl get meshtimeout -n kong-mesh-demo producer-timeout -o jsonpath='{.metadata.labels}'
```

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

```sh
kubectl exec -n first-consumer consumer -- curl -s -XPOST demo-app.kong-mesh-demo:5050/api/counter -H "x-set-response-delay-ms: 2000"
```

```sh
upstream request timeout
```
{:.no-copy-code}

```sh
kubectl exec -n second-consumer consumer -- curl -s -XPOST demo-app.kong-mesh-demo:5050/api/counter -H "x-set-response-delay-ms: 2000"
```

```sh
upstream request timeout
```
{:.no-copy-code}

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

```sh
kubectl exec -n first-consumer consumer -- curl -s -XPOST demo-app.kong-mesh-demo:5050/api/counter -H "x-set-response-delay-ms: 2000"
```

```sh
{
    "counter": 2,
    "zone": ""
}
```
{:.no-copy-code}

```sh
kubectl exec -n second-consumer consumer -- curl -s -XPOST demo-app.kong-mesh-demo:5050/api/counter -H "x-set-response-delay-ms: 2000"
```

```sh
upstream request timeout
```
{:.no-copy-code}