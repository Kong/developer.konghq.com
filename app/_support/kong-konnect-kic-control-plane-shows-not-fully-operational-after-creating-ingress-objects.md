---
title: "Kong Konnect: KIC Control Plane shows not \"Fully Operational\" after creating Ingress objects"
content_type: support
description: KIC's "Failed pushing configuration to Konnect" validation error is a blanket message that, in this case, is caused by route/service names generated from Ingress objects exceeding Konnect's character limit.
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: Why does the KIC Control Plane show not "Fully Operational" after creating Ingress objects?
  a: |
    The "validation error" is a blanket message covering any failure applying KIC-generated configuration to the Gateway — commonly a route or service name exceeding Konnect's character limit (originally 128, since raised to 512).
    This limitation doesn't apply to on-premises Kong Gateway.
related_resources: []
---

## Problem

We recently added a few ingress objects to our K8S cluster and the KIC Control plane now shows it is not "Fully Operational".

In the KIC logging we see the following:

```

time="2023-09-21T11:48:07-07:00" level=warning msg="Failed pushing configuration to Konnect" error="performing update for https://us.kic.api.konghq.com/kic/api/control-planes/220edfee-f32c-4b79-a1b6-a9f2860ad1e6 failed: 5 errors occurred:\n\twhile processing event: {Create} route jeffys-namespace.getallpizzaconfiguration0-internal-0.getallplatformconfig.getallpizzaconfigurationjeffys-namespace.gateway.cloudtwo.jeffykong.com.80 failed: HTTP status 400 (message: \"validation error\")\n\twhile processing event: {Create} route jeffys-namespace.getpizzaconfiguration0-internal-0.getplatformconfig.getpizzaconfigurationjeffys-namespace.gateway.cloudtwo.jeffykong.com.80 failed: HTTP status 400 (message: \"validation error\")\n\twhile processing event: {Create} route jeffys-namespace.getrestaurantlocation-0-internal-0.getrestaurantlocation.getrestaurantlocation-jeffys-namespace.gateway.cloudtwo.jeffykong.com.80 failed: HTTP status 400 (message: \"validation error\")\n\twhile processing event: {Create} route jeffys-namespace.getallpizzacrustfw-0-internal-0.getallpizzacrustfw.getallpizzacrustfw-jeffys-namespace.gateway.cloudtwo.jeffykong.com.80 failed: HTTP status 400 (message: \"validation error\")\n\twhile processing event: {Create} route jeffys-namespace.getallpizzasides-0-internal-0.getallpizzasides.getallpizzasides-jeffys-namespace.gateway.cloudtwo.jeffykong.com.80 failed: HTTP status 400 (message: \"validation error\")\n"
```

## Cause

This validation error is a blanket message for any type of issue with the application of a KIC generated configuration to the Gateway. In this case, it is due to a maximum character limit that can be applied to route and service names.

At the time of the above error, the character limit for route and service names in Konnect was 128. This limit has since been raised to 512. This issue may still occur in the future as the concatenation of Kubernetes maximum size Ingress and Service name is approx. 1031 characters.

## Solution

A more informational version of the error can be seen by manually attempting to create the route name via the GUI and having Dev Tools open:

```json

{
    "code": 3,
    "message": "validation error",
    "details": [
        {
            "@type": "type.googleapis.com/kong.admin.model.v1.ErrorDetail",
            "type": "ERROR_TYPE_FIELD",
            "field": "name",
            "messages": [
                "length must be <= 128, but got 138"
            ]
        }
    ]
}
```

NOTE: This limitation does not exist in Kong on-premises Gateway.
