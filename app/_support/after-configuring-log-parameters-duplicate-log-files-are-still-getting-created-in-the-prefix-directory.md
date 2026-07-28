---
title: After configuring log parameters, duplicate log files are still getting created in the prefix directory
content_type: support
description: Explains why NGINX log files keep being created in the Kong prefix directory even after setting parameters like `proxy_access_log`, and which log variables are actually configurable.
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: Why do NGINX log files keep getting created in the Kong prefix directory even after I configure log parameters?
  a: |
    Parameters such as `nginx_acc_logs` and `admin_acc_logs` are not real Kong settings — they are read-only labels the Admin API shows for internal NGINX log files that Kong always writes under the prefix directory. The actual configurable directives are `proxy_access_log`, `proxy_error_log`, `admin_access_log`, `admin_error_log`, and the equivalent Admin GUI and Portal API variables — set those instead.
related_resources:
  - text: the documented parameters
    url: /gateway/configuration/
---

## Problem

After configuring the Kong logs to a directory outside the prefix directory;

```conf
proxy_access_log = /var/log/kong/access.log show_everything
proxy_error_log = /var/log/kong/error.log
admin_access_log = /var/log/kong/admin_access.log
admin_error_log = /var/log/kong/admin_error.log
admin_gui_access_log = /var/log/kong/admin_gui_access.log
admin_gui_error_log = /var/log/kong/admin_gui_error.log
portal_api_access_log = /var/log/kong/portal_api_access.log
portal_api_error_log = /var/log/kong/portal_api_error.log
```

Log files are still getting created in the prefix directory. When checking the Kong configuration, there are several log parameter values that still point to the prefix directory. Setting these parameter values to a different directory does not work and the files are still created in the prefix directory;

```conf
nginx_acc_logs=/var/logs/kong/access.log
admin_acc_logs=/var/logs/kong/admin_access.log
nginx_portal_api_acc_logs=/var/logs/kong/portal_api_access.log
nginx_err_logs=/var/logs/kong/error.log
```

## Solution

The log variables below which are seen from the output of an Admin API call to `:8001` are non-configurable NGINX log files created by default under the prefix directory;

```
nging_acc_logs == proxy_access_log
nginx_err_logs == proxy_error_log
admin_acc_logs == admin_access_log
nginx_portal_api_acc_logs == portal_api_access_log
```

Only the documented parameters can be configured.

Any parameters that are not documented and are shown on `:8001` as the node information are not configurable properties, but instead they are variables used internally in the `kong/conf_loader.lua` file.

Specifically, for this example with log files, these are NGINX log files that are necessary to compile the `nginx_conf` file. This means that they are always created under the prefix directory and the location cannot be configured.

An example where the NGINX error file is useful even if you have configured the `proxy_error_log` log variable is given below.

Let's say that you have `proxy_error_log = /kong/logs/error.log` configured in your config file `kong.conf` but don't have the `/kong/logs` directory created. If you do:

```bash
kong start -c kong.conf --v
```

Then you will get an NGINX configuration error and that error message will be put under the prefix directory in the NGINX error file. In this example, the prefix directory is `/kong/root`:

```bash
# cat /kong/root/logs/error.log
2026/10/14 19:04:53 [emerg] 343#0: open() "/kong/logs/error.log" failed (2: No such file or directory)
```

So you have configured `proxy_error_log` but you got a specific NGINX error log (prior to starting Kong proxying) stating that the `/kong/logs` directory doesn't exist. That's why the NGINX error log under the Kong prefix directory is necessary. The same logic applies for the other NGINX log files.
