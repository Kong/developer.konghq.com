---
title: "Attribution in {{site.ai_cost_management}}"
content_type: reference
layout: reference_with_schema

products:
  - ai-cost-management
  - ai-gateway

min_version:
  ai-gateway: '2.3'

works_on:
  - konnect

tools:
  - konnect-api

breadcrumbs:
  - /ai-management/
  - /ai-cost-management/

tags:
  - ai
  - governance
  - cost-management

description: "Attribution in {{site.ai_cost_management}} records who made an AI request and what context surrounded it on every usage event."

schema:
  api: konnect/ai-cost-management
  path: /schemas/AICostAttributionPluginConfiguration

api_specs:
  - konnect/ai-cost-management

faqs:
  - q: Why is the subject absent on a usage event?
    a: |
      A usage event has no subject when the request carried no usable identity.
      Check that an auth strategy is attached to the model and that the token or credential is valid for the strategy's type.
  - q: Why does a {{site.identity}} principal exist that I never created?
    a: |
      Automatic user provisioning can create a principal the first time a caller authenticates.
      Check whether automatic user provisioning is enabled on the trusted IdP and the {{site.ai_gateway}} auth strategy, and whether your [org chart](/ai-cost-management/org-chart/) already lists that user.
  - q: Why are groups absent or incomplete on a usage event?
    a: |
      Groups on a usage event come only from the request's {{site.identity}} group memberships, gateway consumer groups, and JWT claims.
      * For OIDC attribution, check that the token includes `group` or `groups` claims.
      * For principal attribution, check that the principal has the expected group memberships in {{site.identity}}.
  - q: Why is a tag missing from a usage event?
    a: |
      A tag could be missing from a usage event when its header doesn't meet the tag rules.
      Check that the header name is exactly `ai-cost-` followed by a valid key, that the value is between 1 and 256 characters and contains no control characters, and that the gateway received the header.
      
      The gateway drops tags with empty or overlong values without an error.
      If you sent a header more than once in the same request, the gateway also drops the tag.
  - q: Why does enabling attribution show a **Conflict** error for custom plugin streaming?
    a: |
      You may see a **Conflict** error if the {{site.ai_gateway}} you selected has data planes that are running without `KONG_CUSTOM_PLUGIN_STREAMING_ENABLED=on`.

      Data planes without this flag can't load the attribution plugin, so tag capture doesn't work and the toggle can't be enabled.

      Start new data planes with `KONG_CUSTOM_PLUGIN_STREAMING_ENABLED=on`, then enable the toggle again.
      `KONG_CUSTOM_PLUGIN_STREAMING_ENABLED' is enabled by default on [{{site.ai_gateway}} 2.x on Dedicated Cloud Gateways](/dedicated-cloud-gateways/reference/#ai-gateway-2-0-on-dedicated-cloud-gateways).

  - q: Why does cost show $0 on a usage event?
    a: |
      A zero cost means the model had no price configured when the request ran.
      Cost is separate from identity attribution.
      See [Price catalog in {{site.ai_cost_management}}](/ai-cost-management/price-catalog/) to configure a price, and the [analytics and debugging page](/ai-cost-management/analytics-and-debugging/) to check which events show as unpriced.

related_resources:
  - text: Attribution integrations
    url: /ai-cost-management/integrations/
  - text: Analytics and debugging in {{site.ai_cost_management}}
    url: /ai-cost-management/analytics-and-debugging/
  - text: Budgets in {{site.ai_cost_management}}
    url: /ai-cost-management/budgets/
  - text: Org chart in {{site.ai_cost_management}}
    url: /ai-cost-management/org-chart/
  - text: Price catalog in {{site.ai_cost_management}}
    url: /ai-cost-management/price-catalog/
---

When AI requests run through your {{site.ai_gateway}}, you need to know where they came from.
Attribution connects each request to an identity and context.

When attribution is in place, you can use the data in the following ways:
* The cost management [**Dashboard**](/ai-cost-management/analytics-and-debugging/#dashboard) breaks spend down by user, group, team, or tag so you can see where costs are concentrated.
* The events [**Explorer**](/ai-cost-management/analytics-and-debugging/#explorer) lets you filter and compare any of those dimensions over time.
* [**Budgets**](/ai-cost-management/budgets/) can target a specific user, group, team, or tag value, so you can track spend against a cap at whatever scope matters to your organization.

## How attribution works

Attribution works in two tracks as each request passes through the gateway: identity resolution and tag capture.

* **Identity resolution**: The gateway evaluates the token or credential against the auth strategy attached to the model and resolves a subject.
  Group and team membership follows from that subject automatically.
* **Tag capture**: The gateway reads the request headers and records them as tags on the usage event.
  The gateway captures headers prefixed with `ai-cost-` without configuration: the part after the prefix becomes the tag key.

   {:.info}
   > Tag capture requires each {{site.ai_gateway}} data plane to run with `KONG_CUSTOM_PLUGIN_STREAMING_ENABLED=on`.
   > Data planes without this flag don't capture `ai-cost-` headers.
   > `KONG_CUSTOM_PLUGIN_STREAMING_ENABLED' is enabled by default on [{{site.ai_gateway}} 2.x on Dedicated Cloud Gateways](/dedicated-cloud-gateways/reference/#ai-gateway-2-0-on-dedicated-cloud-gateways).
   > See [Set up header-based attribution](#set-up-header-based-attribution) for details.

## Subject

The subject is the primary identity attributed to a usage event.

{{site.ai_cost_management}} sets the subject from the following priority chain, using the first value that applies:

1. A valid [{{site.identity}} Principal](/identity/principals/) UUID is on the request.
1. A valid [AI Consumer](/ai-gateway/entities/ai-consumer/) UUID is on the request.
1. The auth strategy type is `openid-connect-credential-claim` and the token has a `sub` claim.
   The `sub` is the raw value from the token's `sub` claim, between 1 and 255 characters with no line break.

When none of these applies, the event has no subject and is unattributed.
Unattributed events still appear in totals, and you can still match them by group, tag, and model.
In the [dashboard](/ai-cost-management/analytics-and-debugging/#dashboard) and the [events view](/ai-cost-management/analytics-and-debugging/#events-debugger), they show as **Unattributed**.

A user's spend can also show as **Unattributed** by cost center, even with a valid subject.
A cost center is an attribute that the org chart sets independently of the subject.
See [Cost centers](/ai-cost-management/org-chart/#cost-centers).

### Automatic user provisioning

Automatic user provisioning creates a {{site.identity}} principal from the caller's token the first time they authenticate.
It depends on users and teams defined in the [org chart](/ai-cost-management/org-chart/).

To use automatic user provisioning, upload your org structure first, so that a newly provisioned principal matches the correct team and cost center.

## Groups and teams

Groups and teams record the organizational context of the request's principal.

{:.info}
> Groups and teams don't come from tag headers.
> Sending a header such as `ai-cost-groups` doesn't populate these fields.

### Groups

Groups appear in the event's `groups` field as an array of typed references.
They come from any of the following sources:
* The request principal's {{site.identity}} group memberships (as `principal/UUID`)
* The request consumer's gateway consumer groups (as `consumer_group/UUID`)
* JWT `group` or `groups` claims on an `openid-connect` auth strategy (as `oidc/GROUP`)

{{site.identity}} group memberships don't have to exist beforehand.
When automatic user provisioning is enabled, {{site.identity}} creates any group from the caller's token claim that doesn't already exist. The principal then joins those groups.

A single event holds at most 64 groups.

### Teams

Teams appear in the event's `teams` field as an array of `principal/UUID` references.
They come from {{site.identity}} team membership of the request's principal only.
A single event can hold a maximum of 200 teams.

Teams are created when you upload your org structure. See [Org chart in {{site.ai_cost_management}}](/ai-cost-management/org-chart/).

## Tags and headers

Tags are key-value pairs attached to a usage event.
Tags hold context the caller controls: the project, the ticket, the environment, or any other dimension useful for cost allocation.

The gateway captures tags from request headers.
You can set a tag by sending a header named `ai-cost-` followed by the tag key.
For example, to set the `project` tag to `atlas`, send the header `ai-cost-project: atlas`.

### Tag and header rules

The `ai-cost-` headers follow these rules:

- **Key:** Lowercase ASCII letters, digits, `.`, `_`, and `-`, between 1 and 128 characters.
- **Value:** Between 1 and 256 characters, no control characters, case-sensitive.
- Header names arrive in lowercase, so `ai-cost-Project` and `ai-cost-project` are the same header.
- Each `ai-cost-` header must appear once per request.
  The gateway drops the tag when a header is duplicated, even when both values are equal.
- The gateway drops tags with empty values.
- A single event holds at most 64 tags.
  When a request exceeds this limit, the gateway drops all of its tags.
- Don't put PII in a tag, for example a name, email, or username.
  User identity comes from the auth strategy on the model.

Some tools send native headers that the gateway maps to standard tag keys automatically, so you don't need `ai-cost-` headers.
See [Attribution integrations](/ai-cost-management/integrations/) for the supported tools and the tags each one sends.

### Standard tag keys

The following standard tag keys define a shared vocabulary for common dimensions.
A tag can use any valid key.
These conventional names help tags from different tools and teams align.

<!--vale off-->
{% table %}
columns:
  - title: Tag key
    key: key
  - title: Category
    key: category
  - title: Meaning
    key: meaning
rows:
  - category: Project context
    key: "`project`"
    meaning: The project this request belongs to.
  - category: Project context
    key: "`ticket`"
    meaning: The issue or ticket this request relates to.
  - category: Project context
    key: "`environment`"
    meaning: The deployment environment, for example `production` or `staging`.
  - category: Project context
    key: "`use-case`"
    meaning: The intended use case.
  - category: Project context
    key: "`feature`"
    meaning: The product feature driving the request.
  - category: Project context
    key: "`customer-account`"
    meaning: The customer account associated with the request.
  - category: Project context
    key: "`experiment`"
    meaning: The experiment this request is part of.
  - category: Project context
    key: "`experiment-variant`"
    meaning: The variant within the experiment.
  - category: Project context
    key: "`deployment`"
    meaning: The deployment identifier.
  - category: Agent
    key: "`agent-session`"
    meaning: A session identifier for the AI agent.
  - category: Agent
    key: "`agent-id`"
    meaning: The agent's unique identifier.
  - category: Agent
    key: "`agent-parent`"
    meaning: The identifier of the parent agent in a multi-agent setup.
  - category: Agent
    key: "`agent-request-kind`"
    meaning: The kind of request the agent is making.
  - category: Agent
    key: "`agent-type`"
    meaning: The type of agent.
  - category: Agent
    key: "`agent-name`"
    meaning: The agent's display name.
  - category: Agent
    key: "`agent-surface`"
    meaning: The surface the agent is running on.
  - category: Source control
    key: "`scm-provider`"
    meaning: The source control provider, for example `github` or `gitlab`.
  - category: Source control
    key: "`scm-repository`"
    meaning: The repository name.
  - category: Source control
    key: "`scm-branch`"
    meaning: The branch name.
  - category: Source control
    key: "`scm-commit`"
    meaning: The commit SHA.
  - category: Source control
    key: "`scm-pull-request`"
    meaning: The pull or merge request identifier.
  - category: Source control
    key: "`scm-issue`"
    meaning: The source control issue identifier.
  - category: CI
    key: "`ci-provider`"
    meaning: The CI provider, for example `github-actions` or `gitlab-ci`.
  - category: CI
    key: "`ci-pipeline`"
    meaning: The pipeline name or identifier.
  - category: CI
    key: "`ci-run`"
    meaning: The run identifier.
  - category: Chat
    key: "`chat-provider`"
    meaning: The chat platform, for example `slack`.
  - category: Chat
    key: "`chat-organization`"
    meaning: The chat organization or enterprise.
  - category: Chat
    key: "`chat-workspace`"
    meaning: The workspace within the chat platform.
  - category: Chat
    key: "`chat-channel`"
    meaning: The channel name.
  - category: Chat
    key: "`chat-channel-id`"
    meaning: The channel's unique identifier.
  - category: Chat
    key: "`chat-channel-type`"
    meaning: The channel type, for example `dm` or `public`.
  - category: Chat
    key: "`chat-trigger`"
    meaning: The event that triggered the request, for example `slash-command`.
  - category: Chat
    key: "`chat-command`"
    meaning: The specific command or action invoked.
  - category: Workflow
    key: "`workflow-name`"
    meaning: The workflow or pipeline name.
  - category: Workflow
    key: "`workflow-run`"
    meaning: The workflow run identifier.
{% endtable %}
<!--vale on-->

### Custom tag keys

You can define custom keys for any dimension the standard keys don't cover.
A custom key follows the same [rules](#tag-and-header-rules) as any other tag key.

To avoid conflicts with future standard keys, prefix custom keys with a namespace, for example `acme-cost-center-` or `internal-team-`.

## Set up attribution

Attribution has two independent parts: the subject on each event and the tags.

### Set up subject attribution

Identity attribution comes from the [AI Auth Strategy](/ai-gateway/entities/ai-auth-strategy/) on the AI Model.
{{site.ai_gateway}} evaluates the strategy on each request and attributes it to the authenticated subject, so no further configuration is needed.

The strategy type determines which subject you get:

* A `key-auth` or `basic-auth` strategy attributes the request to its [AI Consumer](/ai-gateway/entities/ai-consumer/).
* An `openid-connect` strategy with `principals.enabled` attributes the request to a {{site.identity}} principal.
  Pair it with a [trusted IdP](/identity/token-vault/#trusted-idp) and [automatic user provisioning](#automatic-user-provisioning) to create a principal on first login.
* An `openid-connect-credential-claim` strategy attributes the request to the token's raw `sub` claim, with no principal or consumer involved.

Principal-based attribution also depends on the [org chart](/ai-cost-management/org-chart/).
Upload your org structure before the first request, so a newly provisioned principal already has a team and cost center to join.

### Set up header-based attribution

Header-based attribution captures `ai-cost-` headers from each request and records them as tags on the usage event.

#### Prerequisites

Your {{site.ai_gateway}} data planes are running with [`KONG_CUSTOM_PLUGIN_STREAMING_ENABLED=on`](/gateway/configuration/#custom-plugin-streaming-enabled).
If you try to enable attribution on an {{site.ai_gateway}} with data planes that are missing this flag, you will see a **Conflict** error.

#### Set up

Set up header-based attribution from the {{site.konnect_short_name}} UI or the API.

{% navtabs "set-up-header-based-attribution" %}
{% navtab "Konnect UI" %}

Configure tag capture via headers in the {{site.konnect_short_name}} UI:
1. In {{site.konnect_short_name}}, switch to the AI view.
1. In the sidebar, click **Cost Management**.
1. In the sidebar, click **Attribution**.
1. *Optional*: Click the **Header builder** tab to help you generate the `ai-cost-` headers for your tool.
   Choose the output format (curl, HTTP headers, Claude Code, Codex, OpenCode, or Gemini CLI), enter your tags, and copy the result. 

   {:.info}
   > **Note**: The **Header builder** is a helper tool that formats your headers in the correct way.
   Use the tool to help you build headers, and then copy those headers into your integration. 
   Nothing you enter leaves this page.

1. Click the **Integrations** tab.
1. Click your integration, or choose **Your own code** for custom configuration.
1. Follow the on-screen instructions to add headers to your integration.
1. *Optional*: Some providers have a per-gateway toggle under **Turn it on in your gateways**. 
Enable the toggle next to each {{site.ai_gateway}} where you want attribution active.

{% endnavtab %}
{% navtab "Konnect API" %}

Install the plugin using the [`/v1/ai-cost-management/ai-gateways/{gatewayId}/attribution-plugin`](/api/konnect/ai-cost-management/#/operations/upsert-cost-attribution-plugin) endpoint of the {{site.ai_cost_management}} API:

<!--vale off-->
{% konnect_api_request %}
url: /v1/ai-cost-management/ai-gateways/$AI_GATEWAY_ID/attribution-plugin
method: PUT
status_code: 201
body:
  integrations: []
  headers: []
  prefixes: []
  operator_tags: {}
{% endkonnect_api_request %}
<!--vale on-->

{% endnavtab %}
{% endnavtabs %}

## Attribution plugin schema

{% entity_schema %}