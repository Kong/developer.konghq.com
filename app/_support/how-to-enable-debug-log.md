---
title: How to enable debug log
content_type: support
description: "There are multiple ways to change Kong's log level depending on your deployment method: config file, environment variable, Kubernetes, Helm, or dynamically without a restart."
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: How do I enable debug logging in Kong Gateway?
  a: |
    Set `log_level = debug` in `kong.conf`, or set the `KONG_LOG_LEVEL=debug` environment variable (for Docker, Kubernetes, or Helm deployments), then reload or restart Kong. Kong Gateway also supports Dynamic Log Levels, which let you raise or lower the log level without restarting Kong, except in DB-less mode where the Admin API isn't available.
related_resources:
  - text: Kong Gateway log level configuration documentation
    url: /gateway/logs/#configure-log-levels
---

## Overview

How do we enable debug log on different platforms?

## Steps

VM:

There are two ways of changing the log level.

1. On the `/etc/kong/kong.conf` file, change `log_level=debug`

2. Adding the environment variable `KONG_LOG_LEVEL=debug` will override the setting on the config file.

Docker:

Normally we use environment variables to configure Kong containers. Please add `KONG_LOG_LEVEL=debug` to your docker run command or docker compose file under `environment`.

Kubernetes:

You can modify the deployment and add the below to the Kong container

```yaml
        - name: KONG_LOG_LEVEL
          value: debug
```

If you deploy with Helm, you can add `log_level` under `env` as below

```yaml
env:
  log_level: debug
```

Once the changes are made, please remember to reload/restart Kong. For Kubernetes, please remember to apply the deployment file or upgrade your Helm release to bring up a new pod with this configuration.

Dynamically:

Kong Gateway supports Dynamic Log Levels to allow log levels to be increased and decreased without the need to restart Kong.

Caveat: Cannot work in DBLess mode as there is no admin-api available.

For more details, please review the documentation.
