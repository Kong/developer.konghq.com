---
title: How to use the `decK` docker container
content_type: support
description: Use the `decK` Docker container to dump, sync, reset, and validate Kong declarative configuration against a running Kong Admin API.
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources: []
tldr:
  q: How do I use the `decK` Docker container to manage Kong configuration?
  a: |
    Run the official `kong/deck` Docker image with `docker run`, mounting a local directory as a volume and pointing `--kong-addr` at your Kong Admin API. From there you can use `dump`, `sync`, `reset`, and `validate` the same as a locally installed `decK` binary.
---

## Overview

How to use the `decK` docker container.

## Steps

Assuming Kong is running locally and using the default port, the examples below use `http://host.docker.internal:8001` as the endpoint of the Kong Admin API for the `decK` container. Replace this value with your actual Kong Admin API URL.

1. Pull the image:

   ```bash
   docker pull kong/deck
   ```

2. Check available commands:

   ```bash
   docker run kong/deck --help
   ```

3. Run `--help` with each command to check available flags:

   ```bash
   docker run kong/deck dump --help
   docker run kong/deck sync --help
   docker run kong/deck reset --help
   ...
   ```

4. Run `deck dump` to export `kong.yaml`. The file is generated in `$(pwd)/kong.yaml`:

   ```bash
   docker run -i \
   -v $(pwd):/deck \
   kong/deck --kong-addr http://host.docker.internal:8001 --headers kong-admin-token:<admin-token> -o /deck/kong.yaml dump
   ```

5. Run `deck dump` to export declarative configuration files for all workspaces. The files are generated in `$(pwd)/`.

   Note: if you run more than one `dump` into the same directory, `decK` will similarly prompt to confirm overwriting existing files, which fails the same way under `docker run -i` without a TTY (`Error: EOF`). Unlike `reset`, `dump` has no `-f`/`--force` flag at all (passing one fails with `Error: unknown shorthand flag: 'f' in -f`) - remove or rename the existing output file(s) before re-running `dump` instead.

   ```bash
   docker run -i \
   -v $(pwd):/deck \
   --workdir /deck \
   kong/deck --kong-addr http://host.docker.internal:8001 --headers kong-admin-token:<admin-token> dump --all-workspaces
   ```

6. Run `deck reset` to reset the Kong objects to their initial state.

   Note: `reset` prompts for an interactive confirmation, which cannot be answered when running under `docker run -i` without a TTY (it fails with `Error: EOF`). Pass `-f`/`--force` to skip the prompt.

   ```bash
   docker run -i \
   -v $(pwd):/deck \
   kong/deck --kong-addr http://host.docker.internal:8001 --headers kong-admin-token:<admin-token> reset -f
   ```

7. Run `deck sync` to import `kong.yaml`. This example assumes `kong.yaml` is in `$(pwd)/kong.yaml`:

   ```bash
   docker run -i \
   -v $(pwd):/deck \
   kong/deck --kong-addr http://host.docker.internal:8001 --headers kong-admin-token:<admin-token> -s /deck/kong.yaml sync
   ```

8. Run `deck validate` to validate `kong.yaml`. This example assumes `kong.yaml` is in `$(pwd)/kong.yaml`:

   ```bash
   docker run -i \
   -v $(pwd):/deck \
   kong/deck --kong-addr http://host.docker.internal:8001 --headers kong-admin-token:<admin-token> validate --online -s /deck/kong.yaml
   ```
