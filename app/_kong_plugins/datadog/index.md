---
title: 'Datadog'
name: 'Datadog'

content_type: plugin

publisher: kong-inc
description: 'Visualize metrics on Datadog'
products:
    - gateway

works_on:
    - on-prem
    - konnect

topologies:
  on_prem:
    - hybrid
    - db-less
    - traditional
  konnect_deployments:
    - hybrid
    - cloud-gateways
    - serverless
icon: datadog.png

categories:
  - analytics-monitoring

min_version:
  gateway: '1.0'
---

This plugin lets you log metrics for a [Gateway Service](/gateway/entities/service/) or [Route](/gateway/entities/route/) to a local [Datadog agent](https://docs.datadoghq.com/agent/basic_agent_usage/).

## Metrics
The Datadog plugin currently logs the following metrics to the Datadog server about a Service or Route:

{% table %}
columns:
  - title: Metric
    key: metric
  - title: Description
    key: description
  - title: Namespace
    key: namespace
rows:
  - metric: "`request_count`"
    description: Tracks the request
    namespace: "`kong.request.count`"
  - metric: "`request_size`"
    description: Tracks the request body size in bytes
    namespace: "`kong.request.size`"
  - metric: "`response_size`"
    description: Tracks the response body size in bytes
    namespace: "`kong.response.size`"
  - metric: "`latency`"
    description: Tracks the interval between the time the request started and the time the response was received from the upstream server
    namespace: "`kong.latency`"
  - metric: "`upstream_latency`"
    description: Tracks the time it took for the final service to process the request
    namespace: "`kong.upstream_latency`"
  - metric: "`kong_latency`"
    description: Tracks the internal {{site.base_gateway}} latency that it took to run all the plugins
    namespace: "`kong.kong_latency`"
{% endtable %}


The metrics will be sent with the tags `name` and `status` carrying the API name and HTTP status code respectively. If you specify `consumer_identifier` with the metric, a `consumer` tag will be added.

All metrics get logged by default. You can customize the metrics logged with the [`config.metrics`](./reference/#schema--config-metrics) parameter. Note that metrics with `stat_type` set to `counter` or `gauge` must have `sample_rate` defined as well.

## Migrating Datadog queries
The plugin updates replace the API, status, and consumer-specific metrics with a generic metric name.
You must change your Datadog queries in dashboards and alerts to reflect the metrics updates.

For example, the following query:
```
avg:kong.sample_service.latency.avg{*}
```
would need to change to:

```
avg:kong.latency.avg{name:sample-service}
```

## Setting host and port per {{site.base_gateway}} node

When installing a multi-data center setup, you might want to set Datadog's agent host and port for each {{site.base_gateway}} node. This configuration is possible by setting the host and port properties with environment variables.

{% table %}
columns:
  - title: Field
    key: field
  - title: Description
    key: description
  - title: Data types
    key: datatype
rows:
  - field: "`KONG_DATADOG_AGENT_HOST`"
    description: The IP address or hostname to send data to
    datatype: string
  - field: "`KONG_DATADOG_AGENT_PORT`"
    description: The port to send data to on the upstream server
    datatype: integer
{% endtable %}

{:.info}
> **Note:** The `host` and `port` fields in the plugin configuration take precedence over environment variables.
> For Kubernetes, there is a known limitation that you can't set `host` to null to use the environment variable. 
> You can work around this by using a [Vault reference](/gateway/entities/vault/), for example: `{vault://env/kong-datadog-agent-host}`. 
> For more information, see [Configure with Kubernetes](#configure-with-kubernetes).

## {{site.base_gateway}} process errors

{% include /plugins/logging/kong-process-errors.md %}


## Configure with Kubernetes

In most Kubernetes setups, `datadog-agent` runs as a daemon set. 
This means that a `datadog-agent` runs on each node in the Kubernetes cluster, and {{site.base_gateway}} must forward metrics to the `datadog-agent` running on the same node as {{site.base_gateway}}. 

This can be accomplished by providing the IP address of the Kubernetes worker node to {{site.base_gateway}}, then configuring the plugin to use that IP address using environment variables.

{% navtabs "Kubernetes" %}
{% navtab "Helm" %}

Modify the `env` section in `values.yaml`:

```yaml
env:
  datadog_agent_host:
    valueFrom:
      fieldRef:
        fieldPath: status.hostIP
```

Update the Helm deployment:

```sh
helm upgrade -f values.yaml $RELEASE_NAME kong/kong --version $VERSION --namespace $NAMESPACE
```

Modify the plugin's configuration:

    ```yaml
    apiVersion: configuration.konghq.com/v1
    kind: KongClusterPlugin
    metadata:
      name: datadog
      annotations:
        kubernetes.io/ingress.class: kong
      labels:
        global: "true"
    config:
      host: "{vault://env/kong-datadog-agent-host}"
      port: 8125
    ```

{% endnavtab %}
{% navtab "Kubernetes YAML" %}

Modify the `env` section in `values.yaml`:

```yaml
env:
  - name: KONG_DATADOG_AGENT_HOST
    valueFrom:
      fieldRef:
        fieldPath: status.hostIP
```

Modify the plugin's configuration:

```yaml
apiVersion: configuration.konghq.com/v1
kind: KongClusterPlugin
metadata:
  name: datadog
  annotations:
    kubernetes.io/ingress.class: kong
  labels:
    global: "true"
config:
  host: "{vault://env/kong-datadog-agent-host}"
  port: 8125
```
{% endnavtab %}
{% endnavtabs %}

## Queuing

{% include_cached /plugins/queues.md name=page.name %}