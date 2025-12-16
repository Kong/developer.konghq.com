---
title: "{{site.base_gateway}} software bill of materials"
content_type: policy
layout: reference

products:
  - gateway

breadcrumbs:
  - /gateway/

description: |
  Kong provides a software bill of materials (SBOM) for every minor release, starting with 3.3.0.0.

related_resources:
  - text: "Secure {{site.base_gateway}}"
    url: /gateway/security/
  - text: Kong vulnerability patching process
    url: /gateway/vulnerabilities/
  - text: "Supported third-party dependencies for {{site.base_gateway}}"
    url: /gateway/third-party-support/

works_on:
  - on-prem

tags:
  - sbom
---

A software bill of materials (SBOM) is an inventory of all software components (proprietary and open-source), open-source licenses, and dependencies in a given product. A software bill of materials (SBOM) provides visibility into the software supply chain and any license compliance, security, and quality risks that may exist.

Starting in {{site.ee_product_name}} 3.3, we generate SBOMs for our artifact images.


{% table %}
columns:
  - title: {{site.base_gateway}} Version
    key: version
  - title: Direct Download link
    key: download
rows:
  - version: 3.13.0.0
    download: |
      [<img src="/assets/icons/download.svg" class="w-5 m-2 inline-block"> Download 3.13 SBOM](https://packages.konghq.com/public/gateway-313/raw/names/security-assets/versions/3.13.0.0/security-assets.tar.gz)
  - version: 3.12.0.0
    download: |
      [<img src="/assets/icons/download.svg" class="w-5 m-2 inline-block"> Download 3.12 SBOM](https://packages.konghq.com/public/gateway-312/raw/names/security-assets/versions/3.12.0.0/security-assets.tar.gz)
  - version: 3.11.0.0
    download: |
      [<img src="/assets/icons/download.svg" class="w-5 m-2 inline-block"> Download 3.11 SBOM](https://packages.konghq.com/public/gateway-311/raw/names/security-assets/versions/3.11.0.0/security-assets.tar.gz)
  - version: 3.10.0.0
    download: |
      [<img src="/assets/icons/download.svg" class="w-5 m-2 inline-block"> Download 3.10 SBOM](https://packages.konghq.com/public/gateway-310/raw/versions/3.10.0.0/security-assets.tar.gz)
  - version: 3.9.0.0
    download: |
      [<img src="/assets/icons/download.svg" class="w-5 m-2 inline-block"> Download 3.9 SBOM](https://packages.konghq.com/public/gateway-39/raw/versions/3.9.0.0/security-assets.tar.gz)
  - version: 3.8.0.0
    download: |
      [<img src="/assets/icons/download.svg" class="w-5 m-2 inline-block"> Download 3.8 SBOM](https://packages.konghq.com/public/gateway-38/raw/versions/3.8.0.0/security-assets.tar.gz)
  - version: 3.7.0.0
    download: |
      [<img src="/assets/icons/download.svg" class="w-5 m-2 inline-block"> Download 3.7 SBOM](https://packages.konghq.com/public/gateway-37/raw/versions/3.7.0.0/security-assets.tar.gz)
  - version: 3.6.0.0
    download: |
      [<img src="/assets/icons/download.svg" class="w-5 m-2 inline-block"> Download 3.6 SBOM](https://packages.konghq.com/public/gateway-36/raw/versions/3.6.0.0/security-assets.tar.gz)
  - version: 3.5.0.0
    download: |
      [<img src="/assets/icons/download.svg" class="w-5 m-2 inline-block"> Download 3.5 SBOM](https://packages.konghq.com/public/gateway-35/raw/versions/3.5.0.0/security-assets.tar.gz)
  - version: 3.4.0.0
    download: |
      [<img src="/assets/icons/download.svg" class="w-5 m-2 inline-block"> Download 3.4 SBOM](https://packages.konghq.com/public/gateway-34/raw/versions/3.4.0.0/security-assets.tar.gz)
  - version: 3.3.0.0
    download: |
      [<img src="/assets/icons/download.svg" class="w-5 m-2 inline-block"> Download 3.3 SBOM](https://packages.konghq.com/public/gateway-33/raw/versions/3.3.0.0/security-assets.tar.gz)

{% endtable %}
