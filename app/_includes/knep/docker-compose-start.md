We will start a Docker Compose cluster with Kafka, {{site.event_gateway_short}}, `confluent-schema-registry` and a Kafka UI.

First, we need to create a `docker-compose.yaml` file. This file will define the services we want to run in our local environment:

```shell
cat <<EOF > docker-compose.yaml
services:
  broker:
    image: apache/kafka:latest
    container_name: broker
    environment:
      KAFKA_NODE_ID: 1
      KAFKA_PROCESS_ROLES: broker,controller
      KAFKA_CONTROLLER_LISTENER_NAMES: CONTROLLER
      KAFKA_LISTENERS: PLAINTEXT://0.0.0.0:9092,CONTROLLER://0.0.0.0:9093,EXTERNAL://0.0.0.0:9094
      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://broker:9092,EXTERNAL://localhost:9094
      KAFKA_LISTENER_SECURITY_PROTOCOL_MAP: CONTROLLER:PLAINTEXT,PLAINTEXT:PLAINTEXT,EXTERNAL:PLAINTEXT
      KAFKA_INTER_BROKER_LISTENER_NAME: PLAINTEXT
      KAFKA_CONTROLLER_QUORUM_VOTERS: 1@broker:9093
      KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR: 1
      KAFKA_TRANSACTION_STATE_LOG_REPLICATION_FACTOR: 1
      KAFKA_TRANSACTION_STATE_LOG_MIN_ISR: 1
      KAFKA_GROUP_INITIAL_REBALANCE_DELAY: 0
      KAFKA_NUM_PARTITIONS: 3
      KAFKA_CONTROLLER_LISTENER_SECURITY_PROTOCOL_MAP: CONTROLLER:PLAINTEXT
    ports:
      - "9092:9092"
      - "9094:9094"
    healthcheck:
      test: kafka-topics.sh --bootstrap-server broker:9092 --list
      interval: 10s
      timeout: 10s
      retries: 5

  schema-registry:
    image: confluentinc/cp-schema-registry:latest
    container_name: schema-registry
    depends_on:
      - broker
    ports:
      - "8081:8081"
    environment:
      SCHEMA_REGISTRY_HOST_NAME: schema-registry
      SCHEMA_REGISTRY_KAFKASTORE_BOOTSTRAP_SERVERS: broker:9092
      SCHEMA_REGISTRY_LISTENERS: http://0.0.0.0:8081
    healthcheck:
      test: curl -f http://localhost:8081/subjects
      interval: 10s
      timeout: 5s
      retries: 5

  knep:
    image: kong/kong-native-event-proxy-dev:main
    container_name: knep
    depends_on:
      - broker
    ports:
      - "9192-9292:9192-9292"
      - "8080:8080"
    env_file: "knep.env"
    environment:
      KNEP__RUNTIME__DRAIN_DURATION: 1s # makes shutdown quicker, not recommended to be set like this in production 
    healthcheck:
      test: curl -f http://localhost:8080/health/probes/liveness
      interval: 10s
      timeout: 5s
      retries: 5

  kafka-ui:
    image: provectuslabs/kafka-ui:latest
    container_name: kafka-ui
    environment:
      # First cluster configuration (direct Kafka connection)
      KAFKA_CLUSTERS_0_NAME: "direct-kafka-cluster"
      KAFKA_CLUSTERS_0_BOOTSTRAPSERVERS: "broker:9092"
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
- `knep:9192` to `know:9292` for access to the {{site.event_gateway_short}} proxy (the port range is wide to allow many virtual clusters to be created)
- `knep:8080` for probes and metrics access to {{site.event_gateway_short}}

The {{site.event_gateway_short}} container will use environment variables from `knep.env` file. Let's create it:
```shell
cat <<EOF > knep.env
KONNECT_API_TOKEN=\${KONNECT_TOKEN}
KONNECT_API_HOSTNAME=us.api.konghq.com
KONNECT_CONTROL_PLANE_ID=\${KONNECT_CONTROL_PLANE_ID}
EOF
```

Now let's start the local setup:
```shell
docker compose up -d
```
