---
title: "Attribution integrations for {{site.ai_cost_management}}"
content_type: reference
layout: reference

products:
  - ai-cost-management
  - ai-gateway

works_on:
  - konnect

min_version:
  ai-gateway: '2.3'

breadcrumbs:
  - /ai-management/
  - /ai-cost-management/

tags:
  - ai
  - governance
  - cost-management

api_specs:
  - konnect/ai-cost-management

description: "Attribution integrations for {{site.ai_cost_management}} lists the tools that send standard tags through their own headers and those you configure with request headers."

related_resources:
  - text: Attribution in {{site.ai_cost_management}}
    url: /ai-cost-management/attribution/
---

Attribution integrations are the AI tools and platforms that route requests through your {{site.ai_gateway}} and supply the tags {{site.ai_cost_management}} uses to attribute spend.

Some of these integrations send standard tags through their native headers.
These headers become tags only when the [attribution plugin](/ai-cost-management/attribution/#set-up-header-based-attribution) is installed on the gateway and the tool is turned on in the plugin's integrations.
For others, you need to configure the tools to send `ai-cost-` prefixed headers to add the tags you want.
Those integrations work on any {{site.ai_gateway}} 2.3 or later data plane with nothing to turn on.

* For a breakdown of the native and header-based tags for each integration, see the [integrations tag reference table](#tag-reference).
* For the full list of standard tag keys, see [Attribution in {{site.ai_cost_management}}](/ai-cost-management/attribution/#tags-and-headers).

{:.info}
> Data planes on {{site.ai_gateway}} 2.3 or later capture `ai-cost-` headers without any setup.
> The attribution plugin, which reads native integration headers, needs `KONG_CUSTOM_PLUGIN_STREAMING_ENABLED=on` on every data plane.
> While the plugin is installed, a data plane without the flag rejects the gateway's whole configuration.
> See [Set up header-based attribution](/ai-cost-management/attribution/#set-up-header-based-attribution) for details.

## Integrations

The following integrations are available in {{site.ai_cost_management}}. 
Clicking a tile opens the integration in your {{site.konnect_short_name}} org, where you can follow the setup instructions.

{% assign catalog = site.data["ai-cost-management"].integrations %}
{% for category in catalog.categories %}

### {{ category.title }}

{{ category.description }}

{% html_tag type="div" css_classes="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-3" %}
{% for integration in category.integrations %}
{% assign card_url = catalog.base_url | append: integration.id %}
{% icon_card icon=integration.icon title=integration.name cta_url=card_url %}
{% endfor %}
{% endhtml_tag %}

{% endfor %}

## Tag reference

The following table lists the tags each integration sends with the attribution plugin and those you can add with `ai-cost-KEY_NAME` headers.

<!--vale off-->
{% table %}
columns:
  - title: Integration
    key: integration
  - title: Sends with the attribution plugin
    key: auto
  - title: Add with `ai-cost-KEY_NAME` headers
    key: headers
rows:
  - integration: Claude Code
    auto: |-
      - `agent-session`
      - `agent-id`
      - `agent-parent`
      - `agent-request-kind` (with `CLAUDE_CODE_GATEWAY_HINT_HEADERS=1`)
      - `agent-type` (with `CLAUDE_CODE_GATEWAY_HINT_HEADERS=1`)
    headers: |-
      - `scm-provider`
      - `scm-repository`
      - `scm-branch`
  - integration: Codex CLI
    auto: |-
      - `agent-session`
      - `agent-request-kind`
      - `scm-repository`
      - `scm-provider`
      - `scm-commit`
      - `agent-id`
      - `agent-parent`
      - `agent-type`
    headers: |-
      - `scm-branch`
      - `project`
  - integration: OpenCode
    auto: |-
      - `agent-session`
      - `agent-id`
      - `agent-parent`
    headers: |-
      - `scm-provider`
      - `scm-repository`
      - `scm-branch`
  - integration: Gemini CLI
    auto: None
    headers: |-
      - `scm-provider`
      - `scm-repository`
      - `scm-branch`
  - integration: GitHub Copilot in VS Code
    auto: "- `agent-request-kind`"
    headers: "- `project`"
  - integration: Cline
    auto: None
    headers: "- `project`"
  - integration: Aider
    auto: None
    headers: |-
      - `project`
      - `scm-provider`
      - `scm-repository`
  - integration: GitHub Actions
    auto: None
    headers: |-
      - `scm-provider`
      - `scm-repository`
      - `scm-branch`
      - `scm-pull-request`
      - `scm-commit`
      - `ci-provider`
      - `ci-pipeline`
      - `ci-run`
  - integration: GitLab CI
    auto: None
    headers: |-
      - `scm-provider`
      - `scm-repository`
      - `scm-branch`
      - `scm-pull-request`
      - `scm-commit`
      - `ci-provider`
      - `ci-pipeline`
      - `ci-run`
  - integration: Jenkins
    auto: None
    headers: |-
      - `scm-provider`
      - `scm-repository`
      - `scm-branch`
      - `scm-pull-request`
      - `scm-commit`
      - `ci-provider`
      - `ci-pipeline`
      - `ci-run`
  - integration: Buildkite
    auto: None
    headers: |-
      - `scm-provider`
      - `scm-repository`
      - `scm-branch`
      - `scm-pull-request`
      - `scm-commit`
      - `ci-provider`
      - `ci-pipeline`
      - `ci-run`
  - integration: CircleCI
    auto: None
    headers: |-
      - `scm-provider`
      - `scm-repository`
      - `scm-branch`
      - `scm-pull-request`
      - `scm-commit`
      - `ci-provider`
      - `ci-pipeline`
      - `ci-run`
  - integration: Slack
    auto: None
    headers: |-
      - `chat-provider`
      - `chat-organization`
      - `chat-workspace`
      - `chat-channel`
      - `chat-channel-id`
      - `chat-channel-type`
      - `chat-trigger`
      - `chat-command`
      - `agent-name`
      - `agent-session`
      - `workflow-run`
  - integration: Microsoft Teams
    auto: None
    headers: |-
      - `chat-provider`
      - `chat-workspace`
      - `chat-channel-id`
  - integration: Discord
    auto: None
    headers: |-
      - `chat-provider`
      - `chat-workspace`
      - `chat-channel-id`
      - `agent-session`
  - integration: Jira
    auto: None
    headers: |-
      - `ticket`
      - `project`
  - integration: Linear
    auto: None
    headers: |-
      - `ticket`
      - `project`
  - integration: PagerDuty
    auto: None
    headers: "- `ticket`"
  - integration: GitHub and GitLab issues
    auto: None
    headers: |-
      - `scm-issue`
      - `scm-repository`
  - integration: OpenAI Agents SDK
    auto: None
    headers: |-
      - `workflow-name`
      - `workflow-run`
      - `agent-session`
  - integration: LangChain and LangGraph
    auto: None
    headers: |-
      - `workflow-name`
      - `workflow-run`
      - `agent-session`
  - integration: CrewAI
    auto: None
    headers: |-
      - `workflow-name`
      - `workflow-run`
  - integration: LlamaIndex Workflows
    auto: None
    headers: |-
      - `workflow-name`
      - `workflow-run`
  - integration: n8n
    auto: None
    headers: |-
      - `workflow-name`
      - `workflow-run`
      - `agent-session`
  - integration: Vercel AI SDK
    auto: None
    headers: "- `workflow-name`"
  - integration: Helicone
    auto: |-
      - `agent-session` (from `Helicone-Session-Id`)
      - Any `Helicone-Property-<Name>` header becomes a tag named `<name>`.
    headers: None
  - integration: Portkey
    auto: Each key in the `x-portkey-metadata` JSON object becomes a tag of the same name, except keys that start with `_`.
    headers: None
  - integration: Cloudflare AI Gateway
    auto: Each key in the `cf-aig-metadata` JSON object becomes a tag of the same name.
    headers: None
  - integration: Your own code
    auto: None
    headers: |-
      - `project`
      - `environment`
      - `use-case`
      - `feature`
      - `customer-account`
{% endtable %}
<!--vale on-->
