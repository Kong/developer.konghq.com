---
title: Install {{ site.base_gateway }} in Konnect with Helm
description: Create a Control Plane in Konnect, then deploy a Data Plane to your Kubernetes cluster using Helm.
content_type: how_to
permalink: /gateway/install/kubernetes/konnect/
breadcrumbs:
  - /gateway/
  - /gateway/install/

products:
  - gateway

works_on:
  - konnect
  - on-prem

entities: []

tldr:
  q: How do I install {{ site.base_gateway }} in Konnect with Helm?
  a: |
    Create a Control Plane in {{ site.konnect_short_name }}, populate a `values.yaml` file with the Control Plane details, and run `helm install kong kong/kong --values ./values.yaml -n kong --create-namespace`.
faqs:
  - q: Can I install {{ site.base_gateway }} via Helm without cluster permissions?
    a: |
      Yes. Using the `kong` chart, set `ingressController.rbac.enableClusterRoles` to false. 

      {:.danger}
      > **Warning:** Some resources require a ClusterRole for reconciliation because the controllers need to watch cluster scoped resources. Disabling ClusterRoles causes them fail, so you need to disable the controllers when setting it to `false`. These resources include:
      > - All Gateway API resources
      > - `IngressClass`
      > - `KNative/Ingress` (KIC 2.x only)
      > - `KongClusterPlugin`
      > - `KongVault`, `KongLicense` (KIC 3.1 and above)
prereqs:
  skip_product: true

topology_switcher: page
next_steps:
  - text: Rate limit a Gateway Service
    url: /how-to/add-rate-limiting-to-a-service-with-kong-gateway/
  - text: Enable key authentication on a Gateway Service
    url: /how-to/authenticate-consumers-with-key-auth-enc/

automated_tests: false

tags:
  - install
  - helm
---

## Konnect setup

{% include prereqs/products/konnect-auth-only.md raw=true %}

## Helm setup

```bash
helm repo add kong https://charts.konghq.com
helm repo update
```

## Create certificates

Create a certificate and key:

```bash
openssl req -new -x509 -nodes -newkey ec:<(openssl ecparam -name secp384r1) -keyout ./tls.key -out ./tls.crt -days 1095 -subj "/CN=kong_clustering"
```

Create a Secret containing the certificate:

```bash
kubectl create namespace kong
kubectl create secret tls kong-cluster-cert --cert=./tls.crt --key=./tls.key -n kong
```

## Create a Control Plane

{{ site.konnect_short_name }} allows you to create a Control Plane in a single API request.

Create a Control Plane and capture the details for later:

<!--vale off-->
{% konnect_api_request %}
url: /v2/control-planes
status_code: 201
method: POST
body:
    name: demo-control-plane
capture: CONTROL_PLANE_DETAILS
{% endkonnect_api_request %}
<!--vale on-->

Upload the certificates to this Control Plane:

```bash
CONTROL_PLANE_ID=$(echo $CONTROL_PLANE_DETAILS | jq -r .id)
CERT=$(awk 'NF {sub(/\r/, ""); printf "%s\\n",$0;}' tls.crt);
```

{% konnect_api_request %}
url: /v2/control-planes/$CONTROL_PLANE_ID/dp-client-certificates
status_code: 201
method: POST
body:
    cert: "$CERT"
{% endkonnect_api_request %}

## Deploy a Data Plane

Export the Control Plane ID and telemetry endpoint for later:

```bash
CONTROL_PLANE_ENDPOINT=$(echo $CONTROL_PLANE_DETAILS | jq -r '.config.control_plane_endpoint | sub("https://";"")')
CONTROL_PLANE_TELEMETRY=$(echo $CONTROL_PLANE_DETAILS | jq -r '.config.telemetry_endpoint | sub("https://";"")')
```

Create a `values-dp.yaml` file with the following content:

```yaml
echo '
ingressController:
 enabled: false
  
image:
 repository: kong/kong-gateway
 tag: "{{ site.data.gateway_latest.version }}"
  
# Mount the secret created earlier
secretVolumes:
 - kong-cluster-cert
  
env:
  # data_plane nodes do not have a database
  role: data_plane
  database: "off"
  konnect_mode: 'on'
  vitals: "off"
  cluster_mtls: pki

  cluster_control_plane: "'$CONTROL_PLANE_ENDPOINT'"
  cluster_telemetry_endpoint: "'$CONTROL_PLANE_ENDPOINT':443"
  cluster_telemetry_server_name: "'$CONTROL_PLANE_ENDPOINT'"
  cluster_cert: /etc/secrets/kong-cluster-cert/tls.crt
  cluster_cert_key: /etc/secrets/kong-cluster-cert/tls.key

  lua_ssl_trusted_certificate: system
  proxy_access_log: "off"
  dns_stale_ttl: "3600"
resources:
  requests:
    cpu: 1
    memory: "2Gi"
secretVolumes:
  - kong-cluster-cert
  
# The data plane handles proxy traffic only
proxy:
 enabled: true
  
admin:
 enabled: false
  
manager:
 enabled: false
' > values-dp.yaml
```

Deploy the Data Plane using the `values-dp.yaml`:

```bash
helm install kong kong/kong --values ./values-dp.yaml -n kong --create-namespace
```