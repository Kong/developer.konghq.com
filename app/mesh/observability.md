---
title: Observability
description: Learn how to configure observability in {{site.mesh_product_name}} using Prometheus, Grafana, Jaeger, Loki, and Datadog.
content_type: reference
layout: reference
products:
  - mesh
breadcrumbs:
  - /mesh/
tags:
  - observability
  - metrics
  - tracing
min_version:
  mesh: '2.6'
related_resources:
  - text: Audit logs
    url: /mesh/access-audit/
  - text: '{{site.mesh_product_name}} resource sizing guidelines'
    url: '/mesh/resource-sizing-guidelines/'
  - text: '{{site.mesh_product_name}} version compatibility'
    url: '/mesh/version-compatibility/'
  - text: Policy Hub
    url: /mesh/policies/
  - text: Mesh CLI
    url: /mesh/cli/
  - text: Data plane health
    url: /mesh/dataplane-health/
---

This page describes how to configure different observability tools to work with {{site.mesh_product_name}}.

`kumactl` ships with a built-in observability stack that includes:

- [Prometheus](https://prometheus.io) for metrics
- [Jaeger](https://jaegertracing.io) for ingesting and storing traces
- [Loki](https://grafana.com/oss/loki/) for ingesting and storing logs
- [Grafana](https://grafana.com/oss/grafana/) for querying and displaying metrics, traces, and logs

To enable observability, you need the following policies:

- [`MeshMetric`](/mesh/policies/meshmetric/) for telemetry
- [`MeshTrace`](/mesh/policies/meshtrace/) for tracing
- [`MeshAccessLog`](/mesh/policies/meshaccesslog/) for logging

On Kubernetes, the stack can be installed with:

```sh
kumactl install observability | kubectl apply -f -
```

This creates a namespace named `mesh-observability` with Prometheus, Jaeger, Loki, and Grafana installed and set up to work with {{site.mesh_product_name}}.

{:.warning}
> This setup is meant for testing purposes. Do not use it for production.
> For production setups, we recommend referring to each project's website or using a hosted solution such as Grafana Cloud or Datadog.

## Control plane observability

The control plane supports metrics and traces for observability.

### Metrics

Control plane metrics are exposed on port `:5680` and available under the standard path `/metrics`.

### Traces

You can configure {{site.mesh_product_name}} to export OpenTelemetry traces. It exports traces for:

* API server
* KDS on global (only basic information about the connections to zones are traced, nothing resource-specific)
* Inter-CP server

To enable tracing, set the `KUMA_TRACING_OPENTELEMETRY_ENABLED` or `tracing.openTelemetry.enabled` control plane
config variable to `"true"` and configure OpenTelemetry using the
[standard `OTEL_EXPORTER_OTLP_*` environment variables](https://opentelemetry.io/docs/languages/sdk-configuration/otlp-exporter).

## Configure Prometheus

The Kuma community has contributed built-in service discovery for Prometheus. It is documented in the [Prometheus docs](https://prometheus.io/docs/prometheus/latest/configuration/configuration/#kuma_sd_config).
This service discovery connects to the control plane and retrieves all data planes with enabled metrics, which Prometheus scrapes and retrieves according to your [`MeshMetric` policies](/mesh/policies/meshmetric).

There are three ways to run Prometheus:

1. Inside the mesh (default with `kumactl install observability`).
2. Outside the mesh. In this case, you must specify `tls.mode: disabled` in the `MeshMetric` configuration. This is less secure but ensures Prometheus is as available as possible. It's also easier to add to an existing setup with services in and outside the mesh.
3. Outside the mesh with TLS enabled. In this case, you need to provide certificates for each data plane and specify the configuration in the `MeshMetric` policy. This is more secure than the second option but requires more configuration.

In production, we recommend the second option because it provides better visibility when things go wrong, and it's usually acceptable for metrics to be less secure.

### Use an existing prometheus setup

In Prometheus version 2.29 or later, you can add {{site.mesh_product_name}} metrics to your `prometheus.yml`:

```yaml
scrape_configs:
  - job_name: 'kuma-dataplanes'
    scrape_interval: "5s"
    relabel_configs:
      - source_labels:
          - __meta_kuma_mesh
        regex: "(.*)"
        target_label: mesh
      - source_labels:
          - __meta_kuma_dataplane
        regex: "(.*)"
        target_label: dataplane
      - action: labelmap
        regex: __meta_kuma_label_(.+)
    kuma_sd_configs:
      - server: "http://{{site.mesh_cp_name}}.{{site.mesh_namespace}}.svc:5676"
```

For more information, see [the Prometheus documentation](https://prometheus.io/docs/prometheus/latest/configuration/configuration/#kuma_sd_config).

If you have [`MeshMetric`](/mesh/policies/meshmetric) enabled for your mesh, check the **Targets** page in the Prometheus dashboard.
You should see a list of data plane proxies from your mesh.

## Configure Grafana

You can use Grafana to visualize traces from Jaeger and logs from Loki, and the Kuma community ships dashboards and a data source for deeper integration.

### Visualize traces

To visualize your traces with Grafana, you can configure a new data source with the URL `http://jaeger-query.mesh-observability/` (or any other URL Jaeger can be queried at).
Grafana can then retrieve traces from Jaeger.

You can then add a [`MeshTrace` policy](/mesh/policies/meshtrace) to your mesh to start emitting traces.
At this point you can visualize your traces in Grafana by choosing the Jaeger data source in the [**Explore** section](https://grafana.com/docs/grafana/latest/explore/).

### Visualize logs

To visualize your containers' logs and your access logs with Grafana, you can then add a [`MeshAccessLog` policy](/mesh/policies/meshaccesslog) to your mesh to start emitting access logs. Loki picks up logs that are sent to `stdout`. To send logs to `stdout`, you can configure the logging backend as shown below:

{% navtabs "environment" %}
{% navtab "Kubernetes" %}
```yaml
apiVersion: kuma.io/v1alpha1
kind: Mesh
metadata:
  name: default
spec:
  logging:
    defaultBackend: stdout
    backends:
      - name: stdout
        type: file
        conf:
          path: /dev/stdout
```

{% endnavtab %}
{% navtab "Universal" %}
```yaml
type: Mesh
name: default
logging:
  defaultBackend: stdout
  backends:
    - name: stdout
      type: file
      conf:
        path: /dev/stdout
```
{% endnavtab %}
{% endnavtabs %}

You can then visualize your containers' logs and your access logs in Grafana by choosing the Loki data source in the [**Explore** section](https://grafana.com/docs/grafana/latest/explore/).

For example, running `{container="kuma-sidecar"} |= "GET"` shows all GET requests on your cluster.
For more information about the search syntax, see the [Loki docs](https://grafana.com/docs/loki/latest/logql/).

### Grafana extensions

The Kuma community has built a data source and a set of dashboards to provide better integrations between {{site.mesh_product_name}} and Grafana.

#### Data source and service map

The Grafana data source is specifically built to relate information from the control plane with Prometheus metrics.

Current features include:

- Display the graph of your services with MeshGraph using the [Grafana node graph panel](https://grafana.com/docs/grafana/latest/visualizations/node-graph/).
- List meshes.
- List zones.
- List services.

To use the plugin, you need to add the binary to your Grafana instance by following the [installation instructions](https://github.com/kumahq/kuma-grafana-datasource).

The data source is installed and configured when using `kumactl install observability`.

#### Dashboards

{{site.mesh_product_name}} ships with default dashboards that are available to import from [the Grafana Labs repository](https://grafana.com/orgs/konghq):

* **Kuma CP**: Investigate control plane statistics.
* **Kuma Dataplane**: Investigate the status of a single data plane in the mesh. To see these metrics, you need to create a [`MeshMetric` policy](/mesh/policies/meshmetric) first.
* **Kuma Gateway**: Investigate aggregated statistics for each built-in gateway.
* **Kuma Mesh**: Investigate the aggregated statistics of a single mesh. It provides a topology view of your service traffic dependencies (**Service Map**) and includes information such as the number of requests and error rates.
* **Kuma Service**: Investigate aggregated statistics for each service.
* **Kuma Service to Service**: Investigate aggregated statistics from data planes of specified source services to data planes of specified destination services.

## Configure Datadog

The recommended way to use Datadog is with its [agent](https://docs.datadoghq.com/agent).

### Metrics

{{site.mesh_product_name}} exposes metrics with the [`MeshMetric` policy](/mesh/policies/meshmetric) in Prometheus format.

You can add annotations to your Pods to enable the Datadog agent to scrape metrics.

For Kubernetes, refer to the dedicated [documentation](https://docs.datadoghq.com/containers/kubernetes/prometheus/?tab=helm#metric-collection-with-prometheus-annotations-prometheus-check).

On Universal, set up your agent with an [openmetrics.d/conf.yaml](https://docs.datadoghq.com/integrations/guide/prometheus-host-collection/#pagetitle).

### Tracing

To configure tracing using Datadog on Universal, see the [Datadog agent docs](https://docs.datadoghq.com/agent).


On Kubernetes, configure the [Datadog agent for APM](https://docs.datadoghq.com/agent/kubernetes/apm/).

If Datadog isn't running on each node, you can expose the APM agent port to {{site.mesh_product_name}} via a Kubernetes service.
```yaml
apiVersion: v1
kind: Service
metadata:
  name: trace-svc
spec:
  selector:
    app.kubernetes.io/name: datadog-agent-deployment
  ports:
    - protocol: TCP
      port: 8126
      targetPort: 8126
```

Check that the label of the installed Datadog pod hasn't changed (`app.kubernetes.io/name: datadog-agent-deployment`).
If it changed, adjust accordingly.

Once the agent is configured to ingest traces, you must configure a [MeshTrace policy](/mesh/policies/meshtrace).

### Logs

The best way to have {{site.mesh_product_name}} and Datadog work together is with [TCP ingest](https://docs.datadoghq.com/agent/logs/?tab=tcpudp#custom-log-collection).

Once your agent is configured with TCP ingest, you can configure a [`MeshAccessLog` policy](/mesh/policies/meshaccesslog) for data plane proxies to send logs.

## Observability in multi-zone

The following sections explain how to architect your telemetry stack to accommodate multi-zone deployments.

### Prometheus

When {{site.mesh_product_name}} is used in multi-zone, the recommended approach is to use one Prometheus instance in each zone and send the metrics of each zone to a global Prometheus instance.

Prometheus offers different ways to do this:

* [Federation](https://prometheus.io/docs/prometheus/latest/federation/): The global Prometheus scrapes Prometheus in each zone.
* [Remote Write](https://prometheus.io/docs/prometheus/latest/storage/#remote-storage-integrations): Prometheus in each zone directly writes metrics to the global instance. This is usually more efficient than federation.
* [Remote Read](https://prometheus.io/docs/prometheus/latest/storage/#remote-storage-integrations): The global Prometheus reads metrics from the zone instances.

### Jaeger, Loki, Datadog, and others

Most telemetry components don't have a hierarchical setup like Prometheus.
If you want to have a central view of everything, you can set up the system in the global instance and have each zone send data to it.
Because the zone is present in the data plane tags, metrics, logs, and traces should not overlap between zones.

## Known issues

The following are known observability issues in {{site.mesh_product_name}}.

### MADS server bug in 2.6.0

Version 2.6.0 of {{site.mesh_product_name}} introduced a [bug in the MADS server](https://github.com/kumahq/kuma/issues/9508) that was fixed in version 2.7.0.
This bug can cause delays in delivering monitoring assignments to Prometheus if you changed the default Prometheus configuration for `kuma_sd_configs.fetch_timeout`.
This results in Prometheus not collecting metrics from new data plane proxies during that period.

To fix this issue, configure `kuma_sd_configs` as follows:

```yaml
kuma_sd_configs:
  - fetch_timeout: 0s
```

This disables long polling on Prometheus service discovery.
