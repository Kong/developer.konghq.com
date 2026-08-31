---
title: Manage {{site.konnect_short_name}} audit logs with kongctl

description: >-
  Pull, follow, and listen to {{site.konnect_short_name}} audit logs with
  kongctl.

content_type: reference
layout: reference



works_on:
  - konnect

tools:
  - kongctl

breadcrumbs:
  - /kongctl/

related_resources:
  - text: Get started with kongctl
    url: /kongctl/get-started/
  - text: Declarative configuration with kongctl
    url: /kongctl/declarative/
next_steps:
  - text: Example declarative configurations
    url: https://github.com/Kong/kongctl/tree/v1.14.0/docs/examples/declarative
  - text: Learn about managing declarative configuration with kongctl
    url: /kongctl/declarative/
  - text: Learn about kongctl authorization options
    url: /kongctl/authentication/
  - text: kongctl configuration reference guide
    url: /kongctl/config/
  - text: kongctl troubleshooting guide
    url: /kongctl/troubleshooting/
  - text: Using kongctl and decK for full API platform management
    url: /kongctl/kongctl-and-deck/
  - text: View the {{site.konnect_short_name}} API reference
    url: /konnect-api/
---

This page explains how to retrieve organization audit logs and receive audit-log
webhooks with kongctl.

kongctl can:

- Pull organization audit logs on demand.
- Retrieve every cursor page in a result set.
- Follow new organization audit logs until interrupted.
- Create a {{site.konnect_short_name}} audit-log destination.
- Configure the regional {{site.konnect_short_name}} audit-log webhook.
- Start a local HTTP listener to receive webhook events.
- Persist events to local JSONL storage.
- Optionally stream events to STDOUT.
- Optionally run the listener detached in the background.

## Command forms

Supported forms ({{site.konnect_short_name}}-first):

- `kongctl listen`
- `kongctl listen audit-logs`
- `kongctl listen konnect audit-logs`
- `kongctl tail`
- `kongctl tail audit-logs`
- `kongctl tail konnect audit-logs`
- `kongctl tail audit-logs listener`
- `kongctl get audit-logs`
- `kongctl get konnect audit-logs`
- `kongctl get audit-logs destinations`
- `kongctl get audit-logs destination <id|name>`
- `kongctl get audit-logs webhook`
- `kongctl ps`

Use `get audit-logs` to retrieve a finite set of organization audit logs.
kongctl follows cursor pagination automatically.

Use `tail audit-logs` to retrieve a five-minute catch-up window and then poll
for new organization audit logs until interrupted. This command is equivalent
to `kongctl get audit-logs --since 5m --follow`.

Use `listen audit-logs` to create a temporary webhook destination and start a
local listener. Use `tail audit-logs listener` for the same webhook workflow
with records streamed to STDOUT.

The listener commands have these requirements:

- Provide the endpoint from either `--endpoint` or `--public-url` + `--path`.
- `--endpoint` must contain the complete public listener URL and path.
- Listener `--jq` requires listener `--tail`.
- Listener `--detach` isn't compatible with listener `--tail`.

## Pull organization audit logs

Retrieve the 50 most recent events:

```sh
kongctl get audit-logs
```

Retrieve the last 24 hours as JSONL:

```sh
kongctl get audit-logs --since 24h --output jsonl > audit-logs.jsonl
```

Use inclusive RFC3339 bounds and an event type filter:

```sh
kongctl get audit-logs \
  --start-time 2026-08-23T00:00:00Z \
  --end-time 2026-08-24T00:00:00Z \
  --type authorization
```

Supported event types are `authentication`, `authorization`, and
`gateway_access`. Complete API records include their ED25519 signatures.
kongctl doesn't verify signatures or retrieve JWKS.

### Pagination and limits

`--page-size` controls the maximum number of records requested in each API
call. It defaults to 100 and accepts values from 1 through 1,000. kongctl
continues through the returned cursor until it reaches the final page.

`--limit` controls the total records returned by the client. It defaults to 50
when you don't specify a time window. Time-window queries are unlimited unless
you specify `--limit`. Set `--limit 0` explicitly for unlimited retrieval.

JSON and YAML output include `metadata.count` and `metadata.truncated`.
`truncated` is `true` when a limit stops collection while more records exist.

### Time filters

`--start-time` and `--end-time` accept inclusive RFC3339 timestamps. `--since`
accepts a Go duration, such as `30m` or `24h`, and can't be combined with an
absolute bound. kongctl resolves `--since` once at startup for finite pulls.

Go durations don't support `d` or `w`. Use `24h` for one day and `168h` for
one week.

### Output and partial failures

Finite pulls support `text`, `json`, `yaml`, and `jsonl`:

- JSON and YAML are buffered and written after every required page succeeds.
- JSONL writes completed pages immediately. If a later page fails, STDOUT
  contains a partial collection and kongctl exits with a nonzero status.
- Text output provides a compact summary. Use repeated
  `--columns HEADER=.field` flags to select fields.
- JSON and YAML apply `--jq` to the output envelope. JSONL applies it to each
  record independently.

Automation must check the exit status instead of relying on the output file's
presence:

```sh
if kongctl get audit-logs --since 24h --output jsonl > audit-logs.jsonl; then
  echo "Audit-log collection completed"
else
  echo "Audit-log collection failed or is partial" >&2
  exit 1
fi
```

## Follow organization audit logs

Start with a five-minute catch-up and continue polling:

```sh
kongctl tail audit-logs
```

Equivalent forms are:

```sh
kongctl get audit-logs --since 5m --follow
kongctl get audit-logs --since 5m -F
kongctl tail konnect audit-logs
```

Follow mode supports `text` and `jsonl`. `--poll-interval` defaults to 10
seconds. Press Ctrl-C to stop it.

Each successful polling cycle records a checkpoint. The next cycle overlaps
that checkpoint by one minute, deduplicates records by signature or record
hash, and emits new records in timestamp order. Temporary network, rate-limit,
and server errors preserve the checkpoint and use exponential backoff capped
at one minute. Non-retryable authentication, authorization, and client errors
stop the command with a nonzero status.

## Migrate webhook tail commands

`tail audit-logs` now follows the organization pull API. Add the `listener`
child to use the previous webhook-based behavior:

```sh
kongctl tail audit-logs listener \
  --endpoint https://example.com/audit-logs \
  --authorization "Bearer <token>"
```

`kongctl listen` and `kongctl listen audit-logs` are unchanged.

## End-to-end flow

When you run `kongctl listen`:

1. Determines endpoint from `--endpoint` or `--public-url` + `--path`.
1. Checks that a webhook does not already exist for the region (due to one
   webhook per region limitation).
1. Creates audit-log destination in {{site.konnect_short_name}}.
1. Configures and enables regional webhook to use that destination.
1. Starts local listener on `--listen-address` and `--path`.
1. Persists events to local storage.
1. On shutdown, attempts webhook/destination cleanup.

### Startup guard

Before attaching a new destination, kongctl validates that the regional
webhook is in the unconfigured state:

- `enabled=false`
- `endpoint="unconfigured"`

If webhook state is already configured, startup fails fast.

## Event storage and format

Default config profile-scoped storage directory:

- `~/.config/kongctl/audit-logs/<sanitized-profile>/`
- `<sanitized-profile>` is the profile name with unsupported path
  characters replaced by `_`.

Files:

- `events.jsonl`: received event records (raw records, one per line)
- `listener.json`: listener state metadata
- `destination.json`: destination state metadata

Payload handling:

- Only `POST` requests to configured listener path are accepted.
- `gzip` request bodies are decoded when needed.
- Decoded payload is split into line-delimited records.
- Records are stored as-is in `events.jsonl`.

No additional kongctl event envelope is added.

## Tailing and jq

Use the webhook listener child to stream records to STDOUT:

```shell
kongctl tail audit-logs listener \
  --endpoint https://example.com/audit-logs \
  --authorization "Bearer <token>"
```

Filter JSON records with `jq` expression support:

```shell
kongctl tail audit-logs listener \
  --endpoint https://example.com/audit-logs \
  --log-format json \
  --jq '{ts:.event_ts, name, request:(.request // null)}'
```

Notes:

- For structured filtering, use `--log-format json`.
- In tail mode, lifecycle text is logged to the log file, not STDOUT.

## Security

Recommended:

- Use an HTTPS destination endpoint.
- Keep TLS verification enabled (default).
- Provide `--authorization` so {{site.konnect_short_name}} sends an `Authorization` header.

Listener-side authorization validation:

- If `--authorization` is provided, listener requires an exact header match.
- Validation is done in-process before accepting event payloads.

About TLS:

- The local listener is plain HTTP by default.
- HTTPS is usually terminated by your tunnel or reverse proxy.
- `--skip-ssl-verification` affects {{site.konnect_short_name}} delivery to destination endpoint.

## Tailscale example

You can use [Tailscale](https://tailscale.com/) to expose a local listener
through a public HTTPS endpoint during local development.

Example:

```shell
tailscale funnel 19090
```

If your Tailscale DNS host is `my-host.ts.net`, set the destination endpoint
to your listener path:

```shell
kongctl listen --endpoint https://my-host.ts.net/audit-logs
```

Equivalent pattern:

```text
--endpoint https://<tailscale-host>.ts.net/audit-logs
```

## Detached listener mode

Run listener in the background:

```shell
kongctl listen --endpoint https://example.tld/audit-logs --detach
```

Parent process prints:

- child `pid`
- child log file path
- process record file path

Child logs are written to:

- `~/.config/kongctl/logs/kongctl-listener-<pid>.log`

## Process registry and `kongctl ps`

Detached processes are tracked in:

- `~/.config/kongctl/processes/<pid>.json`

List tracked detached processes:

```shell
kongctl ps
```

Stop one detached process:

```shell
kongctl ps stop <pid>
```

Stop all tracked detached processes:

```shell
kongctl ps stop --all
```

Behavior:

- Running tracked process: `stop` sends `SIGTERM` and removes record.
- Exited or stale record: `stop` prunes the record.
- Failed detached startup keeps process record for debugging.

## Troubleshooting

### `kongctl ps` shows no running listener

If `kongctl ps` is empty but `ps aux` shows a `kongctl listen` process, that
process is unmanaged (typically started before process registry tracking).

Use OS tools for unmanaged processes:

```shell
kill -TERM <pid>
```

Then launch a new detached listener to use managed tracking.

### Startup fails with webhook already configured

If you see an error similar to:

- `regional audit-log webhook is already configured ...`

A regional webhook is already active. Stop the active listener and clear
webhook state before launching a new one.

### No events arriving

Check:

- Destination endpoint includes listener path (for example `/audit-logs`).
- Tunnel forwards HTTPS endpoint to local listen address and port.
- Listener is running and bound to expected `--listen-address`.
- Authorization header configuration matches on both sides.

### Verify process and socket quickly

```shell
pid=<pid>
ps -p "$pid" -o pid,ppid,stat,etime,cmd
ss -ltnp | rg ':19090'
tail -n 200 ~/.config/kongctl/logs/kongctl-listener-${pid}.log
```

## Current limitations

- Event file retention and rotation are not implemented yet.
- Replay jobs are not implemented yet.
- `kongctl ps` currently manages tracked detached processes only.
- Pull and follow cover organization audit logs. Dev Portal audit logs remain
  webhook-based.
- Audit-log retention is controlled by the service.
