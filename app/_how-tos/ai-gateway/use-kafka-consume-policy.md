---
title: Consume Kafka messages over HTTP with the Kafka Consume Policy
permalink: /ai-gateway/use-kafka-consume-policy/
content_type: how_to
description: Attach a Kafka Consume AI Policy to an AI Agent to read messages from Kafka topics through an HTTP endpoint

products:
  - ai-gateway

works_on:
  - konnect

min_version:
  ai-gateway: '2.0'

entities:
  - ai-agent
  - ai-policy

tags:
  - ai
  - kafka
  - docker

tldr:
  q: How do I read Kafka messages through an HTTP endpoint with {{site.ai_gateway}}?
  a: |
    Create a [Kafka Consume Policy](/ai-gateway/policies/kafka-consume/) that points at your Kafka brokers and topics, and attach it to an [AI Agent](/ai-gateway/entities/ai-agent/).
    A `GET` request to the Agent's Route returns the messages consumed from the topics.

tools:
  - kongctl

prereqs:
  inline:
    - title: kafkactl
      include_content: md/ai-gateway/v2/prereqs/kafkactl
      icon_url: /assets/icons/kafka.svg
    - title: jq
      include_content: md/ai-gateway/v2/prereqs/jq
      icon_url: /assets/icons/code.svg

related_resources:
  - text: Kafka Consume Policy
    url: /ai-gateway/policies/kafka-consume/
  - text: Kafka Upstream Policy
    url: /ai-gateway/policies/kafka-upstream/reference/
  - text: Kafka Log Policy
    url: /ai-gateway/policies/kafka-log/reference/
  - text: Publish requests to Kafka with the Kafka Upstream Policy
    url: /ai-gateway/use-kafka-upstream-policy/
  - text: AI Agent entity
    url: /ai-gateway/entities/ai-agent/
  - text: AI Policy entity
    url: /ai-gateway/entities/ai-policy/

cleanup:
  inline:
    - title: Stop the Kafka broker
      content: |
        ```sh
        docker compose -f kafka-consume-test/docker-compose.yaml down
        ```
        {: data-test-cleanup="block" }
    - title: Clean up {{site.ai_gateway}} resources
      include_content: cleanup/products/ai-gateway
---

## Create the working directory and SASL credentials

Create a working directory and a JAAS file that defines the SASL/PLAIN user for the broker:

```sh
mkdir -p kafka-consume-test

cat <<'EOF' > kafka-consume-test/kafka_server_jaas.conf
KafkaServer {
    org.apache.kafka.common.security.plain.PlainLoginModule required
    username="kafka_user"
    password="kafka-password"
    user_kafka_user="kafka-password";
};
EOF
```
{: data-test-step="block" }

## Start a Kafka broker

Run a single-node KRaft broker with two listeners:

* SASL on port `9092`, advertised as `host.docker.internal`. The data plane connects to this listener.
* Plaintext on port `9094`, advertised as `localhost`. Local tooling connects to this listener, because `host.docker.internal` doesn't resolve from the host itself.

```sh
cat <<'EOF' > kafka-consume-test/docker-compose.yaml
name: kafka_aigw

services:
  kafka:
    image: apache/kafka:4.3.1
    container_name: kafka
    ports:
      - "9092:9092"
      - "9094:9094"
    environment:
      KAFKA_NODE_ID: 0
      KAFKA_PROCESS_ROLES: broker,controller
      KAFKA_CONTROLLER_LISTENER_NAMES: CONTROLLER
      KAFKA_CONTROLLER_QUORUM_VOTERS: 0@localhost:9093
      KAFKA_LISTENERS: CONTROLLER://localhost:9093,SASL_PLAINTEXT://0.0.0.0:9092,PLAINTEXT://0.0.0.0:9094
      KAFKA_ADVERTISED_LISTENERS: SASL_PLAINTEXT://host.docker.internal:9092,PLAINTEXT://localhost:9094
      KAFKA_LISTENER_SECURITY_PROTOCOL_MAP: CONTROLLER:PLAINTEXT,SASL_PLAINTEXT:SASL_PLAINTEXT,PLAINTEXT:PLAINTEXT
      KAFKA_INTER_BROKER_LISTENER_NAME: PLAINTEXT
      KAFKA_SASL_ENABLED_MECHANISMS: PLAIN
      KAFKA_OPTS: -Djava.security.auth.login.config=/etc/kafka/kafka_server_jaas.conf
      KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR: 1
      KAFKA_TRANSACTION_STATE_LOG_REPLICATION_FACTOR: 1
      KAFKA_TRANSACTION_STATE_LOG_MIN_ISR: 1
      KAFKA_CLUSTER_ID: 'abcdefghijklmnopqrstuv'
      KAFKA_LOG_DIRS: /tmp/kraft-combined-logs
    volumes:
      - ./kafka_server_jaas.conf:/etc/kafka/kafka_server_jaas.conf
EOF

docker compose -f kafka-consume-test/docker-compose.yaml up -d
```
{: data-test-step="block" }

## Verify SASL authentication

Run the SASL check from a separate container so it uses the same network path as the data plane:

{% validation custom-command %}
command: |
  cat <<'EOF' > kafka-consume-test/client.properties
  security.protocol=SASL_PLAINTEXT
  sasl.mechanism=PLAIN
  sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username="kafka_user" password="kafka-password";
  EOF

  docker run --rm \
    -v "$PWD/kafka-consume-test/client.properties:/tmp/client.properties" \
    apache/kafka:4.3.1 \
    /opt/kafka/bin/kafka-broker-api-versions.sh \
      --bootstrap-server host.docker.internal:9092 \
      --command-config /tmp/client.properties
expected:
  return_code: 0
  message: 'SaslHandshake(17)'
render_output: false
{% endvalidation %}

The output lists the broker API versions, including `SaslHandshake(17)` and `SaslAuthenticate(36)`, without a `SaslAuthenticationException`.

## Create the Kafka topics

Create a `kafkactl` context that connects through the plaintext listener, then create the `ai-events` and `ai-audit` topics:

{% validation custom-command %}
command: |
  cat <<'EOF' > kafka-consume-test/kafkactl.yaml
  contexts:
    direct:
      brokers:
        - localhost:9094
  EOF

  kafkactl -C kafka-consume-test/kafkactl.yaml --context direct create topic ai-events
expected:
  return_code: 0
  message: 'topic created: ai-events'
render_output: false
{% endvalidation %}

Create the second topic:

{% validation custom-command %}
command: |
  kafkactl -C kafka-consume-test/kafkactl.yaml --context direct create topic ai-audit
expected:
  return_code: 0
  message: 'topic created: ai-audit'
render_output: false
{% endvalidation %}

## Create a Kafka Consume Policy and an AI Agent

Create a [Kafka Consume Policy](/ai-gateway/policies/kafka-consume/) and attach it to an [AI Agent](/ai-gateway/entities/ai-agent/) that supplies the Route the Policy serves from.

This example sets `security.ssl` to `false` so the test setup doesn't need certificates.
We don't recommend this in production because the traffic isn't encrypted.

```sh
cat <<'EOF' > kafka-consume-test/kafka-consume.yaml
_defaults:
  kongctl:
    namespace: kafka-test

ai_gateway_policies:
  - ref: kafka-consume
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    name: kafka-consume
    display_name: Kafka Consume
    type: kafka-consume
    enabled: true
    global: false
    config:
      bootstrap_servers:
        - host: host.docker.internal
          port: 9092
      topics:
        - name: ai-events
        - name: ai-audit
      mode: http-get
      message_deserializer: json
      auto_offset_reset: latest
      enforce_latest_offset_reset: true
      authentication:
        strategy: sasl
        mechanism: PLAIN
        user: kafka_user
        password: kafka-password
      security:
        ssl: false

ai_gateway_agents:
  - ref: kafka-consume-agent
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    name: kafka-consume-agent
    display_name: "Kafka Consume Agent"
    type: http
    enabled: true
    policies: [ !ref kafka-consume#name ]
    config:
      url: http://host.docker.internal:9999
      route:
        paths:
          - /kafka
        protocols:
          - http
          - https
        methods:
          - GET
        strip_path: true
EOF

kongctl sync -f kafka-consume-test/kafka-consume.yaml --auto-approve --pat "$KONNECT_TOKEN"
```
{: data-test-step="block" }

## Validate

The Policy uses `auto_offset_reset: latest`, so the consumer starts at the end of each topic and only returns messages produced after it starts consuming. Prime the consumer first, then produce messages.

1. Send a first request to start the consumer.
   Requests sent before the data plane picks up the new configuration return `404`, so wait a few seconds after `kongctl sync`.
   The response contains no records yet:

{% validation request-check %}
url: /kafka
status_code: 200
indent: 3
{% endvalidation %}

1. Produce a message to the `ai-events` topic:
<!--vale off-->
{% validation custom-command %}
command: |
  kafkactl -C kafka-consume-test/kafkactl.yaml --context direct produce ai-events --value='{"event":"prompt_received","model":"gpt-4o"}'
expected:
  return_code: 0
  message: 'message produced'
render_output: false
indent: 3
{% endvalidation %}
<!--vale on-->

1. Produce a message to the `ai-audit` topic:
<!--vale off-->
{% validation custom-command %}
command: |
  kafkactl -C kafka-consume-test/kafkactl.yaml --context direct produce ai-audit --value='{"actor":"user","action":"policy_applied"}'
expected:
  return_code: 0
  message: 'message produced'
render_output: false
indent: 3
{% endvalidation %}
<!--vale on-->

1. Send a second request to read the messages:
<!--vale off-->
{% validation custom-command %}
command: |
  curl -s "$KONNECT_PROXY_URL/kafka" | jq .
expected:
  return_code: 0
  message: '"prompt_received"'
render_output: false
indent: 3
{% endvalidation %}
<!--vale on-->
   The response groups records by topic name, then by partition:
   <!--vale off-->
   ```json
   {
     "ai-events": {
       "partitions": {
         "0": {
           "high_watermark": 1,
           "last_stable_offset": 1,
           "errcode": 0,
           "records": [
             {
               "value": {"event": "prompt_received", "model": "gpt-4o"},
               "key": "",
               "timestamp": 1787305085262,
               "offset": 0
             }
           ],
           "aborted_transactions": {}
         }
       }
     },
     "ai-audit": {
       "partitions": {
         "0": {
           "high_watermark": 1,
           "last_stable_offset": 1,
           "errcode": 0,
           "records": [
             {
               "value": {"actor": "user", "action": "policy_applied"},
               "key": "",
               "timestamp": 1787305085290,
               "offset": 0
             }
           ],
           "aborted_transactions": {}
         }
       }
     }
   }
   ```
   {:.no-copy-code}
   <!--vale on-->