---
title: How to set healthcheck in ALB for Kong control plane when it's enabled with RBAC
content_type: support
description: After enabling RBAC for the Kong control plane (CP), its admin port (`8001`/`8444`) will always return `401` if no token has been sent.
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources:
  - text: AWS Application Load Balancer introduction
    url: https://docs.aws.amazon.com/elasticloadbalancing/latest/application/introduction.html
  - text: Kong hybrid mode deployment topology
    url: /gateway/hybrid-mode/
  - text: the `status_listen` configuration reference
    url: /gateway/configuration/#status-listen
  - text: AWS Load Balancer Controller ingress annotations reference
    url: https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.2/guide/ingress/annotations/
tldr:
  q: How do I configure an ALB health check for the Kong control plane when RBAC is enabled?
  a: |
    Enable Kong's status port (`KONG_STATUS_LISTEN`, e.g. `0.0.0.0:8100`) since the RBAC-protected admin port always returns `401` without a token. Point the AWS Load Balancer Controller's health check annotations at that status port and the `/status` path instead of the admin port.
---

## Overview

I installed Kong in k8s by using hybrid mode. And I enabled RBAC for the Kong control plane, I have ALB in front of the Kong control plane. How to set healthcheck for the Kong control plane in ALB?

## Steps

After enabling RBAC for the Kong control plane (CP), its admin port (`8001`/`8444`) will always return `401` if no token has been sent.

We have to follow below steps to use status port for healthcheck in ALB.

1. Enable status port

   Set `KONG_STATUS_LISTEN` env var for CP like below:

   ```
   KONG_STATUS_LISTEN = 0.0.0.0:8100
   ```

   You could refer to the `status_listen` configuration reference to use a different port and protocol; replace them in step 2 if you use a different port and protocol.

2. Add below AWS Load Balancer Controller annotations in the ingress for CP:

   ```
   alb.ingress.kubernetes.io/healthcheck-protocol: HTTP
   alb.ingress.kubernetes.io/healthcheck-port: 8100
   alb.ingress.kubernetes.io/healthcheck-path: /status
   ```
