---
title: "Kong Manager login fails with SSL handshake error: \"ssl3_get_record:wrong version number\""
content_type: support
description: The most common cause of this SSL error is sending HTTPS requests to an endpoint that only listens on HTTP.
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: Why does Kong Manager login fail with an SSL handshake error like "ssl3_get_record:wrong version number"?
  a: |
    This SSL error usually means Kong (or the identity provider) is sending HTTPS requests to an endpoint that only serves plain HTTP — often due to a backend misconfiguration or an incorrect port.
    In more complex cases, SRV DNS records with the wrong port can redirect Kong's connection; fix the SRV record, or set `dns_order` to prefer A records over SRV as a workaround.
related_resources: []
---

## Problem

I get an SSL error when connecting to an Identity Provider for Kong Manager access. Specifically, the error message states "wrong version number".

Example log entries seen in Kong when this happens:

```

2025/01/12 20:16:52 [crit] 40#0: *1477 SSL_do_handshake() failed (SSL: error:0A0000C6:SSL routines::packet length too long error:0A000139:SSL routines::record layer failure), client: 10.239.48.220, server: kong_admin, request: "GET /auth HTTP/1.1", host: "https://openidconnect.example.com/", referrer: "https://kongmanager.example.com/" 

2025/01/12 20:16:52 [notice] 40#0: *1477 [lua] cache.lua:258: discover(): [openid-connect] loading configuration for https://openidconnect.example.com/auth/realms/kong_management/.well-known/openid-configuration using discovery failed: handshake failed (falling back to previous configuration), client: <IPAddress>, server: kong_admin, request: "GET /auth HTTP/1.1", host: "https://openidconnect.example.com/", referrer: "https://kongmanager.example.com/"
```

## Cause

Note: on current {{site.base_gateway}} 3.14.0.0 (modern bundled OpenSSL), this exact scenario — an `https://` issuer/endpoint that actually only serves plain HTTP — is live-reproducible, but the literal OpenSSL error text has changed from the classic `ssl3_get_record:wrong version number` wording to `SSL_do_handshake() failed (SSL: error:0A0000C6:SSL routines::packet length too long error:0A000139:SSL routines::record layer failure)`, confirmed via `kong-dp`'s error log when `openid-connect`'s `issuer` points at a plaintext-HTTP listener. Older Kong/OpenSSL versions may still show the older string. Either way, the underlying cause and fix below are unchanged.

The most common cause of this SSL error is sending HTTPS requests to an endpoint that only listens on HTTP. This usually results from a misconfiguration on the backend or Kong using the wrong port number. Correcting this typically resolves the SSL error.

In more complex cases, the issue may stem from the environment serving SRV DNS records with incorrect port numbers, causing Kong to connect to a different port than originally configured.

By default, Kong prefers SRV records over A records for DNS resolution. In most environments, SRV records do not exist, so Kong uses A records and the configured port remains effective. However, if SRV records are present and incorrect, Kong may be directed to use the wrong port.

For example, if Kong is configured to use port 443 for HTTPS but the SRV record specifies port 80, Kong will send HTTPS requests to port 80, causing the SSL error.

## Solution

The solution is to correct the SRV record to specify the proper port. Since DNS records must be accurate, if SRV records are managed automatically and not maintained by your team, a workaround is to configure Kong to prefer A records over SRV records by setting the `dns_order` property. For more details, see the Kong documentation on the `dns_order` property.

1. Add `dns_order` to the Kong configuration with a value of LAST,A,CNAME,SRV for example.
2. Restart or redeploy Kong to apply the change.
