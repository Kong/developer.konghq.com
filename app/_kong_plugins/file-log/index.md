---
title: 'File Log'
name: 'File Log'

content_type: plugin

publisher: kong-inc
description: 'Append request and response data to a log file'

products:
    - gateway

works_on:
    - on-prem
    - konnect

topologies:
  on_prem:
    - hybrid
    - db-less
    - traditional
  konnect_deployments:
    - hybrid

icon: file-log.png

categories:
  - logging

search_aliases:
  - log file
  - file-log
---

Append request and response data in JSON format to a log file. You can also specify
streams (for example, `/dev/stdout` and `/dev/stderr`), which is especially useful
when running Kong in Kubernetes.

This plugin uses blocking I/O, which could affect performance when writing
to physical files on slow (spinning) disks.

{:.important}
> **Important:** Log interleaving can occur when logging to stdout. This happens because data written through a pipe must fit within the pipe buffer, which is typically 4k as defined by the Linux kernel. If the data exceeds this size, the kernel can't guarantee the atomicity of the `write()` system call, leading to interleaved logs. 

## Log format

{% include /plugins/logging/log-format.md %}

### Log format definitions 

{% include /plugins/logging/json-object-log.md %}

## Kong process errors

{% include /plugins/logging/kong-process-errors.md %}

## Custom fields by Lua

{% include /plugins/logging/log-custom-fields-by-lua.md %}
