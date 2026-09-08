---
title: Setting LDAPS (LDAP over SSL) for LDAP authentication in Kong Manager
content_type: support
description: Kong Manager's LDAP authentication can be configured for LDAPS (LDAP over SSL) using a few extra `admin_gui_auth_conf` settings, either in the configuration file or via environment variables.
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: How can I set LDAPS (LDAP over SSL) for LDAP authentication for Kong Manager?
  a: |
    Enable LDAPS for Kong Manager by setting `ldap_port: 636`, `ldaps: true`, and `verify_ldap_host: false` in your `admin_gui_auth_conf` config (config file or the equivalent environment variables). To verify the LDAP host instead of disabling verification, set `verify_ldap_host: true` and add its CA certificate via `lua_ssl_trusted_certificate`. Note: since Kong Gateway 3.14.0.0, `tls_certificate_verify` defaults to `on`, which blocks `ldaps`/`start_tls` with `verify_ldap_host: false` on the standalone `ldap-auth-advanced` plugin (Admin API) — but this does not affect the `admin_gui_auth_conf` setup for Kong Manager shown here.
related_resources: []
---

## Overview

Kong Doc has an example of how to set LDAP authentication for Kong Manager. 

Can I have an example to use LDAPS?

## Steps

For LDAPS, we should check the following settings either in the configuration file or using environment variables.

1. `"ldap_port":636`

2. `"ldaps":true`

3. `"verify_ldap_host": false`

As of Kong Gateway 3.14.0.0, the global `tls_certificate_verify` setting now defaults to `on`. This adds a new restriction to the standalone `ldap-auth-advanced` plugin (used on Routes/Services via the Admin API): configuring the plugin directly with `ldaps: true` (or `start_tls: true`) and `verify_ldap_host: false` is now rejected with `400 schema violation ("tls_certificate_verify option is enabled, verify_ldap_host cannot be disabled when ldaps or start_tls is enabled")`. This particular restriction is enforced only on that Admin API entity-validation path; live-confirmed it does NOT block the equivalent `admin_gui_auth_conf` (Kong Manager LDAPS) configuration below, which starts and runs fine with `verify_ldap_host: false`. If you do want to verify the LDAP host (`"verify_ldap_host": true`), make sure you add its CA certificate to `lua_ssl_trusted_certificate`.

- Add, a CA certificate of the LDAP certificate `lua_ssl_trusted_certificate`

`lua_ssl_trusted_certificate = /etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem`

lua_ssl_trusted_certificate

Below is an example that gets configured inside the `admin_gui_auth_conf` variable on your configuration file or using environment variables.

```json

{
   "anonymous":"",
   "attribute":"sAMAccountName",
   "bind_dn":"CN=Kong LDAP Service,OU=Domain Users,DC=us,DC=kong,DC=local",
   "base_dn":"OU=Domain Users,DC=us,DC=kong,DC=local",
   "cache_ttl":2,
   "header_type":"Basic",
   "keepalive":60000,
   "ldap_host":"ldap.us.kong.local",
   "ldap_password":"********",
   "start_tls":false,
   "timeout":10000,
   "verify_ldap_host":false,
   "ldap_port":636,
   "ldaps":true
}
```
