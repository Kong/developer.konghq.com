---
title: Get started with {{site.event_gateway}}
short_title: Install {{site.event_gateway_short}}
content_type: how_to
breadcrumbs:
  - /event-gateway/

permalink: /event-gateway/get-started/

series:
  id: event-gateway-get-started
  position: 1

beta: true

products:
    - event-gateway

works_on:
    - konnect

tags:
    - get-started
    - event-gateway
    - kafka

description: Use this tutorial to get started with {{site.event_gateway}}.

tldr: 
  q: How can I get started with {{site.event_gateway}}?
  a: | 
    Get started with {{site.event_gateway}} by setting up a {{site.konnect_short_name}} Control Plane and a Kafka cluster, then configuring the Control Plane using the `/declarative_config` endpoint of the Control Plane Config API.

tools:
    - konnect-api
  
prereqs:
  inline:
    - title: Sign up for the {{site.event_gateway_short}} beta
      content: |
        If you're an existing Kong customer or prospect, please fill out the [beta participation form](https://konghq.com/lp/register-kafka-proxy-beta) and we will reach out to you.

    - title: Install kafkactl
      content: |
        Install [kafkactl](https://github.com/deviceinsight/kafkactl). You'll need it to interact with Kafka clusters. 

cleanup:
  inline:
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg
    - title: Clean up {{site.event_gateway}} resources
      include_content: cleanup/products/event-gateway
      icon_url: /assets/icons/event.svg    

automated_tests: false
related_resources:
  - text: "{{site.event_gateway_short}} configuration schema"
    url: /api/event-gateway/knep/
  - text: Event Gateway
    url: /event-gateway/

faqs:
  - q: | 
      I'm getting the error `Connection refused` when trying to access my Kafka cluster through {{site.event_gateway_short}}.
    a: |
      Check the following:
      * Verify all services are running with `docker ps`
      * Check if ports are available (in this how-to guide, we use 9192 for the proxy, 9092 for Kafka)
      * Ensure that all `KONNECT` environment variables are set correctly
  - q: When I run `list topics`, topics aren't visible.
    a: |
      Troubleshoot your setup by doing the following:
      * Verify that your Kafka broker is healthy
      * Check if you're using the correct `kafkactl` context
      * Ensure that the proxy is properly connected to the backend cluster
---

## Create a Control Plane in {{site.konnect_short_name}}

{% include knep/konnect-create-cp.md name='KNEP getting started' %}

## Start a local Kafka cluster

{% include knep/docker-compose-start.md %}

Let's look at the logs of the KNEP container to see if it started correctly:
```shell
docker compose logs knep
```

You should see something like this:
```
knep  | 2025-04-30T08:59:58.004076Z  WARN tokio-runtime-worker ThreadId(09) add_task{task_id="konnect_watch_config"}:task_run:check_dataplane_config{cp_config_url="/v2/control-planes/c6d325ec-0bd6-4fbc-b2c1-6a56c0a3edb0/declarative-config/native-event-proxy"}: knep::konnect: src/konnect/mod.rs:218: Konnect API returned 404, is the control plane ID correct?
```
{:.no-copy-code}

This is expected, as we haven't configured the Control Plane yet. We'll do this in the next step.

## Configure {{site.event_gateway}} control plane with a passthrough cluster 

Create the configuration file for the Control Plane. This file will define the backend cluster and the virtual cluster:

```shell
cat <<EOF > knep-config.yaml
backend_clusters:
  - name: kafka-localhost
    bootstrap_servers:
      - kafka:9092

listeners:
  port:
    - listen_address: 0.0.0.0
      listen_port_start: 19092
      advertised_host: localhost

virtual_clusters:
  - name: team-a
    backend_cluster_name: kafka-localhost
    route_by:
      type: port
      port:
        min_broker_id: 1
    authentication:
      - type: anonymous
        mediation:
          type: anonymous
EOF
```

Send a basic config to the Control Plane using the `/declarative-config` endpoint:

<!--vale off-->
{% konnect_api_request %}
url: "/v2/control-planes/$KONNECT_CONTROL_PLANE_ID/declarative-config"
status_code: 201
method: PUT
body_cmd: "$(jq -Rs '{config: .}' < knep-config.yaml)"
{% endkonnect_api_request %}
<!--vale on-->


## Validate the cluster

Let's check that the cluster works. We can use the Kafka UI to do this by going to [http://localhost:8082](http://localhost:8082) and checking the cluster list. 
You should see the `direct-kafka-cluster` and `knep-proxy-cluster` cluster listed there.

You can also use the `kafkactl` command to check the cluster. First, let's set up the `kafkactl` config file:
```shell
cat <<EOF > kafkactl.yaml
contexts:
  direct:
    brokers:
      - localhost:9092
  backend:
    brokers:
      - localhost:9092
  knep:
    brokers:
      - localhost:19092
  secured:
    brokers:
      - localhost:29092
  team-a:
    brokers:
      - localhost:19092
  team-b:
    brokers:
      - localhost:29092
current-context: default
EOF
```

Let's check the Kafka cluster directly:
```shell
kafkactl config use-context direct
kafkactl create topic a-first-topic b-second-topic b-third-topic fourth-topic
kafkactl produce a-first-topic --value="Hello World"
```

You should see the following response:
```shell
message produced (partition=0	offset=0)
```
{:.no-copy-code}

Now let's check the Kafka cluster through the {{site.event_gateway_short}} proxy.
By passing the `virtual` context, `kafkactl` will connect to Kafka through the proxy port `19092`:

```shell
kafkactl -C kafkactl.yaml --context virtual list topics
```

You should see a list of the topics you just created:
```shell
TOPIC              PARTITIONS     REPLICATION FACTOR
_schemas           1              1
a-first-topic      1              1
b-second-topic     1              1
b-third-topic      1              1
fourth-topic       1              1
```
{:.no-copy-code}
