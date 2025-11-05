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

description: ""

tldr: 
  q: ""
  a: | 
    ""

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

Export the virtual cluster ID to your environment:
```sh
export ANALYTICS_VC_ID="YOUR-ANALYTICS-VIRTUAL-CLUSTER-ID"
```

## Create a payments virtual cluster

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

Export the virtual cluster ID to your environment:
```sh
export PAYMENTS_VC_ID="YOUR-PAYMENTS-VIRTUAL-CLUSTER-ID"
```

## Create an analytics listener with a policy

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
          - match: user_actions
{% endkonnect_api_request %}
<!--vale on-->

## Add Kafka configuration

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

```sh
docker run --network kafka_event_gateway -v $HOME/kafkactl.yaml:/etc/kafkactl/config.yml deviceinsight/kafkactl:latest get topics
```