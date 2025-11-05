---
title: Productize Kafka topics with {{site.event_gateway}}
content_type: how_to
breadcrumbs:
  - /event-gateway/

permalink: /event-gateway/productize-kafka-topics/

products:
    - event-gateway

works_on:
    - konnect

tags:
    - event-gateway
    - kafka

description: "Use namespaces and ACL policies to create products from Kafka topics."

tldr: 
  q: How can I organize Kafka topics into products? 
  a: | 
    If your Kafka topics follow a naming convention with prefixes, you can easily organize them into categories with {{site.event_gateway}}:
    1. Create a virtual cluster for each product with a namespace based on the topic prefix.
    1. Create a listener with a forwarding policy for each virtual cluster.
    1. Create ACL policies to define access permissions to the virtual clusters.

tools:
    - konnect-api
  
prereqs:
  inline:
    - title: Install kafkactl
      position: before
      content: |
        Install [kafkactl](https://github.com/deviceinsight/kafkactl?tab=readme-ov-file#installation). You'll need it to interact with Kafka clusters. 
    - title: Start a local Kafka cluster
      position: before
      include_content: knep/docker-compose-start

automated_tests: false
related_resources:
  - text: Event Gateway
    url: /event-gateway/
---

## Create kafka topics

In this guide, we'll use namespaces and ACL policies to create products from Kafka topics. We have seven Kafka topics that we'll organize into two categories:
* `analytics_pageviews`
* `analytics_clicks`
* `analytics_orders`
* `payments_transactions`
* `payments_refunds`
* `payments_orders`
* `user_actions`

We'll have an `analytics` category and a `payments` category, and both of these will also include the `user_actions` topic.

First, we need to create these sample topics in the Kafka cluster we created in the [prerequisites](#start-a-local-kakfa-cluster):

```sh
docker-compose exec kafka1 opt/kafka/bin/kafka-topics.sh --create --topic analytics_pageviews --partitions 1 --replication-factor 1 --bootstrap-server kafka1:9092
docker-compose exec kafka1 opt/kafka/bin/kafka-topics.sh --create --topic analytics_clicks --partitions 1 --replication-factor 1 --bootstrap-server kafka1:9092
docker-compose exec kafka1 opt/kafka/bin/kafka-topics.sh --create --topic analytics_orders --partitions 1 --replication-factor 1 --bootstrap-server kafka1:9092
docker-compose exec kafka1 opt/kafka/bin/kafka-topics.sh --create --topic payments_transactions --partitions 1 --replication-factor 1 --bootstrap-server kafka1:9092
docker-compose exec kafka1 opt/kafka/bin/kafka-topics.sh --create --topic payments_refunds --partitions 1 --replication-factor 1 --bootstrap-server kafka1:9092
docker-compose exec kafka1 opt/kafka/bin/kafka-topics.sh --create --topic payments_orders --partitions 1 --replication-factor 1 --bootstrap-server kafka1:9092
docker-compose exec kafka1 opt/kafka/bin/kafka-topics.sh --create --topic user_actions --partitions 1 --replication-factor 1 --bootstrap-server kafka1:9092
```

## Create a backend cluster

Use the following command to create a [backend cluster](/event-gateway/entities/backend-cluster/) that points to the Kafka servers we created:

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
extract_body:
  - name: id
    variable: BACKEND_CLUSTER_ID
{% endkonnect_api_request %}
<!--vale on-->

Export the backend cluster ID to your environment:
```sh
export BACKEND_CLUSTER_ID="YOUR-BACKEND-CLUSTER-ID"
```

## Create an analytics virtual cluster

Use the following command to create a first virtual cluster for the `analytics` category:

<!--vale off-->
{% konnect_api_request %}
url: /v1/event-gateways/$EVENT_GATEWAY_ID/virtual-clusters
status_code: 201
method: POST
body:
  name: analytics_vc
  destination:
    id: $BACKEND_CLUSTER_ID
  dns_label: analytics
  authentication:
    - type: sasl_plain
      mediation: terminate
      principals:
        - username: analytics_user
          password: analytics_password
  acl_mode: enforce_on_gateway
  namespace:
    prefix: analytics_
    mode: hide_prefix
    additional:
      topics:
        - type: exact_list
          conflict: warn
          exact_list:
            - backend: user_actions
extract_body:
  - name: id
    variable: ANALYTICS_VC_ID
{% endkonnect_api_request %}
<!--vale on-->

This virtual cluster will be used to access topics with the `analytics_` prefix, and the `user_actions` topic.

Export the virtual cluster ID to your environment:
```sh
export ANALYTICS_VC_ID="YOUR-ANALYTICS-VIRTUAL-CLUSTER-ID"
```

## Create a payments virtual cluster

Now let's create the `payments` virtual cluster:

<!--vale off-->
{% konnect_api_request %}
url: /v1/event-gateways/$EVENT_GATEWAY_ID/virtual-clusters
status_code: 201
method: POST
body:
  name: payments_vc
  destination:
    id: $BACKEND_CLUSTER_ID
  dns_label: payments
  authentication:
    - type: sasl_plain
      mediation: terminate
      principals:
        - username: payments_user
          password: payments_password
  acl_mode: enforce_on_gateway
  namespace:
    prefix: payments_
    mode: hide_prefix
    additional:
      topics:
        - type: exact_list
          conflict: warn
          exact_list:
            - backend: user_actions
extract_body:
  - name: id
    variable: PAYMENTS_VC_ID
{% endkonnect_api_request %}
<!--vale on-->

This virtual cluster will be used to access topics with the `payments_` prefix, and the `user_actions` topic.

Export the virtual cluster ID to your environment:
```sh
export PAYMENTS_VC_ID="YOUR-PAYMENTS-VIRTUAL-CLUSTER-ID"
```

## Create an analytics listener with a policy

For testing purposes, we'll use port forwarding to route to each virtual cluster. In production, you should use SNI routing instead.

Use the following command to create the listener for the `analytics` category:

<!--vale off-->
{% konnect_api_request %}
url: /v1/event-gateways/$EVENT_GATEWAY_ID/listeners
status_code: 201
method: POST
body:
  name: analytics_listener
  addresses:
    - 0.0.0.0
  ports:
    - 19092-19095
extract_body:
  - name: id
    variable: ANALYTICS_LISTENER_ID
{% endkonnect_api_request %}
<!--vale on-->

Export the listener ID to your environment:
```sh
export ANALYTICS_LISTENER_ID="YOUR-ANALYTICS-LISTENER-ID"
```

Create the [port mapping policy](/event-gateway/policies/forward-to-virtual-cluster/):

<!--vale off-->
{% konnect_api_request %}
url: /v1/event-gateways/$EVENT_GATEWAY_ID/listeners/$ANALYTICS_LISTENER_ID/policies
status_code: 201
method: POST
body:
  type: forward_to_virtual_cluster
  name: forward_to_analytics_virtual_cluster
  config:
    type: port_mapping
    advertised_host: localhost
    destination: 
      id: $ANALYTICS_VC_ID
{% endkonnect_api_request %}
<!--vale on-->

## Create a payments listener with a policy

Use the following command to create the listener for the `payments` category:

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
    - 19096-19099
extract_body:
  - name: id
    variable: PAYMENTS_LISTENER_ID
{% endkonnect_api_request %}
<!--vale on-->

Export the listener ID to your environment:
```sh
export PAYMENTS_LISTENER_ID="YOUR-PAYMENTS-LISTENER-ID"
```
Create the port mapping policy:

<!--vale off-->
{% konnect_api_request %}
url: /v1/event-gateways/$EVENT_GATEWAY_ID/listeners/$PAYMENTS_LISTENER_ID/policies
status_code: 201
method: POST
body:
  type: forward_to_virtual_cluster
  name: forward_to_payments_virtual_cluster
  config:
    type: port_mapping
    advertised_host: localhost
    destination: 
      id: $PAYMENTS_VC_ID
{% endkonnect_api_request %}
<!--vale on-->

## Create an ACLs policy for the analytics virtual cluster

Finally, we need to set [ACL policies](/event-gateway/policies/acl/) for both virtual clusters to allow access to the topics. 

Use the following command to add an ACL policy that allows producing and consuming on the `analytics_*` and `user_actions` topics on the `analytics` virtual cluster:

<!--vale off-->
{% konnect_api_request %}
url: /v1/event-gateways/$EVENT_GATEWAY_ID/virtual-clusters/$ANALYTICS_VC_ID/cluster-policies
status_code: 201
method: POST
body:
  type: acls
  name: analytics_acl_topic_policy
  config:
    rules:
      - resource_type: topic
        action: allow
        operations:
          - name: describe
          - name: describe_configs
          - name: read
          - name: write
        resource_names:
          - match: '*'
{% endkonnect_api_request %}
<!--vale on-->

## Create an ACLs policy for the payments virtual cluster

Use the following command to add an ACL policy that allows producing and consuming to the `payments_*` topics, but only consuming from the `user_actions` topics on the `payments` virtual cluster:

<!--vale off-->
{% konnect_api_request %}
url: /v1/event-gateways/$EVENT_GATEWAY_ID/virtual-clusters/$PAYMENTS_VC_ID/cluster-policies
status_code: 201
method: POST
body:
  type: acls
  name: payments_acl_topic_policy
  config:
    rules:
      - resource_type: topic
        action: allow
        operations:
          - name: describe
          - name: describe_configs
          - name: read
          - name: write
        resource_names:
          - match: '*'
      - resource_type: topic
        action: deny
        operations:
          - name: write
        resource_names:
          - match: user_actions
{% endkonnect_api_request %}
<!--vale on-->

## Add Kafka configuration

Use the following Kafka configuration to access your Kafka resources from the virtual clusters:

```sh
cat <<EOF > kafkactl.yaml
contexts:
  analytics:
    brokers:
      - localhost:19092
    sasl:
      enabled: true
      username: analytics_user
      password: analytics_password
  payments:
    brokers:
      - localhost:19096
    sasl:
      enabled: true
      username: payments_user
      password: payments_password
EOF
```

## Validate

Get a list of topics from the `analytics` virtual cluster:

```sh
docker run --network kafka_event_gateway -v $HOME/kafkactl.yaml:/etc/kafkactl/config.yml deviceinsight/kafkactl:latest --context analytics get topics
```

You should see the following result:
```sh
TOPIC            PARTITIONS     REPLICATION FACTOR
clicks           1              1
orders           1              1
pageviews        1              1
user_actions     1              1
```
{.no-copy-code}

You can access all the topics prefixed with `analytics_` and the `user_action` topic. The `analytics_` prefix is hidden since we set the namespace mode to `hide_prefix`.

Now let's try to write to `user_actions`:

1. From the `analytics` virtual cluster:

   ```sh
   docker run --network kafka_event_gateway -v $HOME/kafkactl.yaml:/etc/kafkactl/config.yml deviceinsight/kafkactl:latest --context analytics produce user_actions --value='kafka record'
   ```

   You should get the following result:

   ```sh
   message produced (partition=0 offset=1)
   ```
   {.no-copy-code}

1. From the `payments` virtual cluster:

   ```sh
   docker run --network kafka_event_gateway -v $HOME/kafkactl.yaml:/etc/kafkactl/config.yml deviceinsight/kafkactl:latest --context payments produce user_actions --value='kafka record'
   ```

   Since we denied write access to the `user_actions` topic from the `payments` virtual cluster, you should get the following result:
   
   ```sh
   Failed to produce message: kafka server: The client is not authorized to access this topic
   ```
   {.no-copy-code}