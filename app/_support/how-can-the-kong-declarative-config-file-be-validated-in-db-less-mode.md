---
title: Validating the Kong declarative config file in db-less mode
content_type: support
description: The Kong binary can be used to validate a config for problems prior to loading using the `config parse` command.
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: How can the Kong declarative config file be validated in db-less mode?
  a: |
    Run `kong config parse <file>.yaml` to validate a declarative config before loading it — Kong reports the exact location of any schema violation (for example, an invalid `protocols` value). You can also run this externally, without a running Kong node, using the `kong/kong-gateway` Docker image against a mounted config directory.
related_resources:
  - text: Kong CLI reference
    url: /gateway/cli/reference/
---

## Overview

The Kong binary can be used to validate a config for problems prior to loading, using the `config parse` command.

## Steps

```bash
kong config parse <declarative-config.yaml>
```

For example, in the below configuration (`kong.yaml`) we specify an invalid route protocol `gruber`:

```yaml
_format_version: "1.1"
services:
- connect_timeout: 60000
  host: localhost
  name: httpbin
  path: /anything
  routes:
  - name: httpbin-route
    paths:
    - /echo
    protocols:
    - gruber
    - http
```

When running `kong config parse` we can see where the error resides:

```bash
kong config parse kong.yaml

Error: Failed parsing:
in 'services':
 - in entry 1 of 'services':
   in 'routes':
     - in entry 1 of 'routes':
       in 'protocols':
         - in entry 1 of 'protocols': expected one of: grpc, grpcs, http, https, tcp, tls, tls_passthrough, udp
```

This can optionally be performed external to the Kong system using the Docker image, where the config file for validation exists in the current directory.

```bash
docker run --rm -v ${PWD}:/config -e "KONG_DATABASE=off" --rm kong/kong-gateway:3.14.0.0 kong config parse /config/kong.yaml
```
