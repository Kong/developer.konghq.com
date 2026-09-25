---
title: How to configure Kong Manager OIDC login to use a POST method
content_type: support
description: "Configure Kong Manager's OIDC login to respond via POST instead of GET by setting `preserve_query_args`, `response_mode: form_post`, and `redirect_uri` in `admin_gui_auth_conf`."
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: How do I configure Kong Manager OIDC login to use a POST method instead of GET?
  a: |
    Add `preserve_query_args: true` and `response_mode: "form_post"` to `admin_gui_auth_conf`, point `redirect_uri` at the Admin API's `/auth` endpoint, and include `session` in `auth_methods`. Don't set `login_action: "redirect"` — Kong Manager/Admin API OIDC authentication always forces `login_action` to `upstream` internally, so `response_mode: "form_post"` is what actually makes the identity provider POST the response instead of using GET query parameters.
related_resources: []
---

## Overview

When using OIDC authentication for Kong Manager, the login is performed by a GET request with query parameters appended. This GET URL is visible in the browser and can be considered a security vulnerability. How can the configuration be set to use a POST method for the login?

## Steps

The OIDC Kong Manager authentication supports a POST method. The OIDC configuration in the `admin_gui_auth_conf` parameter will need to be updated to use a POST method and a summary of these required configuration changes is as below;

1. Add the below 2 parameters to the configuration:

   ```yaml
   preserve_query_args: true
   response_mode: "form_post"
   ```

   Note: do not set `login_action: "redirect"` for `admin_gui_auth_conf`. For Kong Manager/Admin API OIDC authentication, Kong unconditionally forces `login_action` to `"upstream"` internally (`kong/enterprise_edition/auth_plugin_helpers.lua`'s `prepare_openid_config()`, whose code comments explicitly say using `"redirect"` there would skip required post-authentication processing) -- any `login_action` value configured in `admin_gui_auth_conf` is silently ignored and has no effect. `response_mode: "form_post"` (which is not overridden) is what actually causes the identity provider to POST the authorization response to `redirect_uri` instead of appending it as GET query parameters, and is the setting that resolves the security concern this article describes.

2. The `redirect_uri` must be changed to the `/auth` endpoint on Admin API (e.g., `http://localhost:8001/auth`)

3. The `auth_methods` must include `"session"`

To help clarify the above, below is a previous configuration for Azure AD where a GET method is used;

```json
{
	"admin_claim": "name",
	"auth_methods": [
		"authorization_code",
		"password"
	],
	"authenticated_groups_claim": [
		"groups"
	],
	"client_id": [
		"<client_id>"
	],
	"client_secret": [
		"<client_secret>"
	],
	"consumer_by": [
		"username",
		"custom_id"
	],
	"issuer": "https://login.microsoftonline.com/e4bf00f3-2010-40d6-b82f-58df9f957e49/v2.0/.well-known/openid-configuration",
	"login_redirect_uri": [
		"https://manager.kong.lan/"
	],
	"logout_methods": [
		"GET",
		"DELETE",
		"POST"
	],
	"logout_query_arg": "logout",
	"logout_redirect_uri": [
		"https://manager.kong.lan/"
	],
	"redirect_uri": [
		"https://manager.kong.lan/"
	],
	"scopes": [
		"openid",
		"profile",
		"email",
		"4bf4e6a0-43db-4f89-b901-342045486873/.default"
	],
	"session_cookie_name": "kong_manager_session",
	"ssl_verify": false
}
```

After the configuration changes have been made, the configuration would look like this;

```json
{
	"admin_claim": "name",
	"auth_methods": [
		"authorization_code",
		"password",
		"session"
	],
	"client_id": [
		"<client_id>"
	],
	"client_secret": [
		"<client_secret>"
	],
	"consumer_by": [
		"username",
		"custom_id"
	],
	"issuer": "https://login.microsoftonline.com/e4bf00f3-2010-40d6-b82f-58df9f957e49/v2.0/.well-known/openid-configuration",
	"login_redirect_uri": [
		"https://manager.kong.lan/"
	],
	"logout_methods": [
		"GET",
		"DELETE",
		"POST"
	],
	"logout_query_arg": "logout",
	"logout_redirect_uri": [
		"https://manager.kong.lan/"
	],
	"preserve_query_args": true,
	"redirect_uri": [
		"https://api.kong.lan/auth"
	],
	"response_mode": "form_post",
	"scopes": [
		"openid",
		"profile",
		"email",
		"4bf4e6a0-43db-4f89-b901-342045486873/.default"
	],
	"session_cookie_name": "kong_manager_session",
	"ssl_verify": false
}
```
