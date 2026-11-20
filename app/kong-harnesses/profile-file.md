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

A profile is a JSON document that tells {{site.kong_harnesses}} where {{site.ai_gateway}} is, how developers sign in, and how to set up each agent CLI. It holds no secrets, so an administrator can share one file with every developer. [`kong-harnesses profile create`](/kong-harnesses/profile/create/) writes a profile for you, and [`kong-harnesses profile import`](/kong-harnesses/profile/import/) installs one from a file or an HTTPS URL.

The file is JSON of up to 64 KB, and {{site.kong_harnesses}} refuses a field that it doesn't know. To see an installed profile, run:

```sh
kong-harnesses profile get <name> -o json
```

## Example

This profile signs developers in with an identity provider and sets up {{ site.claude_code }} and Codex:

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

## Schema versions

`schema_version` says which fields the profile can use. Each {{site.kong_harnesses}} release reads every schema version up to its own newest one, and refuses a profile with a newer version. `profile create` writes the newest version that its release reads, so an older release can't import that profile. To give one profile to developers on different releases, use the oldest version that has the fields you need.

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
    adds: "`routes`, `clients`, `gateway_ca_bundle`, `sign_in` and `mcp_servers`. The {{ site.claude_code }} settings move from the top level into `clients.claude-code`, and every {{ site.claude_code }} model role is required."
    release: "0.6.0 and later"
  - version: "13"
    adds: "The `codex`, `opencode` and `omp` client blocks."
    release: "0.7.0 and later"
  - version: "14"
    adds: "The {{ site.claude_code }} choices, such as `hint_headers` and `connectors`. Each choice is optional."
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
    adds: "`auto_mode_gateway_check`, and a change to what `auto_updates: false` writes."
    release: "0.18.0 and later"
{% endtable %}

Some values need a newer release than their schema version:

* The `foundry-messages` and `bedrock-mantle-messages` route protocols need 0.8.0 or later.
* `sign_in` set to `static_key`, and `mcp_servers`, need 0.14.0 or later.
* `sign_in` set to `subscription` needs 0.17.0 or later.

## Top-level fields

{% table %}
columns:
  - title: Field
    key: field
  - title: Description
    key: description
rows:
  - field: "`schema_version`"
    description: "Required. The schema version of the document. See [Schema versions](#schema-versions)."
  - field: "`name`"
    description: "Required. The name that commands take with `--profile`. 1 to 63 characters: lowercase letters, digits and hyphens. It starts with a letter, and ends with a letter or a digit."
  - field: "`display_name`"
    description: "A name for people to read. Up to 80 characters."
  - field: "`description`"
    description: "A longer description. Up to 240 characters."
  - field: "`gateway_origin`"
    description: "Required. The origin of {{site.ai_gateway}}, with no path. It uses `https://`. Only a gateway on this computer, on `localhost`, `127.0.0.1` or `[::1]`, can use `http://`."
  - field: "`gateway_ca_bundle`"
    description: "Version 12 and later. The PEM text of the certificate authorities that sign the gateway certificate, for a gateway with a private certificate authority."
  - field: "`sign_in`"
    description: "Version 12 and later. How developers get a credential. See [Sign-in fields](#sign-in-fields)."
  - field: "`routes`"
    description: "Required from version 12. The gateway routes that the clients use. See [Routes](#routes)."
  - field: "`clients`"
    description: "Required from version 12, with at least one client block. See [Clients](#clients)."
  - field: "`mcp_servers`"
    description: "Version 12 and later. MCP servers that the gateway serves to {{ site.claude_code }}. See [MCP servers](#mcp-servers)."
  - field: "`attribution`"
    description: "Version 3 and later. Headers that tell the gateway who a request belongs to. See [Attribution](#attribution)."
{% endtable %}

Versions 2 to 11 keep the {{ site.claude_code }} settings at the top level: `models`, `telemetry`, `request_shape`, `auto_updates`, `model_metadata` and `pricing`. From version 12, these fields are refused at the top level and go in `clients.claude-code`.

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
    description: "Developers sign in with your OpenID Connect identity provider through `kong-harnesses login`. The identity provider fields are required."
  - value: "`static_key`"
    description: "Each developer saves a key from you with `kong-harnesses login`. The profile has no identity provider fields."
  - value: "`environment_key`"
    description: "Version 17 and later. Each command reads the key from `KONG_HARNESSES_STATIC_KEY`, for example in a CI job. The profile has no identity provider fields."
  - value: "`subscription`"
    description: "{{ site.claude_code }} sends each developer's own Claude subscription sign-in to the gateway. The identity provider fields are required."
{% endtable %}

The identity provider fields:

{% table %}
columns:
  - title: Field
    key: field
  - title: Description
    key: description
rows:
  - field: "`issuer`"
    description: "Required. The issuer URL of the identity provider."
  - field: "`discovery_url`"
    description: "Required. The issuer URL followed by `/.well-known/openid-configuration`."
  - field: "`authorization_endpoint`, `token_endpoint`, `jwks_uri`"
    description: "Required. The endpoints from the discovery document."
  - field: "`revocation_endpoint`"
    description: "Version 4 and later. The endpoint that `logout` uses to revoke the sign-in."
  - field: "`client_id`"
    description: "Required. The ID of the public client that you registered for {{site.kong_harnesses}}."
  - field: "`redirect_uri`"
    description: "Where the identity provider sends the browser after sign-in. The default is `http://localhost:9876/callback`. Another value must use `http://` on `localhost`, `127.0.0.1` or `[::1]` with a port."
  - field: "`audience`"
    description: "Required. The audience that the gateway accepts in a token."
  - field: "`audience_parameter`"
    description: "Version 5 and later. How the sign-in request sends the audience: `resource`, the default, `audience`, or `none`."
  - field: "`public_client_evidence`"
    description: "Version 6 and later. Set to `deployment` when the discovery document doesn't list the `none` token endpoint authentication method, and your deployment shows in another way that the client is public."
  - field: "`scopes`"
    description: "Required. The scopes that the sign-in requests, 2 to 16 of them, with `openid` and `offline_access` among them. `profile create` writes `openid`, `profile`, `email` and `offline_access` unless you give `--scope`."
  - field: "`max_access_token_lifetime_seconds`"
    description: "The longest access token lifetime that {{site.kong_harnesses}} accepts, from 360 to 86400. The default is 3600. A changed value needs a new `login`."
{% endtable %}

## Routes

`routes` maps a route name to the protocol that the gateway serves on it. A profile has up to 16 routes, and each client block names one of them in its `route` field.

{% table %}
columns:
  - title: Field
    key: field
  - title: Description
    key: description
rows:
  - field: "`protocol`"
    description: "Required. `anthropic-messages` for the Anthropic API, `foundry-messages` for Microsoft Foundry, `bedrock-mantle-messages` for Amazon Bedrock Mantle, `openai-responses` for Codex, or `gateway-plugin` for OpenCode."
  - field: "`tool_reference`"
    description: "Only for the Anthropic API protocols. `true` when the route serves the tool references that {{ site.claude_code }} tool search sends."
  - field: "`advisor`"
    description: "Only for the Anthropic API protocols. `true` when the route serves the {{ site.claude_code }} advisor tool."
  - field: "`artifact`"
    description: "Only for the Anthropic API protocols. Kept so that older profiles still import. It has no effect."
{% endtable %}

## Clients

`clients` has one block for each agent CLI that `profile activate` sets up. Each block has a `route` field, which names a route with the protocol that the client speaks:

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

The `hermes` block also needs `model`, the gateway model that Hermes uses. A profile with a `hermes` block signs in with an identity provider, sets `audience_parameter` to `audience`, and requests exactly the scopes `openid`, `profile`, `email` and `offline_access`. A profile with an `opencode` block doesn't use `static_key` or `environment_key`. A `subscription` profile has only a `claude-code` block, on an `anthropic-messages` route. `profile activate` doesn't set up pi for a profile with `attribution`.

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
    description: "Required. The route that {{ site.claude_code }} uses."
  - field: "`models`"
    description: "Required. The gateway model aliases. See [Models](#models)."
  - field: "`telemetry`"
    description: "Where {{ site.claude_code }} sends OpenTelemetry data. See [Telemetry](#telemetry)."
  - field: "`request_shape`"
    description: "Changes to the requests that {{ site.claude_code }} sends. See [Request shape](#request-shape)."
  - field: "`model_metadata`"
    description: "How the `/model` picker describes a gateway model. See [Model metadata](#model-metadata)."
  - field: "`pricing`"
    description: "The prices that {{ site.claude_code }} uses to show cost. See [Pricing](#pricing)."
  - field: "`auto_updates` and the other choices"
    description: "See [Claude Code choices](#claude-code-choices)."
{% endtable %}

#### Models

`profile activate` writes each alias into the {{ site.claude_code }} settings. Each alias is 1 to 128 characters. From version 12, every role except `max_context_tokens` is required.

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
    setting: "`CLAUDE_CODE_MAX_CONTEXT_TOKENS`, the context window of the gateway models, from 8192 to 10000000. Set it when the models hold less than {{ site.claude_code }} expects."
{% endtable %}

#### Claude Code choices

From version 14, each choice is optional, and a choice that the profile leaves out changes nothing. Versions 12 and 13 require `auto_updates`, `tool_search`, `advisor` and `artifact`, and refuse the other choices.

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
    off: "Writes `DISABLE_AUTOUPDATER=1`. From version 18, it also writes `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1`, unless another choice turns on a feature that this setting turns off."
    on: "Writes nothing."
  - choice: "`tool_search`"
    off: "Writes `ENABLE_TOOL_SEARCH=false`."
    on: "Writes `ENABLE_TOOL_SEARCH=true`. The route needs `tool_reference: true`."
  - choice: "`advisor`"
    off: "Writes `CLAUDE_CODE_DISABLE_ADVISOR_TOOL=1`."
    on: "Leaves the advisor tool on. The route needs `advisor: true`."
  - choice: "`artifact`"
    off: "No effect."
    on: "No effect. The route needs `artifact: true`."
  - choice: "`hint_headers`"
    off: "Writes `CLAUDE_CODE_GATEWAY_HINT_HEADERS=0`."
    on: "Writes `CLAUDE_CODE_GATEWAY_HINT_HEADERS=1`."
  - choice: "`anthropic_telemetry`"
    off: "Writes `DISABLE_TELEMETRY=1`."
    on: "Leaves `DISABLE_TELEMETRY` blank."
  - choice: "`feature_flags`"
    off: "Writes `DISABLE_GROWTHBOOK=1`, and from version 18 also `CLAUDE_CODE_DISABLE_FEATURE_FLAGS=1`."
    on: "Leaves these settings blank."
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
    on: "Leaves `CLAUDE_CODE_DISABLE_FAST_MODE` blank, and writes `CLAUDE_CODE_SKIP_FAST_MODE_NETWORK_ERRORS=1`."
  - choice: "`bug_command`"
    off: "Writes `DISABLE_BUG_COMMAND=1`."
    on: "Leaves `DISABLE_BUG_COMMAND` blank."
  - choice: "`feedback_command`"
    off: "Writes `DISABLE_FEEDBACK_COMMAND=1`."
    on: "Leaves `DISABLE_FEEDBACK_COMMAND` blank."
  - choice: "`feedback_survey`"
    off: "Writes `CLAUDE_CODE_DISABLE_FEEDBACK_SURVEY=1`."
    on: "Leaves `CLAUDE_CODE_DISABLE_FEEDBACK_SURVEY` blank."
  - choice: "`cost_warnings`"
    off: "Writes `DISABLE_COST_WARNINGS=1`."
    on: "Leaves `DISABLE_COST_WARNINGS` blank."
  - choice: "`webfetch_preflight`"
    off: "Writes `skipWebFetchPreflight: true`."
    on: "Writes `skipWebFetchPreflight: false`."
  - choice: "`auto_mode_gateway_check`"
    off: "Version 18 and later. Writes `CLAUDE_CODE_AUTO_MODE_SERVER=1`. You can't combine it with `experimental_betas: false` in `request_shape`."
    on: "Version 18 and later. Auto mode runs its check through the gateway."
{% endtable %}

#### Request shape

`request_shape` changes the requests that {{ site.claude_code }} sends, for a gateway or a model that refuses some of them. Each field is optional, but the block needs at least one.

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
    description: "A list of beta names that activation writes to `ANTHROPIC_BETAS`."
  - field: "`thinking`"
    description: "`false` writes `CLAUDE_CODE_DISABLE_THINKING=1` and `MAX_THINKING_TOKENS=0`."
  - field: "`interleaved_thinking`"
    description: "`false` writes `DISABLE_INTERLEAVED_THINKING=1`."
  - field: "`prompt_caching`"
    description: "`off` writes `DISABLE_PROMPT_CACHING=1`. `5m` or `1h` writes `CLAUDE_CODE_PROMPT_CACHE_TTL` and `CLAUDE_CODE_SUBAGENT_PROMPT_CACHE_TTL`."
  - field: "`nonstreaming_fallback`"
    description: "`false` writes `CLAUDE_CODE_DISABLE_NONSTREAMING_FALLBACK=1`."
  - field: "`extra_body`"
    description: "A JSON object that activation writes to `CLAUDE_CODE_EXTRA_BODY`."
  - field: "`artifact`"
    description: "Kept so that older profiles still import. It has no effect."
{% endtable %}

#### Model metadata

`model_metadata` maps a gateway model ID to how the {{ site.claude_code }} `/model` picker describes it. A value here wins over the value from the gateway model list.

{% table %}
columns:
  - title: Field
    key: field
  - title: Description
    key: description
rows:
  - field: "`behaves_as`"
    description: "The Claude model ID that the gateway model acts like."
  - field: "`max_input_tokens`"
    description: "The largest input that the model accepts, in tokens."
  - field: "`max_tokens`"
    description: "The largest output that the model writes, in tokens."
  - field: "`web_search`"
    description: "Whether the model serves the web search tool."
{% endtable %}

#### Pricing

`pricing` sets the prices that {{ site.claude_code }} uses to show the cost of a session:

{% table %}
columns:
  - title: Field
    key: field
  - title: Description
    key: description
rows:
  - field: "`multiplier`"
    description: "A number above 0 and up to 10 that each price is multiplied by, both the prices here and the prices from the gateway model list."
  - field: "`models`"
    description: "Maps a gateway model ID to its `input`, `output`, `cache_read` and `cache_write` prices, in USD for each million tokens. A price here wins over the price from the gateway model list."
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
    description: "Required. The URL of the collector."
  - field: "`protocol`"
    description: "`http/protobuf`, the default, `http/json`, or `grpc`."
  - field: "`resource_attributes`"
    description: "Up to 8 names and values that {{ site.claude_code }} adds to each data point, each up to 64 characters."
{% endtable %}

## Attribution

`attribution` declares headers that the agent CLIs send with each request, so that the gateway can group the spend. It has one field, `headers`, which maps a header name to its value, with up to 8 headers. Each value is up to 128 characters. A header that carries a credential, such as `Authorization`, is refused. The gateway reads a header named `Ai-Cost-<name>` as a cost tag.

A `caller` field from an older profile is ignored, so that the profile still imports.

## MCP servers

`mcp_servers` maps a server name to an MCP server that the gateway serves to {{ site.claude_code }}. A profile has up to 32 servers, and each name is up to 32 characters.

{% table %}
columns:
  - title: Field
    key: field
  - title: Description
    key: description
rows:
  - field: "`path`"
    description: "Required. The path of the server on the gateway origin, up to 256 characters."
  - field: "`sign_in`"
    description: "Not set to send the model sign-in, `oauth` for a server that runs its own OAuth sign-in, or `key` for a server that takes a key from you."
  - field: "`oauth_client_id`, `oauth_callback_port`"
    description: "For `oauth`. The client that you registered for {{ site.claude_code }} with the identity provider of the server, when that provider doesn't let {{ site.claude_code }} register a client."
  - field: "`key_header`"
    description: "For `key`. The header that carries the key. The default is `apikey`."
{% endtable %}

A `static_key` profile lists only `oauth` and `key` servers. An `environment_key` profile lists no `key` servers, and a `subscription` profile lists no servers.
