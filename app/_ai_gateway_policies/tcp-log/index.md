---
min_version:
  ai-gateway: '2.0'
works_on:
  - on-prem
  - konnect
products:
  - ai-gateway
content_type: plugin
description: 'Send {{site.ai_gateway}} request and response logs to a TCP server. Covers TLS, custom log fields, and supported scopes.'
categories:
  - logging
tags:
  - logging
  - ai
search_aliases:
  - tcp-log
  - tcp
  - logging
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
  - text: "{{site.ai_gateway}} logs"
    url: /ai-gateway/ai-logs/
  - text: File Log Policy
    url: /ai-gateway/policies/file-log/
  - text: HTTP Log Policy
    url: /ai-gateway/policies/http-log/
  - text: UDP Log Policy
    url: /ai-gateway/policies/udp-log/
---

The TCP Log [AI Policy](/ai-gateway/entities/ai-policy/) sends a log entry for every request to a TCP server that you run, such as a log collector.
Use it to ship request and response data, including token usage and cost for [AI Models](/ai-gateway/entities/ai-model/), into your own logging pipeline.

{{site.ai_gateway}} sends each entry after it sends the response to the client.
If the TCP server is unreachable, clients still get their responses and {{site.ai_gateway}} records the failure in its [process error log](#process-errors).

## Connect to a TCP server

Set [`config.host`](/ai-gateway/policies/tcp-log/reference/#schema--config-host) and [`config.port`](/ai-gateway/policies/tcp-log/reference/#schema--config-port) to the address of your TCP server.
Both are required.

For a configuration that sends logs to a TCP server, see [Send logs to a TCP server](/ai-gateway/policies/tcp-log/examples/enable-tcp-log/).

### Use TLS

To encrypt the connection, set [`config.tls`](/ai-gateway/policies/tcp-log/reference/#schema--config-tls) to `true`.
Set [`config.tls_sni`](/ai-gateway/policies/tcp-log/reference/#schema--config-tls-sni) if your TCP server needs a specific server name in the TLS handshake.
When you don't set `tls_sni`, {{site.ai_gateway}} doesn't send a server name.

For a configuration that connects over TLS and sends a server name, see [Send logs over TLS](/ai-gateway/policies/tcp-log/examples/send-logs-over-tls/).

{{site.ai_gateway}} verifies the certificate that the TCP server presents, and the data plane must trust the certificate authority that signed it.
When the data plane doesn't trust the certificate, {{site.ai_gateway}} drops the log entries.
Requests still succeed, and the data plane records `failed to perform TLS handshake` in its error log.

The [`config.ssl_verify`](/ai-gateway/policies/tcp-log/reference/#schema--config-ssl-verify) parameter can't turn verification off by default.
The [`tls_certificate_verify`](/ai-gateway/configuration/#tls-certificate-verify) property is `on` by default, and while it's on, {{site.ai_gateway}} rejects a configuration with `ssl_verify: false` on the data plane.

## Process errors

{% include md/ai-gateway/v2/policies/process-errors.md %}

Failures to deliver logs appear in this file. For example:

* `failed to connect to <host>:<port>: connection refused`: the TCP server isn't listening on that address.
* `failed to perform TLS handshake to <host>:<port>: 18: self-signed certificate`: the data plane doesn't trust the server certificate.

## Log format

{% include /md/ai-gateway/v2/policies/logging/log-format.md %}

Each entry also includes data that depends on what the request targeted:

* For an [AI Model](/ai-gateway/entities/ai-model/), the `ai.proxy` object holds token usage and cost.
* For an [AI MCP Server](/ai-gateway/entities/ai-mcp-server/), the entry has an `ai.mcp` object.
* For an [AI Agent](/ai-gateway/entities/ai-agent/), the entry doesn't have an `ai` object.
* For an [AI Consumer](/ai-gateway/entities/ai-consumer/), the entry has a `consumer` object.

The `service` and `route` objects in a log entry describe objects that {{site.ai_gateway}} creates internally for each entity.
Don't build alerts or parsers that depend on them.

### Log format definitions

{% include /md/ai-gateway/v2/policies/logging/json-object-log.md %}

## Custom fields by Lua

Use [`config.custom_fields_by_lua`](/ai-gateway/policies/tcp-log/reference/#schema--config-custom-fields-by-lua) to add, change, or remove fields in each log entry.
Each key is a field name, and each value is a Lua snippet that returns the field's value.

For a configuration that removes the `route` field and adds a field with the value of a request header, see [Customize log fields with Lua](/ai-gateway/policies/tcp-log/examples/customize-log-fields/).

A dot (`.`) in a key creates a nested field.
For example, `c.d: "return 2"` produces `{"c": {"d": 2}}`.
To keep the dot as part of a flat field name, escape it with a backslash: `a\.b` produces a single field named `a.b`.

The Lua code runs in a sandbox, and the `untrusted_lua` property controls its restrictions.
The examples on this page work with the default `strict` setting.
For details, see the [`untrusted_lua`](/ai-gateway/configuration/#untrusted-lua) property.

## Scopes

Apply the TCP Log Policy globally to log all {{site.ai_gateway}} traffic, or attach it to an AI Model, an AI Agent, an AI MCP Server, or an AI Consumer to log that entity's traffic only.
For details about how scopes work, see [AI Policy scopes](/ai-gateway/entities/ai-policy/#ai-policy-scopes).

* **Global scope:** the policy logs every request, including requests that {{site.ai_gateway}} rejects before they reach the upstream, such as authentication failures (`401`) and rate limit rejections (`429`).
* **AI Consumer scope:** the policy logs only requests that authenticate as that AI Consumer. Requests that fail authentication aren't logged.

## Limitations

The TCP Log Policy doesn't support AI Consumer Group scope. The control plane rejects the configuration.
