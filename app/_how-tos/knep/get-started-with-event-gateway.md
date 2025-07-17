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
    Get started with {{site.event_gateway}} ({{site.event_gateway_short}}) by setting up a {{site.konnect_short_name}} Control Plane and a Kafka cluster, then configuring the Control Plane using the `/declarative_config` endpoint of the Control Plane Config API.

tools:
    - konnect-api
  
prereqs:
  inline:
    - title: Sign up for the {{site.event_gateway_short}} beta
      content: |
        If you're an existing Kong customer or prospect, please fill out the [beta participation form](https://konghq.com/lp/register-kafka-proxy-beta) and we will reach out to you.

    - title: Install kafkactl
      content: |
        Install [kafkactl](https://github.com/deviceinsight/kafkactl?tab=readme-ov-file#installation). You'll need it to interact with Kafka clusters. 

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

{{site.event_gateway}} lets you configure virtual clusters, which act as a proxy interface between the client and the Kafka cluster.
With virtual clusters, you can:
* Apply transformations, filtering, and custom policies
* Route messages based on specific rules to different Kafka clusters
* Apply auth mediation and message encryption
and much more.

Now, let's configure a proxy and test your first virtual cluster setup.

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

## Update the control plane and data plane

{% include_cached /knep/update.md %}

## Configure the cluster

Set up the `kafkactl` config file:
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
current-context: direct
EOF
```
This file defines several configuration profiles. We're going to switch between these profiles as we test different features.

## Validate the cluster

Let's check that the cluster works. We can use the Kafka UI to do this by going to [http://localhost:8082](http://localhost:8082) and checking the cluster list. 
You should see the `direct-kafka-cluster` and `knep-proxy-cluster` cluster listed there.

You can also use the `kafkactl` command to check the cluster. 
Let's check the Kafka cluster directly:

```shell
kafkactl -C kafkactl.yaml --context direct create topic my-test-topic
kafkactl -C kafkactl.yaml --context direct produce my-test-topic --value="Hello World"
```
It'll use the `direct` context, which is this case is a direct connection to our Kafka cluster.

You should see the following response:
```shell
topic created: my-test-topic
message produced (partition=0	offset=0)
```
{:.no-copy-code}

Now let's check the Kafka cluster through the {{site.event_gateway_short}} proxy.
By passing the `knep` context, `kafkactl` will connect to Kafka through the proxy port `19092`:

```shell
kafkactl -C kafkactl.yaml --context knep list topics
```

You should see a list of the topics you just created:
```shell
TOPIC              PARTITIONS     REPLICATION FACTOR
_schemas           1              1
my-test-topic      1              1
```
{:.no-copy-code}

You now have a Kafka cluster running with a {{site.event_gateway_short}} proxy in front. 