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
---

This plugin lets you log metrics for a [Gateway Service](/gateway/entities/service/) or [Route](/gateway/entities/route/) to a local [Datadog agent](https://docs.datadoghq.com/agent/basic_agent_usage/).

## Queueing

The Datadog plugin uses a queue to decouple the production and
consumption of data. This reduces the number of concurrent requests
made to the upstream server under high load situations and provides
buffering during temporary network or upstream outages.

You can set several parameters to configure the behavior and capacity
of the queues used by the plugin. For more information about how to
use these parameters, see
[Plugin queuing reference](/gateway/entities/plugin/#plugin-queuing).

You can find the queue parameters under [`config.queue`](./reference/#schema--config-queue) in the plugin configuration.

Queues are not shared between workers; queueing parameters are
scoped to one worker. For whole-system capacity planning, the number
of workers needs to be considered when setting queue parameters.

## Metrics
The Datadog plugin currently logs the following metrics to the Datadog server about a Service or Route:

Metric                     | Description | Namespace
---                        | ---         | ---
`request_count`            | Tracks the request | `kong.request.count`
`request_size`             | Tracks the request body size in bytes | `kong.request.size`
`response_size`            | Tracks the response body size in bytes | `kong.response.size`
`latency`                  | Tracks the interval between the time the request started and the time the response was received from the upstream server | `kong.latency`
`upstream_latency`         | Tracks the time it took for the final service to process the request | `kong.upstream_latency`
`kong_latency`             | Tracks the internal {{site.base_gateway}} latency that it took to run all the plugins | `kong.kong_latency`

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

Field           | Description                                           | Data types
---             | ---                                                   | ---
`KONG_DATADOG_AGENT_HOST` | The IP address or hostname to send data to | string
`KONG_DATADOG_AGENT_PORT` | The port to send data to on the upstream server | integer

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
    helm upgrade -f values.yaml RELEASE_NAME kong/kong --version VERSION --namespace NAMESPACE
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