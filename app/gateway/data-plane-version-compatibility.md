---
title: Version compatibility in control planes
content_type: reference
layout: reference
breadcrumbs: 
  - /konnect/
products:
  - gateway
works_on:
  - konnect
tags:
  - gateway-manager
  - troubleshooting

description: Running multiple versions of data plane nodes with a single control plane can cause version compatibility issues.

related_resources:
  - text: "{{site.base_gateway}} logs"
    url: /gateway/logs/
#  - text: "{{site.base_gateway}} debugging"
#    url: /gateway/debug/
  - text: "{{site.konnect_short_name}} compatibility"
    url: /konnect-platform/compatibility/
---

We recommend running one major version (2.x or 3.x) of a data plane node per control plane, unless you are in the middle of version upgrades to the data plane.

If you mix major data plane node versions, the control plane will support the least common subset of configurations across all the versions connected to the {{site.konnect_short_name}} control plane.
For example, if you are running 2.8.1.3 on one data plane node and 3.0.0.0 on another, the control plane will only push configurations that can be used by the 2.8.1.3 data plane node.

If you experience compatibility errors, [upgrade your data plane nodes](/gateway/data-plane-reference/#upgrade-data-planes) to match the version of the highest-versioned data plane node in your control plane.

## Compatibility status

{{site.konnect_short_name}} Gateway Manager displays a **Compatibility status** badge for each data plane node. To see it, go to **Gateway Manager**, select a control plane, and open the **Data plane Nodes** list page. The **Compatibility status** column shows one of the following statuses:

{% table %}
columns:
  - title: Status
    key: status
  - title: Description
    key: description
rows:
  - status: Compatible
    description: This data plane node supports the configuration from the control plane.
  - status: Compatible with limitations
    description: This data plane node is operating normally, but some newer features may be limited because of its Kong Gateway version.
  - status: Incompatible
    description: This data plane node has compatibility issues that may prevent it from receiving or applying the full control plane configuration.
  - status: Unknown
    description: Konnect can't determine the compatibility status for this data plane node. Check the node connection and Kong Gateway version.
{% endtable %}

## Compatibility errors

The following table defines the possible compatibility errors with {{site.konnect_short_name}} data plane nodes:

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
