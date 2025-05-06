---
title: Set DataPlane Image
description: "TODO"
content_type: how_to

permalink: /operator/dataplanes/how-to/set-dataplane-image/
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

entities: []

tags:
  - konnect-crd
 
tldr:
  q: Question?
  a: Answer

prereqs: {}

---

## Deploy a DataPlane

The `DataPlane` image can be specified by providing a custom `image` value for the `proxy` container. This value is provided in the `PodTemplateSpec` field in either the `DataPlane` or the `GatewayConfiguration` resource.

{% operator_podtemplatespec_example %}
kubectl_apply: true
dataplane:
  spec:
    containers:
      - name: proxy
        image: 'kong/kong-gateway:{{ site.data.gateway_latest.release }}'
{% endoperator_podtemplatespec_example %}


## Validation

TODO: get the Kong Gateway pod and check the image key