---
title: How to check whether Kong is OSS version or enterprise version
content_type: support
published: false
description: Explains how to confirm whether a Kong Gateway installation is OSS or Enterprise using Kong Manager, the `kong version` command, or proxy logs.
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: How can I check whether my Kong installation is OSS or Enterprise?
  a: |
    Check the info panel in Kong Manager, run `kong version` (which prints "Enterprise" before the version number for Enterprise installations), or inspect the Kong proxy logs.
related_resources: []
---

## Overview

How to check whether Kong is using an OSS version or an Enterprise version

## Steps

There are several methods to check whether Kong is using an OSS or Enterprise version.

Method 1. By Kong Manager.

Open the Kong Manager and click the 'i' mark on the right top.

It will show you detailed information about the Kong you are using.

Method 2. By the `kong version` command.

For example, the result shows "Enterprise" before the version for an Enterprise version.

```bash
kubectl exec -it <kong pod name> -c proxy -n <kong namespace> -- kong version
Kong Enterprise 3.14.0.0
```

Method 3. By checking Kong proxy logs.
