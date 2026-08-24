---
title: "{{site.kic_product_name}}: Deploying the KIC with no Enterprise license"
content_type: support
description: This error occurs when no Enterprise license (not an expired one) is present, so enterprise-only plugins are rejected.
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: Why do enterprise-only plugins like `openid-connect` fail to apply when deploying Kong Ingress Controller?
  a: |
    Enterprise-only plugins are rejected because no Enterprise license is loaded on the Gateway/data plane — this is different from an expired license, which does not block plugin creation.
    Redeploy the Enterprise license secret and restart the affected pods to resolve it.
related_resources:
  - text: Kong Enterprise license secret deployment steps
    url: /kubernetes-ingress-controller/license/#applying-a-static-license
---

## Problem

While installing {{site.base_gateway}} with {{site.kic_product_name}} (KIC) and no Enterprise license present, we noticed that enterprise-only plugins (such as `openid-connect`) fail to apply.

When reviewing the logs, or the Kubernetes events for the affected resource, we can see a schema violation stating the plugin is enterprise-only, surfaced through one of two paths:

As an admission-webhook rejection when applying the resource:

```

Error from server: error when creating "plugin.yaml": admission webhook "validations.kong.konghq.com" denied the request: openid-connect is an enterprise only plugin
```

Or as a `KongConfigurationApplyFailed` Warning Event on the resource if the webhook path is bypassed:

```

Warning  KongConfigurationApplyFailed  ingress-controller  openid-connect is an enterprise only plugin
```

Note: this is specifically an absent-license symptom. An expired (but present) Enterprise license behaves differently — expired licenses do not block enterprise-only plugin creation the way an absent license does.

## Cause

This occurs because no Enterprise license is loaded on the Gateway/data plane, so enterprise-only plugins are rejected.

## Solution

We can first verify this by checking the startup logs for the proxy pod for licensing-related messages.

To resolve this, please redeploy the license and verify the steps.

Note: You will need to restart/delete/deploy the pods following the new license secret to see the effect.
