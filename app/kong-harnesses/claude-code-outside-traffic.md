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

A {{site.kong_harnesses}} profile routes through [{{site.ai_gateway}}](/ai-gateway/) only requests {{ site.claude_code }} sends to its base URL, including model requests.
{{ site.claude_code }} sends usage metrics, update checks, feature flag lookups, and other requests straight to services such as Anthropic, GitHub, and Datadog, where the gateway can't log, limit, or block them.
{{ site.claude_code }} on the web and Claude in Slack don't use the profile, so [turn off those products](/kong-harnesses/claude-code-web-and-slack/) when all model traffic must pass through the gateway.

When every feature in the following table is off, {{ site.claude_code }} contacts only the hosts in [Traffic that stays](#traffic-that-stays).
`kong-harnesses profile create` turns those features off by default, except for the choices in [In the profile](#in-the-profile).

## Traffic that goes outside the gateway

The profile sets the gateway as the base URL in `ANTHROPIC_BASE_URL`, or in `ANTHROPIC_FOUNDRY_BASE_URL` or `ANTHROPIC_BEDROCK_MANTLE_BASE_URL` in the Azure AI Foundry and Amazon Bedrock Mantle provider modes.
Unless the profile uses the developers' own Claude subscriptions, {{site.kong_harnesses}} also gives {{ site.claude_code }} a gateway key through `apiKeyHelper`: the key from a gateway sign-in, or a key that the administrator issues.
When a host platform that embeds {{ site.claude_code }} sets [`CLAUDE_CODE_PROVIDER_MANAGED_BY_HOST`](https://code.claude.com/docs/en/env-vars#variables), {{ site.claude_code }} ignores the provider, endpoint and authentication variables that the profile writes to the settings files.
Model requests then follow the routing of the host platform instead of the gateway, and the other settings that the profile writes, such as `DISABLE_TELEMETRY`, still apply.

Each row lists one kind of outside traffic and its `clients.claude-code` profile member.

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
      `api.anthropic.com`, and `http-intake.logs.us5.datadoghq.com` in Anthropic API mode, also through the gateway.
      Off by default on third-party providers unless [a host platform](#traffic-that-goes-outside-the-gateway) routes the session.
    member: "`anthropic_telemetry`"
    cost: "Stops [usage metrics](https://code.claude.com/docs/en/data-usage#telemetry-services) to Anthropic."
  - traffic: Feature flags
    destination: >-
      `api.anthropic.com`, and `claude.ai` for claude.ai skill sync.
      Off on third-party providers unless [a host platform](#traffic-that-goes-outside-the-gateway) routes the session.
    member: "`feature_flags`"
    cost: "Disables [features that need feature-flag fetching](https://code.claude.com/docs/en/env-vars#features-that-need-feature-flag-fetching), including claude.ai skill and plugin sync."
  - traffic: Error reports
    destination: "`browser-intake-us5-datadoghq.com` (direct Anthropic API only)"
    member: "`error_reports`"
    cost: "None for a profile: {{ site.claude_code }} doesn't send [error reports](https://code.claude.com/docs/en/data-usage#telemetry-services) through the gateway, even when `error_reports` is `true`."
  - traffic: Fast mode availability check
    destination: "`api.anthropic.com`"
    member: "`fast_mode`"
    cost: >-
      Turns fast mode off.
      When `fast_mode` is `true`, a skipped check or network error doesn't turn fast mode off, though an organization can still turn it off.
      See [Fast mode availability check](#fast-mode-availability-check).
  - traffic: WebFetch domain check
    destination: "`api.anthropic.com`"
    member: "`webfetch_preflight`"
    cost: >-
      WebFetch runs without Anthropic's [domain safety blocklist](https://code.claude.com/docs/en/data-usage#webfetch-domain-safety-check).
      Restrict domains with `WebFetch(domain:...)` permission rules.
  - traffic: claude.ai connectors
    destination: "`mcp-proxy.anthropic.com`"
    member: "`connectors`"
    cost: >-
      Connectors never load with a gateway key, even when `connectors` is `true`.
      With Claude subscriptions, stops loading [claude.ai connectors](https://code.claude.com/docs/en/mcp#use-mcp-servers-from-claude-ai).
      Add needed MCP servers with `claude mcp add`.
  - traffic: "`/feedback`, `/bug`, `/share` and Claude-drafted feedback"
    destination: "Anthropic (Google Cloud Storage), optionally `github.com` for a GitHub issue"
    member: "`bug_command` and `feedback_command`"
    cost: >-
      Either member turns off all of these [feedback commands](https://code.claude.com/docs/en/data-usage#telemetry-services).
      On third-party providers or without Anthropic credentials, `/feedback` writes a local file instead of uploading.
  - traffic: Feedback survey
    destination: Anthropic
    member: "`feedback_survey`"
    cost: >-
      Stops [session quality surveys](https://code.claude.com/docs/en/data-usage#session-quality-surveys).
      While `DISABLE_TELEMETRY` or `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC` is on, [`CLAUDE_CODE_ENABLE_FEEDBACK_SURVEY_FOR_OTEL=1`](https://code.claude.com/docs/en/env-vars#variables) can send ratings to your OpenTelemetry collector instead of Anthropic.
      Setting `feedback_survey` to `false` keeps the survey off even then.
  - traffic: Official plugin marketplace install
    destination: "`github.com`"
    member: "`official_marketplace_autoinstall`"
    cost: >-
      Permanently skips unregistered [official marketplace](https://code.claude.com/docs/en/plugins/anthropic-marketplaces) auto-install, even if set `true` later.
      An already-registered marketplace stays and updates while auto-updates and its `autoUpdate` setting are on.
      Add it with `claude plugin marketplace add anthropics/claude-plugins-official`.
  - traffic: Artifacts
    destination: "`api.anthropic.com` (publish and organization policy), `*.frame.claudeusercontent.com` (reads), `claude.ai` (browser)"
    member: "`artifact` (`auto_updates: false` also turns it off, unless a schema 18 or later profile makes activation write `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC` blank. See [Claude Code choices](/kong-harnesses/profile-file/#claude-code-choices).)"
    cost: >-
      Disables publishing and reading [artifacts](https://code.claude.com/docs/en/artifacts).
      See [Artifact availability](#artifact-availability).
  - traffic: Automatic updates and other nonessential traffic
    destination: "`downloads.claude.ai` (native updates), `registry.npmjs.org` (npm), `formulae.brew.sh` (Homebrew), `raw.githubusercontent.com` (release notes), `api.anthropic.com`, `*-review.googlesource.com`, repository remote hosts (`github.com`, `gitlab.com`), and plugin marketplace hosts (`github.com`, `registry.npmjs.org`)"
    member: "`auto_updates`"
    cost: >-
      `DISABLE_AUTOUPDATER` stops [automatic updates](https://code.claude.com/docs/en/setup#auto-updates) of {{ site.claude_code }}, plugins, and marketplaces.
      `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC` also stops [marketplace refreshes before `name@marketplace` installs](https://code.claude.com/docs/en/plugins/loading#when-claude-code-refreshes-a-marketplace-before-an-install) (installs use cached catalogs), release notes, artifacts, fast mode checks, PR and MR status badges, [`CLAUDE_CODE_RETRY_WATCHDOG`](https://code.claude.com/docs/en/env-vars#variables) and `CLAUDE_CODE_RETRY_WATCHDOG_USAGE_LIMIT_RECHECK_MS` subscription limit checks, and `*-review.googlesource.com` code review lookups.
      Set [`prStatusFooterEnabled`](https://code.claude.com/docs/en/settings-reference#prstatusfooterenabled) to `false` in `~/.claude.json` to stop only status badges.
      Upgrade with `claude update` or your package manager ([update manually](https://code.claude.com/docs/en/setup#update-manually)).
      See [Claude Code choices](/kong-harnesses/profile-file/#claude-code-choices) for when activation writes `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC` blank so `auto_updates` stops only updates.
{% endtable %}

Only a Claude desktop app Code tab session sends `*-review.googlesource.com` code review lookups (matching the `Change-Id` of HEAD), when starting or resuming in a trusted checkout whose `origin` is a `googlesource.com` host.

An interactive session fetches the release notes from `raw.githubusercontent.com` at start when its cached changelog doesn't cover the running version.
Non-interactive and cloud sessions never fetch them.

For omitted members and restoring earlier settings, see [Claude Code choices](/kong-harnesses/profile-file/#claude-code-choices).
When a member is omitted, {{ site.claude_code }} reads user settings, another settings file, or the shell, and otherwise uses its default.
That default depends on the model provider and sign-in, such as usage metrics off on Azure AI Foundry.
Set each member to `false` to ensure its traffic stays off.

`cost_warnings` doesn't change which hosts {{ site.claude_code }} contacts.
[Features that change behind the gateway](/ai-gateway/set-up-claude-code-with-kong-harnesses/#features-that-change-behind-the-gateway) explains what it does.

### Fast mode availability check

`kong-harnesses profile create` turns fast mode off because it costs more per token on the API and draws on subscription usage credits.
Fast mode works only where {{ site.claude_code }} offers it for the provider, model, and organization ([fast mode requirements](https://code.claude.com/docs/en/fast-mode#requirements)).

{{ site.claude_code }} skips the availability check with a gateway key or when the nonessential traffic switch is on.
When `fast_mode` is `true`, activation makes {{ site.claude_code }} treat a skipped check or network error as available, unless the organization disabled fast mode.
If a proxy answers with its own page, {{ site.claude_code }} reads it as [disabled by your organization](https://code.claude.com/docs/en/fast-mode#fast-mode-has-been-disabled-by-your-organization), so let the check reach `api.anthropic.com` through the proxy.
If the proxy can't allow it, set `CLAUDE_CODE_SKIP_FAST_MODE_ORG_CHECK=1` in {{ site.claude_code }} settings, because the variable activation writes doesn't cover that case.

### Artifact availability

Artifacts require a claude.ai sign-in, an eligible plan, and the Anthropic API provider mode, so they work only with a Claude-subscriptions profile ([artifacts availability](https://code.claude.com/docs/en/artifacts#availability) lists plans, organization settings, and run contexts).
Setting `artifact` to `true` in the profile also requires `artifact: true` on the gateway route.
When `feature_flags` is `false`, Claude can't read artifact comments or another organization's public artifact, even when the nonessential traffic switch is blank.
`enableArtifact: true` doesn't override `false` from another settings file, `CLAUDE_CODE_DISABLE_ARTIFACT`, or organization settings.

On Team and Enterprise plans, an Owner can turn off artifacts with the **Artifacts** toggle in [**Organization settings** > **Artifacts**](https://claude.ai/admin-settings/artifacts).
Enterprise organizations with custom roles can also remove the **Artifacts** permission in [**Organization settings** > **Roles**](https://claude.ai/admin-settings/roles).

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
The `anthropic` check of `kong-harnesses doctor` checks only the user settings file.
The `overrides` check warns when project settings in the current directory change a profile's traffic choices (unless managed settings pin them) or turn off the Artifact tool, while command-line flags aren't checked.

### In the profile

`kong-harnesses profile create` writes a schema 18 profile with every member in the table set to `false`.
Two flags or their interactive prompts override that default: `--auto-updates on` sets `auto_updates` to `true`, and `--anthropic-telemetry on` sets `anthropic_telemetry`, `feature_flags` and `error_reports` to `true`.
Turning a member on removes only the profile restriction, so the provider and account conditions in the table still apply.

To keep a feature on, set its member to `true` in a schema 18 profile.
From schema 18, `profile create` and `profile import` refuse `feedback_survey: true` with `anthropic_telemetry: false`, so set `anthropic_telemetry` to `true` or omit it.
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

To turn off outside traffic without {{site.kong_harnesses}}, add the settings for the members in [Traffic that goes outside the gateway](#traffic-that-goes-outside-the-gateway) to a [{{ site.claude_code }} settings file](https://code.claude.com/docs/en/settings), using the setting names and switch rules in [Claude Code choices](/kong-harnesses/profile-file/#claude-code-choices).
Environment variables go in `env`, while `skipWebFetchPreflight`, `enableArtifact`, and `disableClaudeAiConnectors` (which disables claude.ai connectors like `ENABLE_CLAUDEAI_MCP_SERVERS=false`, though activation doesn't write it) are top-level keys.
For feature flags, use `CLAUDE_CODE_DISABLE_FEATURE_FLAGS` on v2.1.319 and later, or `DISABLE_GROWTHBOOK` on v2.1.124 through v2.1.318 ([environment variables](https://code.claude.com/docs/en/env-vars#variables)).
To enable a feature that `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC` turns off, set that variable blank (`""`) or leave it unset, because {{ site.claude_code }} reads any non-empty value, including `0`, as on.

To enforce these settings, deploy [managed settings](https://code.claude.com/docs/en/managed-settings) through MDM or `managed-settings.json`, or pass them with `--policy` to [`kong-harnesses fleet build`](/kong-harnesses/fleet-build-options/#delivery-method-and-existing-policy) and [deploy the build](/kong-harnesses/roll-out-claude-code-through-mdm/#deploy-to-managed-computers).
Also set `FORCE_AUTOUPDATE_PLUGINS` to `0` in managed `env`, because `FORCE_AUTOUPDATE_PLUGINS=1` otherwise restores automatic plugin and marketplace updates.
A managed `env` value [takes precedence](https://code.claude.com/docs/en/env-vars#precedence) over user, project, and most shell values.
An activated profile doesn't receive [server-managed settings](https://code.claude.com/docs/en/server-managed-settings#platform-availability), because activation sets a gateway base URL (and a provider switch or `apiKeyHelper` where applicable) instead of a direct `api.anthropic.com` connection.
