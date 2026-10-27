---
title: "Security Advisory KONGSA-20260608: HTTP/2 Bomb (CVE-2026-49975 and CVE-2026-47774)"
content_type: support
description: "{{site.ee_product_name}}, {{site.ai_gateway_name}} and {{site.mesh_product_name}} are affected by a denial-of-service vulnerability in HTTP/2 listeners, known as HTTP/2 Bomb. This advisory lists the patched versions and a mitigation."
products:
  - gateway
  - ai-gateway
  - mesh
works_on:
  - on-prem
  - konnect
advisory:
  id: KONGSA-20260608
  cves:
    - id: CVE-2026-49975
      severity: high
      cvss_score: 7.7
      cvss_version: "4.0"
      summary: HTTP/2 Bomb, denial of service through excessive resource consumption on HTTP/2 listeners
    - id: CVE-2026-47774
      severity: high
      cvss_score: 7.7
      cvss_version: "4.0"
      summary: HTTP/2 Bomb, denial of service through excessive resource consumption on HTTP/2 listeners
  products:
    - product: gateway
      affected_versions:
        - "3.14.0.0 to 3.14.0.5"
        - "3.13.0.0 to 3.13.0.5"
        - "3.12.0.0 to 3.12.0.7"
        - "3.11.0.0 to 3.11.0.12"
        - "3.10.0.0 to 3.10.0.13"
        - "3.4.0.0 to 3.4.3.27"
      fixed_versions:
        - "3.14.0.6"
        - "3.13.0.6"
        - "3.12.0.8"
        - "3.11.0.13"
        - "3.10.0.14"
        - "3.4.3.28"
    - product: mesh
      affected_versions:
        - "2.13.0 to 2.13.7"
        - "2.12.0 to 2.12.11"
        - "2.11.0 to 2.11.14"
        - "2.9.0 to 2.9.16"
        - "2.7.0 to 2.8.26"
      fixed_versions:
        - "2.13.8"
        - "2.12.12"
        - "2.11.15"
        - "2.9.17"
        - "2.7.27"
---

Kong has identified a denial-of-service vulnerability, CVE-2026-49975 and CVE-2026-47774 (HTTP/2 Bomb), that affects {{site.ee_product_name}}, {{site.mesh_product_name}} and {{site.ai_gateway_name}} where HTTP/2 listeners are enabled and reachable by untrusted clients.

## CVE-2026-49975 and CVE-2026-47774: HTTP/2 Bomb

{{site.ee_product_name}}, {{site.ai_gateway_name}} and {{site.mesh_product_name}} include HTTP/2 proxy listeners, which are enabled by default in Enterprise deployments and are affected by the vulnerability.

A remote, unauthenticated attacker with network access to a vulnerable HTTP/2 listener could exploit this issue to trigger excessive resource consumption. This could exhaust available memory and other system resources, leading to service degradation or a denial-of-service (DoS) condition.

### Kong severity assessment

* **Severity:** High
* **CVSS v4.0 score:** 7.7
* **Vector:** CVSS:4.0/AV:N/AC:L/AT:N/PR:N/UI:N/VC:N/VI:N/VA:H/SC:N/SI:N/SA:N/E:P

### Am I affected?

Consider a {{site.base_gateway}} deployment affected if both of the following are true:

1. Your `kong.conf` configuration file enables `http2` in any of the `*_listen` directives. For example: `proxy_listen = "0.0.0.0:8443 http2 ssl reuseport backlog=16384"`.
2. The affected listener is reachable by untrusted clients or exposed to the internet.

A {{site.mesh_product_name}} deployment may be affected if the attacker can access an Envoy instance using HTTP/2.

{{site.mesh_product_name}} usually runs mTLS between instances, which restricts HTTP/2 access to trusted instances. The most likely area of exposure is a built-in gateway that is exposed to the untrusted internet.

### Impacted products

All {{site.ee_product_name}}, {{site.ai_gateway_name}} and {{site.mesh_product_name}} versions prior to the patch versions listed in the Remediation section are affected. The impact also extends to related services that use the affected {{site.ee_product_name}} versions, including Dedicated Cloud Gateways and other managed gateway deployments.

Dedicated Cloud Gateways and other managed services are continuously monitored, and no evidence of DoS-related impact has been observed at the time of this advisory. Kong teams are monitoring these services, have remediation playbooks in place, and will apply the relevant patches as part of the managed service.

## Remediation

{{site.ee_product_name}} and {{site.ai_gateway_name}} customers should apply the following patch:

{% table %}
columns:
  - title: Impacted supported versions of {{site.ee_product_name}} and {{site.ai_gateway_name}}
    key: impacted
  - title: Patch
    key: patch
rows:
  - impacted: "3.14.0.0 - 3.14.0.5"
    patch: "3.14.0.6"
  - impacted: "3.13.0.0 - 3.13.0.5"
    patch: "3.13.0.6"
  - impacted: "3.12.0.0 - 3.12.0.7"
    patch: "3.12.0.8"
  - impacted: "3.11.0.0 - 3.11.0.12"
    patch: "3.11.0.13"
  - impacted: "3.10.0.0 - 3.10.0.13"
    patch: "3.10.0.14"
  - impacted: "3.4.0.0 - 3.4.3.27"
    patch: "3.4.3.28"
{% endtable %}

{{site.mesh_product_name}} customers should apply the following patch:

{% table %}
columns:
  - title: Impacted supported versions of {{site.mesh_product_name}}
    key: impacted
  - title: Patch
    key: patch
rows:
  - impacted: "2.13.0 - 2.13.7"
    patch: "2.13.8"
  - impacted: "2.12.0 - 2.12.11"
    patch: "2.12.12"
  - impacted: "2.11.0 - 2.11.14"
    patch: "2.11.15"
  - impacted: "2.9.0 - 2.9.16"
    patch: "2.9.17"
  - impacted: "2.7.0 - 2.8.26"
    patch: "2.7.27"
{% endtable %}

Each patch is available for all supported Kong distributions through standard Kong distribution channels.

Users of {{site.ee_product_name}} or {{site.mesh_product_name}} versions that aren't listed in these tables should upgrade to a supported version.

## Mitigation

{{site.ee_product_name}} and {{site.ai_gateway_name}} customers who can't immediately upgrade to a patched version can temporarily disable HTTP/2 if it isn't required in their environment. Instructions are in the [Disable HTTP/2 in Kong](https://support.konghq.com/support/s/article/disable-http-2-in-kong) article.

{{site.mesh_product_name}} customers who can't immediately upgrade to a patched version can temporarily disable HTTP/2 if it isn't required in their environment. Instructions are in the [{{site.mesh_product_name}} CVE-2026-47774 HTTP/2 memory exhaustion](https://support.konghq.com/support/s/article/Kong-Mesh-CVE-2026-47774---HTTP-2-memory-exhaustion) article.
