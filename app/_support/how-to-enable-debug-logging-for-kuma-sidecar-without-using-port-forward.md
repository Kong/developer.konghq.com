---
title: How to enable debug logging for kuma sidecar without using port-forward
content_type: support
description: Steps to enable debug logging on the kuma sidecar by logging in to the container and sending an HTTP POST request to its admin API with the `wget` command.
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources: []
tldr:
  q: How do I enable debug logging for the kuma sidecar without using `kubectl port-forward`?
  a: |
    Use `kubectl exec` to open a shell in the kuma sidecar container, then send an HTTP POST request to its local admin API with `wget` to set the log level to `debug`. The same approach can set the log level back to `info` afterward.
---

## Overview

We do not have permission to use port-forward, how could we enable debug logging for kuma sidecar? (The default log level of kuma sidecar is info.)

## Steps

You have to log in to the kuma sidecar and send an HTTP POST request with the `wget` command.

1. Log in to the kuma sidecar.

   ```bash
   kubectl exec -it <pod-name> -c kuma-sidecar -n <namespace> -- sh
   ```

2. Enable debug logging with the following `wget` command.

   ```bash
   wget http://localhost:9901/logging?level=debug --post-data='' -O /tmp/res
   ```

3. Exit the kuma sidecar container and confirm the log level.

   ```bash
   kubectl logs -f <pod-name> -c kuma-sidecar -n <namespace>
   ```

For the case you want to set the log level back to info, please log in to the kuma sidecar and run the following `wget` command.

```bash
wget http://localhost:9901/logging?level=info --post-data='' -O /tmp/res
```
