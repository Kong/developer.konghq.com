---
title: "Advanced Analytics Explorer"
content_type: reference
layout: reference
description: | 
    Explorer is an intuitive web-based interface that displays API usage data gathered by Konnect Analytics from your data plane nodes. You can use this tool to promptly diagnose performance issues, monitor LLM token consumption and costs, or capture essential usage metrics. 


products:
    - gateway
works_on:
    - konnect
api_specs:
    - konnect/analytics-requests
schema:
    api: konnect/analytics-requests
faqs:
  - q: What data can I collect Analytics from?
    a: |
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
        * **Route**
        * **Status Code**
        * **Status Code Group**
        * **Upstream Status Code**
        * **Upstream Status Code Group**
  - q: What does "None" mean?
    a: |
      "None" is a field that can capture data that does belong to a specific category.
  - q: What can I do after customizing an Explorer dashboard?
    a: |
        * **Save as a Report**: This function creates a new custom report based on your current view, allowing you to revisit these specific insights at a later time.
        * **Export as CSV**: If you prefer to analyze your data using other tools, you can download the current view as a CSV file, making it portable and ready for further analysis elsewhere.    
related_resources:
  - text: Konnect Advanced Analytics
    url: /advanced-analytics/
  - text: LLM Reporting
    url: /advanced-analytics/llm-reporting/
---

The Explorer interface displays API usage data gathered by {{site.konnect_short_name}} Analytics from your data plane nodes. You can use this tool to:
* Diagnose performance issues
* [Monitor LLM token consumption and costs](/advanced-analytics/llm-reporting/)
* Capture essential usage metrics

Explorer also allows you to save the output as custom reports.
## Metrics


Traffic metrics provide insight into which of your services are being used and how they are responding. Within a single report, you have the flexibility to choose one or multiple metrics from the same category.

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
      The amount of time, in milliseconds, that it takes to process an API request. Users can select between average (avg) or different percentiles (p99, p95, and p50). For example, a 99th percentile response latency of 10 milliseconds means that every 1 in 100 requests took at least 10 milliseconds from request received until response returned.
  - metric: "Upstream Latency"
    category: "Latency"
    description: |
      The amount of time, in milliseconds, that {{site.base_gateway}} was waiting for the first byte of the upstream service response. Users can select between different percentiles (p99, p95, and p50). For example, a 99th percentile response latency of 10 milliseconds means that every 1 in 100 requests took at least 10 milliseconds from sending the request to the upstream service until the response returned.
  - metric: "Kong latency"
    category: "Latency"
    description: |
      The amount of time, in milliseconds, that {{site.base_gateway}} was waiting for the first byte of the upstream service response. Users can select between different percentiles (p99, p95, and p50). For example, a 99th percentile response latency of 10 milliseconds means that every 1 in 100 requests took at least 10 milliseconds from the time the {{site.base_gateway}} received the request up to when it sends it back to the upstream service.
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


## Time Intervals

The time frame selector controls the time frame of data visualized, which indirectly controls the
granularity of the data. For example, the “5M” selection displays five minutes in
one-second resolution data, while longer time frames display minute, hour, or days resolution data.

All time interval presets are **relative**. This means that time frames are dynamic and the report captures a snapshot of data
relative to when a user views the report.
For custom reports, you can also choose a **custom** date range. Custom means that time frames are static and the report captures a snapshot of data
during the specified time frame. You can see the exact range below
the time frame selector. For example:

    
    Jan 26, 2023 12:00 AM - Feb 01, 2023 12:00 AM (PST)
    

The following table describes the time intervals you can select:

<!--vale off-->
{% table %}
columns:
  - title: "Interval"
    key: "interval"
  - title: "Aggregation increment frequency"
    key: "aggregation_increment_frequency"
  - title: "Notes"
    key: "notes"
rows:
  - interval: "Last 15 minutes"
    aggregation_increment_frequency: "1 minute"
    notes: "Data is aggregated in one minute increments."
  - interval: "Last hour"
    aggregation_increment_frequency: "1 minute"
    notes: "Data is aggregated in one minute increments."
  - interval: "Last six hours"
    aggregation_increment_frequency: "1 minute"
    notes: "Data is aggregated in one minute increments."
  - interval: "Last 12 hours"
    aggregation_increment_frequency: "1 hour"
    notes: "Data is aggregated in one hour increments."
  - interval: "Last 24 hours"
    aggregation_increment_frequency: "1 hour"
    notes: "Data is aggregated in one hour increments."
  - interval: "Last seven days"
    aggregation_increment_frequency: "1 hour"
    notes: "Data is aggregated in one hour increments."
  - interval: "Last 30 days"
    aggregation_increment_frequency: "Daily"
    notes: "Data is aggregated in daily increments."
  - interval: "Current week"
    aggregation_increment_frequency: "1 hour"
    notes: "Logs any traffic in the current calendar week."
  - interval: "Current month"
    aggregation_increment_frequency: "1 hour"
    notes: "Logs any traffic in the current calendar month."
  - interval: "Previous week"
    aggregation_increment_frequency: "1 hour"
    notes: "Logs any traffic in the previous calendar week."
  - interval: "Previous month"
    aggregation_increment_frequency: "Daily"
    notes: "Logs any traffic in the previous calendar month."
{% endtable %}
<!--vale on-->


## System defined groups

Empty is an optional, system-defined group that indicates that API calls don't have an entity like [Consumers](/gateway/entities/consumer/) or [Routes](/gateway/entities/route), selected for grouping. Empty allows you to group API calls that don't match specific groupings so you can gain more comprehensive insights. You can filter by `Is Empty` or `Is Not Empty`. 

Empty can be used in cases like this: 
* Identify the number of API calls that don't match a Route.
* Identify API calls without an associated Consumer to keep track of any security holes.
