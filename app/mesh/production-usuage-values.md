---
title: "Deploy {{site.mesh_product_name}} in Production with Helm"
description: "Deploy a production-grade {{site.mesh_product_name}} installation on Kubernetes using Helm charts for single zone, multi-zone, or federated environments."
content_type: reference
layout: reference
products:
  - mesh

tags:
  - multi-zone
  - control-plane

works_on:
  - on-prem

related_resources:
  - text: "{{site.mesh_product_name}} Installation Overview"
    url: /mesh/
  - text: "Multi-zone Authentication"
    url: /mesh/multi-zone-authentication/
---



To install a production-ready {{site.mesh_product_name}}, you must ensure that the service mesh is secure, reliable, and performant. When deploying {{site.mesh_product_name}} on Kubernetes, use the provided values here to deploy your {{site.mesh_product_name}} installation.

Instructions on this page are meant to be the starting point for your installation. It's always recommended to read the full [Helm configuration reference](/mesh/{{ page.release }}/reference/kuma-cp/#helm-valuesyaml) to find support for other options available before executing the install steps. Values provided here will override values in the default reference Helm configuration, and they may be overridden again by further `values.yaml` files or arguments of the `helm` command. See the [Helm documentation](https://helm.sh/docs/chart_template_guide/values_files/) to learn more about how values are calculated.

Values on this page may reference resources that need to be created in advance when certain features are enabled, read the file content carefully and prepare these resources according to the notes near the keywords `(action)`. If you decide to disable a feature that requires a pre-existing resource, remove or change those fields according to the full [Helm configuration reference](/mesh/{{ page.release }}/reference/kuma-cp/#helm-valuesyaml).


{% navtabs "install" %}
{% navtab "Single zone Control Plane "%}

Install a single zone Control Plane:

```sh
helm install {{ site.mesh_helm_install_name }} {{ site.mesh_helm_repo }} --namespace {{site.mesh_namespace}} -f ./values.single-zone-cp.yaml
```

Suggested `values.yaml` file:

```yaml
{% embed helm-values-prod/values.single-zone-cp.yaml versioned %}
```

{% endnavtab %}
{% navtab "Multi-zone global Control Plane" %}

Install the global Control Plane for a multi-zone deployment:

```sh
helm install {{ site.mesh_helm_install_name }} {{ site.mesh_helm_repo }} --namespace {{site.mesh_namespace}} -f ./values.global-cp.yaml
```

Suggested `values.yaml` file:

```yaml
{% embed helm-values-prod/values.global-cp.yaml versioned %}
```

The values on this page may reference resources that need to be created in advance when certain features are enabled, read the file content carefully and prepare these resources according to the notes near the keywords `(action)`. If you decide to disable a feature that requires a pre-existing resource, remove or change those fields according to the full [Helm configuration reference](/mesh/{{ page.release }}/reference/kuma-cp/#helm-valuesyaml).

{% endnavtab %}

{% navtab "Multi-zone federated zone Control Planes" %}

Install federated zone Control Planes for a multi-zone deployment:

```sh
helm install {{ site.mesh_helm_install_name }} {{ site.mesh_helm_repo }} --namespace {{site.mesh_namespace}} -f ./values.federated-zone-cp.yaml \
  --set '{{site.set_flag_values_prefix}}controlPlane.zone=zone-prod' \
  --set '{{site.set_flag_values_prefix}}controlPlane.kdsGlobalAddress=kds-global.example.com'
```

Suggested `values.yaml` file:

```yaml
{% embed helm-values-prod/values.federated-zone-cp.yaml versioned %}
```

The values on this page may reference resources that need to be created in advance when certain features are enabled, read the file content carefully and prepare these resources according to the notes near the keywords `(action)`. If you decide to disable a feature that requires a pre-existing resource, remove or change those fields according to the full [Helm configuration reference](/mesh/reference/kuma-cp/#helm-valuesyaml).
{% endnavtab %}
{% endnavtabs %}
