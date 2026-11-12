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
      Groups on a usage event come from the request's {{site.identity}} group memberships, gateway consumer groups, and JWT claims.
      * For OIDC attribution, check that the attribution plugin is installed on the gateway, that the token includes `group` or `groups` claims, and that the **Groups from tokens** patterns match the group names.
      * For principal attribution, check that the principal has the expected group memberships in {{site.identity}}.
      * Check that no source exceeds its [group limit](#groups). A source over its limit adds no groups to the event.
  - q: Why is a tag missing from a usage event?
    a: |
      A tag could be missing from a usage event when its header doesn't meet the tag rules.
      Check that the header name is exactly `ai-cost-` followed by a valid key, that the value is between 1 and 256 characters and contains no control characters, and that the gateway received the header.
      
      The gateway drops tags with empty values without an error.
      With the attribution plugin, a value over 256 characters is cut to 256.
      Without the plugin, one invalid value can remove all of the event's tags.
      If you sent a header more than once in the same request, the gateway also drops the tag.
  - q: Why does enabling attribution show a **Conflict** error for custom plugin streaming?
    a: |
      You may see a **Conflict** error if the {{site.ai_gateway}} you selected has data planes that are running without `KONG_CUSTOM_PLUGIN_STREAMING_ENABLED=on`.

      Data planes without this flag can't load the attribution plugin, so the toggle can't be enabled.
      These data planes still capture `ai-cost-` headers, which don't need the plugin.

      Start new data planes with `KONG_CUSTOM_PLUGIN_STREAMING_ENABLED=on`, then enable the toggle again.
      `KONG_CUSTOM_PLUGIN_STREAMING_ENABLED` is enabled by default on [{{site.ai_gateway}} 2.x on Dedicated Cloud Gateways](/dedicated-cloud-gateways/reference/#ai-gateway-2-0-on-dedicated-cloud-gateways).

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
   > Data planes on {{site.ai_gateway}} 2.3 or later capture `ai-cost-` headers without any setup.
   > The attribution plugin, which reads tools' own headers, header mappings, tags on every request, and groups from tokens, needs `KONG_CUSTOM_PLUGIN_STREAMING_ENABLED=on` on every data plane.
   > `KONG_CUSTOM_PLUGIN_STREAMING_ENABLED` is enabled by default on [{{site.ai_gateway}} 2.x on Dedicated Cloud Gateways](/dedicated-cloud-gateways/reference/#ai-gateway-2-0-on-dedicated-cloud-gateways).
   > See [Set up header-based attribution](#set-up-header-based-attribution) for details.

## Subject

The subject is the primary identity attributed to a usage event.

{{site.ai_cost_management}} sets the subject from the following priority chain, using the first value that applies:

1. A valid [{{site.identity}} Principal](/identity/principals/) UUID is on the request.
1. A valid gateway Consumer or [AI Consumer](/ai-gateway/entities/ai-consumer/) UUID is on the request.
1. An `openid-connect` auth strategy without principals authenticated the request, and the token has a `sub` claim.
   The `sub` is the raw value from the token's `sub` claim, between 1 and 255 characters with no line break.

When none of these applies, the event has no subject and is unattributed.
Unattributed events still appear in totals, and you can still match them by group, tag, and model.
In the [dashboard](/ai-cost-management/analytics-and-debugging/#dashboard) and the [events view](/ai-cost-management/analytics-and-debugging/#events-debugger), they show as **Unattributed**.

### Automatic user provisioning

Automatic user provisioning creates a {{site.identity}} principal from the caller's token the first time they authenticate.
It depends on users and teams defined in the [org chart](/ai-cost-management/org-chart/).

To use automatic user provisioning, upload your org structure first, so that a newly provisioned principal matches the correct team and cost center.

## Groups and teams

Groups and teams record the organizational context of the request's principal.

{:.info}
> Teams never come from request headers.
> Under the attribution plugin, no header sets a group either.
> On a data plane without the plugin, an `ai-cost-group` or `ai-cost-groups` header still sets groups.
> Install the [attribution plugin](#set-up-header-based-attribution) to stop clients from setting their own groups.

### Groups

Groups appear in the event's `groups` field as an array of typed references.
They come from any of the following sources:
* The request principal's {{site.identity}} group memberships (as `principal/UUID`)
* The request consumer's gateway consumer groups (as `consumer_group/UUID`)
* JWT `group` or `groups` claims, when the attribution plugin is installed on the gateway (as `oidc/GROUP`)

The attribution plugin keeps the token's groups that match its **Groups from tokens** patterns (`group_patterns`), or every group when there are no patterns.
It drops a claim whole when more than 64 groups in it match.

Each source has its own limit: 200 {{site.identity}} groups, 64 consumer groups, and 64 OIDC groups.
When a source exceeds its limit, the event gets no groups from that source and keeps the groups from the others.

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

- **Key:** Lowercase letters and digits in words joined by single hyphens, at most 128 characters, such as `cost-center`.
  A key with `.`, `_`, or a double hyphen produces no tag.
- **Value:** Between 1 and 256 characters, no control characters, case-sensitive.
- Header names arrive in lowercase, so `ai-cost-Project` and `ai-cost-project` are the same header.
- Each `ai-cost-` header must appear once per request.
  The gateway drops the tag when a header is duplicated, even when both values are equal.
- The gateway drops tags with empty values.
- With the attribution plugin, values over 256 characters are cut to 256, and a request keeps at most 64 tags, dropping the lowest-precedence tags first.
  See [Tag precedence](#tag-precedence).
- Without the plugin, keep values within 256 characters, because one invalid value can remove all of the event's tags.
- Don't put PII in a tag, for example a name, email, or username.
  User identity comes from the auth strategy on the model.

Some tools send native headers that the attribution plugin maps to standard tag keys, so you don't need `ai-cost-` headers for those tags.
See [Attribution integrations](/ai-cost-management/integrations/) for the supported tools and the tags each one sends.

### Tag precedence

When two sources give the same tag key, the attribution plugin keeps the value from the source that comes first in the following list:
1. Tags on every request (`operator_tags`)
1. Mapped headers (`headers`)
1. Mapped prefixes (`prefixes`)
1. `ai-cost-` headers
1. Other AI gateways' headers, such as Helicone, Portkey, and Cloudflare AI Gateway metadata
1. Tools' own headers, such as Claude Code and Codex CLI headers

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
  - category: Agent
    key: "`agent-plugin`"
    meaning: The plugin or extension that sends the tool's requests to the gateway, with its version when the tool reports one.
  - category: Agent
    key: "`agent-version`"
    meaning: The release of the coding tool. The gateway sets it from the `User-Agent` header of recognized coding tools.
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
    meaning: The CI provider, for example `github_actions` or `gitlab_ci`.
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

* A `key-auth` strategy attributes the request to its [AI Consumer](/ai-gateway/entities/ai-consumer/).
* An `openid-connect` strategy with `principals.enabled` attributes the request to a {{site.identity}} principal.
  Pair it with a [trusted IdP](/identity/token-vault/#trusted-idp) and [automatic user provisioning](#automatic-user-provisioning) to create a principal on first login.
* An `openid-connect` strategy without `principals.enabled` attributes the request to the token's raw `sub` claim, with no principal or consumer involved.
  Keep `credential_claim` at its default, `sub`.
  The usage event doesn't record which claim was used, and a claim such as `email` puts personal data in the subject.

Principal-based attribution also depends on the [org chart](/ai-cost-management/org-chart/).
Upload your org structure before the first request, so a newly provisioned principal already has a team and cost center to join.

### Set up header-based attribution

Header-based attribution captures `ai-cost-` headers from each request and records them as tags on the usage event.
Data planes on {{site.ai_gateway}} 2.3 or later capture `ai-cost-` headers without any setup.

The attribution plugin adds more sources: tools' own headers, header mappings, tags on every request, and groups from tokens.
Install it on each {{site.ai_gateway}} where you need these sources.

#### Prerequisites

The following prerequisites apply to the attribution plugin:
* Your {{site.ai_gateway}} data planes are running with [`KONG_CUSTOM_PLUGIN_STREAMING_ENABLED=on`](/gateway/configuration/#custom-plugin-streaming-enabled).
  If you try to enable attribution on an {{site.ai_gateway}} with data planes that are missing this flag, you will see a **Conflict** error.
* You have the AI Gateways Admin role on the {{site.ai_gateway}}, because the plugin is written to the gateway with your credentials.

{:.warning}
> While the attribution plugin is installed, a data plane without `KONG_CUSTOM_PLUGIN_STREAMING_ENABLED=on` rejects the gateway's whole configuration, not only the plugin.
> Set the flag on every new data plane before it connects.

#### Set up

Set up header-based attribution from the {{site.konnect_short_name}} UI or the API.

{% navtabs "set-up-header-based-attribution" %}
{% navtab "Konnect UI" %}

Configure tag capture via headers in the {{site.konnect_short_name}} UI:
1. In {{site.konnect_short_name}}, switch to the AI view.
1. In the sidebar, click **Cost Management**.
1. In the sidebar, click **Attribution**.
1. Click the **Integrations** tab.
1. Click your integration, or choose **Your own code** for custom configuration.
1. Follow the on-screen instructions to add headers to your integration.
1. *Optional*: Some providers have a per-gateway toggle under **Turn it on in your gateways**. 
Enable the toggle next to each {{site.ai_gateway}} where you want attribution active.

The **Attribution** page has two more tabs:
* **Cost tags** maps your own request headers and header prefixes to tags on every {{site.ai_gateway}} that has the attribution plugin, and lists the standard tags in the **Tag catalog**.
* **Gateways** installs, edits, updates, and removes the attribution plugin on each {{site.ai_gateway}}.
  Installing or editing the plugin on a gateway also sets that gateway's **Tags on every request** and **Groups from tokens**.

{% endnavtab %}
{% navtab "Konnect API" %}

Install the plugin using the [`/v1/ai-cost-management/ai-gateways/{gatewayId}/attribution-plugin`](/api/konnect/ai-cost-management/#/operations/upsert-cost-attribution-plugin) endpoint of the {{site.ai_cost_management}} API:

<!--vale off-->
{% konnect_api_request %}
url: /v1/ai-cost-management/ai-gateways/$AI_GATEWAY_ID/attribution-plugin
method: PUT
status_code: 201
body:
  integrations:
    - claude-code
    - codex
  headers: []
  prefixes: []
  operator_tags: {}
{% endkonnect_api_request %}
<!--vale on-->

{% endnavtab %}
{% endnavtabs %}

## Attribution plugin schema

The attribution plugin configuration has the following fields:
* `integrations`: The tools whose own headers the plugin reads, such as `claude-code` and `codex`.
* `headers`: Request headers mapped to tag keys, one header to one key.
* `prefixes`: Header prefixes whose headers become tags. With the prefix `my-co`, the header `my-co-region` becomes the tag `region`.
* `operator_tags`: Tags added to every request through the gateway, as a map of tag key to value. The UI calls these **Tags on every request**.
* `group_patterns`: Regular expressions that choose which groups the plugin keeps from a token's `group` and `groups` claims. The UI calls these **Groups from tokens**.

`headers` and `prefixes` hold at most 32 entries together.
Credential headers, such as `authorization`, can't be mapped.

Plugin updates are manual.
To update a gateway to the latest plugin version, select **Update to** in its actions menu on the **Gateways** tab, or send a `PUT` with the gateway's stored configuration.

{% entity_schema %}