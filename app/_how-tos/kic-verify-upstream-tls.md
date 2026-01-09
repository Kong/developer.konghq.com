---
title: Verify Upstream TLS
description: Learn how to configure {{ site.base_gateway }} to verify TLS certificates when connecting to upstream services.
content_type: how_to

min_version:
  kic: "3.4"

permalink: /kubernetes-ingress-controller/verify-upstream-tls/
breadcrumbs:
  - /kubernetes-ingress-controller/

products:
  - kic

works_on:
  - on-prem
  - konnect

tldr:
  q: How do I configure {{ site.base_gateway }} to verify TLS certificates when connecting to upstream services?
  a: You can configure {{ site.base_gateway }} to verify the certificate it presents by attaching a CA certificate to a Service. This guide shows how to achieve this using the `BackendTLSPolicy` (when using Gateway API) or using Kubernetes Service annotations (when using Ingress API).

prereqs:
  kubernetes:
    gateway_api: experimental
  entities:
    services:
      - echo-service

cleanup:
  inline:
    - title: Uninstall KIC from your cluster
      include_content: cleanup/products/kic
      icon_url: /assets/icons/kubernetes.svg
---

## Generate a CA Certificate

{{ site.base_gateway }} can validate the certificate chain to a specific depth. To showcase all the possible configurations, create a certificate chain with a root CA, an intermediate CA, and a leaf server certificate:

```bash
mkdir certs && cd certs
cd certs

openssl req -new -newkey rsa:2048 -nodes -keyout root.key -subj "/CN=root" -x509 -days 365 -out root.crt

openssl req -new -newkey rsa:2048 -nodes -keyout inter.key -subj "/CN=inter" -out inter.csr
openssl x509 -req -in inter.csr -CA root.crt -CAkey root.key -CAcreateserial -days 365 -out inter.crt -extfile <(echo "basicConstraints=CA:TRUE")

openssl req -new -newkey rsa:2048 -nodes -keyout leaf.key -subj "/CN=kong.example" -out leaf.csr
openssl x509 -req -in leaf.csr -CA inter.crt -CAkey inter.key -CAcreateserial -days 365 -out leaf.crt -extfile <(printf "subjectAltName=DNS:kong.example")

cat leaf.crt inter.crt > chain.crt

rm -f *.csr *.srl
cd ..
```

Running this script generates the following files in `certs` directory:

- `root.key`, `root.crt`: Root CA key and certificate
- `inter.key`, `inter.crt`: Intermediate CA key and certificate
- `leaf.key`, `leaf.crt`: Server key and certificate (valid for `kong.example` SAN)
- `chain.crt`: Server certificate chain

## Configure TLS on the echo service

As part of the [prerequisites](#prerequisites), you deployed the `echo` Service to your cluster. Let's configure it to serve HTTPS. Create a secret with the server key and the certificate chain (including the intermediate certificate and the leaf certificate).

1. Create a Kubernetes secret containing the certificate:

    ```bash
    kubectl create secret -n kong tls goecho-tls --key ./certs/leaf.key --cert ./certs/chain.crt
    ```

1. Patch the `echo` deployment to use the secret and serve HTTPS using it:

    ```bash
    kubectl patch -n kong deployment echo -p '{
      "spec": {
        "template": {
          "spec": {
            "containers": [
              {
                "name": "echo",
                "ports": [
                  {
                    "containerPort": 443
                  }
                ],
                "env": [
                  {
                    "name": "HTTPS_PORT",
                    "value": "443"
                  },
                  {
                    "name": "TLS_CERT_FILE",
                    "value": "/etc/tls/tls.crt"
                  },
                  {
                    "name": "TLS_KEY_FILE",
                    "value": "/etc/tls/tls.key"
                  }
                ],
                "volumeMounts": [
                  {
                    "mountPath": "/etc/tls",
                    "name": "tls"
                  }
                ]
              }
            ],
            "volumes": [
              {
                "name": "tls",
                "secret": {
                  "secretName": "goecho-tls"
                }
              }
            ]
          }
        }
      }
    }'
    ```

1. Patch the Service to use HTTPS by adding the `konghq.com/protocol: https` annotation and the `spec.ports` entry:

    ```bash
    kubectl patch -n kong service echo -p '{
      "metadata": {
        "annotations": {
          "konghq.com/protocol": "https"
        }
      },
      "spec": {
        "ports": [
          {
            "name": "https",
            "port": 443,
            "targetPort": 443
          }
        ]
      }
    }'
    ```

## Expose the echo Service

Now that the `echo` Service is serving an HTTPS endpoint, we need to expose it:

<!--vale off-->
{% httproute %}
name: echo
matches:
  - path: /echo
    service: echo
    port: 443
host: kong.example
{% endhttproute %}
<!--vale on-->

Verify connectivity by making an HTTP request to proxy. The Service serves HTTPS but {{ site.base_gateway }} initiates the connection and proxies it as HTTP in this case, so the request should be made over HTTP. The `Host` header  has to match the hostname of the Service.

{% validation request-check %}
url: /echo
headers:
  - 'Host: kong.example'
status_code: 200
on_prem_url: $PROXY_IP
konnect_url: $PROXY_IP
{% endvalidation %}

You should see a response similar to this:

```text
Welcome, you are connected to node orbstack.
Running on Pod echo-bd94b7dcc-qxs2b.
In namespace default.
With IP address 192.168.194.9.
Through HTTPS connection.
```
{:.no-copy-code}

That means the Service is up and running and {{ site.base_gateway }} connects to it successfully over HTTPS, _without verification_.

## Configure the root CA Certificate

Before enabling TLS verification, we need to add the root CA certificate to the {{ site.base_gateway }}'s CA certificates and associate it with the Service.

{% navtabs certificate %}
{% navtab "Gateway API" %}

{% navtabs ca_source %}
{% navtab "Secret" %}
{% include /k8s/verify-upstream-tls-ca.md ca_source_kind="Secret" %}
{% endnavtab %}
{% navtab "ConfigMap" %}
{% include /k8s/verify-upstream-tls-ca.md ca_source_kind="ConfigMap" %}
{% endnavtab %}
{% endnavtabs %}

The CA is already associated with the `Service` through `BackendTLSPolicy`'s `spec.validation.caCertificateRefs`.

{% endnavtab %}
{% navtab "Ingress" %}

{% navtabs ca_source %}
{% navtab "Secret" %}
{% include /k8s/verify-upstream-tls-ca.md ca_source_kind="Secret" associate_with_service=true %}
{% endnavtab %}
{% navtab "ConfigMap" %}
{% include /k8s/verify-upstream-tls-ca.md ca_source_kind="ConfigMap" associate_with_service=true %}
{% endnavtab %}
{% endnavtabs %}

{% endnavtab %}
{% endnavtabs %}

## Enable TLS verification

Update your Route to verify the certificate of the upstream service:

{% navtabs certificate %}
{% navtab "Gateway API" %}

Create a `BackendTLSPolicy` resource:
 
```bash
echo 'apiVersion: gateway.networking.k8s.io/v1alpha3
kind: BackendTLSPolicy
metadata:
  name: goecho-tls-policy
  namespace: kong
spec:
  options:
    tls-verify-depth: "1"
  targetRefs:
  - group: core
    kind: Service
    name: echo
  validation:
    caCertificateRefs:
    - group: core
      kind: Secret # or ConfigMap
      name: root-ca
    hostname: kong.example' | kubectl apply -f -
```
{% endnavtab %}
{% navtab "Ingress" %}

Annotate the Service with the `konghq.com/tls-verify` annotation:

```bash
kubectl annotate -n kong service echo konghq.com/tls-verify=true
```
{% endnavtab %}
{% endnavtabs %}

{{ site.base_gateway }} is now verifying the certificate of the upstream service and accepting the connection because the certificate is trusted.

## Configure verification depth

By default, {{ site.base_gateway }} verifies the certificate chain up to the root CA certificate with no depth limit.  You can configure the verification depth by annotating the service with the `konghq.com/tls-verify-depth` annotation.

To test, set the verification depth to 0 to not allow any intermediate certificates.

{% navtabs certificate %}
{% navtab "Gateway API" %}
```shell
kubectl patch -n kong backendtlspolicies.gateway.networking.k8s.io goecho-tls-policy --type merge -p='{
  "spec": {
    "options" : {
      "tls-verify-depth": "0"
    }
  }
}'
```
{% endnavtab %}
{% navtab "Ingress" %}
```shell
kubectl annotate -n kong --overwrite service echo konghq.com/tls-verify-depth=0
```

{% endnavtab %}
{% endnavtabs %}

Now, when you issue the same request as before, you should see an error stating that an invalid response was received from the upstream server.

{:.warning}
> By default, {{ site.base_gateway }} keeps upstream connections alive for 60 seconds ([`upstream_keepalive_idle_timeout`](/gateway/configuration/#upstream-keepalive-idle-timeout)).
> Due to this, you may need to wait for 60 seconds to see the TLS verification fail.
> To speed up the process, you can restart the {{ site.base_gateway }} pod.

{% validation request-check %}
url: /echo
headers:
  - 'Host: kong.example'
status_code: 200
on_prem_url: $PROXY_IP
konnect_url: $PROXY_IP
{% endvalidation %}

```text
{
  "message":"An invalid response was received from the upstream server",
  "request_id":"e2b3182856c96c23d61e880d0a28012f"
}
```
{:.no-copy-code}

You can inspect {{ site.base_gateway }}'s container logs to see the error.

```shell
kubectl logs -n kong deploy/kong-gateway | grep "GET /echo"
```

```text
2024/11/29 11:41:46 [error] 1280#0: *45531 upstream SSL certificate verify error: (22:certificate chain too long) while SSL handshaking to upstream, client: 192.168.194.1, server: kong, request: "GET /echo HTTP/1.1", upstream: "https://192.168.194.19:443/", host: "kong.example", request_id: "678281372fb8907ed06d517cf515de78"
192.168.194.1 - - [29/Nov/2024:11:41:46 +0000] "GET /echo HTTP/1.1" 502 126 "-" "curl/8.7.1" kong_request_id: "678281372fb8907ed06d517cf515de78"
```
{:.no-copy-code}

{{ site.base_gateway }} is now rejecting the connection because the certificate chain is too long.
Changing the verification depth to 1 should allow the connection to succeed again.

{% navtabs certificate %}
{% navtab "Gateway API" %}
```shell
kubectl patch -n kong backendtlspolicies.gateway.networking.k8s.io goecho-tls-policy --type merge -p='{
  "spec": {
    "options" : {
      "tls-verify-depth": "1"
    }
  }
}'
```

The results should look like this:

```text
backendtlspolicy.gateway.networking.k8s.io/goecho-tls-policy patched
```
{:.no-copy-code}
{% endnavtab %}
{% navtab "Ingress" %}
For example, to limit the verification depth to 1 (i.e., only verify one intermediate certificate),
you can annotate the service like this:

```shell
kubectl annotate -n kong --overwrite service echo konghq.com/tls-verify-depth=1
```
{% endnavtab %}
{% endnavtabs %}

Now, when you issue the same request as before, you should see a successful response.

{% validation request-check %}
url: /echo
headers:
  - 'Host: kong.example'
status_code: 200
on_prem_url: $PROXY_IP
konnect_url: $PROXY_IP
{% endvalidation %}