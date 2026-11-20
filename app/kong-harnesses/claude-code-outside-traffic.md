---
title: "{{ site.claude_code }} traffic outside {{site.ai_gateway}}"
description: "The hosts that {{ site.claude_code }} contacts outside {{site.ai_gateway}}, the profile member and {{ site.claude_code }} setting that turn off each one, what each one costs when it's off, and how to turn off {{ site.claude_code }} on the web and in Slack."
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
  - text: Set up {{ site.claude_code }} with kong-harnesses
    url: /ai-gateway/set-up-claude-code-with-kong-harnesses/
  - text: "{{site.kong_harnesses}} profile"
    url: /kong-harnesses/profile/
  - text: "{{site.kong_harnesses}} doctor"
    url: /kong-harnesses/doctor/
---

A {{site.kong_harnesses}} profile points {{ site.claude_code }} at [{{site.ai_gateway}}](/ai-gateway/) with `ANTHROPIC_BASE_URL`.
That setting moves only the model requests.
{{ site.claude_code }} also sends usage metrics, update checks, feature flag lookups and other requests to Anthropic, GitHub and Google Cloud Storage.
Those requests don't pass through the gateway, so the gateway can't log, limit or block them.

If your network policy says that all {{ site.claude_code }} traffic must pass through the gateway, keep every feature in the following tables off.
`kong-harnesses profile create` writes that profile for you.
Turn a feature back on only when your policy allows the host that the feature contacts.

## Traffic that goes outside the gateway

Each row in the following table is one kind of {{ site.claude_code }} traffic that goes straight to its destination.
The profile member is a member of `clients.claude-code` in the profile.

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
    destination: "`api.anthropic.com` and Anthropic's logging service"
    member: "`anthropic_telemetry`"
    cost: Anthropic doesn't get latency, reliability and usage data from your sessions. Feature flags also turn off.
  - traffic: Feature flags
    destination: "`api.anthropic.com`"
    member: "`feature_flags`"
    cost: "{{ site.claude_code }} uses its built-in values for features that Anthropic turns on in stages."
  - traffic: Error reports
    destination: Anthropic's error tracking service
    member: "`error_reports`"
    cost: Anthropic doesn't get stack traces when {{ site.claude_code }} fails.
  - traffic: WebFetch domain check
    destination: "`api.anthropic.com`"
    member: "`webfetch_preflight`"
    cost: "WebFetch still works, without Anthropic's list of blocked domains. To limit the domains, add `WebFetch(domain:...)` permission rules."
  - traffic: claude.ai connectors
    destination: "`claude.ai` and `mcp-proxy.anthropic.com`"
    member: "`connectors`"
    cost: "The connectors don't load. The gateway sign-in replaces the claude.ai sign-in, so they can't load behind the gateway in any case. Add the MCP servers you need with `claude mcp add`."
  - traffic: "`/bug` and `/feedback`"
    destination: Anthropic and Google Cloud Storage
    member: "`bug_command` and `feedback_command`"
    cost: Developers can't send a conversation to Anthropic. Each member turns off both commands.
  - traffic: Feedback survey
    destination: Anthropic
    member: "`feedback_survey`"
    cost: "{{ site.claude_code }} doesn't ask developers to rate a session."
  - traffic: Official plugin marketplace install
    destination: "`github.com`"
    member: "`official_marketplace_autoinstall`"
    cost: "{{ site.claude_code }} doesn't add Anthropic's plugin marketplace. Developers can add it with `/plugin marketplace add`."
  - traffic: Automatic updates and other background traffic
    destination: "`downloads.claude.ai`, `raw.githubusercontent.com` and `api.anthropic.com`"
    member: "`auto_updates`"
    cost: "{{ site.claude_code }} doesn't check for updates, fetch the release notes, fetch the MCP server registry or let plugins use the network. Cloud sessions, Remote Control and pull request status badges also turn off. Run `claude update` to install a newer release."
{% endtable %}

A member that the profile leaves out keeps the {{ site.claude_code }} default, and the default sends the traffic.
So a profile that must keep all traffic on the gateway sets each member to `false`.

`fast_mode` and `cost_warnings` don't change which hosts {{ site.claude_code }} contacts.
[Features that change behind the gateway](/ai-gateway/set-up-claude-code-with-kong-harnesses/#features-that-change-behind-the-gateway) explains what they do.

### Members that depend on each other

`auto_updates` set to `false` turns off all nonessential {{ site.claude_code }} traffic.
That one switch also turns off usage metrics, feature flags, error reports, `/bug`, `/feedback` and the feedback survey.
For that reason, {{site.kong_harnesses}} refuses a profile that turns on one of these features while another member keeps it off:

* `anthropic_telemetry`, `error_reports` and `feedback_survey` set to `true` need `auto_updates` set to `true`.
* `feature_flags` set to `true` needs `auto_updates` and `anthropic_telemetry` set to `true`.
* `bug_command` and `feedback_command` must have the same value, and `true` for either one needs `auto_updates` set to `true`.

## Traffic that stays

When every member in the profile is `false`, a {{ site.claude_code }} session contacts only these hosts:

* The {{site.ai_gateway}} host
* Your identity provider, for the sign-in
* The OpenTelemetry collector, when the profile sends telemetry to one
* The sites that WebFetch opens, and the MCP servers and plugins that a developer adds

## Turn off the outside traffic

You can turn off each kind of outside traffic in the profile, or in {{ site.claude_code }} settings directly.

### In the profile

`kong-harnesses profile create` sets every member in the table to `false`.
`--auto-updates on` keeps automatic updates on.

To keep a feature on, set its member to `true` in the profile file.
The members need `schema_version` 14 or later.
The following part of a profile file keeps the WebFetch domain check on, and keeps the other traffic off:

```json
{
  "clients": {
    "claude-code": {
      "auto_updates": false,
      "anthropic_telemetry": false,
      "feature_flags": false,
      "error_reports": false,
      "official_marketplace_autoinstall": false,
      "connectors": false,
      "bug_command": false,
      "feedback_command": false,
      "feedback_survey": false,
      "webfetch_preflight": true
    }
  }
}
```
{:.no-copy-code}

After you change the file, run `kong-harnesses profile import` and `kong-harnesses profile activate` again.
Activation writes the matching settings to the `env` key of the {{ site.claude_code }} user settings file.
If a developer changes or removes one of these settings later, the `anthropic` check of [`kong-harnesses doctor`](/kong-harnesses/doctor/) fails and shows the command that restores it.

### In {{ site.claude_code }} settings

Each profile member writes one or more {{ site.claude_code }} settings.
To set them without {{site.kong_harnesses}}, add them to the `env` key of a [{{ site.claude_code }} settings file](https://code.claude.com/docs/en/settings).
To stop developers from turning them back on, set them in [managed settings](https://code.claude.com/docs/en/server-managed-settings).
Managed settings take precedence over the user settings file that `profile activate` writes.

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
    setting: "`DISABLE_GROWTHBOOK=1`"
  - member: "`error_reports`"
    setting: "`DISABLE_ERROR_REPORTING=1`"
  - member: "`webfetch_preflight`"
    setting: "`skipWebFetchPreflight: true`, a top-level setting outside `env`"
  - member: "`connectors`"
    setting: "`ENABLE_CLAUDEAI_MCP_SERVERS=false`"
  - member: "`bug_command`"
    setting: "`DISABLE_BUG_COMMAND=1`"
  - member: "`feedback_command`"
    setting: "`DISABLE_FEEDBACK_COMMAND=1`"
  - member: "`feedback_survey`"
    setting: "`CLAUDE_CODE_DISABLE_FEEDBACK_SURVEY=1`"
  - member: "`official_marketplace_autoinstall`"
    setting: "`CLAUDE_CODE_DISABLE_OFFICIAL_MARKETPLACE_AUTOINSTALL=1`"
  - member: "`auto_updates`"
    setting: "`DISABLE_AUTOUPDATER=1` and `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1`"
{% endtable %}

[Network access requirements](https://code.claude.com/docs/en/network-config) in the {{ site.claude_code }} documentation lists every host that {{ site.claude_code }} can contact.

## {{ site.claude_code }} on the web and in Slack

{{ site.claude_code }} on the web and {{ site.claude_code }} in Slack run sessions on Anthropic's infrastructure with a claude.ai account.
Those sessions don't use the {{site.kong_harnesses}} profile, so their model requests never pass through the gateway.
If all model traffic must pass through the gateway, turn off both products for your organization.

To turn off {{ site.claude_code }} on the web on a Team or Enterprise plan:

1. Sign in to claude.ai as an Owner of your organization.
1. Open the [{{ site.claude_code }} admin settings](https://claude.ai/admin-settings/claude-code).
1. Turn off cloud sessions.

If your organization uses custom roles, also leave the cloud sessions permission out of each role in [**Organization settings** > **Roles**](https://claude.ai/admin-settings/roles).
[{{ site.claude_code }} on the web](https://code.claude.com/docs/en/claude-code-on-the-web) explains cloud sessions.

{{ site.claude_code }} in Slack starts cloud sessions, so it stops when cloud sessions are off.
Claude Tag, the Claude app in Slack for Team and Enterprise plans, has its own settings.
An Owner controls Claude Tag for each channel, each workspace and the organization default in the [Claude Tag admin settings](https://claude.ai/admin-settings/claude-tag).

Slack workspace administrators also control the Claude app in Slack:

* A workspace administrator decides whether to install the Claude app.
* On Enterprise Grid, an organization administrator decides which workspaces get the Claude app.
* When an administrator removes the Claude app from a workspace, every user in that workspace loses access at once.

[{{ site.claude_code }} in Slack](https://code.claude.com/docs/en/slack) has the details.
