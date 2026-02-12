---
title: "{{site.mesh_product_name}} CLI tools"
description: Reference for the CLI tools included in {{site.mesh_product_name}}, including usage examples and commands for kumactl, kuma-cp, and kuma-dp.
content_type: reference
layout: reference
products:
  - mesh
breadcrumbs:
  - /mesh/

works_on:
  - on-prem
  - konnect

related_resources:
  - text: 'kuma-cp configuration reference'
    url: '/mesh/reference/kuma-cp/'
  - text: Mesh observability
    url: '/mesh/observability/'
  - text: "{{site.mesh_product_name}} Policy Hub"
    url: /mesh/policies/
---

{{site.mesh_product_name}} ships in a bundle that includes a few executables:

* `kuma-cp`: The main {{site.mesh_product_name}} executable that runs the control plane.
* `kuma-dp`: The {{site.mesh_product_name}} data plane proxy executable that invokes `envoy`.
* `envoy`: The [Envoy](https://www.envoyproxy.io/) executable that we bundle into the archive for convenience.
* `kumactl`: The user CLI to interact with {{site.mesh_product_name}} (`kuma-cp`) and its data.
* `kuma-tcp-echo`: A sample application that echoes back the requests we make, used for demo purposes.

You can learn how to use each executable by running it with the `-h` flag:

```sh
kuma-cp -h
```

You can check their versions by running the `version [--detailed]` command:

```sh
kuma-cp version --detailed
```

## kumactl

The `kumactl` executable is your primary CLI tool for managing {{site.mesh_product_name}}. It allows you to:

* Retrieve the state of {{site.mesh_product_name}} and the configured [policies](/mesh/policies-introduction/) in every environment.
* Change the state of {{site.mesh_product_name}} by applying new policies with the `kumactl apply [..]` command.
  {:.info}
  > This is only possible on Universal. On Kubernetes, `kumactl` is read-only. You can change the state of {{site.mesh_product_name}} by leveraging its CRDs.
* Install {{site.mesh_product_name}} on Kubernetes, and configure the PostgreSQL schema on Universal (`kumactl install [..]`).

{:.info}
The `kumactl` application is a CLI client for the underlying {{site.mesh_product_name}} HTTP API. Therefore, you can access the state of {{site.mesh_product_name}} by leveraging with the API directly. On Universal, you can also make changes via the HTTP API, while on Kubernetes the HTTP API is read-only.


### kumactl commands
The following commands are available on `kumactl`:

* `kumactl install [..]`: Provides helpers to install {{site.mesh_product_name}} components in Kubernetes.
  * `kumactl install control-plane`: Installs {{site.mesh_product_name}} in Kubernetes in a `{{site.mesh_namespace}}` namespace.
  * `kumactl install observability`: Installs an observability (metrics, logging, tracing) backend in a Kubernetes cluster (Prometheus, Grafana, Loki, Jaeger, and Zipkin) in the `mesh-observability` namespace.
* `kumactl config [..]`: Configures the local or zone control planes that `kumactl` should talk to. You can have more than one enabled, and the configuration will be stored in `~/.kumactl/config`.
* `kumactl apply [..]`: Changes the state of {{site.mesh_product_name}}. Only available on Universal.
* `kumactl get [..]`: Retrieves the raw state of {{site.mesh_product_name}} entities.
* `kumactl inspect [..]`: Retrieves an augmented state of {{site.mesh_product_name}} entities.
* `kumactl generate dataplane-token`: Generates a [data plane token](/mesh/dp-auth/#data-plane-proxy-token).
* `kumactl generate tls-certificate`: Generates a TLS certificate for the client or server.
* `kumactl manage ca [..]`: Manages certificate authorities.
* `kumactl help [..]`: Explains the commands available.
* `kumactl version [--detailed]`: Shows the version of the program.

You can use `kumactl [cmd] --help` for documentation.

### Using variables

When using `kumactl apply`, you can specify variables to use your YAML as a template.
This is useful for configuring policies and specifying values at runtime.

For example, using the following YAML snippet:

```yaml
type: Mesh
name: default
mtls:
  backends:
  - name: vault-1
    type: {% raw %}{{ caType }}{% endraw %}
    dpCert:
      rotation:
        expiration: 10h
```

You can set the `caType` when applying the configuration:

```sh
kumactl apply -f ~/res/mesh.yaml -v caType=builtin
```

This will create the following mesh:

```yaml
type: Mesh
name: default
mtls:
  backends:
    - name: vault-1
      type: builtin
      dpCert:
        rotation:
          expiration: 10h
```

### Configuration

You can view the current configuration using `kumactl config view`.

The configuration is stored in `$HOME/.kumactl/config`, which is created when you run `kumactl` for the first time.
When you add a new control plane with `kumactl config control-planes add`, the config file is updated.
To change the path of the config file, run `kumactl` with `--config-file /new-path/config`.
