---
title: "`luarocks pack` fails with \"executor failed running\" on Kong 3.x and above"
content_type: support
description: "Running `luarocks pack` on Kong 3.x and above fails with \"executor failed running\"; install `zip` in the Dockerfile to resolve it."
products:
  - gateway
works_on:
  - on-prem
  - konnect
published: false
tldr:
  q: "Why does `luarocks pack` fail with \"executor failed running\" on {{site.base_gateway}} 3.x?"
  a: |
    `zip` is not installed. Add `RUN yum install zip -y` to your Dockerfile and rerun.
related_resources: []
---

## Problem

When installing custom plugins using `luarocks` after upgrading to 3.x, the `luarocks pack` command fails with the following error:

```
executor failed running [/bin/sh -c luarocks pack kong-plugin-myplugin 0.1.0-1 --verbose]: exit code: 1
```
{:.no-copy-code}

## Solution

First, verify the error in verbose mode. For example, add the following to a Dockerfile:

```dockerfile
RUN luarocks pack kong-plugin-myplugin 0.1.0-1 --verbose
```

In the logs, the last message will show:

```
#11 0.721 fs.is_tool_available("zip", "zip")
#11 0.721 fs.search_in_path("zip")
#11 0.721 fs.change_dir_to_root()
```
{:.no-copy-code}

This indicates `zip` needs to be installed to properly handle the files. 
Add the following line to the Dockerfile

```dockerfile
RUN yum install zip -y
```

Rerun the Dockerfile and the `luarocks pack` command will succeed.
