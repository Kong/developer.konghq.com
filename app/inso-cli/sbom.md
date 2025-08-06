---
title: "Inso CLI software bill of materials (SBOM)"
content_type: policy
layout: reference

products:
  - insomnia

tools:
  - inso-cli

breadcrumbs:
  - /inso-cli/

tags:
  - sbom

description: Kong provides a software bill of materials (SBOM) for Inso CLI.

related_resources:
  - text: Insomnia collected data
    url: /insomnia/collected-data/
  - text: Kong vulnerability patching process
    url: /gateway/vulnerabilities/
---

A software bill of materials (SBOM) is an inventory of all software components (proprietary and open source), open source licenses, and dependencies in a given product. A software bill of materials provides visibility into the software supply chain and any license compliance, security, and quality risks that may exist.

Kong provides SBOMs for both Inso CLI binaries and Docker container images.

## Download Inso CLI SBOMs

1. Navigate to Insomnia [GitHub Releases](https://updates.insomnia.rest/downloads/release/latest?app=com.insomnia.inso&channel=stable)

2. Download the below SBOMs as needed:

* SBOMs for Inso CLI binaries: `sbom.spdx.json` and `sbom.cyclonedx.json`
* SBOMs for Inso CLI Docker images: `image-inso-*-sbom.spdx.json` and `image-inso-*-sbom.cyclonedx.json`
