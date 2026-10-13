---
min_version:
  ai-gateway: '2.0'
works_on:
  - konnect
products:
  - ai-gateway
content_type: plugin
description: 'Allow or deny client IP addresses and CIDR ranges that can send requests to your AI Models, AI Agents, and AI MCP Servers.'
categories:
  - security
tags:
  - security
  - ai
search_aliases:
  - ip-restriction
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

The IP Restriction [AI Policy](/ai-gateway/entities/ai-policy/) restricts access to your [AI Models](/ai-gateway/entities/ai-model/), [AI Agents](/ai-gateway/entities/ai-agent/), and [AI MCP Servers](/ai-gateway/entities/ai-mcp-server/) by allowing or denying client IP addresses.
This can help block malicious activity, such as spam or traffic from unwanted networks.
You can use single IPs, multiple IPs, or ranges in [Classless Inter-Domain Routing (CIDR) notation](https://datatracker.ietf.org/doc/html/rfc4632) like `10.10.10.0/24`.
The policy supports IPv4 and IPv6 addresses.

## How does the IP Restriction Policy work?

Configure the policy with an `allow` list of IP addresses or ranges to allow and a `deny` list of IP addresses or ranges to reject.
When only an `allow` list is configured, {{site.ai_gateway}} rejects all IP addresses that aren't on that list.
When only a `deny` list is configured, {{site.ai_gateway}} accepts all IP addresses that aren't on the `deny` list.

Configuring both lists is useful if you want to allow a CIDR range but deny an IP address in that range.

The following example allows `203.0.113.0/24` but denies `203.0.113.5`:

{% entity_example %}
type: policy
data:
  name: ip-allow-range-deny-address
  display_name: IP Allow Range and Deny Address
  type: ip-restriction
  global: true
  config:
    allow:
      - 203.0.113.0/24
    deny:
      - 203.0.113.5
formats:
  - konnect-api
{% endentity_example %}

## Choose between an allow list, a deny list, or both

If you need to limit access to known networks, such as an office VPN or a partner's address range, use an `allow` list.
If you need to block specific addresses and accept everything else, use a `deny` list.
If you need an exception inside an allowed range, use both lists.

## Scopes

Apply the IP Restriction Policy globally to restrict all {{site.ai_gateway}} traffic on the data plane, or attach it to an AI Agent or AI MCP Server to restrict access to that entity only.
For details about how scopes work, see [AI Policy scopes](/ai-gateway/entities/ai-policy/#ai-policy-scopes).

{:.warning}
> **AI Model scope:** Do not attach an IP Restriction Policy to an AI Model to block clients.
>
> The AI Policy runs before {{site.ai_gateway}} identifies the Model for the request, so its Model scope never matches and {{site.ai_gateway}} skips the policy without logging anything.
>
> The control plane still accepts the configuration, so the request succeeds and the restriction isn't applied.
> As a temporary workaround, apply the policy globally and use a [`condition`](/ai-gateway/entities/ai-policy/#conditional-ai-policy-execution) to run it only where you need it.

## How is the IP address determined?

{{site.ai_gateway}} determines the client IP address from a request header set by the client or by a proxy in front of {{site.ai_gateway}}.
In most cases, the header is named `X-Real-IP` or `X-Forwarded-For`.

By default, {{site.ai_gateway}} uses the `X-Real-IP` header.
If your environment requires a different header, set the [`real_ip_header`](/ai-gateway/configuration/#real-ip-header) Nginx property.

{{site.ai_gateway}} only reads the client IP from the header when the request comes from an address listed in the [`trusted_ips`](/ai-gateway/configuration/#trusted-ips) Nginx property, such as your load balancer.
For any other sender, it ignores the header and uses the IP address of the direct connection.
If `trusted_ips` isn't set, the policy evaluates the IP of the proxy or network gateway in front of {{site.ai_gateway}}, not the original client.

{:.warning}
> If you configure only an `allow` list and the load balancer or proxy in front of {{site.ai_gateway}} isn't listed in `trusted_ips`, {{site.ai_gateway}} evaluates that address instead of the client's and can reject all traffic.
