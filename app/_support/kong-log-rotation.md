---
title: Kong Log Rotation
content_type: support
description: While there is no built in mechanism to rotate logs inside of Kong, we suggest using the Linux tool `logrotate`.
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: How do I rotate Kong's logs since there's no built-in log rotation?
  a: |
    Kong doesn't rotate logs internally, so use the Linux `logrotate` utility. Install it, add a config file such as `/etc/logrotate.d/kong` pointing at `/usr/local/kong/logs/*.log`, and set directives like `rotate`, `daily`, and `copytruncate` to control retention and rotation behavior.
related_resources: []
---

## Problem

The Kong logs (located `/usr/local/kong/logs` by default) can potentially grow rather large over time and may need to be rotated. How can this be done?

## Solution

While there is no built in mechanism to rotate logs inside of Kong, we suggest using the Linux tool `logrotate`.

Here is a guide to get started using this tool. Before suggesting this to customers, please take some time and ensure you know what you are suggesting.

- Install logrotate

- Create a Kong specific logrotate config `vim /etc/logrotate.d/kong`

```bash

/usr/local/kong/logs/*.log
{
    rotate 500000
    daily
    copytruncate
    missingok
    postrotate
    kong reload | true > /dev/null
    endscript
}
```

Config Explained:

location of the logs

{

`rotate` - the number of log files to keep

`daily` - how often to rotate

`copytruncate` - Truncate the original log file to zero size in place after creating a copy, instead of moving the old log file and optionally creating a new one.

`missingok` - If the log file is missing, go on to the next one without issuing an error message.

`postrotate`/`endscript` - The lines between postrotate and endscript (both of which must appear on lines by themselves) are executed after the log file is rotated.

If you want to manually rotate the logs, the following command can be used `logrotate -f /etc/logrotate.d/kong`
