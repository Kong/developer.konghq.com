---
title: "{{site.mesh_product_name}} license"
description: "Understand how licensing works in {{site.mesh_product_name}}, including limits, behaviors, and how to apply a license in both Kubernetes and Universal modes."
content_type: reference
layout: reference
products:
  - mesh
breadcrumbs:
  - /mesh/

tags:
  - license
  - multi-zone

related_resources:
  - text: Enterprise features
    url: /mesh/enterprise/
  - text: Install {{site.mesh_product_name}}
    url: /mesh/#get-started-with-kong-mesh
---


{{site.mesh_product_name}} requires a valid license to start the global control plane process. If no license is set, a pre-bundled trial license is used. The trial license expires after 30 days.

To override the default, provide a new license file. You can request one from the [{{site.mesh_product_name}} team](https://konghq.com/request-demo-kong-mesh/).


In a multi-zone setup, apply the license only to the global control plane. It automatically syncs to remote control planes. When installing {{site.mesh_product_name}}, the license file can be passed to `kuma-cp` with the 
[following instructions](#configure-the-license). 


## Configure the license

A valid license file can be passed to {{site.mesh_product_name}} in a variety of ways.

{% navtabs "configure" %}
{% navtab "kumactl" %}


When installing the {{site.mesh_product_name}} control plane with `kumactl install control-plane`, provide a `--license-path` argument with a full path to a valid license file. For example:

```sh
kumactl install control-plane --license-path=./license.json
```
{% endnavtab %}
{% navtab "Helm" %}


To install a valid license via Helm:

1. Create a secret named `kong-mesh-license` in the same namespace where {{site.mesh_product_name}} is being installed. For example:

   ```sh
   kubectl create namespace kong-mesh-system
   kubectl create secret generic kong-mesh-license -n kong-mesh-system --from-file=./license.json
   ```

   Where:
   * `kong-mesh-system` is the namespace where {{site.mesh_product_name}} control plane is installed
   * `./license.json` is the path to a valid license file. The filename should be `license.json` unless otherwise specified in `values.yaml`.

1. Modify the `values.yaml` file to point to the secret. For example:

   ```yaml
   kuma:
     controlPlane:
       secrets:
         - Env: "KMESH_LICENSE_INLINE"
           Secret: "kong-mesh-license"
           Key: "license.json"
   ```
{% endnavtab %}
{% navtab "Universal" %}


In Universal mode, configure a valid license by using one of the following environment variables:

* `KMESH_LICENSE_PATH`: The path to a valid license file
* `KMESH_LICENSE_INLINE`: The actual contents of the license file
{% endnavtab %}
{% endnavtabs %}
## Update a license

{% navtabs "Update a License" %}
{% navtab "Kubernetes" %}


1. Update the `kong-mesh-license` secret in `kong-mesh-system` namespace with a new license:
  ```sh
  kubectl edit secrets -n kong-mesh-system kong-mesh-license
  ```
1. Restart the control plane:
  ```sh
  kubectl rollout restart -n kong-mesh-system deployment kong-mesh-control-plane
  ```
{% endnavtab %}
{% navtab "Universal" %}


1. Update the license by doing one of the following:
  - If you used `KMESH_LICENSE_PATH`, update the content of the file.
  - If you used `KMESH_LICENSE_INLINE`, update the value of the environment variable.
1. Restart the control plane.
{% endnavtab %}
{% endnavtabs %}

## Multi-zone

In a multi-zone deployment of {{site.mesh_product_name}}, only the global control plane should be configured with a valid license. The global control plane automatically synchronizes the license to any remote control plane that is part of the cluster.

## Licensed metrics

{{site.mesh_product_name}} licenses are based on:

* The number of zones connected to your global control plane
* The license expiration date

A zone is a zone control plane and the data plane proxies connected to it. A single-zone deployment counts as one zone. The number of data plane proxies in a zone does not change the license count.

## License behaviors

With an expired license or invalid license, the control plane will fail to start.
If the license expires while the control-plane is running it will keep running but a restart of the instance will fail. 
The control plane will issue a warning in the logs and the GUI when the license expires in less than 30 days.
