---
title: Unable to connect to a Postgres DB using TLSv1.2 or higher
content_type: support
description: When SSL/TLS is enabled for PostgreSQL connections via `pg_ssl`, a matching `pg_ssl_version` must be set to connect to PostgreSQL server versions higher than 12.x that require a higher TLS protocol than the Kong default.
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources:
  - text: the Kong PostgreSQL datastore settings
    url: /gateway/configuration/#pg-ssl-version
tldr:
  q: Why can't Kong Gateway connect to a PostgreSQL database that requires TLSv1.2 or higher?
  a: |
    PostgreSQL server versions above 12.x may require a higher TLS protocol than Kong's default. Set `pg_ssl: on` and `pg_ssl_version: tlsv1_2` (or `tlsv1_3`) to match.

    As of Kong Gateway 3.14.0.0, `pg_ssl_version` already defaults to `tlsv1_2`, so this is only needed on older Gateway versions or when a lower value has been explicitly set.
---

## Problem

When attempting to connect Kong Gateway with a PostgreSQL database using SSL, an error is seen in the Kong logs similar to one of the below:

A.

```

Error:
/usr/local/share/lua/5.1/kong/cmd/start.lua:31: [PostgreSQL error] failed to retrieve PostgreSQL server_version_num: closed
stack traceback:
[C]: in function 'assert'
/usr/local/share/lua/5.1/kong/cmd/start.lua:31: in function 'cmd_exec'
/usr/local/share/lua/5.1/kong/cmd/init.lua:88: in function </usr/local/share/lua/5.1/kong/cmd/init.lua:88>
[C]: in function 'xpcall'
/usr/local/share/lua/5.1/kong/cmd/init.lua:88: in function </usr/local/share/lua/5.1/kong/cmd/init.lua:45>
/usr/local/bin/kong:9: in function 'file_gen'
init_worker_by_lua:49: in function <init_worker_by_lua:47>
[C]: in function 'xpcall'
init_worker_by_lua:56: in function <init_worker_by_lua:54>
```

B.

```

Error: [PostgreSQL error] failed to retrieve PostgreSQL server_version_num: FATAL: TLS version used does not meet minimal requirements for this server. Please use a higher TLS version and retry.
```

C.

```

Error: [PostgreSQL error] failed to retrieve PostgreSQL server_version_num: tlsv1 alert protocol version
```

Additionally, the Postgres log may show the entry below:

```

2026-09-07 04:18:57.729 CDT [38122] LOG: could not accept SSL connection: unknown protocol
```

## Solution

When SSL/TLS is enabled in Kong for PostgreSQL connections via the `pg_ssl` setting, a TLS version must be specified too when connecting to newer PostgreSQL database server versions which require a higher TLS protocol than the Kong default. This affects connections to PostgreSQL server versions higher than 12.x.

**This applies to older Kong Gateway versions.** As of Kong Gateway 3.14.0.0, `pg_ssl_version` already defaults to `tlsv1_2` (confirmed via `GET /` on the Admin API: `.configuration.pg_ssl_version` is `"tlsv1_2"` on a stock install with no explicit configuration), and `tlsv1`/`tlsv1_1` are no longer accepted values at all — only `tlsv1_2`, `tlsv1_3`, and `any` are valid. This means that on current Kong Gateway, connecting to a PostgreSQL server that requires TLSv1.2 works out of the box with `pg_ssl: on` and no `pg_ssl_version` override; you'll only see the errors above on 3.14.0.0 if `pg_ssl_version` has been explicitly set to an unsupported low value (which will now fail Kong's own config validation at startup, rather than failing the TLS handshake against PostgreSQL), or if the PostgreSQL server requires TLSv1.3.

To accommodate TLSv1.2 (already the default on current Kong Gateway; only needed if it's been explicitly overridden to something lower, or on an older Kong version):

```conf

  pg_ssl: on
  pg_ssl_version: tlsv1_2
```

To accommodate TLSv1.3, you will still need to explicitly change the setting for `pg_ssl_version`:

```conf

  pg_ssl: on
  pg_ssl_version: tlsv1_3
```

More details on the Kong PostgreSQL datastore settings can be found here.
