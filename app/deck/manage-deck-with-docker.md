---
title: Manage decK with Docker

description: If you used the [kong/deck](https://hub.docker.com/r/kong/deck) Docker image to install decK, you can use the same Docker image to manage decK.  

content_type: reference
layout: reference

tools:
   - deck

works_on:
    - on-prem
    - konnect

tags:
  - docker

products:
  - api-ops

breadcrumbs:
  - /deck/
---

{{ page.description | liquify }}

Adjust `KONG_ADMIN_HOST` and the port `8001` in the following examples to the 
host and port of your own {{site.base_gateway}} instance.

## Export the configuration
Run this command to export the `kong.yaml` file:

```bash
docker run -i \
    -v $(pwd):/deck \
    kong/deck \
    --kong-addr http://KONG_ADMIN_HOST:8001 \
    --headers kong-admin-token:KONG_ADMIN_TOKEN \
    -o /deck/kong.yaml gateway dump
```
Where `$(pwd)/kong.yaml` is the path to a `kong.yaml` file.

## Export objects from all workspaces
Run this command to export objects from all the workspaces:

```bash
docker run -i \
    -v $(pwd):/deck \
    --workdir /deck \
    kong/deck \
    --kong-addr http://KONG_ADMIN_HOST:8001 \
    --headers kong-admin-token:KONG_ADMIN_TOKEN \
    -o /deck/kong.yaml gateway dump \
    --all-workspaces
```

## Reset the configuration
Run this command to initialize Kong objects:

```bash
docker run -i \
    -v $(pwd):/deck \
    kong/deck \
    --kong-addr http://KONG_ADMIN_HOST:8001 \
    --headers kong-admin-token:KONG_ADMIN_TOKEN \
    gateway reset
```

## Import the configuration
Run this command to import `kong.yaml`:

```bash
docker run -i \
-v $(pwd):/deck \
kong/deck \
    --kong-addr http://KONG_ADMIN_HOST:8001 \
    --headers kong-admin-token:KONG_ADMIN_TOKEN \
    gateway sync /deck/kong.yaml
```
In this example, `kong.yaml` is in `$(pwd)/kong.yaml`.

## View help manual pages
Run this command to view all available commands:

```bash
docker run kong/deck --help
```

Run the following to check available command flags:

```bash
docker run kong/deck gateway dump --help
docker run kong/deck gateway sync --help
docker run kong/deck gateway reset --help
```
