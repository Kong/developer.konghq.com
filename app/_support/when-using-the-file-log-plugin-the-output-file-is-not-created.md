---
title: When using the `file-log` plugin, the output file is not created
content_type: support
description: Explains why `file-log` plugin output isn't created when Kong runs under systemd, where `PrivateTmp` redirects `/tmp` writes to a private systemd directory instead of the configured path.
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: When using the `file-log` plugin, the output file is not created
  a: |
    When Kong runs under systemd, `PrivateTmp` isolates `/tmp` into a private per-service directory, so `file-log` plugin output configured under `/tmp` (via `config.path`) is written there instead of the path you expect. Either read the log from the private systemd `/tmp` path, or set `PrivateTmp=false` in the `.service` file and run `systemctl daemon-reload` followed by a Kong restart.
related_resources: []
---

## Problem

After applying the `file-log` plugin to an API and sending a request, the file defined by `config.path` is not created. There are no errors in the Kong logs

```json
{
    "created_at": 1584530151,
    "config": {
        "path": "/tmp/konghttp.log",
        "reopen": true
    },
    "id": "58ec6abf-49d9-49f4-901a-f6e74c728700",
    "service": null,
    "name": "file-log",
    "protocols": [
        "grpc",
        "grpcs",
        "http",
        "https"
    ],
    "enabled": true,
    "run_on": "first",
    "consumer": null,
    "route": {
        "id": "5dbafa8c-01fe-42ae-9065-c1628f5c04bc"
    },
    "tags": null
}
```

For example, the `/tmp/konghttp.log` file is not created when sending a request to the defined Route

## Cause

If you are using systemctl to start the Kong service, then the `/tmp` directory is actually under a private systemd directory in the tmp directory. For example;

```
/tmp/systemd-private-f3eb59483cee411bb225df3503bc7428-kong-enterprise-edition.service-ars6p8/tmp/konghttp.log
```

This is the standard behavior of systemd to ensure one process does not overwrite a file from a different process and to avoid any security issues with well known filenames.

## Solution

If you wish to use a non-private directory, then you will need to change the systemd configuration and specify the `PrivateTmp` parameter to disable writing to a systemd private directly. Adding a line as below in the `.service` file to disable the private directory;

```
PrivateTmp=false
```

After editing the `.service` file, make sure to run a `systemctl daemon-reload` to reload the altered systemd configuration and then restart Kong.
