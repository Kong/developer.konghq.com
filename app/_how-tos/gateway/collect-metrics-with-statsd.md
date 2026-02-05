---
title: Collect {{site.base_gateway}} metrics with the StatsD plugin
permalink: /how-to/collect-metrics-with-statsd/
content_type: how_to
description: "Learn how to collect metrics from {{site.base_gateway}} with the StatsD plugin."
products:
    - gateway

related_resources:
  - text: StatsD plugin
    url: /plugins/statsd/

works_on:
    - on-prem
    - konnect

min_version:
  gateway: '3.4'

entities: 
  - plugins

plugins:
    - statsd

tags:
    - monitoring
    - statsd

tldr:
    q: How do I collect {{site.base_gateway}} metrics with the StatsD plugin?
    a: |
        Run a StatsD server and enable the StatsD plugin on your {{site.base_gateway}}.

tools:
    - deck

prereqs:
  entities:
    services:
      - example-service
    routes:
      - example-route

cleanup:
  inline:
    - title: StatsD
      content: |
        Once you are done experimenting with StatsD, you can use the following
        command to stop the StatsD server you created in this guide:

        ```sh
        docker stop kong-quickstart-statsd
        ```
      icon_url: /assets/icons/statsd.svg
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg

next_steps:
  - text: Review the StatsD plugin configuration reference
    url: /plugins/statsd/reference/
---

## Start a StatsD server

Use the following command to run a StatsD container to capture monitoring data:

```sh
docker run -d --rm -p 8126:8126 \
  --name kong-quickstart-statsd --network=kong-quickstart-net \
  statsd/statsd:latest
```

## Enable the StatsD plugin

Configure the StatsD plugin with the hostname and port of the listening StatsD service. In this example, the listening host is the Docker container name, since it was started in the same network as the {{site.base_gateway}} quickstart, and the port is `8125`:

{% entity_examples %}
entities:
  plugins:
    - name: statsd
      config:
        host: kong-quickstart-statsd
        port: 8125
{% endentity_examples %}

## Validate

You can validate that the plugin is collecting metrics by generating traffic to the example Service:
<!--vale off -->
{% validation request-check %}
url: '/anything'
status_code: 200
display_headers: true
{% endvalidation %}
<!--vale on -->

Run this command to check the metrics collected with StatsD:
```
echo "counters" | nc localhost 8126
```
In the response from StatsD, you should see a request count, the response code received, and a few other metrics. 
In this case, the request to the `/anything` path should have generated:
```
  'kong.service.example-service.request.count': 1,
  'kong.service.example-service.status.200': 1,
  ...
```
{:.no-copy-code}

{:.info}
> The StatsD server may take a few minutes to connect. If you're not getting any metrics, wait a few minutes and try these validation steps again.





