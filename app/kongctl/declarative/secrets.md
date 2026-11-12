---
title: "Write-only secrets and rotation with kongctl"
description: "Create and rotate write-only values without embedding them in plans."
content_type: reference
layout: reference
works_on:
  - konnect
tools:
  - kongctl
breadcrumbs:
  - /kongctl/
  - /kongctl/declarative/
related_resources:
  - text: Declarative configuration overview
    url: /kongctl/declarative/
  - text: Supported resources
    url: /kongctl/supported-resources/
---

Read this page when creating or rotating write-only values, composing `!secret`
sources, or moving plans that depend on secret files.

For a complete create, rotation, saved-plan, composition, and aggregate-write
walkthrough, see the
[Secrets example][secrets-example].

Some {{site.konnect_short_name}} APIs accept secret values on create or update but do not return
them from `get` or `list` responses. Common examples include:

- Portal identity provider `config.client_secret`
- DCR provider secrets such as `dcr_token`, `api_key`, and
  `initial_client_secret`
- {{site.ai_gateway}} Model Provider authentication values such as
  `config.auth.headers[].value`, `client_secret`, `secret_access_key`, and
  `service_account_json`
- {{site.ai_gateway}} Auth Strategy OpenID Connect `config.client_secret`,
  `config.http_proxy_authorization`, and `config.https_proxy_authorization`
- {{site.ai_gateway}} Vault authentication credentials
- {{site.ai_gateway}} runtime certificate `key` and `key_alt`
- Portal custom domain `ssl.custom_private_key`
- {{site.event_gateway_short}} backend cluster `authentication.password`
- {{site.event_gateway_short}} schema registry authentication `password`
- {{site.ai_gateway}} Consumer Credential `api_key`

Secret material in write-only fields must use `!secret`. Literal values and
eager `!file` values are rejected because they could enter a saved plan:

```yaml
client_secret: !secret
  source: !env PORTAL_OIDC_CLIENT_SECRET
```

Deferred files are also supported inside `!secret`. The file is validated when
the manifest is loaded and read again immediately before execution, without
placing its contents in a saved plan:

```yaml
key: !secret
  source: !file ./certs/runtime-key.pem
```

Saved plans store deferred secret-file paths relative to the plan file. Keep the
referenced files in the plan directory or one of its subdirectories, and move
the plan and those files together when executing on another host. Apply resolves
the path within the plan directory and rejects absolute paths, parent traversal,
and symlinks that escape that boundary. When a plan is written to standard
output, the current working directory is the boundary.

Recognized {{site.konnect_short_name}} vault references can be written literally because they
identify secret material without containing it. They remain visible in plans,
and {{site.konnect_short_name}} resolves them when applying the configuration:

```yaml
value: "{vault://support-secrets/openai-auth-header}"
```

`!secret` can also compose public decorations with one or more deferred sources.
Parts are concatenated exactly as written:

```yaml
value: !secret
  parts:
    - "Bearer "
    - !env AI_PROVIDER_TOKEN
```

Do not put secret material in literal parts. Literal parts, source kinds, and
environment variable names are stored as metadata in saved plans. Resolved
values are not. Planning does not require the secret environment variables;
execution requires every source to exist and resolve to a non-empty string. All
sources are checked before the first API mutation.

Bare `!env` remains accepted on reviewed secret fields for one deprecation
cycle. It has the same deferred behavior as `!secret {source: !env ...}` and
produces a warning. New configuration should use the explicit wrapper.

Declaring a source and authorizing a write are separate operations. Creates send
each configured secret once. Existing resources write a secret only when
selected during plan generation:

```sh
# One field
kongctl plan --mode apply -f config.yaml \
  --write-secret workforce-idp#config.client_secret \
  --output-file rotation.json

# Every configured secret on one resource
kongctl plan --mode apply -f config.yaml \
  --write-secret workforce-idp \
  --output-file rotation.json

# Every eligible configured secret
kongctl plan --mode apply -f config.yaml --write-secrets \
  --output-file rotation.json
```

`--write-secrets` is best-effort across the complete configuration. It writes
every eligible configured secret and reports skipped create-only or otherwise
ineligible fields as warnings on standard error. The warnings are also kept in
saved plan metadata for later review. If the flag finds no writable secrets, the
command succeeds with a warning. An exact `--write-secret` selector remains
strict and fails if its requested field cannot be written.

The current {{site.konnect_short_name}} API permits at most one {{site.ai_gateway}} Model Provider
authentication header. The selector still uses `config.auth.headers[].value`
because it follows the array-shaped OpenAPI field without coupling configuration
to index `0`.

Selectors use `[resource-type:]resource-ref[#field]`. `plan`, `diff`, and direct
configuration-based `apply` and `sync` accept them. A saved plan already
contains its secret-write intents, so write-selection flags cannot be combined
with `--plan`. Delete mode does not accept secret selection.

The planner cannot compare a write-only field with its remote value. Without a
selector, it continues to omit the field and remains idempotent. With a
selector, it records a write intent, merges it into an ordinary update, or
creates a secret-only update. Human output reports `write requested` without
showing a value.

{{site.ai_gateway}} Consumer Credential `api_key` is create-only. Omit it to let
{{site.konnect_short_name}} generate a key, or supply it with `!secret` on a new credential.
Selecting it on an existing credential fails. Rotate it by declaring a new
credential and deliberately retiring the old one; kongctl never silently
recreates it.

[secrets-example]:
https://github.com/Kong/kongctl/blob/main/docs/examples/declarative/secrets/README.md
