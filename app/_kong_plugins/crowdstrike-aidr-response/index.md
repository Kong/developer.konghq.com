---
title: 'CrowdStrike AIDR Response'
name: 'CrowdStrike AIDR Response'

content_type: plugin

publisher: crowdstrike
description: 'Inspect LLM responses against CrowdStrike AIDR output rules, redacting or blocking sensitive content before delivery to the client'

products:
  - gateway
  - ai-gateway

works_on:
  - on-prem
  - konnect

third_party: true
source_code_url: 'https://github.com/crowdstrike/aidr-kong'
support_url: 'https://supportportal.crowdstrike.com'

icon: falcon.svg

tags:
  - security
  - ai

search_aliases:
  - crowdstrike-aidr-response
  - crowdstrike falcon
  - aidr
  - ai detection and response
  - llm security
  - ai security

min_version:
  gateway: '3.8'

related_resources:
  - text: CrowdStrike AIDR documentation
    url: https://pangea.cloud/docs/aidr
  - text: CrowdStrike AIDR Request plugin
    url: /plugins/crowdstrike-aidr-request/
---

The {{page.name}} plugin intercepts LLM responses before they are returned to the client, evaluating them against CrowdStrike's AIDR [output rules](https://aidr-docs.crowdstrike.com/docs/aidr/policies/prompt-rules) in real time.
Responses that violate your security policies can be redacted, masked, or blocked at the gateway. No application code changes required.

{:.info}
> Use this plugin together with the [CrowdStrike AIDR Request plugin](/plugins/crowdstrike-aidr-request/) to protect both sides of your AI traffic.

Integrating the {{page.name}} plugin into your {{site.base_gateway}} allows you to:
* **Redact PII and sensitive data from LLM output**: Automatically mask or remove sensitive content before it reaches the client.
* **Block non-compliant LLM responses**: Enforce output rules to prevent harmful, restricted, or policy-violating content from being delivered.
* **Centralize AI security visibility**: Stream audit events to the CrowdStrike AIDR console and Next-Gen SIEM without modifying your application.

## How it works

The {{page.name}} plugin runs in the response phase. After the upstream LLM returns a response, the plugin submits it to the CrowdStrike AIDR AI Guard API for evaluation against your output rules. Based on the verdict, the plugin either delivers the (potentially redacted) response or blocks it before it reaches the client.

<!-- vale off-->
{% mermaid %}
sequenceDiagram
autonumber
    participant Client
    participant LLM
    participant Plugin as {{site.base_gateway}}<br/>AIDR Response plugin
    participant AIDR as CrowdStrike AIDR

    Client->>LLM: Send request (via {{site.base_gateway}})
    LLM-->>Plugin: Return LLM response
    Plugin->>AIDR: Submit response against output rules
    AIDR-->>Plugin: Verdict

    alt Response flagged
        Plugin->>Client: Return blocked or redacted response
    else Response allowed
        Plugin->>Client: Return LLM response
    end
{% endmermaid %}
<!-- vale on-->

### LLM support

{% include_cached /plugins/crowdstrike-aidr/llm-support.md name=page.name %}

## Install the {{page.name}} plugin

{% include_cached /plugins/crowdstrike-aidr/install.md plugin_slug="crowdstrike-aidr-response" other_plugin_slug="crowdstrike-aidr-request" other_plugin_name="CrowdStrike AIDR Request" name=page.name %}

## Enable the plugin

After installing the plugin, [enable the CrowdStrike AIDR Response plugin](/plugins/crowdstrike-aidr-response/examples/enable-crowdstrike-aidr-response/).

If you're routing LLM traffic through {{site.ai_gateway}}, [set up {{site.ai_gateway}}](/ai-gateway/get-started/) first by creating a Service, a Route, and enabling the AI Proxy plugin. Then set `upstream_llm.provider` to `kong` and `upstream_llm.api_uri` to the AI Proxy route path.

## Test the plugin

After enabling the plugin, verify it's redacting sensitive data from LLM responses as expected.

Send a prompt asking the LLM to include a social security number in its response:

```sh
curl -s -X POST http://localhost:8000/your-route \
  -H "Content-Type: application/json" \
  -d '{"messages": [{"role": "user", "content": "Return a sample social security number in your response."}]}'
```

If the plugin is working correctly and your AIDR policy includes a PII Output Rule, any SSN in the LLM response is redacted before it reaches the client. 
The response should look something like this:

```json
{
  "choices": [
    {
      "message": {
        "content": "Here it is: *******7890. Let me know if you would like me to draft a loan application! 🚀 ",
        "role": "assistant"
      }
    }
  ],
  "object": "chat.completion"
}
```
The event also appears in the AIDR console under your collector.

## View collector data in AIDR

{% include_cached /plugins/crowdstrike-aidr/view-collector-data.md %}