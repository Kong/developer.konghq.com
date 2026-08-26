---
title: Automate TLS certificate provisioning and rotation with cert-manager
short_title: Automate TLS certificates with cert-manager
description: "Learn how to use cert-manager to provision TLS certificates for {{ site.operator_product_name }} and rotate them without restarting {{site.base_gateway}}."
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
  inline:
    - title: Install cert-manager
      include_content: prereqs/cert-manager
      icon_url: /assets/icons/kubernetes.svg
      position: before
  operator:
    set:
      - global.webhooks.options.certManager.enabled=true
    skip_cert_manager: true
    konnect:
      auth: true
  enterprise: true


works_on:
  - on-prem
  - konnect

tags:
  - certificates
  - cert-manager
  - tls

tldr:
  q: How do I automate TLS certificates with {{ site.operator_product_name }}?
  a: |
    Annotate your `Gateway` with `cert-manager.io/issuer` and reference the resulting `Secret` in your `Gateway` listeners.
    Label the Secret with `konghq.com/secret: "true"` so {{ site.operator_product_name }} watches it.
    Listener certificates become [Certificate](/gateway/entities/certificate/) and [SNI](/gateway/entities/sni/) entities, so cert-manager renewals are served without a reload or a pod restart.

faqs:
  - q: How do I check whether my deployment uses certificates that don't rotate this way?
    a: |
      Certificates set through `kong.conf` are read once at startup, so they don't follow the rotation described here. Check whether your `GatewayConfiguration` overrides any of them:

      ```bash
      kubectl get gatewayconfiguration kong-gateway-configuration -n kong -o yaml | grep -i "ssl_cert\|cluster_cert"
      ```

      If the command returns nothing, every certificate in your deployment rotates automatically. If it returns a proxy certificate, remove the `ssl_cert` override and serve the certificate from a `Gateway` listener as shown in this guide.

      {{ site.operator_product_name }} provisions and rotates the clustering and Admin API certificates for the data planes it manages, so you don't need to handle those yourself.

      For the full list of parameters that behave this way and why, see [When certificates are loaded and reloaded](/gateway/ssl-certificates/#when-certificates-are-loaded-and-reloaded).

cleanup:
  inline:
    - title: Uninstall cert-manager
      include_content: cleanup/third-party/cert-manager
      icon_url: /assets/icons/kubernetes.svg
    - title: Uninstall {{site.operator_product_name}}
      icon_url: /assets/icons/kubernetes.svg
      content: |
        ```bash
        helm uninstall kong-operator -n kong-system
        kubectl delete namespace kong kong-system
        ```

related_resources:
  - text: Proxy HTTPS traffic with TLS termination
    url: /operator/dataplanes/how-to/tls-termination/
  - text: Kubernetes Secrets with {{site.operator_product_name}}
    url: /operator/reference/secrets/
  - text: Using SSL certificates in {{site.base_gateway}}
    url: /gateway/ssl-certificates/
  - text: Certificate entity
    url: /gateway/entities/certificate/
  - text: Restart {{site.base_gateway}} on Kubernetes
    url: /how-to/restart-kong-gateway-kubernetes/

---

Integrating {{ site.operator_product_name }} with [cert-manager](https://cert-manager.io/) allows you to automatically provision and rotate TLS certificates for your Gateway listeners. This integration follows the standard Kubernetes Gateway API pattern.

When you annotate a `Gateway` resource with a cert-manager issuer, cert-manager automatically creates a `Certificate` and a corresponding `Secret` containing the TLS key pair. The Operator then configures the managed data planes to use this secret for TLS termination.

Renewals are handled the same way. When cert-manager writes a new key pair to the Secret, {{ site.operator_product_name }} reconciles it and the data planes start serving the new certificate without a reload and without a pod restart. For more information, see [When certificates are loaded and reloaded](/gateway/ssl-certificates/#when-certificates-are-loaded-and-reloaded).

## Create a cert-manager issuer

{% include /k8s/cert-manager-selfsigned-issuer.md namespace='kong' %}

## Configure the Gateway with cert-manager

Create the following resources:

* A `GatewayConfiguration` and a `GatewayClass` to configure the gateway with the latest {{site.base_gateway}} version and {{site.operator_product_name}} as the controller.
* A `Gateway` with the `cert-manager.io/issuer: "selfsigned-issuer"` annotation and the `tls.certificateRefs` pointing to the name of the Secret to provision.
* A `Certificate` that references the cert-manager issuer and the provisioned Secret.

1. Create the `GatewayConfiguration`:

{% konnect %}
content: |
  Set `spec.konnect.authRef` to the `KonnectAPIAuthConfiguration` you created in the prerequisites. This attaches the data planes to {{site.konnect_short_name}}, which delivers the {{site.base_gateway}} license to them:

  ```sh
  echo '
  apiVersion: gateway-operator.konghq.com/{{ site.operator_gatewayconfiguration_api_version }}
  kind: GatewayConfiguration
  metadata:
    name: kong-gateway-configuration
    namespace: kong
  spec:
    konnect:
      authRef:
        name: konnect-api-auth
    dataPlaneOptions:
      deployment:
        podTemplateSpec:
          spec:
            containers:
              - image: kong/kong-gateway:{{ site.data.gateway_latest.release }}
                name: proxy' | kubectl apply -f -
  ```
indent: 3
{% endkonnect %}

{% on_prem %}
content: |
  ```sh
  echo '
  apiVersion: gateway-operator.konghq.com/{{ site.operator_gatewayconfiguration_api_version }}
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
                name: proxy' | kubectl apply -f -
  ```
indent: 3
{% endon_prem %}

1. Create the `GatewayClass`, `Gateway`, and `Certificate`:

   ```sh
   echo '
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

1. Create a sample echo Service:

   ```bash
   kubectl apply -f https://developer.konghq.com/manifests/kic/echo-service.yaml -n kong
   ```

1. Wait for it to be ready:

   ```bash
   kubectl wait --for=condition=ready pod -l app=echo -n kong --timeout=120s
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

Confirm that the certificate is provisioned and served, then that a renewal reaches the data planes without restarting them.

1. Check that cert-manager has created the `Certificate` resource and that the `Secret` has been provisioned:

   ```bash
   kubectl get certificate -n kong
   kubectl get secret example-tls-secret -n kong
   ```

1. Wait for the Gateway to be programmed, so that it has an address to connect to:

   ```bash
   kubectl wait --for=condition=Programmed gateway/kong-gateway -n kong --timeout=180s
   ```

1. Get the Gateway's external IP:

   ```bash
   export PROXY_IP=$(kubectl get gateway kong-gateway -n kong -o jsonpath='{.status.addresses[0].value}')
   echo $PROXY_IP
   ```

1. Test the connection:

   ```bash
   curl -ivk --resolve example.localdomain.dev:443:$PROXY_IP https://example.localdomain.dev/echo
   ```

   You should get a TLS handshake and a 200 response.

1. Check the serial number and validity dates of the certificate {{site.base_gateway}} is currently serving, so we can compare after a renewal:

   ```bash
   echo "" | openssl s_client -connect $PROXY_IP:443 -servername example.localdomain.dev 2>/dev/null \
     | openssl x509 -noout -serial -dates -ext subjectAltName
   ```

   The output should look like this:

   ```
   serial=5B2C9A1E7F04D8B3A6E1C0F29D3847BA
   notBefore=Aug  7 10:12:04 2026 GMT
   notAfter=Nov  5 10:12:04 2026 GMT
   X509v3 Subject Alternative Name: critical
       DNS:example.localdomain.dev
   ```
   {:.no-copy-code}

1. Check how long the data plane pods have been running, so we can compare afterwards:

   ```bash
   kubectl get pods -n kong
   ```

1. Force cert-manager to issue a new certificate ahead of schedule by deleting the Secret. cert-manager detects that the `Certificate` no longer has a valid Secret and reissues it immediately:

   ```bash
   kubectl delete secret example-tls-secret -n kong
   kubectl wait --for=condition=Ready certificate/example-tls-certificate -n kong --timeout=90s
   ```

1. Query the proxy again. The serial number and the validity dates should have changed:

   ```bash
   echo "" | openssl s_client -connect $PROXY_IP:443 -servername example.localdomain.dev 2>/dev/null \
     | openssl x509 -noout -serial -dates -ext subjectAltName
   ```

1. Confirm that no data plane pod restarted:

   ```bash
   kubectl get pods -n kong
   ```

   The value of the `RESTARTS` column should still be `0`.

1. Confirm that traffic was never interrupted:

   ```bash
   curl -sk --resolve example.localdomain.dev:443:$PROXY_IP https://example.localdomain.dev/echo -o /dev/null -w "%{http_code}\n"
   ```

   The response should be `200`.
