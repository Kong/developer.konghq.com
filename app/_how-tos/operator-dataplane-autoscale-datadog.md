---
title: Autoscale workloads with Datadog
description: 'Use the Gateway Operator and Datadog metrics to automatically scale {{site.base_gateway}} Data Plane workloads.'
content_type: how_to

permalink: /operator/dataplanes/how-to/autoscale-workloads/datadog/
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
  - konnect
  - on-prem

tldr:
  q: How can I autoscale {{site.base_gateway}} workloads using Datadog metrics?
  a: |
    Deploy a `DataPlaneMetricsExtension` to collect metrics (like latency) from a target service,
    expose those metrics on the `/metrics` endpoint, and configure the operator to reference this
    data for scaling decisions.

---

{% assign gatewayApiVersion = "v1" %}

## TODO

TODO

## Example

This example deploys an `echo` `Service` which will have its latency measured and exposed on {{ site.operator_product_name }}'s `/metrics` endpoint. The Service allows us to run any shell command, which we'll use to add artificial latency later for testing purposes.

```yaml
echo '
apiVersion: v1
kind: Service
metadata:
  name: echo
  namespace: default
spec:
  ports:
    - protocol: TCP
      name: http
      port: 80
      targetPort: http
  selector:
    app: echo
---
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: echo
  name: echo
  namespace: default
spec:
  replicas: 1
  selector:
    matchLabels:
      app: echo
  template:
    metadata:
      labels:
        app: echo
    spec:
      containers:
        - name: echo
          image: registry.k8s.io/e2e-test-images/agnhost:2.40
          command:
            - /agnhost
            - netexec
            - --http-port=8080
          ports:
            - containerPort: 8080
              name: http
          env:
            - name: NODE_NAME
              valueFrom:
                fieldRef:
                  fieldPath: spec.nodeName
            - name: POD_NAME
              valueFrom:
                fieldRef:
                  fieldPath: metadata.name
            - name: NAMESPACE
              valueFrom:
                fieldRef:
                  fieldPath: metadata.namespace
            - name: POD_IP
              valueFrom:
                fieldRef:
                  fieldPath: status.podIP' | kubectl apply -f -
```

Next, create a `DataPlaneMetricsExtension` that points to the `echo` Service, attach it to a `GatewayConfiguration` resource and deploy a `Gateway` with a `HTTPRoute` so that we can make a HTTP request to the Service.

```yaml
echo '
kind: DataPlaneMetricsExtension
apiVersion: gateway-operator.konghq.com/v1alpha1
metadata:
  name: kong
  namespace: default
spec:
  serviceSelector:
    matchNames:
    - name: echo
  config:
    latency: true
---
kind: GatewayConfiguration
apiVersion: gateway-operator.konghq.com/v1beta1
metadata:
  name: kong
  namespace: default
spec:
  dataPlaneOptions:
    deployment:
      replicas: 1
      podTemplateSpec:
        spec:
          containers:
          - name: proxy
            image: kong/kong-gateway:{{ site.data.kong_latest_gateway.ee-version }}
  controlPlaneOptions:
    deployment:
      podTemplateSpec:
        spec:
          containers:
          - name: controller
    extensions:
    - kind: DataPlaneMetricsExtension
      group: gateway-operator.konghq.com
      name: kong
---
kind: GatewayClass
apiVersion: gateway.networking.k8s.io/{{ gatewayApiVersion }}
metadata:
  name: kong
spec:
  controllerName: konghq.com/gateway-operator
  parametersRef:
    group: gateway-operator.konghq.com
    kind: GatewayConfiguration
    name: kong
    namespace: default
---
kind: Gateway
apiVersion: gateway.networking.k8s.io/{{ gatewayApiVersion }}
metadata:
  name: kong
  namespace: default
spec:
  gatewayClassName: kong
  listeners:
  - name: http
    protocol: HTTP
    port: 80
---
apiVersion: gateway.networking.k8s.io/{{ gatewayApiVersion }}
kind: HTTPRoute
metadata:
  name: httproute-echo
  namespace: default
  annotations:
    konghq.com/strip-path: "true"
spec:
  parentRefs:
  - name: kong
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /echo
    backendRefs:
    - name: echo
      kind: Service
      port: 80 ' | kubectl apply -f -
```