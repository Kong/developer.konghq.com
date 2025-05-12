---
title: "{{site.konnect_short_name}} Data Plane logs"
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
search_aliases: 
  - data plane logs

description: "Review logs for Data Plane activity in {{site.konnect_short_name}}."
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

Data Plane logs provide users with the ability to view, filter, search, and download logs for the Data Plane nodes associated with a Dedicated Cloud Gateway.
Reviewing logs is essential for debugging, monitoring, and understanding the behavior of Data Plane nodes.

## Log management in Gateway Manager

You can access Data Plane logs from the Data Plane dashboard in [Gateway Manager](https://cloud.konghq.com/us/gateway-manager/).

From the Data Plane dashboard, you can perform the following actions:
{% table %}
columns:
  - title: Use Case
    key: feature
  - title: Description
    key: description
rows:
  - feature: View logs
    description: Access detailed logs for all Data Plane nodes in your gateway.
  - feature: Filter logs
    description: Type keywords or phrases in the **Filter Log Messages** box to refine log content.
  - feature: Download logs
    description: Click the download icon near the log table to save logs locally.
  - feature: Data Plane node selection
    description: Use the **Node ID** input box to view logs from a specific Data Plane node.
  - feature: Date range selection
    description: Use the date picker tool to specify a date range for logs.
  - feature: Group-specific logs
    description: Navigate to a specific Data Plane group within the Gateway Manager to view logs limited to that group.
{% endtable %}
