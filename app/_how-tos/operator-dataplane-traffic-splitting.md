---
title: How to split traffic 
description: "Learn how to configure HTTPS listeners and TLS termination for {{ site.operator_product_name }}."
content_type: how_to

permalink: /operator/dataplanes/how-to/how-to-traffic-splitting/
breadcrumbs:
  - /operator/
  - index: operator
    group: Gateway Deployment
  - index: operator
    group: Gateway Deployment
    section: "How-To"

products:
  - operator

works_on:
  - on-prem
  - konnect

tldr:
  q: How do I configure TLS termination for {{ site.operator_product_name }}?
  a: Add an `HTTPS` protocol listener to your `Gateway` resource and reference a Kubernetes `Secret` containing your TLS certificate and key.

---

# Traffic Splitting with HTTPRoute

Traffic splitting, also known as canary releases or blue/green deployments, allows you to shift traffic between multiple versions of your service. 

With the {{ site.operator_product_name }} and Gateway API, traffic splitting is managed natively using `HTTPRoute` weights.

## Prerequisites

*   {{ site.operator_product_name }} installed.
*   A `Gateway` resource configured and programmed.
*   Two versions of your service deployed (e.g., `echo-v1` and `echo-v2`).

## Step 1: Deploy Sample Services

First, ensure you have two separate deployments and services representing your service versions.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: echo-v1
spec:
  selector:
    app: echo-v1
  ports:
  - name: http
    port: 80
    targetPort: 1027
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: echo-v1
spec:
  replicas: 1
  selector:
    matchLabels:
      app: echo-v1
  template:
    metadata:
      labels:
        app: echo-v1
    spec:
      containers:
      - name: echo
        image: kong/go-echo:latest
        env:
        - name: NODE_NAME
          value: "v1"
---
apiVersion: v1
kind: Service
metadata:
  name: echo-v2
spec:
  selector:
    app: echo-v2
  ports:
  - name: http
    port: 80
    targetPort: 1027
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: echo-v2
spec:
  replicas: 1
  selector:
    matchLabels:
      app: echo-v2
  template:
    metadata:
      labels:
        app: echo-v2
    spec:
      containers:
      - name: echo
        image: kong/go-echo:latest
        env:
        - name: NODE_NAME
          value: "v2"
```

## Step 2: Create a Weighted HTTPRoute

Define an `HTTPRoute` that references both services in the `backendRefs` section. Each reference includes a `weight`.

{% tip %}
Weights are relative. If you have two backends with weights 50 and 50, traffic is split 50/50. If weights are 90 and 10, traffic is split 90/10.
{% endtip %}

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: canary-route
spec:
  parentRefs:
  - name: kong-gateway
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /echo
    backendRefs:
    - name: echo-v1
      port: 80
      weight: 50
    - name: echo-v2
      port: 80
      weight: 50
```

## Step 3: Verify Traffic Distribution

Once the `HTTPRoute` is applied, you can verify the distribution by sending multiple requests to the route.

```bash
for i in {1..10}; do curl -s http://<GATEWAY_IP>/echo; done
```

You should see an approximate 50/50 split between "node v1" and "node v2" responses.

