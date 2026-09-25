---
title: When using helm to install Kong the IP Restriction plugin does not work
content_type: support
description: "The IP Restriction plugin uses the wrong client IP when `real_ip_recursive` is set as an unquoted boolean instead of a quoted string in the Helm values."
products:
  - kic
works_on:
  - on-prem
  - konnect
tldr:
  q: Why does the IP Restriction plugin not work when Kong is installed via Helm?
  a: |
    The Helm chart's `real_ip_recursive` parameter must be set as a quoted string (`"on"`), because an unquoted value is parsed as a YAML boolean and Kong treats that as invalid. Depending on the Kong version, this either prevents Kong from starting (`nginx: [emerg] invalid value "true" in "real_ip_recursive" directive`) or is silently ignored, leaving the IP Restriction plugin using the wrong client IP.
related_resources: []
---

## Problem

When using the helm chart to install Kong, the `real_ip_recursive` parameter is not being set correctly which causes the IP restriction plugin to use the wrong IP address for limiting requests.

## Solution

Make sure to set the `real_ip_recursive` parameter value as a quoted string:

```
real_ip_recursive "on"
```

If you do not use quotes, then the parameter value is interpreted as a boolean value following the YAML standard where the following unquoted tokens are parsed as booleans: `y|Y|yes|Yes|YES|n|N|no|No|NO|true|True|TRUE|false|False|FALSE|on|On|ON|off|Off|OFF`

With an unquoted value the `real_ip_recursive` parameter is being set to `true` which is an invalid value.

This behavior has improved in later versions (2.x) where you will see an error like this:

```
Error: could not prepare Kong prefix at /kong_prefix: nginx configuration is invalid (exit code 1): nginx: [emerg] invalid value "true" in "real_ip_recursive" directive, it must be "on" or "off" in /kong_prefix/nginx-kong.conf:57 nginx: configuration file /kong_prefix/nginx.conf test failed
```

and Kong will not start. In 1.5, the error is silently ignored and Kong will start but the `real_ip_recursive` parameter will not be set as expected.
