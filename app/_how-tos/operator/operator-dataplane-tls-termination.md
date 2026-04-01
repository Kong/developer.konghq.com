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

prereqs:
  operator:
    konnect:
      auth: true
      control_plane: true

---

Configuring TLS termination at the Gateway level allows {{ site.operator_product_name }} to manage SSL/TLS certificates and decrypt incoming traffic before it reaches your services. This guide shows how to set up an HTTPS listener using the standard Kubernetes Gateway API.

{% include k8s/kong-namespace.md %}
{: data-depoloyment-topology="on-prem"}

## Create a certificate

1. Create a self-signed certificate:
   ```sh
   openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout tls.key -out tls.crt -subj "/CN=demo.example.com"
   ```

1. Create a Kubernetes secret containing the certificate and key:   
   ```sh
   echo "apiVersion: v1
   kind: Secret
   metadata:
     name: my-certificate
     namespace: kong
   type: kubernetes.io/tls
   data:
     tls.crt: "$(cat tls.crt | base64)"
     tls.key: "$(cat tls.key | base64)"" | kubectl apply -f - 
   ```

## Configure the Gateway

Create the following resources:

* A `GatewayConfiguration` and a `GatewayClass` to configure your gateway with the latest {{site.base_gateway}} version and {{site.operator_product_name}} as the controller.
* A `Gateway` with a listener on port 443 with the `HTTPS` protocol and a reference to the Secret we created.

```sh
echo '
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
            - image: kong/kong-gateway:{{ site.data.gateway_latest.release }}
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
            name: my-certificate' | kubectl apply -f - 
```

## Label the Secret

{{ site.operator_product_name }} requires a specific label on Secrets to recognize them for use in gateways:

```bash
kubectl label secret my-certificate -n kong konghq.com/secret="true"
```

For more information about how {{ site.operator_product_name }} handles secrets, see the [Secrets reference](/operator/reference/secrets).


## Create an echo Service

Run the following command to create a sample echo Service:

```bash
kubectl apply -f https://developer.konghq.com/manifests/kic/echo-service.yaml -n kong
```

## Create a Route

Deploy a sample `HTTPRoute` to verify that TLS termination is working:

```sh
echo '
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
          port: 1027' | kubectl apply -f - 
```

## Validate

1.  Check the status of the gateway to ensure the listeners are programmed:

    ```bash
    kubectl get gateway kong-tls-gateway -n kong -o jsonpath='{.status.listeners}'
    ```

1. Get the Gateway's external IP:
   
   ```bash
   export PROXY_IP=$(kubectl get gateway kong-gateway -n kong -o jsonpath='{.status.addresses[0].value}')
   ```

1.  Test the connection:

    ```bash
    curl -ivk --resolve example.localdomain.dev:443:$PROXY_IP https://example.localdomain.dev/echo
    ```

    You should get TLS handshake and a 200 response.
