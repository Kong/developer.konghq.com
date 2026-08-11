---
title: Rotate TLS certificates without restarting {{site.base_gateway}}
short_title: Rotate TLS certificates
description: "Let cert-manager rotate a TLS certificate and have {{site.base_gateway}} serve it without a reload or a pod restart."
content_type: how_to

permalink: /kubernetes-ingress-controller/routing/rotate-tls-certificates/
breadcrumbs:
  - /kubernetes-ingress-controller/
  - index: kubernetes-ingress-controller
    section: Routing

products:
  - kic

works_on:
  - on-prem
  - konnect

entities: []

tags:
  - certificates
  - cert-manager
  - tls

tldr:
  q: How do I get {{site.base_gateway}} to serve a certificate that cert-manager rotated?
  a: |
    Reference the cert-manager `Secret` from a `Gateway` listener.
    {{site.kic_product_name}} converts the Secret into [Certificate](/gateway/entities/certificate/) and [SNI](/gateway/entities/sni/) entities and pushes them to {{site.base_gateway}} over the Admin API on every renewal, so the new certificate is served without a reload or a pod restart.
    Certificates configured in `kong.conf`, such as `ssl_cert`, behave differently: they're read once at startup and need a restart.

faqs:
  - q: How do I check whether my deployment uses certificates that don't rotate this way?
    a: |
      Certificates set through `kong.conf` are read once at startup, so they don't follow the rotation described here. Check whether your {{site.base_gateway}} pods set any of them:

      ```bash
      kubectl get pods -n kong -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{range .spec.containers[*].env[*]}{"  "}{.name}{"="}{.value}{"\n"}{end}{end}' | grep -i "ssl_cert\|cluster_cert"
      ```

      If the command returns nothing, every certificate in your deployment rotates automatically. If it returns a proxy certificate, move it out of `ssl_cert` and onto a `Gateway` listener as shown in this guide. For the rest, rotation requires the pods to be replaced: see [Restart {{site.base_gateway}} on Kubernetes](/how-to/restart-kong-gateway-kubernetes/), or [Restart {{site.base_gateway}} when a mounted certificate changes](/how-to/rotate-kong-conf-certificates-with-reloader/) to automate it.

      For the full list of parameters that behave this way and why, see [When certificates are loaded and reloaded](/gateway/ssl-certificates/#when-certificates-are-loaded-and-reloaded).

prereqs:
  kubernetes:
    gateway_api: true
  entities:
    services:
      - echo-service
  inline:
    - title: Install cert-manager
      include_content: prereqs/cert-manager

related_resources:
  - text: Proxy HTTPS traffic with TLS termination
    url: /kubernetes-ingress-controller/routing/https-tls-termination/
  - text: Automate TLS certificate provisioning and rotation with cert-manager
    url: /operator/dataplanes/how-to/cert-manager/
  - text: Restart {{site.base_gateway}} when a mounted certificate changes
    url: /how-to/rotate-kong-conf-certificates-with-reloader/
  - text: Using SSL certificates in {{site.base_gateway}}
    url: /gateway/ssl-certificates/
  - text: Certificate entity
    url: /gateway/entities/certificate/
  - text: SNI entity
    url: /gateway/entities/sni/

cleanup:
  inline:
    - title: Delete the certificate resources
      icon_url: /assets/icons/key.svg
      content: |
        ```bash
        kubectl delete httproute echo -n kong
        kubectl delete certificate demo.example.com -n kong
        kubectl delete issuer selfsigned-issuer -n kong
        kubectl delete secret demo.example.com -n kong --ignore-not-found
        ```
    - title: Uninstall {{site.kic_product_name}} from your cluster
      include_content: cleanup/products/kic
      icon_url: /assets/icons/kubernetes.svg
    - title: Uninstall cert-manager
      include_content: cleanup/third-party/cert-manager
      icon_url: /assets/icons/kubernetes.svg

automated_tests: false
---

[cert-manager](https://cert-manager.io/) renews certificates and writes the new key pair to a Kubernetes Secret. Whether {{site.base_gateway}} starts serving that new certificate depends on how the certificate reached the proxy in the first place.

In this guide, we'll issue a certificate with cert-manager, serve it from a `Gateway` listener, force a renewal, and confirm that {{site.base_gateway}} picks up the new certificate without restarting.

Referencing a Secret from a `Gateway` listener is what makes rotation automatic: {{site.kic_product_name}} watches the Secret and converts it into [Certificate](/gateway/entities/certificate/) and [SNI](/gateway/entities/sni/) entities, which {{site.base_gateway}} re-reads on every configuration update. Certificates set through `kong.conf` behave differently. For more information, see [When certificates are loaded and reloaded](/gateway/ssl-certificates/#when-certificates-are-loaded-and-reloaded).

## Create a cert-manager Issuer

{% include /k8s/cert-manager-selfsigned-issuer.md namespace='kong' %}

## Issue a certificate

Create a `Certificate` for the `demo.example.com` hostname. cert-manager writes the key pair to a Secret named `demo.example.com` and renews it automatically before it expires:

```bash
echo '
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: demo.example.com
  namespace: kong
spec:
  secretName: demo.example.com
  duration: 24h
  renewBefore: 12h
  issuerRef:
    name: selfsigned-issuer
    kind: Issuer
  dnsNames:
    - demo.example.com' | kubectl apply -f -
```

Wait for cert-manager to issue the certificate and confirm that the Secret exists:

```bash
kubectl wait --for=condition=Ready certificate/demo.example.com -n kong --timeout=90s
kubectl get secret demo.example.com -n kong
```

You should see the Secret listed with three keys:

```
NAME               TYPE                DATA   AGE
demo.example.com   kubernetes.io/tls   3      5s
```
{:.no-copy-code}

The three keys are `tls.crt`, `tls.key`, and `ca.crt`.

## Add an HTTPS listener that references the Secret

Add a TLS listener to the `Gateway` and point `certificateRefs` at the cert-manager Secret:

```bash
kubectl patch -n kong --type=json gateway kong -p='[
    {
        "op":"add",
        "path":"/spec/listeners/-",
        "value":{
            "name": "https",
            "port": 443,
            "protocol": "HTTPS",
            "hostname": "demo.example.com",
            "allowedRoutes": {
              "namespaces": {
                "from": "All"
              }
            },
            "tls": {
              "mode": "Terminate",
              "certificateRefs":[{
                "group": "",
                "kind": "Secret",
                "name": "demo.example.com"
              }]
            }
        }
    }
]'
```

{{site.kic_product_name}} now watches `demo.example.com` and re-syncs the Certificate entity every time cert-manager writes to it.

## Route traffic through the listener

Create an `HTTPRoute` that attaches to the `https` listener and sends requests to the `echo` Service we created as a [prerequisite](#required-kubernetes-resources):

<!--vale off-->
{% httproute %}
name: echo
matches:
  - path: /echo
    service: echo
    port: 1027
hostname: demo.example.com
section_name: https
{% endhttproute %}
<!--vale on-->

{% validation kubernetes-wait-for %}
kind: httproute
resource: echo
{% endvalidation %}

## Record the certificate currently being served

1. Check the certificate that {{site.base_gateway}} presents for `demo.example.com`, and note the serial number and validity dates:

   ```bash
   echo "" | openssl s_client -connect $PROXY_IP:443 -servername demo.example.com 2>/dev/null \
     | openssl x509 -noout -serial -dates -ext subjectAltName
   ```

   The output should look like this:

   ```
   serial=5B2C9A1E7F04D8B3A6E1C0F29D3847BA
   notBefore=Aug  7 10:12:04 2026 GMT
   notAfter=Aug  8 10:12:04 2026 GMT
   X509v3 Subject Alternative Name: critical
       DNS:demo.example.com
   ```
   {:.no-copy-code}

1. Note how long the {{site.base_gateway}} pods have been running, so we can check later that they didn't restart:

   ```bash
   kubectl get pods -n kong
   ```

## Rotate the certificate

Force cert-manager to issue a new certificate ahead of schedule by deleting the Secret. cert-manager detects that the `Certificate` no longer has a valid Secret and immediately reissues it:

```bash
kubectl delete secret demo.example.com -n kong
kubectl wait --for=condition=Ready certificate/demo.example.com -n kong --timeout=90s
```

## Validate the rotation

1. Query the proxy again:

   ```bash
   echo "" | openssl s_client -connect $PROXY_IP:443 -servername demo.example.com 2>/dev/null \
     | openssl x509 -noout -serial -dates -ext subjectAltName
   ```

   The serial number and the validity dates should have changed:

   ```
   serial=91F4D07C3A5B8E26D14903BC7E85A2FD
   notBefore=Aug  7 10:19:41 2026 GMT
   notAfter=Aug  8 10:19:41 2026 GMT
   X509v3 Subject Alternative Name: critical
       DNS:demo.example.com
   ```
   {:.no-copy-code}

1. Confirm that no pod restarted:

   ```bash
   kubectl get pods -n kong
   ```

   The value of the `RESTARTS` column should still be `0`.

1. Confirm that traffic was never interrupted:

   ```bash
   curl -sk --resolve demo.example.com:443:$PROXY_IP https://demo.example.com/echo -o /dev/null -w "%{http_code}\n"
   ```

   The response should be `200`.
