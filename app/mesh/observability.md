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

## Demo setup

`kumactl` ships with a built-in observability stack which consists of:

- [prometheus](https://prometheus.io) for metrics
- [jaeger](https://jaegertracing.io) for ingesting and storing traces
- [loki](https://grafana.com/oss/loki/) for ingesting and storing logs
- [grafana](https://grafana.com/oss/grafana/) for querying and displaying metrics, traces, and logs

First, remember to configure {{site.mesh_product_name}} appropriately for the tools in the observability stack:

{% if_version lte:2.5.x %}
- [Traffic metrics](/mesh/policies/traffic-metrics) for telemetry
- [`TrafficTrace`](/mesh/policies/traffic-trace) for tracing
- [`TrafficLog`](/mesh/policies/traffic-log) for logging
{% endif_version %}

{% if_version gte:2.6.x %}
- [`MeshMetric`](/mesh/policies/meshmetric) for telemetry
- [`MeshTrace`](/mesh/policies/meshtrace) for tracing
- [`MeshAccessLog`](/mesh/policies/meshaccesslog) for logging
{% endif_version %}

On Kubernetes, the stack can be installed with:

```shell
kumactl install observability | kubectl apply -f -
```

This creates a namespace named `mesh-observability` with prometheus, jaeger, loki, and grafana installed and set up to work with {{site.mesh_product_name}}.

{:.warning}
> This setup is meant to be used for trying out {{site.mesh_product_name}}. It is not fit for production use.
> For production setups, we recommend referring to each project's website or using a hosted solution such as Grafana Cloud or Datadog.

## Control plane observability

The control plane supports metrics and traces for observability.

### Metrics

Control plane metrics are exposed on port `:5680` and available under the standard path `/metrics`.

{% if_version gte:2.4.x %}
### Traces

{{site.mesh_product_name}} can be configured to export OpenTelemetry traces. It exports traces for:

* API server
* KDS on global
  * Note only basic information about the connections to zones are traced,
    nothing resource specific
* Inter CP server

To enable tracing, set the `KUMA_TRACING_OPENTELEMETRY_ENABLED` or `tracing.openTelemetry.enabled` control plane
config variable to `"true"` and configure OpenTelemetry using the
[standard `OTEL_EXPORTER_OTLP_*` environment variables](https://opentelemetry.io/docs/languages/sdk-configuration/otlp-exporter).
{% endif_version %}

## Configure Prometheus

{% if_version gte:2.6.x %}
{:.warning}
> Version 2.6.0 of {{site.mesh_product_name}} introduced a [bug in the MADS server](https://github.com/kumahq/kuma/issues/9508).
> This bug can cause delays in delivering monitoring assignments to Prometheus if you changed the default prometheus configuration for `kuma_sd_configs.fetch_timeout`.
> This results in Prometheus not collecting metrics from new data plane proxies during that period.
> To fix this issue, configure `kuma_sd_configs` as follows:
>
> ```yaml
> kuma_sd_configs:
>   - fetch_timeout: 0s
> ```
>
> This disables long polling on Prometheus service discovery.
{% endif_version %}

The {{site.mesh_product_name}} community has contributed built-in service discovery for Prometheus. It is documented in the [Prometheus docs](https://prometheus.io/docs/prometheus/latest/configuration/configuration/#kuma_sd_config).
This service discovery connects to the control plane and retrieves all data planes with enabled metrics, which Prometheus scrapes and retrieves according to your {% if_version lte:2.5.x inline:true %}[traffic metrics setup](/mesh/policies/traffic-metrics){% endif_version %}{% if_version gte:2.6.x inline:true %}[MeshMetric policies](/mesh/policies/meshmetric){% endif_version %}.

{:.info}
> There are 2 ways to run prometheus:
>
> 1. Inside the mesh (default for [`kumactl install observability`](#demo-setup)).{% if_version lte:2.5.x inline:true %} In this case you can use mTLS to retrieve metrics. This provides high security but requires one prometheus per mesh and might not be accessible if your mesh becomes unavailable. It also requires one Prometheus deployment per {{site.mesh_product_name}} mesh.{% endif_version %}
> 2. Outside the mesh. In this case you need to specify {% if_version lte:2.3.x %}`skipMTLS: true`{% endif_version %}{% if_version gte:2.4.x %}`tls.mode: disabled`{% endif_version %} in the {% if_version lte:2.5.x inline:true %}[traffic metrics configuration](/mesh/policies/traffic-metrics){% endif_version %}{% if_version gte:2.6.x inline:true %}[MeshMetric configuration](/mesh/policies/meshmetric){% endif_version %}. This is less secure but ensures Prometheus is as available as possible. It is also easier to add to an existing setup with services in and outside the mesh.
> {% if_version gte:2.4.x %}
> 3. Outside the mesh with TLS enabled. In this case you need to provide certificates for each data plane and specify configuration in the {% if_version lte:2.5.x inline:true %}[traffic metrics configuration](/mesh/policies/traffic-metrics){% endif_version %}{% if_version gte:2.6.x inline:true %}[MeshMetric configuration](/mesh/policies/meshmetric){% endif_version %}. This is more secure than the second option but requires more configuration.
> {% endif_version %}
>
> In production, we recommend the second option because it provides better visibility when things go wrong, and it is usually acceptable for metrics to be less secure.

### Use an existing prometheus setup

In Prometheus version 2.29 and later, you can add {{site.mesh_product_name}} metrics to your `prometheus.yml`:

```sh
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
      - server: "http://{{site.mesh_cp_name}}.{{site.mesh_namespace}}.svc:5676" # replace with the URL of your control plane
```

For more information, see [the Prometheus documentation](https://prometheus.io/docs/prometheus/latest/configuration/configuration/#kuma_sd_config).

If you have {% if_version lte:2.5.x inline:true %}[traffic metrics](/mesh/policies/traffic-metrics){% endif_version %}{% if_version gte:2.6.x inline:true %}[MeshMetric](/mesh/policies/meshmetric){% endif_version %} enabled for your mesh, check the Targets page in the Prometheus dashboard.
You should see a list of data plane proxies from your mesh. For example:

<center>
<img src="/assets/images/docs/0.4.0/prometheus-targets.png" alt="A screenshot of Targets page on Prometheus UI" style="width: 600px; padding-top: 20px; padding-bottom: 10px;"/>
</center>

## Configure Grafana

### Visualize traces

To visualize your **traces**, you need to have Grafana up and running.

{:.info}
> [`kumactl install observability`](#demo-setup) sets this up out of the box.

With Grafana installed, you can configure a new data source with URL `http://jaeger-query.mesh-observability/` (or whatever URL jaeger can be queried at).
Grafana can then retrieve traces from Jaeger.

<center>
<img src="/assets/images/docs/jaeger_grafana_config.jpg" alt="Jaeger Grafana configuration" style="width: 600px; padding-top: 20px; padding-bottom: 10px;"/>
</center>

You can then add a {% if_version lte:2.5.x inline:true %}[TrafficTrace policy](/mesh/policies/traffic-trace){% endif_version %}{% if_version gte:2.6.x inline:true %}[MeshTrace policy](/mesh/policies/meshtrace){% endif_version %} to your mesh to start emitting traces.
At this point you can visualize your traces in Grafana by choosing the jaeger data source in the [Explore section](https://grafana.com/docs/grafana/latest/explore/).

### Visualize logs

To visualize your **containers' logs** and your **access logs**, you need to have Grafana up and running.

{:.info}
> [`kumactl install observability`](#demo-setup) sets this up out of the box.

<center>
<img src="/assets/images/docs/loki_grafana_config.jpg" alt="Loki Grafana configuration" style="width: 600px; padding-top: 20px; padding-bottom: 10px;"/>
</center>

You can then add a {% if_version lte:2.5.x inline:true %}[TrafficLog policy](/mesh/policies/traffic-log){% endif_version %}{% if_version gte:2.6.x inline:true %}[MeshAccessLog policy](/mesh/policies/meshaccesslog){% endif_version %} to your mesh to start emitting access logs. Loki picks up logs that are sent to `stdout`. To send logs to `stdout`, you can configure the logging backend as shown below:

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

At this point you can visualize your **containers' logs** and your **access logs** in Grafana by choosing the loki data source in the [Explore section](https://grafana.com/docs/grafana/latest/explore/).

For example, running `{container="kuma-sidecar"} |= "GET"` shows all GET requests on your cluster.
To learn more about the search syntax, check the [Loki docs](https://grafana.com/docs/loki/latest/logql/).

{:.info}
> **Nice to have**
>
> Having logs and traces in the same visualization tool can be very useful. By adding the `traceId` in your app logs, you can visualize your logs and the related Jaeger traces.
> To learn more, read [this article](https://grafana.com/blog/2020/05/22/new-in-grafana-7.0-trace-viewer-and-integrations-with-jaeger-and-zipkin/).

### Grafana extensions

The {{site.mesh_product_name}} community has built a data source and a set of dashboards to provide better integrations between {{site.mesh_product_name}} and Grafana.

#### Data source and service map

The Grafana data source is specifically built to relate information from the control plane with Prometheus metrics.

Current features include:

- Display the graph of your services with MeshGraph using the [Grafana nodeGraph panel](https://grafana.com/docs/grafana/latest/visualizations/node-graph/).
- List meshes.
- List zones.
- List services.

To use the plugin, you need to add the binary to your Grafana instance by following the [installation instructions](https://github.com/kumahq/kuma-grafana-datasource).

To make things simpler, the data source is installed and configured when using [`kumactl install observability`](#demo-setup).

#### Dashboards

{{site.mesh_product_name}} ships with default dashboards that are available to import from [the Grafana Labs repository](https://grafana.com/orgs/konghq).

##### {{site.mesh_product_name}} Dataplane

This dashboard lets you investigate the status of a single data plane in the mesh. To see these metrics, you need to create {% if_version lte:2.5.x inline:true %}[Traffic Metrics policy](/mesh/policies/traffic-metrics){% endif_version %}{% if_version gte:2.6.x inline:true %}[MeshMetric policy](/mesh/policies/meshmetric){% endif_version %} first.

<center>
<img src="/assets/images/docs/0.4.0/kuma_dp1.jpeg" alt="Kuma Dataplane dashboard" style="width: 600px; padding-top: 20px; padding-bottom: 10px;"/>
<img src="/assets/images/docs/0.4.0/kuma_dp2.png" alt="Kuma Dataplane dashboard" style="width: 600px; padding-top: 20px; padding-bottom: 10px;"/>
<img src="/assets/images/docs/0.4.0/kuma_dp3.png" alt="Kuma Dataplane dashboard" style="width: 600px; padding-top: 20px; padding-bottom: 10px;"/>
<img src="/assets/images/docs/1.1.2/kuma_dp4.png" alt="Kuma Dataplane dashboard" style="width: 600px; padding-top: 20px; padding-bottom: 10px;"/>
</center>

##### {{site.mesh_product_name}} Mesh

This dashboard lets you investigate the aggregated statistics of a single mesh.
It provides a topology view of your service traffic dependencies (**Service Map**)
and includes information such as number of requests and error rates.

<center>
<img src="/assets/images/docs/grafana_dashboard_mesh.png" alt="Kuma Mesh dashboard" style="width: 600px; padding-top: 20px; padding-bottom: 10px;"/>
</center>

##### {{site.mesh_product_name}} Service to service

This dashboard lets you investigate aggregated statistics from data planes of specified source services to data planes of specified destination service.

<center>
<img src="/assets/images/docs/0.4.0/kuma_service_to_service.png" alt="Kuma Service to Service dashboard" style="width: 600px; padding-top: 20px; padding-bottom: 10px;"/>
<img src="/assets/images/docs/1.1.2/kuma_service_to_service_http.png" alt="Kuma Service to Service HTTP" style="width: 600px; padding-top: 20px; padding-bottom: 10px;"/>
</center>

##### {{site.mesh_product_name}} CP

This dashboard lets you investigate control plane statistics.

<center>
<img src="/assets/images/docs/0.7.1/grafana-dashboard-kuma-cp1.png" alt="Kuma CP dashboard" style="width: 600px; padding-top: 20px; padding-bottom: 10px;"/>
<img src="/assets/images/docs/0.7.1/grafana-dashboard-kuma-cp2.png" alt="Kuma CP dashboard" style="width: 600px; padding-top: 20px; padding-bottom: 10px;"/>
<img src="/assets/images/docs/0.7.1/grafana-dashboard-kuma-cp3.png" alt="Kuma CP dashboard" style="width: 600px; padding-top: 20px; padding-bottom: 10px;"/>
</center>

##### {{site.mesh_product_name}} Service

This dashboard lets you investigate aggregated statistics for each service.

<center>
<img src="/assets/images/docs/1.1.2/grafana-dashboard-kuma-service.jpg" alt="Kuma Service dashboard" style="width: 600px; padding-top: 20px; padding-bottom: 10px;"/>
</center>

##### {{site.mesh_product_name}} MeshGateway

This dashboard lets you investigate aggregated statistics for each built-in gateway.

<center>
<img src="/assets/images/docs/grafana_dashboard_gateway.png" alt="Kuma Gateway dashboard" style="width: 600px; padding-top: 20px; padding-bottom: 10px;"/>
</center>

## Configure Datadog

The recommended way to use Datadog is with its [agent](https://docs.datadoghq.com/agent).

{% navtabs "environment" %}
{% navtab "Kubernetes" %}
The [Datadog agent docs](https://docs.datadoghq.com/agent/kubernetes/installation) have in-depth installation methods.
{% endnavtab %}

{% navtab "Universal" %}
Check out the [Datadog agent docs](https://docs.datadoghq.com/agent).
{% endnavtab %}
{% endnavtabs %}

### Metrics

{{site.mesh_product_name}} exposes metrics with {% if_version lte:2.5.x inline:true %}[traffic metrics](/mesh/policies/traffic-metrics){% endif_version %}{% if_version gte:2.6.x inline:true %}[MeshMetric policy](/mesh/policies/meshmetric){% endif_version %} in Prometheus format.

You can add annotations to your pods to enable the Datadog agent to scrape metrics.

{% navtabs "environment" %}
{% navtab "Kubernetes" %}
Please refer to the dedicated [documentation](https://docs.datadoghq.com/containers/kubernetes/prometheus/?tab=helm#metric-collection-with-prometheus-annotations-prometheus-check).
{% endnavtab %}

{% navtab "Universal" %}
You need to set up your agent with an [openmetrics.d/conf.yaml](https://docs.datadoghq.com/integrations/guide/prometheus-host-collection/#pagetitle).
{% endnavtab %}
{% endnavtabs %}

### Tracing

Check out the following:
1. Set up the [Datadog](https://docs.datadoghq.com/tracing/) agent.
2. Set up [APM](https://docs.datadoghq.com/tracing/).

{% navtabs "environment" %}
{% navtab "Kubernetes" %}
Configure the [Datadog agent for APM](https://docs.datadoghq.com/agent/kubernetes/apm/).

If Datadog is not running on each node, you can expose the APM agent port to {{site.mesh_product_name}} via a Kubernetes service.
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

Apply the configuration with `kubectl apply -f [..]`.

Check that the label of the installed Datadog pod has not changed (`app.kubernetes.io/name: datadog-agent-deployment`).
If it changed, adjust accordingly.
{% endnavtab %}

{% navtab "Universal" %}
Check out the [Datadog agent docs](https://docs.datadoghq.com/agent).
{% endnavtab %}
{% endnavtabs %}

Once the agent is configured to ingest traces, you need to configure a {% if_version lte:2.5.x inline:true %}[TrafficTrace policy](/mesh/policies/traffic-trace){% endif_version %}{% if_version gte:2.6.x inline:true %}[MeshTrace policy](/mesh/policies/meshtrace){% endif_version %}.

### Logs

The best way to have {{site.mesh_product_name}} and Datadog work together is with [TCP ingest](https://docs.datadoghq.com/agent/logs/?tab=tcpudp#custom-log-collection).

Once your agent is configured with TCP ingest, you can configure a {% if_version lte:2.5.x inline:true %}[TrafficLog policy](/mesh/policies/traffic-log){% endif_version %}{% if_version gte:2.6.x inline:true %}[MeshAccessLog policy](/mesh/policies/meshaccesslog){% endif_version %} for data plane proxies to send logs.

## Observability in multi-zone

{{site.mesh_product_name}} is multi-zone at heart. The following sections explain how to architect your telemetry stack to accommodate multi-zone.

### Prometheus

When {{site.mesh_product_name}} is used in multi-zone, the recommended approach is to use one Prometheus instance in each zone and send the metrics of each zone to a global Prometheus instance.

Prometheus offers different ways to do this:

- [Federation](https://prometheus.io/docs/prometheus/latest/federation/): The global Prometheus scrapes Prometheus in each zone.
- [Remote Write](https://prometheus.io/docs/prometheus/latest/storage/#remote-storage-integrations): Prometheus in each zone directly writes metrics to global. This is usually more efficient than federation.
- [Remote Read](https://prometheus.io/docs/prometheus/latest/storage/#remote-storage-integrations): Similar to remote write, but in the opposite direction.

### Jaeger, Loki, Datadog, and others

Most telemetry components do not have a hierarchical setup like Prometheus.
If you want to have a central view of everything, you can set up the system in global and have each zone send data to it.
Because zone is present in data plane tags, metrics, logs, and traces should not overlap between zones.
