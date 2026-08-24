---
title: "Kong Gateway: Receiving error \"entity tags missing fields\" error=\"no namespace\" name=openid-connect"
content_type: support
description: This error occurs typically due to not recognizing the license that has been created.
products:
  - gateway
  - kic
works_on:
  - on-prem
  - konnect
related_resources:
  - text: Kong Ingress Controller Enterprise license deployment steps
    url: /kubernetes-ingress-controller/license/#applying-a-static-license
tldr:
  q: Why does the Kong Ingress Controller fail to apply the `openid-connect` plugin with an "enterprise only plugin" error?
  a: |
    The `openid-connect` plugin requires a valid Kong Enterprise license, and this error means no valid license is currently loaded on the Gateway/data plane. Check the proxy pod's startup logs for licensing messages, then redeploy the Enterprise license to resolve it.
---

## Problem

We're currently deployed in dbless on kubernetes. While installing Kong Gateway with Kong Ingress Controller (KIC), we noticed that our ingress-controller is failing to start up properly.

When reviewing the logs, or the Kubernetes events for the affected resource, we can see a schema violation for the `openid-connect` plugin stating it is an enterprise-only plugin, surfaced through one of two paths:

As an admission-webhook rejection when applying the resource:

```

Error from server: error when creating "plugin.yaml": admission webhook "validations.kong.konghq.com" denied the request: openid-connect is an enterprise only plugin
```

Or as a `KongConfigurationApplyFailed` Warning Event on the resource if the webhook path is bypassed:

```

Warning  KongConfigurationApplyFailed  ingress-controller  openid-connect is an enterprise only plugin
```

How can we resolve this?

## Cause

This occurs because the `openid-connect` plugin is only available with a valid Kong Enterprise license, and no license (or no valid license) is currently loaded on the Gateway/data plane. We can verify this by checking the startup logs for the proxy pod for licensing-related messages.

## Solution

To resolve this, please redeploy the license and verify the steps.
