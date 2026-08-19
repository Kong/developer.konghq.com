---
min_version:
  ai-gateway: '2.0'
works_on:
  - konnect
products:
  - ai-gateway
content_type: plugin
---

This AI Policy allows you to append request and response data in JSON format to a log file. You can also specify streams (for example, `/dev/stdout` and `/dev/stderr`), which is especially useful when running {{site.base_gateway}} in Kubernetes.

This AI Policy uses blocking I/O, which could affect performance when writing to physical files on slow (spinning) disks.

{:.warning}
> **Important:** Log interleaving can occur when logging to `stdout`. This happens because data written through a pipe must fit within the pipe buffer, which is typically 4k as defined by the Linux kernel. If the data exceeds this size, the kernel can't guarantee the atomicity of the `write()` system call, leading to interleaved logs. 

## Log format

{% include /md/ai-gateway/v2/policies/logging/log-format.md %}

### Log format definitions 

{% include /md/ai-gateway/v2/policies/logging/json-object-log.md %}

## Kong process errors

{% include /md/ai-gateway/v2/policies/logging/kong-process-errors.md %}

## Custom fields by Lua

{% include /md/ai-gateway/v2/policies/logging/log-custom-fields-by-lua.md 
custom_fields_by_lua='config.custom_fields_by_lua' 
custom_fields_by_lua_slug='config-custom-fields-by-lua' 
custom_fields_by_lua_name='custom_fields_by_lua' 
name=page.name 
slug=page.slug %}