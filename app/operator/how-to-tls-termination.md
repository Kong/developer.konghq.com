---
title: Proxy HTTPS traffic with TLS termination
description: "Learn how to configure HTTPS listeners and TLS termination for {{ site.operator_product_name }}."
content_type: how_to

permalink: /operator/dataplanes/how-to/tls-termination/
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

## Overview

Configuring TLS termination at the Gateway level allows {{ site.operator_product_name }} to manage SSL/TLS certificates and decrypt incoming traffic before it reaches your services. This guide shows how to set up an HTTPS listener using the standard Kubernetes Gateway API.

## Prerequisites

- A Kubernetes cluster with {{ site.operator_product_name }} installed.
- A TLS certificate and private key stored in a Kubernetes `Secret`.

## Configuration

To enable TLS termination, you must configure a `Gateway` with an `HTTPS` listener and reference the TLS `Secret`.

### 1. Configure the Gateway with an HTTPS Listener

Create or update your `Gateway` resource to include a listener on port 443 with the `HTTPS` protocol.

```yaml
---
apiVersion: gateway-operator.konghq.com/v2beta1
kind: GatewayConfiguration
metadata:
  name: kong-gateway-configuration
  namespace: kong
spec:
  dataPlaneOptions:
    deployment:
      podTemplateSpec:
        spec:
          containers:
            - image: kong/kong-gateway:3.12
              name: proxy
---
apiVersion: gateway.networking.k8s.io/v1
kind: GatewayClass
metadata:
  name: kong-tls
spec:
  controllerName: konghq.com/gateway-operator
  parametersRef:
    group: gateway-operator.konghq.com
    kind: GatewayConfiguration
    name: kong-gateway-configuration
    namespace: kong
---
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: kong-tls-gateway
  namespace: kong
spec:
  gatewayClassName: kong-tls
  listeners:
    - name: http
      port: 80
      protocol: HTTP
    - name: https
      port: 443
      protocol: HTTPS
      hostname: demo.example.com
      tls:
        mode: Terminate
        certificateRefs:
          - group: ""
            kind: Secret
            name: demo.example.com
```

### 2. Label the Secret

The {{ site.operator_product_name }} requires a specific label on secrets to recognize them for use in Gateways. Label the secret created in the step above:

```bash
kubectl label secret demo.example.com -n kong konghq.com/secret="true"
```

{% tip %}
For more information on how the Operator handles secrets, please refer to [Secrets and Credentials Reference](/operator/reference/secrets-and-credentials)
{% endtip %}


### 3. Deploy a Route

Create an `HTTPRoute` to forward traffic to your service.

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: echo-route
  namespace: kong
spec:
  parentRefs:
    - name: kong-tls-gateway
  hostnames:
    - demo.example.com
  rules:
    - matches:
        - path:
            type: PathPrefix
            value: /echo
      backendRefs:
        - name: echo
          kind: Service
          port: 1027
```

Deploy an echo service to test the communication with a service:

```bash
kubectl apply -f https://developer.konghq.com/manifests/kic/echo-service.yaml -n kong
```

## Verify the Setup

1.  Check the status of the `Gateway` to ensure the listeners are programmed:

    ```bash
    kubectl get gateway kong-tls-gateway -n kong -o yaml
    ```

2.  Test the HTTPS endpoint (assuming you have access to the Gateway's external IP):

    ```bash
    # Get the Gateway IP
    GATEWAY_IP=$(kubectl get gateway kong-tls-gateway -n kong -o jsonpath='{.status.addresses[0].value}')

    # Test the connection
    curl -ivk --resolve demo.example.com:443:$GATEWAY_IP https://demo.example.com/echo
    ```
