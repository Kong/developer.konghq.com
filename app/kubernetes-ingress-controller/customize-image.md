---
title: "Customize Images"

description: |
  Customize the image name used for {{ site.kic_product_name }} and {{ site.base_gateway }}

breadcrumbs:
  - /kubernetes-ingress-controller/
  
content_type: reference
layout: reference

products:
  - kic

works_on:
  - on-prem
  - konnect
---


{{ site.kic_product_name }} supports both {{ site.base_gateway }} OSS and Enterprise. If you install {{ site.kic_product_name }} using the default Helm charts, {{ site.base_gateway }} OSS will be installed.

You can customize the products used by setting `gateway.image` and `controller.image` in your `values.yaml`, then upgrading your Helm deployment:

```bash
helm upgrade {release_name} kong/ingress -n {namespace} --values ./values.yaml
```

You can check which images are being used with the following query:

```bash
kubectl get pods -n kong -o jsonpath="{.items[*].spec.containers[*].image}"
```

## Common images

These are some of the commonly used `values.yaml` files.

### {{ site.ee_product_name }}

You can switch to {{ site.ee_product_name }} using the `kong/kong-gateway` image:

```yaml
gateway:
  image:
    repository: kong/kong-gateway
    tag: {{ site.data.gateway_latest.release }}
```

### {{ site.kic_product_name }} nightly

You can test the latest build of {{ site.kic_product_name }} using the `kong/nightly-ingress-controller` image:

```yaml
controller:
  ingressController:
    image:
      repository: kong/nightly-ingress-controller
      tag: nightly
      effectiveSemver: v{{ site.data.kic_latest.release }}
```
