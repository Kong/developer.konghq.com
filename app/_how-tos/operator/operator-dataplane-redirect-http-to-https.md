---
title: Redirect HTTP traffic to HTTPS
description: "Learn how to redirect HTTP requests to HTTPS with a custom status code using the konghq.com/https-redirect-status-code annotation on an HTTPRoute."
content_type: how_to

permalink: /operator/dataplanes/how-to/redirect-http-to-https/
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

min_version:
  operator: '2.4'

prereqs:
  operator:
    konnect:
      auth: true
      control_plane: true

tldr:
  q: How do I redirect HTTP requests to HTTPS with {{ site.operator_product_name }}?
  a: |
    Attach an `HTTPRoute` to the `HTTPS` listener only, and annotate it with `konghq.com/https-redirect-status-code: "301"`. {{ site.base_gateway }} answers plain HTTP requests that match the Route with a redirect to the HTTPS URL.

related_resources:
  - text: Route annotations reference
    url: /operator/dataplanes/reference/route-annotations/
  - text: Proxy HTTPS traffic with TLS termination
    url: /operator/dataplanes/how-to/tls-termination/
---

By default, when a Route accepts only HTTPS, {{site.base_gateway}} answers plain HTTP requests that match the Route with a `426 Upgrade Required` status code. Use the `konghq.com/https-redirect-status-code` annotation to return a redirect status code such as `301` instead.

{% include k8s/kong-namespace.md %}
{: data-deployment-topology="on-prem"}

## Create a certificate

1. Create a self-signed certificate:

   ```sh
   openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout tls.key -out tls.crt -subj "/CN=demo.example.com"
   ```

1. Create a Kubernetes Secret containing the certificate and key, and label it so {{ site.operator_product_name }} can use it:

   ```sh
   kubectl create secret tls my-certificate -n kong --cert=tls.crt --key=tls.key
   kubectl label secret my-certificate -n kong konghq.com/secret="true"
   ```

## Create Gateway resources

Create a `Gateway` with an `HTTP` listener on port 80 and an `HTTPS` listener on port 443:

```sh
echo '
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
  name: kong
  namespace: kong
spec:
  gatewayClassName: gateway-class
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

## Create a Service and a Route

1. Create a sample echo Service:

   ```sh
   kubectl apply -f https://developer.konghq.com/manifests/kic/echo-service.yaml -n kong
   ```

1. Create an `HTTPRoute` bound to the `https` listener only. Add the `konghq.com/https-redirect-status-code` annotation:

   ```sh
   echo '
   apiVersion: gateway.networking.k8s.io/v1
   kind: HTTPRoute
   metadata:
     name: echo-route
     namespace: kong
     annotations:
       konghq.com/https-redirect-status-code: "301"
   spec:
     parentRefs:
       - name: kong
         sectionName: https
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

1. Get the Gateway's external IP address:

   ```sh
   export PROXY_IP=$(kubectl get gateway kong -n kong -o jsonpath='{.status.addresses[0].value}')
   ```

1. Send an HTTP request to the Route:

   ```sh
   curl -i --resolve demo.example.com:80:$PROXY_IP http://demo.example.com/echo
   ```

   {{site.base_gateway}} returns a `301` response with a `Location` header that points to the HTTPS URL:

   ```text
   HTTP/1.1 301 Moved Permanently
   Location: https://demo.example.com/echo
   ```
   {:.no-copy-code}

1. Send an HTTPS request to the Route:

   ```sh
   curl -ik --resolve demo.example.com:443:$PROXY_IP https://demo.example.com/echo
   ```

   The request succeeds and returns a `200` response.
