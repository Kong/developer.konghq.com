---
title: How to allow anonymous access to a route using the OIDC plugin
content_type: support
description: Configure the OpenID Connect plugin's anonymous consumer so that requests without a valid token fall through to an anonymous consumer instead of being rejected.
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: How do I allow anonymous access to a route that has the OIDC plugin applied?
  a: |
    Create a consumer to represent anonymous access, then set the OpenID Connect plugin's `config.anonymous` to that consumer's ID.
    Requests with a valid token authenticate as the real consumer; requests without one fall through to the anonymous consumer instead of being rejected. This works whether the plugin is applied at the service or route level.
related_resources: []
---

## Overview

How to enable anonymous access to a route when an OIDC plugin is installed at the service level or the route level

## Steps

Here's an example of a service with a route that allows access for an anonymous consumer.

We have a service that’s configured like so:

```
❯ curl -k -H "Kong-Admin-Token:password" https://api.kong.lan/services/e399a95c-5a02-4594-814e-8d364167903e | jq 'with_entries(select(.value != null))'
{
  "created_at": 1680192808,
  "id": "e399a95c-5a02-4594-814e-8d364167903e",
  "retries": 5,
  "write_timeout": 60000,
  "name": "local-echo-server",
  "connect_timeout": 60000,
  "read_timeout": 60000,
  "updated_at": 1680192808,
  "protocol": "http",
  "host": "echo-server",
  "port": 8080,
  "enabled": true
}
```

and this route:

```
❯ curl -k -H "Kong-Admin-Token:password" https://api.kong.lan/services/e399a95c-5a02-4594-814e-8d364167903e/routes/auth-oidc | jq 'with_entries(select(.value != null))'
{
  "created_at": 1680192808,
  "paths": [
    "/auth/oidc"
  ],
  "https_redirect_status_code": 426,
  "regex_priority": 0,
  "name": "auth-oidc",
  "path_handling": "v0",
  "request_buffering": true,
  "response_buffering": true,
  "service": {
    "id": "e399a95c-5a02-4594-814e-8d364167903e"
  },
  "strip_path": true,
  "preserve_host": false,
  "id": "4625ebe0-8287-44a2-8cc0-27a182e5a06d",
  "protocols": [
    "http",
    "https"
  ],
  "updated_at": 1680192808
}
```

An “anonymous” consumer has also been configured and looks like this:

```
❯ curl -k -H "Kong-Admin-Token:password" https://api.kong.lan/consumers/anonymous | jq 'with_entries(select(.value != null))'
{
  "created_at": 1680192808,
  "id": "b4d6a39a-5dc6-4ce8-b85a-fee580b5513b",
  "type": 0,
  "username": "anonymous",
  "username_lower": "anonymous"
}
```

and that the oidc-config

```
"created_at": 1680192883,
  "id": "d7f831f7-0323-49f3-8f87-1a55a127bca0",
  "name": "openid-connect",
  "service": {
    "id": "e399a95c-5a02-4594-814e-8d364167903e"
  },
 ...
  "enabled": true,
  "config": {
   ...
    "introspection_check_active": true,
    "login_methods": [
      "authorization_code"
    ],
    "session_strategy": "default",
    "session_memcache_prefix": "sessions",
    "cache_token_exchange": true,
    "session_compressor": "none",
    "preserve_query_args": false,
    "authorization_cookie_samesite": "off",
    "forbidden_error_message": "Forbidden",
    "unauthorized_error_message": "Unauthorized",
    "userinfo_accept": "application/json",
    "upstream_access_token_header": "authorization:bearer",
    "authorization_cookie_httponly": true,
    "authorization_cookie_path": "/",
    "authorization_cookie_lifetime": 600,
    "authorization_cookie_name": "authorization",
    "credential_claim": [
      "sub"
    ],
    "issuer": "http://keycloak.kong.lan:8080/auth/realms/kong",
    "refresh_token_param_type": [
      "header",
      "query",
      "body"
   ...
    "forbidden_destroy_session": true,
    "session_redis_ssl_verify": false,
    "logout_revoke_access_token": true,
    "logout_revoke_refresh_token": true,
    "logout_revoke": false,
    "cache_tokens_salt": "rDrzmZtubsQt6ZRTWldsi8Y01FCNfiIJ",
    "login_redirect_mode": "fragment",
    "session_cookie_maxsize": 4000,
    "session_cookie_httponly": true,
    "session_cookie_path": "/",
  ...
    ],
    "session_cookie_lifetime": 3600,
    "scopes_claim": [
      "scope"
    ],
    "verify_nonce": true,
    "response_mode": "query",
    "resolve_distributed_claims": false,
    "enable_hs_signatures": false,
    "session_cookie_name": "session",
    "cache_ttl": 3600,
    "groups_claim": [
      "groups"
    ],
    "scopes_required": [
      "profile",
      "email",
      "nope-scope"
    ],
    "rediscovery_lifetime": 30,
    "audience_claim": [
      "aud"
    ],
  ...
    "scopes": [
      "openid"
    ],
    "session_redis_prefix": "sessions",
    "auth_methods": [
      "bearer"
    ],
    "introspection_accept": "application/json",
    "session_memcache_host": "127.0.0.1",
    "cache_introspection": true,
    "refresh_tokens": true,
    "anonymous": "b4d6a39a-5dc6-4ce8-b85a-fee580b5513b",
    "run_on_preflight": true,
    "consumer_by": [
      "username",
      "custom_id"
    ],
    "verify_claims": true,
    "verify_parameters": false,
    "consumer_claim": [
      "email"
    ],
    "consumer_claims": [
      ["email"]
    ],
...
  }
}
```

includes:

```
"config": {
...
...
  "anonymous": "b4d6a39a-5dc6-4ce8-b85a-fee580b5513b",
...
 }
```

If we access the route with the correct token, the echo service would return an output that looks like this:

```
> curl -H "Authorization: Bearer $TOKEN" http://proxy.kong.lan/auth/oidc

Request served by 97f243d248ea

HTTP/1.1 GET /

Host: echo-server:8080
Connection: keep-alive
X-Forwarded-Path: /auth/oidc
Accept: */*
Authorization: Bearer XXX
X-Consumer-Custom-Id: stu+keycloak_user@konghq.com
X-Consumer-Username: oidc-consumer
X-Consumer-Id: accb0537-af5f-4d29-8948-e78eaf0e677f
X-Forwarded-For: 172.28.0.1, 172.28.0.16
X-Forwarded-Prefix: /auth/oidc
X-Real-Ip: 172.28.0.1
X-Forwarded-Proto: http
X-Forwarded-Host: proxy.kong.lan
X-Forwarded-Port: 48000
User-Agent: curl/7.86.0
```

If however a wrong token is used, this is what's returned:

```
❯ curl -H "Authorization: Bearer $XXXX" http://proxy.kong.lan/auth/oidc

Request served by 97f243d248ea

HTTP/1.1 GET /

Host: echo-server:8080
X-Forwarded-Proto: http
X-Forwarded-Host: proxy.kong.lan
X-Forwarded-Path: /auth/oidc
X-Consumer-Id: b4d6a39a-5dc6-4ce8-b85a-fee580b5513b
X-Consumer-Username: anonymous
Connection: keep-alive
X-Forwarded-Prefix: /auth/oidc
Authorization: Bearer
User-Agent: curl/7.86.0
Accept: */*
X-Anonymous-Consumer: true
X-Forwarded-For: 172.28.0.1, 172.28.0.16
X-Forwarded-Port: 48000
X-Real-Ip: 172.28.0.1
```

Note that the same plugin could be removed from the service and be applied only to the route, and the behavior would remain the same, i.e. the anonymous consumer will act as a “catch-all” case for non-authorized calls to the route.

```bash
curl -k -H "Kong-Admin-Token:password" https://api.kong.lan/routes/auth-oidc/plugins 

  "data": [
    {
      "created_at": 1680192883,
      "id": "d7f831f7-0323-49f3-8f87-1a55a127bca0",
      "route": {
        "id": "4625ebe0-8287-44a2-8cc0-27a182e5a06d"
      },
      "name": "openid-connect",
      "protocols": [
        "grpc",
        "grpcs",
        "http",
        "https"
      ],
      "enabled": true,
      "config": {
        "display_errors": false,
        "response_type": [
          "code"
...
...
       "session_redis_prefix": "sessions",
        "auth_methods": [
          "bearer"
        ],
        "introspection_accept": "application/json",
        "session_memcache_host": "127.0.0.1",
        "cache_introspection": true,
        "refresh_tokens": true,
        "anonymous": "b4d6a39a-5dc6-4ce8-b85a-fee580b5513b",
        "run_on_preflight": true,
        "consumer_by": [
          "username",
          "custom_id"
        ],
        "verify_claims": true,
        "verify_parameters": false,
        "consumer_claim": [
          "email"
        ],
        "consumer_claims": [
          ["email"]
        ],
        "session_storage": "cookie",
        "leeway": 0,
        "http_version": 1.1,
        "session_cookie_samesite": "Lax",
        "cache_tokens": true,
        "cache_user_info": true,
        "ssl_verify": false
      }
    }
  ]
}
```
