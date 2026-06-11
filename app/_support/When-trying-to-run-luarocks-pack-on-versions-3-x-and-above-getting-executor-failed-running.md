---
title: "luarocks pack fails with \"executor failed running\" on Kong 3.x and above"
content_type: support
description: Running luarocks pack on Kong 3.x and above fails with "executor failed running"; install zip in the Dockerfile to resolve it.
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: "When trying to run luarocks pack on versions 3.x and above getting \"executor failed running\""
related_resources: []
---

## Problem

When installing custom plugins using luarocks after upgrading to 3.x, the `luarocks pack` command fails with the following error.

```
executor failed running [/bin/sh -c luarocks pack kong-plugin-myplugin 0.1.0-1 --verbose]: exit code: 1
```

## Solution

First, verify the error in verbose mode. For example, inside a Dockerfile add the following:

```dockerfile
RUN luarocks pack kong-plugin-myplugin 0.1.0-1 --verbose
```

In the logs the last message will show:

```
#11 0.721 fs.is_tool_available("zip", "zip")
#11 0.721 fs.search_in_path("zip")
#11 0.721 fs.change_dir_to_root()
```

This indicates `zip` needs to be installed to properly handle the files. Inside the Dockerfile add the following line:

```dockerfile
RUN yum install zip -y
```

Now rerun the Dockerfile and the `luarocks pack` command will succeed.
