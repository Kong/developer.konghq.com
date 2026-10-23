---
title: Send request logs to Kafka with the Kafka Log Policy
permalink: /ai-gateway/use-kafka-log-policy/
content_type: how_to
description: Create a global Kafka Log AI Policy to publish request and response logs to a Kafka topic

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
  - logging
  - docker

tldr:
  q: How do I send request and response logs to a Kafka topic with {{site.ai_gateway}}?
  a: |
    Create a global [Kafka Log Policy](/ai-gateway/policies/kafka-log/) that points at your Kafka brokers and a log topic.
    The Policy publishes a log entry to the topic for every request, whatever the response status.

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
  - text: Kafka Log Policy
    url: /ai-gateway/policies/kafka-log/
  - text: Kafka Consume Policy
    url: /ai-gateway/policies/kafka-consume/
  - text: Kafka Upstream Policy
    url: /ai-gateway/policies/kafka-upstream/reference/
  - text: HTTP Log Policy
    url: /ai-gateway/policies/http-log/
  - text: AI Agent entity
    url: /ai-gateway/entities/ai-agent/
  - text: AI Policy entity
    url: /ai-gateway/entities/ai-policy/

cleanup:
  inline:
    - title: Stop the Kafka broker and the HTTP upstream
      content: |
        Stop the Kafka broker:

        ```sh
        docker compose down
        ```

        Remove the nginx container:

        ```sh
        docker rm -f log-upstream
        ```
    - title: Clean up {{site.ai_gateway}} resources
      include_content: cleanup/products/ai-gateway
---

## Create the working directory and SASL credentials

Create a working directory and a JAAS file that defines the SASL/PLAIN user for the broker:

```sh
mkdir -p ~/kafka-log-test && cd ~/kafka-log-test

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

## Create the Kafka log topic

Create a `kafkactl` context that connects through the plaintext listener, then create the `kong-log` topic:

```sh
cat <<'EOF' > kafkactl.yaml
contexts:
  direct:
    brokers:
      - localhost:9094
EOF

kafkactl -C kafkactl.yaml --context direct create topic kong-log
```

## Start an HTTP upstream

The AI Agent needs an HTTP upstream to proxy requests to.
Start an nginx container to serve that role:

```sh
docker run -d --name log-upstream -p 8080:80 nginx:alpine
```

Confirm that nginx responds on port `8080`:

```sh
curl -i http://localhost:8080
```

## Create a Kafka Log Policy and an AI Agent

Create a global [Kafka Log Policy](/ai-gateway/policies/kafka-log/), which logs every request, and an [AI Agent](/ai-gateway/entities/ai-agent/) that supplies a Route to send requests through.
The Agent's `config.url` points at the nginx container, so proxied requests return a `200`.

This example sets `security.ssl` to `false` so the test setup doesn't need certificates.
We don't recommend this in production because the traffic isn't encrypted.

```sh
cat <<'EOF' > kafka-log.yaml
_defaults:
  kongctl:
    namespace: kafka-log-test

ai_gateway_policies:
  - ref: kafka-log
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    name: kafka-log
    display_name: Kafka Log
    type: kafka-log
    enabled: true
    global: true
    config:
      bootstrap_servers:
        - host: host.docker.internal
          port: 9092
      topic: kong-log
      authentication:
        strategy: sasl
        mechanism: PLAIN
        user: kafka_user
        password: kafka-password
      security:
        ssl: false

ai_gateway_agents:
  - ref: kafka-log-agent
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    name: kafka-log-agent
    display_name: "Kafka Log Agent"
    type: http
    enabled: true
    config:
      url: http://host.docker.internal:8080
      route:
        paths:
          - /log-test
        protocols:
          - http
          - https
        methods:
          - GET
          - POST
        strip_path: true
EOF

kongctl sync -f kafka-log.yaml --pat "$KONNECT_TOKEN"
```

## Validate

Unlike the Kafka Consume Policy, the Kafka Log Policy publishes to Kafka.
Send requests first, then read the topic.

1. Wait a few seconds for the data plane to pick up the new configuration.
   Requests sent before the data plane picks up the configuration return `404`.
   Then send a `GET` request to the Agent's Route to generate a log entry:

   ```sh
   curl -s -o /dev/null "$KONNECT_PROXY_URL/log-test"
   ```

1. Send a `POST` request with a JSON body to generate a second log entry:

   ```sh
   curl -s -o /dev/null -X POST "$KONNECT_PROXY_URL/log-test" \
     -H 'Content-Type: application/json' \
     -d '{"hello":"world"}'
   ```

1. Read the log entries from the topic.
   Because `config.producer_async` defaults to `true`, entries can take a second or two to appear:

   ```sh
   kafkactl -C kafkactl.yaml --context direct consume kong-log --from-beginning --exit | jq .
   ```

   The `GET` is logged with `response.status: 200`.
   The `POST` is logged with `405`, because nginx rejects a `POST` to a static file.
   The Policy logs both requests regardless of the response status.

   The following is a trimmed log entry:

   ```json
   {
     "source": "kong",
     "client_ip": "192.168.97.1",
     "started_at": 1787579347089,
     "workspace_name": "default",
     "upstream_uri": "/",
     "upstream_status": "200",
     "request": {
       "method": "GET",
       "uri": "/log-test",
       "url": "http://localhost:8000/log-test",
       "size": 86,
       "querystring": {},
       "headers": {
         "host": "localhost:8000",
         "user-agent": "curl/8.17.0",
         "accept": "*/*"
       }
     },
     "response": {
       "status": 200,
       "size": 853,
       "headers": {
         "content-type": "text/html",
         "server": "kong/2.0.2-ai-gateway"
       }
     },
     "latencies": {
       "kong": 1,
       "proxy": 4,
       "request": 5
     },
     "route": {
       "name": "kafka-log-agent-route",
       "paths": ["/log-test"],
       "methods": ["GET", "POST"],
       "strip_path": true
     },
     "service": {
       "name": "kafka-log-agent",
       "host": "host.docker.internal",
       "port": 8080,
       "protocol": "http"
     },
     "tries": []
   }
   ```
   {:.no-copy-code}
