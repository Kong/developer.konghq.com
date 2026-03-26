---
title: "{{site.observability}} Explorer"
content_type: reference
layout: reference
description: | 
    Explorer is an intuitive web-based interface that displays API, LLM, and platform usage data gathered by {{site.konnect_short_name}} Analytics. You can use this tool to promptly diagnose performance issues, monitor LLM token consumption and costs, or capture essential usage metrics. 
breadcrumbs:
  - /observability/
products:
    - gateway
    - observability
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
  - q: What does "None" mean in {{site.observability}}?
    a: |
      "None" is a field that can capture data that doesn't belong to a specific category.
  - q: What can I do after customizing an Explorer dashboard?
    a: |
        * **Save as a Report**: This function creates a new custom report based on your current view, allowing you to revisit these specific insights at a later time.
        * **Export as CSV**: If you prefer to analyze your data using other tools, you can download the current view as a CSV file, making it portable and ready for further analysis elsewhere.
  - q: How do I check what location an API request is coming from?
    a: In the Analytics Explorer, you can view the geographic origin of API requests by using the country dimension and the map chart type. Navigate to Analytics → Explorer, select an API Usage report, then group or filter by Country. Switch the chart view to Map to see request volumes by country. The country information is added automatically by {{site.base_gateway}} using the IP‑to‑country database [IPinfo](https://ipinfo.io/developers/ip-to-country-database).
  - q: What interactions are available when working with charts to investigate my data?
    a: |
       Charts in {{site.konnect_short_name}} Analytics include interactive options to help you investigate data:
       - **Hover** over a chart to see a tooltip with exact values.
       - **Left-click** to pin the tooltip. This lets you scroll through long lists or drag the tooltip to a different spot.
       - **Click and drag** across the chart to highlight a time range. When you release, choose one of the following actions: 
            - **View requests**: Opens **Analytics > API Requests** with a filtered list of matching calls.
            - **Explore**: Opens Explorer with the same filters and highlighted time window, so you can add group-bys and extra filters.
            - **Zoom**: Focuses the chart on the selected time range.
       
       From the chart settings, you can do the following:
       - Open Explorer with the chart’s current filters and time range, by selecting **Explore**.
       - Download the chart view by selecting **Export CSV**. The file includes the current filters and time window.
  - q: Why don't I see any API requests in my chart?
    a: If you're sending requests from an internal IP address (local), those won't display in {{site.observability}} charts.

related_resources:
  - text: "{{site.konnect_short_name}} {{site.observability}}"
    url: /observability/
  - text: Dev Portal analytics
    url: /dev-portal/analytics/
---

The Explorer interface displays API, LLM, and platform usage data gathered by {{site.konnect_short_name}} Analytics. You can use this tool to:
* Diagnose performance issues
* Monitor LLM token consumption and costs
* Capture essential usage metrics
* See how many {{site.base_gateway}} entities exist in your platform or control plane

The Analytics Explorer also lets you save the output as a custom report.

To use this feature, navigate to the [Explorer dashboard](https://cloud.konghq.com/us/analytics/explorer) and switch between API usage, LLM usage, and platform usage using the dataset dropdown. 
Metrics and groupings will dynamically adjust based on the selected dataset.

## Enabling data ingestion

Manage data ingestion from any **Control Plane Dashboard** using the **Advanced Analytics** toggle. 
This toggle lets you enable or disable data collection for your API traffic per Control Plane.

**Modes:**
- **On:** Both basic and advanced analytics data is collected, allowing in-depth insights and reporting.
- **Off:** Advanced analytics collection stops, but basic API metrics remain available for API Gateway in {{site.konnect_short_name}}, 
and can still be used for custom reports. 

## Metrics

Traffic metrics provide insight into which of your services are being used and how they are responding. 
Within a single report, you have the flexibility to choose one or multiple metrics from the same category.

{% navtabs "metrics" %}
{% navtab "API usage" %}
With API usage reporting, you can:
* Identify which services are slow or have high error rates
* Monitor request volume and throughput over time
* Analyze payload sizes for clients and upstream services

The following table shows which API usage metrics you can view:
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
{% endnavtab %}
{% navtab "LLM usage" %}
{{site.observability}} allows you to monitor and optimize your LLM usage by providing detailed insights into objects such as token consumption, costs, and latency. 

With LLM usage reporting, you can:

* Track token consumption: Monitor the number of tokens processed by the different LLM models you have configured. 
* Understand costs: Gain visibility into the costs associated with your LLM providers. 
* Measure latency: Analyze the latency involved in processing LLM requests.

The following table shows which LLM usage metrics you can view:
<!--vale off-->
{% table %}
columns:
  - title: "Attribute"
    key: "attribute"
  - title: "Unit"
    key: "unit"
  - title: "Description"
    key: "description"
rows:
  - attribute: "Completion Tokens"
    unit: "Count"
    description: "Completion tokens are any tokens that the model generates in response to an input."
  - attribute: "Prompt Tokens"
    unit: "Count"
    description: "Prompt tokens are the number of tokens in the prompt that are input into the model."
  - attribute: "Total Tokens"
    unit: "Count"
    description: "Sum of all tokens used in a single request to the model. It includes both the tokens in the input (prompt) and the tokens generated by the model (completion)."
  - attribute: "Time per Tokens"
    unit: "Number"
    description: "Average time in milliseconds to generate a token. Calculated as LLM latency divided by the number of tokens."
  - attribute: "Costs"
    unit: "Cost"
    description: "Represents the resulting costs for a request. Final costs = (total number of prompt tokens × input cost per token) + (total number of completion tokens × output cost per token) + (total number of prompt tokens × embedding cost per token)."
  - attribute: "Response Model"
    unit: "String"
    description: "Represents which AI model was used to process the prompt by the AI provider."
  - attribute: "Request Model"
    unit: "String"
    description: "Represents which AI model was used to process the prompt."
  - attribute: "Provider Name"
    unit: "String"
    description: "Represents which AI provider was used to process the prompt."
  - attribute: "Plugin ID"
    unit: "String"
    description: "Represents the UUID of the plugin."
  - attribute: "LLM Latency"
    unit: "Latency"
    description: "Total time taken to receive a full response after a request sent from Kong (LLM latency + connection time)."
  - attribute: "Embeddings Latency"
    unit: "Latency"
    description: "Time taken to generate the vector for the prompt string."
  - attribute: "Fetch Latency"
    unit: "Latency"
    description: "Total time taken to return a cache."
  - attribute: "Cache Status"
    unit: "String"
    description: "Shows if the response comes directly from the upstream or not. Possible values: `hit` or `Miss`."
  - attribute: "Embeddings Model"
    unit: "String"
    description: "AI providers may have multiple embedding models. This represents the model used for the embeddings."
  - attribute: "Embeddings Provider"
    unit: "String"
    description: "Provider used for generating embeddings."
  - attribute: "Embeddings Token"
    unit: "Count"
    description: "Tokens input into the model for embeddings."
  - attribute: "Embeddings Cost"
    unit: "Cost"
    description: "Cost of caching."
  - attribute: "Cost Savings"
    unit: "Cost"
    description: "Cost savings from cache."
{% endtable %}
<!--vale on-->
{% endnavtab %}
{% navtab "Platform usage" %}

With platform usage reporting, you can:
* Track the number of control planes and data plane nodes in your organization
* Monitor Gateway Services, Routes, and plugins per control plane
* View Consumer counts across your realms and control planes

The following table shows which platform usage metrics you can view:
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
  - metric: "Control plane count"
    category: "Count"
    description: |
      Number of control planes in your organization.
  - metric: "Data plane node count"
    category: "Count"
    description: |
      Number of data plane nodes in your organization.
      You can also filter this metric by data plane node version.
  - metric: "Gateway Service count"
    category: "Count"
    description: |
      Number of Gateway Services in your control plane.
  - metric: "Route count"
    category: "Count"
    description: |
      Number of Routes in your control plane or associated with a specific Gateway Service.
  - metric: "Plugin count"
    category: "Count"
    description: |
      Number of plugins in your control plane. 
      These can also be filtered by plugin scope and name.
  - metric: "Consumer count"
    category: "Count"
    description: |
      Number of Consumers in your realm or control plane.
{% endtable %}
<!--vale on-->
{% endnavtab %}
{% endnavtabs %}

## Time intervals

{% include_cached /konnect/analytics-intervals.md %}

## System-defined groups

`Empty` is an optional, system-defined group that indicates that API calls don't have an entity like [Consumers](/gateway/entities/consumer/) or [Routes](/gateway/entities/route), selected for grouping. `Empty` allows you to group API calls that don't match specific groupings so you can gain more comprehensive insights. You can filter by `Is Empty` or `Is Not Empty`. 

Some common use cases for `Empty` include:
* Identifying the number of API calls that don't match a Route.
* Identifying API calls without an associated Consumer to keep track of any security holes.
