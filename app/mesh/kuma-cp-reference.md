---
title: kuma-cp configuration reference
description: Configuration reference for the {{site.mesh_product_name}} control plane

content_type: reference
layout: reference
products:
  - mesh
breadcrumbs:
  - /mesh/

related_resources:
  - text: Control plane configuration
    url: /mesh/control-plane-configuration/
  - text: Deploy {{site.mesh_product_name}} on Universal
    url: /mesh/universal/
  - text: Deploy {{site.mesh_product_name}} on Kubernetes
    url: /mesh/kubernetes/

---

The following parameters can be used to configure `kuma-cp`:
```yaml
{% embed kuma-cp.yaml versioned %}
```

## Helm values.yaml

The following parameters can be used to configure `kuma-cp` in the Helm `values.yaml` file:

```yaml
{% embed helm-values.yaml versioned %}
```