---
title: "{{site.base_gateway}} vulnerability patching process"

description: Learn how Kong handles vulnerabilities or potential vulnerabilities in {{site.base_gateway}} or third-party code, and how to report any security issues.

content_type: policy
layout: reference

tags:
  - vulnerabilities
  - patching
search_aliases:
  - CVSS

products:
  - gateway

breadcrumbs:
  - /gateway/

related_resources:
  - text: Security in {{site.base_gateway}}
    url: /gateway/security/
  - text: "{{site.base_gateway}} version support policy"
    url: /gateway/version-support-policy/
  - text: Common Vulnerability Scoring System
    url: https://www.first.org/cvss/

works_on:
  - on-prem
  - konnect
---

{{site.base_gateway}} is primarily delivered as [DEB, RPM, and APK](/gateway/version-support-policy/#supported-versions) installable artifacts. 
Kong also offers Docker images with the artifacts preinstalled as a convenience to customers. 
At the time of release, all artifacts and images are patched, scanned and are free of publicly-known vulnerabilities. 

## Types of vulnerabilities

Generally, there may be three types of vulnerabilities:
* In {{site.base_gateway}} code
* In third-party code that {{site.base_gateway}} directly links (such as OpenSSL, glibc, libxml2)
* In third-party code that is part of the convenience Docker image (such as Python, Perl, cURL, etc). This code is not part of {{site.base_gateway}}.

Vulnerabilities reported in {{site.base_gateway}} code will be assessed by Kong and if the vulnerability is validated, a [CVSS 3.0](https://www.first.org/cvss/) score will be assigned. 
Based on the CVSS score, Kong will aim to produce patches for all applicable {{site.base_gateway}} versions currently under support within the SLAs below. 
The SLA clock starts from the day the CVSS score is assigned.

For a CVSS 3.0 Critical vulnerability (CVSS > 9.0), Kong will provide a workaround/recommendation as soon as possible.
This will take the shape of a configuration change recommendation, if available. 
If there is no workaround/recommendation readily available, Kong will use continuous efforts to develop one.
For a CVSS <9.0, Kong will use commercially-reasonable efforts to provide a workaround or patch within the applicable SLA period.

<!--vale off-->
{% table %}
columns:
  - title: "CVSS 3.0 Criticality for Kong code"
    key: criticality
  - title: "CVSS 3.0 Score"
    key: score
  - title: SLA
    key: sla
rows:
  - criticality: Critical
    score: "9.0 - 10.0"
    sla: "15 days"
  - criticality: High
    score: "7.0 - 8.9"
    sla: "30 days"
  - criticality: Medium
    score: "4.0 - 6.9"
    sla: "90 days"
  - criticality: Low
    score: "0.1 - 3.9"
    sla: "180 days"
{% endtable %}
<!--vale on-->


Vulnerabilities reported in third party-code that {{site.base_gateway}} links directly must have confirmed CVE numbers assigned. 
Kong will aim to produce patches for all applicable {{site.base_gateway}} versions currently under support within the SLA reproduced in the table below. 
The SLA clock for these vulnerabilities starts from the day the upstream (third party) announces availability of patches.  

<!--vale off-->
{% table %}
columns:
  - title: "CVSS 3.0 Criticality for third-party code"
    key: criticality
  - title: "CVSS 3.0 Score"
    key: score
  - title: SLA
    key: sla
rows:
  - criticality: Critical
    score: "9.0 - 10.0"
    sla: "15 days"
  - criticality: High
    score: "7.0 - 8.9"
    sla: "30 days"
  - criticality: Medium
    score: "4.0 - 6.9"
    sla: "90 days"
  - criticality: Low
    score: "0.1 - 3.9"
    sla: "180 days"
{% endtable %}
<!--vale on-->


Vulnerabilities reported in third-party code that is part of the convenience Docker images are only addressed by Kong as part of the regularly scheduled release process. 
These vulnerabilities are not exploitable during normal {{site.base_gateway}} operations. 
Kong always applies all available patches when releasing a Docker image, but by definition images accrue vulnerabilities over time. 

All customers using containers are strongly urged to generate their own images using their secure corporate approved base images.
Customers wishing to use the convenience images from Kong should always apply the latest patches for their Gateway version to receive the latest patched container images. 
Kong does not undertake to address third-party vulnerabilities in convenience images outside of the scheduled release mechanism.

## Reporting vulnerabilities in Kong code

If you are reporting a vulnerability in Kong code, we request you to follow the instructions in the [Kong Vulnerability Disclosure Program](https://konghq.com/compliance/bug-bounty). 
