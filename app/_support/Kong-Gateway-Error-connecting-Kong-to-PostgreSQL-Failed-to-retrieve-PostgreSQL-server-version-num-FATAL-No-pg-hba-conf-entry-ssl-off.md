---
title: "Kong Gateway: Error connecting Kong to PostgreSQL: \"Failed to retrieve PostgreSQL server_version_num: FATAL: No pg_hba.conf entry\" & \"ssl off\" or \"no encryption\""
content_type: support
description: This error occurs when Kong connects to the PostgreSQL DB server without SSL, but the server requires SSL connections.
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources: []
---

## Problem

We see this error when trying to connect Kong to our PostgreSQL database (DB) server.

```
Error: [PostgreSQL error] failed to retrieve PostgreSQL server_version_num: FATAL: no pg_hba.conf entry for host "<IP/Hostname>", user "<user>", database "kong", SSL off
```

Another variation of the error will look like this:

```
Error: [PostgreSQL error] failed to retrieve PostgreSQL server_version_num: FATAL: no pg_hba.conf entry for host "<IP/Hostname>", user "<user>", database "kong", no encryption"
```

## Cause

This error occurs when Kong connects to the PostgreSQL DB server without SSL, but the server requires SSL connections.

## Solution

To resolve this, consider the following options:

1. Recommended: Configure Kong to connect to the PostgreSQL DB server using SSL. The PostgreSQL configuration properties are documented in the documentation on PostgreSQL settings.

   Set the `pg_ssl` property to `on`, and if needed, set `pg_ssl_version` to `tlsv1_2` or the version required by your PostgreSQL server. Consult the documentation for detailed setup instructions.

2. Disable the SSL-only requirement on the PostgreSQL server to allow non-SSL connections.

   Warning: This reduces security and is discouraged.
