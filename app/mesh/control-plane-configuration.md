---
title: "{{site.mesh_product_name}} control plane configuration"
description: Learn how to configure the {{site.mesh_product_name}} control plane using environment variables or YAML, with details on store types (memory, Kubernetes, PostgreSQL) and configuration inspection.
content_type: reference
layout: reference
products:
  - mesh
breadcrumbs:
  - /mesh/

tags:
  - control-plane

related_resources:
  - text: Policy Hub
    url: /mesh/policies/
  - text: Use Kong as a delegated Gateway
    url: '/mesh/gateway-delegated/'
  - text: Data plane health
    url: /mesh/dataplane-health/
---

There are two ways to customize the {{site.mesh_product_name}} control plane configuration:
- With environment variables
- With a YAML configuration file

If both are specified, environment variables take precedence over YAML configuration.

All possible parameters and their default values are in the [`kuma-cp` reference doc](/mesh/reference/kuma-cp/).

{:.info}
> Environment variables usually match the YAML path by replacing `.` with `_`, capitalizing names and prefixing with `KUMA_`.
> For example, for the YAML path `store.postgres.port`, the corresponding environment variable is `KUMA_STORE_POSTGRES_PORT`.

## Configuration examples

The following examples show you how to apply configuration with environment variables or a YAML file, on Kubernetes or Universal.

These examples show you how to set the refresh interval, but the format applies to all {{site.mesh_product_name}} control plane configuration options.

### Kubernetes

{% navtabs "Kubernetes" %}
{% navtab "Environment variables" %}
To configure the {{site.mesh_product_name}} control plane on Kubernetes with environment variables, use the `envVars` field:

{% cpinstall envars %}
controlPlane.envVars.KUMA_XDS_SERVER_DATAPLANE_CONFIGURATION_REFRESH_INTERVAL=5s
controlPlane.envVars.KUMA_XDS_SERVER_DATAPLANE_STATUS_FLUSH_INTERVAL=5s
{% endcpinstall %}
{% endnavtab %}
{% navtab "YAML configuration file" %}

To configure a {{site.mesh_product_name}} control plane on Kubernetes with a YAML file, create a `values.yaml` file with the following content:
```yaml
controlPlane:
  envVars:
    KUMA_XDS_SERVER_DATAPLANE_CONFIGURATION_REFRESH_INTERVAL: 5s
    KUMA_XDS_SERVER_DATAPLANE_STATUS_FLUSH_INTERVAL: 5s
```
Use this configuration file in the Helm install command:

```sh
helm install -f values.yaml {{ site.mesh_helm_install_name }} {{ site.mesh_helm_repo }}
```

If you have a lot of configuration to customize, you can write it all in a YAML file and use:

```sh
helm install {{ site.mesh_helm_install_name }} {{ site.mesh_helm_repo }} --set-file {{site.set_flag_values_prefix}}controlPlane.config=cp-conf.yaml
```

The value of the ConfigMap `{{site.mesh_cp_name}}-config` is now the content of `cp-conf.yaml`.

{% endnavtab %}
{% endnavtabs %}


### Universal

{% navtabs "Universal" %}
{% navtab "Environment variables" %}

To configure the {{site.mesh_product_name}} control plane on Universal with environment variables, use the following command:

```sh
KUMA_XDS_SERVER_DATAPLANE_CONFIGURATION_REFRESH_INTERVAL=5s \
  KUMA_XDS_SERVER_DATAPLANE_STATUS_FLUSH_INTERVAL=5s \
  kuma-cp run
```
{% endnavtab %}
{% navtab "YAML configuration file" %}

To configure the {{site.mesh_product_name}} control plane on Universal with a YAML file, create a `kuma-cp.conf.overrides.yaml` file with the following content:

```yaml
xdsServer:
  dataplaneConfigurationRefreshInterval: 5s
  dataplaneStatusFlushInterval: 5s
```

Use this configuration file in the `kuma-cp run` command:
```sh
kuma-cp run -c kuma-cp.conf.overrides.yaml
```

{:.warning}
> If you configure `kuma-cp` with a YAML file, make sure to provide only values that you want to override.
> Otherwise, upgrading {{site.mesh_product_name}} might be harder, because you need to keep track of your changes when replacing this file on every upgrade.

{% endnavtab %}
{% endnavtabs %}


## Inspecting the configuration

There are many ways to see your control plane configuration:

- In the `kuma-cp` logs, the configuration is logged on startup.
- Using the control plane API server `/config` endpoint (for example, `http://YOUR_CP_ADDRESS:5681/config`).
- In the UI's **Diagnostic** tab.
- Using the `kumactl inspect zones -o yaml` command on a global control plane in a multi-zone deployment.

## Store

When the {{site.mesh_product_name}} control plane is up and running, it needs to store its state.

{{site.mesh_product_name}} supports a few different types of store.
You can configure the backend storage by setting the `KUMA_STORE_TYPE` environment variable or `store.type` in the YAML configuration file when running the control plane. The following values are supported:
- `kubernetes`
- `memory`
- `postgres`

### Kubernetes

{{site.mesh_product_name}} stores all the state in the underlying Kubernetes cluster.

This is only usable if the control plane is running in Kubernetes mode. You can't manage Universal control planes from a control plane with a Kubernetes store.

### Memory

{{site.mesh_product_name}} stores all the state in-memory. Restarting {{site.mesh_product_name}} deletes all the data, and you can't have more than one control plane instance running.

Memory is the **default** memory store when running in Universal mode and is only available in Universal mode.

{:.danger}
> Don't use this store in production, as the state isn't persisted.

### PostgreSQL

{{site.mesh_product_name}} stores all the state in a PostgreSQL database. This can only be used when running in Universal mode.

To configure it, run the following command with your database details:

```sh
KUMA_STORE_TYPE=postgres \
  KUMA_STORE_POSTGRES_HOST=localhost \
  KUMA_STORE_POSTGRES_PORT=5432 \
  KUMA_STORE_POSTGRES_USER=kuma-user \
  KUMA_STORE_POSTGRES_PASSWORD=kuma-password \
  KUMA_STORE_POSTGRES_DB_NAME=kuma \
  kuma-cp run
```

#### TLS

Connections between PostgreSQL and {{site.mesh_product_name}} control planes should be secured with TLS.
You can configure the TLS mode with the `KUMA_STORE_POSTGRES_TLS_MODE` environment variable, or the `store.postgres.tls.mode` YAML path.

The following modes are available to secure the connection to PostgreSQL:
* `disable`: The connection is not secured with TLS. Secrets will be transmitted over network in plain text.
* `verifyNone`: The connection is secured but the hostname and the signing CA are not checked.
* `verifyCa`: The connection is secured and the certificate presented by the server is verified using the provided CA.
* `verifyFull`: The connection is secured, the certificate presented by the server is verified using the provided CA, and the server hostname must match the one in the certificate.

For the`verifyCA` and `verifyFull` options, you also need to configure the `KUMA_STORE_POSTGRES_TLS_CA_PATH` environment variable or the `store.postgres.tls.capath` YAML path.

After configuring the PostgreSQL TLS security settings in {{site.mesh_product_name}}, you also have to configure PostgreSQL's [`pg_hba.conf`](https://www.postgresql.org/docs/9.1/auth-pg-hba-conf.html) file to restrict unsecured connections.

Here is an example configuration that allows only TLS connections and requires a username and password:

```sh
# TYPE  DATABASE        USER            ADDRESS                 METHOD
hostssl all             all             0.0.0.0/0               password
```

You can also provide a client key and certificate for mTLS using the `KUMA_STORE_POSTGRES_TLS_CERT_PATH` and `KUMA_STORE_POSTGRES_TLS_KEY_PATH` variables, or their YAML paths.
This pair can be used in conjunction with the `cert` authentication method. For more information, see the [PostgreSQL documentation](https://www.postgresql.org/docs/9.1/auth-pg-hba-conf.html).

#### Migrations

To simplify upgrades to new versions, {{site.mesh_product_name}} provides a migration system for the PostgreSQL database schema.

When upgrading to a new version of {{site.mesh_product_name}}, run `kuma-cp migrate up` to apply the new schema:

```sh
KUMA_STORE_TYPE=postgres \
  KUMA_STORE_POSTGRES_HOST=localhost \
  KUMA_STORE_POSTGRES_PORT=5432 \
  KUMA_STORE_POSTGRES_USER=kuma-user \
  KUMA_STORE_POSTGRES_PASSWORD=kuma-password \
  KUMA_STORE_POSTGRES_DB_NAME=kuma \
  kuma-cp migrate up
```

When it starts, the {{site.mesh_product_name}} control plane checks if the current database schema is compatible with the version of {{site.mesh_product_name}} you are trying to run.

Information about the latest migration is stored in `schema_migration` table.
