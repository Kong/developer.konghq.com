---
title: "Kong Gateway: Customize error message for a disabled service"
content_type: support
published: false
description: Create a catch-all service/route and attach the `request-termination` plugin to it so a disabled service returns a customized error message.
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources: []
tldr:
  q: How can I customize the error message returned to clients when a Kong Gateway service is disabled?
  a: |
    Disabling a service and attaching the `request-termination` plugin to it does not change the response; clients get `no Route matched with those values`.
    Instead, create a catch-all service/route that stays enabled and attach `request-termination` to it, so requests to the disabled service hit the catch-all and return your customized message.
---

## Problem

We are looking for a way to disable a service and customize the error message that is displayed to the client when they try to access the service. If we disable the service and attach a `request-termination` plugin, the message does not get modified and we receive the error:

```json
{
	"message": "no Route matched with those values"
}
```

## Solution

The way around this is to create a catch-all service/route and attach the `request-termination` plugin to the catch-all route/service. You will have 2 services: the original one is temporarily disabled while you have a catch-all that is enabled. Afterwards, attach the `request-termination` plugin to the catch-all service. Now when the disabled service is hit, the catch-all route is called and the `request-termination` plugin is executed.
