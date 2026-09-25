---
title: How to configure Request Transformer Advanced plugin for replace URI on Kubernetes
content_type: support
description: "How to configure the Request Transformer Advanced plugin's `config.replace.uri` parameter in Kubernetes using a `KongClusterPlugin` resource."
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources: []
tldr:
  q: How do I configure the Request Transformer Advanced plugin's `config.replace.uri` parameter in Kubernetes?
  a: |
    Apply a `KongClusterPlugin` resource with `config.replace.uri` set under the `replace` config block for the `request-transformer-advanced` plugin, then run `kubectl apply -f sample.yaml`.
---

## Overview

How can we configure the Request Transformer Advanced plugin to utilize `config.replace.uri` in our Kubernetes environment. We see it as an available field but the documentation doesn't display an example on how to configure this.

## Steps

To configure the Request Transformer Advanced plugin to utilize the `config.replace.uri` parameter in kubernetes we can apply the following yaml file.

```bash
kubectl apply -f sample.yaml
```

sample.yaml contents:

```yaml
apiVersion: configuration.konghq.com/v1
kind: KongClusterPlugin
metadata:
  name: global-request-transformer-advanced
  annotations:
    kubernetes.io/ingress.class: kong
  labels:
    global: "true"
config: 
  replace:
    uri: "/anything"
plugin: request-transformer-advanced
```
