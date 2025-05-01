---
title: mTLS
description: "Configure the {{ site.kic_product_name }} to verify client certificates using CA certificates and mtls-auth plugin for HTTPS requests."
content_type: how_to

permalink: /kubernetes-ingress-controller/mtls/
breadcrumbs:
  - /kubernetes-ingress-controller/
  - index: kubernetes-ingress-controller
    section: How To
plugins:
  - mtls-auth
search_aliases:
  - kic mtls
products:
  - kic

tools:
  - kic

works_on:
  - on-prem
  - konnect
related_resources:
  - text: Support multiple authentication methods
    url: /kubernetes-ingress-controller/multiple-auth-methods/
entities: []

tldr:
  q: How do I enforce mTLS from a client to {{ site.base_gateway }} using {{ site.kic_product_name }}?
  a: Create a Secret containing a CA Certificate and pass the ID of the certificate to an mTLS plugin configuration.

prereqs:
  enterprise: true
  kubernetes:
    gateway_api: true
  entities:
    services:
      - echo-service
    routes:
      - echo

cleanup:
  inline:
    - title: Uninstall KIC from your cluster
      include_content: cleanup/products/kic
      icon_url: /assets/icons/kubernetes.svg
---

## About mTLS

Mutual TLS (mTLS) is a way to secure connectivity using certificates. {{ site.base_gateway }} can look for a certificate in incoming requests and reject the request if the public key presented does not match the private key stored in {{ site.base_gateway }}.

## Generate a CA certificate

To use the `mtls-auth` plugin you need a CA certificate. If you don't have one, generate a new certificate using `openssl`:

```bash
openssl req -x509 -newkey rsa:4096 -keyout key.pem -out cert.pem -sha256 -days 365 -nodes \
-subj "/C=US/ST=California/L=San Francisco/O=Kong/OU=Org/CN=www.example.com"
```

## Add the Certificate to {{ site.base_gateway }}

CA Certificates in {{site.base_gateway}} are provisioned by creating a `Secret` or `ConfigMap` resource in Kubernetes.

Resources holding CA certificates must have the following properties:
- The `konghq.com/ca-cert: "true"` label applied
- A `cert` or `ca.crt` data property which contains a valid CA certificate in PEM format
- A `kubernetes.io/ingress.class` annotation whose value matches the value of the controller's `--ingress-class` argument. By default, that value is `kong`.
- An `id` data property which contains a random UUID

Each CA Certificate that you create needs a unique ID. Any random UUID should suffice here, and it doesn't have a security implication. You can use [uuidgen](https://linux.die.net/man/1/uuidgen) (Linux, macOS) or [New-Guid](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/new-guid) (Windows) to generate an ID.

```bash
CERT_ID=$(uuidgen | tr "[:upper:]" "[:lower:]")
kubectl create secret -n kong generic my-ca-cert --from-literal=id=$CERT_ID --from-file=cert=./cert.pem
kubectl label secret -n kong my-ca-cert 'konghq.com/ca-cert=true'
kubectl annotate secret -n kong my-ca-cert 'kubernetes.io/ingress.class=kong'
```

## Configure the mtls-auth plugin

The [mtls-auth plugin](/plugins/mtls-auth/) requires a CA Certificate ID that will be used to validate the Certificate in the incoming request. In this example we disable revocation checks, but you should enable checks in a production setting.

{% entity_example %}
type: plugin
data:
  name: mtls-auth
  config:
    ca_certificates:
    - $CERT_ID
    skip_consumer_lookup: true
    revocation_check_mode: SKIP

  service: echo
{% endentity_example %}

## Validate your configuration

At this point, {{ site.base_gateway }} will reject requests that do not contain a client certificate.

1. Send a request to check {{site.base_gateway}} prompts for a client certificate:

{% validation request-check %}
url: /echo
status_code: 401
message: No required TLS certificate was sent
on_prem_url: $PROXY_IP
konnect_url: $PROXY_IP
indent: 4
{% endvalidation %}

    As you can see, {{ site.base_gateway }} is restricting the request because it doesn't have the necessary authentication information.

   Two things to note here:
   - `-k` is used because {{ site.base_gateway }} is set up to serve a self-signed certificate by default. For full mutual authentication in production use cases, you must configure {{ site.base_gateway }} to serve a Certificate that is signed by a trusted CA.
   - For some deployments `$PROXY_IP` might contain a port that points to `http` port of {{ site.base_gateway }}. In others, it might contain a DNS name instead of an IP address. If needed, update the command to send an `https` request to the `https` port of {{ site.base_gateway }} or the load balancer in front of it.

1. Use the key and Certificate to authenticate against {{ site.base_gateway }} and use the Service:

{% validation request-check %}
url: /echo
mtls: true
status_code: 401
on_prem_url: $PROXY_IP
konnect_url: $PROXY_IP
indent: 4
{% endvalidation %}

    The results should look like this:

    ```text
    HTTP/2 200
    content-type: text/plain; charset=UTF-8
    server: echoserver
    x-kong-upstream-latency: 1
    x-kong-proxy-latency: 1
    via: kong/x.y.z
    ```