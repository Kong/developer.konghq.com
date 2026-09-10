---
title: OIDC - Wild card support for login redirects with Azure as an IDP
content_type: support
description: A static `redirect_uri` combined with `login_action=redirect` lets the OIDC plugin redirect back to the originally requested URL after authentication, working around Azure AD's lack of wildcard login redirect support.
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources: []
tldr:
  q: How can I support wildcard login redirects with Azure AD using the OIDC plugin?
  a: |
    Azure AD doesn't support wildcard redirect URIs. Configure the OIDC plugin with a static `redirect_uri`, and set `login_action=redirect` and `preserve_query_args=true` so Kong performs an additional redirect to the originally requested URL after authentication.
---

## Problem

We use Azure as our OpenID Connect (OIDC) Identity Provider (IDP). Azure documentation states they have no support for wild card login redirects, is there any workaround for this?

## Solution

The following config for the OIDC plugin will perform an additional redirect (to the originally requested URL) at the Kong side once the OIDC has performed its authentication:

```
config.redirect_uri=<static-url> -- as adfs does not support wildcards
config.login_action=redirect     -- to make extra redirecting after the login
config.preserve_query_args=true  -- to preserve possible query args from original url
config.login_tokens=             -- set it to null so that plugin does not add any tokens to redirection
```
