---
min_version:
  ai-gateway: '2.0'
works_on:
  - on-prem
  - konnect
products:
  - ai-gateway
content_type: plugin
description: 'Block crawlers, scripted clients, and other unwanted User-Agents from calling your AI Models, AI Agents, and AI MCP Servers.'
categories:
  - security
tags:
  - security
  - ai
search_aliases:
  - bot-detection
  - user-agent
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

Crawlers and scripted clients can call your [AI Models](/ai-gateway/entities/ai-model/), [AI Agents](/ai-gateway/entities/ai-agent/), and [AI MCP Servers](/ai-gateway/entities/ai-mcp-server/) and use up your provider tokens and upstream capacity.
The Bot Detection [AI Policy](/ai-gateway/entities/ai-policy/) blocks these requests in {{site.ai_gateway}} based on the `User-Agent` header, before they reach the upstream.
It blocks a built-in list of common bots, and you can add your own patterns to deny or allow specific clients.

## How does the Bot Detection Policy work?

The Bot Detection Policy compares the `User-Agent` header of each request against the built-in list and your custom patterns.
When the header matches, {{site.ai_gateway}} rejects the request with a `403 Forbidden` response.

{{site.ai_gateway}} sends the `403` response before it forwards the request upstream, so a blocked streaming request doesn't open a stream.
Requests without a `User-Agent` header pass through.

The [AI Auth Strategy](/ai-gateway/entities/ai-auth-strategy/) runs before the Bot Detection Policy.
When an AI Model requires authentication, a bot without valid credentials receives a `401` response from the AI Auth Strategy before the Bot Detection Policy runs.

## Built-in bot list

The Bot Detection Policy blocks [common bots](https://github.com/Kong/kong/blob/master/kong/plugins/bot-detection/rules.lua) by default, such as the `Googlebot` and `bingbot` search engine crawlers.

The built-in list also includes HTTP client libraries that scripts use.
If your applications, SDKs, or agent frameworks use one of these libraries, the Policy blocks them unless you allow them:

* `Go-http-client`
* `axios`
* `okhttp`
* `Python-urllib`
* `Apache-HttpClient`
* `reqwest`
* `aws-sdk-*` and `Boto3`

The following example applies the built-in list to all traffic:

{% entity_example %}
type: policy
data:
  name: block-common-bots
  display_name: Block common bots
  type: bot-detection
  global: true
  config: {}
formats:
  - konnect-api
  - kongctl
{% endentity_example %}

## Deny or allow custom User-Agents

The Bot Detection Policy's [`config.deny`](/ai-gateway/policies/bot-detection/reference/#schema--config-deny) setting blocks additional clients, and [`config.allow`](/ai-gateway/policies/bot-detection/reference/#schema--config-allow) lets specific clients through.
Both settings take a list of regular expressions that the Policy matches against any part of the `User-Agent` header.

An `allow` pattern takes precedence over the built-in list and over `deny`.
When a `User-Agent` matches both an `allow` pattern and a `deny` pattern, {{site.ai_gateway}} accepts the request.

Patterns are case-sensitive.
To match a pattern regardless of case, start it with `(?i)`.

The following example allows a client built on the Go HTTP library and blocks any `User-Agent` that contains `scraper`, in any case:

{% entity_example %}
type: policy
data:
  name: bot-detection-custom
  display_name: Bot Detection with custom patterns
  type: bot-detection
  global: true
  config:
    allow:
      - Go-http-client
    deny:
      - (?i)scraper
formats:
  - konnect-api
  - kongctl
{% endentity_example %}
