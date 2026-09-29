---
title: "\"[file-log] failed to open the file: Permission denied\" error when logging to /dev/stdout as a non-root user"
content_type: support
description: "Explains why the file-log plugin returns a Permission denied error when logging to `/dev/stdout`, and how to fix it by keeping the container running as the `kong` user instead of root."
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources:
  - text: file-log plugin documentation
    url: /plugins/file-log/
tldr:
  q: Why does the file-log plugin return a "Permission denied" error when logging to /dev/stdout?
  a: |
    `/dev/stdout` is owned by the `kong` user with `700` permissions, so a {{site.base_gateway}} process running as root can't write to it. This typically happens when a Dockerfile switches to `USER root` for setup steps and never switches back. Add `USER kong` back to the Dockerfile before Kong starts, rebuild the image, and redeploy.
---

## Problem

We are trying to deploy the file-log plugin with the path defined as `/dev/stdout`. However, we are running into the following error:

```

[file-log] failed to open the file: Permission denied while logging request
```

When checking the permissions we don't see anything that is lacking.

```bash
ls -al /dev/stdout
lrwxrwxrwx 1 root root 15 Mar 13 13:22 /dev/stdout -> /proc/self/fd/1
```

The file-log plugin documentation shows that logging to `/dev/stdout` is supported, but running the plugin this way produces a permissions error.

## Solution

It is possible to configure the file-log plugin to `/dev/stdout`. The issue here is that the worker permissions are locked down.

`/dev/stdout` is owned by kong with 700 permissions so root cannot write to that dir.

This will happen if the user is switched to root in a Dockerfile. The way to resolve this is by changing the user back to kong. In your Dockerfile we need to add the following:

```dockerfile
USER kong
```

After this we need to re-create the image and then re-deploy kong with the updated image.

Rerun the file-log plugin now, and the issue will be resolved.
