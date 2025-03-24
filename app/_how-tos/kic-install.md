---
title: Install {{ site.kic_product_name }}
description: Run {{ site.kic_product_name }} with {{ site.konnect_short_name }} or on-prem using Helm
content_type: how_to
permalink: /kubernetes-ingress-controller/install/
breadcrumbs:
  - /kubernetes-ingress-controller/

related_resources:
  - text: All KIC documentation
    url: /index/kubernetes-ingress-controller/

products:
  - kic

works_on:
  - on-prem
  - konnect

entities: []

tldr:
  q: How do I install {{ site.kic_product_name }}?
  a: |
    ```bash
    helm install kong kong/ingress -n kong --create-namespace
    ```

prereqs:
  skip_product: true
  expand_accordion: false
  kubernetes:
    gateway_api: true
    gateway_api_optional: true

cleanup:
  inline:
    - title: Uninstall KIC from your cluster
      include_content: cleanup/products/kic
      icon_url: /assets/icons/kic.svg
---

{: data-deployment-topology="konnect" }
## Konnect setup

{:.info}
> For UI setup instructions to install {{ site.kic_product_name }} on {{ site.konnect_short_name }}, use the [Gateway Manager setup UI](https://cloud.konghq.com/us/gateway-manager/create-control-plane).

To create a {{ site.kic_product_name }} in {{ site.konnect_short_name }} deployment, you need the following items:

1. A [{{ site.konnect_short_name }} access token](https://cloud.konghq.com/global/account/tokens), saved in the `KONNECT_TOKEN` environment variable using `export KONNECT_TOKEN="kpat..."`
1. A {{ site.kic_product_name }} Control Plane, including the CP URL
1. An mTLS certificate for {{ site.kic_product_name }} to talk to {{ site.konnect_short_name }}

### Create a KIC in {{ site.konnect_short_name }} control plane

Use the {{ site.konnect_short_name }} API to create a new `CLUSTER_TYPE_K8S_INGRESS_CONTROLLER` control plane:

```bash
curl -H "Authorization: Bearer $KONNECT_TOKEN" \
    https://us.api.konghq.com/v2/control-planes \
    --json '{"name": "My KIC CP", "cluster_type": "CLUSTER_TYPE_K8S_INGRESS_CONTROLLER"}'
```

We'll need the `id` and `telemetry_endpoint` for the `values.yaml` file later. Save them as environment variables, replacing the `...` with the values from the API response in your terminal.

```bash
export CONTROL_PLANE_ID='...';
export CONTROL_PLANE_TELEMETRY='...';
```

### Create mTLS certificates

{{ site.kic_product_name }} talks to {{ site.konnect_short_name }} over a connected secured with TLS certificates.

Generate a new certificate using `openssl`:

```bash
openssl req -new -x509 -nodes -newkey rsa:2048 -subj "/CN=kongdp/C=US" -keyout ./tls.key -out ./tls.crt
```

Next, upload the certificate to Konnect:

```bash
export CERT=$(awk 'NF {sub(/\r/, ""); printf "%s\\n",$0;}' tls.crt);

curl -H "Authorization: Bearer $KONNECT_TOKEN" \
  https://us.api.konghq.com/v2/control-planes/$CONTROL_PLANE_ID/dp-client-certificates \
  --json '{"cert":"'"$CERT"'"}' \
```

Finally, store the certificate in a Kubernetes secret so that {{ site.kic_product_name }} can read it:

```bash
kubectl create namespace kong
kubectl create secret tls konnect-client-tls -n kong --cert=./tls.crt --key=./tls.key
```

### Create a values.yaml

{{ site.kic_product_name }} needs configuring to send it's configuration to {{ site.konnect_short_name }}. Create a `values.yaml` file by copying and pasting the following command:

```bash
echo 'controller:
  ingressController:
    image:
      tag: "3.4"
    env:
      feature_gates: "FillIDs=true"
    konnect:
      license:
        enabled: true
      enabled: true
      controlPlaneID: "'$CONTROL_PLANE_ID'"
      tlsClientCertSecretName: konnect-client-tls
      apiHostname: "us.kic.api.konghq.com"

gateway:
  image:
    repository: kong/kong-gateway
    tag: "3.9"
  env:
    konnect_mode: 'on'
    vitals: "off"
    cluster_mtls: pki
    cluster_telemetry_endpoint: "'${CONTROL_PLANE_TELEMETRY/https:\/\//}':443"
    cluster_telemetry_server_name: "'${CONTROL_PLANE_TELEMETRY/https:\/\//}'"
    cluster_cert: /etc/secrets/konnect-client-tls/tls.crt
    cluster_cert_key: /etc/secrets/konnect-client-tls/tls.key
    lua_ssl_trusted_certificate: system
    proxy_access_log: "off"
    dns_stale_ttl: "3600"
  resources:
    requests:
      cpu: 1
      memory: "2Gi"
  secretVolumes:
    - konnect-client-tls' > values.yaml
```

## Install Kong

Kong provides Helm charts to install {{ site.kic_product_name }}. Add the Kong charts repo and update to the latest version:

```bash
helm repo add kong https://charts.konghq.com
helm repo update
```

The default values file installs {{ site.kic_product_name }} in [Gateway Discovery](#) mode with a DB-less {{ site.base_gateway }}. This is our recommended deployment topology.

Run `helm upgrade --install` to install {{ site.kic_product_name }}:

{: data-deployment-topology="konnect" }
```bash
helm upgrade --install kong kong/ingress -n kong --values ./values.yaml
```

{: data-deployment-topology="on-prem" }
```bash
helm install kong kong/ingress -n kong --create-namespace
```

## Test connectivity to Kong

Ensure that you can call the proxy IP:

```bash
export PROXY_IP=$(kubectl get svc --namespace kong kong-gateway-proxy -o jsonpath='{range .status.loadBalancer.ingress[0]}{@.ip}{@.hostname}{end}')
curl -i $PROXY_IP
```

The results should look like this:

```
HTTP/1.1 404 Not Found
Content-Type: application/json; charset=utf-8
Connection: keep-alive
Content-Length: 48
X-Kong-Response-Latency: 0
Server: kong/3.9.0

{"message":"no Route matched with those values"}
```
