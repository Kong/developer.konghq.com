---
title: Configuring AWS ALB health checks for proxy pods
content_type: support
description: "Steps to configure AWS Application Load Balancer (ALB) health checks for Kong Gateway proxy pods using the `/status/ready` endpoint exposed by the `status_listen` server."
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: How can I configure AWS ALB health checks for proxy pods?
  a: |
    Enable the Kong `status_listen` server so it exposes `/status/ready`, then point the ALB target group's health check at that port and path — for example, using the `alb.ingress.kubernetes.io/healthcheck-port` and `-healthcheck-path` annotations with `target-type: ip` so the ALB checks the pod IPs directly.
related_resources:
  - text: "Kong Gateway changelog: status API feature"
    url: /gateway/changelog/#3-3-0-0-feature-status-api
  - text: References for ALB annotations
    url: https://docs.aws.amazon.com/eks/latest/userguide/alb-ingress.html
---

## Overview

To configure AWS ALB health checks for proxy pods, you can utilize the `/status/ready` endpoint provided by the `status_listen` server. This endpoint is designed for monitoring the health of Kong Gateway.

## Steps

Here are the steps to configure the health checks:

1. Ensure that the `status_listen` server is enabled in your Kong configuration. This server provides the `/status/ready` endpoint.

   In the Helm values, enable the status server:

   ```yaml
   status:
     enabled: true
     http:
       # Enable plaintext HTTP listen for the status listen
       enabled: true
       containerPort: 8100
       parameters: []
   ```

2. Configure your AWS Application Load Balancer (ALB) to perform health checks directly on the pods using the `/status/ready` endpoint.

   To do this, you need to set the target type to `ip` and specify the health check port and path.

   Here is an example of the annotations to add to the proxy service:

   ```yaml
   annotations:
     alb.ingress.kubernetes.io/target-type: ip
     alb.ingress.kubernetes.io/healthcheck-port: "8100"
     alb.ingress.kubernetes.io/healthcheck-path: "/status/ready"
   ```

   By setting the target type to `ip`, the ALB will perform health checks directly on the pod IPs, bypassing the Kong proxy.
