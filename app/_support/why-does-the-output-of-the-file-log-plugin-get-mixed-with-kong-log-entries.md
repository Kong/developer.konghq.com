---
title: File-log plugin output mixed with Kong log entries
content_type: support
description: In containerized environments, the Docker or Kubernetes host node collects logs via a PIPE that every container outputs to /dev/stdout.
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: Why does the output of the file-log plugin get mixed with Kong log entries?
  a: |
    In containerized environments, the host node collects logs via a PIPE that every container outputs to
    `/dev/stdout`. When writing data larger than the PIPE buffer (usually 4096 bytes), the Linux kernel can't
    ensure the atomicity of the `write()` syscall, which explains the interleaving for logs bigger than 4kB.
    The `PIPE_BUF` limit is hard-coded in the kernel and can't be increased via config. As a workaround,
    remove any unneeded response headers or data from the file-log output using the `custom_fields_by_lua` field.
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

## Why does the output of the file-log plugin get mixed with Kong log entries?

When running in Kubernetes, some of Kong's logs are directed to `/dev/stdout`.

If we also use a file-log plugin to write to `/dev/stdout`, why does the output of the file-log plugin get mixed with Kong log entries?

In containerized environments, the Docker or Kubernetes host node collects logs via a PIPE that every container outputs to `/dev/stdout`.

When writing data through a PIPE, the size of the data has to fit into a PIPE buffer, which is usually 4096 Bytes. In other words, when writing data larger than 4kB through a PIPE, the Linux kernel can’t ensure the atomicity of the syscall `write()`.

This could explain why the interleaving occurs for logs whose size is bigger than 4kB. Unfortunately, there’s no config setting to increase the `PIPE_BUF` directly as it is hard-coded in the kernel.

The file-log plugin uses `write()` directly to output to a file. This is already a blocking I/O operation, which could affect performance, and there is no locking mechanism in `/dev/stdout`.

As a workaround, we recommend removing any unneeded response headers or any data that isn't required from the file-log by using the `custom_fields_by_lua` field.
