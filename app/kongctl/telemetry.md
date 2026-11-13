---
title: kongctl telemetry and privacy
description: >-
  kongctl collects usage data by default. This reference lists the event fields,
  telemetry opt-out options, and how to inspect events locally without sending
  them to Kong.
content_type: reference
layout: reference

works_on:
  - konnect

tools:
  - kongctl

tags:
  - cli

breadcrumbs:
  - /kongctl/

related_resources:
  - text: kongctl configuration reference
    url: /kongctl/config/
  - text: kongctl authentication reference
    url: /kongctl/authentication/
---

kongctl collects limited usage data to help Kong understand which commands,
versions, and platforms are used, and prioritize CLI improvements. Telemetry is
enabled by default. You can disable it at any time.

## What is collected

Each telemetry event contains the following fields:

{% table %}
columns:
  - title: Field
    key: field
  - title: Description
    key: description
rows:
  - field: "`schema_version`"
    description: Version of the telemetry event format.
  - field: "`timestamp`"
    description: Timestamp when the command finishes.
  - field: "`version`"
    description: kongctl version.
  - field: "`os`"
    description: Operating system, such as `linux` or `darwin`.
  - field: "`arch`"
    description: CPU architecture, such as `amd64` or `arm64`.
  - field: "`command_path`"
    description: Command names, such as `login`, `apply`, or `get konnect apis`.
{% endtable %}

The transport also includes a fixed `signal=kongctl` label to identify the tool.
The event doesn't contain a user, device, installation, or
{{site.konnect_short_name}} organization identifier.

## What is not collected

The telemetry payload does not include:

* Command arguments or flag values
* Resource names or IDs
* Authentication tokens or other credentials
* API request bodies or response bodies
* Configuration file contents or file paths
* Hostnames, usernames, email addresses, or IP addresses

Network infrastructure can still observe the source IP address of a telemetry
datagram, even though the payload doesn't contain it.

## When telemetry is sent

When telemetry is enabled, kongctl attempts to send one event when an eligible
command finishes. Help, version, and shell completion commands are excluded, as is
running `kongctl` without a subcommand. Commands that fail before a subcommand
is resolved do not produce an event.

Events are sent to Kong's telemetry receiver at `kong-hf.konghq.com` on UDP port
`61829`. This transport does not use HTTPS or TLS. Delivery is best effort;
telemetry delivery failures do not cause the command to fail.

### Login preference

During the first interactive `kongctl login`, if telemetry is enabled and no
saved device preference exists, kongctl explains what it collects and asks:

```text
Allow kongctl to collect usage data on this device? [Y/n]:
```
{:.no-copy-code}

Answer `n` to disable telemetry or `y` to enable it. Pressing Enter accepts `y`.
The answer is saved in `.telemetry-enabled` beside your `config.yaml` file and
applies to all profiles that use that configuration directory. The file contains
`true` or `false`.

By default, the preference file is at
`$XDG_CONFIG_HOME/kongctl/.telemetry-enabled`, or
`$HOME/.config/kongctl/.telemetry-enabled` when `XDG_CONFIG_HOME` is unset.
If you use a custom configuration file, the preference is stored in that file's
directory instead.

### CI and non-interactive sessions

Telemetry is also enabled by default in CI and other non-interactive sessions.
These sessions do not ask for a preference. When telemetry is enabled and no
saved preference exists, a non-interactive login displays the disclosure without
prompting or saving a preference. Set an opt-out environment variable before
running kongctl to disable collection in automation.

## Disable telemetry

For a single invocation, use any one of the following options. Pass the flag:

```bash
kongctl --no-telemetry get apis
```

Or set `KONGCTL_NO_TELEMETRY`:

```bash
KONGCTL_NO_TELEMETRY=true kongctl get apis
```

Or set `DO_NOT_TRACK`:

```bash
DO_NOT_TRACK=1 kongctl get apis
```

To disable telemetry across commands and profiles in a shell or CI environment:

```bash
export KONGCTL_NO_TELEMETRY=true
```

You can alternatively export `DO_NOT_TRACK=1`. The value must be exactly `1`;
`KONGCTL_NO_TELEMETRY` accepts `true` case-insensitively.

To disable telemetry for a profile, add this to your
[configuration file](/kongctl/config/):

```yaml
default:
  telemetry:
    enabled: false
```

Replace `default` with your profile name. A saved device preference takes
precedence over this setting.

### Setting precedence

kongctl checks these settings in order:

1. If `--no-telemetry`, `DO_NOT_TRACK=1`, or `KONGCTL_NO_TELEMETRY=true` is set,
   telemetry is off, regardless of other settings.
2. Otherwise, use the choice you saved at the initial login prompt.
3. If you haven't saved a choice, use the profile's `telemetry.enabled` setting,
   which defaults to `true`.

`KONGCTL_NO_TELEMETRY=false` does not turn telemetry on. Your saved login choice
or profile setting still applies.

### Change or reset the device preference

To change your saved preference, edit `.telemetry-enabled` in your configuration
directory and replace its contents with `false` to disable telemetry or `true`
to enable it.

To reset the preference, delete only `.telemetry-enabled` from that directory.
The active profile's setting then applies. Resetting the preference does not
disable telemetry; without another opt-out, it defaults to enabled. If telemetry
is enabled, the next interactive login asks again.

## Inspect events without sending them

Set `telemetry.debug` to `true` in the active profile to write events to a local
JSON Lines file instead of sending them to Kong:

```yaml
default:
  telemetry:
    enabled: true
    debug: true
```

Run an eligible command, such as `kongctl get apis`, then inspect
`$XDG_CONFIG_HOME/kongctl/logs/telemetry.log`, or
`$HOME/.config/kongctl/logs/telemetry.log` when `XDG_CONFIG_HOME` is unset.
For a custom configuration file, the log is in `logs/telemetry.log` beside it.

An illustrative event looks like this:

```json
{
  "schema_version": 1,
  "timestamp": "2026-11-11T12:00:00Z",
  "version": "1.0.0",
  "os": "linux",
  "arch": "amd64",
  "command_path": "get konnect apis"
}
```
{:.no-copy-code}

Debug mode respects all telemetry opt-outs. If a flag, environment variable, or
saved device preference disables telemetry, no events are written. Local events
are appended to the log; you can delete the file when you finish inspecting it.
Set `telemetry.debug` back to `false` to resume normal delivery when telemetry
is enabled.

## Privacy questions

For questions about data handling or retention, contact
[Kong's privacy team](mailto:privacyrequests@konghq.com). The
[telemetry implementation](https://github.com/Kong/kongctl/tree/main/internal/telemetry)
is available in the kongctl repository.
