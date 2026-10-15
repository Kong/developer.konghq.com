---
title: Publish requests to Kafka with the Kafka Upstream Policy
permalink: /ai-gateway/use-kafka-upstream-policy/
content_type: how_to
description: Attach a Kafka Upstream AI Policy to an AI Agent to publish incoming requests to a Kafka topic

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
  q: How do I publish requests to a Kafka topic with {{site.ai_gateway}}?
  a: |
    Create a [Kafka Upstream Policy](/ai-gateway/policies/kafka-upstream/) that points at your Kafka brokers and attach it to an [AI Agent](/ai-gateway/entities/ai-agent/).
    The Policy publishes each request to the configured topic and returns without proxying it upstream.

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
  - text: Kafka Upstream Policy
    url: /ai-gateway/policies/kafka-upstream/
  - text: Kafka Log Policy
    url: /ai-gateway/policies/kafka-log/reference/
  - text: Kafka Consume Policy
    url: /ai-gateway/policies/kafka-consume/
  - text: AI Agent entity
    url: /ai-gateway/entities/ai-agent/
  - text: AI Policy entity
    url: /ai-gateway/entities/ai-policy/

cleanup:
  inline:
    - title: Stop the Kafka broker
      content: |
        ```sh
        docker compose down
        ```
    - title: Clean up {{site.ai_gateway}} resources
      include_content: cleanup/products/ai-gateway
---

## Create the working directory and SASL credentials

Create a working directory and a JAAS file that defines the SASL/PLAIN user for the broker:

```sh
mkdir -p ~/kafka-upstream-test && cd ~/kafka-upstream-test

cat <<'EOF' > kafka_server_jaas.conf
KafkaServer {
    org.apache.kafka.common.security.plain.PlainLoginModule required
    username="kafka_user"
    password="kafka-password"
    user_kafka_user="kafka-password";
};
EOF
```

## Start a Kafka broker

Run a single-node KRaft broker with two listeners:

* SASL on port `9092`, advertised as `host.docker.internal`. The data plane connects to this listener.
* Plaintext on port `9094`, advertised as `localhost`. Local tooling connects to this listener, because `host.docker.internal` doesn't resolve from the host itself.

```sh
cat <<'EOF' > docker-compose.yaml
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

docker compose up -d
```

## Verify SASL authentication

Run the SASL check from a separate container so it uses the same network path as the data plane:

```sh
cat <<'EOF' > client.properties
security.protocol=SASL_PLAINTEXT
sasl.mechanism=PLAIN
sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username="kafka_user" password="kafka-password";
EOF

docker run --rm \
  -v "$PWD/client.properties:/tmp/client.properties" \
  apache/kafka:4.3.1 \
  /opt/kafka/bin/kafka-broker-api-versions.sh \
    --bootstrap-server host.docker.internal:9092 \
    --command-config /tmp/client.properties
```

The output lists the broker API versions, including `SaslHandshake(17)` and `SaslAuthenticate(36)`, without a `SaslAuthenticationException`.

## Create the Kafka topic

Create a `kafkactl` context that connects through the plaintext listener, then create the `kong-upstream` topic:

```sh
cat <<'EOF' > kafkactl.yaml
contexts:
  direct:
    brokers:
      - localhost:9094
EOF

kafkactl -C kafkactl.yaml --context direct create topic kong-upstream
```

## Create a Kafka Upstream Policy and an AI Agent

Create a [Kafka Upstream Policy](/ai-gateway/policies/kafka-upstream/) and attach it to an [AI Agent](/ai-gateway/entities/ai-agent/) that supplies the Route.
The Policy terminates the request after publishing it to Kafka, so the Agent never forwards the request to its `config.url`.

This example sets `security.ssl` to `false` so the test setup doesn't need certificates.
We don't recommend this in production because the traffic isn't encrypted.

```sh
cat <<'EOF' > kafka-upstream.yaml
_defaults:
  kongctl:
    namespace: kafka-upstream-test

ai_gateway_policies:
  - ref: kafka-upstream
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    name: kafka-upstream
    display_name: Kafka Upstream
    type: kafka-upstream
    enabled: true
    global: false
    config:
      bootstrap_servers:
        - host: host.docker.internal
          port: 9092
      topic: kong-upstream
      forward_body: true
      forward_headers: true
      forward_method: true
      forward_uri: true
      authentication:
        strategy: sasl
        mechanism: PLAIN
        user: kafka_user
        password: kafka-password
      security:
        ssl: false

ai_gateway_agents:
  - ref: kafka-upstream-agent
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    name: kafka-upstream-agent
    display_name: "Kafka Upstream Agent"
    type: http
    enabled: true
    policies: [ !ref kafka-upstream#name ]
    config:
      url: http://host.docker.internal:9999
      route:
        paths:
          - /upstream-test
        protocols:
          - http
          - https
        methods:
          - GET
          - POST
        strip_path: true
EOF

kongctl sync -f kafka-upstream.yaml --pat "$KONNECT_TOKEN"
```

## Validate

Wait a few seconds for the data plane to pick up the new configuration.
Requests sent before the data plane picks up the configuration return `404`.

1. Send a `POST` request with a JSON body to the Agent's Route:

   ```sh
   curl -i -X POST "$KONNECT_PROXY_URL/upstream-test" \
     -H 'Content-Type: application/json' \
     -d '{"hello":"world"}'
   ```

   The Policy terminates the request, so the response is a `200` with an acknowledgement from the Policy instead of a response from `config.url`.
   A `502` means the Policy didn't engage, so the Agent forwarded the request to the unused upstream port.

1. Read the message back from the topic:

   ```sh
   kafkactl -C kafkactl.yaml --context direct consume kong-upstream --from-beginning --exit | jq .
   ```

   The output contains the request body, headers, method, and URI:

   ```json
   {
     "body": "{\"hello\":\"world\"}",
     "body_args": {
       "hello": "world"
     },
     "uri": "/upstream-test",
     "method": "POST",
     "headers": {
       "content-type": "application/json",
       "user-agent": "curl/8.7.1",
       "accept": "*/*",
       "host": "localhost:8000",
       "content-length": "17"
     },
     "uri_args": {}
   }
   ```
   {:.no-copy-code}
