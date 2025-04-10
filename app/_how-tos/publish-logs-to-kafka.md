---
title: Publish request and response logs to an Apache Kafka topic with the Kafka Log plugin
content_type: how_to
related_resources:
  - text: Apache Kafka documentation
    url: https://kafka.apache.org/documentation/

products:
    - gateway

plugins:
  - kafka-log

works_on:
    - on-prem
    - konnect

min_version:
  gateway: '3.4'

entities: 
  - plugin
  - service
  - route
  - consumer

tags:
    - authentication

tldr:
    q: How do I publish request and response logs to an Apache Kafka topic with the Kafka Log plugin?
    a: Create a Kafka topic, and set your Kafka host as an environment variable. Enable the Kafka Log plugin and specify the Kafka host, port, and topic when you configure it.

tools:
    - deck

prereqs:
  entities:
    services:
        - example-service
    routes:
        - example-route

cleanup:
  inline:
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg
---

## 1. Run the Kafka broker in Docker

To run the broker, this will run Kafka 4.0 in [KRaft mode](https://kafka.apache.org/40/documentation/zk2kraft.html). This allows for connections from within the Docker network, from the host machine, and from the Docker bridge network:

```sh
docker run -d --rm --name=kafka -h kafka -p 9092:9092 -p 39092:39092 \
    -e KAFKA_NODE_ID=1 \
    -e KAFKA_LISTENERS='DOCKER://kafka:29092,CONTROLLER://kafka:29093,HOST://0.0.0.0:9092,BRIDGE://0.0.0.0:39092' \
    -e KAFKA_LISTENER_SECURITY_PROTOCOL_MAP='CONTROLLER:PLAINTEXT,DOCKER:PLAINTEXT,HOST:PLAINTEXT,BRIDGE:PLAINTEXT' \
    -e KAFKA_ADVERTISED_LISTENERS='DOCKER://kafka:29092,HOST://localhost:9092,BRIDGE://host.docker.internal:39092' \
    -e KAFKA_PROCESS_ROLES='broker,controller' \
    -e KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR=1 \
    -e KAFKA_CONTROLLER_QUORUM_VOTERS='1@kafka:29093' \
    -e KAFKA_INTER_BROKER_LISTENER_NAME='DOCKER' \
    -e KAFKA_CONTROLLER_LISTENER_NAMES='CONTROLLER' \
    -e CLUSTER_ID='MkU3OEVBNTcwNTJENDM2Qk' \
    apache/kafka:4.0.0
```

## 2. Create Kafka topic

Now that the broker is running, we can create the `kong-log` Kafka topic:
```sh
docker exec -it kafka /opt/kafka/bin/kafka-topics.sh --bootstrap-server kafka:29092 --create --topic kong-log
```

Since the topic can vary in production instances, set the Kafka topic as an environment variable:
```sh
export DECK_KAFKA_TOPIC=kong-log
```

## 2. Enable the Kafka Log plugin

Set the `host.docker.internal` as your host. We're using this as our host in this tutorial because {{site.base_gateway}} is using `localhost` and both {{site.base_gateway}} and Kafka are in Docker containers.

```sh
export DECK_KAFKA_HOST=host.docker.internal
```

Enable the plugin on the [`example-route` we created earlier](/how-to/publish-logs-to-kafka/#prerequisites):

{% entity_examples %}
entities:
  plugins:
    - name: kafka-log
      route: example-route
      config:
        bootstrap_servers:
        - host: ${kafka_host}
          port: 39092
        topic: ${kafka_topic}
variables:
  kafka_host:
    value: $HOST
  kafka_topic:
    value: $KAFKA_TOPIC
{% endentity_examples %}

## Make sample requests

Send the following request to generate logs:

```bash
for i in {1..50} ; do curl http://localhost:8000/anything/$i ; done
```

## 3. Validate

Verify the contents of the Kafka `kong-log` topic:

```sh
docker exec -it kafka /opt/kafka/bin/kafka-console-consumer.sh --bootstrap-server kafka:29092 --topic kong-log --from-beginning
```