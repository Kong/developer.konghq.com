---
min_version:
  ai-gateway: '2.0'
works_on:
  - on-prem
  - konnect
products:
  - ai-gateway
content_type: plugin
description: 'Send request and response logs from your AI Models, AI Agents, and AI MCP Servers to the syslog daemon on the data plane.'
categories:
  - logging
tags:
  - logging
  - ai
search_aliases:
  - syslog
related_resources:
  - text: AI Policy entity
    url: /ai-gateway/entities/ai-policy/
  - text: AI Model entity
    url: /ai-gateway/entities/ai-model/
  - text: AI Agent entity
    url: /ai-gateway/entities/ai-agent/
  - text: AI MCP Server entity
    url: /ai-gateway/entities/ai-mcp-server/
  - text: AI Consumer entity
    url: /ai-gateway/entities/ai-consumer/
  - text: AI Consumer Group entity
    url: /ai-gateway/entities/ai-consumer-group/
---

If your logs already flow through syslog, use the Syslog [AI Policy](/ai-gateway/entities/ai-policy/) to add {{site.ai_gateway}} traffic to that pipeline.
The Policy writes request and response logs for your [AI Models](/ai-gateway/entities/ai-model/), [AI Agents](/ai-gateway/entities/ai-agent/), and [AI MCP Servers](/ai-gateway/entities/ai-mcp-server/) to the syslog daemon on the data plane host.
You can also scope it to an [AI Consumer](/ai-gateway/entities/ai-consumer/) or [AI Consumer Group](/ai-gateway/entities/ai-consumer-group/) to log only their requests.

{:.info}
> **Note:** The Policy writes to the syslog daemon on the data plane host, so the daemon must be running there. Configure the daemon to accept messages at the severity that you set in [`config.log_level`](/ai-gateway/policies/syslog/reference/#schema--config-log-level).

## Set the severity and facility

The Policy sets the severity of each log entry based on the response status code:

* [`config.successful_severity`](/ai-gateway/policies/syslog/reference/#schema--config-successful-severity) applies to responses with a status code below `400`.
* [`config.client_errors_severity`](/ai-gateway/policies/syslog/reference/#schema--config-client-errors-severity) applies to `4xx` responses.
* [`config.server_errors_severity`](/ai-gateway/policies/syslog/reference/#schema--config-server-errors-severity) applies to `5xx` responses.

[`config.log_level`](/ai-gateway/policies/syslog/reference/#schema--config-log-level) sets the least severe level that the Policy logs.
For example, with `log_level` set to `warning`, the Policy doesn't log an entry assigned `info`, and it logs entries assigned `warning` or `err`.

[`config.facility`](/ai-gateway/policies/syslog/reference/#schema--config-facility) tags every entry with a syslog facility, so the daemon can route entries to different destinations.

## Log format

{% include /md/ai-gateway/v2/policies/logging/log-format.md name="Syslog" %}

### Log format definitions

{% include /md/ai-gateway/v2/policies/logging/json-object-log.md %}

## Log LLM payloads

The Syslog Policy logs token usage, cost, and latency for each request.
To also log the full request and response bodies, enable `config.logging.payloads` on the AI Model.
See [Logging and observability](/ai-gateway/entities/ai-model/#logging-and-observability).

{:.warning}
> **Important:** Request and response bodies can contain sensitive data. Enable payload logging together with [log redaction](#redact-sensitive-data).

## Redact sensitive data

Use [`config.log_sanitization`](/ai-gateway/policies/syslog/reference/#schema--config-log-sanitization) to redact sensitive values from log entries.
JSONPath expressions in `body_json_paths` apply to each payload separately, so `$.messages[*].content` redacts request messages and leaves the response untouched.

Body redaction has an effect only when payload logging is enabled on the AI Model.

For a configuration that redacts a header and matching values, see [Redact sensitive data](/ai-gateway/policies/syslog/examples/redact-sensitive-data/).

## Custom fields by Lua

The [`config.custom_fields_by_lua`](/ai-gateway/policies/syslog/reference/#schema--config-custom-fields-by-lua) setting lets you add, change, or remove log fields with Lua code.

Dots in a field key create nested fields.

### Target {{site.ai_gateway}} fields

{{site.ai_gateway}} records AI-specific data in the `ai` object of each log entry. The key depends on the entity that handles the request:

{% table %}
columns:
  - title: Entity
    key: entity
  - title: Log key
    key: key
  - title: Contents
    key: contents
rows:
  - entity: AI Model
    key: "`ai.proxy`"
    contents: "`usage`, `meta`, and `tried_targets`. Also `payload.request` and `payload.response` when payload logging is enabled on the AI Model."
  - entity: AI MCP Server
    key: "`ai.mcp`"
    contents: "`rpc` (the method, ID, latency, and response body size of each JSON-RPC call), `mcp_server_id`, and `mcp_session_id`."
  - entity: AI Agent
    key: "`ai.a2a`"
    contents: "`rpc` (the method, binding, ID, latency, and response body size of each JSON-RPC call) and `agent_id`."
{% endtable %}

Use these keys in `custom_fields_by_lua` with dotted syntax to remove or override a field.

For a configuration that removes the request body from the log, see [Remove LLM request payloads from logs](/ai-gateway/policies/syslog/examples/remove-request-payload/).

### Lua sandbox

{% include /md/ai-gateway/v2/policies/sandbox.md %}

The [`untrusted_lua`](/ai-gateway/configuration/#untrusted-lua) setting defaults to `strict`.
The Lua code runs in the log phase, so only [PDK](/gateway/pdk/reference/) methods that work in that phase are available.

## Scopes

The Syslog AI Policy supports the following scopes:

* [AI Model](/ai-gateway/entities/ai-model/)
* [AI MCP Server](/ai-gateway/entities/ai-mcp-server/)
* [AI Agent](/ai-gateway/entities/ai-agent/)
* [AI Consumer](/ai-gateway/entities/ai-consumer/)
* [AI Consumer Group](/ai-gateway/entities/ai-consumer-group/)
* Global

Use global scope to ship all {{site.ai_gateway}} traffic to syslog.
The data plane logs every request that it processes, including requests to AI Models without an attached Policy, so expect a higher log volume.
Attach the Policy to an AI Model, AI Agent, or AI MCP Server to log one entity, or to an AI Consumer or AI Consumer Group to log one caller.
The Consumer scopes only log requests that the data plane has authenticated as that caller.
Only one Syslog Policy applies to a request. When you attach the Policy to an entity and also apply one globally, the Policy attached to the entity applies to that entity's requests.

For details about how scopes work, see [AI Policy scopes](/ai-gateway/entities/ai-policy/#ai-policy-scopes).
