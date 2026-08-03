---
title: "Kong Ingress Controller reports \"failed to connect to reporting server\""
content_type: support
description: Kong Ingress Controller, by default, sends anonymous usage data to help improve Kong.
products:
  - kic
works_on:
  - on-prem
  - konnect
related_resources: []
tldr:
  q: Why does Kong Ingress Controller log "failed to connect to reporting server"?
  a: |
    Kong Ingress Controller sends anonymous usage data to `kong-hf.konghq.com` by default, and a firewall blocking that outbound connection produces this error. Set `CONTROLLER_ANONYMOUS_REPORTS` to `false` in the controller configuration to disable the reports and stop the error.
---

## Problem

Kong Ingress Controller reports this error in the logs:

```
time="2026-03-04T13:14:00Z" level=error msg="failed to connect to reporting server: dial tcp 34.233.69.182:61833: i/o timeout"
```

Kong Ingress Controller, by default, sends anonymous usage data to help improve Kong, and a firewall may be blocking it from communicating this reporting data to `kong-hf.konghq.com` on port 61833.

## Solution

You can disable sending this reporting data by setting `-anonymous-reports` to `false` in the Kong Ingress Controller configuration:

```yaml
- name: CONTROLLER_ANONYMOUS_REPORTS
  value: "false"
```

More information is available in the Kong Ingress Controller environment variables documentation.
