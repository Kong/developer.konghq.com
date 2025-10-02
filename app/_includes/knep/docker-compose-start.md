We will start a Docker Compose cluster with Kafka, {{site.event_gateway_short}}, `confluent-schema-registry` and a Kafka UI.

First, we need to create a `docker-compose.yaml` file. This file will define the services we want to run in our local environment:

```shell
cat <<EOF > docker-compose.yaml
services:
  kafka:
    image: apache/kafka:3.9.0
    container_name: kafka
    ports:
      - "9092:19092"
    environment:
      KAFKA_NODE_ID: 1
      KAFKA_PROCESS_ROLES: broker,controller
      KAFKA_CONTROLLER_LISTENER_NAMES: CONTROLLER
      KAFKA_LISTENERS: INTERNAL://kafka:9092,CONTROLLER://kafka:9093,EXTERNAL://0.0.0.0:19092
      KAFKA_ADVERTISED_LISTENERS: INTERNAL://kafka:9092,EXTERNAL://localhost:9092
      KAFKA_LISTENER_SECURITY_PROTOCOL_MAP: CONTROLLER:PLAINTEXT,INTERNAL:PLAINTEXT,EXTERNAL:PLAINTEXT
      KAFKA_INTER_BROKER_LISTENER_NAME: INTERNAL
      KAFKA_CONTROLLER_QUORUM_VOTERS: 1@kafka:9093
      KAFKA_CLUSTER_ID: 'abcdefghijklmnopqrstuv'
      KAFKA_LOG_DIRS: /tmp/kraft-combined-logs

  schema-registry:
      image: confluentinc/cp-schema-registry:latest
      container_name: schema-registry
      depends_on:
        - kafka
      ports:
        - "8081:8081"
      environment:
        SCHEMA_REGISTRY_HOST_NAME: schema-registry
        SCHEMA_REGISTRY_KAFKASTORE_BOOTSTRAP_SERVERS: kafka:9092
        SCHEMA_REGISTRY_LISTENERS: http://0.0.0.0:8081
      healthcheck:
        test: curl -f http://localhost:8081/subjects
        interval: 10s
        timeout: 5s
        retries: 5
  
  kafka-ui:
    image: provectuslabs/kafka-ui:latest
    container_name: kafka-ui
    environment:
      # First cluster configuration (direct Kafka connection)
      KAFKA_CLUSTERS_0_NAME: "direct-kafka-cluster"
      KAFKA_CLUSTERS_0_BOOTSTRAPSERVERS: "kafka:9092"
      KAFKA_CLUSTERS_0_SCHEMAREGISTRY: "http://schema-registry:8081"

      # Second cluster configuration (KNEP proxy connection)
      KAFKA_CLUSTERS_1_NAME: "knep-proxy-cluster"
      KAFKA_CLUSTERS_1_BOOTSTRAPSERVERS: "knep:9092"
      KAFKA_CLUSTERS_1_SCHEMAREGISTRY: "http://schema-registry:8081"
      
      SERVER_PORT: 8082
    ports:
      - "8082:8082"
EOF
```

Note that the above config publishes the following ports to the host:

- `kafka:9092` for plaintext auth
- `kafka:9094` for SASL username/password auth
- `kafka-ui:8082` for access to the Kafka UI
- `schema-registry:8081` for access to the schema registry
- `knep:9192` to `knep:9292` for access to the {{site.event_gateway_short}} proxy (the port range is wide to allow many virtual clusters to be created)
- `knep:8080` for probes and metrics access to {{site.event_gateway_short}}

Now let's start the local setup:
```shell
docker compose up -d
```
