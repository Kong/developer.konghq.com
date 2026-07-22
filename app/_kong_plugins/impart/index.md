---
title: 'Impart Security'
name: 'Impart Security'

content_type: plugin

publisher: impart-security
description: "Block LLM, agent, and MCP attacks in real time with Impart Security's runtime enforcement platform for {{site.base_gateway}}."

products:
    - gateway

works_on:
    - on-prem
    - konnect

third_party: true

min_version:
  gateway: '2.8'

support_url: https://www.impart.security/get-started

icon: impart.png

tags:
  - ai
  - security
  - impart-security

search_aliases:
  - kong-plugin-impart
  - waf
  - api security
  - runtime protection
  - llm security
  - ai security
  - agent security
  - mcp security
  - prompt injection
  - ai-dr
  - ai detection and response

related_resources:
  - text: Impart Kong integration documentation
    url: https://docs.impartsecurity.net/docs/Quickstart/Integrations/Kong_lua
  - text: Impart Security
    url: https://www.impart.security
---

Impart is a runtime enforcement platform purpose-built to stop AI attacks in real time. The {{page.name}} plugin lets {{site.base_gateway}} detect and block threats against your LLM, agent, and MCP traffic inline. It stops malicious prompts before they reach your model, unsafe actions before they reach your agent, and abusive calls before they reach your MCP tools.

Integrating the {{page.name}} plugin into your {{site.base_gateway}} allows you to:
* **Block LLM attacks**: Stop prompt injection and jailbreak attempts with deterministic, sequence-aware enforcement, not best-effort regex
* **Control agent behavior**: Block unsafe actions and excessive agency before an agent executes them in production.
* **Protect the MCP layer**: Apply runtime controls over MCP tool calls and block unauthorized or abusive MCP traffic.
* **Stop zero-day attacks fast**: Enforce AI-generated, human-reviewed, code-based detection rules that update in minutes, not days.
* **Protect APIs and web apps too**: Block legacy threats like injection, enumeration, and credential stuffing using the same WAF and API security engine.

{:.info}
> Unlike tools that only generate alerts and tickets, Impart enforces policy inline, in the request path, at the moment an attack happens.

## How it works

The {{page.name}} plugin inspects HTTP traffic, including LLM, agent, and MCP requests, and streams it to an **Impart Inspector** running inside your own environment. The inspector evaluates each request against your rules and returns a verdict. Based on that verdict, the plugin either forwards the request upstream or blocks it inline.

Because the inspector runs inside your infrastructure, sensitive request and response data never leaves your environment. The integration adds minimal latency, and fails open if the inspector is unreachable, so your gateway stays available.

<!-- vale off-->
{% mermaid %}
sequenceDiagram
autonumber
    participant Client
    participant Plugin as {{site.base_gateway}}<br/>Impart Plugin
    participant Inspector as Impart Inspector<br/>(your environment)
    participant Upstream as Upstream<br/>(LLM, agent, or MCP tool)

    Client->>Plugin: Send request
    Plugin->>Inspector: Stream request metadata
    Inspector->>Inspector: Evaluate against rules
    Inspector->>Plugin: Verdict

    alt If request is malicious
        Plugin->>Client: Block request
    else If request is allowed
        Plugin->>Upstream: Forward request
        Upstream->>Client: Return response
    end
{% endmermaid %}
<!-- vale on-->

_**Figure 1**: Request flow showing how the {{page.name}} plugin streams traffic to a locally-run Impart Inspector for real-time policy enforcement. Malicious requests are blocked inline; allowed requests are forwarded upstream._

## Threats Impart helps you catch

Some of the most dangerous AI attack patterns don't show up in any single request. Instead, they only appear as a pattern across a session. Because the {{page.name}} plugin correlates signals across requests, not just within one, it can catch threats a single-message filter would miss entirely.

**Excessive agent tool use.** An AI agent starts calling far more distinct tools than its task requires. This is a common signature of a compromised or hijacked agent. For example, an agent may have been prompt-injected into exploring your entire tool surface, or may be testing which tools it can reach with a stolen identity. Any one of those tool calls looks completely legitimate on its own; only the pattern across a session gives it away. Left unchecked, this kind of agent drift can mean data loss, runaway cost, or actions taken on your users' behalf that can't be undone. Impart tracks how many distinct tools a caller invokes within a session and flags or blocks callers that cross normal thresholds, catching an agent that's drifted outside its intended scope before it can do real damage.

**MCP catalog drift ("rug-pull" attacks).** An MCP server changes the tools, prompts, or resources it advertises after a client has already started trusting its catalog, or serves a tool that was never advertised in the first place. This is a supply-chain-style attack: a server can look completely benign during initial discovery, then swap in a malicious tool mid-session once trust is established. Nothing about a single tool invocation reveals the swap; only comparing it against what was originally advertised does. A successful rug-pull can expose sensitive data or trigger unauthorized actions across every session that trusted the server, the kind of supply-chain compromise that's expensive to detect and worse to explain to customers. Impart snapshots the catalog an MCP server advertises and checks every later invocation in that session against it, flagging tools that were never advertised or catalogs that changed mid-session.

**Persistent LLM prompt injection.** An attacker sends prompt injection or jailbreak attempts repeatedly, often adjusting their approach each time to stay just under the radar of a single-message filter. One borderline prompt may not be conclusive enough to block without risking false positives on real users, but an attacker who keeps trying is a much clearer signal of intent, and a filter with no memory has no way to notice the pattern. A determined attacker who eventually succeeds can extract sensitive data, generate brand-damaging output, or trigger a compliance incident. What matters isn't whether the first attempt gets through; it's whether the hundredth one does. Impart tracks flagged prompt-injection attempts per session, IP, and device, and escalates enforcement, temporarily blocking a source once it crosses a violation threshold, catching persistent attackers a single-message scan alone would miss.

## Install the Impart plugin

{% include_cached /plugins/install-third-party.md name=page.name slug=page.slug rock="kong-plugin-impart" %}

## Enable the plugin

This plugin requires an Impart Inspector running in your environment. Navigate to the Impart console for [step-by-step instructions](https://console.impartsecurity.net/orgs/_/integrations?q=kong).

Once the inspector is running, [enable the Impart plugin](/plugins/impart/examples/enable-impart/) and set `config.inspector_rpc_addr` to the inspector's socket address.

## Test the plugin

After enabling the plugin, send a request through your Kong route as usual to confirm it passes through normally:

```sh
curl -i http://localhost:8000/your-route
```

A request that matches one of your configured detection rules is blocked before it reaches the upstream, returning an HTTP `403` response by default (the status code and response body are configurable per rule from the Impart console).

## Limitations

* Response inspection detects but doesn't block or redact. It evaluates the response only after it has already been sent to the client, so the plugin never buffers or delays streaming responses (for example, LLM completions sent over SSE).
* Request and response bodies are inspected up to a configurable size limit; bodies over the limit are truncated rather than rejected.
* If the Impart Inspector is unreachable, the plugin fails open by default so your gateway stays available.

