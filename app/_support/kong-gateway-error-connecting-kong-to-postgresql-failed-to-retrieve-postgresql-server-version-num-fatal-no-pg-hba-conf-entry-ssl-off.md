---
title: "Error connecting {{site.base_gateway}} to PostgreSQL"
content_type: support
description: This error occurs when Kong connects to the PostgreSQL DB server without SSL, but the server requires SSL connections.
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: "Why do I get `Failed to retrieve PostgreSQL server_version_num: FATAL: no pg_hba.conf entry` with \"SSL off\" or \"no encryption\" when connecting Kong to PostgreSQL?"
  a: |
    {{site.base_gateway}} is connecting without SSL, but the PostgreSQL server requires it.
    Set `pg_ssl` to `on` (and `pg_ssl_version` if needed) to connect with SSL.
related_resources:
  - text: "`pg_ssl_version`"
    url: /gateway/configuration/#pg-ssl-version
  - text: "`pg_ssl`"
    url: /gateway/configuration/#pg-ssl
---

## Problem

You see this error when trying to connect {{site.base_gateway}} to your PostgreSQL database (DB) server:

```text
Error: [PostgreSQL error] failed to retrieve PostgreSQL server_version_num: FATAL: no pg_hba.conf entry for host "<IP/Hostname>", user "<user>", database "kong", SSL off
```
{:.no-copy-code}

Another variation of the error looks like this:

```text
Error: [PostgreSQL error] failed to retrieve PostgreSQL server_version_num: FATAL: no pg_hba.conf entry for host "<IP/Hostname>", user "<user>", database "kong", no encryption"
```
{:.no-copy-code}

## Cause

This error occurs when {{site.base_gateway}} connects to the PostgreSQL DB server without SSL, but the server requires SSL connections.

## Solution

To resolve this error, consider the following options:

* We recommend configuring {{site.base_gateway}} to connect to the PostgreSQL DB server using SSL. The PostgreSQL configuration properties are documented in the documentation on PostgreSQL settings.

   Set the [`pg_ssl`](/gateway/configuration/#pg-ssl) property to `on`, and if needed, set [`pg_ssl_version`](/gateway/configuration/#pg-ssl-version) to `tlsv1_2` or the version required by your PostgreSQL server.

* Disable the SSL-only requirement on the PostgreSQL server to allow non-SSL connections.

   {:.warning}
   > **Warning:** Disabling the SSL-only requirement reduces security. We do not recommend this option.
