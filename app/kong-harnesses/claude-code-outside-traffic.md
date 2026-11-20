---
title: "{{ site.claude_code }} traffic outside {{site.ai_gateway}}"
description: "Lists the hosts that {{ site.claude_code }} contacts outside {{site.ai_gateway}} with a {{site.kong_harnesses}} profile, the profile member and {{ site.claude_code }} setting that turn off each kind of traffic and what that costs, and how to turn off {{ site.claude_code }} on the web and in Slack."
content_type: reference
layout: reference

products:
  - ai-gateway

works_on:
  - konnect

tools:
  - kong-harnesses

tags:
  - cli
  - anthropic

breadcrumbs:
  - /kong-harnesses/

related_resources:
  - text: "Set up {{ site.claude_code }} with {{site.kong_harnesses}}"
    url: /ai-gateway/set-up-claude-code-with-kong-harnesses/
  - text: "{{site.kong_harnesses}} profile"
    url: /kong-harnesses/profile/
  - text: "{{site.kong_harnesses}} doctor"
    url: /kong-harnesses/doctor/
---

A {{site.kong_harnesses}} profile routes only the requests to its base URL, such as the model requests, through [{{site.ai_gateway}}](/ai-gateway/).
{{ site.claude_code }} sends usage metrics, update checks, feature flag lookups and more straight to services such as Anthropic, GitHub and Datadog, where the gateway can't log, limit or block them.

When every feature in the following table is off, {{ site.claude_code }} contacts only the hosts in [Traffic that stays](#traffic-that-stays).
`kong-harnesses profile create` writes a profile with those features off, except for the choices in [In the profile](#in-the-profile).

## Traffic that goes outside the gateway

The profile sets the gateway as the base URL in `ANTHROPIC_BASE_URL`, or in `ANTHROPIC_FOUNDRY_BASE_URL` or `ANTHROPIC_BEDROCK_MANTLE_BASE_URL` in the Azure AI Foundry and Amazon Bedrock Mantle provider modes.
Unless the profile uses the developers' own Claude subscriptions, {{site.kong_harnesses}} also gives {{ site.claude_code }} a gateway key through `apiKeyHelper`: the key from a gateway sign-in, or a key that the administrator issues.

Each row in the following table is one kind of {{ site.claude_code }} traffic that goes straight to its destination.
The profile member is a key of `clients.claude-code` in the profile file.

{% table %}
columns:
  - title: Traffic
    key: traffic
  - title: Destination
    key: destination
  - title: Profile member
    key: member
  - title: When the traffic is off
    key: cost
rows:
  - traffic: Usage metrics
    destination: "`api.anthropic.com` and `http-intake.logs.us5.datadoghq.com`, only when {{ site.claude_code }} uses the Anthropic API directly, which means the Anthropic API provider mode. On a third-party provider such as Azure AI Foundry, usage metrics are off by default."
    member: "`anthropic_telemetry`"
    cost: Anthropic doesn't get latency, reliability and usage data from your sessions.
  - traffic: Feature flags
    destination: "`api.anthropic.com`, and `claude.ai` for the skill sync of a claude.ai sign-in. The {{ site.claude_code }} documentation doesn't name a host for the plugin sync. {{ site.claude_code }} doesn't fetch feature flags on a third-party provider such as Azure AI Foundry."
    member: "`feature_flags`"
    cost: "The [features that need feature-flag fetching](https://code.claude.com/docs/en/env-vars#features-that-need-feature-flag-fetching) are unavailable, such as the advisor tool, Code Mode, MCP tasks, Claude-drafted feedback, and the sync of the skills and plugins of a claude.ai account."
  - traffic: Error reports
    destination: "`browser-intake-us5-datadoghq.com`, only when an Anthropic rollout turns error reports on, the developer signs in with a Claude Pro, Max or Ultra subscription, {{ site.claude_code }} uses the Anthropic API directly, and the organization doesn't have a zero data retention or HIPAA agreement"
    member: "`error_reports`"
    cost: Anthropic doesn't get stack traces when {{ site.claude_code }} fails.
  - traffic: Fast mode availability check
    destination: "`api.anthropic.com`"
    member: "`fast_mode`"
    cost: "`fast_mode` set to `false` turns fast mode off, so developers can't use it. When `fast_mode` is `true`, a skipped or failed check doesn't turn fast mode off, as the paragraph after this table explains."
  - traffic: WebFetch domain check
    destination: "`api.anthropic.com`"
    member: "`webfetch_preflight`"
    cost: "WebFetch still works, without Anthropic's list of blocked domains. To limit the domains, add `WebFetch(domain:...)` permission rules."
  - traffic: claude.ai connectors
    destination: "`mcp-proxy.anthropic.com`"
    member: "`connectors`"
    cost: "{{ site.claude_code }} loads connectors only with a claude.ai sign-in. When the profile uses a gateway key, the connectors never load, even when `connectors` is `true`. When the profile uses the developers' own Claude subscriptions, `false` stops {{ site.claude_code }} from loading the connectors of the claude.ai account. Add the MCP servers you need with `claude mcp add`."
  - traffic: "`/feedback`, `/bug`, `/share` and Claude-drafted feedback"
    destination: "Anthropic, which stores the report in Google Cloud Storage, and optionally `github.com` for a GitHub issue"
    member: "`bug_command` and `feedback_command`"
    cost: "Developers can't send a conversation to Anthropic. Each member turns off all of these commands. On a third-party provider or without Anthropic credentials, {{ site.claude_code }} writes the report to a local file instead of sending it."
  - traffic: Feedback survey
    destination: Anthropic
    member: "`feedback_survey`"
    cost: "{{ site.claude_code }} doesn't ask developers to rate a session, or to send the session transcript and log after the rating. On a third-party provider, that follow-up writes the transcript and log to a local file instead of sending them."
  - traffic: Official plugin marketplace install
    destination: "`github.com`"
    member: "`official_marketplace_autoinstall`"
    cost: "{{ site.claude_code }} doesn't add Anthropic's plugin marketplace. {{ site.claude_code }} skips the registration permanently, even when the member is set to `true` later. Developers can add the marketplace with `claude plugin marketplace add anthropics/claude-plugins-official`."
  - traffic: Artifacts
    destination: "`api.anthropic.com` for the publish requests and the organization policy, and `*.frame.claudeusercontent.com` for the artifact reads. The developer's browser opens the published page on `claude.ai`."
    member: "`artifact`. `auto_updates` set to `false` also turns artifacts off through the nonessential traffic switch (`CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC`), until activation writes that switch blank."
    cost: "Developers can't publish session output as a web page on claude.ai, and {{ site.claude_code }} can't read the files of an artifact. The paragraphs after this table say when artifacts are available and how an administrator turns them off on claude.ai."
  - traffic: Automatic updates and other nonessential traffic
    destination: "`downloads.claude.ai`, `formulae.brew.sh` for a Homebrew install, `raw.githubusercontent.com` for the release notes, which an interactive session also fetches at start when its cached changelog doesn't cover the running version, `api.anthropic.com`, `*-review.googlesource.com`, the GitHub or GitLab host of the repository remote, such as `github.com` or `gitlab.com`, and the marketplace hosts that plugin updates download from, such as `github.com` and `registry.npmjs.org`"
    member: "`auto_updates`"
    cost: "{{ site.claude_code }} doesn't update itself, its plugins or its marketplaces automatically, and doesn't fetch the release notes. Before a `name@marketplace` plugin install, it doesn't refresh that marketplace, so the install uses the cached catalog. Artifacts, the fast mode availability check, the pull request and merge request status badges, the usage limit checks that `CLAUDE_CODE_RETRY_WATCHDOG` and `CLAUDE_CODE_RETRY_WATCHDOG_USAGE_LIMIT_RECHECK_MS` turn on for a claude.ai subscription while usage credits aren't in use, and the code review lookups to `*-review.googlesource.com` also turn off. Run `claude update` to install a newer release, or upgrade a Homebrew, WinGet or Linux package manager install with that package manager. The [Members that depend on each other](#members-that-depend-on-each-other) section explains when only automatic updates turn off."
{% endtable %}

{{ site.claude_code }} skips the fast mode availability check with a gateway key, and when the nonessential traffic switch is on.
When `fast_mode` is `true`, activation tells {{ site.claude_code }} to treat a skipped check, or a check that fails with a network error, as available, unless the organization turned fast mode off.
When a proxy answers the check with its own page, {{ site.claude_code }} reads that page as an organization that [turned fast mode off](https://code.claude.com/docs/en/fast-mode#fast-mode-has-been-disabled-by-your-organization), so let the check reach `api.anthropic.com` through the proxy.
When the proxy can't let it through, set `CLAUDE_CODE_SKIP_FAST_MODE_ORG_CHECK=1` in {{ site.claude_code }} settings, because the variable that activation writes doesn't cover that case.

Artifacts need a Pro, Max, Ultra, Team or Enterprise plan, a claude.ai sign-in and the Anthropic API provider mode, so they work only with a profile that uses the developers' own Claude subscriptions.
Only that profile signs in to claude.ai, and it always uses the Anthropic API provider mode.
When feature flags are off, Claude can't read artifact comments or another organization's public artifact.
Artifacts are also unavailable when the organization has customer-managed encryption keys, HIPAA or zero data retention turned on.

On Team and Enterprise plans, an Owner can turn off artifacts for the organization in [**Organization settings** > **Artifacts**](https://claude.ai/admin-settings/artifacts).
On Enterprise plans with role-based access control, you can also remove the **Artifacts** permission from each role in [**Organization settings** > **Roles**](https://claude.ai/admin-settings/roles).

A code review lookup asks `*-review.googlesource.com` for the change that matches the `Change-Id` of HEAD.
Only a Claude desktop app Code tab session sends it, when the session starts or resumes in a trusted checkout whose `origin` is a `googlesource.com` host.

Activation doesn't write a setting for a member that the profile leaves out.
When an earlier activation wrote that setting, activation gives back the value that the user settings file held before, unless someone changed the setting since.
{{ site.claude_code }} then uses that value, a value from another settings file or the shell, or its own default.
The default depends on the model provider and the sign-in.
For example, {{ site.claude_code }} doesn't send usage metrics or error reports by default on Azure AI Foundry.
To be sure that the traffic stays off, set each member to `false`.

`cost_warnings` doesn't change which hosts {{ site.claude_code }} contacts.
[Features that change behind the gateway](/ai-gateway/set-up-claude-code-with-kong-harnesses/#features-that-change-behind-the-gateway) explains what it does.

### Members that depend on each other

Some {{ site.claude_code }} switches turn off more than one feature:

* The usage metrics switch (`DISABLE_TELEMETRY`) also turns off feature flags, error reports and the feedback survey.
* The `/bug` and `/feedback` switches each turn off all of the feedback commands.
* The nonessential traffic switch, which `auto_updates` set to `false` writes, also turns off usage metrics, feature flags, error reports, `/feedback`, Claude-drafted feedback and the feedback survey.

For that reason, {{site.kong_harnesses}} refuses a profile that turns on a feature while another member turns it off:

* `feature_flags`, `error_reports` or `feedback_survey` set to `true` while `anthropic_telemetry` is `false`.
* `bug_command` or `feedback_command` set to `true` while the other command member is `false`.

A member that the profile leaves out never causes a conflict.

When the usage metrics switch or the nonessential traffic switch is on, `CLAUDE_CODE_ENABLE_FEEDBACK_SURVEY_FOR_OTEL=1` shows the feedback survey again and sends the ratings only to your OpenTelemetry collector.
`feedback_survey` set to `false` keeps the survey off even then.

In a schema 18 profile, `auto_updates` set to `false` doesn't cause a conflict.
When the profile turns on usage metrics, feature flags, error reports, a feedback command or the feedback survey, activation writes the nonessential traffic switch blank.
Activation also writes it blank when a profile that uses the developers' own Claude subscriptions sets `artifact` to `true`.
A blank value turns the switch itself off, so the feature stays on, even when the developer's shell exports the switch.
When the Claude desktop app or a self-hosted environment runner starts the session, the launch environment that it builds [takes precedence](https://code.claude.com/docs/en/settings-reference#how-env-values-interact-with-your-shell) over the settings, so a switch that it sets stays on.
Then `auto_updates` set to `false` turns off only the automatic updates of {{ site.claude_code }}, its plugins and its marketplaces, and {{ site.claude_code }} sends the other traffic in the automatic updates row of the table again, but only where that traffic's own conditions apply.
A member set to `false` keeps its own traffic off, and a gateway key still stops the fast mode availability check.
`FORCE_AUTOUPDATE_PLUGINS=1` in {{ site.claude_code }} settings keeps the automatic plugin updates on, even while `auto_updates` is `false`.
The sync of the skills and plugins of a claude.ai account needs feature flags, so the nonessential traffic switch stops it too.
When the developer signs in to claude.ai and feature flags are on, {{ site.claude_code }} downloads new and updated plugins at each start.
Set `feature_flags` to `false` to stop both syncs, or set `syncClaudeAiPlugins` or `syncClaudeAiSkills` to `false` to stop one of them.
The background runs of plugin `command` sources, which can install dependencies, also start again.
To stop them without the nonessential traffic switch, set [`disableCommandPluginSources`](https://code.claude.com/docs/en/settings-reference#disablecommandpluginsources) to `true` in managed settings.
That setting also stops the installs, updates and loading of the plugins that use a `command` source, and `allowManagedHooksOnly` set to `true` has the same effect while `disableCommandPluginSources` is unset.

## Traffic that stays

When every kind of traffic in the table is off, a {{ site.claude_code }} session contacts these hosts:

* The {{site.ai_gateway}} host
* Your identity provider, for the sign-in, when the profile signs in through one. A profile with a key from the administrator doesn't use one.
* `claude.ai`, `claude.com` and `platform.claude.com`, when the profile uses the developers' own Claude subscriptions, because {{ site.claude_code }} signs in to claude.ai itself. Organizations that use single sign-on also need `sso.claude.com`.
* `api.anthropic.com`, when the profile uses the developers' own Claude subscriptions, for the organization policy and for the [connectivity check](https://code.claude.com/docs/en/errors#unable-to-connect-to-anthropic-services) of the first start. That check also needs `platform.claude.com`, and {{ site.claude_code }} exits when it can't reach one of them. When the profile uses a gateway key, {{ site.claude_code }} has a key at its first start and skips the check.
* `code.claude.com`, for the documentation lookups of the built-in `claude-code-guide` agent and for pre-approved WebFetch requests
* `claude.com`, for pre-approved WebFetch documentation lookups
* The OpenTelemetry collector, when the profile sends telemetry to one
* The sites that WebFetch opens, the MCP servers that a developer adds, and the hosts of the plugins and marketplaces that a developer adds or that settings declare, such as a marketplace that {{ site.claude_code }} clones from `github.com`. After a session starts, {{ site.claude_code }} clones each marketplace that [`extraKnownMarketplaces`](https://code.claude.com/docs/en/settings-reference#extraknownmarketplaces) declares and that the computer doesn't have yet, and downloads the enabled plugins that aren't cached. For a marketplace that a repository's settings declare, it waits until the developer trusts the folder.
* `storage.googleapis.com`, for the plugin metadata that `/plugin` shows
* `downloads.claude.ai`, for plugin executable downloads
* `registry.npmjs.org`, for npm and bun installs of {{ site.claude_code }}, npm-source plugins and their Node.js package dependencies, and MCP servers that `npx` starts
* `bridge.claudeusercontent.com`, for the Claude in Chrome extension

{{ site.claude_code }} can add hosts in a new release, so check [Network access requirements](https://code.claude.com/docs/en/network-config#network-access-requirements) in the {{ site.claude_code }} documentation for the current list.

## Turn off the outside traffic

Set a profile member to `false` where the table lists one, or set the {{ site.claude_code }} settings directly.

### In the profile

`kong-harnesses profile create` sets every member in the table to `false`, with two exceptions:

* `--auto-updates on`, or the automatic updates choice in the questions, sets `auto_updates` to `true`. For that value, activation doesn't write `DISABLE_AUTOUPDATER`. It writes the nonessential traffic switch blank when the profile also turns on a feature that the switch turns off, as [Members that depend on each other](#members-that-depend-on-each-other) explains, and doesn't write the switch otherwise. Each feature in the automatic updates row then stays on where its own conditions apply. A developer can still turn them off with `DISABLE_AUTOUPDATER`, or with the nonessential traffic switch when activation doesn't write it blank.
* `--anthropic-telemetry on`, or a yes to the telemetry question, turns on usage metrics, feature flags and error reports.

The telemetry choice removes only the profile restriction, so the provider and account conditions in the table still apply.
Activation then writes the nonessential traffic switch blank, so {{ site.claude_code }} sends the other nonessential traffic again, as [Members that depend on each other](#members-that-depend-on-each-other) explains.

To keep a feature on, set its member to `true` in the profile file.
The members in the table other than `auto_updates` take effect from `schema_version` 14, and schemas 12 and 13 accept `artifact` but write nothing for it.
The behavior on this page needs schema 18, which `profile create` writes.
The following part of a profile file keeps the WebFetch domain check on, and keeps the other traffic off:

```json
{
  "schema_version": 18,
  "clients": {
    "claude-code": {
      "auto_updates": false,
      "anthropic_telemetry": false,
      "feature_flags": false,
      "error_reports": false,
      "fast_mode": false,
      "official_marketplace_autoinstall": false,
      "artifact": false,
      "connectors": false,
      "bug_command": false,
      "feedback_command": false,
      "feedback_survey": false,
      "webfetch_preflight": true
    }
  }
}
```

After you change the file, import it again:

```sh
kong-harnesses profile import <profile-file>
```

Activate the imported profile, so that {{ site.claude_code }} gets the changed settings:

```sh
kong-harnesses profile activate <profile-name> --client claude-code
```

Activation writes the matching settings to the {{ site.claude_code }} user settings file.
If a developer changes or removes one of these settings later, the `anthropic` check of [`kong-harnesses doctor`](/kong-harnesses/doctor/) fails and shows the command that restores it.

### In {{ site.claude_code }} settings

The following table gives the {{ site.claude_code }} settings that each profile member writes.
To set them without {{site.kong_harnesses}}, add them to a [{{ site.claude_code }} settings file](https://code.claude.com/docs/en/settings).
The environment variables go in the `env` key, and `skipWebFetchPreflight`, `enableArtifact` and `disableClaudeAiConnectors` are top-level keys.

To stop developers from turning the settings back on, set them in [managed settings](https://code.claude.com/docs/en/managed-settings) that you deliver with MDM or a `managed-settings.json` file.
Managed settings take precedence over the user settings file that `profile activate` writes.
A developer can still turn the plugin updates back on with `FORCE_AUTOUPDATE_PLUGINS=1`, so also set `FORCE_AUTOUPDATE_PLUGINS` to `0` in the managed settings `env` block.
A managed `env` value [takes precedence](https://code.claude.com/docs/en/env-vars#precedence) over the user and project settings, and replaces the shell value in most sessions.
A profile that `kong-harnesses profile activate` set up doesn't get [server-managed settings](https://code.claude.com/docs/en/server-managed-settings#platform-availability).
Server-managed settings need a direct connection to `api.anthropic.com`.
Activation writes the gateway base URL to the user settings file, with the provider switch in the Azure AI Foundry and Amazon Bedrock Mantle modes, and {{ site.claude_code }} reads those values before it decides to fetch the settings.
When the profile uses a gateway key, {{ site.claude_code }} gets its key through `apiKeyHelper`, and a key from `apiKeyHelper` doesn't start the fetch.

{% table %}
columns:
  - title: Profile member
    key: member
  - title: "{{ site.claude_code }} setting for `false`"
    key: setting
rows:
  - member: "`anthropic_telemetry`"
    setting: "`DISABLE_TELEMETRY=1`"
  - member: "`feature_flags`"
    setting: "`CLAUDE_CODE_DISABLE_FEATURE_FLAGS=1` and `DISABLE_GROWTHBOOK=1`, its earlier name"
  - member: "`error_reports`"
    setting: "`DISABLE_ERROR_REPORTING=1`"
  - member: "`fast_mode`"
    setting: "`CLAUDE_CODE_DISABLE_FAST_MODE=1`"
  - member: "`webfetch_preflight`"
    setting: "`skipWebFetchPreflight: true`"
  - member: "`connectors`"
    setting: "`ENABLE_CLAUDEAI_MCP_SERVERS=false`, or `disableClaudeAiConnectors: true`"
  - member: "`bug_command`"
    setting: "`DISABLE_BUG_COMMAND=1`"
  - member: "`feedback_command`"
    setting: "`DISABLE_FEEDBACK_COMMAND=1`"
  - member: "`feedback_survey`"
    setting: "`CLAUDE_CODE_DISABLE_FEEDBACK_SURVEY=1`"
  - member: "`official_marketplace_autoinstall`"
    setting: "`CLAUDE_CODE_DISABLE_OFFICIAL_MARKETPLACE_AUTOINSTALL=1`"
  - member: "`artifact`"
    setting: "`enableArtifact: false`"
  - member: "`auto_updates`"
    setting: "`DISABLE_AUTOUPDATER=1`, and `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1`. When you turn on a feature that the second switch turns off, set `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC` blank instead, as activation does."
{% endtable %}

## {{ site.claude_code }} on the web and Claude in Slack

{{ site.claude_code }} on the web, Claude Tag and the earlier {{ site.claude_code }} in Slack run sessions outside the developer's computer.
Those sessions don't use the {{site.kong_harnesses}} profile, and their model requests don't go through its gateway.
If all model traffic must pass through the gateway, turn off each of these products.

### {{ site.claude_code }} on the web

{{ site.claude_code }} on the web runs cloud sessions on Anthropic's infrastructure, or in your organization's [self-hosted environment](https://code.claude.com/docs/en/self-hosted-environments) when you route them there.
In a self-hosted environment, the conversation still goes to `api.anthropic.com`, and model inference uses the Anthropic API unless you configure the runner to send model requests to Amazon Bedrock or Google Vertex AI.
To turn off cloud sessions for a Team or Enterprise organization:

1. Sign in to claude.ai as an Owner of your organization.
1. Open [**Organization settings** > **Claude Code**](https://claude.ai/admin-settings/claude-code).
1. Turn off cloud sessions, which sets the `allow_remote_sessions` policy to off.

If your organization uses custom roles, you can also remove the cloud sessions permission from each role in [**Organization settings** > **Roles**](https://claude.ai/admin-settings/roles).
The organization setting applies only to the accounts of your organization.
[{{ site.claude_code }} on the web](https://code.claude.com/docs/en/claude-code-on-the-web) explains cloud sessions.

### Claude Tag

Claude Tag is the Claude app in Slack for Team and Enterprise organizations.
To turn off Claude Tag for the whole organization, open the [Claude Tag admin settings](https://claude.ai/admin-settings/claude-tag) as an Owner and disable **Enable Claude Tag in Slack**.
The switch also turns off direct messages to Claude.

### {{ site.claude_code }} in Slack

The earlier {{ site.claude_code }} in Slack answers only Pro, Max and Ultra accounts, in a Slack workspace that no organization connected to Claude Tag.
Your organization's Claude settings don't control these personal accounts.
To block the app, a Slack administrator removes the Claude app and stops new installs:

* A Workspace Owner or app manager [removes the Claude app](https://slack.com/help/articles/360003125231-Remove-apps-and-custom-integrations-from-your-workspace) from the workspace. Every user in that workspace loses access at once.
* A Workspace Owner [turns on app approval](https://slack.com/help/articles/222386767-Manage-app-approval-for-your-workspace) and restricts the Claude app, so that members can't install it again. To turn on app approval in the app management settings:
  1. Select the **Only allow pre-approved apps** checkbox.
  1. Click **Save**.
* On Enterprise Grid, an Org Owner or Org Admin [restricts the Claude app for the organization](https://slack.com/help/articles/360000281563-Manage-apps-in-an-Enterprise-organization) in **Organization settings** > **Integrations** > **Manage Apps** > **Restrict an app**. Restricting the app doesn't remove existing installations, so also remove it from each workspace.
* On Enterprise Grid, when the Claude app is installed for the whole organization, an Org Owner or Org Admin [uninstalls it from the organization](https://slack.com/help/articles/360000281563-Manage-apps-in-an-Enterprise-organization) in **Organization settings** > **Integrations** > **Installed Apps**. That removes the app from all workspaces.

[{{ site.claude_code }} in Slack](https://code.claude.com/docs/en/slack) has the details.
