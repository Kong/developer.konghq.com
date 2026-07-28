---
title: Limiting the Ingress Controller to watch resources in specific namespaces
content_type: support
description: Restrict the Kong Ingress Controller to only watch resources in specific namespaces using the `watch-namespace` parameter, environment variable, or config setting.
products:
  - kic
works_on:
  - on-prem
  - konnect
tldr:
  q: How can the Ingress Controller be limited to only watch resources in specific namespaces?
  a: |
    Set the comma-separated `--watch-namespace` flag (or the `CONTROLLER_WATCH_NAMESPACE` environment variable / `watch_namespace` config setting) to restrict the controller to specific namespaces. Resources created outside those namespaces — including Ingresses with a `konghq.com/plugins` annotation pointing at a non-existent plugin — are ignored by the controller.
related_resources:
  - text: "Kong Ingress Controller: Ingress documentation"
    url: /kubernetes-ingress-controller/ingress/
---

## Overview

Sometimes it may be ideal to only have the Ingress Controller use resources created in specific namespaces. For example, you only want to monitor an Ingress created within the Kong namespace and disregard resources in the default namespace regardless of the Ingress Class defined. How can this be achieved?

## Steps

This can be handled using the parameter `watch-namespace`. It can be passed as either a command line parameter, environment variable, or config setting (Helm value).

- Parameter: `--watch-namespace`
- Environment variable: `CONTROLLER_WATCH_NAMESPACE`
- Config setting: `watch_namespace`

This is a comma-separated list of namespaces that will be watched for new resources. For example, if you have two namespaces you want to watch, `prod` and `dev`, and someone creates an ingress in the default namespace, it will not be picked up by the controller.

This can avoid errors commonly seen when an Ingress or KongConsumer is created with the annotation `konghq.com/plugins` and no plugin exists.
