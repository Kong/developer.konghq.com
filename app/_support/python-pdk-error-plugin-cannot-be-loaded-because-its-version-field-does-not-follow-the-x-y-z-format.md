---
title: "\"Plugin cannot be loaded because its VERSION field does not follow the 'x.y.z' format\" error when upgrading a Python plugin from Kong 2.x to 3.x"
content_type: support
description: When upgrading Kong from 2.x to 3.x with a custom Python plugin, Kong logs a `VERSION field does not follow the 'x.y.z' format` error and fails to start unless the Python PDK is upgraded to `kong-pdk` version `0.32` or later.
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources:
  - text: Ref
    url: /gateway/upgrade/
tldr:
  q: Why does my custom Python plugin fail to load with a "VERSION field does not follow the x.y.z format" error after upgrading to Kong 3.x?
  a: |
    Kong 3.x requires plugins to declare `Priority` and `Version` fields, and older Python PDK releases don't set `VERSION` in the plugin info table, so Kong can't validate it. Upgrade to `kong-pdk` version `0.32` or later (`pip install kong-pdk --upgrade`, or pin `kong-pdk==0.32` in `requirements.txt`).
---

## Problem

When upgrading Kong from 2.x to 3.x using a custom plugin written in Python, the below errors are logged and Kong still does not start.

```

2026/12/06 11:46:52 [error] 1#0: init_by_lua error: /usr/local/share/lua/5.1/kong/init.lua:629: error loading plugin schemas: on plugin 'py-hello': Plugin "py-hello" cannot be loaded because its VERSION field does not follow the "x.y.z" format, got: "nil".

stack traceback:
        [C]: in function 'assert'
        /usr/local/share/lua/5.1/kong/init.lua:629: in function 'init'
        init_by_lua:3: in main chunk
nginx: [error] init_by_lua error: /usr/local/share/lua/5.1/kong/init.lua:629: error loading plugin schemas: on plugin 'py-hello': Plugin "py-hello" cannot be loaded because its VERSION field does not follow the "x.y.z" format, got: "nil".
```

## Cause

This occurs when using a newer version of Kong, 3.x, with an older version of the Python PDK.

As noted in the documentation, with the upgrade to 3.x the plugin `Priority` and `Version` are required fields which results in this check. Required changes were also made to the PDK to include these details in the plugin info table.

## Solution

To address this, please ensure you are using a PDK version >= 0.32. You can check this using:

```bash
pip list | grep kong-pdk

Package        Version
-------------- -------
kong-pdk       0.27
```

And upgrade either through

```bash
pip install kong-pdk --upgrade
```

or

Create a requirements.txt to include

```
kong-pdk==0.32
```

and run

```bash
pip install -r requirements.txt
```
