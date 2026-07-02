---
title: File Log plugin output mixed with {{site.base_gateway}} log entries
content_type: support
description: "When the File Lof plugin writes to /dev/stdout in a containerized environment, log entries can interleave because the Linux kernel can't guarantee atomicity for writes larger than the PIPE_BUF limit (4096 bytes)."
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: Why does the output of the File Log plugin get mixed with {{site.base_gateway}} log entries?
  a: |
    Logs interleave because the Linux kernel can't guarantee atomicity for `write()` calls larger than the `PIPE_BUF` limit (4096 bytes), and this limit can't be changed.
    Use `custom_fields_by_lua` to remove unneeded fields from the File Log output and keep entries under the limit.
related_resources:
  - text: file-log
    url: /plugins/file-log/
  - text: "`custom_fields_by_lua`"
    url: /plugins/file-log/#custom-fields-by-lua
  - text: Kong charts values.yaml
    url: https://github.com/Kong/charts/blob/kong-2.47.0/charts/kong/values.yaml#L101-L108
  - text: Pipe Atomicity
    url: https://www.gnu.org/software/libc/manual/html_node/Pipe-Atomicity.html
  - text: Limits for Files
    url: https://www.gnu.org/software/libc/manual/html_node/Limits-for-Files.html
  - text: Linux PIPE_BUF limit
    url: https://github.com/torvalds/linux/blob/v5.15/include/uapi/linux/limits.h#L14
---

When running in Kubernetes, some of {{site.base_gateway}}’s logs are directed to `/dev/stdout`.
When the File Log plugin is also configured to write to `/dev/stdout`, the output can get mixed with {{site.base_gateway}} log entries.

In containerized environments, the Docker or Kubernetes host node collects logs via a PIPE that every container outputs to `/dev/stdout`.

When writing data through a PIPE, the data must fit within the PIPE buffer, which is usually 4096 bytes.
When writing data larger than 4 KB through a PIPE, the Linux kernel can’t ensure the atomicity of the `write()` syscall.

This explains why the interleaving occurs for logs larger than 4 KB.
There’s no config setting to increase `PIPE_BUF` directly, as it’s hard-coded in the kernel.

The File Log plugin uses `write()` directly to output to a file.
This is a blocking I/O operation, which can affect performance, and there’s no locking mechanism in `/dev/stdout`.

As a workaround, we recommend removing any unneeded response headers or data from the File Log output using the `custom_fields_by_lua` field.
