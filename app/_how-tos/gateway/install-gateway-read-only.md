---
title: Install {{site.base_gateway}} in read-only mode using Docker Compose
description: Use Docker Compose to install {{site.base_gateway}} in read-only mode
content_type: how_to
breadcrumbs:
  - /gateway/
  - /gateway/install/
permalink: /gateway/install/docker-read-only/
related_resources:
  - text: Install {{site.base_gateway}} on a supported platform
    url: /gateway/install/
  - text: Build a custom Docker image
    url: /how-to/build-custom-docker-image/
  - text: Install {{site.base_gateway}} using Docker Compose
    url: /gateway/install/docker/
products:
  - gateway

works_on:
  - on-prem
min_version:
  gateway: '3.2'

tldr:
  q: How do I install and {{site.base_gateway}} in Docker's read-only mode?
  a: | 
    Run a {{site.base_gateway}} Docker container in DB-less mode using the provided Docker Compose file with `read_only` set to `true`.
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
next_steps:
  - text: Learn about DB-less mode
    url: /gateway/db-less-mode/

automated_tests: false

tags:
  - install
---

## Create a `kong.yml` configuration file

For read-only mode, you need to run {{site.base_gateway}} as a DB-less deployment - that is, without a database.
This means that you can't use the Admin API or decK to configure the Gateway instance. 
Instead, you have to pass a declarative configuration file to {{site.base_gateway}} while starting the instance.

Create a directory for your Kong configuration:

```sh
mkdir declarative
```

Then, create a `kong.yml` file with your entire Gateway configuration. For example, the following file creates a Service and a Route:

```yaml
cat <<EOF > ./declarative/kong.yml
_format_version: "3.0"
services:
- name: example-service
  url: http://httpbin.org
  routes:
  - name: example-route
    paths:
    - /anything
EOF
```

## Set up the Docker Compose file for read-only mode

Now we need to configure our {{site.base_gateway}} Docker Compose stack.

In this configuration file, we're going to mount a Docker volume to the locations where {{site.base_gateway}} needs to write data, which includes the `/declarative` directory.
This default configuration requires write access to `/tmp` and to the prefix path.

Run the following command to create a Docker Compose file at `docker-compose.yml` with `read_only` set to `true`:

<!-- vale off -->
```bash
cat <<EOF > docker-compose.yml

services:
  kong-dbless:
    image: '${GW_IMAGE:-kong/kong-gateway:{{ site.data.gateway_latest.ee-version }}}' # Kong Gateway image (default to latest version)
    container_name: kong-dbless-readonly
    read_only: true
    restart: unless-stopped
    networks:
      - kong-net
    volumes:
      - ./declarative:/kong/declarative/
      - ./tmp_volume:/tmp
      - ./prefix_volume:/var/run/kong
    environment:
      KONG_PREFIX: /var/run/kong
      KONG_DATABASE: off
      KONG_DECLARATIVE_CONFIG: /kong/declarative/kong.yml
      KONG_PROXY_ACCESS_LOG: /dev/stdout
      KONG_ADMIN_ACCESS_LOG: /dev/stdout
      KONG_PROXY_ERROR_LOG: /dev/stderr
      KONG_ADMIN_ERROR_LOG: /dev/stderr
      KONG_ADMIN_LISTEN: 0.0.0.0:8001
      KONG_ADMIN_GUI_URL: http://localhost:8002
      KONG_LICENSE_DATA: "\${KONG_LICENSE_DATA}" # Kong Enterprise license passed via environment variable
    ports:
      - "8000:8000"
      - "8443:8443"
      - "8001:8001"
      - "8444:8444"
      - "8002:8002"
      - "8445:8445"
      - "8003:8003"
      - "8004:8004"

networks:
  kong-net:
    external: true
EOF
```
<!-- vale on -->

This Docker Compose file will create a read-only {{site.base_gateway}} instance without a datastore.

## Start {{site.base_gateway}}

Start {{site.base_gateway}} with the Docker Compose file: 

```sh
docker compose up -d
```

## Validate

Let's make sure that {{site.base_gateway}} is running in read-only mode by checking that we can't write to the API.

First, check that {{site.base_gateway}} is running:

<!--vale off-->
{% control_plane_request %}
url: '/services'
method: GET
status_code: 200
{% endcontrol_plane_request %}
<!--vale on-->

This will return an `HTTP/1.1 200 OK` response with the `example-service` Service configured through `kong.yml`.

Now, try writing to the Kong Admin API:

<!--vale off-->
{% control_plane_request %}
url: /consumers
method: POST
headers:
  - 'Accept: application/json'
body:
  username: consumer
{% endcontrol_plane_request %}
<!--vale on-->

This time, you'll get a `405 Not Allowed` response, with the following message:
```
{"code":12,"message":"cannot create 'consumers' entities when not using a database","name":"operation unsupported"}%
```
{:.no-copy-code}
