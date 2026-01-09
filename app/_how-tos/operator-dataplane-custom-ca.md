---
title: Use a Custom CA Certificate
description: "Use a custom CA certificate when generating Data Plane certificates for {{ site.konnect_short_name }}"
content_type: how_to

permalink: /operator/dataplanes/how-to/use-custom-ca-certificate/
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
  - konnect

prereqs:
  operator:
    konnect:
      auth: true
      control_plane: true

tldr:
  q: How do I use a custom CA certificate to sign new `DataPlane` certificates?
  a: Provide the `spec.clientAuth.certificateSecret` field when defining your `KonnectExtension` resource
---

## Use a custom CA certificate

{{ site.operator_product_name }} generates TLS certificates to enable {{ site.base_gateway }} to authenticate with Konnect. By default, {{ site.operator_product_name }} will act as its own CA. If you would prefer to use your own CA, upload the CA certificate as a Kubernetes secret.

## Generate a certificate

{% include k8s/operator_client_certificate.md namespace="kong" %}

## Create a KonnectExtension

{{ site.operator_product_name }} inspects the `spec.clientAuth.certificateSecret` to decide how to provision certificates. Create a `KonnectExtension` with `spec.clientAuth.certificateSecret.provisioning: Manual`:

{% include /k8s/konnectextension.md use_custom_ca=true %}

## Validate your configuration

To ensure that the correct certificate has been used, fetch the Data Plane certificate from the {{ site.konnect_short_name }} API.

Fetch the Control Plane ID:

 ```bash
CONTROL_PLANE_ID=$(kubectl get -n kong konnectgatewaycontrolplanes.konnect.konghq.com gateway-control-plane -o yaml | yq .status.id)
```

Fetch the client certificate:

<!--vale off-->
{% konnect_api_request %}
url: /v2/control-planes/$CONTROL_PLANE_ID/dp-client-certificates
status_code: 2010
method: GET
jq: |
  .items[].cert
capture: DP_CERT
{% endkonnect_api_request %}
<!--vale on-->

To validate that the correct CA certificate has been used, you can `diff` the local certificate with the one from the API:

<!--vale off-->
{% validation custom-command %}
command: |
  echo $DP_CERT > dp.crt
  diff -u tls.crt dp.crt
expected:
  return_code: 0
{% endvalidation %}
<!--vale on-->
