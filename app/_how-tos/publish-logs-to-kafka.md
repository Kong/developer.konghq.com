---
title: Publish request and response logs to an Apache Kafka topic with the Kafka Log plugin
content_type: how_to
related_resources:
  - text: Authentication
    url: /gateway/authentication/

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
    q: How do I authenticate Consumers with basic authentication?
    a: Create a Consumer with a username and password in the `basicauth_credentials` configuration. Enable the Basic Authentication plugin globally, and authenticate with the base64-encoded Consumer credentials.

tools:
    - deck

prereqs:
  entities:
    services:
        - example-service
    routes:
        - example-route
  inline:
    - title: Apache Kafka
      content: |
        In this tutorial, we'll be using Apache Kafka:
        1. Install Apache Kafka.
        2. Get the Kafka Docker image:
        ```sh
        docker pull apache/kafka-native:4.0.0
        docker run -d --name kafka --network kong-quickstart-net -p 9092:9092 apache/kafka-native:4.0.0
        ```

cleanup:
  inline:
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg
---

## Create Kafka topic

Save the path to `/bin/kafka-topics` as an environment variable:

```sh
export KAFKA_HOME='</path/to/kafka/>'
```

Create the `kong-log` Kafka topic:
```bash
$KAFKA_HOME/bin/kafka-topics --create \
    --bootstrap-server localhost:9092 \
    --replication-factor 1 \
    --partitions 10 \
    --topic kong-log
```

Since the topic can vary in production instances, set the Kafka topic as an environment variable:
```sh
export DECK_KAFKA_TOPIC=kong-log
```

## 2. Enable the Kafka Log plugin

Set the `host.docker.internal` as your host. We're using this as our host in this tutorial because {{site.base_gateway}} is using `localhost` and both {{site.base_gateway}} and Kafka are in Docker containers.

```sh
export DECK_HOST=host.docker.internal
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
          port: 9092
        topic: ${kafka_topic}
variables:
  kafka_host:
    value: $HOST
  kafka_topic:
    value: $KAFKA_TOPIC
{% endentity_examples %}

## Make sample requests

```bash
for i in {1..50} ; do curl http://localhost:8000/anything/$i ; done
```

## 3. Validate

Verify the contents of the Kafka `kong-log` topic:

```sh
$KAFKA_HOME/bin/kafka-console-consumer \
    --bootstrap-server localhost:9092 \
    --topic kong-log \
    --partition 0 \
    --from-beginning \
    --timeout-ms 1000
```