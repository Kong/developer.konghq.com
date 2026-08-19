---
title: Proxy gRPC traffic using GRPCRoute
description: "Learn how to configure GRPCRoute with {{ site.operator_product_name }} to route gRPC traffic secured with TLS."
content_type: how_to

permalink: /operator/dataplanes/how-to/grpcroute/
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
min_version:
  operator: '2.3'

tldr:
  q: How do I route gRPC traffic with {{ site.operator_product_name }}?
  a: Annotate the backend Service with `konghq.com/protocol=grpcs`, add an `HTTPS` listener to your `Gateway`, then create a `GRPCRoute` resource. {{ site.operator_product_name }} converts the `GRPCRoute` into a {{ site.base_gateway }} [Service](/gateway/entities/service/) and [Route](/gateway/entities/route/).

prereqs:
  enterprise: true
  inline:
    - title: gRPCurl installed
      include_content: prereqs/grpcurl
      icon_url: /assets/icons/code.svg

---

`GRPCRoute` is a Kubernetes Gateway API resource for routing gRPC traffic. This guide shows how to configure {{ site.operator_product_name }} to proxy gRPC traffic secured with TLS to a backend Service.

{% include k8s/kong-namespace.md %}

## Configure the Gateway

Create a `GatewayConfiguration`, `GatewayClass`, and `Gateway` with an `HTTP` listener:

```bash
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
  name: kong-grpc
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
  name: kong-grpc-gateway
  namespace: kong
spec:
  gatewayClassName: kong-grpc
  listeners:
    - name: http
      port: 80
      protocol: HTTP' | kubectl apply -f -
```

## Deploy a gRPC backend

Install the `grpcbin` Service, which implements a simple gRPC test API:

```bash
kubectl apply -f {{site.links.web}}/manifests/kic/grpcbin-service.yaml -n kong
```

## Annotate the Kubernetes Service

{{ site.base_gateway }} assumes Services are HTTP or HTTPS by default. Add the `konghq.com/protocol` annotation so {{ site.operator_product_name }} configures the backend Service as gRPC over TLS instead:

```bash
kubectl annotate service -n kong grpcbin 'konghq.com/protocol=grpcs'
```

## Generate a TLS certificate

{% include /k8s/create-certificate.md namespace='kong' hostname='example.com' cert_required=true %}

1. {{ site.operator_product_name }} only watches certificate Secrets that carry the `konghq.com/secret="true"` label. Add the label so {{ site.operator_product_name }} picks up the Secret you just created:

   ```bash
   kubectl label secret example.com -n kong konghq.com/secret="true"
   ```

## Route gRPC traffic

1. Re-apply the `kong-grpc-gateway` Gateway with an additional `HTTPS` listener for gRPC traffic:

   {:.warning}
   > **Warning**: Applying this Gateway replaces the listener list. Include every listener you want to keep.
   
   ```bash
   echo 'apiVersion: gateway.networking.k8s.io/v1
   kind: Gateway
   metadata:
     name: kong-grpc-gateway
     namespace: kong
   spec:
     gatewayClassName: kong-grpc
     listeners:
       - name: http
         port: 80
         protocol: HTTP
       - name: grpc
         port: 443
         protocol: HTTPS
         hostname: example.com
         tls:
           certificateRefs:
             - group: ""
               kind: Secret
               name: example.com' | kubectl apply -f -
   ```
   
1. Create a `GRPCRoute`:
   
   ```bash
   echo 'apiVersion: gateway.networking.k8s.io/v1
   kind: GRPCRoute
   metadata:
     name: grpcbin
     namespace: kong
   spec:
     parentRefs:
       - name: kong-grpc-gateway
         sectionName: grpc
     hostnames:
       - "example.com"
     rules:
       - backendRefs:
           - name: grpcbin
             port: 9001
   ' | kubectl apply -f -
   ```

This configuration instructs {{ site.base_gateway }} to forward gRPC requests for `example.com` on port `443` to the `grpcbin` Service on port `9001`.

## Validate

1. Wait for the Gateway to be programmed:

   ```bash
   kubectl wait gateway/kong-grpc-gateway -n kong \
     --for=condition=Programmed=True \
     --timeout=5m
   ```

1. Get the Gateway's external IP:

   ```bash
   export PROXY_IP=$(kubectl get gateway kong-grpc-gateway -n kong -o jsonpath='{.status.addresses[0].value}')
   echo $PROXY_IP
   ```

1. Call the `grpcbin` test service through the proxy:

   ```bash
   grpcurl -insecure -authority example.com \
     -d '{"greeting": "Kong"}' \
     $PROXY_IP:443 hello.HelloService.SayHello
   ```

   The results should look like this:

   ```json
   {
     "reply": "hello Kong"
   }
   ```
   {:.no-copy-code}
