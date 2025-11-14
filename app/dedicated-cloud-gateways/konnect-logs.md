---
title: "Dedicated Cloud Gateway data plane logs"
content_type: reference
layout: reference
breadcrumbs: 
  - /konnect/
products:
    - gateway
works_on:
  - konnect

tags:
  - logging
  - dedicated-cloud-gateways
search_aliases: 
  - data plane logs

description: "Review logs for data plane activity in {{site.konnect_short_name}} Dedicated Cloud Gateways."
related_resources:
  - text: "Dedicated Cloud Gateways"
    url: /dedicated-cloud-gateways/
  - text: "{{site.base_gateway}} audit logs"
    url: /gateway/audit-logs/
  - text: "{{site.konnect_short_name}} audit logs"
    url: /konnect-platform/audit-logs/
  - text: "{{site.base_gateway}} logs"
    url: /gateway/logs/
---

Data plane logs provide users with the ability to view, filter, search, and download logs for the data plane nodes associated with a Dedicated Cloud Gateway.
Reviewing logs is essential for debugging, monitoring, and understanding the behavior of data plane nodes.

## Gateway log management in {{site.konnect_short_name}}

You can access data plane logs from the data plane dashboard in a Dedicated Cloud Gateway.

From the data plane dashboard, you can perform the following actions:
{% table %}
columns:
  - title: Use Case
    key: feature
  - title: Description
    key: description
rows:
  - feature: View logs
    description: Access detailed logs for all data plane nodes in your gateway.
  - feature: Filter logs
    description: Type keywords or phrases in the **Filter Log Messages** box to refine log content.
  - feature: Download logs
    description: Click the download icon near the log table to save logs locally.
  - feature: Data plane node selection
    description: Use the **Node ID** input box to view logs from a specific data plane node.
  - feature: Date range selection
    description: Use the date picker tool to specify a date range for logs.
  - feature: Group-specific logs
    description: Navigate to a specific data plane group within a control plane to view logs limited to that group.
{% endtable %}
