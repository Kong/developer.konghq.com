---
title: RBAC authentication problems after setting up Group Mapping for Kong Manager
content_type: support
description: When using RBAC Token authorization, Service Directory Mapping to Kong Roles does not take effect.
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources: []
tldr:
  q: Why doesn't Service Directory Group Mapping take effect when I authenticate to the Admin API with an RBAC token?
  a: |
    RBAC token authorization doesn't apply Service Directory Group Mapping to Kong Roles — that mapping only takes effect for Kong Manager's browser session. To get the same mapped permissions for CLI or Admin API access, authenticate the way Kong Manager does: send a request to `/auth` with your Service Directory credentials to obtain a session cookie, then reuse that cookie (or its `Set-Cookie` value) on subsequent Admin API requests instead of an RBAC token.
---

## Problem

After using Service Directory Group Mapping, access to Kong Manager works well. However, when using the Admin API with an RBAC token, the requests fail with a permissions error.

## Cause

When using RBAC Token authorization, Service Directory Mapping to Kong Roles does not take effect.

## Solution

If you need to use CLI access with your Service Directory mapping, you should use the same authentication mechanism that Kong Manager uses to secure browser sessions i.e. session cookies.

1. Send an authentication request and save the cookie to a temporary file;

   ```bash
   curl -c /tmp/cookie https://kong-api:8444/auth \
   -H 'Kong-Admin-User: <LDAP_USERNAME>' \
   --user <LDAP_USERNAME>:<LDAP_PASSWORD>
   ```

2. When calling the Admin API, send the saved cookie in the request. In this command, we are both reading the auth cookie and sending this with the request (`-b`) and writing any additional cookies to the same file (`-c`);

   ```bash
   curl -b /tmp/cookie -c /tmp/cookie https://kong-api:8444/routes \
   -H 'Kong-Admin-User: <LDAP_USERNAME>'
   ```

Alternatively, if you do not wish to save the cookie to a file then it is also possible to retrieve the cookie value from the auth call response and manually send this value as a Cookie header in subsequent requests.

1. Send the curl request with the `-v` option;

   ```bash
   curl -v https://kong-api:8444/auth -H 'Kong-Admin-User: super' --user super:password
   *   Trying 10.0.10.1...
   * TCP_NODELAY set
   * Connected to kong-api (10.0.10.1) port 8444 (#0)
   * Server auth using Basic with user 'super'
   > GET /auth HTTP/1.1
   > Host: kong-api:8444
   > Authorization: Basic c3VwZXI6cGFzc3dvcmQ=
   > User-Agent: curl/7.64.1
   > Accept: */*
   > Kong-Admin-User: super
   >
   < HTTP/1.1 200 OK
   < Date: Mon, 28 Sep 2026 10:21:28 GMT
   < Content-Type: application/json
   < Connection: keep-alive
   < X-Kong-Admin-Request-ID: qYv3AcNHt3nXMPju6Zx3M1383RWyb47Q
   < Vary: Origin
   < Access-Control-Allow-Origin: https://kong-manager:8445
   < Access-Control-Allow-Credentials: true
   < Set-Cookie: manager_session=u8TaYNqYyY3zTr0kM3GrjA|1601324488|JOM6NIauJTsfk-8XDoPzclBn1kk; Path=/; SameSite=Strict; Secure; HttpOnly
   < Server: kong/3.14.0.0-enterprise-edition
   < Content-Length: 0
   < X-Kong-Admin-Latency: 25
   <
   * Connection #0 to host kong-api left intact
   * Closing connection 0
   ```

2. Use the value from the Set-Cookie header in subsequent Admin API requests by manually setting the Cookie header. Your cookie may have a different name than `manager_session`, depending on the values you have configured for the `admin_gui_session_conf` parameter;

   ```bash
   curl -v https://kong-api:8444/routes -H 'Kong-Admin-User: super' -H 'Cookie: manager_session=Woay6aeFfJxaIvsSZpPOog|1601324325|edXfraWkf58GYZ5EGB0vvnQ_sk0; Path=/; SameSite=Strict; Secure; HttpOnly'
   *   Trying 10.0.10.1...
   * TCP_NODELAY set
   * Connected to kong-api (10.0.10.1) port 8444 (#0)
   > GET /routes HTTP/1.1
   > Host: kong-api:8444
   > User-Agent: curl/7.64.1
   > Accept: */*
   > Kong-Admin-User: super
   > Cookie: manager_session=Woay6aeFfJxaIvsSZpPOog|1601324325|edXfraWkf58GYZ5EGB0vvnQ_sk0; Path=/; SameSite=Strict; Secure; HttpOnly
   >
   < HTTP/1.1 200 OK
   < Date: Mon, 28 Sep 2026 10:24:49 GMT
   < Content-Type: application/json; charset=utf-8
   < Connection: keep-alive
   < X-Kong-Admin-Request-ID: SVWgHCI4DIDeiTrxNZUzi5o5JA8xcTTa
   < Vary: Origin
   < Access-Control-Allow-Origin: https://kong-manager:8445
   < Access-Control-Allow-Credentials: true
   < Server: kong/3.14.0.0-enterprise-edition
   < Content-Length: 470
   < X-Kong-Admin-Latency: 19
   <
   * Connection #0 to host kong-api left intact
   {"next":null,"data":[{"id":"9aa40cbf-1a45-444c-bee2-3f444ed64d90","tags":null,"paths":["\/default\/httpbin"],"destinations":null,"headers":null,"protocols":["http","https"],"created_at":1596786936,"snis":null,"hosts":null,"name":"local-httpbin","strip_path":true,"updated_at":1596786936,"preserve_host":false,"regex_priority":0,"service":{"id":"45342f46-59e9-4ab7-94d0-ff2a2f4556f4"},"sources":null,"methods":null,"https_redirect_status_code":426,"path_handling":"v0"}]}* Closing connection 0
   ```

Note, if you do not see the expected cookie values being saved/sent in the above commands, make sure that you are using the correct protocol for the requests. If you have `cookie_secure:true` in the `admin_gui_session_conf` configuration, then you will need to use https (port: 8444). Likewise, if you have `cookie_secure:false` in the `admin_gui_session_conf` configuration, then you will need to use http (port: 8001).
