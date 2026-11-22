---
title: "{{site.kong_harnesses}} profile file"
description: "Every field of a {{site.kong_harnesses}} profile, and which {{site.kong_harnesses}} releases read each profile schema version."
content_type: reference
layout: reference

products:
  - ai-gateway

works_on:
  - konnect

tools:
  - kong-harnesses

tags:
  - cli

breadcrumbs:
  - /kong-harnesses/

related_resources:
  - text: "kong-harnesses profile create"
    url: /kong-harnesses/profile/create/
  - text: "kong-harnesses profile import"
    url: /kong-harnesses/profile/import/
  - text: "kong-harnesses errors and exit codes"
    url: /kong-harnesses/errors/
  - text: "Set up {{ site.claude_code }} with kong-harnesses"
    url: /ai-gateway/set-up-claude-code-with-kong-harnesses/
---

A profile is a JSON document that tells {{site.kong_harnesses}} where {{site.ai_gateway}} is, how developers sign in, and how to set up each agent CLI.
A profile doesn't contain secrets, so an administrator can share one file with every developer.
Create one with [`kong-harnesses profile create`](/kong-harnesses/profile/create/) or install one from a file or HTTPS URL with [`kong-harnesses profile import`](/kong-harnesses/profile/import/).

A profile file can be up to 65,536 bytes as saved, so a UTF-16 file holds about half as much text.
For accepted encodings and how to convert refused files, see [Profile file encoding](#profile-file-encoding).
{{site.kong_harnesses}} refuses unknown fields, fields disallowed by the schema version, and duplicate keys.
To inspect an installed profile document (stored under `.profile` in JSON output), run `profile get` with [jq](https://jqlang.org/):

```sh
kong-harnesses profile get PROFILE_NAME -o json | jq '.profile'
```

The following profile signs developers in with an identity provider and sets up {{ site.claude_code }} and Codex:

```json
{
  "schema_version": 17,
  "name": "work",
  "display_name": "Work AI Gateway",
  "issuer": "https://login.example.com/oauth2/default",
  "discovery_url": "https://login.example.com/oauth2/default/.well-known/openid-configuration",
  "authorization_endpoint": "https://login.example.com/oauth2/default/v1/authorize",
  "token_endpoint": "https://login.example.com/oauth2/default/v1/token",
  "jwks_uri": "https://login.example.com/oauth2/default/v1/keys",
  "client_id": "YOUR_CLIENT_ID",
  "gateway_origin": "https://ai-gateway.example.com",
  "audience": "api://default",
  "scopes": ["openid", "profile", "email", "offline_access"],
  "routes": {
    "anthropic": {
      "protocol": "anthropic-messages",
      "tool_reference": true,
      "advisor": false,
      "artifact": false
    },
    "openai": {
      "protocol": "openai-responses"
    }
  },
  "clients": {
    "claude-code": {
      "route": "anthropic",
      "models": {
        "active": "claude-sonnet-5-5",
        "default": "claude-sonnet-5-5",
        "sonnet": "claude-sonnet-5-5",
        "opus": "claude-opus-5-5",
        "haiku": "claude-haiku-5-5",
        "fable": "claude-fable-5-2",
        "subagent": "claude-sonnet-5-5",
        "background_classifier": "claude-haiku-5-5",
        "auto_mode": "claude-sonnet-5-5"
      },
      "auto_updates": false,
      "tool_search": true,
      "advisor": false
    },
    "codex": {
      "route": "openai"
    }
  }
}
```

## Profile file encoding

`profile import` reads UTF-8 (with or without a byte-order mark) and UTF-16LE or UTF-16BE with a byte-order mark, and stores it as UTF-8 without a byte-order mark.
Windows PowerShell 5.1 `>` redirection writes UTF-16LE with a byte-order mark, so `profile import` reads it directly.

When `profile import` refuses an encoding, the error names what it found and the fix:

{% table %}
columns:
  - title: Encoding reported
    key: encoding
  - title: Fix
    key: fix
rows:
  - encoding: "`UTF-16LE without a byte-order mark` or `UTF-16BE without a byte-order mark`"
    fix: "Save a copy with a byte-order mark, for example in PowerShell with `Get-Content -Raw -Encoding Unicode PROFILE_FILE | Set-Content -Encoding Unicode COPY_FILE` (use `-Encoding BigEndianUnicode` after `Get-Content` for UTF-16BE), then import the copy."
  - encoding: "`UTF-32`"
    fix: "Save a copy as UTF-16, for example in PowerShell with `Get-Content -Raw PROFILE_FILE | Set-Content -Encoding Unicode COPY_FILE`, then import the copy."
  - encoding: "`UTF-16 with a broken character`"
    fix: "Get the profile file again, because the file is cut short or damaged."
  - encoding: "`a text encoding that is not UTF-8`, or `UTF-8 with a byte-order mark` (when a file has two byte-order marks)"
    fix: "Save a copy as UTF-8 with an editor, then import the copy."
{% endtable %}

## Schema versions

`schema_version` controls which fields a profile can use.
Each release reads versions up to its latest and refuses newer ones.
From 0.6.0, `profile create` writes its latest version (earlier releases wrote the lowest needed version), so older releases can't import it.

To share one profile across releases, set the lowest version with every needed field that the oldest release reads:

{% table %}
columns:
  - title: Version
    key: version
  - title: What it adds
    key: adds
  - title: Read by
    key: release
rows:
  - version: "1"
    adds: "The sign-in and gateway fields."
    release: "0.1.0 and later"
  - version: "2"
    adds: "`models`, the model aliases for {{ site.claude_code }}."
    release: "0.1.0 and later"
  - version: "3"
    adds: "`attribution` and `telemetry`."
    release: "0.1.0 and later"
  - version: "4"
    adds: "`revocation_endpoint`."
    release: "0.1.0 and later"
  - version: "5"
    adds: "`audience_parameter`."
    release: "0.1.0 and later"
  - version: "6"
    adds: "`public_client_evidence`."
    release: "0.1.0 and later"
  - version: "7"
    adds: "`haiku` and `max_context_tokens` in `models`."
    release: "0.2.0 and later"
  - version: "8"
    adds: "`request_shape`."
    release: "0.5.0 and later"
  - version: "9"
    adds: "`auto_updates`."
    release: "0.5.0 and later"
  - version: "10"
    adds: "`model_metadata`."
    release: "0.5.0 and later"
  - version: "11"
    adds: "`pricing`."
    release: "0.5.0 and later"
  - version: "12"
    adds: >-
      `routes`, `clients`, `gateway_ca_bundle`, `sign_in` and `mcp_servers`.
      The {{ site.claude_code }} settings move from the top level into `clients.claude-code`.
      `models` adds the `default`, `fable`, `subagent`, `background_classifier` and `auto_mode` roles, and every role except `max_context_tokens` is required.
    release: "0.6.0 and later"
  - version: "13"
    adds: "The `codex`, `opencode` and `omp` client blocks."
    release: "0.7.0 and later"
  - version: "14"
    adds: >-
      The {{ site.claude_code }} choices, such as `hint_headers` and `connectors`.
      Each choice is optional.
    release: "0.9.0 and later"
  - version: "15"
    adds: "A client block other than `claude-code` in a profile that sets `gateway_ca_bundle`."
    release: "0.14.0 and later"
  - version: "16"
    adds: "The `hermes` and `pi` client blocks."
    release: "0.14.0 and later"
  - version: "17"
    adds: "`sign_in` set to `environment_key`."
    release: "0.16.0 and later"
  - version: "18"
    adds: >-
      `auto_mode_gateway_check`, and new rules for what `auto_updates: false` and `feature_flags` write.
      See [Claude Code choices](#claude-code-choices).
    release: "0.18.0 and later"
{% endtable %}

Some values need a newer release than their schema version:

* The `foundry-messages` and `bedrock-mantle-messages` route protocols need 0.8.0 or later.
* `sign_in` set to `static_key`, and `mcp_servers`, need 0.14.0 or later.
* `sign_in` set to `subscription` needs 0.17.0 or later.

## Top-level fields

The top-level fields of a profile document set the schema version, profile identity, gateway origin, and configuration sections:

{% table %}
columns:
  - title: Field
    key: field
  - title: Description
    key: description
rows:
  - field: "`schema_version`"
    description: >-
      Required.
      The schema version of the document.
      See [Schema versions](#schema-versions).
  - field: "`name`"
    description: >-
      Required.
      The name that commands take with `--profile`.
      1 to 63 bytes of lowercase letters, digits and hyphens.
      It starts with a letter, and ends with a letter or a digit.
      `default`, `con`, `prn`, `aux`, `nul`, `com1` to `com9` and `lpt1` to `lpt9` are reserved.
  - field: "`display_name`"
    description: "A name for people to read, 1 to 80 printable ASCII characters."
  - field: "`description`"
    description: "A longer description, 1 to 240 printable ASCII characters."
  - field: "`gateway_origin`"
    description: >-
      Required.
      The origin of {{site.ai_gateway}}, up to 2,048 bytes, without a path or the default port.
      It uses `https://`.
      From 0.17.1, a gateway on this computer can use `http://`, on `localhost` or on a loopback address such as `127.0.0.1` or `[::1]`, but not an IPv4-mapped IPv6 address.
      `fleet build` refuses an `http://` gateway.
      A `subscription` profile, and a profile with an `oauth` MCP server, need `https://`.
      For which agent CLIs work with an `http://` gateway and the proxy rules, see [Plain HTTP gateways](#plain-http-gateways).
  - field: "`gateway_ca_bundle`"
    description: >-
      Version 12 and later.
      PEM certificate authorities for the gateway certificate, up to 32 KB.
      Releases before 0.14.0 wrote it for {{ site.claude_code }}, and 0.14.0 used it only for {{site.kong_harnesses}} itself.
      From 0.15.0, releases still read it, but neither {{site.kong_harnesses}} nor the agent CLIs use it, and `profile get` and `profile activate` say so.
      Add the certificate authority to the system trust store of each computer instead, as [Private certificate authorities](/kong-harnesses/private-certificate-authorities/) describes.
  - field: "`sign_in`"
    description: >-
      Version 12 and later.
      How developers get a credential.
      See [Sign-in fields](#sign-in-fields).
  - field: "`routes`"
    description: >-
      Required from version 12.
      The gateway routes that the clients use.
      See [Routes](#routes).
  - field: "`clients`"
    description: >-
      Required from version 12, with at least one client block.
      See [Clients](#clients).
  - field: "`mcp_servers`"
    description: >-
      Version 12 and later.
      MCP servers that the gateway serves to {{ site.claude_code }}.
      See [MCP servers](#mcp-servers).
  - field: "`attribution`"
    description: >-
      Version 3 and later.
      Headers that tell the gateway who a request belongs to.
      See [Attribution](#attribution).
{% endtable %}

Versions 2 to 11 keep the {{ site.claude_code }} settings at the top level: `models`, `telemetry`, `request_shape`, `auto_updates`, `model_metadata` and `pricing`.
From version 12, these fields go in `clients.claude-code`, and the top level refuses them.
A profile before version 12 doesn't have client blocks, so `profile activate` sets up every agent CLI except Hermes Agent.

### Plain HTTP gateways

Requests to an `http://` gateway aren't encrypted, so a proxy could read the credential.
{{site.kong_harnesses}} keeps these requests off proxies:

* Codex, OpenCode, and Hermes Agent need an `https://` gateway, even for a gateway on this computer, because they pick their proxy in ways that {{site.kong_harnesses}} can't check, so `profile activate` doesn't set them up for an `http://` gateway.
  {{ site.claude_code }}, `omp`, and pi work with an `http://` gateway when the profile configures them, they are installed (or named with `--client`), and the applicable checks pass.
  `profile activate` doesn't change any client settings when a pre-write check fails.
* When a proxy variable in the command environment applies to the gateway host, `profile activate` doesn't set up any client, and `credential` and `token` don't return a credential.
  Exclude the gateway host with `NO_PROXY` as the `gateway` check in [Troubleshoot kong-harnesses](/kong-harnesses/troubleshooting/#next-step-for-each-check) describes.
  From 0.18.0, `profile activate` also writes `NO_PROXY` and `no_proxy` in {{ site.claude_code }} user settings.
  A proxy variable or `NO_PROXY` in project settings takes precedence over these values, and `profile activate` refuses when managed settings could send the requests through a proxy.
* `fleet build` refuses `http://` profiles because it can't check proxy settings on managed computers.

See [Client setup errors](/kong-harnesses/errors/#client-setup-errors) and [Fleet build errors](/kong-harnesses/errors/#fleet-build-errors) for errors and fixes.

## Sign-in fields

`sign_in` picks how developers get a credential for the gateway:

{% table %}
columns:
  - title: Value
    key: value
  - title: Description
    key: description
rows:
  - value: "Not set"
    description: >-
      Developers sign in with your OpenID Connect identity provider through `kong-harnesses login`.
      The identity provider fields are required.
  - value: "`static_key`"
    description: >-
      Each developer saves a key from you with `kong-harnesses login`.
      The profile can't have identity provider fields.
  - value: "`environment_key`"
    description: >-
      Version 17 and later.
      Each command reads the key from `KONG_HARNESSES_STATIC_KEY`, for example in a CI job.
      The profile can't have identity provider fields.
  - value: "`subscription`"
    description: >-
      {{ site.claude_code }} sends each developer's own Claude subscription sign-in to the gateway.
      The identity provider fields are required, and `gateway_origin` uses `https://`.
{% endtable %}

The identity provider fields apply when `sign_in` isn't set or is `subscription`.
Each URL other than `redirect_uri` uses `https://`, is up to 2,048 bytes, and is in canonical form: without user information, a fragment, a `.` or `..` path segment, or the default port 443.
`issuer` can't have a query, and the endpoint URLs can.

{% table %}
columns:
  - title: Field
    key: field
  - title: Description
    key: description
rows:
  - field: "`issuer`"
    description: >-
      Required.
      The issuer URL of the identity provider.
  - field: "`discovery_url`"
    description: >-
      Required.
      The issuer URL without a trailing `/`, followed by `/.well-known/openid-configuration`.
  - field: "`authorization_endpoint`, `token_endpoint`, `jwks_uri`"
    description: >-
      Required.
      The endpoints from the discovery document.
      `profile create` and `profile import` refuse an `authorization_endpoint` with a query that sets a parameter that the sign-in request adds: `response_type`, `client_id`, `redirect_uri`, `scope`, `state`, `nonce`, `code_challenge`, `code_challenge_method`, `resource`, `audience` or `prompt`.
  - field: "`revocation_endpoint`"
    description: >-
      Version 4 and later.
      The endpoint that `logout` uses to revoke the sign-in.
  - field: "`client_id`"
    description: >-
      Required.
      The ID of the public client that you registered for {{site.kong_harnesses}}, 1 to 256 visible ASCII characters.
  - field: "`redirect_uri`"
    description: >-
      Where the identity provider sends the browser after sign-in.
      The default is `http://localhost:9876/callback`.
      Another value uses `http://`, the host `localhost`, `127.0.0.1` or `[::1]`, and a port from 1 to 65535.
      Its path is 2 to 256 characters of letters, digits and `-._~/`, without a `.` or `..` segment, `//`, a query or a fragment.
      Register the same value with the identity provider.
  - field: "`audience`"
    description: >-
      Required.
      The audience that the gateway accepts in a token, as an absolute URI of 1 to 2,048 bytes of visible ASCII, without user information or a fragment.
  - field: "`audience_parameter`"
    description: >-
      Version 5 and later.
      How the sign-in request sends the audience: `resource`, the default, `audience`, or `none`.
  - field: "`public_client_evidence`"
    description: >-
      Version 6 and later.
      Set to `deployment` when the discovery document doesn't list the `none` token endpoint authentication method, and your deployment shows in another way that the client is public.
      Like the other identity provider fields, a `static_key` or `environment_key` profile refuses it.
  - field: "`scopes`"
    description: >-
      Required.
      The scopes that the sign-in requests, 2 to 16 of them, with `openid` and `offline_access` among them.
      Each scope appears once, and is 1 to 128 visible ASCII characters, except double quotes and backslashes.
      `profile create` writes `openid`, `profile`, `email` and `offline_access` unless you give `--scope`.
  - field: "`max_access_token_lifetime_seconds`"
    description: >-
      The longest access token lifetime that {{site.kong_harnesses}} accepts, from 365 to 86400.
      The default is 3600.
      Releases up to 0.17.1 also accepted 360.
      A profile that they installed with 360 still reads, but sign-in refuses it, so give developers a profile with 365 or more.
{% endtable %}

### Security identity

A profile's security identity consists of `issuer`, `discovery_url`, `authorization_endpoint`, `token_endpoint`, `jwks_uri`, `revocation_endpoint`, `client_id`, `redirect_uri`, `gateway_origin`, `audience`, `audience_parameter`, `public_client_evidence`, `scopes`, `max_access_token_lifetime_seconds`, `gateway_ca_bundle` and `sign_in`.

A saved sign-in belongs to one security identity.
When `profile create` or `profile import` replaces a profile and changes one of these fields, each developer signs in again, as [Sign in to a profile](/kong-harnesses/sign-in/#sign-in-to-a-profile) describes for each kind of profile.
An `environment_key` profile doesn't save a sign-in, so developers don't need to sign in again.
`profile create` and `profile import` refuse the change while an agent CLI uses the profile: run `profile cleanup` for that client, or activate another profile there, then create or import the profile and activate it again.
A profile that moves from version 11 or earlier to version 12 or later also gets a new security identity, even when these fields keep their values.
A change to the other fields, such as `routes` or `clients`, keeps the sign-in.

## Routes

`routes` maps a route name to the protocol that the gateway serves on it.
A profile has 1 to 16 routes.
Each route name is 1 to 64 bytes of visible ASCII, and each client block names one route in its `route` field.

{% table %}
columns:
  - title: Field
    key: field
  - title: Description
    key: description
rows:
  - field: "`protocol`"
    description: >-
      Required.
      `anthropic-messages` for the Anthropic API, `foundry-messages` for Microsoft Foundry, `bedrock-mantle-messages` for Amazon Bedrock Mantle, `openai-responses` for Codex, or `gateway-plugin` for OpenCode.
  - field: "`tool_reference`"
    description: >-
      Required for the three Anthropic API protocols, and refused for the others.
      `true` when the route serves the tool references that {{ site.claude_code }} tool search sends.
  - field: "`advisor`"
    description: >-
      Required for the three Anthropic API protocols, and refused for the others.
      `true` when the route serves the {{ site.claude_code }} advisor tool.
  - field: "`artifact`"
    description: >-
      Required for the three Anthropic API protocols, and refused for the others.
      Activation ignores it.
      It stays so that older profiles still import.
{% endtable %}

## Clients

`clients` has one block for each agent CLI that `profile activate` sets up.
Each block has a `route` field, which names a route with the protocol that the client uses:

{% table %}
columns:
  - title: Block
    key: block
  - title: Version
    key: version
  - title: Route protocol
    key: protocol
rows:
  - block: "`claude-code`"
    version: "12"
    protocol: "`anthropic-messages`, `foundry-messages` or `bedrock-mantle-messages`"
  - block: "`codex`"
    version: "13"
    protocol: "`openai-responses`"
  - block: "`opencode`"
    version: "13"
    protocol: "`gateway-plugin`"
  - block: "`omp`"
    version: "13"
    protocol: "`anthropic-messages`"
  - block: "`hermes`"
    version: "16"
    protocol: "`anthropic-messages`"
  - block: "`pi`"
    version: "16"
    protocol: "`anthropic-messages`"
{% endtable %}

Some blocks have more rules:

* The `hermes` block also needs `model`, the gateway model that Hermes Agent starts with, 1 to 128 bytes.
  A profile with a `hermes` block signs in with an identity provider, so it can't use `static_key`, `environment_key` or `subscription`.
  It also sets `audience_parameter` to `audience`, and requests exactly the scopes `openid`, `profile`, `email` and `offline_access`.
* A profile with an `opencode` block can't use `static_key` or `environment_key`.
* A `subscription` profile has only a `claude-code` block, on an `anthropic-messages` route.
* A profile named `constructor` or `prototype` can't set up OpenCode.

`profile activate` also refuses some agent CLIs for a profile that has fields they can't use:

* Hermes Agent and pi don't take `attribution`.
* Codex, OpenCode, and Hermes Agent don't take an `http://` gateway.
  See [Plain HTTP gateways](#plain-http-gateways).
* In a profile before version 12, top-level `telemetry` stops Codex, OpenCode, `omp`, and pi, and top-level `models` stops Codex.

### Claude Code

The `claude-code` block has these fields:

{% table %}
columns:
  - title: Field
    key: field
  - title: Description
    key: description
rows:
  - field: "`route`"
    description: >-
      Required.
      The route that {{ site.claude_code }} uses.
  - field: "`models`"
    description: >-
      Required.
      The gateway model aliases.
      See [Models](#models).
  - field: "`telemetry`"
    description: >-
      Where {{ site.claude_code }} sends OpenTelemetry data.
      See [Telemetry](#telemetry).
  - field: "`request_shape`"
    description: >-
      Changes to the requests that {{ site.claude_code }} sends.
      See [Request shape](#request-shape).
  - field: "`model_metadata`"
    description: >-
      How the `/model` picker describes a gateway model.
      See [Model metadata](#model-metadata).
  - field: "`pricing`"
    description: >-
      The prices that {{ site.claude_code }} uses to show cost.
      See [Pricing](#pricing).
  - field: "`auto_updates` and the other choices"
    description: "See [Claude Code choices](#claude-code-choices)."
{% endtable %}

#### Models

`profile activate` writes each alias into {{ site.claude_code }} settings.
Each alias is 1 to 128 bytes of visible ASCII.
Versions 2 to 6 take `active`, `sonnet` and `opus`, and require all three.
Version 7 adds optional `haiku` and `max_context_tokens`.
From version 12, every role except `max_context_tokens` is required.

{% table %}
columns:
  - title: Field
    key: field
  - title: Setting that it writes
    key: setting
rows:
  - field: "`active`"
    setting: "`ANTHROPIC_MODEL`"
  - field: "`default`"
    setting: "`ANTHROPIC_DEFAULT_MODEL`"
  - field: "`sonnet`"
    setting: "`ANTHROPIC_DEFAULT_SONNET_MODEL`"
  - field: "`opus`"
    setting: "`ANTHROPIC_DEFAULT_OPUS_MODEL`"
  - field: "`haiku`"
    setting: "`ANTHROPIC_DEFAULT_HAIKU_MODEL`"
  - field: "`fable`"
    setting: "`ANTHROPIC_DEFAULT_FABLE_MODEL`"
  - field: "`subagent`"
    setting: "`CLAUDE_CODE_SUBAGENT_MODEL`"
  - field: "`background_classifier`"
    setting: "`CLAUDE_CODE_BG_CLASSIFIER_MODEL`"
  - field: "`auto_mode`"
    setting: "`CLAUDE_CODE_AUTO_MODE_MODEL`"
  - field: "`max_context_tokens`"
    setting: >-
      `CLAUDE_CODE_MAX_CONTEXT_TOKENS`, the context window of the gateway models, from 8192 to 10000000.
      Set it when the models hold less than {{ site.claude_code }} expects.
{% endtable %}

#### Claude Code choices

Each choice is `true` or `false`.
From version 14, each choice is optional, and a choice that the profile leaves out changes nothing.
Versions 12 and 13 require `auto_updates`, `tool_search`, `advisor` and `artifact`, and refuse the other choices.
For a profile before version 14, {{site.kong_harnesses}} treats each choice from `anthropic_telemetry` to `webfetch_preflight` as `false`.
When a later profile omits a choice or sets `auto_updates: true`, `profile activate` restores each setting it stops controlling to its earlier value, unless the setting changed after activation wrote it.
If the setting changed, `profile activate` keeps the current value.
Either a restored setting from you or another tool, or a later edit, can still turn the feature off.

`CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC`, which `auto_updates: false` writes, also turns off {{ site.claude_code }} telemetry, feature flags, error reports, `/bug`, `/feedback`, the feedback survey, subscription artifacts, and the advisor tool on `anthropic-messages`, where it depends on a feature flag.
`DISABLE_TELEMETRY` also turns off feature flags, error reports and the feedback survey.
`DISABLE_BUG_COMMAND` is the earlier name of `DISABLE_FEEDBACK_COMMAND`, and either turns off `/bug`, `/feedback`, `/share`, and feedback that Claude drafts.
So `profile create` and `profile import` refuse a profile that turns on a feature and also turns off a setting that it needs:

* Up to version 17, `auto_updates: false` can't go with `true` for `anthropic_telemetry`, `feature_flags`, `error_reports`, `bug_command`, `feedback_command`, or `feedback_survey`, with `artifact: true` in a `subscription` profile, or with an eligible `advisor: true` on `anthropic-messages` (where `experimental_betas`, `feature_flags`, and `anthropic_telemetry` aren't `false`).
  Releases up to 0.17.1 accepted `artifact: true` in a `subscription` profile, and `advisor: true`, with `auto_updates: false`, so installed pre-18 profiles with either pair still read.
  In those profiles, `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC` keeps those features off, and `profile activate` and `profile get` report them and ask for a version 18 profile.
* `feature_flags: true` can't go with `anthropic_telemetry: false`.
* From version 18, `error_reports: true` and `feedback_survey: true` can't go with `anthropic_telemetry: false`.
* From version 18, `advisor: true` is refused on provider modes without advisor support (`foundry-messages` and `bedrock-mantle-messages`), with `experimental_betas: false`, or on `anthropic-messages` with `feature_flags: false` or `anthropic_telemetry: false`.
* `bug_command: true` and `feedback_command: true` each can't go with `false` for the other one.
  From version 18, `profile create` and `profile import` also refuse setting only one of `bug_command` and `feedback_command`.

Apart from `bug_command` and `feedback_command` in version 18, an omitted choice never causes a conflict.

{% table %}
columns:
  - title: Choice
    key: choice
  - title: When `false`
    key: off
  - title: When `true`
    key: on
rows:
  - choice: "`auto_updates`"
    off: "Writes `DISABLE_AUTOUPDATER=1` and `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1`, except when a version 18 or later profile writes `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC` blank."
    on: >-
      Writes neither setting, except when a version 18 or later profile writes `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC` blank for another enabled choice.
      A developer can still turn off automatic updates with `DISABLE_AUTOUPDATER`, and can turn off all nonessential traffic with `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC` when activation doesn't write it blank.
  - choice: "`tool_search`"
    off: "Writes `ENABLE_TOOL_SEARCH=false`."
    on: >-
      Writes `ENABLE_TOOL_SEARCH=true`.
      The route needs `tool_reference: true`.
      When `request_shape` sets `experimental_betas: false`, tool search stays off.
  - choice: "`advisor`"
    off: "Writes `CLAUDE_CODE_DISABLE_ADVISOR_TOOL=1`."
    on: >-
      Leaves the advisor tool on when nothing in the profile keeps it off.
      The route needs `advisor: true`.
      For an older stored profile whose provider mode, `experimental_betas: false`, or blocked feature flags keep the advisor off, `profile activate` writes `CLAUDE_CODE_DISABLE_ADVISOR_TOOL=1`.
  - choice: "`artifact`"
    off: >-
      From version 14, writes `enableArtifact: false`.
      Versions 12 and 13 write nothing.
    on: >-
      From version 14, writes `enableArtifact: true`.
      Versions 12 and 13 write nothing.
      The route needs `artifact: true`.
  - choice: "`hint_headers`"
    off: "Writes `CLAUDE_CODE_GATEWAY_HINT_HEADERS=0`."
    on: "Writes `CLAUDE_CODE_GATEWAY_HINT_HEADERS=1`."
  - choice: "`anthropic_telemetry`"
    off: "Writes `DISABLE_TELEMETRY=1`."
    on: "Leaves `DISABLE_TELEMETRY` blank."
  - choice: "`feature_flags`"
    off: >-
      Writes `DISABLE_GROWTHBOOK=1`.
      From version 18, it also writes `CLAUDE_CODE_DISABLE_FEATURE_FLAGS=1`.
    on: >-
      Leaves `DISABLE_GROWTHBOOK` blank.
      From version 18, it also leaves `CLAUDE_CODE_DISABLE_FEATURE_FLAGS` blank.
  - choice: "`error_reports`"
    off: "Writes `DISABLE_ERROR_REPORTING=1`."
    on: "Leaves `DISABLE_ERROR_REPORTING` blank."
  - choice: "`official_marketplace_autoinstall`"
    off: "Writes `CLAUDE_CODE_DISABLE_OFFICIAL_MARKETPLACE_AUTOINSTALL=1`."
    on: "Leaves this setting blank."
  - choice: "`connectors`"
    off: "Writes `ENABLE_CLAUDEAI_MCP_SERVERS=false`."
    on: "Writes `ENABLE_CLAUDEAI_MCP_SERVERS=true`."
  - choice: "`fast_mode`"
    off: "Writes `CLAUDE_CODE_DISABLE_FAST_MODE=1`."
    on: >-
      Leaves `CLAUDE_CODE_DISABLE_FAST_MODE` blank.
      From release 0.18.0, it also writes `CLAUDE_CODE_SKIP_FAST_MODE_NETWORK_ERRORS=1`, for each schema version.
  - choice: "`bug_command`"
    off: "Writes `DISABLE_BUG_COMMAND=1`."
    on: >-
      Leaves `DISABLE_BUG_COMMAND` blank.
      `/bug` uploads the conversation to Anthropic.
  - choice: "`feedback_command`"
    off: "Writes `DISABLE_FEEDBACK_COMMAND=1`."
    on: >-
      Leaves `DISABLE_FEEDBACK_COMMAND` blank.
      `/feedback` uploads the conversation to Anthropic.
  - choice: "`feedback_survey`"
    off: "Writes `CLAUDE_CODE_DISABLE_FEEDBACK_SURVEY=1`."
    on: >-
      Leaves `CLAUDE_CODE_DISABLE_FEEDBACK_SURVEY` blank.
      The survey sends session ratings to Anthropic.
  - choice: "`cost_warnings`"
    off: "Writes `DISABLE_COST_WARNINGS=1`."
    on: "Leaves `DISABLE_COST_WARNINGS` blank."
  - choice: "`webfetch_preflight`"
    off: "Writes `skipWebFetchPreflight: true`."
    on: "Writes `skipWebFetchPreflight: false`."
  - choice: "`auto_mode_gateway_check`"
    off: >-
      Version 18 and later.
      Writes `CLAUDE_CODE_AUTO_MODE_SERVER=1`, so auto mode asks the model API for its verdict.
      A model that isn't Claude doesn't give one, so auto mode then asks about or denies each checked action.
      You can't combine it with `experimental_betas: false` in `request_shape`.
    on: >-
      Version 18 and later.
      Writes `CLAUDE_CODE_AUTO_MODE_SERVER=0`, so {{ site.claude_code }} sends the auto mode check to the `auto_mode` model through the gateway.
{% endtable %}

From version 18, `profile activate` writes `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC` blank, regardless of `auto_updates`, whenever the profile sets `true` for `anthropic_telemetry`, `feature_flags`, `error_reports`, `bug_command`, `feedback_command`, or `feedback_survey`, sets `artifact: true` in a `subscription` profile, or sets an eligible `advisor: true` on `anthropic-messages` (with `experimental_betas`, `feature_flags`, and `anthropic_telemetry` not `false`).
A shell export then can't turn those features off.
In the Claude Desktop app or a self-hosted environment runner, the launch environment [takes precedence](https://code.claude.com/docs/en/settings-reference#how-env-values-interact-with-your-shell) over settings, so a `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC` value set there stays on even when activation writes the switch blank.
While activation writes the switch blank, `auto_updates: false` turns off only automatic updates of {{ site.claude_code }}, its plugins, and its marketplaces, unless `FORCE_AUTOUPDATE_PLUGINS=1` is set to restore plugin auto-updates.
Other nonessential background traffic resumes where each feature's own conditions apply.
Choices set to `false` keep their own traffic off, and {{ site.claude_code }} still skips the [fast mode availability check](https://code.claude.com/docs/en/fast-mode#fast-mode-is-currently-unavailable) when `ANTHROPIC_BASE_URL` points to the gateway and `ANTHROPIC_API_KEY` is a gateway-issued key not in the format of an Anthropic API key.

When the profile omits `tool_search`, {{ site.claude_code }} keeps its default, which loads every tool at startup behind a gateway.

#### Request shape

`request_shape` changes the requests that {{ site.claude_code }} sends, for a gateway or a model that refuses some of them.
Each field is optional, but the block needs at least one.

{% table %}
columns:
  - title: Field
    key: field
  - title: Description
    key: description
rows:
  - field: "`experimental_betas`"
    description: "`false` writes `CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS=1` and `ENABLE_TOOL_SEARCH=false`."
  - field: "`betas`"
    description: >-
      A list of beta names that activation writes to `ANTHROPIC_BETAS`.
      1 to 16 names, each unique and 1 to 64 characters of lowercase letters, digits and hyphens.
      A name starts and ends with a letter or a digit.
  - field: "`thinking`"
    description: "`false` writes `CLAUDE_CODE_DISABLE_THINKING=1` and `MAX_THINKING_TOKENS=0`."
  - field: "`interleaved_thinking`"
    description: "`false` writes `DISABLE_INTERLEAVED_THINKING=1`."
  - field: "`prompt_caching`"
    description: >-
      `off` writes `DISABLE_PROMPT_CACHING=1`.
      `5m` or `1h` writes `CLAUDE_CODE_PROMPT_CACHE_TTL` and `CLAUDE_CODE_SUBAGENT_PROMPT_CACHE_TTL`.
  - field: "`nonstreaming_fallback`"
    description: "`false` writes `CLAUDE_CODE_DISABLE_NONSTREAMING_FALLBACK=1`."
  - field: "`extra_body`"
    description: >-
      A JSON object with at least one field, that activation writes to `CLAUDE_CODE_EXTRA_BODY`.
      Without spaces between the tokens, it is up to 4096 bytes of printable ASCII.
      Each key appears once in its object, also in a nested object.
  - field: "`artifact`"
    description: >-
      Only in the top-level `request_shape` of versions 8 to 11.
      Activation ignores it.
      It stays so that older profiles still import.
{% endtable %}

#### Model metadata

`model_metadata` maps a gateway model ID to how the {{ site.claude_code }} `/model` picker describes it.
It has 1 to 64 entries.
Each model ID is 1 to 128 bytes, and each entry sets at least one field.
A value here takes precedence over the value from the gateway model list.

{% table %}
columns:
  - title: Field
    key: field
  - title: Description
    key: description
rows:
  - field: "`behaves_as`"
    description: >-
      The Claude model ID that the gateway model acts like.
      It starts with `claude-`.
  - field: "`max_input_tokens`"
    description: "The largest input that the model accepts, from 8192 to 10000000 tokens."
  - field: "`max_tokens`"
    description: "The largest output that the model writes, from 4096 to 10000000 tokens."
  - field: "`web_search`"
    description: "Whether the model serves the web search tool."
{% endtable %}

#### Pricing

`pricing` sets the prices that {{ site.claude_code }} uses to show the cost of a session.
The block sets `multiplier`, `models` or both.

{% table %}
columns:
  - title: Field
    key: field
  - title: Description
    key: description
rows:
  - field: "`multiplier`"
    description: >-
      A number greater than 0 and up to 10 that each price is multiplied by, both the prices here and the prices from the gateway model list.
      The default is 1.
  - field: "`models`"
    description: >-
      Maps a gateway model ID to its `input`, `output`, `cache_read` and `cache_write` prices, in USD for each million tokens.
      Each model sets all four prices, from 0 to 10000.
      Model IDs are unique without regard to case, and can't end with `[1m]`.
      A price here takes precedence over the price from the gateway model list.
{% endtable %}

#### Telemetry

`telemetry` points {{ site.claude_code }} at your OpenTelemetry collector:

{% table %}
columns:
  - title: Field
    key: field
  - title: Description
    key: description
rows:
  - field: "`endpoint`"
    description: >-
      Required.
      The URL of the collector, up to 512 characters, without user information, a query or a fragment.
      It uses `https://`, or `http://` for a collector on this computer.
  - field: "`protocol`"
    description: "`http/protobuf`, the default, `http/json`, or `grpc`."
  - field: "`resource_attributes`"
    description: >-
      1 to 8 names and values that {{ site.claude_code }} adds to each data point.
      A name is 1 to 64 characters of letters, digits, `.`, `_` and `-`.
      A value is 1 to 64 visible ASCII characters, without `,` or `=`.
{% endtable %}

## Attribution

`attribution` declares HTTP headers that agent CLIs send with each request for gateway spend grouping.
Its only field, `headers`, maps 1 to 8 header names to values.
The gateway reads `Ai-Cost-<name>` headers as cost tags.

A header name is an HTTP token of up to 64 bytes, and appears once without regard to case.
A value is 1 to 128 printable ASCII characters.
These header names are reserved, in any case: `Authorization`, `Connection`, `Cookie`, `Content-Encoding`, `Content-Length`, `Content-Type`, `Expect`, `Host`, `Keep-Alive`, `Proxy-Authenticate`, `Proxy-Authorization`, `Set-Cookie`, `TE`, `Trailer`, `Transfer-Encoding`, `Upgrade`, `User-Agent` and `X-Api-Key`.

{{site.kong_harnesses}} ignores `caller` from older profiles so they still import.

## MCP servers

`mcp_servers` maps 1 to 32 server names to gateway MCP servers for {{ site.claude_code }}.
Each name is 1 to 32 characters of letters, digits, `-`, and `_`.

{% table %}
columns:
  - title: Field
    key: field
  - title: Description
    key: description
rows:
  - field: "`path`"
    description: >-
      Required.
      The path of the server on the gateway origin, 2 to 256 characters.
      It starts with `/` and doesn't end with `/`.
      Each segment uses letters, digits and `-._~`, and isn't `.` or `..`.
      Each server has its own path.
  - field: "`sign_in`"
    description: "Not set to send the model sign-in, `oauth` for a server that runs its own OAuth sign-in, or `key` for a server that takes a key from you."
  - field: "`oauth_client_id`, `oauth_callback_port`"
    description: >-
      For `oauth`, and refused for other servers.
      Both are optional.
      Set them to the client that you registered for {{ site.claude_code }} with the identity provider of the server, when that provider doesn't let {{ site.claude_code }} register a client.
      The client ID is up to 256 visible ASCII characters.
      The port is from 0 to 65535, and `0` is the same as no port: `profile activate` then writes no callback port.
  - field: "`key_header`"
    description: >-
      For `key`.
      The header that carries the key, an HTTP token of up to 64 bytes.
      The default is `apikey`.
      `Authorization`, `Cookie`, `Host`, `Content-Length`, `Transfer-Encoding` and `Connection` are refused.
{% endtable %}

Each sign-in setting has its own rules:

* A `static_key` profile lists only `oauth` and `key` servers.
* An `environment_key` profile lists only `oauth` servers.
* A `subscription` profile can't list servers.
* A profile with an `http://` gateway can't list `oauth` servers.
* Two `key` servers can't have names that differ only in case.
