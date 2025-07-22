---
title: "Advanced Analytics Explorer"
content_type: reference
layout: reference
description: | 
    Explorer is an intuitive web-based interface that displays API usage data gathered by {{site.konnect_short_name}} Analytics from your Data Plane nodes. You can use this tool to promptly diagnose performance issues, monitor LLM token consumption and costs, or capture essential usage metrics. 
breadcrumbs:
  - /advanced-analytics/
products:
    - gateway
    - advanced-analytics
tags:
  - analytics
works_on:
    - konnect
api_specs:
    - konnect/analytics-requests
schema:
    api: konnect/analytics-requests
faqs:
  - q: What data can I collect Analytics from?
    a: |
        * **API**
        * **API Product**
        * **API Product Version**
        * **Application**
        * **Consumer**
        * **Control Plane**
        * **Control Plane Group**
        * **Data Plane Node**
        * **Data Plane Node Version**
        * **Gateway Services**
        * **Response Source**
        * **Portal**
        * **Route**
        * **Status Code**
        * **Status Code Group**
        * **Upstream Status Code**
        * **Upstream Status Code Group**
  - q: What does "None" mean in Advanced Analytics?
    a: |
      "None" is a field that can capture data that doesn't belong to a specific category.
  - q: What can I do after customizing an Explorer dashboard?
    a: |
        * **Save as a Report**: This function creates a new custom report based on your current view, allowing you to revisit these specific insights at a later time.
        * **Export as CSV**: If you prefer to analyze your data using other tools, you can download the current view as a CSV file, making it portable and ready for further analysis elsewhere.    
related_resources:
  - text: Konnect Advanced Analytics
    url: /advanced-analytics/
  - text: LLM Reporting
    url: /advanced-analytics/llm-reporting/
  - text: Dev Portal analytics
    url: /dev-portal/analytics/
---

The Explorer interface displays API usage data gathered by {{site.konnect_short_name}} Analytics from your Data Plane nodes. You can use this tool to:
* Diagnose performance issues
* [Monitor LLM token consumption and costs](/advanced-analytics/llm-reporting/)
* Capture essential usage metrics

The Analytics Explorer also lets you save the output as a custom report.

## Enabling data ingestion

Manage data ingestion from any **Control Plane Dashboard** using the **Advanced Analytics** toggle. 
This toggle lets you enable or disable data collection for your API traffic per Control Plane.

**Modes:**
- **On:** Both basic and advanced analytics data is collected, allowing in-depth insights and reporting.
- **Off:** Advanced analytics collection stops, but basic API metrics remain available in Gateway Manager, 
and can still be used for custom reports.

## Metrics

Traffic metrics provide insight into which of your Services are being used and how they are responding. 
Within a single report, you have the flexibility to choose one or multiple metrics from the same category.

<!--vale off-->
{% table %}
columns:
  - title: "Metric"
    key: "metric"
  - title: "Category"
    key: "category"
  - title: "Description"
    key: "description"
rows:
  - metric: "Request Count"
    category: "Count"
    description: |
      Total number of API calls within the selected time frame. This includes requests that were rejected due to rate limiting, failed authentication, and so on.
  - metric: "Requests per Minute"
    category: "Rate"
    description: |
      Number of API calls per minute within the selected time frame.
  - metric: "Response Latency"
    category: "Latency"
    description: |
      The time, in milliseconds, it takes to process an API request from start to finish. Users can choose from average (avg) or specific percentiles (p99, p95, and p50). For example, a 99th percentile response latency of 10 milliseconds means that 99 out of 100 requests were completed in under 10 ms from the time the request was received to when the response was sent.
  - metric: "Upstream Latency"
    category: "Latency"
    description: |
      The amount of time, in milliseconds, that {{site.base_gateway}} was waiting for the first byte of the upstream service response. Users can select between different percentiles (p99, p95, and p50). For example, a 99th percentile latency of 10 milliseconds means that 99 out of 100 requests took less than 10 ms from the moment the request was sent to the upstream service to when the first byte of the response was received.
  - metric: "Kong latency"
    category: "Latency"
    description: |
      The time, in milliseconds, spent within {{site.base_gateway}} processing a request, excluding upstream response time. Users can choose from different percentiles (p99, p95, and p50). For example, a 99th percentile Kong latency of 10 milliseconds means that 99 out of 100 requests took less than 10 ms to be processed in {{site.base_gateway}} before reaching the upstream service.
  - metric: "Request Size"
    category: "Size"
    description: |
      The size of the request payload received from the client, in bytes. Users can select between the total sum or different percentiles (p99, p95, and p50). For example, a 99th percentile request size of 100 bytes means that the payload size for every 1 in 100 requests was at least 100 bytes.
  - metric: "Response Size"
    category: "Size"
    description: |
      The size of the response payload returned to the client, in bytes. Users can select between the total sum or different percentiles (p99, p95, and p50). For example, a 99th percentile response size of 100 bytes means that the payload size for every 1 in 100 response back to the original caller was at least 100 bytes.
{% endtable %}
<!--vale on-->

## Time intervals

{% include_cached /konnect/analytics-intervals.md %}

## System-defined groups

`Empty` is an optional, system-defined group that indicates that API calls don't have an entity like [Consumers](/gateway/entities/consumer/) or [Routes](/gateway/entities/route), selected for grouping. `Empty` allows you to group API calls that don't match specific groupings so you can gain more comprehensive insights. You can filter by `Is Empty` or `Is Not Empty`. 

Some common use cases for `Empty` include:
* Identifying the number of API calls that don't match a Route.
* Identifying API calls without an associated Consumer to keep track of any security holes.
