---
title: Logging to JSON format for Kubernetes
content_type: support
description: 'The Kong Ingress Controller supports a `--log-format` flag to switch its logs from plain text to JSON, which can be set via `ingressController.args` in the Helm chart.'
products:
  - kic
works_on:
  - on-prem
  - konnect
tldr:
  q: How do I configure the Kong Ingress Controller to log in JSON format?
  a: |
    Set the Ingress Controller's `--log-format` flag to `json` (the default is `text`). With the Helm chart, pass it via `--set ingressController.args[0]='--log-format=json'`, or add it under `ingressController.args` in your `values.yaml`.
related_resources:
  - text: the `--log-format` option
    url: https://github.com/Kong/kubernetes-ingress-controller/blob/main/internal/cmd/rootcmd/config/cli.go#L55
  - text: the `ingressController.args` field in the Kong Helm chart values.yaml
    url: https://github.com/Kong/charts/blob/main/charts/kong/values.yaml#L588
---

## Problem

By default Kong on containerized environments logs in plain text to `STDOUT`/`STDERR`. I would like this to log in a JSON format, how is this possible?

## Solution

The current Kong Kubernetes Ingress Controller (KIC) has the `--log-format` option.

This defaults to text and can be configured to JSON. With the helm chart specifically, this can be added to the arguments for the ingress controller.

Essentially something like `--set ingressController.args[0]='--log-format=json'` for the helm chart deployment, or adding it to the `ingressController.args` of their `values.yaml` file for their installation if they do it that way.

Example:

```bash
helm install ingress-controller kong/kong --create-namespace --namespace kong-system --set ingressController.args[0]='--log-format=json'
```

Default logging format:

```
time="2025-02-22T17:21:15Z" level=info msg="syncing configuration" component=controller
time="2025-02-22T17:21:15Z" level=info msg="no configuration change, skipping sync to kong" component=controller
```

New logging format:

```json
{"component":"controller","level":"info","msg":"syncing configuration","time":"2025-02-22T17:21:15Z"}
{"component":"controller","level":"info","msg":"no configuration change, skipping sync to kong","time":"2025-02-22T17:21:15Z"}
```
