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

Set your Enterprise license in the `KONG_LICENSE_DATA` environment variable:

```sh
export KONG_LICENSE_DATA='YOUR LICENSE DATA'
```

Then, start the containers:
```sh
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

## Configure your on-prem {{site.ai_gateway}} 2.x

For {{site.ai_gateway}} 2.x running on-prem, you'll use {{site.ai_gateway}} 2.x decK configuration files and `deck ai sync` to apply them.
`deck ai sync` converts the {{site.ai_gateway}} 2.x AI entities and policies into compatible {{site.base_gateway}} 3.x configuration with plugins, Services, and Routes.

You can convert any `kongctl` {{site.ai_gateway}} 2.x configuration to decK by removing the fields that only apply to a {{site.konnect_short_name}}-managed control plane:

* Drop each entity's `ref` field.
* Drop each entity's `ai_gateway: !lookup {id: ...}` field. On-prem, there's only one {{site.ai_gateway}}, so entities don't need to reference one by ID.
* Rename the top-level entity collections from their `kongctl` names (`ai_gateway_model_providers`, `ai_gateway_models`, and so on) to their decK names (`model_providers`, `models`). See [Configure {{site.ai_gateway}} on-prem](/ai-gateway/configure-on-prem/) for the full set of entity names decK expects.

See [{{site.ai_gateway}} 2.x concepts](/ai-gateway/ai-gateway-v2-concepts/) for how the entity model maps to the underlying {{site.base_gateway}} primitives.

For example, here's the [AI Model Provider and AI Model from the {{site.ai_gateway}} get started guide](/ai-gateway/get-started/) written as a decK configuration file instead of a `kongctl` one. Set the `DECK_OPENAI_API_KEY` environment variable to your OpenAI API key, then apply the file with `deck ai sync`:

```sh
export DECK_OPENAI_API_KEY='Bearer YOUR OPENAI API KEY'
```

{:.info}
> This example substitutes `$DECK_OPENAI_API_KEY` directly into the YAML using the shell, instead of decK's own `{% raw %}${{ env "..." }}{% endraw %}` templating. That templating is the documented way to avoid hardcoding secrets (see [Managing sensitive data](/deck/gateway/sensitive-data/)), but it doesn't resolve when a {{site.ai_gateway}} 2.x entity file is applied with `deck ai sync`/`deck file ai2kong`: the literal, unresolved string ends up in the generated plugin config instead of the real key.

<!-- vale off -->
```sh
cat <<EOF | deck ai sync --yes -
model_providers:
  - name: generic-openai
    display_name: "generic-openai"
    type: openai
    config:
      auth:
        type: basic
        headers:
          - name: Authorization
            value: $DECK_OPENAI_API_KEY

models:
  - name: my-gpt-4o
    display_name: "my-gpt-4o"
    type: model
    capabilities:
      - generate
    formats:
      - type: openai
    policies: []
    config:
      route:
        paths:
          - /v1
        protocols:
          - http
          - https
        model:
          body_param: model
          values:
            - my-gpt-4o
    targets:
      - name: gpt-4o
        provider: generic-openai
        config:
          type: openai
EOF
```
<!-- vale on -->

{:.info}
> This example omits `--kong-addr`, since it defaults to `http://localhost:8001`, which is already where this Docker Compose file exposes the Admin API. If your {{site.ai_gateway}} isn't reachable at that address, or needs authentication, see [Configuring on-prem authentication](/deck/gateway/configuration/).

### Validate your configuration

Send a chat request to verify your setup:

```sh
curl -X POST "http://localhost:8000/v1/chat/completions" \
     --no-progress-meter --fail-with-body \
     -H "Accept: application/json" \
     -H "Content-Type: application/json" \
     -H "Authorization: $DECK_OPENAI_API_KEY" \
     --json '{
       "messages": [
         {
           "role": "user",
           "content": "Say this is a test!"
         }
       ],
       "model": "my-gpt-4o"
     }'
```
