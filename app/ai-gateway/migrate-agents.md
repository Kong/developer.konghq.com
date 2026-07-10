---
title: "Migrate your agents to {{site.ai_gateway}} 2.x"
content_type: reference
layout: reference

works_on:
 - konnect

products:
  - ai-gateway
breadcrumbs:
  - /ai-gateway/
tags:
  - ai

  
min_version:
  ai-gateway: '2.0'

description: This guide walks you through moving your a2a agents to the new {{site.ai_gateway}} AI Agent entities.
---

In {{site.ai_gateway}} version 1.x, an agent is an [AI A2A Proxy](/plugins/ai-a2a-proxy/) plugin attached to a Service and Route. The plugin is a transparent proxy that adds observability and agent card URL rewriting to Agent-to-Agent (A2A) traffic (where the gateway automatically changes the agent's address so clients connect through the gateway instead of directly to the agent.)

In {{site.ai_gateway}} version 2.x, that plugin becomes an [AI Agent](/ai-gateway/entities/ai-agent/) entity, which captures the following in a single entity and applies the agent card rewriting automatically:
* The upstream URL
* Routing
* Logging

## Converting configuration files

The following version 1.x example defines an A2A agent that proxies an upstream agent that handles flight bookings:

```
# kong.yaml (AI Gateway v1, exported with deck gateway dump)
services:
- name: flight-booking-agent
  url: https://booking-agent.internal.kongair.com
  routes:
  - name: flight-booking-agent-route
    paths:
    - /booking-agent
  plugins:
  - name: ai-a2a-proxy
    config:
      max_request_body_size: 8388608
      logging:
        log_statistics: true
        log_payloads: false
        max_payload_size: 1048576
```

Converting the example to use the version 2.x model:
* Moves the upstream URL, route, request-size limit, and logging settings onto a single AI Agent entity.
* Renames the `config.logging` fields: `log_statistics` becomes `statistics`, and `log_payloads` becomes `payloads`

```
# ai-gateway.yaml (AI Gateway v2 entity model)
agents:
- type: a2a
  name: kongair-flight-booking-agent
  display_name: Kong Air Flight Booking Agent
  enabled: true
  access:
    acls:
      allow: []
      deny: []
  policies: []
  config:
    url: https://booking-agent.internal.kongair.com
    route:
      paths:
      - /booking-agent
    max_request_body_size: 8388608
    logging:
      statistics: true
      payloads: false
      max_payload_size: 1048576
```

## What to check on AI Agents

- Agent type: most A2A workloads use `type: a2a`. Use `type: http` for plain HTTP agent traffic that does not follow the A2A protocol bindings.
- URL rewriting: the AI Agent entity rewrites agent card `url` and `additionalInterfaces[].url` fields to the gateway address automatically, the same behavior the version 1.x plugin provided. No extra configuration is needed.
- Logging field names: as with AI MCP Servers, `log_statistics` and `log_payloads` become `statistics` and `payloads` under `config.logging`.
- Analytics: with `statistics` enabled, A2A metrics flow into {{site.konnect_short_name}} analytics. View them under Agentic usage analytics in {{site.konnect_short_name}} Explorer and Dashboards.