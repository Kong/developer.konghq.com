---
title: "Kong Gateway: We have multiple pods but only 1 is accepting traffic"
content_type: support
description: When only one of several Kong Proxy pods receives traffic, sticky sessions configured on the load balancer is a likely cause.
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources: []
tldr:
  q: Why is only one of my Kong Proxy pods receiving traffic when several are running?
  a: |
    When each pod serves traffic fine directly but the load balancer sends everything to one pod, sticky sessions on the load balancer are the likely cause.
    Confirm the pods work without the load balancer, then remove sticky sessions from the load balancer configuration.
---

## Problem

We have multiple Kong Proxy pods running however only 1 pod is taking traffic. If we exec into each of the pods and hit each proxy service directly the pod will accept traffic so we know they are functioning properly. We are using a Load Balancer to direct traffic to the Proxy Pods but there are no special restrictions on the Load Balancer.

## Cause

This would occur if sticky sessions were configured on the load balancer. Sticky sessions ensure all traffic from particular clients is sent to the same server.

## Solution

First, we should confirm that the proxy pods accept traffic externally/internally when we remove the Load Balancer. If there are no issues here we can confirm that the proxy pods can handle traffic as expected. Internally, you can either exec into the pod and `curl localhost:8000` or you can port-forward to the pod and hit it locally by curling `localhost:8000`. For external checking, we would need to explore if the Load Balancer has any restrictions configured. To resolve this, remove sticky sessions from the load balancer.
