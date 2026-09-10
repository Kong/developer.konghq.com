---
title: Unable to load value from vault (`env`)
content_type: support
description: Kong's `env` vault backend can fail with "could not get value from external vault (no value found)" if the environment variable name isn't uppercase, is set under a different user account, or was added without reloading Kong.
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources: []
tldr:
  q: Why does Kong return "could not get value from external vault (no value found)" when loading a secret from the `env` vault backend?
  a: |
    This happens when the referenced environment variable isn't uppercase, is set under a different user account than the one Kong runs as, or was added without reloading Kong afterward. Fix it by exporting the variable in uppercase (for example `export PASSWORD=value`), setting it for the account Kong runs under (or using `sudo -E`), and running `kong reload` after adding a new variable.
---

## Problem

When using Secrets Management and attempting to retrieve a value from the vault you receive an error similar to the below. In this example the environment variable `password` has been set.

```

Error: could not get value from external vault (no value found)
```

When running the command in debug mode

```

Error: 
/usr/local/share/lua/5.1/kong/cmd/vault.lua:108: could not get value from external vault (no value found)
stack traceback:
        [C]: in function 'get'
        /usr/local/share/lua/5.1/kong/cmd/vault.lua:108: in function 'cmd_exec'
        /usr/local/share/lua/5.1/kong/cmd/init.lua:32: in function </usr/local/share/lua/5.1/kong/cmd/init.lua:32>
        [C]: in function 'xpcall'
        /usr/local/share/lua/5.1/kong/cmd/init.lua:32: in function </usr/local/share/lua/5.1/kong/cmd/init.lua:16>
        (command line -e):5: in function 'inline_gen'
        init_worker_by_lua(nginx.conf:147):48: in function <init_worker_by_lua(nginx.conf:147):47>
        [C]: in function 'xpcall'
        init_worker_by_lua(nginx.conf:147):57: in function <init_worker_by_lua(nginx.conf:147):55>
```

I can see the environment is currently set, why can it not be referenced?

```bash

printenv | grep password
password=lowercase_kong
```

## Solution

This can occur for several reasons:

1. The environment variable name MUST be uppercase. Using a lowercase variable name will result in this error.

```bash

export PASSWORD=uppercase_kong
kong vault get env/password
uppercase_kong
unset PASSWORD

export password=kong
kong vault get env/password
Error: could not get value from external vault (no value found)

  Run with --v (verbose) or --vv (debug) for more details
```

2. The variable is inaccessible or set under another user account than the one under which Kong is running.

For example

Setting this variable on an AWS EC2 instance (under the account `ec2-user`) while Kong is running under the `root` account will produce this error.

```bash

[ec2-user@ip-10-0-66-76 ~]$ export PASSWORD=kong
```

If Kong is started with `sudo`, and you have the appropriate permissions to do so, you can preserve your existing environment variable

```bash

[ec2-user@ip-10-0-66-76 ~]$ sudo -E kong vault get env/password
kong
```

3. Kong has not been reloaded since the creation of the environment variable. Once a new variable is introduced a `kong reload` will need to be performed.
