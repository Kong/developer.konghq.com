---
title: Deploy a DataPlane
description: "TODO"
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
  q: Question?
  a: Answer

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

Configure a Kong `DataPlane` by using your `KonnectExtension` reference.

```bash
echo '
apiVersion: gateway-operator.konghq.com/v1beta1
kind: DataPlane
metadata:
  name: dataplane-example
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

## Check the Programmed status

If the `DataPlane` has `Programmed` condition set to `True` then you can visit {{site.konnect_short_name}} and see the dataplane in the list of connected dataplanes for your control plane:

<!-- vale off -->
{% validation kubernetes-resource %}
kind: dataplane
name: kong
{% endvalidation %}
<!-- vale on -->