---
title: "Agents in {{site.konnect_catalog}}"
content_type: reference
layout: reference
beta: true
products:
    - catalog
    - ai-gateway

breadcrumbs:
  - /catalog/

works_on:
  - konnect

search_aliases:
  - A2A
  - agent card
  - AI agent

description: An Agent is an interface in {{site.konnect_catalog}} that represents an A2A-compatible agent your organization builds or consumes. Learn how to create and manage Agents.

related_resources:
  - text: "{{site.konnect_catalog}}"
    url: /catalog/
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/
  - text: "MCP Registries (tech preview)"
    url: /catalog/mcp-registry/
  - text: "AI Models"
    url: /catalog/ai-models/
---

An Agent is an interface in {{site.konnect_catalog}} modeled on the [A2A protocol's](https://a2a-protocol.org/v1.0.0/specification/#441-agentcard) AgentCard, representing an agent that your organization builds or consumes.
{{site.konnect_catalog}} gives you a single place to see every agent across your organization, whether it's registered from a pasted card, discovered from a remote host, or linked to {{site.ai_gateway}} 2.0 AI Agent entities, so teams don't have to track agents individually in separate tools.

You can create an Agent in three ways:
* Paste the agent's A2A card directly as JSON.
* (Coming soon) Import it from a remote host that serves an A2A card at a well-known URL.
* (Coming soon) Link it to an AI Agent entity from {{site.ai_gateway}} 2.0.

{{site.konnect_catalog}} Agents represent the agents available across your organization, regardless of where they are defined or run. 
When an Agent is also configured in {{site.ai_gateway}}, you can link the {{site.konnect_catalog}} Agent to its corresponding {{site.ai_gateway}} representation. 
That relationship identifies {{site.ai_gateway}} as an implementation of the Agent, which indicates that the Agent is served or protected through {{site.ai_gateway}}.

## Create an Agent

1. In the {{site.konnect_short_name}} sidebar, click **Catalog**.
1. From the **New** dropdown menu, select **Agent**.
1. Under **Data source**, select **Paste JSON**.
1. In the **Agent card JSON** field, paste the agent's A2A card. The card must include a `name`, `description`, and `version`. A live preview of the card renders under **Card preview**.
1. In the **Display name** field, enter a name for your Agent, for example `My Agent`.
1. In the **Name** field, enter a unique identifier for the Agent, for example `my-agent`. This is derived from the display name until you edit it. Only use lowercase letters, numbers, hyphens, and periods.
1. (Optional) In the **Description** field, describe the purpose of your Agent. Leave this blank to use the description from the agent card.
1. (Optional) Click **Add labels**, and do the following:
   1. In the **Key** field, enter a label key.
   1. In the **Value** field, enter a label value.
   1. (Optional) Click **Add another label** to add more labels.
1. Click **Create**.

{% comment %}
{% navtabs "create-agent" %}
{% navtab "{{site.konnect_short_name}} API" %}
Creating an Agent from a remote URL or linking one to {{site.ai_gateway}} 2.0 is coming soon. Today, send a POST request to the `/agents` endpoint with `source_type: manual` and the agent's A2A card. The card must include a `name`, `description`, and `version`:
<!--vale off-->
{% konnect_api_request %}
url: /v1/agents
status_code: 201
method: POST
body:
    source_type: manual
    display_name: My Agent
    agent_card:
        name: my-agent
        description: Handles customer support triage
        version: 1.0.0
extract_body:
    - name: 'id'
      variable: AGENT_ID
{% endkonnect_api_request %}
<!--vale on-->
{% endnavtab %}
{% navtab "{{site.konnect_short_name}} UI" %}
1. In the {{site.konnect_short_name}} sidebar, click **Catalog**.
1. From the **New** dropdown menu, select **Agent**.
1. Under **Data source**, select **Paste JSON**.
1. In the **Agent card JSON** field, paste the agent's A2A card. The card must include a `name`, `description`, and `version`. A live preview of the card renders under **Card preview**.
1. In the **Display name** field, enter a name for your Agent, for example `My Agent`.
1. In the **Name** field, enter a unique identifier for the Agent, for example `my-agent`. This is derived from the display name until you edit it. Only use lowercase letters, numbers, hyphens, and periods.
1. (Optional) In the **Description** field, describe the purpose of your Agent. Leave this blank to use the description from the agent card.
1. (Optional) Click **Add labels**, and do the following:
   1. In the **Key** field, enter a label key.
   1. In the **Value** field, enter a label value.
   1. (Optional) Click **Add another label** to add more labels.
1. Click **Create**.
{% endnavtab %}
{% endnavtabs %}
{% endcomment %}
