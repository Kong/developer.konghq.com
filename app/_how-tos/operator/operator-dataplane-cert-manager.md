---
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

{% include /k8s/kong-namespace.md %}

## Install {{site.operator_product_name}} with cert-manager enabled

1. Add the Kong Helm charts:

   ```sh
   helm repo add kong https://charts.konghq.com
   helm repo update
   ```

1. Install [cert-manager](https://cert-manager.io/) on your cluster:

   ```sh
   kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.14.2/cert-manager.yaml
   ```

1. Install {{ site.operator_product_name }} using Helm:

   ```bash
   helm upgrade --install kong-operator kong/kong-operator -n kong-system \
     --create-namespace \
     --set image.tag={{ site.data.operator_latest.release }} \
     --set global.webhooks.options.certManager.enabled=true
   ```
   {: data-deployment-topology="on-prem" }


   ```bash
   helm upgrade --install kong-operator kong/kong-operator -n kong-system \
     --create-namespace \
     --set image.tag={{ site.data.operator_latest.release }} \
     --set global.webhooks.options.certManager.enabled=true \
     --set env.ENABLE_CONTROLLER_KONNECT=true
   ```
   {: data-deployment-topology="konnect" }

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

Create the following resources:

* A `GatewayConfiguration` and a `GatewayClass` to configure your gateway with the latest {{site.base_gateway}} version and {{site.operator_product_name}} as the controller.
* A `Gateway` with the `cert-manager.io/issuer: "selfsigned-issuer"` annotation and the `tls.certificateRefs` pointing to the name of the Secret to provision.
* A `Certificate` that references the cert-manager issuer and the provisioned Secret.

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
    - name: kong-gateway
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

1.  Check that cert-manager has created the `Certificate` resource and that the `Secret` has been provisioned:

    ```bash
    kubectl get certificate -n kong
    kubectl get secret example-tls-secret -n kong
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