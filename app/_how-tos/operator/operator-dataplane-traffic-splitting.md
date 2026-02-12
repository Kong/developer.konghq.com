---
title: Split traffic between versions of a Service
description: Learn how to use the HTTPRoute resource to split traffic between multiples versions of the same Service.
content_type: how_to

permalink: /operator/dataplanes/how-to/split-traffic/
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

prereqs:
  inline:
    - title: Create Gateway resources
      include_content: /prereqs/operator/gateway

tldr:
  q: How can I split traffic between multiple versions of a Service?
  a: |
    Configure your `HTTPRoute` with one entry in `backendRefs` for each Service version, and assign a weight to each version to define how to split the traffic.

---

Traffic splitting, also known as canary releases or blue/green deployments, allows you to shift traffic between multiple versions of your service. 

With {{ site.operator_product_name }} and the Gateway API, traffic splitting is managed natively using `HTTPRoute` weights.

## Deploy sample Services

Deploy two versions of the same Service:

```sh
echo '
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
' | kubectl apply -f - -n kong
```

## Create a weighted HTTPRoute

Define an `HTTPRoute` resource that references both Services in the `backendRefs` section. Each reference includes a `weight`.
In this example, we'll configure a 50/50 split between the Services:

```sh
echo '
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: canary-route
  namespace: kong
spec:
  parentRefs:
  - name: kong
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
      weight: 50' | kubectl apply -f -
```

{:.info}
> Weights are relative. If you have two backends with weights 50 and 50, traffic is split 50/50. If weights are 90 and 10, traffic is split 90/10.

## Validate

1. Get the Gateway's external IP:
   
   ```bash
   export PROXY_IP=$(kubectl get gateway kong -n kong -o jsonpath='{.status.addresses[0].value}')
   ```


1. Send multiple requests to the Route:

   ```bash
   for i in {1..10}; do curl -s http://$PROXY_IP/echo; done
   ```

   You should see an even split between v1 and v2:

   ```
   Welcome, you are connected to node v1.

   Welcome, you are connected to node v2.

   Welcome, you are connected to node v1.

   Welcome, you are connected to node v1.

   Welcome, you are connected to node v2.

   Welcome, you are connected to node v1.

   Welcome, you are connected to node v2.

   Welcome, you are connected to node v1.

   Welcome, you are connected to node v2.

   Welcome, you are connected to node v2.
   ```
   {:.no-copy-code}

