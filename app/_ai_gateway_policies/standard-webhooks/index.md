---
description: 'Accept only webhooks that are signed with your shared secret and carry a recent timestamp before they reach your AI Agents and AI MCP Servers.'
min_version:
  ai-gateway: '2.0'
works_on:
  - on-prem
  - konnect
products:
  - ai-gateway
content_type: plugin
categories:
  - traffic-control
tags:
  - webhook
  - traffic-control
  - validation
  - ai
search_aliases:
  - standard webhooks
related_resources:
  - text: AI Policy entity
    url: /ai-gateway/entities/ai-policy/
  - text: AI Agent entity
    url: /ai-gateway/entities/ai-agent/
  - text: AI MCP Server entity
    url: /ai-gateway/entities/ai-mcp-server/
  - text: AI Model entity
    url: /ai-gateway/entities/ai-model/
  - text: AI Consumer Group entity
    url: /ai-gateway/entities/ai-consumer-group/
---

If an external system sends webhooks to your [AI Agents](/ai-gateway/entities/ai-agent/) or [AI MCP Servers](/ai-gateway/entities/ai-mcp-server/), anyone who finds the URL can send forged events.
The Standard Webhooks [AI Policy](/ai-gateway/entities/ai-policy/) accepts only webhook requests that are signed with your shared secret and carry a recent timestamp.
It validates webhooks signed with the Standard Webhooks scheme, an HMAC-SHA256 signature over the message ID, the timestamp, and the request body.
For details about the scheme, see the [Standard Webhooks](https://github.com/standard-webhooks/standard-webhooks) specification.
The policy supports only HMAC-SHA256 signatures.

## How does the Standard Webhooks Policy work?

The Standard Webhooks Policy validates three headers that the sender adds to each webhook:

{% table %}
columns:
  - title: Header
    key: header
  - title: Description
    key: description
rows:
  - header: "`webhook-id`"
    description: The message ID, which is part of the signed content.
  - header: "`webhook-timestamp`"
    description: The time the sender signed the message, as a Unix timestamp in seconds.
  - header: "`webhook-signature`"
    description: The signature in the form `v1,<base64-encoded signature>`.
{% endtable %}

{{site.ai_gateway}} joins the message ID, the timestamp, and the raw request body with dots (`<id>.<timestamp>.<body>`).
It then computes an HMAC-SHA256 of that string with the secret from `config.secret_v1`.
The policy accepts the request when the result matches the signature header and the timestamp is within [`config.tolerance_second`](/ai-gateway/policies/standard-webhooks/reference/#schema--config-tolerance-second).
When validation fails, {{site.ai_gateway}} returns `400` with the message `Bad request`.
The response contains only that message.

Set [`config.secret_v1`](/ai-gateway/policies/standard-webhooks/reference/#schema--config-secret-v1) to the secret that you also configure on the webhook sender.
See [Limitations](#limitations) for how the policy uses the secret as a signing key.

## Set the timestamp tolerance

The [`config.tolerance_second`](/ai-gateway/policies/standard-webhooks/reference/#schema--config-tolerance-second) parameter sets how old a webhook timestamp can be, in seconds.
The default is `300`.
{{site.ai_gateway}} rejects a webhook with a timestamp older than this value.
For example, with `tolerance_second: 60`, a webhook signed 30 seconds ago passes and a webhook signed 90 seconds ago doesn't.

## Scopes

Attach the Standard Webhooks Policy to an AI Agent, an AI MCP Server, or an [AI Consumer Group](/ai-gateway/entities/ai-consumer-group/), or apply it globally.
You can also attach it to an AI Model, but see [Limitations](#limitations) first.
For details about how scopes work, see [AI Policy scopes](/ai-gateway/entities/ai-policy/#ai-policy-scopes).

Consider the following when you choose a scope:
* A policy scoped to an AI Consumer Group applies only after the client authenticates, because authentication runs first.
* A global policy validates every request on the data plane, so every sender needs to sign its requests.
  Use a [`condition`](/ai-gateway/entities/ai-policy/#conditional-ai-policy-execution) to run the policy only for the requests that carry webhooks.

## Limitations

The Standard Webhooks Policy has the following limitations:

* **AI Model scope:** a correctly signed request fails validation when the policy applies to an AI Model, whether you attach it to the AI Model or apply it globally to AI Model traffic.
  The same signature passes on an AI Agent, an AI MCP Server, and an AI Consumer Group.
  Use the policy on those entities instead.
* **Signing key:** the policy uses the configured `secret_v1` string, as you wrote it, as the HMAC key.
  It keeps a `whsec_` prefix and skips base64 decoding, which differs from what the Standard Webhooks specification describes.
  Signatures from a sender that follows the specification are rejected, unless the sender signs with the configured string itself.
* **Future timestamps:** the policy rejects only timestamps that are older than `tolerance_second`.
  It accepts a timestamp that is ahead of the gateway clock by any amount.
* **Multiple signatures:** the policy rejects a `webhook-signature` header with several space-separated signatures when the first signature isn't valid.
* **Error details:** every validation failure returns the same `400` response.
