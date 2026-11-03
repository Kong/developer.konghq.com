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
    use: "Check the health and cost of all AI traffic for a time range."
  - page: "[**Dashboards**](#dashboards)"
    use: "Build and share your own dashboards from AI Gateway metrics."
  - page: "[**Explorer**](#explorer)"
    use: "Answer one specific question with a custom query."
  - page: "[**Logs**](#logs)"
    use: "Read and search the logs of your gateways."
{% endtable %}
<!-- vale on -->

## Who can see what

What you see depends on your [AI Management role](/ai-management/roles-and-permissions/#observability):

* Org Admins see data for the whole organization.
* Team Managers see data for their teams.
* Individual Users see their own usage.

## Overview

Overview is a prebuilt dashboard for all AI traffic.
To narrow it, use the **All Providers**, **All AI gateway models**, and **All AI gateway agents** filters.
To change the period, use the time range menu.
The default period is the last 7 days.

The page has the following sections. Click a section name at the top of the page to jump to it.

<!-- vale off -->
{% table %}
columns:
  - title: Section
    key: section
  - title: What it shows
    key: shows
rows:
  - section: "**Key metrics**"
    shows: "LLM latency (p95), request count, total and cached token counts, error rate, and costs. Each tile compares the value with the previous period."
  - section: "**Top consumers**"
    shows: "The top five models, providers, users, and MCP servers by request count, with each one's share of requests."
  - section: "**Performance**"
    shows: "Total requests, LLM latency, error rate, tokens per minute, time to first token (TTFT), and time per output token (TPOT) over time. The LLM latency, TTFT, and TPOT charts show p50, p95, and p99 on the same chart."
  - section: "**Costs**"
    shows: "Total costs compared with request count, and cost by model."
  - section: "**Models**"
    shows: "Model usage by user, error rate per model, and latency per model."
  - section: "**MCP**"
    shows: "MCP method calls by model, and failing method calls."
{% endtable %}
<!-- vale on -->

TTFT is the time from sending a request to receiving the first token of the response.
TPOT is the average time to generate each token after the first.

## Dashboards

Dashboards are the same [Custom Dashboards](/custom-dashboards/) that you use for API traffic, with {{site.ai_gateway}} metrics.
Click **Manage dashboards** to see the dashboards in your organization.
To add one, click **Create dashboard**, then create it from a template, from scratch, or from a JSON definition.

The **AI gateway dashboard**, **{{site.ai_gateway}} 2 dashboard**, and **Agentic analytics dashboard** templates are built for AI traffic.
For tiles, filters, sharing, and automation, see the [Custom Dashboards reference](/observability/custom-dashboards-reference/).
For a walkthrough, see [Create a dashboard from a template](/how-to/create-custom-dashboards/).

## Explorer

Explorer runs one query at a time.
You build the query in the query bar: **From** a data source, **Show** a chart type **with** a metric, **per** a time interval, **by** a dimension.
Use **Add filter** to narrow the requests, and the time range menu to change the period.

For AI traffic, use one of these data sources:

* **LLM usage**: requests to models. Metrics include **Costs**, token counts, **LLM latency**, **Time to first token**, **Time per token**, and **Error rate**.
* **Agentic usage**: requests to MCP servers and agents. Metrics include **Request count**, **Active agents**, **MCP latency**, **A2A latency**, **Kong latency**, **Upstream latency**, and **Error rate**.

For the full list of metrics in each data source, see [{{site.konnect_short_name}} Explorer](/observability/explorer/#metrics).

The following dimensions group or filter AI traffic:

<!-- vale off -->
{% table %}
columns:
  - title: Dimension
    key: dimension
  - title: Groups requests by
    key: groups
  - title: Data source
    key: source
rows:
  - dimension: "**AI gateway**"
    groups: "The {{site.ai_gateway}} that handled the request."
    source: "LLM usage, Agentic usage"
  - dimension: "**AI gateway model**"
    groups: "The [AI Model](/ai-gateway/entities/ai-model/) that the client called."
    source: "LLM usage, Agentic usage"
  - dimension: "**AI gateway MCP server**"
    groups: "The [AI MCP Server](/ai-gateway/entities/ai-mcp-server/) that the client called."
    source: "LLM usage, Agentic usage"
  - dimension: "**AI gateway agent**"
    groups: "The [AI Agent](/ai-gateway/entities/ai-agent/) that the client called."
    source: "LLM usage, Agentic usage"
  - dimension: "**Provider**"
    groups: "The upstream LLM provider."
    source: "LLM usage, Agentic usage"
  - dimension: "**Request model** and **Response model**"
    groups: "The model name in the request and in the provider's response."
    source: "LLM usage"
  - dimension: "**Principal** and **Principal group**"
    groups: "The user or agent that made the request, and their group. See [principals](/identity/principals/)."
    source: "LLM usage, Agentic usage"
  - dimension: "**AI gateway consumer** and **AI gateway consumer group**"
    groups: "The [AI Consumer](/ai-gateway/entities/ai-consumer/) that made the request, and its group."
    source: "LLM usage, Agentic usage"
  - dimension: "**MCP tool name**, **MCP method**, and **MCP error**"
    groups: "The MCP tool and method that were called, and the MCP error that was returned."
    source: "Agentic usage"
  - dimension: "**Status code (grouped)**"
    groups: "The response class, for example 4XX or 5XX."
    source: "LLM usage, Agentic usage"
{% endtable %}
<!-- vale on -->

To keep a result, open the menu next to the time range and click **Save as report** or **Export as CSV**.

## Answer common questions with Explorer

Each row is one Explorer query.
To compare two metrics, for example two latency percentiles, run the query once for each metric.

<!-- vale off -->
{% table %}
columns:
  - title: Question
    key: question
  - title: From
    key: from
  - title: Show
    key: show
  - title: With
    key: with
  - title: By
    key: by
rows:
  - question: "Which models, agents, MCP servers, providers, or users get the most traffic?"
    from: "LLM usage or Agentic usage"
    show: "Top list"
    with: "Request count"
    by: "**AI gateway model**, **AI gateway agent**, **AI gateway MCP server**, **Provider**, or **Principal**"
  - question: "Which MCP tools are called the most, or in a loop?"
    from: "Agentic usage"
    show: "Top list or Timeseries line"
    with: "Request count"
    by: "**MCP tool name**"
  - question: "Is a model slow for a few requests or for all of them?"
    from: "LLM usage"
    show: "Timeseries line"
    with: "**LLM latency (p50)**, then **LLM latency (p99)**"
    by: "**AI gateway model**"
  - question: "Is the delay in the gateway or in the upstream service?"
    from: "Agentic usage"
    show: "Timeseries line"
    with: "**Kong latency (p95)**, then **Upstream latency (p95)**"
    by: "**AI gateway MCP server** or **AI gateway agent**"
  - question: "Which provider is slow to start responding?"
    from: "LLM usage"
    show: "Timeseries line"
    with: "**Time to first token (p95)** or **Time per token (p95)**"
    by: "**Provider**"
  - question: "Which MCP server or agent is failing?"
    from: "Agentic usage"
    show: "Timeseries line"
    with: "Error rate"
    by: "**AI gateway MCP server**, **AI gateway agent**, or **MCP error**"
  - question: "Which models or providers cost the most?"
    from: "LLM usage"
    show: "Top list or Timeseries bar"
    with: "**Costs** or **Share of cost**"
    by: "**AI gateway model** or **Provider**"
{% endtable %}
<!-- vale on -->

## Logs

Logs lists the logs of your gateways and their control planes, newest first.

* Search in **Basic** or **Advanced** mode, and use the time range menu to change the period. The default period is the last 15 minutes.
* Use the **Filter** panel to narrow the entries by **Log Level**, **Service** (for example, the data plane or the control plane), or **Control Plane**.
* The default columns are **Timestamp**, **Log level**, **Log type**, **Dataplane ID**, **Control plane**, and **Message**.
* Click an entry to open its details: a summary, its attributes, and the full message.

## Explorer and {{site.ai_cost_management}}

{{site.ai_cost_management}} has its own [Explorer](/ai-cost-management/analytics-and-debugging/#explorer) for spend, with budgets, users, teams, and cost tags.
Use the Observability Explorer for traffic, latency, and errors, and for cost by model or provider.

## Data retention

The metrics that Explorer shows are kept for one year.
