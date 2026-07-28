---
title: "Kong Mesh generates the error \"stream terminated by RST_STREAM with error code: PROTOCOL_ERROR\""
content_type: support
description: Kong Mesh's zone status flaps between online and offline when cross-zone traffic passes through a layer 7 Application Load Balancer instead of a layer 4 load balancer.
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources: []
tldr:
  q: "Why does Kong Mesh multi-zone status flap between online and offline with a \"stream terminated by RST_STREAM with error code: PROTOCOL_ERROR\" error?"
  a: |
    This happens when cross-zone traffic passes through an Application Load Balancer (layer 7/HTTP), which can't correctly route Kong Mesh's raw TCP/TLS traffic between zones. Use an Elastic Load Balancer that operates at layer 4 (TCP) instead.
---

## Problem

When running Kong Mesh in multi-zone mode you may notice the status of the remote control planes continuously change between online and offline. This is observed both through the GUI (`http://<global-cp>/status/zones`) and the HTTP API (`/status/zones`).

You will also notice the below error in the remote Control Plane logs

```
ERROR kds-remote.mux-client component terminated with an error {"generationID": 11, "error": "rpc error: code = Internal desc = stream terminated by RST_STREAM with error code: PROTOCOL_ERROR"}
```

## Cause

This can occur when using an Application Load Balancer. Kong Mesh passes traffic between zones using TLS, which is effectively raw TCP traffic. As the ALB only works at layer 7 (HTTP) it can cause issues with the communication because it will not know where to route the traffic.

## Solution

It is required that you use an Elastic Load Balancer that works at layer 4 (TCP).
