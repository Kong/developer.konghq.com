---
# @TODO KO 2.1
title: Automate TLS certificates with cert-manager
description: "Learn how to use cert-manager to automatically provision and rotate TLS certificates for {{ site.operator_product_name }}."
content_type: how_to

permalink: /operator/dataplanes/how-to/cert-manager/
breadcrumbs:
  - /operator/
  - index: operator
    group: Gateway Deployment
  - index: operator
    group: Gateway Deployment
    section: "How-To"

products:
  - operator

prereqs:
  skip_product: true

works_on:
  - on-prem
  - konnect

tldr:
  q: How do I automate TLS certificates with {{ site.operator_product_name }}?
  a: Annotate your `Gateway` with `cert-manager.io/issuer` and reference the resulting `Secret` in your `Gateway` listeners.

---

Integrating {{ site.operator_product_name }} with [cert-manager](https://cert-manager.io/) allows you to automatically provision and rotate TLS certificates for your Gateway listeners. This integration follows the standard Kubernetes Gateway API pattern.

When you annotate a `Gateway` resource with a cert-manager issuer, cert-manager automatically creates a `Certificate` and a corresponding `Secret` containing the TLS key pair. The Operator then configures the managed Data Planes to use this secret for TLS termination.

## Install {{site.operator_product_name}} with cert-manager enabled

1. Add the Kong Helm charts:

   ```sh
   helm repo add kong https://charts.konghq.com
   helm repo update
   ```

1. Install [cert-manager](https://cert-manager.io/) on your cluster:

   ```sh
   kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.19.2/cert-manager.yaml
   ```

1. Install {{ site.operator_product_name }} using Helm:

   ```bash
   helm upgrade --install kong-operator kong/kong-operator -n kong-system \
     --create-namespace \
     --set image.tag={{ site.data.operator_latest.release }} \
     --set global.webhooks.options.certManager.enabled=true
   ```
   {:.data-deployment-topology="on-prem"}


   ```bash
   helm upgrade --install kong-operator kong/kong-operator -n kong-system \
     --create-namespace \
     --set image.tag={{ site.data.operator_latest.release }} \
     --set global.webhooks.options.certManager.enabled=true \
     --set env.ENABLE_CONTROLLER_KONNECT=true
   ```
   {:.data-deployment-topology="konnect"}

1. Create the `kong` namespace:
   ```sh
   kubectl create namespace kong

## Create a cert-manager issuer

The cert-manager `Issuer` resource represents a certificate authority. For more information, see the [cert-manager documentation](https://cert-manager.io/docs/configuration/).

```yaml
echo '
apiVersion: cert-manager.io/v1
kind: Issuer
metadata:
  name: selfsigned-issuer
  namespace: kong
spec:
  selfSigned: {}' | kubectl apply -f -
```

{:.info}
> In this example, we're using a simple self-signed issuer. In a production environment, you would typically use an ACME issuer like Let's Encrypt, or a CA issuer.

## Configure the Gateway with cert-manager

Create a `Gateway` resource with the `cert-manager.io/issuer` annotation and specify the `tls.certificateRefs` pointing to the secret name you want cert-manager to manage.

```yaml
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
  name: kong-cert-manager
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
  name: kong-gateway
  namespace: kong
  annotations:
    cert-manager.io/issuer: "selfsigned-issuer"
spec:
  gatewayClassName: kong-cert-manager
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
---
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: example-tls-certificate
  namespace: kong
spec:
  secretName: example-tls-secret
  issuerRef:
    name: selfsigned-issuer
    kind: Issuer
  dnsNames:
    - example.localdomain.dev
  secretTemplate:
    labels:
      konghq.com/secret: "true"' | kubectl apply -f -
```

### 3. Deploy a Route

Deploy a sample `HTTPRoute` to verify that TLS termination is working.

```yaml
echo '
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: echo-route
  namespace: kong
spec:
  parentRefs:
    - name: kong-gateway
  rules:
    - matches:
        - path:
            type: PathPrefix
            value: /echo
      backendRefs:
        - name: echo
          kind: Service
          port: 80' | kubectl apply -f -
```

Deploy the standard echo service to test the route:

```bash
kubectl apply -f https://developer.konghq.com/manifests/kic/echo-service.yaml -n kong
```

## Verify the Setup

1.  Check that cert-manager has created the `Certificate` resource:

    ```bash
    kubectl get certificate -n kong
    ```

2.  Verify that the `Secret` has been provisioned:

    ```bash
    kubectl get secret example-tls-secret -n kong
    ```

3.  Test the connection (assuming you have access to the Gateway's external IP and have configured DNS or hosts for `example.localdomain.dev`):

    ```bash
    curl -ivk --resolve example.localdomain.dev:443:$GATEWAY_IP https://example.localdomain.dev/echo
    ```
