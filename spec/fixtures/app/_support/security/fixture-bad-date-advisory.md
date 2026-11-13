---
title: "Fixture advisory with a malformed date"
content_type: support
description: "A fixture advisory whose published value is not a date."
products:
  - gateway
advisory:
  published: "not-a-date"
  cves:
    - id: CVE-2026-0004
      severity: low
      summary: Placeholder
  products:
    - product: gateway
      affected_versions:
        - "3.1.x"
      fixed_versions:
        - "3.1.2.7"
---

A fixture advisory with an invalid `advisory.published`. It exists to back the feeds specs.
