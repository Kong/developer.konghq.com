---
title: "`[ssl] failed to fetch SNI: failed to fetch '<IPAddress>' SNI: [postgres/cassandra] must not be an IP` error logged on older Kong Gateway versions"
content_type: support
description: This error happens if a request reached the Kong https proxy listener port with the Server Name Indication (SNI) information in the client request set to an IP instead of a host name.
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: "Why am I getting an error: [ssl] failed to fetch SNI: failed to fetch '<IPAddress>' SNI: [postgres/cassandra] must not be an IP"
  a: |
    This log entry appears when a client's TLS handshake sets the SNI to an IP address instead of a host name, which SSL certificates aren't associated with. It's unrelated to the actual Postgres or Cassandra connection despite the misleading tag, and has no functional impact. On current Kong Gateway versions the same condition logs at `DEBUG` level instead of `ERROR` and falls back to the default SSL certificate, so upgrading Kong Gateway removes the noisy log entry.
related_resources: []
---

## Problem

On older Kong Gateway versions, we would intermittently see the following type of error when using a postgres database:

```

2026/09/07 15:03:18 [error] 26680#0: *100925 [lua] certificate.lua:22: log(): [ssl] failed to fetch SNI: failed to fetch '10.10.1.2' SNI: [postgres] must not be an IP, context: ssl_certificate_by_lua*, client: 10.11.2.34, server: 0.0.0.0:8443
```

When using Cassandra the following error occurred:

```

2026/09/07 15:03:18 [error] 26680#0: *100925 [lua] certificate.lua:22: log(): [ssl] failed to fetch SNI: failed to fetch '10.10.1.2' SNI: [cassandra] must not be an IP, context: ssl_certificate_by_lua*, client: 10.11.2.34, server: 0.0.0.0:8443
```

Even after defining `pg_host`, `KONG_PG_HOST` or `cassandra_contact_points`, `KONG_CASSANDRA_CONTACT_POINTS` config values as host names, these log entries continued to appear intermittently. There does not appear to be any functional issue.

## Solution

This log entry is produced if a request reaches the Kong https proxy listener port with the Server Name Indication (SNI) information in the client request set to an IP instead of a host name.

`server: 0.0.0.0:8443` in the sample entry refers to the SSL `proxy_listen` port so will be whatever you have configured for that. `SNI: failed to fetch '10.10.1.2'` in the sample entry shows what IP the SNI had been set to by a client. In the sample case this is an internal IP but this has also been seen with external IPs, which would indicate that clients managed to connect via an IP, setting the SNI to that IP.

Normally, clients should not send SNI as an IP because SSL certificates are associated with a host or domain name rather than an IP, and sending SNI information with the ssl handshake request allows the server, i.e. Kong in this case, to present the correct certificate to the client if multiple certificates are available.

On current Kong Gateway versions, sending SNI as an IP no longer produces an ERROR-level log entry, and the TLS handshake is not rejected. Kong instead logs a DEBUG-level message and gracefully falls back to serving the listener's default/fallback SSL certificate:

```

2026/08/27 07:06:39 [debug] 2914#0: *2207 [kong] certificate.lua:366 invalid SNI '10.10.1.2', must not be an IP, serving default SSL certificate
```

An easy way to reproduce this is by using `openssl`, and setting the `-servername` parameter to an IP:

```bash

openssl s_client -connect <IPAddressToReachGate>:<sslPort> -servername <anyIpAddress>
```

The handshake itself still completes successfully (a certificate is returned to the client) — only the DEBUG-level log line above is produced; there is no client-visible impact.

The fact that the older, ERROR-level log entry included postgres or cassandra depending on which database you use with Kong has nothing to do with connections of Kong to the database. The underlying SNI-must-not-be-an-IP validation is part of Kong's db subsystem code:

`kong/db/schema/typedefs.lua`

Older Kong Gateway versions had a general setting that added the db strategy to all log entries in that code subsystem, which is why the tag showed up in this particular message. On current Kong Gateway versions the logging/caller code for this check has moved to `kong/runloop/certificate.lua`, and no longer carries the confusing db-strategy tag or the ERROR severity — if you are seeing the old tagged, ERROR-level form of this message, upgrading Kong Gateway resolves it.
