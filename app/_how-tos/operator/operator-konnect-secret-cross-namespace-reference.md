---
title: Reference Secrets across multiple namespaces with {{ site.operator_product_name }}
description: "Learn how to use the ReferenceGrant and KongReferenceGrant resources to reference a Secret across namespaces."
content_type: how_to

permalink: /operator/konnect/how-to/secret-cross-namespace-reference/
breadcrumbs:
  - /operator/
  - index: operator
    group: Konnect

products:
  - operator

works_on:
  - konnect
  - on-prem

tldr:
  q: How do I reference a Secret from a different namespace?
  a: Use a `ReferenceGrant` for Gateway API resources or a `KongReferenceGrant` for Kong-specific resources in the same namespace as the Secret to authorize references from the source namespace.

related_resources:
  - text: Reference {{site.konnect_short_name}} authentication across multiple namespaces
    url: /operator/konnect/how-to/auth-cross-namespace-reference/

min_version:
  operator: '2.1'
---

{% include /operator/cross-namespace-ref.md %}

This example demonstrates using both `ReferenceGrant` and `KongReferenceGrant` to allow a `Gateway` in the `kong` namespace to reference a TLS `Secret` in the `secret-ns` namespace.

## Create a certificate

Run the following command to create a self-signed certificate:

```sh
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout tls.key -out tls.crt -subj "/CN=example.localdomain.dev"
```

## Create a Secret

Run the following command to create a `secret-ns` namespace and a `Secret` resource containing the TLS certificate and key in that namespace:

```sh
echo "
apiVersion: v1
kind: Namespace
metadata:
  name: secret-ns
---
apiVersion: v1
kind: Secret
metadata:
  name: example-tls-secret
  namespace: secret-ns
  labels:
    konghq.com/secret: 'true'
type: kubernetes.io/tls
data:
  tls.crt: "$(cat tls.crt | base64)"
  tls.key: "$(cat tls.key | base64)"" | kubectl apply -f - 
```

## Create a ReferenceGrant and a KongReferenceGrant

Create the following resources:
* A `ReferenceGrant` to allow standard Gateway API resources in other namespaces to access the Secret. In this example, we'll grant access to `Gateway` resources in the `kong` namespace.
* A `KongReferenceGrant` to allow Kong-specific resources in other namespaces to access the Secret. In this example, we'll grant access to `KongCertificate` resources in the `kong` namespace.

```sh
echo '
apiVersion: gateway.networking.k8s.io/v1beta1
kind: ReferenceGrant
metadata:
  name: allow-gateway-to-secret
  namespace: secret-ns
spec:
  from:
    - group: gateway.networking.k8s.io
      kind: Gateway
      namespace: kong
  to:
    - group: ""
      kind: Secret
---
apiVersion: configuration.konghq.com/v1alpha1
kind: KongReferenceGrant
metadata:
  name: allow-kong-to-secret
  namespace: secret-ns
spec:
  from:
    - group: configuration.konghq.com
      kind: KongCertificate
      namespace: kong
  to:
    - group: core
      kind: Secret' | kubectl apply -f -
```

## Configure the Gateway


Create the following resources:
* A `kong` namespace.
* A `GatewayConfiguration` and a `GatewayClass` to configure your gateway with the latest {{site.base_gateway}} version and {{site.operator_product_name}} as the controller.
* A `Gateway` that references the `Secret` in the `secret-ns` namespace.

```sh
echo '
apiVersion: v1
kind: Namespace
metadata:
  name: kong
---
apiVersion: gateway-operator.konghq.com/v2beta1
kind: GatewayConfiguration
metadata:
  name: gateway-configuration
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
  name: gateway-class
spec:
  controllerName: konghq.com/gateway-operator
  parametersRef:
    group: gateway-operator.konghq.com
    kind: GatewayConfiguration
    name: gateway-configuration
    namespace: kong
---
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: kong-gateway
  namespace: kong
spec:
  gatewayClassName: gateway-class
  listeners:
    - name: https
      port: 443
      protocol: HTTPS
      hostname: example.localdomain.dev
      tls:
        mode: Terminate
        certificateRefs:
          - group: ""
            kind: Secret
            name: example-tls-secret
            namespace: secret-ns' | kubectl apply -f -
```

## Create a Service and a Route

1. Run the following command to create a sample echo Service:
   ```bash
   kubectl apply -f https://developer.konghq.com/manifests/kic/echo-service.yaml -n kong
   ```

1. Deploy a sample `HTTPRoute` to verify that TLS termination is working:

   ```sh
   echo '
   apiVersion: gateway.networking.k8s.io/v1
   kind: HTTPRoute
   metadata:
     name: echo-route
     namespace: kong
   spec:
     parentRefs:
       - name: kong-gateway
     hostnames:
       - example.localdomain.dev
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

1. Get the Gateway's external IP:
   
   ```bash
   export PROXY_IP=$(kubectl get gateway kong-gateway -n kong -o jsonpath='{.status.addresses[0].value}')
   ```

1.  Test the connection:

    ```bash
    curl -ivk --resolve example.localdomain.dev:443:$PROXY_IP https://example.localdomain.dev/echo
    ```

    You should get TLS handshake and a 200 response.