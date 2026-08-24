---
title: "Getting \"[PostgreSQL error] failed to retrieve PostgreSQL server_version_num: the server does not support SSL connections\" error when connecting to PostgreSQL"
content_type: support
description: PostgreSQL must have SSL enabled in `postgresql.conf` before Kong can make a TLS connection to it.
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: "Why does Kong show \"the server does not support SSL connections\" when connecting to PostgreSQL over TLS?"
  a: |
    PostgreSQL rejects the TLS connection because SSL isn't enabled on the server. Set `ssl = on` in `postgresql.conf` (and configure `ssl_cert_file` / `ssl_key_file`) to allow SSL connections. If you're using a self-signed or private CA certificate, don't set `pg_ssl_verify=off` — Kong's `tls_certificate_verify` check blocks that; instead point `lua_ssl_trusted_certificate` to the CA that signed the PostgreSQL certificate.
related_resources:
  - text: PostgreSQL documentation - SSL connection settings
    url: https://www.postgresql.org/docs/12/runtime-config-connection.html#RUNTIME-CONFIG-CONNECTION-SSL
---

## Problem

When enabling Kong for TLS connections to the underlying PostgreSQL DB, you receive the following error:

```

Error: [PostgreSQL error] failed to retrieve PostgreSQL server_version_num: the server does not support SSL connections
```

## Solution

The reason for this, is that SSL needs to be enabled within PostgreSQL for this to work. To enable this, there are a number of settings you need to enable in the `postgresql.conf` file. This file is generally located under the `/var/lib/pgsql/12/data/postgresql.conf` directory. You must enable `ssl` by changing the value to `on` and also provide additional configuration for the other parameters. This includes specifying your `ssl_cert_file` and `ssl_key_file`. Full details on these parameters can be found in the PostgreSQL documentation. The list of parameters (for version 12 of PostgreSQL) is below:

```

# - SSL -

ssl = on
#ssl_ca_file = ''
#ssl_cert_file = 'server.crt'
#ssl_crl_file = ''
#ssl_key_file = 'server.key'
#ssl_ciphers = 'HIGH:MEDIUM:+3DES:!aNULL' # allowed SSL ciphers
#ssl_prefer_server_ciphers = on
#ssl_ecdh_curve = 'prime256v1'
#ssl_min_protocol_version = 'TLSv1'
#ssl_max_protocol_version = ''
#ssl_dh_params_file = ''
#ssl_passphrase_command = ''
#ssl_passphrase_command_supports_reload = off
```

Note: if you are connecting to a PostgreSQL server using a self-signed certificate or one issued by a private CA, do not attempt to work around certificate validation by setting `pg_ssl_verify=off`. This no longer disables verification: Kong now enforces a global `tls_certificate_verify` check, and setting `pg_ssl_verify=off` while it is enabled produces the error "attempt to disable certificate verification while global tls_certificate_verify option is enabled". Instead, configure `lua_ssl_trusted_certificate` to point to the CA certificate that signed the PostgreSQL server certificate, so the connection can be verified properly.
