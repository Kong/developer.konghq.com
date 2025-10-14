We will start a Docker Compose cluster with Kafka, {{site.event_gateway_short}}, `confluent-schema-registry` and a Kafka UI.

First, we need to create a `docker-compose.yaml` file. This file will define the services we want to run in our local environment:

```shell
cat <<EOF > docker-compose.yaml
name: kafka_knep

networks:
  kafka:

services:
  kafka1:
    image: apache/kafka:3.7.0
    networks:
      - kafka
    container_name: kafka1
    ports:
      - "9094:9094"
    environment:
      KAFKA_NODE_ID: 0
      KAFKA_PROCESS_ROLES: broker,controller
      KAFKA_CONTROLLER_LISTENER_NAMES: CONTROLLER
      KAFKA_LISTENERS: INTERNAL://kafka1:9092,CONTROLLER://kafka1:9093,EXTERNAL://0.0.0.0:9094
      KAFKA_ADVERTISED_LISTENERS: INTERNAL://kafka1:9092,EXTERNAL://localhost:9094
      KAFKA_LISTENER_SECURITY_PROTOCOL_MAP: CONTROLLER:PLAINTEXT,INTERNAL:PLAINTEXT,EXTERNAL:PLAINTEXT
      KAFKA_INTER_BROKER_LISTENER_NAME: INTERNAL
      KAFKA_CONTROLLER_QUORUM_VOTERS: 0@kafka1:9093,1@kafka2:9093,2@kafka3:9093
      KAFKA_CLUSTER_ID: 'abcdefghijklmnopqrstuv'
      KAFKA_LOG_DIRS: /tmp/kraft-combined-logs

  kafka2:
    image: apache/kafka:3.7.0
    networks:
      - kafka
    container_name: kafka2
    ports:
      - "9095:9095"
    environment:
      KAFKA_NODE_ID: 1
      KAFKA_PROCESS_ROLES: broker,controller
      KAFKA_CONTROLLER_LISTENER_NAMES: CONTROLLER
      KAFKA_LISTENERS: INTERNAL://kafka2:9092,CONTROLLER://kafka2:9093,EXTERNAL://0.0.0.0:9095
      KAFKA_ADVERTISED_LISTENERS: INTERNAL://kafka2:9092,EXTERNAL://localhost:9095
      KAFKA_LISTENER_SECURITY_PROTOCOL_MAP: CONTROLLER:PLAINTEXT,INTERNAL:PLAINTEXT,EXTERNAL:PLAINTEXT
      KAFKA_INTER_BROKER_LISTENER_NAME: INTERNAL
      KAFKA_CONTROLLER_QUORUM_VOTERS: 0@kafka1:9093,1@kafka2:9093,2@kafka3:9093
      KAFKA_CLUSTER_ID: 'abcdefghijklmnopqrstuv'
      KAFKA_LOG_DIRS: /tmp/kraft-combined-logs

  kafka3:
    image: apache/kafka:3.7.0
    networks:
      - kafka
    container_name: kafka3
    ports:
      - "9096:9096"
    environment:
      KAFKA_NODE_ID: 2
      KAFKA_PROCESS_ROLES: broker,controller
      KAFKA_CONTROLLER_LISTENER_NAMES: CONTROLLER
      KAFKA_LISTENERS: INTERNAL://kafka3:9092,CONTROLLER://kafka3:9093,EXTERNAL://0.0.0.0:9096
      KAFKA_ADVERTISED_LISTENERS: INTERNAL://kafka3:9092,EXTERNAL://localhost:9096
      KAFKA_LISTENER_SECURITY_PROTOCOL_MAP: CONTROLLER:PLAINTEXT,INTERNAL:PLAINTEXT,EXTERNAL:PLAINTEXT
      KAFKA_INTER_BROKER_LISTENER_NAME: INTERNAL
      KAFKA_CONTROLLER_QUORUM_VOTERS: 0@kafka1:9093,1@kafka2:9093,2@kafka3:9093
      KAFKA_CLUSTER_ID: 'abcdefghijklmnopqrstuv'
      KAFKA_LOG_DIRS: /tmp/kraft-combined-logs
EOF
```

Now let's start the local setup:
```shell
docker compose up -d
```
