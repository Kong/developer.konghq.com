---
title: Set up observability for {{site.event_gateway}}
content_type: how_to
permalink: /event-gateway/configure-observability-with-otel/
breadcrumbs:
  - /event-gateway/

products:
    - event-gateway

works_on:
    - konnect

tags:
    - observability
    - kafka
    - troubleshooting

description: "Export metrics, traces, and logs from {{site.event_gateway}} into your own observability systems using OpenTelemetry (OTEL)."

tldr: 
  q: How do I see metrics, traces, and logs for {{site.event_gateway}}?
  a: |
    Export metrics, traces, and logs from {{site.event_gateway}} into your own observability systems using OpenTelemetry (OTEL), which helps you understand how {{site.event_gateway_short}} functions and how to troubleshoot it when something goes wrong.

    In this tutorial, we're using the Grafana LGTM stack (Loki, Grafana, Tempo, Prometheus), but you can substitute your own preferred OTLP-compatible tools as well.
tools:
    - konnect-api

faqs:
  - q: What metrics are available for {{site.event_gateway}}?
    a: You can find the list of all available metrics in the [metrics reference](/event-gateway/metrics/).
  
prereqs:
  skip_product: true
  inline:
    - title: Install kafkactl
      position: before
      content: |
        Install [kafkactl](https://github.com/deviceinsight/kafkactl?tab=readme-ov-file#installation). You'll need it to interact with Kafka clusters. 

    - title: Start a local Kafka cluster
      position: before
      include_content: knep/docker-compose-start

related_resources:
  - text: "{{site.event_gateway_short}} Control Plane API"
    url: /api/konnect/event-gateway/
  - text: Event Gateway metrics reference
    url: /event-gateway/metrics/

automated_tests: false

---

In this guide, you’ll configure the [Grafana LGTM stack](https://github.com/grafana/docker-otel-lgtm) to receive and visualize observability data from {{site.event_gateway_short}}. The LGTM stack bundles Grafana, [Loki](https://grafana.com/oss/loki/) (logs), [Tempo](https://grafana.com/oss/tempo/) (traces), [Prometheus](https://prometheus.io/) (metrics), and a built-in [OpenTelemetry Collector](https://opentelemetry.io/docs/collector/) in a single container.

Since {{site.event_gateway_short}} 1.1 can push traces, metrics, and logs directly via OTLP to the LGTM stack, you don’t need a separate collector container or any custom collector configuration.

Here’s how it works:

{% mermaid %}
flowchart LR

    A[Traces]
    B[Metrics]
    C[Logs]

    subgraph id1 [Event Gateway]
    A
    B
    C
    end

    D[OTLP
    endpoint]
    E[Tempo]
    F[Prometheus]
    G[Loki]
    H[Grafana]

    A --push via OTLP--> D
    B --push via OTLP--> D
    C --push via OTLP--> D

    subgraph id2 [Grafana LGTM]
    D
    E
    F
    G
    H
    end

    D --> E
    D --> F
    D --> G
    E --> H
    F --> H
    G --> H
{% endmermaid %}

In this setup:
1. {{site.event_gateway_short}} generates traces, metrics, and logs.
1. All three signals are pushed directly to the LGTM stack’s OTLP endpoint (gRPC on port 4317).
1. Inside the LGTM stack, the built-in OTEL Collector routes traces to Tempo, metrics to Prometheus, and logs to Loki.
1. Grafana provides a unified UI to explore all signals.

## Create an {{site.event_gateway_short}} control plane and data plane

Run the quickstart script to automatically provision a demo {{site.event_gateway_short}} control plane and data plane, and configure your environment for exporting observability data:

```sh
curl -Ls https://get.konghq.com/event-gateway | bash -s -- \
  -k $KONNECT_TOKEN \
  -N kafka_event_gateway \
  -e "OTEL_EXPORTER_OTLP_PROTOCOL=grpc" \
  -e "OTEL_EXPORTER_OTLP_ENDPOINT=http://lgtm:4317" \
  -e "OTEL_EXPORTER_OTLP_TIMEOUT=10s" \
  -e "OTEL_SERVICE_NAME=eventgw"
```

Where you configure the following custom telemetry settings:

{% table %}
columns:
  - title: Parameter
    key: param
  - title: Default
    key: default
  - title: New value
    key: new
  - title: Description
    key: desc
rows:
  - param: "`OTEL_EXPORTER_OTLP_PROTOCOL`"
    default: "`http/binary`"
    new: "`grpc`"
    desc: Protocol used to export OpenTelemetry data.
  - param: "`OTEL_EXPORTER_OTLP_ENDPOINT`"
    default: none
    new: "`http://lgtm:4317`"
    desc: Endpoint to send OpenTelemetry data. Setting this enables all OTLP signals (traces, metrics, and logs). In most cases, this will be the URL of your OTLP-compatible backend.
  - param: "`OTEL_EXPORTER_OTLP_TIMEOUT`"
    default: 10s
    new: 10s
    desc: Max waiting time for the backend to process each batch. We're not adjusting this for the tutorial, but you can adjust as needed for troubleshooting.
  - param: "`OTEL_SERVICE_NAME`"
    default: none
    new: "`eventgw`"
    desc: Name of the OTEL service identified in the observability tools. For example, in Grafana/Tempo, the service will appear as `eventgw`.
{% endtable %}

This sets up an {{site.event_gateway_short}} control plane named `event-gateway-quickstart`, provisions a local data plane, and prints out the following environment variable export:

```
export EVENT_GATEWAY_ID=your-gateway-id
```

Copy and paste this into your terminal to configure your session.

{% include_cached /knep/quickstart-note.md %}

## Launch the Grafana LGTM stack

The [`grafana/otel-lgtm`](https://github.com/grafana/docker-otel-lgtm) image bundles Grafana, Tempo, Prometheus, Loki, and a built-in OTEL Collector in a single container. No custom configuration files are needed.

Run the following command to start the LGTM stack on the same network as your Kafka cluster and {{site.event_gateway_short}} data plane:

```sh
docker run -d --name lgtm \
  --network kafka_event_gateway \
  -p 3000:3000 \
  -p 4317:4317 \
  -p 4318:4318 \
  grafana/otel-lgtm:latest
```

## Add Kafka configuration

Use the following Kafka configuration to access your Kafka resources from the virtual clusters:

<!--vale off-->
{% validation custom-command %}
command: |
  cat <<EOF > kafkactl.yaml
  contexts:
    direct:
      brokers:
        - localhost:9095
        - localhost:9096
        - localhost:9094
    vc:
      brokers:
        - localhost:19092
  EOF
expected:
  return_code: 0
render_output: false
{% endvalidation %}
<!--vale on-->

## Create a backend cluster

Use the following command to create a [backend cluster](/event-gateway/entities/backend-cluster/) that connects to the Kafka servers you set up:

<!--vale off-->
{% konnect_api_request %}
url: /v1/event-gateways/$EVENT_GATEWAY_ID/backend-clusters
status_code: 201
method: POST
body:
  name: backend_cluster
  bootstrap_servers:
    - kafka1:9092
    - kafka2:9092
    - kafka3:9092
  authentication:
    type: anonymous
  tls:
    enabled: false
  insecure_allow_anonymous_virtual_cluster_auth: true
extract_body:
  - name: id
    variable: BACKEND_CLUSTER_ID
capture:
  - variable: BACKEND_CLUSTER_ID
    jq: ".id"
{% endkonnect_api_request %}
<!--vale on-->

In this example configuration:
* `bootstrap_servers`: Points the backend cluster to the three bootstrap servers that we launched in the prerequisites. 
* `authentication` and `insecure_allow_anonymous_virtual_cluster_auth`: For demo purposes, we're allowing insecure `anonymous` connections, which means no authentication required. 
* `tls`: TLS is disabled so that we can easily test the connection.

## Add a virtual cluster

Run the following command to create a new [virtual cluster](/event-gateway/entities/virtual-cluster/) associated with our backend cluster. This will let you route event traffic and apply policies:

<!--vale off-->
{% konnect_api_request %}
url: /v1/event-gateways/$EVENT_GATEWAY_ID/virtual-clusters
status_code: 201
method: POST
body:
  name: example_virtual_cluster
  destination:
    id: $BACKEND_CLUSTER_ID
  dns_label: vcluster-1
  authentication:
    - type: anonymous
  acl_mode: passthrough
extract_body:
  - name: id
    variable: VIRTUAL_CLUSTER_ID
capture:
  - variable: VIRTUAL_CLUSTER_ID
    jq: ".id"
{% endkonnect_api_request %}
<!--vale on-->

In this example:
* `authentication`: Allows anonymous authentication.
* `acl_mode`: The setting `passthrough` means that all clients are allowed and don't have to match a defined ACL. 
In a production environment, you would set this to `enforce_on_gateway` and define an ACL policy.
* `name` is an internal name for the configuration object, while the `dns_label` is necessary for SNI routing.

## Add a listener and policy

For testing purposes, we'll use **port forwarding** to route traffic to the virtual cluster.  
In production environments, you should use **SNI routing** instead.

Run the following command to create a new [listener](/event-gateway/entities/listener/):
<!--vale off-->
{% konnect_api_request %}
url: /v1/event-gateways/$EVENT_GATEWAY_ID/listeners
status_code: 201
method: POST
body:
  name: example_listener
  addresses:
    - 0.0.0.0
  ports:
    - 19092-19095
extract_body:
  - name: id
    variable: LISTENER_ID
capture:
  - variable: LISTENER_ID
    jq: ".id"
{% endkonnect_api_request %}
<!--vale on-->

Create the [port mapping policy](/event-gateway/policies/forward-to-virtual-cluster/):

<!--vale off-->
{% konnect_api_request %}
url: /v1/event-gateways/$EVENT_GATEWAY_ID/listeners/$LISTENER_ID/policies
status_code: 201
method: POST
body:
  type: forward_to_virtual_cluster
  name: forward
  config:
    type: port_mapping
    advertised_host: localhost
    destination: 
      id: $VIRTUAL_CLUSTER_ID
{% endkonnect_api_request %}
<!--vale on-->

## Validate the cluster

Create a topic using the `direct` context, which is a direct connection to our Kafka cluster:

{% validation custom-command %}
command: |
  kafkactl -C kafkactl.yaml --context direct create topic my-test-topic
expected:
  message: "topic created: my-test-topic"
  return_code: 0
render_output: false
{% endvalidation %}

Then produce a message through the virtual cluster:

{% validation custom-command %}
command: |
  kafkactl -C kafkactl.yaml --context vc produce my-test-topic --value="test message"
expected:
  message: "message produced (partition=0	offset=0)"
  return_code: 0
render_output: false
{% endvalidation %}

You should see the following responses:
```shell
topic created: my-test-topic
message produced (partition=0	offset=0)
```
{:.no-copy-code}

## View metrics in Grafana

Now that {{site.event_gateway_short}} is pushing metrics via OTLP to the LGTM stack, let’s explore them in Grafana.

1. In your browser, open Grafana at `http://localhost:3000/`.
1. Navigate to **Drilldown** > **Metrics**.
1. Search for `kong` to see the list of available metrics.
1. Let’s look at a sample metric: `kong_keg_kafka_backend_roundtrip_duration_seconds_sum`.

This tells you how long it took for the {{site.event_gateway_short}} to send a request to the backend cluster and receive a response.

## View traces in Grafana

Let’s explore the traces generated by {{site.event_gateway_short}}.

1. Send any command through the virtual cluster, such as `list topics`:

   ```sh
   kafkactl -C kafkactl.yaml --context vc list topics
   ```
1. In your browser, open Grafana at `http://localhost:3000/`.
1. Navigate to **Drilldown** > **Traces**.
1. Select `eventgw` as the service name and click **Run query**.

Here you can see the full trace generated by {{site.event_gateway_short}} for each command.
For example, you can click a trace to see the span details, including information about the virtual cluster and backend cluster.

## View logs in Grafana

{{site.event_gateway_short}} 1.1 also exports logs via OTLP. Let’s explore them in Grafana.

1. In Grafana, navigate to **Drilldown** > **Logs**.
1. Use the label filter `service_name` = `eventgw` to see {{site.event_gateway_short}} logs.

