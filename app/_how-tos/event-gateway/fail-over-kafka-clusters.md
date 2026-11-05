---
title: Fail over to a standby Kafka cluster with {{site.event_gateway}}
content_type: how_to
breadcrumbs:
  - /event-gateway/

permalink: /event-gateway/fail-over-kafka-clusters/

products:
    - event-gateway

works_on:
    - konnect

tags:
    - event-gateway
    - kafka
    - failover
    - resilience

description: "Move Kafka clients from a primary cluster to a standby cluster without changing or restarting the clients, by pausing writes with an ACL policy and swapping the virtual cluster's backend cluster."

tldr:
  q: How do I fail over Kafka clients to another cluster without reconfiguring them?
  a: |
    1. Connect clients to a virtual cluster instead of to the brokers.
    1. Pre-stage a disabled ACL policy that denies writes.
    1. To fail over, enable the policy, wait for replication to catch up, and point the virtual cluster at the standby backend cluster.
    1. Run a health check, then disable the policy to resume writes.

tools:
    - konnect-api

prereqs:
  skip_product: true
  inline:
    - title: Install kafkactl
      position: before
      include_content: knep/kafkactl

cleanup:
  inline:
    - title: Clean up {{site.event_gateway}} resources
      include_content: cleanup/products/event-gateway
      icon_url: /assets/icons/gateway.svg

related_resources:
  - text: Virtual clusters
    url: /event-gateway/entities/virtual-cluster/
  - text: Backend clusters
    url: /event-gateway/entities/backend-cluster/
  - text: ACL policy
    url: /event-gateway/policies/acl/
  - text: "{{site.event_gateway_short}} architecture"
    url: /event-gateway/architecture/
  - text: "{{site.event_gateway_short}} Control Plane API"
    url: /api/konnect/event-gateway/
---

## Overview

Failing over between Kafka clusters is hard because Kafka clients are tightly coupled to the cluster they connect to:

* **Every client hardcodes the cluster address.** Producers and consumers are configured with the bootstrap servers of one cluster. To move them, you have to change the configuration of every application and restart it, often across many teams.
* **Credentials and ACLs are tied to the cluster.** The standby cluster needs the same users, credentials, and ACLs as the primary, and clients may need new credentials to reach it.
* **Producers keep writing during the switch.** While clients move one by one, some write to the old cluster and some to the new one, and records written to the old cluster after replication stops are lost.
* **Offsets don't move with the data.** Consumer group offsets are stored per cluster, so consumers that switch clusters can skip or reprocess records. See [Consumer offsets](#consumer-offsets).

With {{site.event_gateway}}, clients connect to a [virtual cluster](/event-gateway/entities/virtual-cluster/) instead of to the brokers, and the virtual cluster forwards traffic to a [backend cluster](/event-gateway/entities/backend-cluster/). Failover becomes a control plane change: you point the virtual cluster at a different backend cluster, and clients keep the same address and credentials.

In this guide, you'll run a planned failover from a primary cluster to a standby cluster in five steps:

1. Stop writes by enabling a pre-staged ACL policy that denies produce requests.
1. Wait for replication to the standby cluster to catch up.
1. Point the virtual cluster at the standby backend cluster.
1. Check that the standby cluster serves traffic through the virtual cluster.
1. Resume writes by disabling the ACL policy.

{% mermaid %}
flowchart LR
    C[Kafka clients] --> VC

    subgraph GW [Event Gateway]
        VC[payments virtual cluster<br/>ACL policies]
    end

    VC -->|before failover| P[(primary-kafka)]
    VC -.->|after failover| S[(secondary-kafka)]
    P -. replication .-> S
{% endmermaid %}

{:.info}
> This guide doesn't set up replication between the clusters. It creates the same topics on both clusters to stand in for a replicated topic. In production, use a replication tool such as MirrorMaker 2 or Confluent Cluster Linking to copy records and consumer offsets to the standby cluster.

## Start two Kafka clusters

Create a Docker Compose file that defines two single-broker Kafka clusters, `primary-kafka` and `secondary-kafka`:

```bash
cat <<'EOF' > docker-compose.yaml
{% include_cached _files/event-gateway/docker-compose-failover.yaml %}
EOF
```
{:data-test-step="block" .collapsible}

Each broker listens on port `9092` inside the Docker network for {{site.event_gateway_short}} connections. For direct local access, the primary cluster is exposed on port `9094` and the secondary cluster on port `9095`.

Start the clusters:

```bash
docker compose up -d
```
{:data-test-step="block"}

## Create an {{site.event_gateway_short}} control plane and data plane

{% event_gateway_quickstart %}
{% endevent_gateway_quickstart %}

## Create the backend clusters

Create a backend cluster for the primary Kafka cluster:

<!--vale off-->
{% konnect_api_request %}
url: /v1/event-gateways/$EVENT_GATEWAY_ID/backend-clusters
status_code: 201
method: POST
body:
  name: primary_cluster
  bootstrap_servers:
    - primary-kafka:9092
  authentication:
    type: anonymous
  tls:
    enabled: false
  insecure_allow_anonymous_virtual_cluster_auth: true
extract_body:
  - name: id
    variable: PRIMARY_CLUSTER_ID
capture:
  - variable: PRIMARY_CLUSTER_ID
    jq: ".id"
{% endkonnect_api_request %}
<!--vale on-->

Create a second backend cluster for the standby Kafka cluster:

<!--vale off-->
{% konnect_api_request %}
url: /v1/event-gateways/$EVENT_GATEWAY_ID/backend-clusters
status_code: 201
method: POST
body:
  name: secondary_cluster
  bootstrap_servers:
    - secondary-kafka:9092
  authentication:
    type: anonymous
  tls:
    enabled: false
  insecure_allow_anonymous_virtual_cluster_auth: true
extract_body:
  - name: id
    variable: SECONDARY_CLUSTER_ID
capture:
  - variable: SECONDARY_CLUSTER_ID
    jq: ".id"
{% endkonnect_api_request %}
<!--vale on-->

Each backend cluster holds the credentials that {{site.event_gateway_short}} uses to connect to that Kafka cluster. When you fail over, the gateway uses the standby cluster's credentials automatically, so clients don't need new credentials.

## Create a virtual cluster

Create a virtual cluster that points at the primary backend cluster:

<!--vale off-->
{% konnect_api_request %}
url: /v1/event-gateways/$EVENT_GATEWAY_ID/virtual-clusters
status_code: 201
method: POST
body:
  name: payments_vc
  destination:
    id: $PRIMARY_CLUSTER_ID
  dns_label: payments
  authentication:
    - type: anonymous
  acl_mode: enforce_on_gateway
extract_body:
  - name: id
    variable: VIRTUAL_CLUSTER_ID
capture:
  - variable: VIRTUAL_CLUSTER_ID
    jq: ".id"
{% endkonnect_api_request %}
<!--vale on-->

The virtual cluster uses `acl_mode: enforce_on_gateway`, so {{site.event_gateway_short}} evaluates [ACL policies](/event-gateway/policies/acl/) on every request. You'll use an ACL policy to pause writes during the failover.

## Create a listener with a forwarding policy

Create a [listener](/event-gateway/entities/listener/) to accept client connections:

<!--vale off-->
{% konnect_api_request %}
url: /v1/event-gateways/$EVENT_GATEWAY_ID/listeners
status_code: 201
method: POST
body:
  name: payments_listener
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

Create a [Forward to Virtual Cluster policy](/event-gateway/policies/forward-to-virtual-cluster/) to forward traffic to the virtual cluster:

<!--vale off-->
{% konnect_api_request %}
url: /v1/event-gateways/$EVENT_GATEWAY_ID/listeners/$LISTENER_ID/policies
status_code: 201
method: POST
body:
  type: forward_to_virtual_cluster
  name: forward_to_payments_vc
  config:
    type: port_mapping
    advertised_host: localhost
    destination:
      id: $VIRTUAL_CLUSTER_ID
{% endkonnect_api_request %}
<!--vale on-->

For demo purposes, this guide uses port mapping, which assigns each Kafka broker to a dedicated port on the {{site.event_gateway_short}}. In production, we recommend using [SNI routing](/event-gateway/architecture/#hostname-mapping) instead.

## Allow access to topics and consumer groups

With `acl_mode: enforce_on_gateway`, clients have no access until an ACL policy grants it. Create an ACL policy that allows all operations on all topics and consumer groups:

<!--vale off-->
{% konnect_api_request %}
url: /v1/event-gateways/$EVENT_GATEWAY_ID/virtual-clusters/$VIRTUAL_CLUSTER_ID/cluster-policies
status_code: 201
method: POST
body:
  type: acls
  name: allow_all
  config:
    rules:
      - resource_type: topic
        action: allow
        operations:
          - name: all
        resource_names:
          - match: "*"
      - resource_type: group
        action: allow
        operations:
          - name: all
        resource_names:
          - match: "*"
{% endkonnect_api_request %}
<!--vale on-->

In production, replace this policy with the access rules your clients need.

## Pre-stage the write gate

Create a second ACL policy that denies writes to the `orders` topic. Create it disabled, so it has no effect until you need it:

<!--vale off-->
{% konnect_api_request %}
url: /v1/event-gateways/$EVENT_GATEWAY_ID/virtual-clusters/$VIRTUAL_CLUSTER_ID/cluster-policies
status_code: 201
method: POST
body:
  type: acls
  name: failover_write_gate
  description: Deny writes to business topics during a failover
  enabled: false
  config:
    rules:
      - resource_type: topic
        action: deny
        operations:
          - name: write
        resource_names:
          - match: orders
      - resource_type: topic
        action: allow
        operations:
          - name: all
        resource_names:
          - match: "*"
      - resource_type: group
        action: allow
        operations:
          - name: all
        resource_names:
          - match: "*"
extract_body:
  - name: id
    variable: GATE_POLICY_ID
capture:
  - variable: GATE_POLICY_ID
    jq: ".id"
{% endkonnect_api_request %}
<!--vale on-->

When you enable this policy, it must work alongside `allow_all`. Keep the following in mind when you design a write gate:

* **Every enabled ACL policy must allow a request.** A request is allowed only if each enabled ACL policy on the virtual cluster allows it. That's why the gate includes its own `allow` rules for everything it doesn't block. A gate that contains only a `deny` rule blocks all requests, including reads.
* **Deny rules take precedence over allow rules.** The order of the rules, and the order of the policies in the chain, doesn't change the result. Writes to `orders` are denied even though another rule allows all operations on all topics.
* **List the topics to block explicitly.** Because `deny` always wins, a gate that denies writes on `*` also blocks every topic you might want to keep writable. This guide keeps a `healthcheck` topic outside the gate, so you can test writes against the standby cluster before you resume business traffic.

## Configure kafkactl

Create a kafkactl configuration with a context for each Kafka cluster and a `vc` context that connects through the virtual cluster:

<!--vale off-->
{% validation custom-command %}
command: |
  cat <<EOF > kafkactl.yaml
  contexts:
    primary:
      brokers:
        - localhost:9094
    secondary:
      brokers:
        - localhost:9095
    vc:
      brokers:
        - localhost:19092
  EOF
expected:
  return_code: 0
render_output: false
{% endvalidation %}
<!--vale on-->

The `vc` context represents your applications. Its broker address is the {{site.event_gateway_short}}, and it stays the same throughout the failover.

## Create the topics

Create the `orders` and `healthcheck` topics on both clusters. In production, your replication tool creates the topics on the standby cluster.

<!--vale off-->
{% validation custom-command %}
command: |
  for cluster in primary secondary; do
    kafkactl -C kafkactl.yaml --context $cluster create topic orders
    kafkactl -C kafkactl.yaml --context $cluster create topic healthcheck
  done
expected:
  return_code: 0
render_output: false
{% endvalidation %}
<!--vale on-->

## Produce and consume through the virtual cluster

Produce a record to the `orders` topic through the virtual cluster:

<!--vale off-->
{% validation custom-command %}
command: |
  echo '{"order_id":1,"amount":10}' | kafkactl -C kafkactl.yaml --context vc produce orders
expected:
  message: "1 messages produced"
  return_code: 0
render_output: false
{% endvalidation %}
<!--vale on-->

Consume the record as the `payments-app` consumer group:

<!--vale off-->
{% validation custom-command %}
command: |
  kafkactl -C kafkactl.yaml --context vc consume orders --group payments-app --from-beginning --max-messages 1
expected:
  message: '"order_id":1'
  return_code: 0
render_output: false
{% endvalidation %}
<!--vale on-->

```shell
{"order_id":1,"amount":10}
```
{:.no-copy-code}

The consumer group commits its offset. Check it through the virtual cluster:

<!--vale off-->
{% validation custom-command %}
command: |
  kafkactl -C kafkactl.yaml --context vc describe consumer-group payments-app
expected:
  message: "orders"
  return_code: 0
render_output: false
{% endvalidation %}
<!--vale on-->

The `CONSUMER_OFFSET` column shows that `payments-app` has consumed the first record of `orders`:

```shell
TOPIC      PARTITION     NEWEST_OFFSET     OLDEST_OFFSET     CONSUMER_OFFSET     LEAD     LAG
orders     0             1                 0                 1                   1        0

CLIENT_HOST     CLIENT_ID     GROUP_INSTANCE_ID     TOPIC     ASSIGNED_PARTITIONS
```
{:.no-copy-code}

Confirm that the record is stored on the primary cluster:

<!--vale off-->
{% validation custom-command %}
command: |
  kafkactl -C kafkactl.yaml --context primary consume orders --from-beginning --exit
expected:
  message: '"order_id":1'
  return_code: 0
render_output: false
{% endvalidation %}
<!--vale on-->

## Fail over to the standby cluster

### 1. Stop writes

Enable the write gate:

<!--vale off-->
{% konnect_api_request %}
url: /v1/event-gateways/$EVENT_GATEWAY_ID/virtual-clusters/$VIRTUAL_CLUSTER_ID/cluster-policies/$GATE_POLICY_ID
status_code: 200
method: PATCH
body:
  enabled: true
{% endkonnect_api_request %}
<!--vale on-->

The data plane picks up the change within a few seconds. Try to produce a record to `orders`:

<!--vale off-->
{% validation custom-command %}
command: |
  echo '{"order_id":2,"amount":20}' | kafkactl -C kafkactl.yaml --context vc produce orders
expected:
  message: "The client is not authorized to access this topic"
  return_code: 1
render_output: false
{% endvalidation %}
<!--vale on-->

{{site.event_gateway_short}} rejects the request with the `TOPIC_AUTHORIZATION_FAILED` error code, so the record never reaches the primary cluster:

```shell
0 messages produced
Failed to produce message: kafka server: The client is not authorized to access this topic
```
{:.no-copy-code}

If the record is produced, the data plane hasn't picked up the change yet. Wait a few seconds and try again.

Reads aren't affected, so consumers keep processing the records that are already on the primary cluster. Producers that retry on authorization errors wait until you resume writes. Depending on its settings, a producer may report the failed records to the application, so make sure your applications handle `TOPIC_AUTHORIZATION_FAILED` during a failover.

### 2. Wait for replication to catch up

Before you switch clusters, make sure that the standby cluster has everything the primary cluster has:

1. **No more writes reach the primary cluster.** The incoming byte rate on the primary's topics, for example the `kafka.server:type=BrokerTopicMetrics,name=BytesInPerSec` metric, drops to zero.
1. **Replication lag is zero.** With MirrorMaker 2, check the lag of the replication consumer group on the primary cluster. With Cluster Linking, check the mirror lag metrics.
1. **Consumer offsets are synced.** See [Consumer offsets](#consumer-offsets).

This guide doesn't use replication, so you can continue to the next step.

### 3. Point the virtual cluster at the standby cluster

Update the virtual cluster's `destination` to the secondary backend cluster. The update replaces the whole virtual cluster, so send the complete configuration:

<!--vale off-->
{% konnect_api_request %}
url: /v1/event-gateways/$EVENT_GATEWAY_ID/virtual-clusters/$VIRTUAL_CLUSTER_ID
status_code: 200
method: PUT
body:
  name: payments_vc
  destination:
    id: $SECONDARY_CLUSTER_ID
  dns_label: payments
  authentication:
    - type: anonymous
  acl_mode: enforce_on_gateway
{% endkonnect_api_request %}
<!--vale on-->

{{site.event_gateway_short}} closes the open client connections and forwards new connections to the secondary cluster. Kafka clients reconnect to the same {{site.event_gateway_short}} address automatically. Authentication and ACL policies belong to the virtual cluster, so they apply unchanged.

### 4. Check the standby cluster

Produce a canary record to the `healthcheck` topic through the virtual cluster, which the write gate doesn't block. Then read the topic directly from the secondary cluster to confirm that the virtual cluster now writes there:

<!--vale off-->
{% validation custom-command %}
command: |
  echo "canary" | kafkactl -C kafkactl.yaml --context vc produce healthcheck
  kafkactl -C kafkactl.yaml --context secondary consume healthcheck --from-beginning --exit
expected:
  message: "canary"
  return_code: 0
render_output: false
{% endvalidation %}
<!--vale on-->

```shell
1 messages produced
canary
```
{:.no-copy-code}

If the secondary cluster doesn't return the canary record, the data plane hasn't picked up the new destination yet. The canary went to the primary cluster instead. Wait a few seconds and run the commands again.

### 5. Resume writes

Disable the write gate:

<!--vale off-->
{% konnect_api_request %}
url: /v1/event-gateways/$EVENT_GATEWAY_ID/virtual-clusters/$VIRTUAL_CLUSTER_ID/cluster-policies/$GATE_POLICY_ID
status_code: 200
method: PATCH
body:
  enabled: false
{% endkonnect_api_request %}
<!--vale on-->

Produce a record to `orders` through the virtual cluster:

<!--vale off-->
{% validation custom-command %}
command: |
  echo '{"order_id":3,"amount":30}' | kafkactl -C kafkactl.yaml --context vc produce orders
expected:
  message: "1 messages produced"
  return_code: 0
render_output: false
{% endvalidation %}
<!--vale on-->

## Validate

Read the `orders` topic directly from the secondary cluster:

<!--vale off-->
{% validation custom-command %}
command: |
  kafkactl -C kafkactl.yaml --context secondary consume orders --from-beginning --exit
expected:
  message: '"order_id":3'
  return_code: 0
render_output: false
{% endvalidation %}
<!--vale on-->

The record that you produced after the failover is stored on the secondary cluster:

```shell
{"order_id":3,"amount":30}
```
{:.no-copy-code}

The client configuration in the `vc` context never changed. The record that you produced before the failover is still on the primary cluster only, because this guide doesn't replicate data between the clusters.

## Consumer offsets

{{site.event_gateway_short}} doesn't copy or translate consumer group offsets. A consumer group's committed offsets are stored on the Kafka cluster where the group committed them, and the virtual cluster forwards offset requests to whichever backend cluster it currently points at.

You can see this with the `payments-app` consumer group, which committed its offset before the failover. Describe the group through the virtual cluster again:

<!--vale off-->
{% validation custom-command %}
command: |
  kafkactl -C kafkactl.yaml --context vc describe consumer-group payments-app
expected:
  return_code: 0
render_output: false
{% endvalidation %}
<!--vale on-->

The virtual cluster now points at the secondary cluster, which has no committed offsets for `payments-app`, so the table is empty:

```shell
TOPIC     PARTITION     NEWEST_OFFSET     OLDEST_OFFSET     CONSUMER_OFFSET     LEAD     LAG

CLIENT_HOST     CLIENT_ID     GROUP_INSTANCE_ID     TOPIC     ASSIGNED_PARTITIONS
```
{:.no-copy-code}

The offset is still stored on the primary cluster:

<!--vale off-->
{% validation custom-command %}
command: |
  kafkactl -C kafkactl.yaml --context primary describe consumer-group payments-app
expected:
  message: "orders"
  return_code: 0
render_output: false
{% endvalidation %}
<!--vale on-->

```shell
TOPIC      PARTITION     NEWEST_OFFSET     OLDEST_OFFSET     CONSUMER_OFFSET     LEAD     LAG
orders     0             1                 0                 1                   1        0

CLIENT_HOST     CLIENT_ID     GROUP_INSTANCE_ID     TOPIC     ASSIGNED_PARTITIONS
```
{:.no-copy-code}

If `payments-app` started consuming now, it would have no starting position on the secondary cluster.

What a consumer does after a failover depends on whether its offsets exist on the new cluster:

* **If the offsets were synced to the standby cluster**, the consumer resumes close to where it stopped. Offset sync runs on an interval, so the consumer may reprocess a few records committed after the last sync. Design consumers to handle duplicates.
* **If the offsets weren't synced**, the consumer has no committed offset on the new cluster and falls back to its `auto.offset.reset` setting. With `latest`, the default, it skips records that it hadn't consumed yet. With `earliest`, it reprocesses the whole topic.

How offsets reach the standby cluster depends on your replication tool:

* **MirrorMaker 2** copies records to new offsets on the target cluster, so the offsets on the two clusters differ. Its checkpoint connector translates committed offsets, and with `sync.group.offsets.enabled=true` it writes the translated offsets to the target cluster. MirrorMaker 2 only writes offsets for consumer groups that have no active members on the target cluster.
* **Confluent Cluster Linking** keeps the same offsets on mirror topics as on the source topics, and can sync consumer group offsets to the destination cluster.

During a planned failover, check that the offsets of your important consumer groups are synced before you point the virtual cluster at the standby cluster, as described in [step 2](#2-wait-for-replication-to-catch-up).

## Unplanned failover

If the primary cluster is unavailable, skip steps 1 and 2: producers are already failing, and there's nothing left to drain. Check the standby cluster, estimate how much data didn't replicate before the outage, and then point the virtual cluster at the standby cluster. Records that didn't replicate are lost, and consumers resume from the last offsets that were synced.

If the primary cluster is still reachable but degraded, for example because of performance problems, use the full planned procedure so that no writes are lost during the switch.
