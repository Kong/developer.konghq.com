---
title: How to configure http log plugin with Loki
content_type: support
description: Explains how to format the HTTP Log plugin's output so log entries are ingested correctly by Grafana Loki.
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: Why don't HTTP Log plugin entries show up in Grafana Loki?
  a: |
    Loki expects log entries in its streams format, not Kong's raw log JSON. Add a Lua snippet under the HTTP Log plugin's `custom_fields_by_lua` (field `Streams`) that reshapes `kong.log.serialize()` output into the `{stream, values}` structure Loki's push API expects, then point the plugin at your Loki push endpoint.
related_resources: []
---

## Problem

We are trying to deploy the http plugin and utilize grafana/loki as our HTTP endpoint.

We've set the plugin directly to the endpoint with this format:

```

https://<user>:<password>=@logs.grafana.net/loki/api/v1/push
```

However, when looking in grafana we notice that nothing is actually being logged. How can we resolve this?

## Cause

Loki is expecting a specific format when sending logs over to it. For the http log plugin to generate the logs inside Loki, we need to add some custom formatting.

## Solution

*This is only an example - anything additional should be created as custom work.*

Inside the plugin under `custom_fields_by_lua` we can add the field `Streams` with the following values:

```lua

"local ts=string.format('%18.0f', os.time()*1000000000) local log_payload = kong.log.serialize() local request = log_payload['request'] local service = log_payload['service'] local response = log_payload['response'] local latencies = log_payload['latencies'] local t = { {stream = {gateway='total-latency', service=service['name']}, values={{ts, 'ip='..log_payload['client_ip']..' duration='..latencies['request']..'ms upstream_uri='..log_payload['upstream_uri']..' status='..response['status']}}}, {stream = {gateway='upstream-latency', service=service['name']}, values={{ts, 'ip='..log_payload['client_ip']..' duration='..latencies['proxy']..'ms upstream_uri='..log_payload['upstream_uri']..' status='..response['status']}}}, {stream = {gateway='gateway-latency', service=service['name']}, values={{ts, 'ip='..log_payload['client_ip']..' duration='..latencies['kong']..'ms upstream_uri='..log_payload['upstream_uri']..' status='..response['status']}}} } return t"}
```

It should look like this in the UI:

Now when we send a request through kong and Log into Grafana we can see log entries like this:
