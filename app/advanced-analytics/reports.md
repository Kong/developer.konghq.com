---
title: "custom reports"
content_type: reference
layout: reference
description: | 
    custom reports reference

no_version: true
products:
    - gateway
works_on:
    - konnect
api_specs:
    - konnect/analytics-requests
related_resources:
  - text: Konnect Advanced Analytics
    url: /advanced-analytics/
  - text: Explorer Reference
    url: /advanced-analytics/explorer/
schema:
    api: konnect/analytics-requests

---
@todo

Pull content from https://docs.konghq.com/konnect/analytics/dashboard/


This is still placeholder text


Data ingestion is managed from the **Control Plane Dashboard** using the analytics toggle. 
This feature allows you to enable or disable data collection for your API traffic per control plane.

**Modes:**
- **On:** Both basic and advanced analytics data is collected, allowing in-depth insights and reporting.
- **Off:** Advanced analytics collection stops, but basic API metrics remain available in Gateway Manager.

**Note:** If analytics is disabled, new data will not appear in [Custom Reports](/konnect/analytics/custom-reports/) 
or [API Requests](/konnect/analytics/api-requests/), but basic usage stats will still be accessible.


You can assign users to predefined **Analytics teams** in {{site.konnect_short_name}} to control access levels. 
This allows specific users to **view** or **manage** Analytics independently.

Learn more in the [Teams Reference](/konnect-platform/teams-and-roles/).