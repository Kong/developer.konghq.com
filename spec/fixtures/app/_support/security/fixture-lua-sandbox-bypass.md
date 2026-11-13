---
title: "Security Advisory: {{site.base_gateway}} Lua sandbox bypass"
content_type: support
description: "{{site.base_gateway}} is affected by a Lua sandbox bypass. This advisory lists the patched versions."
products:
  - gateway
advisory:
  published: "2026-06-05"
  cves:
    - id: CVE-2026-0001
      severity: high
      summary: Lua sandbox escape in {{site.base_gateway}}
  products:
    - product: gateway
      affected_versions:
        - "3.4.x"
      fixed_versions:
        - "3.4.1.2"
---

## Summary

A fixture advisory published 2026-06-05. It exists to back the feeds specs.
