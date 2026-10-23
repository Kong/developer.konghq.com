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
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/
  - text: "{{site.base_gateway}} version support policy"
    url: /gateway/version-support-policy/
  - text: "{{site.konnect_short_name}} compatibility and support policy"
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

* **Major Version** means a version identified by the number to the left of the leftmost decimal point (X.y.z). For example, `2.1.3` indicates Major Version `2` and `1.3.0` indicates Major Version `1`.  
    
* **Minor Version** means a version identified by a change in the number in between the two leftmost decimal points (x.Y.z). For example, `2.1.3` indicates Minor Version `1` and `1.3.0` indicates Minor Version `3`.  
    
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

### Rolling and stable releases

To support both rapid innovation and stability, {{site.ai_gateway_name}} offers two support tracks:

* **Rolling releases** are supported for **1 month**.
* **Stable releases** are supported for **6 months**. Kong aims to designate a new stable release once per quarter, which means **2 stable releases** are generally maintained at any point in time.

Kong may require that the customer upgrade to the most current released minor or stable version to receive a technical fix.

A stable release is a specific minor version that Kong designates as stable at the time it is declared. It follows the same `{MAJOR}.{MINOR}.{PATCH}` versioning scheme as rolling releases.

Patches are cumulative ("rolled-up"), meaning that a release such as `2.1.3` includes fixes from `2.1.2`, `2.1.1`, and `2.1.0`.

#### Sunset support

After the support period ends, Kong provides limited support for 1 month on rolling releases and 3 months on stable releases to help customers upgrade to a fully supported version of {{site.ai_gateway_name}}.

Kong will not provide patches for software covered by this sunset period. If there is an issue that requires a patch during this period, the customer will need to upgrade to a newer {{site.ai_gateway_name}} version covered by active support.

## Supported versions

Kong supports the following versions of {{site.ai_gateway_name}}:

{% navtabs "ai-gateway-version" %}
<!-- TODO: confirm 2.3 release date, EOL date, and release track (rolling/stable) before publishing -->
{% navtab "2.3" %}
{{site.ai_gateway_name}} 2.3 was released on <!-- TODO: release date -->.

{{site.ai_gateway_name}} 2.3 supports the following deployment targets until <!-- TODO: EOL date -->, unless otherwise noted by an earlier OS vendor end of life (EOL) date.

<!--vale off-->
{% table %}
columns:
  - title: OS
    key: os
  - title: Version
    key: version
  - title: ARM support
    key: arm
  - title: FIPS 140-3
    key: fips
  - title: EOL
    key: eol
rows:
  - os: Ubuntu
    version: "26.04"
    arm: true
    fips: true
    eol: "<!-- TODO: EOL date -->"
  - os: RHEL
    version: "10.x"
    arm: true
    fips: true
    eol: "<!-- TODO: EOL date -->"
  - os: Distroless
    version: "N/A"
    arm: true
    fips: true
    eol: "<!-- TODO: EOL date -->"
{% endtable %}
<!--vale on-->
{% endnavtab %}
{% navtab "2.2 (stable)" %}
{{site.ai_gateway_name}} 2.2 was released on 2026-09-30.

{{site.ai_gateway_name}} 2.2 supports the following deployment targets until 2027-03-30, unless otherwise noted by an earlier OS vendor end of life (EOL) date.

<!--vale off-->
{% table %}
columns:
  - title: OS
    key: os
  - title: Version
    key: version
  - title: ARM support
    key: arm
  - title: FIPS 140-3
    key: fips
  - title: EOL
    key: eol
rows:
  - os: Ubuntu
    version: "24.04"
    arm: true
    fips: true
    eol: "2027-03-30"
  - os: RHEL
    version: "9.x"
    arm: true
    fips: true
    eol: "2027-03-30"
  - os: Distroless
    version: "N/A"
    arm: true
    fips: true
    eol: "2027-03-30"
{% endtable %}
<!--vale on-->
{% endnavtab %}
{% navtab "2.1" %}
{{site.ai_gateway_name}} 2.1 was released on 2026-09-24.

{{site.ai_gateway_name}} 2.1 supports the following deployment targets until 2026-10-24, unless otherwise noted by an earlier OS vendor end of life (EOL) date.

<!--vale off-->
{% table %}
columns:
  - title: OS
    key: os
  - title: Version
    key: version
  - title: ARM support
    key: arm
  - title: FIPS 140-3
    key: fips
  - title: EOL
    key: eol
rows:
  - os: Ubuntu
    version: "24.04"
    arm: true
    fips: true
    eol: "2026-10-24"
  - os: RHEL
    version: "9.x"
    arm: true
    fips: true
    eol: "2026-10-24"
  - os: Distroless
    version: "N/A"
    arm: true
    fips: true
    eol: "2026-10-24"
{% endtable %}
<!--vale on-->
{% endnavtab %}
{% endnavtabs %}

{:.info .no-icon}
> **Notes**:
> * **OS End of Life**: If you're running a currently supported version of {{site.ai_gateway_name}} on an OS that doesn't appear in this table, that OS has reached End of Life and Kong no longer supports it.
> * **ARM support**: Packages and Docker images are available for both AMD64 (x86_64) and ARM64 (aarch64). Docker images are multi-architecture.
> * **FIPS mode**: FIPS 140-3 packages and Docker images are only available for AMD64. ARM64 is not supported.

## Older versions

The following versions of {{site.ai_gateway_name}} have reached the end of full support:

<!--vale off-->
{% table %}
columns:
  - title: Version
    key: version
  - title: Released date
    key: release_date
  - title: End of support
    key: eol
  - title: End of sunset support
    key: sunset
rows:
  - version: "2.0"
    release_date: "2026-08-31"
    eol: "2026-09-30"
    sunset: "2026-10-31"
{% endtable %}
<!--vale on-->

## Bug fix guidelines

Kong follows a structured process for addressing bugs:

* **Security vulnerabilities:** 
  
  Treated with highest priority. See the [security vulnerability policy](/gateway/vulnerabilities/) for reporting and resolution procedures.  
    
* **Critical bugs:** 
  
  Fixed with **high-priority patches** to the latest rolling release and to all currently supported stable releases. This includes things such as production outages or catastrophic degradation.
    
* **Other bugs and feature requests:** 
  
  Assessed for severity and impact. Fixes are generally applied only to the **latest rolling release**. Backports to a currently supported stable release are evaluated case by case.

{:.info}
> Customers with platinum or higher subscriptions may request fixes outside of the above and Kong will assess them at its sole discretion.

## Deprecation guidelines

From time to time, as part of the evolution of our products, we deprecate (in other words, remove or discontinue) product features or functionality.

We aim to provide customers with at least 6 months' notice of the removal or phasing out of a significant feature or functionality. 
We may provide less or no notice if the change is necessary for security or legal reasons, though such situations should be rare. 
We may provide notice in our documentation, product update emails, or in-product notifications if applicable.

Once we have announced that we will deprecate a significant feature or functionality, in general, we won’t extend or enhance the feature or functionality.

## Additional terms

This policy is a **summary** and is qualified by the broader [Kong Support and Maintenance Policy](https://konghq.com/legal/kong-support-and-maintenance-policy).
