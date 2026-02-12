---
title: Interacting with the {{site.mesh_product_name}} control plane
description: Access and interact with the control plane using the UI, HTTP API, kumactl, or kubectl, and understand the ports exposed by each control plane mode.

content_type: reference
layout: reference
products:
  - mesh
breadcrumbs:
  - /mesh/

min_version:
  mesh: '2.6'

related_resources:
  - text: Resource sizing guidelines
    url: /mesh/resource-sizing-guidelines/
  - text: Version compatibility
    url: /mesh/version-compatibility/
---

After {{site.mesh_product_name}} is installed, you can access the control plane via the following methods:

{% table %}
columns:
  - title: Access method
    key: method
  - title: Deployment mode
    key: mode
  - title: Permissions
    key: permissions
rows:
  - method: "{{site.mesh_product_name}} UI"
    mode: Kubernetes and Universal
    permissions: Read-only
  - method: HTTP API
    mode: Kubernetes and Universal
    permissions: Read-only
  - method: "`kumactl`"
    mode: Kubernetes
    permissions: Read-only
  - method: "`kumactl`"
    mode: Universal
    permissions: Read and write
  - method: "`kubectl`"
    mode: Kubernetes
    permissions: Read and write
{% endtable %}


{% capture ui %}
{{site.mesh_product_name}} ships with a read-only UI that you can use to retrieve {{site.mesh_product_name}} resources. 
By default the UI listens on the API port and defaults to `:5681/gui`.
{% endcapture %}

{% capture kumactl-example %}
You can then run `kumactl`, for example:

```sh
kumactl get meshes
```

You can configure `kumactl` to point to any zone `kuma-cp` instance by running:

```sh
kumactl config control-planes add --name=$CP_NAME --address=http://$HOST:5681
```
{% endcapture %}

## Kubernetes
{% navtabs "Method" %}
{% navtab "UI" %}

{{ui}}

To access the {{site.mesh_product_name}} UI, you must first port-forward to make the port accessible outside of the cluster:

```sh
kubectl port-forward svc/{{site.mesh_cp_name}} -n {{site.mesh_namespace}} 5681:5681
```

You can then navigate to [`127.0.0.1:5681/gui`](http://127.0.0.1:5681/gui) to see the UI.

{% endnavtab %}
{% navtab "kubectl" %}

You can use `kubectl` to perform read and write operations on {{site.mesh_product_name}} resources. 

For example, you can use the following command to enable mTLS on the `default` mesh:

```sh
echo "apiVersion: kuma.io/v1alpha1
kind: Mesh
metadata:
  name: default
spec:
  mtls:
    enabledBackend: ca-1
    backends:
    - name: ca-1
      type: builtin" | kubectl apply -f -
```

{% endnavtab %}
{% navtab "HTTP API" %}

{{site.mesh_product_name}} ships with a read-only HTTP API that you can use to retrieve {{site.mesh_product_name}} resources.

By default the HTTP API listens on port `5681`. To access the API, you must first port-forward to make the port accessible outside of the cluster:

```sh
kubectl port-forward svc/{{site.mesh_cp_name}} -n {{site.mesh_namespace}} 5681:5681
```

You can then navigate to [`127.0.0.1:5681`](http://127.0.0.1:5681) to see the HTTP API.

{% endnavtab %}
{% navtab "kumactl" %}

You can use the [`kumactl` CLI](/mesh/cli/#kumactl) to perform read-only operations on {{site.mesh_product_name}} resources. 
The `kumactl` binary uses the {{site.mesh_product_name}} HTTP API, so you must first port-forward to make the HTTP API port accessible outside of the cluster:

```sh
kubectl port-forward svc/{{site.mesh_cp_name}} -n {{site.mesh_namespace}} 5681:5681
```

{{kumactl-example}}


{% endnavtab %}
{% endnavtabs %}


## Universal
{% navtabs "Method" %}
{% navtab "UI" %}

{{ui}}

{% endnavtab %}
{% navtab "HTTP API" %}

{{site.mesh_product_name}} ships with a read and write HTTP API that you can use to perform operations on {{site.mesh_product_name}} resources. 
By default the HTTP API listens on port `5681`.

{% endnavtab %}
{% navtab "kumactl" %}

You can use the `kumactl` CLI to perform **read and write** operations on {{site.mesh_product_name}} resources. The `kumactl` binary is a client to the {{site.mesh_product_name}} HTTP API. For example:

{{kumactl-example}}

You can enable mTLS on the `default` mesh with:

```sh
echo "type: Mesh
name: default
mtls:
  enabledBackend: ca-1
  backends:
  - name: ca-1
    type: builtin" | kumactl apply -f -
```

{% endnavtab %}
{% endnavtabs %}

{{site.mesh_product_name}} improves connectivity between your services and makes the network more reliable. However, it also has its own networking requirements.

## Control plane ports

The `kuma-cp` application is a server that offers a number of services. Some are meant for internal consumption by `kuma-dp` data plane proxies, and some are meant for external consumption by `kumactl`, the HTTP API, the UI, or other systems.

The number and type of exposed ports depends on the type of control plane.

{% capture p5443 %}
`5443`: The port for the admission webhook, only enabled in `Kubernetes`. The default Kubernetes `{{site.mesh_cp_name}}` service exposes this port on `443`.
{% endcapture %}

{% capture p5680 %}
`5680`: The HTTP server that returns the health status and metrics of the control plane.
{% endcapture %}

{% capture p5682 %}
`5682`: The HTTPS version of the services available under `5681`.
{% endcapture %}

{% capture p5683 %}
`5683`: The gRPC intercommunication CP server used internally by {{site.mesh_product_name}} to communicate between CP instances.
{% endcapture %}

### Global control plane

When {{site.mesh_product_name}} runs as a distributed service mesh, the global control plane exposes the following TCP ports:

* {{p5443}}
* {{p5680}}
* `5681`: The HTTP API server used by `kumactl`, which you can also use to retrieve {{site.mesh_product_name}}'s policies and, when running in `universal`, that you can use to apply new policies. Manipulating data plane resources is not possible. It also exposes the {{site.mesh_product_name}} UI at `/gui`.
* {{p5682}}
* {{p5683}}
* `5685`: The {{site.mesh_product_name}} Discovery Service port, leveraged in multi-zone deployments.

### Zone control plane

When {{site.mesh_product_name}} is run as a distributed service mesh, the zone control plane exposes the following TCP ports:

* {{p5443}}
* `5676`: The Monitoring Assignment server that responds to discovery requests from monitoring tools, such as `Prometheus`, that are looking for a list of targets to scrape metrics from.
* `5678`: The server for the control plane to data plane proxy communication (bootstrap configuration, xDS to retrieve data plane proxy configuration, SDS to retrieve mTLS certificates).
* {{p5680}}
* `5681`: The HTTP API server that is being used by `kumactl`. You can also use it to retrieve {{site.mesh_product_name}}'s policies and, when running in Universal mode, you can manage data plane resources. When not connected to a global control plane, it also exposes the {{site.mesh_product_name}} UI at `/gui`.
* {{p5682}}
* {{p5683}}
