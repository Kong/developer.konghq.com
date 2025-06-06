---
title: "Red Hat Universal Base Images"
description: "Use Red Hat Universal Base Images (UBI) for running {{site.mesh_product_name}} components, available alongside standard Alpine-based images."
content_type: reference
layout: reference
products:
  - mesh

breadcrumbs:
  - /mesh/
tags:
  - ubi
  - red-hat

related_resources:
  - text: "Enterprise features"
    url: /mesh/enterprise/
  - text: "Verify signatures for signed images"
    url: /mesh/signed-images/
  - text: Get started with Red Hat OpenShift
    url: /mesh/openshift-quickstart/
---

In addition to the standard {{site.mesh_product_name}} images built on Alpine Linux, {{site.mesh_product_name}} also ships with images based on the [Red Hat Universal Base Image (UBI)](https://developers.redhat.com/products/rhel/ubi).

{{site.mesh_product_name}} UBI images are distributed with all standard images, but with the `ubi-` prefix:

* [kuma-dp UBI image](https://hub.docker.com/r/kong/ubi-kuma-dp)
* [kuma-cp UBI image](https://hub.docker.com/r/kong/ubi-kuma-cp)
* [kumactl UBI image](https://hub.docker.com/r/kong/ubi-kumactl)
* [kuma-init UBI image](https://hub.docker.com/r/kong/ubi-kuma-init)
* [kuma-prometheus-sd UBI image](https://hub.docker.com/r/kong/ubi-kuma-prometheus-sd)

The base UBI variant for all images is `ubi-minimal`.

## Using {{site.mesh_product_name}} UBI images

To use UBI images, you need to explicitly pass them when the Control Plane is installed:

{% navtabs "usage"%}
{% navtab "kumactl" %}
```sh
kumactl install control plane \
  --control-plane-repository=ubi-kuma-cp \
  --dataplane-init-repository=ubi-kuma-init \
  --dataplane-repository=ubi-kuma-dp
```
{% endnavtab %}
{% navtab "Helm" %}
```sh
helm install kong-mesh \
  --namespace kong-mesh-system \
  --set kuma.controlPlane.image.repository=ubi-kuma-cp \
  --set kuma.dataPlane.image.repository=ubi-kuma-dp \
  --set kuma.dataPlane.image.repository=ubi-kuma-dp \
  --set kuma.dataPlane.initImage.repository=ubi-kuma-dp \
  --set kuma.kumactl.image.repository=ubi-kumactl \
  kong-mesh/kong-mesh
```
{% endnavtab %}
{% endnavtabs %}