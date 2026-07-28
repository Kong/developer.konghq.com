---
title: Why the `wait-for-db` container doesn't terminate in Kubernetes
content_type: support
published: false
description: Explains why a `wait-for-db` container hangs in Kubernetes: the `nginx_daemon` setting must be `on` so Kong runs in the background and the container can exit once the database is available.
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: Why does my `wait-for-db` container refuse to terminate in k8s?
  a: |
    A `wait-for-db` init container relies on Kong running in the background briefly, then exiting once the database is reachable. If `nginx_daemon` is set to `off` in the deployment, Kong runs in the foreground indefinitely and the container never exits; set `nginx_daemon` to `on` so Kong daemonizes and the container can terminate once the database is available.
related_resources: []
---

## Why does my `wait-for-db` container refuse to terminate in k8s

Why does my `wait-for-db` container refuse to terminate in k8s?

Check your `nginx_daemon` setting in your deployment YAML.

When set to `on`, this will daemonize the Kong instance running, into the background.

When set to `off`, Kong will run in the foreground.

The implications for the `wait-for-db` container are that if it is set to `off`, then the `wait-for-db` container will never quit once the DB becomes available and halt your deployment.

The correct setting of `on` will allow Kong to run in the background until the DB is available, then it will terminate itself and the deployment will continue.
