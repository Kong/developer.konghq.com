---
title: "Kong Kubernetes Ingress Controller: Enable/Disable migrations bootstrap to run when using Helm"
content_type: support
published: false
description: The chart supports a parameter, `migrations.init`, which can be used to control spawning the migrations bootstrap job.
products:
  - kic
works_on:
  - on-prem
  - konnect
tldr:
  q: How can I enable or disable the migrations bootstrap job when installing Kong with Helm?
  a: |
    The Helm chart exposes a `migrations.init` parameter that controls whether the migrations bootstrap job runs. Set `migrations.init=false` to skip it; the job runs by default on install.
related_resources: []
---

## Kong Kubernetes Ingress Controller: Enable/Disable migrations bootstrap to run when using Helm

When deploying Kong with Helm there may be specific use cases where you want control of whether or not the migrations bootstrap job runs. How can this be achieved?

The chart supports a parameter, `migrations.init`, which can be used to control spawning the migrations bootstrap job.

For example:

```bash

helm upgrade -i kong kong/kong --set env.database=postgres --set migrations.init=false
```

Please note that the default behavior is to always run this job on install and generally should not need to be modified.
