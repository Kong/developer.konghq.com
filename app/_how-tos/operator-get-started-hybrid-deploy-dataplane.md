---
title: Deploy a DataPlane
description: "Deploy a DataPlane using {{ site.operator_product_name }}."
content_type: how_to

permalink: /operator/dataplanes/get-started/hybrid/deploy-dataplane/
series:
  id: operator-get-started-hybrid
  position: 2

breadcrumbs:
  - /operator/
  - index: operator
    group: Gateway Deployment
  - index: operator
    group: Gateway Deployment
    section: "Get Started"

products:
  - operator

works_on:
  - konnect

entities: []

tldr:
  q: How can I deploy a DataPlane with {{ site.operator_product_name }}?
  a: Create a `DataPlane` object and use the `KonnectExtension` reference.

prereqs:
  show_works_on: true
  skip_product: true
  operator:
    konnect:
      auth: true
      control_plane: true
      konnectextension: true

---

{:data-deployment-topology='konnect'}
## Create the DataPlane

Configure a Kong `DataPlane` by using your `KonnectExtension` reference:

```bash
echo '
apiVersion: gateway-operator.konghq.com/v1beta1
kind: DataPlane
metadata:
  name: dataplane-example
  namespace: kong
spec:
  extensions:
  - kind: KonnectExtension
    name: my-konnect-config
    group: konnect.konghq.com
  deployment:
    podTemplateSpec:
      spec:
        containers:
        - name: proxy
          image: kong/kong-gateway:{{ site.data.gateway_latest.release }}
' | kubectl apply -f -
```

## Check the Ready status

<!-- vale off -->
{% validation kubernetes-resource %}
kind: DataPlane
name: dataplane-example
conditionType: Ready
reason: Ready
{% endvalidation %}
<!-- vale on -->

If the `DataPlane` has `Ready` condition set to `True` then you can visit {{site.konnect_short_name}} and see the dataplane in the list of connected Data Planes for your Control Plane.
