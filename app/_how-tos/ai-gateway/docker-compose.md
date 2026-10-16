---
title: Install {{site.ai_gateway}} 2.x on-prem using Docker Compose
content_type: how_to
permalink: /ai-gateway/install/docker/
description: Use Docker Compose to install {{site.ai_gateway}} 2.x on self-managed {{site.base_gateway}}
products:
  - ai-gateway

works_on:
  - on-prem

min_version:
  ai-gateway: '2.2'

tldr:
  q: How do I install {{site.ai_gateway}} 2.x on-prem using Docker Compose?
  a: "Create the example Docker Compose file and run `docker compose up -d`."

prereqs:
  skip_product: true
  inline:
    - title: Docker Compose
      content: |
        This guide requires [Docker](https://docs.docker.com/get-started/get-docker/) installed on your system.

cleanup:
  inline:
    - title: Destroy the {{site.ai_gateway}} containers
      include_content: cleanup/products/docker
      icon_url: /assets/icons/ai-gateway.svg

related_resources:
  - text: Configure {{site.ai_gateway}} on-prem
    url: /ai-gateway/configure-on-prem/
  - text: Install {{site.base_gateway}} using Docker Compose
    url: /gateway/install/docker/

automated_tests: false
---

## Set up the Docker Compose file

Run the following command to create `docker-compose.yml`:

<!-- vale off -->
```bash
cat <<EOF > docker-compose.yml

networks:
  kong:
    name: kong
    driver: bridge

# Image used by every Kong service in this file
x-kong-image: &kong-image
  image: kong/kong-ai-gateway:{{ site.data.ai_gateway_latest.version }}

# Common environment variables used by Kong services (migrations and gateway)
x-kong-db-config: &kong-db-config
  KONG_DATABASE: postgres             # Use Postgres as the backing database
  KONG_PG_HOST: db                    # Hostname of the Postgres service
  KONG_PG_DATABASE: kong              # Name of the database to connect to
  KONG_PG_USER: kong                  # Database username
  KONG_PG_PASSWORD: kong              # Database password
  KONG_PASSWORD: password             # Admin GUI password (required for RBAC)
  KONG_LICENSE_DATA: "\${KONG_LICENSE_DATA}"  # Kong Enterprise license passed via environment variable

x-kong-container-common: &kong-container-common
  healthcheck:
    test: [ "CMD", "kong", "health" ]
    interval: 3s
    timeout: 3s
    retries: 10
    start_period: 3s
  restart: on-failure
  tmpfs:
    - /tmp

services:

  db:
    image: postgres:13
    networks:
      - kong
    environment:
      POSTGRES_DB: kong
      POSTGRES_USER: kong
      POSTGRES_PASSWORD: kong
    healthcheck:                      # Ensure the DB is ready before starting dependent services
      test: [ "CMD", "pg_isready", "-U", "kong" ]
      interval: 5s
      timeout: 5s
      retries: 10
    restart: on-failure

  kong-migrations:
    <<: *kong-image
    networks:
      - kong
    command: "kong migrations bootstrap"
    depends_on:
      db:
        condition: service_healthy    # Wait until Postgres is up and healthy
    environment:
      <<: *kong-db-config

  kong-gateway:
    <<: [ *kong-container-common, *kong-image ]
    deploy:
      replicas: 1
    mem_limit: 2g
    cpus: 4
    networks:
      - kong
    user: "\${KONG_USER:-kong}"
    ports:
      - 8000:8000   # Proxy HTTP
      - 8443:8443   # Proxy HTTPS
      - 8001:8001   # Admin API
      - 8002:8002   # Kong Manager (Admin GUI)
      - 8003:8003   # Dev Portal GUI
      - 8004:8004   # Dev Portal API
    depends_on:
      db:
        condition: service_healthy
      kong-migrations:
        condition: service_completed_successfully  # Start only after bootstrap has succeeded
    environment:
      <<: *kong-db-config
      KONG_ANONYMOUS_REPORTS: "off"
      KONG_PROXY_LISTEN: "0.0.0.0:8000,0.0.0.0:8443 ssl"
      KONG_ADMIN_LISTEN: "0.0.0.0:8001"
      KONG_ADMIN_GUI_LISTEN: "0.0.0.0:8002"
      KONG_PORTAL_GUI_LISTEN: "0.0.0.0:8003"
      KONG_PORTAL_API_LISTEN: "0.0.0.0:8004"
      KONG_LOG_LEVEL: "debug"
      KONG_PLUGINS: "bundled"
EOF
```
<!-- vale on -->

## Start {{site.ai_gateway}}

Set your Enterprise license in the `KONG_LICENSE_DATA` environment variable, then start the containers:

```sh
export KONG_LICENSE_DATA='<your_license_data>'
docker compose up -d
```

## Validate

You can validate {{site.ai_gateway}} is running using cURL against the Admin API:

{% control_plane_request %}
url: ''
method: GET
status_code: 200
{% endcontrol_plane_request %}

This will return an `HTTP/1.1 200 OK` response.
