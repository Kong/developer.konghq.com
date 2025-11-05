---
title: Set DataPlane Image
description: "Customize the image used for {{ site.base_gateway }}"
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
  - on-prem

tldr:
  q: How do I customize the image used for {{ site.base_gateway }} with {{ site.operator_product_name }}?
  a: Use PodTemplateSpec to customize the container spec and specify an `image` name for the `proxy` container.

---

## Deploy a DataPlane

The `DataPlane` image can be specified by providing a custom `image` value for the `proxy` container. This value is provided in the `PodTemplateSpec` field in either the `DataPlane` or the `GatewayConfiguration` resource.

<!--vale off-->
{% operator_podtemplatespec_example %}
kubectl_apply: true
dataplane:
  spec:
    containers:
      - name: proxy
        image: 'kong/kong-gateway:3.9'
{% endoperator_podtemplatespec_example %}
<!--vale on-->

## Validation

To validate that the correct image was used, fetch the pod created by {{ site.operator_product_name }} and check the `.spec.containers[].image` value:

<!--vale off-->
{% validation kubernetes-resource-property %}
kind: pod
name_selector: |
  .items[].metadata.name | select(contains("dataplane-example"))
path: |
  .spec.containers[] | select(.name == "proxy") | .image
expected: "kong/kong-gateway:3.10"
{% endvalidation %}
<!--vale on-->
