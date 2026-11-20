# Konnect AI Gateway API shapes (test harness)

Base: `https://us.api.konghq.tech/v1/ai-gateways/$KONNECT_CONTROL_PLANE_ID` (`.tech` or `.com`).
Check the OpenAPI spec if a shape here is rejected. The spec wins.

## Policy
`POST /policies` with `{name, display_name, type, global, config}`. `PUT /policies/<name>` updates in place.

## Model
`POST /models` needs:
- `"type": "model"`, `formats`
- `targets: [{name, provider, weight, config: {type}}]`
- `policies: [names]`
- `config.route.paths` and `config.route.model.body_param` / `values`

Requests go to `<path>/chat/completions`, not the bare path.
Update with `PUT` (full body), not `PATCH` (405). The same applies to agents and MCP servers.

## Agent
`type: a2a`, `config.url`, `config.route.paths`, `policies`.

## MCP server
- Only listener types serve traffic (for example `conversion-listener`). `conversion-only` always returns 404.
- Body: `type: conversion-listener`, `config.url`, `config.route.paths`, and a `tools` array with `name`, `description`, `method`, `path`, `annotations.title`.
- Call it with JSON-RPC and `accept: application/json, text/event-stream`.

## Consumers, groups, auth
- Consumer: `type: api-key`.
- Credential: `POST /consumers/<consumer-uuid>/credentials` with `{name, display_name, type: api-key}`. The key is generated and returned in `api_key`. You cannot choose it. `key` and `config.key` are rejected. Keep generated keys in a scratchpad file and delete it afterward.
- Credentials, group membership and group endpoints take UUIDs, not names.
- Add a group member: `POST /consumer-groups/<group-uuid>/consumers` with `{"consumer": "<consumer-uuid>"}`.
- Key-auth: `POST /auth-strategies` with `{type: key-auth, config: {key_names: [...]}}`, then attach with `"access": {"auth_strategies": ["<name>"]}` on the model. A request without a key returns "No API key found in request", which confirms auth runs first.

## Real provider
Create a temporary `model-providers` entry with `config.auth.headers: [{name: Authorization, value: "Bearer $KEY"}]`. Delete it afterward.

## kongctl check
Write a manifest under the scratchpad (`ai_gateways:` with `_external.selector.matchFields.name`, and a `policies:` list), then:

```bash
KONGCTL_DEFAULT_KONNECT_ENVIRONMENT=tech ~/.local/bin/kongctl apply -f <file> --auto-approve
```

Send a request that proves the policy works, then delete the policy through the API.
