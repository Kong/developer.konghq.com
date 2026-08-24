---
title: "Kong fails to start with the error \"password authentication failed for user\""
content_type: support
description: A hash mark (`#`) in a Postgres password set via `kong.conf` gets truncated as a comment, causing Kong to fail to start with a password authentication error.
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources: []
tldr:
  q: Why does Kong fail to start with a "password authentication failed for user" error?
  a: |
    A hash mark (`#`) in a `kong.conf`-configured Postgres password is treated as a comment, truncating the password. Escape it as `\#` in `kong.conf`, or set the password via the `KONG_PG_PASSWORD` environment variable instead, which isn't affected.
---

## Problem

After installing and trying to start Kong, the below error is thrown:

```

Error: /usr/local/share/lua/5.1/kong/cmd/start.lua:156: 
nginx: [error] init_by_lua error: /usr/local/share/lua/5.1/kong/init.lua:462: [PostgreSQL error] failed to retrieve PostgreSQL server_version_num: FATAL: password authentication failed for user "root"
stack traceback:
	[C]: in function 'assert'
	/usr/local/share/lua/5.1/kong/init.lua:462: in function 'init'
	init_by_lua:3: in main chunk
a:3: in main chunk

  Run with --v (verbose) or --vv (debug) for more details
waiting for db
```

You will notice the migrations jobs have run, however Kong fails to start using the same db account. A review of the Postgres logs will show a similar error

```

2025-12-15 21:00:00 UTC:10.10.100.190(26680):root@kong:[10839]:FATAL: password authentication failed for user "root"
2025-12-15 21:00:00 UTC:10.10.100.190(26680):root@kong:[10839]:DETAIL: Password does not match for user "root".
```

## Solution

The issue stems from the handling of special characters in the Postgres password. In particular, if the password contains a hash mark (#), Kong treats everything after it as a comment when parsing `kong.conf`, which truncates the password and produces this error.

This only affects password values set in the `kong.conf` file. If the password is instead supplied via the environment variable `KONG_PG_PASSWORD`, the hash mark is not interpreted as a comment and the value is passed through correctly, so no change is needed in that case.

For passwords set in `kong.conf`, rather than changing the password to remove the hash mark, escape it as `\#` in the file. This preserves the real password (including the `#` character) while preventing Kong from truncating it at parse time.
