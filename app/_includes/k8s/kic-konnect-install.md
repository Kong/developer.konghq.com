{%- if include.is_prereq %}{% assign heading = 4 %}{% else %}{% assign heading = 3 %}{%- endif -%}
{% unless include.is_prereq %}
{% for i in (1..heading) %}#{% endfor %} Create a KIC in {{ site.konnect_short_name }} Control Plane
{% endunless %}

Use the {{ site.konnect_short_name }} API to create a new `CLUSTER_TYPE_K8S_INGRESS_CONTROLLER` Control Plane:

<!--vale off-->
{% konnect_api_request %}
url: /v2/control-planes
status_code: 201
method: POST
body:
    name: My KIC CP
    cluster_type: "CLUSTER_TYPE_K8S_INGRESS_CONTROLLER"
capture: CONTROL_PLANE_DETAILS
{% endkonnect_api_request %}
<!--vale on-->

We'll need the `id` and `telemetry_endpoint` for the `values.yaml` file later. Save them as environment variables:

```bash
CONTROL_PLANE_ID=$(echo $CONTROL_PLANE_DETAILS | jq -r .id)
CONTROL_PLANE_TELEMETRY=$(echo $CONTROL_PLANE_DETAILS | jq -r '.config.telemetry_endpoint | sub("https://";"")')
```

{% for i in (1..heading) %}#{% endfor %} Create mTLS certificates

{{ site.kic_product_name }} talks to {{ site.konnect_short_name }} over a connected secured with TLS certificates.

Generate a new certificate using `openssl`:

```bash
openssl req -new -x509 -nodes -newkey rsa:2048 -subj "/CN=kongdp/C=US" -keyout ./tls.key -out ./tls.crt
```

The certificate needs to be a single line string to send it to the Konnect API with curl. Use `awk` to format the certificate:

```bash
export CERT=$(awk 'NF {sub(/\r/, ""); printf "%s\\n",$0;}' tls.crt);
```

Next, upload the certificate to Konnect:

<!--vale off-->
{% konnect_api_request %}
url: /v2/control-planes/$CONTROL_PLANE_ID/dp-client-certificates
status_code: 201
method: POST
body:
    cert: $CERT
{% endkonnect_api_request %}
<!--vale on-->

Finally, store the certificate in a Kubernetes secret so that {{ site.kic_product_name }} can read it:

```bash
kubectl create namespace kong -o yaml --dry-run=client | kubectl apply -f -
kubectl create secret tls konnect-client-tls -n kong --cert=./tls.crt --key=./tls.key
```

{% unless include.skip_values_file %}
{% for i in (1..heading) %}#{% endfor %} Create a values.yaml

{{ site.kic_product_name }} must be configured to send it's configuration to {{ site.konnect_short_name }}. Create a `values.yaml` file by copying and pasting the following command into your terminal:

```bash
echo 'controller:
  ingressController:
    image:
      tag: {{ site.data.kic_latest.release }}
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
    tag: "{{ site.data.gateway_latest.release }}"
  env:
    konnect_mode: 'on'
    vitals: "off"
    cluster_mtls: pki
    cluster_telemetry_endpoint: "'$CONTROL_PLANE_TELEMETRY':443"
    cluster_telemetry_server_name: "'$CONTROL_PLANE_TELEMETRY'"
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

{% endunless %}