---
min_version:
  ai-gateway: '2.0'
works_on:
  - on-prem
  - konnect
products:
  - ai-gateway
content_type: plugin
description: 'Detect and block requests that contain SQL, server-side include, or other injection patterns before they reach your AI Models, AI Agents, and AI MCP Servers.'
categories:
  - security
tags:
  - security
  - ai
search_aliases:
  - injection-protection
related_resources:
  - text: AI Policy entity
    url: /ai-gateway/entities/ai-policy/
  - text: AI Model entity
    url: /ai-gateway/entities/ai-model/
  - text: AI Agent entity
    url: /ai-gateway/entities/ai-agent/
  - text: AI MCP Server entity
    url: /ai-gateway/entities/ai-mcp-server/
---

Requests that carry SQL, script, or other injection payloads in a path, query string, header, or body can reach your models and tools unchecked.
The Injection Protection [AI Policy](/ai-gateway/entities/ai-policy/) compares each request against regular expressions for known injection patterns, and either rejects matching requests or logs them.
This policy can complement your existing firewall solution by adding a layer of customizable protection to prevent injection attacks, or it can eliminate some content-based attacks if you don’t have an existing firewall.
Attach the policy to your [AI Models](/ai-gateway/entities/ai-model/), [AI Agents](/ai-gateway/entities/ai-agent/), or [AI MCP Servers](/ai-gateway/entities/ai-mcp-server/), or apply it globally.


## How does the Injection Protection Policy work?

The Injection Protection Policy processes each request in the following order:

1. When an AI Model requires authentication, {{site.ai_gateway}} authenticates the client.
1. The policy extracts content from the [`locations`](/ai-gateway/policies/injection-protection/reference/#schema--config-locations) you configure.
1. The policy compares that content against the regular expressions for the selected [`injection_types`](/ai-gateway/policies/injection-protection/reference/#schema--config-injection-types) and any [`custom_injections`](/ai-gateway/policies/injection-protection/reference/#schema--config-custom-injections).
1. When the content matches, the policy acts according to [`enforcement_mode`](/ai-gateway/policies/injection-protection/reference/#schema--config-enforcement-mode):
   * `block`: {{site.ai_gateway}} rejects the request with an error response before it reaches the provider, agent, or tool.
   * `log_only`: {{site.ai_gateway}} sends the request on and records the match.

Every match writes a warning to the data plane log, whichever enforcement mode you use.
The entry names the injection type, the action taken, the location, and the content that matched:

```
threat detected: 'sql', action taken: block, found in query, query param value: q: ' OR 1=1 --
```
{:.no-copy-code}

{{site.ai_gateway}} rejects blocked requests before a streaming response starts.
Clients receive a standard JSON error response for streaming and non-streaming requests.


{:.warning}
> The `xpath_abbreviated` type matches strings such as `//*` and `<script>` tags, so it can match ordinary content.
> Run the policy with `enforcement_mode` set to `log_only` and review the log before you block traffic.

## Scopes

Apply the Injection Protection Policy globally to inspect all {{site.ai_gateway}} traffic on the data plane, or attach it to an AI Model, an AI Agent, or an AI MCP Server to inspect that entity only.
For details about how scopes work, see [AI Policy scopes](/ai-gateway/entities/ai-policy/#ai-policy-scopes).

Global scope applies the same patterns to all traffic, so a pattern that matches ordinary content, such as `xpath_abbreviated`, affects every entity.
To limit that risk, attach the policy to one entity first, or start with `log_only`.

On an AI MCP Server, the policy inspects every MCP request, including `initialize` and `tools/list`.

## Limitations

Attaching the Injection Protection Policy to an [AI Consumer](/ai-gateway/entities/ai-consumer/) or an [AI Consumer Group](/ai-gateway/entities/ai-consumer-group/) stops the data plane from applying configuration changes.
The data plane keeps running its previous configuration until you detach the policy.

