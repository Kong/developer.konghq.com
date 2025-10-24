Start a Docker Compose cluster with multiple Kafka services.

First, we need to create a `docker-compose.yaml` file. This file will define the services we want to run in our local environment:

```shell
cat <<EOF > docker-compose.yaml
{% include _files/event-gateway/docker-compose.yaml %}
EOF
```

Now, let's start the local setup:
```shell
docker compose up -d
```
