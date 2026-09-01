---
title: "{{site.ai_gateway}} version support policy"
content_type: policy
layout: reference

products:
  - ai-gateway

breadcrumbs:
  - /ai-gateway/
tags:
  - versioning

description: |
  The {{site.ai_gateway}} version support policy outlines the {{site.ai_gateway}} versioning scheme and version lifecycle, from release to sunset support.

related_resources:
  - text: "{{site.base_gateway}} support policy"
    url: /gateway/version-support-policy/
  - text: "{{site.konnect_short_name}} support policy"
    url: /konnect-platform/compatibility/
  - text: Kong vulnerability patching process
    url: /gateway/vulnerabilities/
  - text: "{{site.ai_gateway}} changelog"
    url: /ai-gateway/changelog/

works_on:
  - on-prem
  - konnect

toc_depth: 3
---

This page describes the {{site.ai_gateway}} version support policy, including versioning, bug fix, and deprecation guidelines.

This policy only applies to {{site.ai_gateway_name}}. See the [{{site.base_gateway}} support policy](/gateway/version-support-policy/) and the [{{site.konnect_short_name}} support policy](/konnect-platform/compatibility/) for information specific to those products.

## Versioning

Kong adopts a structured approach to versioning its products. Products follow a pattern of `{MAJOR}.{MINOR}.{PATCH}`.

For the purposes of this support document:

**Versioning**:

* **Major Version** means a version identified by the number to the left of the leftmost decimal point (X.y.z). For example, 2.1.3 indicates Major Version 2 and 1.3.0 indicates Major Version 1.  
    
* **Minor Version** means a version identified by a change in the number in between the two leftmost decimal points (x.Y.z). For example, 2.1.3 indicates Minor Version 1 and 1.3.0 indicates Minor Version 3.  
    
* **Patch Version** means a version identified by a change in the number to the right of the rightmost decimal (x.y.Z). For example, `2.1.3` indicates patch version `3`.

### Major version release

Kong introduces major functionality and breaking changes by releasing a new **major version**. 
Major releases happen rarely and are usually prompted by one or more of:

* Major industry shifts
* Significant architectural changes
* Internal product innovation

There is no regular cadence of major versions.

### Minor version release

Kong aims to release a new **minor version approximately every 4 weeks**.

Minor versions contain features and bug fixes and are usually backwards compatible within their major version sequence.

We will be supporting the **two most recent minor versions** of {{site.ai_gateway_name}}.

### Patch release

Patches are cumulative ("rolled-up"), meaning that a release such as `2.1.3` includes fixes from `2.1.2`, `2.1.1`, and `2.1.0`.

Due to the frequent iteration of the {{site.ai_gateway_name}} and the fast pace of the AI ecosystem generally, Kong does not provide a long-term support (LTS) version of the {{site.ai_gateway_name}}.

## Bug fix guidelines

Kong follows a structured process for addressing bugs:

* **Security vulnerabilities:** 
  
  Treated with highest priority. See the [security vulnerability policy](/gateway/vulnerabilities/) for reporting and resolution procedures.  
    
* **Critical bugs:** 
  
  Fixed with **high-priority patches** to the latest major/minor release of all currently supported versions. This includes things such as production outages or catastrophic degradation.
    
* **Other bugs and feature requests:** 
  
  Assessed for severity and impact. Fixes are generally applied only to the **latest minor version** of the **latest major release**.

{:.info}
> Customers with Enterprise Platinum or higher subscriptions may request special-case fixes outside this process; such requests are evaluated at Kong's discretion.

## Deprecation guidelines

From time to time, as part of the evolution of our products, we deprecate (in other words, remove or discontinue) product features or functionality.

We aim to provide customers with at least 6 months' notice of the removal or phasing out of a significant feature or functionality. 
We may provide less or no notice if the change is necessary for security or legal reasons, though such situations should be rare. 
We may provide notice in our documentation, product update emails, or in-product notifications if applicable.

Once we have announced that we will deprecate a significant feature or functionality, in general, we won’t extend or enhance the feature or functionality.

## Additional terms

This policy is a **summary** and is qualified by the broader [Kong Support and Maintenance Policy](https://konghq.com/legal/kong-support-and-maintenance-policy).

## Release timeline

The following {{site.ai_gateway_name}} versions are currently supported by Kong:

{% assign supported_releases = site.data.products.ai-gateway.releases | reverse | where: "label", empty | where_exp: "release", "release.version" | slice: 0, 2 %}

{% table %}
columns:
  - title: Version
    key: version
  - title: Release date
    key: date
rows:
{%- for release in supported_releases %}
{%- assign release_date = site.data.products.ai-gateway.release_dates[release.version] | split: '/' | join: '-' %}
  - version: "{{ release.release }}.x"
    date: "{{ release_date }}"
{%- endfor %}
{% endtable %}