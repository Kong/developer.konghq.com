---
title: "{{ site.claude_code }} traffic outside {{site.ai_gateway}}"
description: "Lists the hosts that {{ site.claude_code }} contacts outside {{site.ai_gateway}} with a {{site.kong_harnesses}} profile, the profile member and {{ site.claude_code }} setting that turn off each kind of traffic, and what that costs."
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
  - text: "{{site.kong_harnesses}} profile file"
    url: /kong-harnesses/profile-file/
  - text: "{{site.kong_harnesses}} doctor"
    url: /kong-harnesses/doctor/
  - text: "{{ site.claude_code }} on the web and Claude in Slack"
    url: /kong-harnesses/claude-code-web-and-slack/
---

A {{site.kong_harnesses}} profile routes through [{{site.ai_gateway}}](/ai-gateway/) only the requests that {{ site.claude_code }} sends to its base URL, which include the model requests.
{{ site.claude_code }} sends usage metrics, update checks, feature flag lookups and more straight to services such as Anthropic, GitHub and Datadog, where the gateway can't log, limit or block them.
The sessions of {{ site.claude_code }} on the web and of Claude in Slack don't use the profile at all, so [turn off those products](/kong-harnesses/claude-code-web-and-slack/) when all model traffic must pass through the gateway.

When every feature in the following table is off, {{ site.claude_code }} contacts only the hosts in [Traffic that stays](#traffic-that-stays).
`kong-harnesses profile create` writes a profile with those features off, except for the choices in [In the profile](#in-the-profile).

## Traffic that goes outside the gateway

The profile sets the gateway as the base URL in `ANTHROPIC_BASE_URL`, or in `ANTHROPIC_FOUNDRY_BASE_URL` or `ANTHROPIC_BEDROCK_MANTLE_BASE_URL` in the Azure AI Foundry and Amazon Bedrock Mantle provider modes.
Unless the profile uses the developers' own Claude subscriptions, {{site.kong_harnesses}} also gives {{ site.claude_code }} a gateway key through `apiKeyHelper`: the key from a gateway sign-in, or a key that the administrator issues.
When a host platform that embeds {{ site.claude_code }} sets [`CLAUDE_CODE_PROVIDER_MANAGED_BY_HOST`](https://code.claude.com/docs/en/env-vars#variables), {{ site.claude_code }} ignores the provider, endpoint and authentication variables that the profile writes to the settings files.
Model requests then follow the routing of the host platform instead of the gateway, and the other settings that the profile writes, such as `DISABLE_TELEMETRY`, still apply.

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
    destination: >-
      `api.anthropic.com`, and `http-intake.logs.us5.datadoghq.com` only when {{ site.claude_code }} uses the Anthropic API provider mode, also through the gateway.
      When the profile selects a third-party provider, such as Azure AI Foundry, usage metrics are off by default, unless [a host platform](#traffic-that-goes-outside-the-gateway) routes the session.
    member: "`anthropic_telemetry`"
    cost: Anthropic doesn't get latency, reliability and usage data from your sessions.
  - traffic: Feature flags
    destination: >-
      `api.anthropic.com`, and `claude.ai` for the skill sync of a claude.ai sign-in.
      When the profile selects a third-party provider, such as Azure AI Foundry, {{ site.claude_code }} doesn't fetch feature flags, unless [a host platform](#traffic-that-goes-outside-the-gateway) routes the session.
    member: "`feature_flags`"
    cost: "The [features that need feature-flag fetching](https://code.claude.com/docs/en/env-vars#features-that-need-feature-flag-fetching) are unavailable, such as the advisor tool, Code Mode, MCP tasks, Claude-drafted feedback, and the sync of the skills and plugins of a claude.ai account."
  - traffic: Error reports
    destination: >-
      `browser-intake-us5-datadoghq.com`, only when {{ site.claude_code }} connects straight to the Anthropic API.
      A profile sends {{ site.claude_code }} to the gateway, so {{ site.claude_code }} doesn't send error reports, even when `error_reports` is `true`.
    member: "`error_reports`"
    cost: "None for a profile, because {{ site.claude_code }} sends no error reports through the gateway."
  - traffic: Fast mode availability check
    destination: "`api.anthropic.com`"
    member: "`fast_mode`"
    cost: >-
      `fast_mode` set to `false` turns fast mode off, so developers can't use it.
      When `fast_mode` is `true`, a skipped or failed check doesn't turn fast mode off, as [Fast mode availability check](#fast-mode-availability-check) explains.
  - traffic: WebFetch domain check
    destination: "`api.anthropic.com`"
    member: "`webfetch_preflight`"
    cost: >-
      WebFetch still works, without Anthropic's list of blocked domains.
      To limit the domains, add `WebFetch(domain:...)` permission rules.
  - traffic: claude.ai connectors
    destination: "`mcp-proxy.anthropic.com`"
    member: "`connectors`"
    cost: >-
      {{ site.claude_code }} loads connectors only with a claude.ai sign-in.
      When the profile uses a gateway key, the connectors never load, even when `connectors` is `true`.
      When the profile uses the developers' own Claude subscriptions, `false` stops {{ site.claude_code }} from loading the connectors of the claude.ai account.
      Add the MCP servers you need with `claude mcp add`.
  - traffic: "`/feedback`, `/bug`, `/share` and Claude-drafted feedback"
    destination: "Anthropic, which stores the report in Google Cloud Storage, and optionally `github.com` for a GitHub issue"
    member: "`bug_command` and `feedback_command`"
    cost: >-
      Developers can't send a conversation to Anthropic.
      Each member turns off all of these commands.
      On a third-party provider or without Anthropic credentials, {{ site.claude_code }} writes the report to a local file instead of sending it.
  - traffic: Feedback survey
    destination: Anthropic
    member: "`feedback_survey`"
    cost: >-
      {{ site.claude_code }} doesn't ask developers to rate a session, or to send the session transcript and log after the rating.
      The follow-up uploads them only when the developer selects **Yes**, and zero data retention or an organization policy that turns off product feedback stops the follow-up.
      On a third-party provider, that follow-up writes the transcript and log to a local file instead of sending them.
      While `DISABLE_TELEMETRY` or `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC` is on, [`CLAUDE_CODE_ENABLE_FEEDBACK_SURVEY_FOR_OTEL=1`](https://code.claude.com/docs/en/env-vars#variables) can send the survey ratings to your OpenTelemetry collector instead of Anthropic.
      Setting `feedback_survey` to `false` keeps the survey off even then.
  - traffic: Official plugin marketplace install
    destination: "`github.com`"
    member: "`official_marketplace_autoinstall`"
    cost: >-
      {{ site.claude_code }} doesn't add Anthropic's plugin marketplace.
      {{ site.claude_code }} skips the registration permanently, even when the member is set to `true` later.
      `false` stops only a registration that hasn't happened yet, which is usually at the first interactive start.
      A marketplace that is already registered stays, and it updates from `github.com` while automatic updates and its own `autoUpdate` setting are on, which is the default for this marketplace.
      Developers can add the marketplace with `claude plugin marketplace add anthropics/claude-plugins-official`.
  - traffic: Artifacts
    destination: >-
      `api.anthropic.com` for the publish requests and the organization policy, and `*.frame.claudeusercontent.com` for the artifact reads.
      The developer's browser opens the published page on `claude.ai`.
    member: >-
      `artifact`.
      `auto_updates` set to `false` also turns artifacts off through the nonessential traffic switch (`CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC`), until activation writes that switch blank.
    cost: >-
      Developers can't publish session output as a web page on claude.ai, and {{ site.claude_code }} can't read the files of an artifact.
      [Artifact availability](#artifact-availability) says when artifacts are available and how an administrator turns them off on claude.ai.
  - traffic: Automatic updates and other nonessential traffic
    destination: "`downloads.claude.ai` for the native installer and its automatic updates, `registry.npmjs.org` for an npm install, `formulae.brew.sh` for a Homebrew install, `raw.githubusercontent.com` for the release notes, `api.anthropic.com`, `*-review.googlesource.com`, the GitHub or GitLab host of the repository remote, such as `github.com` or `gitlab.com`, and the marketplace hosts that plugin updates download from, such as `github.com` and `registry.npmjs.org`"
    member: "`auto_updates`"
    cost: >-
      {{ site.claude_code }} doesn't update itself, its plugins or its marketplaces automatically, and doesn't fetch the release notes.
      Before a `name@marketplace` plugin install, it doesn't refresh that marketplace, so the install uses the cached catalog.
      Artifacts, the fast mode availability check, the pull request and merge request status badges, the usage limit checks that `CLAUDE_CODE_RETRY_WATCHDOG` and `CLAUDE_CODE_RETRY_WATCHDOG_USAGE_LIMIT_RECHECK_MS` turn on for a claude.ai subscription while usage credits aren't in use, and the code review lookups to `*-review.googlesource.com` also turn off.
      While that traffic is on, [`prStatusFooterEnabled`](https://code.claude.com/docs/en/settings-reference#prstatusfooterenabled) set to `false` in `~/.claude.json` stops only the status badge checks.
      Run `claude update` to install a newer release, or upgrade a Homebrew, WinGet or Linux package manager install with that package manager.
      [Claude Code choices](/kong-harnesses/profile-file/#claude-code-choices) explains when `auto_updates` turns off only automatic updates.
{% endtable %}

A code review lookup asks `*-review.googlesource.com` for the change that matches the `Change-Id` of HEAD.
Only a Claude desktop app Code tab session sends it, when the session starts or resumes in a trusted checkout whose `origin` is a `googlesource.com` host.

An interactive session also fetches the release notes from `raw.githubusercontent.com` at start, when its cached changelog doesn't cover the running version.
Non-interactive and cloud sessions never fetch them.

Activation doesn't write a setting for a member that the profile leaves out, except for the schema 18 `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC` case in [Claude Code choices](/kong-harnesses/profile-file/#claude-code-choices).
When an earlier activation wrote a setting for that omitted member, activation gives back the value that the user settings file held before, unless someone changed the setting since.
{{ site.claude_code }} then uses that value, a value from another settings file or the shell, or its own default.
The default depends on the model provider and the sign-in.
For example, {{ site.claude_code }} doesn't send usage metrics by default on Azure AI Foundry.
To be sure that the traffic stays off, set each member to `false`.
`FORCE_AUTOUPDATE_PLUGINS=1` in {{ site.claude_code }} settings still turns automatic plugin and marketplace updates back on.
Some switches cover more than one profile member, and [Claude Code choices](/kong-harnesses/profile-file/#claude-code-choices) lists the member conflict rules and the settings activation writes.

`cost_warnings` doesn't change which hosts {{ site.claude_code }} contacts.
[Features that change behind the gateway](/ai-gateway/set-up-claude-code-with-kong-harnesses/#features-that-change-behind-the-gateway) explains what it does.

### Fast mode availability check

`kong-harnesses profile create` turns fast mode off because it costs more per token on the API and draws on usage credits on a subscription.
Fast mode works only on supported models on the Anthropic Console API, Claude subscription plans, and Google Cloud's Agent Platform, and isn't available on Amazon Bedrock, Microsoft Foundry, or Claude Platform on AWS.
On the Anthropic API, fast mode supports Claude Fable 5.2, Opus 5.5, Opus 5, and Opus 4.8.
Paid Claude Console organizations need an admin to enable fast mode in **Claude Code preferences**, with provisioned access for Opus 5 and Opus 4.8 and an eligible usage tier for Fable 5.2 and Opus 5.5.
Claude subscription plans need usage credits turned on, and Team and Enterprise organizations also need an Owner to enable fast mode.
On Google Cloud's Agent Platform, fast mode supports only Claude Fable 5.2 in the `global`, `us`, or `eu` region.
See the [fast mode requirements](https://code.claude.com/docs/en/fast-mode#requirements) for the full conditions.

{{ site.claude_code }} skips the fast mode availability check with a gateway key, and when the nonessential traffic switch is on.
When `fast_mode` is `true`, activation tells {{ site.claude_code }} to treat a skipped check, or a check that fails with a network error, as available, unless the organization turned fast mode off.
When a proxy answers the check with its own page, {{ site.claude_code }} reads that page as an organization that [turned fast mode off](https://code.claude.com/docs/en/fast-mode#fast-mode-has-been-disabled-by-your-organization), so let the check reach `api.anthropic.com` through the proxy.
When the proxy can't let it through, set `CLAUDE_CODE_SKIP_FAST_MODE_ORG_CHECK=1` in {{ site.claude_code }} settings, because the variable that activation writes doesn't cover that case.

### Artifact availability

Artifacts need a Pro, Max, Ultra, Team or Enterprise plan, a claude.ai sign-in and the Anthropic API provider mode, so they work only with a profile that uses the developers' own Claude subscriptions.
Only that profile signs in to claude.ai, and it always uses the Anthropic API provider mode.
The [artifacts availability](https://code.claude.com/docs/en/artifacts#availability) conditions name the organization settings and the run contexts that also turn artifacts off.
In the profile, `artifact` set to `true` also needs `artifact` set to `true` on the gateway route.
When `feature_flags` is `false`, Claude can't read artifact comments or another organization's public artifact, even while the nonessential traffic switch is blank.
`enableArtifact: true` doesn't override a `false` from another settings file, from `CLAUDE_CODE_DISABLE_ARTIFACT` or from the organization setting.

On Team and Enterprise plans, an Owner can turn off artifacts for the organization with the **Artifacts** toggle in [**Organization settings** > **Artifacts**](https://claude.ai/admin-settings/artifacts).
If your Enterprise organization uses custom roles, you can also remove the **Artifacts** permission from each role in [**Organization settings** > **Roles**](https://claude.ai/admin-settings/roles).

### Skill and plugin sync from claude.ai

Only a profile that uses the developers' own Claude subscriptions can sync the skills and plugins of a claude.ai account.
A profile with a gateway key never syncs, even after `/login`, because the key comes from `apiKeyHelper`.
The sync needs feature flags, so each switch that turns off feature flags stops it too.
When feature flags are on, {{ site.claude_code }} downloads new and updated plugins at each start.
The [sign-in requirements for terminal sync](https://code.claude.com/docs/en/plugins/loading#sign-in-requirements-for-terminal-sync) name the other cases that skip it.
Set `feature_flags` to `false` to stop both syncs, or set `syncClaudeAiPlugins` or `syncClaudeAiSkills` to `false` to stop one of them.

### Plugin command sources

A plugin with a `command` source runs its command in the background once in each session, and again when its installed version is missing from the plugin cache.
These runs can install dependencies.
The nonessential traffic switch stops the background runs, but an explicit plugin install or update runs the command even while the switch is on.
When activation writes the switch blank, as [Claude Code choices](/kong-harnesses/profile-file/#claude-code-choices) explains, the background runs start again.
To stop them without the nonessential traffic switch, set [`disableCommandPluginSources`](https://code.claude.com/docs/en/settings-reference#disablecommandpluginsources) to `true` in managed settings.
That setting also stops the installs, updates and loading of the plugins that use a `command` source.
`allowManagedHooksOnly` set to `true` has the same effect while `disableCommandPluginSources` is unset.

## Traffic that stays

When every kind of traffic in the table is off, a {{ site.claude_code }} session contacts these hosts:

* The {{site.ai_gateway}} host.
* Your identity provider, for the sign-in, when the profile signs in through one.
  A profile with a key from the administrator doesn't use one.
* `claude.ai`, `claude.com` and `platform.claude.com`, when the profile uses the developers' own Claude subscriptions, because {{ site.claude_code }} signs in to claude.ai itself and refreshes and revokes its tokens on `platform.claude.com`.
  Organizations that use single sign-on also need `sso.claude.com`.
* `api.anthropic.com`, when the profile uses the developers' own Claude subscriptions, for the organization policy and for the [connectivity check](https://code.claude.com/docs/en/errors#unable-to-connect-to-anthropic-services) of the first start.
  That check also needs `platform.claude.com`, and {{ site.claude_code }} exits when it can't reach one of them.
  When the profile uses a gateway key, {{ site.claude_code }} has a key at its first start and skips the check.
* `api.anthropic.com`, when a developer who signed in with `claude auth login` starts, resumes or messages a cloud session from the terminal, for the [organization's cloud session policy](https://code.claude.com/docs/en/errors#couldnt-verify-your-organizations-policy-for-cloud-sessions).
* `code.claude.com`, for the documentation lookups of the built-in `claude-code-guide` agent and for pre-approved WebFetch requests.
* `claude.com`, for pre-approved WebFetch documentation lookups.
* The OpenTelemetry collector, when the profile sends telemetry to one.
* The sites that WebFetch opens, the MCP servers that a developer adds, and the hosts of the plugins and marketplaces that a developer adds or that settings declare, such as a marketplace that {{ site.claude_code }} clones from `github.com` over HTTPS or SSH.
  For an allowlist that permits only HTTPS, set `CLAUDE_CODE_PLUGIN_PREFER_HTTPS=1`, which clones GitHub `owner/repo` shorthand sources over HTTPS.
  [Plugins and marketplaces that aren't on disk at session start](https://code.claude.com/docs/en/plugins/loading#plugins-and-marketplaces-that-arent-on-disk-at-session-start) says when {{ site.claude_code }} fetches a declared marketplace and its plugins in the background.
  To limit the marketplaces, set [`strictKnownMarketplaces`](https://code.claude.com/docs/en/settings-reference#strictknownmarketplaces) or [`blockedMarketplaces`](https://code.claude.com/docs/en/settings-reference#blockedmarketplaces) in managed settings.
* The URLs of the plugin `.zip` archives that a developer passes with [`--plugin-url`](https://code.claude.com/docs/en/cli-reference#cli-flags).
  To refuse that flag at startup, set [`disableSideloadFlags`](https://code.claude.com/docs/en/settings-reference#disablesideloadflags) to `true` in managed settings.
* `storage.googleapis.com`, for the plugin metadata that `/plugin` shows.
* `downloads.claude.ai`, for plugin executable downloads.
* `registry.npmjs.org`, for npm and bun installs of {{ site.claude_code }}, npm-source plugins and their Node.js package dependencies, and MCP servers that `npx` starts.
* `bridge.claudeusercontent.com`, for the [Claude in Chrome](https://code.claude.com/docs/en/chrome) extension, when Chrome integration is on.
* The endpoints that you or your settings name, such as [managed MCP servers](https://code.claude.com/docs/en/settings-reference#managedmcpservers) and [HTTP hooks](https://code.claude.com/docs/en/hooks#http-hook-fields).
  {{ site.claude_code }} sends those requests where the settings point, and no member in the table turns them off.

{{ site.claude_code }} can add hosts in a new release, so check [Network access requirements](https://code.claude.com/docs/en/network-config#network-access-requirements) in the {{ site.claude_code }} documentation for the current list.

## Turn off the outside traffic

Set a profile member to `false` where the table lists one, or set the {{ site.claude_code }} settings directly.

Activation writes the user settings file of {{ site.claude_code }}.
Command-line flags, the shared project settings and the local project settings [take precedence](https://code.claude.com/docs/en/settings#settings-precedence) over that file, so a repository or a developer can turn a feature back on for one project.
Only [managed settings](https://code.claude.com/docs/en/managed-settings) enforce a value.
A session that starts with a [`--setting-sources`](https://code.claude.com/docs/en/cli-reference#cli-flags) list that leaves out `user` doesn't read the user settings file, so none of the settings that activation writes apply to that session.
Two keys on this page are [exceptions](https://code.claude.com/docs/en/settings#exceptions-to-managed-settings-precedence): `enableArtifact: false` and `disableClaudeAiConnectors: true` from any settings source win even over managed settings.
In a schema 14 or later profile, activation writes `enableArtifact: false` for `artifact` set to `false`, so while {{ site.claude_code }} reads the user settings file, no other settings source can turn the Artifact tool back on.
`kong-harnesses doctor` checks the user settings file, so it doesn't report a project setting or a command-line flag that changes one of these settings.

### In the profile

`kong-harnesses profile create` writes a schema 18 profile with every member in the table set to `false`.
Two flags or their interactive prompts override that default: `--auto-updates on` sets `auto_updates` to `true`, and `--anthropic-telemetry on` sets `anthropic_telemetry`, `feature_flags` and `error_reports` to `true`.
Turning a member on removes only the profile restriction, so the provider and account conditions in the table still apply.

To keep a feature on, set its member to `true` in a schema 18 profile.
In a default profile, turning on the feedback survey requires setting both `feedback_survey` and `anthropic_telemetry` to `true`, because {{site.kong_harnesses}} refuses `feedback_survey` set to `true` while `anthropic_telemetry` is `false`.
For schema version rules, all member conflict rules, what activation writes for each choice, and how schema 18 handles `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC`, see [Claude Code choices](/kong-harnesses/profile-file/#claude-code-choices).
The following part of a profile file keeps the WebFetch domain check on and the other traffic off:

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

After you change the file, run [`kong-harnesses profile import`](/kong-harnesses/profile/import/) and [`kong-harnesses profile activate`](/kong-harnesses/profile/activate/) to apply the new settings.
If a developer changes or removes one of these settings later, the `anthropic` check of [`kong-harnesses doctor`](/kong-harnesses/doctor/) fails and shows the command that restores it.

### In {{ site.claude_code }} settings

To turn off outside traffic without {{site.kong_harnesses}}, add the settings for the members in [Traffic that goes outside the gateway](#traffic-that-goes-outside-the-gateway), as listed in [Claude Code choices](/kong-harnesses/profile-file/#claude-code-choices), to a [{{ site.claude_code }} settings file](https://code.claude.com/docs/en/settings).
The environment variables go in the `env` key, and `skipWebFetchPreflight`, `enableArtifact` and `disableClaudeAiConnectors` are top-level keys.
`disableClaudeAiConnectors: true` turns off claude.ai connectors like `ENABLE_CLAUDEAI_MCP_SERVERS=false`, though activation doesn't write it.
{{ site.claude_code }} reads `DISABLE_GROWTHBOOK` from v2.1.124, and its newer name `CLAUDE_CODE_DISABLE_FEATURE_FLAGS` from v2.1.319.
To turn off feature flags manually on {{ site.claude_code }} v2.1.318 or earlier, use `DISABLE_GROWTHBOOK`, as the [environment variables reference](https://code.claude.com/docs/en/env-vars#variables) explains.
Otherwise, use `CLAUDE_CODE_DISABLE_FEATURE_FLAGS`.
When you turn on a feature that `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC` turns off, set `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC` blank instead of `1`.

To stop developers from turning these settings back on, set them in [managed settings](https://code.claude.com/docs/en/managed-settings) delivered through MDM or a `managed-settings.json` file.
Managed settings take precedence over the user settings file that `profile activate` writes.
A developer can still turn plugin updates back on with `FORCE_AUTOUPDATE_PLUGINS=1`, so also set `FORCE_AUTOUPDATE_PLUGINS` to `0` in the managed settings `env` block.
A managed `env` value [takes precedence](https://code.claude.com/docs/en/env-vars#precedence) over user and project settings, and replaces the shell value in most sessions.
A profile that `kong-harnesses profile activate` sets up doesn't get [server-managed settings](https://code.claude.com/docs/en/server-managed-settings#platform-availability), because server-managed settings need a direct connection to `api.anthropic.com`.
Activation writes the gateway base URL to the user settings file, with the provider switch in the Azure AI Foundry and Amazon Bedrock Mantle modes, and {{ site.claude_code }} reads those values before it decides to fetch the settings.
When the profile uses a gateway key, {{ site.claude_code }} gets its key through `apiKeyHelper`, and a key from `apiKeyHelper` doesn't start the fetch.
