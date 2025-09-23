---
title: Version compatibility in Control Planes
content_type: reference
layout: reference
breadcrumbs: 
  - /gateway-manager/
products:
  - gateway
works_on:
  - konnect
tags:
  - gateway-manager
  - troubleshooting

description: Running multiple versions of Data Plane nodes with a single Control Plane can cause version compatibility issues.

related_resources:
  - text: "{{site.base_gateway}} logs"
    url: /gateway/logs/
#  - text: "{{site.base_gateway}} debugging"
#    url: /gateway/debug/
  - text: "{{site.konnect_short_name}} compatibility"
    url: /konnect-platform/compatibility/
---

We recommend running one major version (2.x or 3.x) of a Data Plane node per Control Plane, unless you are in the middle of version upgrades to the Data Plane.

If you mix major Data Plane node versions, the Control Plane will support the least common subset of configurations across all the versions connected to the {{site.konnect_short_name}} Control Plane.
For example, if you are running 2.8.1.3 on one Data Plane node and 3.0.0.0 on another, the Control Plane will only push configurations that can be used by the 2.8.1.3 Data Plane node.

If you experience compatibility errors, [upgrade your Data Plane nodes](/gateway-manager/data-plane-reference/#upgrade-data-planes) to match the version of the highest-versioned Data Plane node in your Control Plane.

The following table defines the possible compatibility errors with {{site.konnect_short_name}} Data Plane nodes:

{% assign errors = site.data.version_errors_konnect %}

{% table %}
columns:
  - title: Error code
    key: error
  - title: Severity
    key: severity
  - title: Description
    key: description
  - title: Resolution
    key: resolution
  - title: References
    key: references
rows:
{% for message in errors.messages %}
  - error: {{ message.ID }}
    severity: {{ message.Severity }}
    description: "{{ message.Description}}"
    resolution: "{{ message.Resolution }}"
    references: "{{ message.DocumentationURL }}"
{% endfor %}
{% endtable %}
