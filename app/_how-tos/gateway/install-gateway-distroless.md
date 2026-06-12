---
title: Install {{site.base_gateway}} using the distroless image
description: Run {{site.base_gateway}} from the distroless Docker image, which contains only the {{site.base_gateway}} runtime and its dependencies with no shell or package manager.
content_type: how_to
breadcrumbs:
  - /gateway/
  - /gateway/install/
permalink: /gateway/install/docker-distroless/
related_resources:
  - text: Install {{site.base_gateway}} on a supported platform
    url: /gateway/install/
  - text: Install {{site.base_gateway}} using Docker Compose
    url: /gateway/install/docker/
  - text: Install {{site.base_gateway}} in read-only mode
    url: /gateway/install/docker-read-only/
  - text: Build your own custom Docker image
    url: /how-to/build-custom-docker-image/

products:
  - gateway

works_on:
  - on-prem
min_version:
  gateway: '3.15'

tldr:
  q: How do I run {{site.base_gateway}} using the distroless image?
  a: |
    Pull `kong/kong-gateway:{{site.data.gateway_latest.ee-version}}-distroless` and run it with configuration passed via environment variables.
    The distroless image has no shell, so you must configure Gateway at container startup.

prereqs:
  skip_product: true
  inline:
    - title: Docker
      content: |
        This guide requires [Docker](https://docs.docker.com/get-started/get-docker/) installed on your system.
    - title: Kong license
      content: |
        Set your {{site.base_gateway}} license as an environment variable:
        ```sh
        export KONG_LICENSE_DATA='<your-license-json>'
        ```

faqs:
  - q: Why use the distroless image?
    a: |
      The distroless image contains only the {{site.base_gateway}} runtime and its dependencies.
      It has no shell, package manager, or OS tooling, which reduces the image's attack surface and can simplify security scanning.
  - q: Can I get a shell inside the distroless container?
    a: |
      No. The distroless image has no shell.
      Use environment variables or mounted config files to configure {{site.base_gateway}} instead of running commands inside the container.
  - q: Is there a FIPS-compliant distroless image?
    a: |
      Yes. Pull `kong/kong-gateway:{{site.data.gateway_latest.ee-version}}-distroless-fips` and set `KONG_FIPS=on`.
      See [FIPS support](/gateway/fips-support/) for additional configuration requirements.

  - q: Can I run the distroless image with a database?
    a: |
      Yes. The distroless image supports the same deployment modes as other {{site.base_gateway}} images.
      This guide uses DB-less mode, which requires no separate database container.

      If you need a database-backed deployment, start a Postgres container first and run `kong migrations bootstrap` before starting the Gateway.
      See [Install {{site.base_gateway}} using Docker Compose](/gateway/install/docker/) for a database-backed example.

tags:
  - install
  - docker

automated_tests: false
---

## Pull the distroless image

Pull the {{site.base_gateway}} distroless image from Docker Hub:

```sh
docker pull kong/kong-gateway:{{ site.data.gateway_latest.ee-version }}-distroless
```

The distroless image is available for `linux/amd64` and `linux/arm64`.
Docker pulls the correct variant automatically based on your host architecture.

## Create a Docker network

Create a dedicated network for {{site.base_gateway}}:

```sh
docker network create kong-net
```

## Create a declarative configuration file

In DB-less mode, you provide your Gateway configuration in a YAML file at startup.


Create a directory for your Kong configuration:

```sh
mkdir -p declarative
```

Then, create a `kong.yml` file with your entire Gateway configuration. For example, the following file creates a Service and a Route:

```sh
cat <<EOF > declarative/kong.yml
_format_version: "3.0"
services:
- name: example-service
  url: http://httpbin.konghq.com
  routes:
  - name: example-route
    paths:
    - /anything
EOF
```

## Start {{site.base_gateway}}

Run the distroless container, mounting the declarative configuration file and passing all settings via environment variables:

```sh
docker run -d \
  --name kong-distroless \
  --network kong-net \
  -v "$(pwd)/declarative:/kong/declarative" \
  -e KONG_DATABASE=off \
  -e KONG_DECLARATIVE_CONFIG=/kong/declarative/kong.yml \
  -e KONG_PROXY_ACCESS_LOG=/dev/stdout \
  -e KONG_PROXY_ERROR_LOG=/dev/stderr \
  -e KONG_ADMIN_ACCESS_LOG=/dev/stdout \
  -e KONG_ADMIN_ERROR_LOG=/dev/stderr \
  -e KONG_ADMIN_LISTEN="0.0.0.0:8001" \
  -e KONG_LICENSE_DATA="$KONG_LICENSE_DATA" \
  -p 8000:8000 \
  -p 8001:8001 \
  kong/kong-gateway:{{ site.data.gateway_latest.ee-version }}-distroless
```

{:.info}
> Because the distroless image has no shell, all {{site.base_gateway}} configuration must be passed as environment variables (`KONG_*`) or in a mounted `kong.conf` file.
> You **cannot** run `kong` commands inside the container after it starts.

## Validate

Check that {{site.base_gateway}} is running by accessing the `example-route` Route:

{% control_plane_request %}
url: '/anything'
method: GET
status_code: 200
{% endcontrol_plane_request %}

This should return an `HTTP/1.1 200 OK` response.