---
title: How to test `kafka-log` plugin with sasl
content_type: support
description: "Use `kafkacat` and a local Kafka broker configured for SASL authentication to verify that the `kafka-log` plugin is sending request and response logs to Kong."
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources: []
tldr:
  q: How do I test the `kafka-log` plugin with SASL authentication?
  a: |
    Spin up a local Kafka broker configured for `SASL_PLAINTEXT` authentication using a `kafka_server_jaas.conf` file, then attach the `kafka-log` plugin to a Kong route or service with matching SASL credentials. Use `kafkacat` to consume from the configured topic, send a request through Kong, and confirm a matching log entry appears in the `kafkacat` consumer output — this confirms the plugin is delivering logs to Kafka successfully.
---

## Overview

How to test the `kafka-log` plugin with sasl?

## Steps

Tool check:

The `kafka-log` plugin sends request and response logs to a Kafka topic.

Kafka is a message queue / event streaming platform that stores the logs and allows their retrieval.

`kafkacat` is a tool we can use to produce and consume messages from a Kafka topic. This allows us to test that Kong is sending the logs successfully.

This example will be using sasl plaintext as the auth mechanism.

1. Spin up Kong.

   Setup Kong to your normal liking.

2. Start Zookeeper, Broker, and `kafkacat`.

   This requires a few components.

   1. The `kafka_server_jaas.conf` file, which the docker compose loads as a volume mount. This file is what sets the admin password: `admin-secret`.

      Copy the following contents into a file called `kafka_server_jaas.conf`:

      ```text
      KafkaServer {
        org.apache.kafka.common.security.plain.PlainLoginModule required
        username="admin"
        password="admin-secret"
        user_admin="admin-secret"
        user_alice="alice-secret";
      };
      Client {};
      ```

   2. Once `kafka_server_jaas.conf` exists, you can then spin up the docker compose file below to start the containers. Note: the Confluent images pinned below (`7.0.1`) are quite old — if the `kafka-log` plugin's producer fails to initialize against your broker with an error like `could not create a Kafka Producer from given configuration: Could not retrieve version map from cluster`, try a current-generation Confluent/Apache Kafka image instead, since old broker images can hit client/broker version-negotiation issues unrelated to the SASL configuration itself.

      ```yaml
      version: "3"

      networks:
        kong_net:
          driver: bridge
          ipam:
            driver: default
            config:
              - subnet: "172.18.0.0/24"
                gateway: "172.18.0.1"

      services:

       zookeeper:
        image: confluentinc/cp-zookeeper:7.0.1
        container_name: zookeeper
        environment:
          ZOOKEEPER_CLIENT_PORT: 2181
          ZOOKEEPER_TICK_TIME: 2000
        networks:
          kong_net:
            ipv4_address: 172.18.0.81

       broker:
        image: confluentinc/cp-kafka:7.0.1
        container_name: broker
        ports:
        # To learn about configuring Kafka for access across networks see
        # https://www.confluent.io/blog/kafka-client-cannot-connect-to-broker-on-aws-on-docker-etc/
          - "9092:9092"
        depends_on:
          - zookeeper
        environment:
          KAFKA_BROKER_ID: 1
          KAFKA_ZOOKEEPER_CONNECT: 'zookeeper:2181'
          KAFKA_LISTENER_SECURITY_PROTOCOL_MAP: PLAINTEXT:PLAINTEXT,PLAINTEXT_INTERNAL:PLAINTEXT,SASL_PLAINTEXT:SASL_PLAINTEXT
          KAFKA_LISTENERS: SASL_PLAINTEXT://:9092
          KAFKA_ADVERTISED_LISTENERS: SASL_PLAINTEXT://broker:9092
          KAFKA_OPTS: "-Djava.security.auth.login.config=/etc/kafka/kafka_server_jaas.conf"
          KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR: 1
          KAFKA_TRANSACTION_STATE_LOG_MIN_ISR: 1
          KAFKA_TRANSACTION_STATE_LOG_REPLICATION_FACTOR: 1
          KAFKA_SASL_ENABLED_MECHANISMS: PLAIN
          KAFKA_SASL_MECHANISM_INTER_BROKER_PROTOCOL: PLAIN
          KAFKA_INTER_BROKER_LISTENER_NAME: SASL_PLAINTEXT
          ZOOKEEPER_SASL_ENABLED: false
        volumes:
          - /var/run/docker.sock:/var/run/docker.sock
          - ./kafka_server_jaas.conf:/etc/kafka/kafka_server_jaas.conf
        networks:
          kong_net:
            ipv4_address: 172.18.0.82

       kafkacat:
        image: confluentinc/cp-kafkacat
        container_name: kafkacat
        command: "tail -F anything"
        networks:
          kong_net:
            ipv4_address: 172.18.0.83
      ```

3. Attach a `kafka-log` plugin to any route or service of your choice.

   Ensure the config has the following values:

   ```yaml
   - config:
       authentication:
         mechanism: PLAIN
         password: admin-secret
         strategy: sasl
         user: admin
       bootstrap_servers:
       - host: broker
         port: 9092

       topic: test-topic
   ```

   Or you can sync the following declarative config and have the plugin setup for you on a httpbin service / route:

   ```yaml
   _format_version: "3.0"
   services:
   - connect_timeout: 60000
     enabled: true
     host: httpbin.org
     name: httpbin
     path: /anything
     plugins:
     - config:
         authentication:
           mechanism: PLAIN
           password: admin-secret
           strategy: sasl
           tokenauth: null
           user: admin
         bootstrap_servers:
         - host: broker
           port: 9092
         cluster_name: PKJCWy97gRL2dgm6N5AGdSxfjWm4xW6m
         keepalive: 60000
         keepalive_enabled: false
         producer_async: true
         producer_async_buffering_limits_messages_in_memory: 50000
         producer_async_flush_timeout: 1000
         producer_request_acks: 1
         producer_request_limits_bytes_per_request: 1048576
         producer_request_limits_messages_per_request: 200
         producer_request_retries_backoff_timeout: 100
         producer_request_retries_max_attempts: 10
         producer_request_timeout: 2000
         security:
           certificate_id: null
           ssl: null
         timeout: 10000
         topic: new-topic
       enabled: true
       name: kafka-log
       protocols:
       - grpc
       - grpcs
       - http
       - https
     port: 443
     protocol: https
     read_timeout: 60000
     retries: 5
     routes:
     - https_redirect_status_code: 426
       id: 8ca0d4e4-687b-42f4-be19-b59fa7978739
       path_handling: v0
       paths:
       - /bin
       preserve_host: false
       protocols:
       - http
       - https
       regex_priority: 0
       request_buffering: true
       response_buffering: true
       strip_path: true
     write_timeout: 60000
   ```

4. Test the setup.

   1. Create the Kafka topic.

      Run the following `kafkacat` command twice in a new terminal window.

      The first time will initialize the broker but the second time will begin listening to the messages that are sent to the broker from Kong:

      ```bash
      docker exec -it kafkacat kafkacat \
      -C -b broker:9092 \
      -X security.protocol=SASL_PLAINTEXT \
      -X sasl.mechanism=PLAIN \
      -X sasl.username=admin \
      -X sasl.password=admin-secret \
      -t new-topic \
      -o beginning
      ```

      You may receive this error on the first attempt:

      ```
      ERROR: Topic new-topic error: Broker: Leader not available
      ```

      However the second attempt should be met with the following and a running prompt:

      ```
      Reached end of topic new-topic [0] at offset 0
      ```

   2. Send a request to the route to generate a log entry:

      ```bash
      curl https://proxy.local.docker:8443/bin

      {
        "args": {},
        "data": "",
        "files": {},
        "form": {},
        "headers": {
          "Accept": "*/*",
          "Host": "httpbin.org",
          "User-Agent": "curl/7.85.0",
          "X-Amzn-Trace-Id": "Root=1-63c8b8b4-44b556021311f8cb2e75db6b",
          "X-Forwarded-Host": "proxy.local.docker",
          "X-Forwarded-Path": "/bin",
          "X-Forwarded-Prefix": "/bin"
        },
        "json": null,
        "method": "GET",
        "origin": "172.18.0.1, 159.196.53.233",
        "url": "https://proxy.local.docker/anything"
      }
      ```

      You should see the request and response log appear from your request in your `kafkacat` terminal window as below:

      ```
      Reached end of topic new-topic [0] at offset 0

      {"upstream_uri":"/anything","response":{"headers":{"content-length":"478", ...}

      Reached end of topic new-topic [0] at offset 1
      ```

      Kong has successfully sent request and response logs to Kafka.

Bonus command: How to send arbitrary messages to kafka with `kafkacat` to ensure Kafka is working.

```bash
docker exec -it kafkacat kafkacat -P -b broker:9092 \
-X security.protocol=SASL_PLAINTEXT \
-X sasl.mechanism=PLAIN \
-X sasl.username=admin \
-X sasl.password=admin-secret \
-t new-topic
```

This command will have a rolling prompt which you can send the message by hitting enter.

The messages should appear in your other `kafkacat` terminal as they did when Kong sent the messages.
