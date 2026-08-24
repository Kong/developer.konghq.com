---
title: "Postgres logs \"could not receive data from client: Connection reset by peer\" when TLS is enabled"
content_type: support
description: "Why Postgres logs a `could not receive data from client: Connection reset by peer` message after TLS is enabled, and why it's expected behavior."
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources:
  - text: Postgres documentation on log_disconnections
    url: https://postgresqlco.nf/doc/en/param/log_disconnections/
tldr:
  q: "Why does Postgres log \"could not receive data from client: Connection reset by peer\" when TLS is enabled?"
  a: |
    This is expected behavior. Kong's Postgres connection pool releases idle connections after `pg_keepalive_timeout` (60 seconds by default), and closing a TLS connection sends an RST packet that Postgres logs as a reset connection. To reduce log noise, raise `pg_keepalive_timeout` or disable Postgres connection logging (`log_disconnections`).
---

## Problem

When enabling TLS connections for Postgres as documented here Configuring PostgreSQL TLS, the DB container logs:

`LOG: could not receive data from client: Connection reset by peer`

There's no impact about this log, however, you may want to understand why this is repeatedly logged.

This is an expected normal behavior. The reason why it happens is because Kong maintains a connection pool with Postgres, and the default timeout is 60 seconds, which is controlled by the `pg_keepalive_timeout` parameter. When a connection in the pool times out, it will be released. If TLS is enabled on that connection, the underlying Nginx that Kong depends on will send an RST packet to quickly close TLS when closing the connection. The RST packet caused Postgres to detect that Kong reset the connection and therefore output a log.

## Solution

You can also adjust the `pg_keepalive_timeout` to a very large value, such as 500 seconds, to suppress the disconnection errors overrunning your logging systems, but it is not necessary from Kong's side. Alternatively, you can disable the connection logs in Postgres (which is off by default) according to the Postgres documentation on `log_disconnections`.

### Related documentation:

- Kong Configuration Reference: Postgres Settings
