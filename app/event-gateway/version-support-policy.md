---
title: "{{site.event_gateway}} version support policy"
content_type: policy
layout: reference

products:
  - event-gateway

breadcrumbs:
  - /event-gateway/

description: |
  The {{site.event_gateway}} version support policy outlines the {{site.event_gateway}} versioning scheme and lifecycle, from release to sunset support.

related_resources:
  - text: "{{site.event_gateway}}"
    url: /event-gateway/
  - text: "{{site.base_gateway}} version support policy"
    url: /gateway/version-support-policy/
  - text: "{{site.konnect_short_name}} compatibility and support policy"
    url: /konnect-platform/compatibility/
  - text: "Kong vulnerability patching process"
    url: /gateway/vulnerabilities/

works_on:
  - konnect
---

The policy only applies to {{site.event_gateway}}.  
See the [{{site.base_gateway}} support policy](/gateway/version-support-policy/) and the [{{site.konnect_short_name}} support policy](/konnect-platform/compatibility/) for information specific to those products.


## Versioning

Kong adopts a structured approach to versioning its products.  
Products follow a pattern of `{MAJOR}.{MINOR}.{PATCH}`.

For the purposes of this support document: 

**Versioning**:
  * **Major Version** means a version identified by the number to the left of the leftmost decimal point (X.y.z). For example, 2.1.3 indicates Major Version 2 and 1.3.0 indicates Major Version 1.
  
  * **Minor Version** means a version identified by a change in the number in between the two leftmost decimal points (x.Y.z). For example, 2.1.3 indicates Minor Version 1 and 1.3.0 indicates Minor Version 3.
  * **Patch Version** means a version identified by a change in the number to the right of the rightmost decimal (x.y.Z). Example: `2.1.3` indicates patch version `3`.


There is no community edition of {{site.event_gateway}}, and therefore no difference between enterprise and community patches.

### Major version release
Kong introduces major functionality and breaking changes by releasing a new **major version**. Major releases happen rarely and are usually prompted by:
* major industry shifts,
* significant architectural changes, or
* internal product innovation.  

There is no regular cadence of major versions.

Kong aims to release a new **minor version approximately every 12 weeks**.  
Minor versions contain features and bug fixes and are usually backwards compatible within their major version sequence.

Each minor version is supported for **1 year** from its release date.  
Patches are cumulative ("rolled-up"), meaning that a release such as `3.3.5` includes fixes from `3.3.4`, `3.3.3`, `3.3.2`, and `3.3.1`.


## Long-term support (LTS) {#long-term-support}

Kong may designate a specific minor version as a **Long-Term Support (LTS)** version.  
LTS releases receive full support for the **shorter** of either:

* 3 years from the LTS release date 
* the lifecycle of the underlying distribution.

An LTS version is backwards compatible within its major version and receives all security fixes, as well as select non-security patches at Kong’s discretion.

* **{{site.event_gateway}} does not have an LTS release.**  
* Each release starting from `1.0` will have a **1-year support period**.  
* Kong may designate an {{site.event_gateway}} LTS release in the future.



## Sunset support

After the product reaches end of support, Kong provides **limited support** for up to **12 months** to help customers upgrade to a supported version.  
During this sunset period:
* No patches are released.
* If an issue requires a patch, customers must upgrade to a newer supported version.


## Bug fix guidelines

Kong follows a structured process for addressing bugs:

* **Security vulnerabilities:**  
  Treated with highest priority.  
  See the [security vulnerability policy](/gateway/vulnerabilities/) for reporting and resolution procedures.

* **Critical bugs (e.g. production outages or catastrophic degradation):**  
  Fixed with **high-priority patches** to the latest major/minor release of all currently supported versions.  
  Fixes may be backported at Kong’s discretion.

* **Other bugs and feature requests:**  
  Assessed for severity and impact. Fixes are generally applied only to the **latest minor version** of the **latest major release**.

> Customers with Enterprise Platinum or higher subscriptions may request special-case fixes outside this process; such requests are evaluated at Kong’s discretion.



## Deprecation guidelines

From time to time, Kong may deprecate or remove product features as part of {{site.event_gateway}}’s evolution.

* Kong aims to provide **at least 6 months’ notice** before removing or phasing out a significant feature.  
* Less or no notice may be given if the change is required for **security or legal reasons** (rare).  
* Notices may appear in:
  * Documentation
  * Release notes
  * Product update emails
  * In-product notifications

Once a feature is announced as deprecated, it will not receive new enhancements or extensions.

## Additional terms

This policy is a **summary** and is qualified by the broader [Kong Support and Maintenance Policy](https://konghq.com/legal/kong-support-and-maintenance-policy).


## Release timeline
<!--vale off-->
{% table %}
columns:
  - title: Version
    key: version
  - title: Release Date
    key: release
  - title: End of Full Support
    key: full_support
  - title: End of Sunset Support
    key: sunset
rows:
  - version: "1.0"
    release: "2025-11-06"
    full_support: "2026-11-06"
    sunset: "2027-11-06"
{% endtable %}
<!--vale on-->