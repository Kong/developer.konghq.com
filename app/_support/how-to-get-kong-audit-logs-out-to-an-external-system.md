---
title: How to get Kong Audit Logs out to an external system
content_type: support
published: false
description: "Kong doesn't push Audit Logs to an external system; use the Admin API to pull them into your SIEM tool."
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: Can Kong push Audit Logs to an external system?
  a: |
    No — Kong doesn't support pushing Audit Logs to an external system. Use the Admin API to pull Audit Logs, since most SIEM tools support pulling from an API.
related_resources:
  - text: Kong Audit Logs documentation
    url: /gateway/audit-logs/
---

## Overview

Can the Kong Audit Logs be uploaded to an external system via a push mechanism from Kong?

## Steps

No, this feature is not available as a push operation from Kong. The Kong Admin API can be used to retrieve the Audit Logs as most SIEM tools have a mechanism to pull from an API.

Please refer to the Kong documentation for examples of our Audit Logging.
