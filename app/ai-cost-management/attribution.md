---
title: "Attribution in {{site.ai_cost_management}}"
content_type: reference
layout: reference

products:
  - ai-cost-management

min_version:
  ai-gateway: '2.3'

works_on:
  - konnect

tools:
  - konnect-api

breadcrumbs:
  - /ai-cost-management/

tags:
  - ai
  - governance
  - metering

description: "Attribution in {{site.ai_cost_management}} records who made an AI request and what context surrounded it on every usage event."

api_specs:
  - konnect/ai-cost-management

faqs:
  - q: Why is the subject absent on a usage event?
    a: |
      No usable identity was present on the request.
      Check that an auth strategy is attached to the model and that the token or credential is valid for the strategy's type.
  - q: Why are groups absent or incomplete on a usage event?
    a: |
      Groups come from JWT claims and Kong Identity group memberships, not from `ai-cost-` headers.
      For OIDC attribution, check that the token includes `group` or `groups` claims.
      For principal attribution, check that the principal has the expected group memberships in Kong Identity.
  - q: Why is a tag missing from a usage event?
    a: |
      Check that the header name is exactly `ai-cost-` followed by a valid key, that the value is between 1 and 256 characters and contains no control characters, and that the header reached the gateway.
      The gateway drops tags with empty or overlong values silently.
      If you sent a header more than once in the same request, the tag is also dropped.
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
  - text: Price catalog in {{site.ai_cost_management}}
    url: /ai-cost-management/price-catalog/
---

When AI requests run through your {{site.ai_gateway}}, you need to know where they came from.
Attribution connects each request to an identity and context.

With attribution in place, you can use the data in the following ways:
* The **cost management dashboard** breaks spend down by user, group, team, or tag so you can see where costs are concentrated.
* The **events explorer** lets you filter and compare any of those dimensions over time.
* **Budget limits** can target a specific user, group, or tag value, so you can enforce spend caps at whatever scope matters to your organization.

## How attribution works

Attribution works in two tracks as each request passes through the gateway: identity resolution and tag capture.

* **Identity resolution**: The gateway evaluates the token or credential against the auth strategy attached to the model and resolves a subject. Group and team membership follows from that subject automatically.
* **Tag capture**: The gateway reads the request headers and records them as tags on the usage event.
Headers prefixed with `ai-cost-` are captured automatically: the part after the prefix becomes the tag key, with no configuration needed.

## Subject

The subject is the primary identity attributed to a usage event.

{{site.ai_cost_management}} sets the subject from the following priority chain, using the first value that applies:

1. A valid [{{site.identity}} Principal](/identity/principals/) UUID is on the request.
1. A valid [AI Consumer](/ai-gateway/entities/ai-consumer/) UUID is on the request.
1. The auth strategy type is `openid-connect-credential-claim` and the token has a `sub` claim.
   The `sub` is the raw value from the token's `sub` claim, between 1 and 255 characters with no line break.
1. No usable identity value present. The event is unattributed.

When no usable identity is present on the request, the event has no subject and is considered unattributed.
Unattributed events still appear in totals and are matchable by group, tag, and model, but they show as **Unattributed** in the Dashboard and Events debugger.

## Groups and teams

Groups and teams record the organizational context of the request's principal.

{:.info}
> Groups and teams don't come from tag headers.
> Sending a header named `ai-cost-groups` or similar doesn't populate these fields.

### Groups

Groups appear in the event's `groups` field as an array of typed references.
They come from any of the following sources:
* The request principal's {{site.identity}} group memberships (as `principal/UUID`)
* The request consumer's gateway consumer groups (as `consumer_group/UUID`)
* JWT `group` or `groups` claims on an `openid-connect` auth strategy (as `oidc/GROUP`)

A single event holds at most 328 groups.

### Teams

Teams appear in the event's `teams` field as an array of `principal/UUID` references.
They come from {{site.identity}} team membership of the request's principal only.
A single event can hold a maximum of 200 teams.

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
- Each `ai-cost-` header must appear once per request. A duplicate header drops that tag, even when both values are equal.
- Empty values are skipped.
- A single event holds at most 64 tags. A request that exceeds this limit has all its tags dropped.
- Don't put PII in a tag, for example a name, email, or username.
User identity comes from the auth strategy on the model.

Some tools send native headers that the gateway maps to standard tag keys automatically, without needing `ai-cost-` prefix headers.
See the [integrations catalog](/ai-cost-management/integrations/) for details.

### Standard tag keys

The following standard tag keys define a shared vocabulary for common dimensions.
Any key works in a tag. These are conventional names so that tags from different tools and teams align.

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

Some tools send their own attribution context through native headers that {{site.ai_gateway}} translates automatically into tag keys.
See the [integrations catalog](/ai-cost-management/integrations/) for the full list of supported tools and what tags each one sends.

## Set up attribution

Attribution has two independent parts: the subject on each event and the tags.

### Set up subject attribution

Identity attribution comes from the [AI Auth Strategy](/ai-gateway/entities/ai-auth-strategy/) on the AI Model.
{{site.ai_gateway}} evaluates it on each request and resolves the subject automatically.

Each request to that model is attributed to the authenticated subject automatically.

### Set up header-based attribution

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
1. Follow the on-screen instructions to complete the setup.

After setting up your provider, the {{site.ai_gateway}} captures your configured `ai-cost-` headers automatically with no additional data plane configuration needed.
