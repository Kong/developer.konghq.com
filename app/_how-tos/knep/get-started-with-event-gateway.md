---
title: Get started with {{site.event_gateway}}
content_type: how_to
breadcrumbs:
  - /event-gateway/

permalink: /knep/get-started/

beta: true

products:
    - event-gateway

works_on:
    - konnect

tags:
    - get-started
    - event-gateway

description: Use this tutorial to get started with {{site.event_gateway}}.

tldr: 
  q: What is {{site.event_gateway}}, and how can I get started with it?
  a: | 
    Info on what you're going to learn about in this how-to 

tools:
    - konnect-api
  
prereqs:
  inline:
    - title: Install kafkactl
      content: |
        Install [kafkactl](https://github.com/deviceinsight/kafkactl). You'll need it to interact with Kafka clusters. 

cleanup:
  inline:
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg

automated_tests: false
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

This is expected, as we have not yet configured the Control Plane. We'll do this in the next step.

## Configure {{site.event_gateway}} control plane with a passthrough cluster 

Let's create the configuration file for the Control Plane. This file will define the backend cluster and the virtual cluster:

```shell
cat <<EOF > knep-config.yaml
virtual_clusters:
- name: demo
  backend_cluster_name: kafka-1
  route_by:
      type: port
      port:
        min_broker_id: 1
  authentication: # don't set any authentication for now 
  - type: anonymous
    mediation:
        type: anonymous
backend_clusters:
- name: kafka-1 
  bootstrap_servers:
  - broker:9092 
listeners:
  port:
    - listen_address: 0.0.0.0
      advertised_host: knep
      listen_port_start: 9092
    - listen_address: 0.0.0.0
      advertised_host: localhost
      listen_port_start: 9192
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


## Check the cluster works

Now let's check that the cluster works. We can use the Kafka UI to do this by going to [http://localhost:8082](http://localhost:8082) and checking the cluster list. 
You should see the `direct-kafka-cluster` and `knep-proxy-cluster` cluster listed there.

You can also use the `kafkactl` command to check the cluster. First, let's set up the `kafkactl` config file:
```shell
cat <<EOF > kafkactl.yaml
contexts:
    direct:
        brokers:
            - localhost:9092
    knep:
        brokers:
            - localhost:9192
current-context: knep
EOF
```

Now let's check the Kafka cluster directly:
```shell
kafkactl -C kafkactl.yaml --context direct list topics
```

You should see the topics listed there. Now let's check the same command but through the {{site.event_gateway_short}} proxy:
```shell
TOPIC                  PARTITIONS     REPLICATION FACTOR
__consumer_offsets     50             1
_schemas               1              1
```
{:.no-copy-code}

And now through the {{site.event_gateway_short}} proxy:
```shell
kafkactl -C kafkactl.yaml --context knep list topics
```

You should see a similar output:
```shell
TOPIC                  PARTITIONS     REPLICATION FACTOR
__consumer_offsets     50             1
_schemas               1              1
```
{:.no-copy-code}


<!-- 

## Add prefix to the cluster 

TODO!
 -->