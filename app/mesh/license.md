---
title: "{{site.mesh_product_name}} License"
description: "Understand how licensing works in {{site.mesh_product_name}}, including limits, behaviors, and how to apply a license in both Kubernetes and Universal modes."
content_type: reference
layout: reference
products:
  - mesh

tags:
  - licensing
  - multi-zone

works_on:
  - on-prem

related_resources:
  - text: "Access Audit"
    url: /mesh/access-audit/
  - text: "Certificate Manager"
    url: /mesh/cert-manager/
---


{{site.mesh_product_name}} requires a valid license to start the Global Control Plane process. If no license is set, a **pre-bundled license** is used:

* Data Plane Proxy (DPP) limit: 5
* Expiration: 30 days

To override the default, provide a new license file. You can request one from the [{{site.mesh_product_name}} team](https://konghq.com/request-demo-kong-mesh/).


In a multi-zone setup, apply the license only to the Global Control Plane. It automatically syncs to remote Control Planes.

When installing {{site.mesh_product_name}}, the license file can be passed to `kuma-cp` with the 
[following instructions](#configure-the-license). 

If running {{site.mesh_product_name}} in a multi-zone deployment, the file must be passed to the global `kuma-cp`.
In this mode, {{site.mesh_product_name}} automatically synchronizes the license to the remote 
`kuma-cp`, therefore this operation is only required on the global `kuma-cp`.


## Configure the license

A valid license file can be passed to {{site.mesh_product_name}} in a variety of ways.

{% navtabs "configure" %}
{% navtab "kumactl" %}


When installing the {{site.mesh_product_name}} control plane with `kumactl install control-plane`, provide a `--license-path` argument with a full path to a valid license file. For example:

```sh
$ kumactl install control-plane --license-path=/path/to/license.json
```
{% endnavtab %}
{% navtab "Helm" %}


To install a valid license via Helm:

1. Create a secret named `kong-mesh-license` in the same namespace where {{site.mesh_product_name}} is being installed. For example:

   ```sh
   $ kubectl create namespace kong-mesh-system
   $ kubectl create secret generic kong-mesh-license -n kong-mesh-system --from-file=/path/to/license.json
   ```

   Where:
   * `kong-mesh-system` is the namespace where {{site.mesh_product_name}} control plane is installed
   * `/path/to/license.json` is the path to a valid license file. The filename should be `license.json` unless otherwise specified in `values.yaml`.

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


In Universal mode, configure a valid license by using the following environment variables:

* `KMESH_LICENSE_PATH` - value with the path to a valid license file.
* `KMESH_LICENSE_INLINE` - value with the actual contents of the license file.
{% endnavtab %}
{% endnavtabs %}
## Update a license

{% navtabs "Update a License" %}
{% navtab "Kubernetes" %}


1. Update the `kong-mesh-license` Secret in `kong-mesh-system` namespace with a new license:
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
{% navtab "Multi-zone" %}
## Multi-zone

In a multi-zone deployment of {{site.mesh_product_name}}, only the global control plane should be configured with a valid license. The global control plane automatically synchronizes the license to any remote control plane that is part of the cluster.

In a multi-zone deployment, the DPPs count includes the total aggregate of every data plane proxy in every zone. For example, with a limit of 5 DPPs and 2 zones, you can connect 3 DPPs in one zone and 2 in another, but not 5 DPPs for each zone.
{% endnavtab %}
{% endnavtabs %}


## Licensed metrics

The license encourages a pay-as-you-go model that delivers the best benefits to you, the end user, since the derived value of {{site.mesh_product_name}} is directly associated to the positive benefits of real service mesh usage.
Licenses are based on:

* Total number of connected Data Plane Proxies (DPPs), across all zones.

* License expiration date.



In the context of the metric, a data plane proxy (DPP) is a standard data plane proxy that is deployed next to your services, either as a sidecar container or in a virtual machine. Gateway data plane proxies, zone ingresses, and zone egresses are not counted.

You can measure the number of data plane proxies needed in {{site.mesh_product_name}} by the 
number of services you want to include in your service meshes. Use the following formula:

```
Number of DPPs = Number of Pods + Number of VMs.
```


## License behaviours

With an expired license or invalid license the control-plane will fail to start.
If the license expires while the control-plane is running it will keep running but a restart of the instance will fail. 
The control-plane will issue a warning in the logs and the GUI when the license expires in less than 30 days.

With a valid issued license, a data plane proxy will always be able to join the service mesh, even if you go above the allowed limit to prevent service disruptions.
If the number of DPPs does go above the limit, you will see a warning in the GUI and in the control plane logs. 

With the pre-bundled license, if you go over the maximum allowed number of DPPs, the system will automatically refuse their connections.
