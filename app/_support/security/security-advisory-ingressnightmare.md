---
title: "Security Advisory: IngressNightmare ({{site.kic_product_name}} not affected)"
content_type: support
description: "{{site.kic_product_name}} (KIC) is not impacted or affected by the vulnerability \"IngressNightmare\"."
products:
  - kic
works_on:
  - on-prem
  - konnect
advisory:
  published: "2025-03-25"
  cves:
    - id: CVE-2025-24513
      status: not_affected
    - id: CVE-2025-24514
      status: not_affected
    - id: CVE-2025-1097
      status: not_affected
    - id: CVE-2025-1098
      status: not_affected
    - id: CVE-2025-1974
      status: not_affected
related_resources:
  - text: Reference
    url: https://kubernetes.io/blog/2025/03/24/ingress-nginx-cve-2025-1974/
---

{{site.kic_product_name}} (KIC) is not impacted or affected by the vulnerability "IngressNightmare".

In Ingress-nginx, some configurations rely on constructing file paths, but KIC does not. As a result, KIC remains unaffected by this vulnerability.

The vulnerabilities included in IngressNightmare are:

* CVE-2025-24513
* CVE-2025-24514
* CVE-2025-1097
* CVE-2025-1098
* CVE-2025-1974

For more information about IngressNightmare, see the [Kubernetes blog post on CVE-2025-1974](https://kubernetes.io/blog/2025/03/24/ingress-nginx-cve-2025-1974/).
