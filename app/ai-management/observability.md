---
title: "Observability in AI Management"
content_type: reference
layout: reference
permalink: /ai-management/observability/
breadcrumbs:
  - /ai-management/
products:
  - ai-gateway
works_on:
  - konnect
tags:
  - ai
  - analytics
description: "Monitor traffic, latency, errors, and cost for AI Models, AI MCP Servers, and AI Agents."
related_resources:
  - text: AI Management
    url: /ai-management/
  - text: "{{site.konnect_short_name}} Explorer"
    url: /observability/explorer/
  - text: Custom Dashboards reference
    url: /observability/custom-dashboards-reference/
  - text: "Analytics and debugging in {{site.ai_cost_management}}"
    url: /ai-cost-management/analytics-and-debugging/
  - text: AI Management roles and permissions
    url: /ai-management/roles-and-permissions/
  - text: AI Model entity
    url: /ai-gateway/entities/ai-model/
  - text: AI MCP Server entity
    url: /ai-gateway/entities/ai-mcp-server/
  - text: AI Agent entity
    url: /ai-gateway/entities/ai-agent/
faqs:
  - q: How long is Observability data kept?
    a: The metrics that Overview, Dashboards, and Explorer show are kept for one year.
---

Observability in [AI Management](/ai-management/) shows the traffic that passes through {{site.ai_gateway}}: calls to [models](/ai-gateway/entities/ai-model/), [MCP servers](/ai-gateway/entities/ai-mcp-server/), and [agents](/ai-gateway/entities/ai-agent/).
In the {{site.konnect_short_name}} sidebar, click **Observability** to open these pages:

<!-- vale off -->
{% table %}
columns:
  - title: Page
    key: page
  - title: Use it to
    key: use
rows:
  - page: "[**Overview**](#overview-page)"
    use: "Review the health and cost of AI traffic."
  - page: "[**Dashboards**](#dashboards)"
    use: "Build and share your own dashboards from AI Gateway metrics."
  - page: "[**Explorer**](#explorer)"
    use: "Answer specific questions with custom queries."
  - page: "[**Alerts**](#alerts)"
    use: "Get notified about unusual error rates, latency, or traffic."
  - page: "[**Logs**](#logs)"
    use: "Read and search logs."
{% endtable %}
<!-- vale on -->

## Overview page

To narrow the Overview page, use the following filters:

* **All Providers**
* **All AI gateway models**
* **All AI gateway agents**

To change the period, use the time range menu.
The default period is the last 7 days.

The page has the following sections. Click a section name at the top of the page to jump to it.

<!-- vale off -->
{% table %}
columns:
  - title: Section
    key: section
  - title: Charts
    key: charts
rows:
  - section: "**Key metrics**"
    charts: "**LLM latency (p95)**, **Request count**, **Total token count**, **Cached token count**, **Error rate**, and **Costs**, each compared with the previous period"
  - section: "**Top consumers**"
    charts: "**Models**, **Providers**, **Users**, and **MCP Server**"
  - section: "**Performance**"
    charts: "**Total requests**, **LLM latency**, **Error rate**, **Tokens per minute**, **Time to first token (TTFT)**, and **Time per output token (TPOT)**"
  - section: "**Costs**"
    charts: "**Total costs vs request count** and **Cost by model**"
  - section: "**Models**"
    charts: "Success rate and usage by model: **Model usage by user**, **Error rate per model**, and **Latency per model**"
  - section: "**MCP**"
    charts: "Tool usage by model across MCP servers: **Method calls by model** and **Failing method calls**"
{% endtable %}
<!-- vale on -->

The **LLM latency**, **Time to first token (TTFT)**, and **Time per output token (TPOT)** charts show p50, p95, and p99.

## Observability roles

The data you see in Observability depends on your [AI Management role](/ai-management/roles-and-permissions/#observability):

* Org Admins see data for the whole organization.
* Team Managers see data for their teams.
* Individual Users see their own usage.

## Dashboards

Use dashboards to view {{site.ai_gateway}} metrics.
Click **Manage dashboards** to see the dashboards in your organization.
To add one, click **Create dashboard**, then create it from a template, from scratch, or from a JSON definition.

The following templates are built for AI traffic:

<!-- vale off -->
{% table %}
columns:
  - title: Template
    key: template
  - title: Description
    key: description
rows:
  - template: "**AI gateway dashboard**"
    description: |
      AI-focused insight into your LLM traffic and operational costs.
      Track request volume by model and provider, understand token usage trends, and monitor latency across different models.
      Teams operating {{site.ai_gateway}}s can use this dashboard to optimize performance and manage costs by monitoring traffic patterns and provider-specific behavior.
  - template: "**Agentic analytics dashboard**"
    description: |
      Overview of agentic traffic flowing through your {{site.ai_gateway}}.
      This dashboard highlights which tools are called most frequently, breaks down tool usage by consumer, and tracks average latency per tool over time.
      It helps teams operating MCP-enabled services understand usage patterns and identify performance bottlenecks.
{% endtable %}
<!-- vale on -->

To see cost next to latency or TTFT, add a tile for each metric to the same dashboard.
* For tiles, filters, sharing, and automation, see the [Custom Dashboards reference](/observability/custom-dashboards-reference/).
* For a walkthrough, see [Create a dashboard from a template](/how-to/create-custom-dashboards/).

## Explorer

The Explorer in AI Management works the same as the {{site.konnect_short_name}} Explorer.
For the full Explorer documentation, including time ranges, saving reports, and exporting to CSV, see the [{{site.konnect_short_name}} Explorer reference](/observability/explorer/).

In the Explorer query bar, you can build a query **From** a data source, **Show** a chart type **with** a metric, **per** a time interval, **by** a dimension.

For AI traffic, use one of these data sources:

<!-- vale off -->
{% table %}
columns:
  - title: Data source
    key: source
  - title: Metrics
    key: metrics
rows:
  - source: "LLM usage"
    metrics: |
      * Costs
      * Token counts
      * LLM latency
      * Time to first token
      * Time per token
      * Error rate
  - source: "Agentic usage"
    metrics: |
      * Request count
      * Active agents
      * MCP latency
      * A2A latency
      * Kong latency
      * Upstream latency
      * Error rate
{% endtable %}
<!-- vale on -->

To group or filter AI traffic, use these dimensions:

<!-- vale off -->
{% feature_table %}
item_title: Dimension
columns:
  - title: LLM usage
    key: llm
  - title: Agentic usage
    key: agentic
features:
  - title: AI gateway
    llm: true
    agentic: true
  - title: AI gateway model
    llm: true
    agentic: true
  - title: AI gateway MCP server
    llm: true
    agentic: true
  - title: AI gateway agent
    llm: true
    agentic: true
  - title: AI gateway consumer
    llm: true
    agentic: true
  - title: AI gateway consumer group
    llm: true
    agentic: true
  - title: Provider
    llm: true
    agentic: true
  - title: Principal
    llm: true
    agentic: true
  - title: Principal group
    llm: true
    agentic: true
  - title: Status code (grouped)
    llm: true
    agentic: true
  - title: Request model
    llm: true
    agentic: false
  - title: Response model
    llm: true
    agentic: false
  - title: MCP tool name
    llm: false
    agentic: true
  - title: MCP method
    llm: false
    agentic: true
  - title: MCP error
    llm: false
    agentic: true
{% endfeature_table %}
<!-- vale on -->

## Alerts

An alert rule watches one metric of your AI traffic, like error rates or latency from models, routes, or providers.
When the metric breaks the rule, the rule triggers an alert for that model, route, or provider, for example `Model: gpt-4o`.
An alert shows **Triggered** while it is active and **Resolved** after it ends.

To open alerts, in the {{site.konnect_short_name}} sidebar, click **Observability**, then click **Alerts**.

### Default detection rules

Every organization starts with the following rules, which are enabled by default:

<!-- vale off -->
{% table %}
columns:
  - title: Rule
    key: rule
  - title: Metric
    key: metric
  - title: Scope
    key: scope
  - title: Severity
    key: severity
rows:
  - rule: "**Error rate spike**"
    metric: Error rate
    scope: Model
    severity: Critical
  - rule: "**Latency degradation**"
    metric: p95 request latency
    scope: Route
    severity: Warning
  - rule: "**Time to first token degradation**"
    metric: Time to first token (TTFT)
    scope: Provider
    severity: Warning
  - rule: "**Time per output token degradation**"
    metric: Time per output token (TPOT)
    scope: Provider
    severity: Warning
  - rule: "**Traffic flatline**"
    metric: Request volume
    scope: Model
    severity: Critical
{% endtable %}
<!-- vale on -->

The default rules don't have notifications set up.
To get notified, edit a rule and add an email address or a webhook. For more information, see [Alert notifications](#alert-notifications).

### Create an alert

1. In the {{site.konnect_short_name}} sidebar, click **Observability**.
1. In the Observability sidebar, click **Alerts**.
1. Click **Create alert**.
1. In the **Alert name** field, enter `High error rate on gpt-4o`.
1. From the **Control plane** dropdown menu, select your control plane.
1. Select **Template**.
1. From the **Category** dropdown menu, select "Error rate spike".
1. From the **Threshold** dropdown menu, select "12%".
1. In the **Notify** section, select the **Email** checkbox.
1. In the email address field, enter `alerts@example.com`.
1. Click **Save alert rule**.

You can change the pre-filled values from the template for:

* The metric
* The dimensions
* A condition with a severity, a threshold, and a duration

To define your own conditions, select **Custom** instead of **Template**.
Each custom condition uses a data source (**LLM usage** or **Agentic usage**), a metric, dimensions, optional filters, a threshold, and a duration.
A custom rule can match all of its conditions or any one of them. To save it, click **Save custom rule**.

You can also create an alert from a query in [Explorer](#explorer).
In Explorer, click **Create alert**. The **New alert** page opens with **Custom** selected, and the first condition uses the data source, metric, and dimension of your query.

### Alert notifications

A rule can notify by email, by webhook, or by both.
For a webhook, select a saved webhook or click **New webhook**.
When you create a webhook, you can select its provider.
To get details about delivery problems, add a failure-notice email to the webhook. If a delivery fails, Kong sends the reason to that address.

## Logs

The Logs page shows your {{site.ai_gateway}} control plane logs and the runtime logs of Dedicated Cloud Gateways, newest first.
Runtime logs from self-managed data planes do not appear on this page.

* Search in **Basic** or **Advanced** mode, and use the time range menu to change the period. The default period is the last 15 minutes.
* Use the **Filter** panel to narrow the entries by **Log Level**, **Service** (a Dedicated Cloud Gateway or the control plane), or **Control Plane**.
* The default columns are **Timestamp**, **Log level**, **Log type**, **Dataplane ID**, **Control plane**, and **Message**.
* Click an entry to open its details: a summary, its attributes, and the full message. Copy buttons allow you to copy raw logs or each element separately. 

## Explorer and {{site.ai_cost_management}}

{{site.ai_cost_management}} has its own [Explorer](/ai-cost-management/analytics-and-debugging/#explorer), which shows spend, requests, or tokens over time for any combination of filters and group-by dimensions.
Set spend limits using [budgets](/ai-cost-management/budgets/) in {{site.ai_cost_management}}.
