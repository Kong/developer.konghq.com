---
title: "{{ site.claude_code }} traffic outside {{site.ai_gateway}}"
description: "Lists the hosts that {{ site.claude_code }} contacts outside {{site.ai_gateway}} with a {{site.kong_harnesses}} profile, the profile member that turns off each kind of traffic, and what that costs."
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

A {{site.kong_harnesses}} profile routes only the requests that {{ site.claude_code }} sends to its base URL through [{{site.ai_gateway}}](/ai-gateway/).
Other requests, such as usage metrics, update checks and feature flag lookups, go straight to services like Anthropic and GitHub, where the gateway can't log, limit or block them.
`kong-harnesses profile create` turns that traffic off by default, except for the choices in [Turn off the outside traffic](#turn-off-the-outside-traffic).

{{ site.claude_code }} on the web and Claude in Slack don't use the profile.
When all model traffic must pass through the gateway, [turn off those products](/kong-harnesses/claude-code-web-and-slack/).

## Traffic that goes outside the gateway

Each row is one kind of outside traffic and the `clients.claude-code` profile member that turns it off.
The provider and account conditions of the profile still apply when a member is `true`.

{% table %}
columns:
  - title: Traffic
    key: traffic
  - title: Hosts
    key: hosts
  - title: Profile member
    key: member
  - title: When it's off
    key: off
rows:
  - traffic: Usage metrics
    hosts: "`api.anthropic.com`, `http-intake.logs.us5.datadoghq.com`"
    member: "`anthropic_telemetry`"
    off: "No [usage metrics](https://code.claude.com/docs/en/data-usage#telemetry-services) go to Anthropic."
  - traffic: Feature flags
    hosts: "`api.anthropic.com`"
    member: "`feature_flags`"
    off: "Features that [need feature flags](https://code.claude.com/docs/en/env-vars#features-that-need-feature-flag-fetching) stop, including claude.ai skill and plugin sync."
  - traffic: Error reports
    hosts: "`browser-intake-us5-datadoghq.com`"
    member: "`error_reports`"
    off: "Nothing changes. {{ site.claude_code }} sends error reports only on a direct Anthropic API connection, so a profile sends none."
  - traffic: Fast mode check
    hosts: "`api.anthropic.com`"
    member: "`fast_mode`"
    off: "Fast mode is off. See [Fast mode](#fast-mode)."
  - traffic: WebFetch domain check
    hosts: "`api.anthropic.com`"
    member: "`webfetch_preflight`"
    off: "WebFetch runs without Anthropic's [domain safety blocklist](https://code.claude.com/docs/en/data-usage#webfetch-domain-safety-check). Restrict domains with `WebFetch(domain:...)` permission rules."
  - traffic: claude.ai connectors
    hosts: "`mcp-proxy.anthropic.com`"
    member: "`connectors`"
    off: "[claude.ai connectors](https://code.claude.com/docs/en/mcp#use-mcp-servers-from-claude-ai) don't load. With a gateway key, {{ site.claude_code }} has no claude.ai sign-in, so they can't load even when `connectors` is `true`."
  - traffic: "`/feedback`, `/bug` and `/share`"
    hosts: "Anthropic, `github.com`"
    member: "`bug_command` and `feedback_command`"
    off: "Either member turns off all of these [feedback commands](https://code.claude.com/docs/en/data-usage#telemetry-services). From schema 18, set both to the same value."
  - traffic: Feedback survey
    hosts: "Anthropic"
    member: "`feedback_survey`"
    off: "No [session quality surveys](https://code.claude.com/docs/en/data-usage#session-quality-surveys)."
  - traffic: Official marketplace install
    hosts: "`github.com`"
    member: "`official_marketplace_autoinstall`"
    off: "{{ site.claude_code }} skips the [official marketplace](https://code.claude.com/docs/en/plugins/anthropic-marketplaces) auto-install."
  - traffic: Artifacts
    hosts: "`api.anthropic.com`, `*.frame.claudeusercontent.com`, `claude.ai`"
    member: "`artifact`"
    off: "No publishing or reading of [artifacts](https://code.claude.com/docs/en/artifacts). See [Artifacts](#artifacts)."
  - traffic: Automatic updates and other nonessential traffic
    hosts: "`downloads.claude.ai`, `registry.npmjs.org`, `formulae.brew.sh`, `raw.githubusercontent.com`, `api.anthropic.com`"
    member: "`auto_updates`"
    off: "{{ site.claude_code }} doesn't update itself, its plugins or its marketplaces. Upgrade with `claude update` or your package manager."
{% endtable %}

[Claude Code choices](/kong-harnesses/profile-file/#claude-code-choices) lists the settings that activation writes for each member, and what happens when you omit one.
`cost_warnings` doesn't change which hosts {{ site.claude_code }} contacts. See [{{ site.claude_code }} features behind the gateway](/kong-harnesses/claude-code-features-behind-the-gateway/).

### Fast mode

When `fast_mode` is `true`, activation writes `CLAUDE_CODE_SKIP_FAST_MODE_NETWORK_ERRORS=1`, so {{ site.claude_code }} treats a check it didn't send, or a network error, as fast mode available.
A proxy that answers the check with its own page makes {{ site.claude_code }} report fast mode as [disabled by your organization](https://code.claude.com/docs/en/fast-mode#fast-mode-has-been-disabled-by-your-organization).
Let the check reach `api.anthropic.com` through the proxy, or set `CLAUDE_CODE_SKIP_FAST_MODE_ORG_CHECK=1` in the {{ site.claude_code }} settings, which activation doesn't write.

### Artifacts

Artifacts work only with a profile that uses the developers' own Claude subscriptions, and `artifact: true` also needs `artifact: true` on the route in the profile.
In a schema 14 or later profile, `artifact: false` makes activation write `enableArtifact: false`, so no other settings file turns artifacts back on.
See the [artifacts availability](https://code.claude.com/docs/en/artifacts#availability) rules for plans and organization settings.

## Traffic that stays

When every kind of traffic in the table is off, a session still contacts:

* The {{site.ai_gateway}} host.
* Your identity provider, when the profile signs in through one.
* The OpenTelemetry collector, when the profile sends telemetry to one.
* `claude.ai`, `claude.com`, `platform.claude.com` and `api.anthropic.com`, when the profile uses the developers' own Claude subscriptions. Organizations that use single sign-on also need `sso.claude.com`.
* `code.claude.com`, for documentation lookups.
* The sites, MCP servers, plugins, marketplaces, managed MCP servers and HTTP hooks that developers or settings add. No profile member turns these off.

{{ site.claude_code }} adds hosts in new releases, so use [Network access requirements](https://code.claude.com/docs/en/network-config#network-access-requirements) for the current list.

## Turn off the outside traffic

`kong-harnesses profile create` writes a schema 18 profile with every member in the table set to `false`, unless a flag or prompt turns one on.
Two flags, or their interactive prompts, do that:

* `--auto-updates on` sets `auto_updates` to `true`.
* `--anthropic-telemetry on` sets `anthropic_telemetry`, `feature_flags` and `error_reports` to `true`.

To keep a feature on, set its member to `true`.
From schema 18, `profile create` and `profile import` refuse `error_reports: true` or `feedback_survey: true` with `anthropic_telemetry: false`, and every schema refuses `feature_flags: true` with it.
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

After you change the file, run [`kong-harnesses profile import`](/kong-harnesses/profile/import/) and [`kong-harnesses profile activate`](/kong-harnesses/profile/activate/).
If a developer changes or removes one of these settings later, the `anthropic` check of [`kong-harnesses doctor`](/kong-harnesses/doctor/) fails and shows the command that restores it.

### Enforce the settings

Activation writes the user settings file of {{ site.claude_code }}.
Command-line flags and project settings [take precedence](https://code.claude.com/docs/en/settings#settings-precedence) over it, so a repository or a developer can turn a feature back on.
The `overrides` check of `doctor` warns when project settings in the current directory set a choice differently, but it doesn't look at command-line flags.

Only [managed settings](https://code.claude.com/docs/en/managed-settings) enforce a value.
Pass them with `--policy` to [`kong-harnesses fleet build`](/kong-harnesses/fleet-build-options/#delivery-method-and-existing-policy) and [deploy the build](/kong-harnesses/roll-out-claude-code-through-mdm/#deploy-to-managed-computers).
To turn off outside traffic without {{site.kong_harnesses}}, use the setting names in [Claude Code choices](/kong-harnesses/profile-file/#claude-code-choices).
