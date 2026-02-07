---
title: Use the {{site.mesh_product_name}} CLI
description: How to communicate with Mesh components
content_type: how_to
breadcrumbs:
  - /mesh/
permalink: /mesh/use-mesh-cli/
related_resources:
  - text: "{{site.mesh_product_name}}"
    url: /mesh/overview/
  - text: All {{site.mesh_product_name}} documentation
    url: /index/mesh/

products:
  - mesh
works_on:
  - on-prem
  - konnect

tldr:
  q: How do I use the CLI components and communicate with {{site.mesh_product_name}}?
  a: "kumactl and kubectl can be used to communicate with the Mesh Control plane"
prereqs:
  inline:
    - title: Install kumactl
      include_content: prereqs/tools/kumactl
    - title: Review {{site.mesh_product_name}} documentation
      content: Go to the [CLI reference](/mesh/cli/) to see what options you have on the command line.

---

After {{site.mesh_product_name}} is installed, you can access the control plane via the following methods:

<!--vale off-->
{% table %}
columns:
  - title: Access method
    key: access_method
  - title: Mode
    key: mode
  - title: Permissions
    key: permissions
rows:
  - access_method: "The {{site.konnect_short_name}} GUI"
    mode: Kubernetes and Universal self managed control plane
    permissions: Read-only
  - access_method: "HTTP API"
    mode: Kubernetes and Universal
    permissions: Read-only
  - access_method: "`kumactl`"
    mode: Kubernetes self managed control plane
    permissions: Read-only
  - access_method: "`kumactl`"
    mode: Kubernetes Konnect managed control plane
    permissions: Read and write
  - access_method: "`kubectl`"
    mode: Kubernetes self managed control plane
    permissions: Read and write
  - access_method: "`kubectl`"
    mode: Kubernetes Konnect managed control plane
    permissions: Read-only
{% endtable %}
<!--vale on-->

By accessing the control plane using one of these methods, you can see the current {{site.mesh_product_name}} configuration or with some methods, you can edit the configuration.

{% tabs %}
{% tab Kubernetes %}
{% tabs %}
{% tab GUI (Read-only) %}

{{site.mesh_product_name}} ships with a **read-only** GUI that you can use to retrieve {{site.mesh_product_name}} resources. By default the GUI listens on the API port and defaults to `:5681/gui`.

To access {{site.mesh_product_name}} we need to first port forward to the API with:

```sh
kubectl port-forward svc/{{site.mesh_cp_name}} -n {{site.mesh_namespace}} 5681:5681
```

And then navigate to [`127.0.0.1:5681/gui`](http://127.0.0.1:5681/gui) to see the GUI.

You will notice that {{site.mesh_product_name}} automatically creates a [`Mesh`](/mesh/) entity with name `default`.

{% endtab %}
{% tab kubectl (Read & Write) %}

You can use {{site.mesh_product_name}} with `kubectl` to perform **read and write** operations on {{site.mesh_product_name}} resources. For example:

```sh
kubectl get meshes
# NAME          AGE
# default       1m
```

or you can enable mTLS on the `default` Mesh with:

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

You will notice that {{site.mesh_product_name}} automatically creates a [`Mesh`](/mesh/) entity with name `default`.

{% endtab %}
{% tab HTTP API (Read-only) %}

{{site.mesh_product_name}} ships with a **read-only** HTTP API that you can use to retrieve {{site.mesh_product_name}} resources.

By default the HTTP API listens on port `5681`. To access {{site.mesh_product_name}} we need to first port forward to the API with:

```sh
kubectl port-forward svc/{{site.mesh_cp_name}} -n {{site.mesh_namespace}} 5681:5681
```

And then you can navigate to [`127.0.0.1:5681`](http://127.0.0.1:5681) to see the HTTP API.

You will notice that {{site.mesh_product_name}} automatically creates a [`Mesh`](/mesh/) entity with name `default`.

{% endtab %}
{% tab kumactl (Read-only) %}

You can use the `kumactl` CLI to perform **read-only** operations on {{site.mesh_product_name}} resources. The `kumactl` binary is a client to the {{site.mesh_product_name}} HTTP API, you will need to first port forward to the API with:

```sh
kubectl port-forward svc/{{site.mesh_cp_name}} -n {{site.mesh_namespace}} 5681:5681
```

and then run `kumactl`, for example:

```sh
kumactl get meshes
# NAME          mTLS      METRICS      LOGGING   TRACING
# default       off       off          off       off
```

You can configure `kumactl` to point to any zone `kuma-cp` instance by running:

```sh
kumactl config control-planes add --name=XYZ --address=http://{address-to-kuma}:5681
```

You will notice that {{site.mesh_product_name}} automatically creates a [`Mesh`](/mesh/) entity with name `default`.

{% endtab %}
{% endtabs %}

{% endtab %}
{% tab Universal%}
{% tabs %}
{% tab GUI (Read-only) %}

{{site.mesh_product_name}} ships with a **read-only** GUI that you can use to retrieve {{site.mesh_product_name}} resources. By default the GUI listens on the API port and defaults to `:5681/gui`.

To access {{site.mesh_product_name}} you can navigate to [`127.0.0.1:5681/gui`](http://127.0.0.1:5681/gui) to see the GUI.

You will notice that {{site.mesh_product_name}} automatically creates a [`Mesh`](/mesh/) entity with name `default`.

{% endtab %}
{% tab HTTP API (Read & Write) %}

{{site.mesh_product_name}} ships with a **read and write** HTTP API that you can use to perform operations on {{site.mesh_product_name}} resources. By default the HTTP API listens on port `5681`.

To access {{site.mesh_product_name}} you can navigate to [`127.0.0.1:5681`](http://127.0.0.1:5681) to see the HTTP API.

You will notice that {{site.mesh_product_name}} automatically creates a [`Mesh`](/mesh/) entity with name `default`.

{% endtab %}
{% tab kumactl (Read & Write) %}

You can use the `kumactl` CLI to perform **read and write** operations on {{site.mesh_product_name}} resources. The `kumactl` binary is a client to the {{site.mesh_product_name}} HTTP API. For example:

```sh
kumactl get meshes
# NAME          mTLS      METRICS      LOGGING   TRACING
# default       off       off          off       off
```

or you can enable mTLS on the `default` Mesh with:

```sh
echo "type: Mesh
name: default
mtls:
  enabledBackend: ca-1
  backends:
  - name: ca-1
    type: builtin" | kumactl apply -f -
```

You can configure `kumactl` to point to any zone `kuma-cp` instance by running:

```sh
kumactl config control-planes add --name=XYZ --address=http://{address-to-kuma}:5681
```

You will notice that {{site.mesh_product_name}} automatically creates a [`Mesh`](/mesh/) entity with name `default`.

{% endtab %}
{% endtabs %}
{% endtab %}
{% endtabs %}

{{site.mesh_product_name}}, being an application that improves the underlying connectivity between your services by making the underlying network more reliable, also comes with some networking requirements itself.

## Control plane ports

First and foremost, the `kuma-cp` application is a server that offers a number of services - some meant for internal consumption by `kuma-dp` data plane proxies and some meant for external consumption by `kumactl`, the HTTP API, the GUI or other systems.

The number and type of exposed ports depends on the mode in which the control plane is running as:

### Global control plane

When {{site.mesh_product_name}} is run as a distributed service mesh, the global control plane exposes the following ports:

* TCP
    * `5443`: the port for the admission webhook, only enabled in `Kubernetes`. The default Kubernetes `{{site.mesh_cp_name}}` service exposes this port on `443`.
    * `5680`: the HTTP server that returns the health status of the control plane.
    * `5681`: the HTTP API server that is being used by `kumactl`, and that you can also use to retrieve {{site.mesh_product_name}}'s policies and - when running in `universal` - that you can use to apply new policies. Manipulating Dataplane resources is not possible. It also exposes the {{site.mesh_product_name}} GUI at `/gui`
    * `5682`: HTTPS version of the services available under `5681`
    * `5683`: gRPC Intercommunication CP server used internally by {{site.mesh_product_name}} to communicate between CP instances.
    * `5685`: the {{site.mesh_product_name}} Discovery Service port, leveraged in multi-zone deployments

### Zone control plane

When {{site.mesh_product_name}} is run as a distributed service mesh, the zone control plane exposes the following ports:

* TCP
    * `5443`: the port for the admission webhook, only enabled in `Kubernetes`. The default Kubernetes `{{site.mesh_cp_name}}` service exposes this port on `443`.
    * `5676`: the Monitoring Assignment server that responds to discovery requests from monitoring tools, such as `Prometheus`, that are looking for a list of targets to scrape metrics from.
    * `5678`: the server for the control plane to data plane proxy communication (bootstrap configuration, xDS to retrieve data plane proxy configuration, SDS to retrieve mTLS certificates).
    * `5680`: the HTTP server that returns the health status and metrics of the control plane.
    * `5681`: the HTTP API server that is being used by `kumactl`. You can also use it to retrieve {{site.mesh_product_name}}'s policies and, when running in `universal`, you can manage Dataplane resources. When not connected to global, it also exposes the {{site.mesh_product_name}} GUI at `/gui`
    * `5682`: HTTPS version of the services available under `5681`
    * `5683`: gRPC Intercommunication CP server used internally by {{site.mesh_product_name}} to communicate between CP instances.
