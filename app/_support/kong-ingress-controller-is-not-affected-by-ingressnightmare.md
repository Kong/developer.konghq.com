---
title: "{{site.kic_product_name}} is not affected by IngressNightmare"
content_type: support
description: "Kong Ingress Controller (KIC) is not impacted or affected by the vulnerability \"IngressNightmare\"."
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: Is Kong Ingress Controller affected by the IngressNightmare vulnerability?
  a: |
    No. IngressNightmare (CVE-2025-24513, CVE-2025-24514, CVE-2025-1097, CVE-2025-1098, CVE-2025-1974) affects Ingress-nginx configurations that construct file paths, which KIC does not do, so KIC is not impacted.
related_resources:
  - text: Reference
    url: https://kubernetes.io/blog/2025/03/24/ingress-nginx-cve-2025-1974/
---

## Problem

{{site.kic_product_name}} users need to know whether they are affected by the vulnerability codenamed "IngressNightmare".

## Solution

{{site.kic_product_name}} (KIC) is not impacted or affected by the vulnerability "IngressNightmare".

In Ingress-nginx, some configurations rely on constructing file paths, but KIC does not. As a result, KIC remains unaffected by this vulnerability.

Vulnerabilities included in IngressNightmare:

CVE-2025-24513

CVE-2025-24514

CVE-2025-1097

CVE-2025-1098

CVE-2025-1974
