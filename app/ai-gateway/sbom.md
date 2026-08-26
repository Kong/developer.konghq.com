---
title: "{{site.ai_gateway}} software bill of materials"
content_type: policy
layout: reference

products:
  - ai-gateway

breadcrumbs:
  - /ai-gateway/

description: |
  Kong provides a software bill of materials (SBOM) for every {{site.ai_gateway}} release, starting with 2.0.2.

related_resources:
  - text: "{{site.base_gateway}} software bill of materials"
    url: /gateway/sbom/
  - text: Kong vulnerability patching process
    url: /gateway/vulnerabilities/

works_on:
  - on-prem
  - konnect

tags:
  - sbom
---

A software bill of materials (SBOM) is an inventory of all software components (proprietary and open-source), open-source licenses, and dependencies in a given product. A software bill of materials (SBOM) provides visibility into the software supply chain and any license compliance, security, and quality risks that may exist.

{% table %}
columns:
  - title: {{site.ai_gateway}} Version
    key: version
  - title: Direct Download link
    key: download
rows:
  - version: 2.0.2
    download: |
      [<img src="/assets/icons/download.svg" class="w-5 m-2 inline-block" alt=""> Download 2.0.2 SBOM](https://packages.konghq.com/public/ai-gateway-20/raw/names/security-assets/versions/2.0.2/kong-aigw-2.0.2-security-assets.tar.gz)

{% endtable %}
