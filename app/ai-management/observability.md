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
description: "Monitor traffic, latency, errors, and cost for AI Models, AI MCP Servers, and AI Agents in AI Management."
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
  - page: "[**Overview**](#overview)"
    use: "Review the health and cost of AI traffic."
  - page: "[**Dashboards**](#dashboards)"
    use: "Build and share your own dashboards from AI Gateway metrics."
  - page: "[**Explorer**](#explorer)"
    use: "Answer specific questions with custom queries."
  - page: "[**Logs**](#logs)"
    use: "Read and search logs."
{% endtable %}
<!-- vale on -->

## Overview

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

Dashboards are for viewing {{site.ai_gateway}} metrics.
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
      This dashboard helps teams operating AI gateways to optimize performance and manage costs with visibility into traffic patterns and provider-specific behavior.
  - template: "**Agentic analytics dashboard**"
    description: |
      Overview of agentic traffic flowing through your Kong gateway.
      This dashboard highlights which tools are called most frequently, breaks down tool usage by consumer, and tracks average latency per tool over time.
      It helps teams operating MCP-enabled services understand usage patterns and identify performance bottlenecks.
{% endtable %}
<!-- vale on -->

To see cost next to latency or TTFT, add a tile for each metric to the same dashboard.
For tiles, filters, sharing, and automation, see the [Custom Dashboards reference](/observability/custom-dashboards-reference/).
For a walkthrough, see [Create a dashboard from a template](/how-to/create-custom-dashboards/).

## Explorer

Explorer in AI Management is the [{{site.konnect_short_name}} Explorer](/observability/explorer/), which also covers time ranges, saving reports, and exporting to CSV.
In the Explorer query bar, build a query: **From** a data source, **Show** a chart type **with** a metric, **per** a time interval, **by** a dimension.

For AI traffic, use one of these data sources:

* **LLM usage**: metrics include **Costs**, token counts, **LLM latency**, **Time to first token**, **Time per token**, and **Error rate**.
* **Agentic usage**: metrics include **Request count**, **Active agents**, **MCP latency**, **A2A latency**, **Kong latency**, **Upstream latency**, and **Error rate**.

To group or filter AI traffic, use these dimensions:

* In both data sources: **AI gateway**, **AI gateway model**, **AI gateway MCP server**, **AI gateway agent**, **AI gateway consumer**, **AI gateway consumer group**, **Provider**, **Principal**, **Principal group**, and **Status code (grouped)**.
* In **LLM usage** only: **Request model** and **Response model**.
* In **Agentic usage** only: **MCP tool name**, **MCP method**, and **MCP error**.

## Logs

Logs lists the logs of your gateways and their control planes, newest first.

* Search in **Basic** or **Advanced** mode, and use the time range menu to change the period. The default period is the last 15 minutes.
* Use the **Filter** panel to narrow the entries by **Log Level**, **Service** (for example, the data plane or the control plane), or **Control Plane**.
* The default columns are **Timestamp**, **Log level**, **Log type**, **Dataplane ID**, **Control plane**, and **Message**.
* Click an entry to open its details: a summary, its attributes, and the full message.

## Explorer and {{site.ai_cost_management}}

{{site.ai_cost_management}} has its own [Explorer](/ai-cost-management/analytics-and-debugging/#explorer), which shows spend, requests, or tokens over time for any combination of filters and group-by dimensions.
Spend limits are set with [budgets](/ai-cost-management/budgets/) in {{site.ai_cost_management}}.
