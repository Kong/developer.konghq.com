---
title: Install {{site.base_gateway}} using Docker Compose
description: Use Docker Compose to install {{site.base_gateway}}
content_type: how_to
breadcrumbs:
  - /gateway/
  - /gateway/install/
permalink: /gateway/install/docker/
related_resources:
  - text: Install {{site.base_gateway}} on a supported platform
    url: /gateway/install/
  - text: Build a custom Docker image
    url: /how-to/build-custom-docker-image/
  - text: Install {{site.base_gateway}} in read-only mode
    url: /gateway/install/docker-read-only/
products:
  - gateway

works_on:
  - on-prem
min_version:
  gateway: '3.4'

tldr:
  q: How do I install {{site.base_gateway}} using Docker Compose?
  a: "Copy the Docker Compose file and run `docker compose up -d`."
prereqs:
  skip_product: true
  inline: 
    - title: Docker Compose 
      content: |
        This guide requires [Docker](https://docs.docker.com/get-started/get-docker/) installed on your system.
        
cleanup:
  inline:
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/docker
      icon_url: /assets/icons/gateway.svg

faqs:
  - q: Can I run {{site.base_gateway}} in read-only mode?
    a: |
      Yes, you can run a {{site.base_gateway}} Docker container in read-only mode by setting `database` to `off` and passing a configuration file when starting the container.
      See [Running {{site.base_gateway}} in read-only mode using Docker Compose](/gateway/install/docker-read-only/) for more information.

automated_tests: false
---

## Set up the Docker Compose file

Copy the Docker Compose file to `docker-compose.yml`:

<!-- vale off -->
```bash
cat <<EOF > docker-compose.yml

volumes:
  kong_db_data: {}  # Named volume to persist Postgres data across container restarts

networks:
  kong-ee-net:      # Custom bridge network for isolated Kong and Postgres communication
    driver: bridge

# Common environment variables used by Kong services (bootstrap and CP)
x-kong-config: &kong-env
  KONG_DATABASE: postgres             # Use Postgres as the backing database
  KONG_PG_HOST: kong-ee-database      # Hostname of the Postgres service
  KONG_PG_DATABASE: kong              # Name of the database to connect to
  KONG_PG_USER: kong                  # Database username
  KONG_PG_PASSWORD: kong              # Database password
  KONG_LICENSE_DATA: "\${KONG_LICENSE_DATA}"  # Kong Enterprise license passed via environment variable

services:

  kong-ee-database:
    container_name: kong-ee-database
    image: postgres:latest           # Official Postgres image
    restart: on-failure              # Restart if the container fails
    volumes:
      - kong_db_data:/var/lib/postgresql  # Mount the volume for persistent data
    networks:
      - kong-ee-net                  # Connect to the shared Kong network
    environment:
      POSTGRES_USER: kong            # Set DB user inside the container
      POSTGRES_DB: kong              # Create this database on first run
      POSTGRES_PASSWORD: kong        # Set the password for the DB user
    healthcheck:                     # Ensure the DB is ready before starting dependent services
      test: ["CMD", "pg_isready", "-U", "kong"]
      interval: 5s
      timeout: 10s
      retries: 10
    ports:
      - '5432:5432'                  # Optional: expose Postgres on localhost for debugging

  kong-bootstrap:
    image: '${GW_IMAGE:-kong/kong-gateway:{{ site.data.gateway_latest.ee-version }}}'  # Kong Gateway image (default to latest version)
    container_name: kong-bootstrap
    networks:
      - kong-ee-net
    depends_on:
      kong-ee-database:
        condition: service_healthy   # Wait until Postgres is up and healthy
    restart: on-failure
    environment:
      <<: *kong-env                 # Reuse environment config from x-kong-config
      KONG_PASSWORD: handyshake    # Admin GUI password (required for RBAC)
    command: kong migrations bootstrap  # Run DB migrations to initialize Kong schema

  kong-cp:
    image: '${GW_IMAGE:-kong/kong-gateway:{{ site.data.gateway_latest.ee-version }}}'  # Main Kong Gateway Control Plane (default to latest version)
    container_name: kong-cp
    restart: on-failure
    networks:
      - kong-ee-net
    environment:
      <<: *kong-env
      KONG_ADMIN_LISTEN: 0.0.0.0:8001, 0.0.0.0:8444 ssl  # Admin API on HTTP + HTTPS
      KONG_ADMIN_GUI_LISTEN: 0.0.0.0:8002, 0.0.0.0:8445 ssl  # Kong Manager on HTTP + HTTPS
      KONG_ADMIN_GUI_URL: http://${GW_HOST:-localhost}:8002  # URL for GUI links
      KONG_PASSWORD: handyshake  # Required for logging in to Kong Manager (RBAC)
    depends_on:
      kong-bootstrap:
        condition: service_completed_successfully  # Start only after bootstrap has succeeded
    ports:
      - "8000:8000"  # Proxy HTTP
      - "8443:8443"  # Proxy HTTPS
      - "8001:8001"  # Admin API HTTP
      - "8444:8444"  # Admin API HTTPS
      - "8002:8002"  # Kong Manager HTTP
      - "8445:8445"  # Kong Manager HTTPS
EOF
```
<!-- vale on -->

## Start {{site.base_gateway}}

Start {{site.base_gateway}} with the Docker Compose file: 

```sh
docker compose up -d
```

## Validate

You can validate {{site.base_gateway}} is running using cURL against the {{site.base_gateway}} Admin API:

{% control_plane_request %}
url: ''
method: GET
status_code: 200
{% endcontrol_plane_request %}

This will return an `HTTP/1.1 200 OK` response.
