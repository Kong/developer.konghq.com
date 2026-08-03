---
title: "Kong Gateway: How to rate limit OAuth2 token endpoint"
content_type: support
description: Out of the box it is not a configurable option to limit token creation through the OAuth2 plugin.
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources: []
tldr:
  q: How do I rate limit the OAuth2 token endpoint in Kong Gateway?
  a: |
    The OAuth2 plugin has no built-in option to limit token creation. As a workaround, create a second service whose path points at the `/oauth2/token` endpoint, expose it through a new route, and apply the Rate Limiting Advanced plugin to that service so token generation through the proxy is rate limited.
    Direct access to the original token endpoint is still possible and must be blocked by external means if required.
---

## Rate limiting the OAuth2 token endpoint

We setup the OAuth2 plugin and can confirm it is working as expected. However, when we try to apply a rate limiting advanced (RLA) plugin with the OAuth2 plugin, we noticed that the token endpoint is not being rate limited. For example if we setup the RLA plugin with `config.limits` as 3 and `config.window_size` as 30 globally. We can endlessly call the `/oauth2/token` endpoint. Is there a way to rate limit token generation?

Out of the box it is not a configurable option to limit token creation through the OAuth2 plugin.

However, there is a workaround where if we proxy the `/oauth2/token` endpoint through the proxy. We can then rate limit the service this way.

## Steps

Steps to test:

1) Create workspace

```bash
curl --request POST \
  --url http://localhost:8001/workspaces \
  --header 'Content-Type: multipart/form-data' \
  --header 'kong-admin-token: <token>' \
  --form name=teamA
```
2) Create Service

```bash
curl --request POST \
  --url http://localhost:8001/teamA/services \
  --header 'Content-Type: multipart/form-data' \
  --header 'kong-admin-token: <token>' \
  --form name=mockbin \
  --form url=http://mockbin.org/request
```
3) Create Route

```bash
curl --request POST \
  --url http://localhost:8001/teamA/services/mockbin/routes \
  --header 'Content-Type: multipart/form-data' \
  --header 'kong-admin-token: <token>' \
  --form name=mockbin \
  --form paths=/mockbin
```
4) Create OAuth2 plugin

```bash
curl --request POST \
  --url http://localhost:8001/teamA/services/mockbin/plugins \
  --header 'Content-Type: multipart/form-data' \
  --header 'kong-admin-token: admin' \
  --form name=oauth2 \
  --form config.scopes=email \
  --form config.enable_authorization_code=true \
  --form config.enable_client_credentials=true
```
5) Create consumer

```bash
curl --request POST \
  --url http://localhost:8001/teamA/consumers \
  --header 'Content-Type: multipart/form-data' \
  --header 'kong-admin-token: admin' \
  --form username=user1
```
At this point we can generate tokens successfully.

Example call:

```bash
curl --request POST -k \
  --url 'https://localhost:8443/mockbin/oauth2/token' \
  --header 'Content-Type: multipart/form-data' \
  --header 'kong-admin-token: admin' \
  --form client_id=456 \
  --form client_secret=789 \
  --form grant_type=client_credentials
```
To begin Rate Limiting them we need to do the following:

6) Create a service with the `/oauth2/token` endpoint.

```bash
curl --request POST \
  --url http://localhost:8001/teamA/services \
  --header 'Content-Type: application/json' \
  --header 'Kong-Admin-Token: admin' \
  --data '{
	"name": "Oauth",
	"retries": 0,
	"host": "localhost",
	"path": "/mockbin/oauth2/token",
	"port": 8443,
  "protocol":"https"
}'
```
7) Create a route for the previous service

```bash
curl --request POST \
  --url http://localhost:8001/teamA/services/Oauth/routes \
  --header 'Content-Type: multipart/form-data' \
  --header 'kong-admin-token: admin' \
  --form name=oauthRoute \
  --form paths=/oauth
```
At this point we can call the new service/route to generate a token.

8) Add a Rate Limiting Advanced (RLA) plugin.

```bash
curl --request POST \
  --url http://localhost:8001/teamA/services/mockbin/plugins \
  --header 'Content-Type: application/json' \
  --header 'kong-admin-token: admin' \
  --data '{
 "name": "rate-limiting-advanced",
 "config":
	{
		"limit":[3], 
		"window_size":[30], 
		"sync_rate": -1,
		"strategy": "local"
}
}'
```
We can now proxy the token endpoint for exactly 3 times in 30 seconds and then it will rate limit the token creation.

**Direct access to the token endpoint is still possible and should be blocked using external means if this is a requirement.**
