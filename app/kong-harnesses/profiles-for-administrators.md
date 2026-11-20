---
title: "{{site.kong_harnesses}} profiles for administrators"
description: "Choose a provider mode, and create and publish a {{site.kong_harnesses}} profile for the developers of your organization."
content_type: reference
layout: reference

products:
  - ai-gateway

works_on:
  - konnect

tools:
  - kong-harnesses

min_version:
  ai-gateway: '2.4'

tags:
  - cli

breadcrumbs:
  - /kong-harnesses/

related_resources:
  - text: Set up {{ site.claude_code }} with kong-harnesses
    url: /ai-gateway/set-up-claude-code-with-kong-harnesses/
  - text: kong-harnesses profile create
    url: /kong-harnesses/profile/create/
  - text: kong-harnesses setup
    url: /kong-harnesses/setup/
  - text: Serve Claude subscriptions and company Claude models on one {{site.ai_gateway}} base URL
    url: /ai-gateway/use-claude-subscriptions-with-ai-gateway/
  - text: kong-harnesses and private certificate authorities
    url: /kong-harnesses/private-certificate-authorities/
  - text: Changes that kong-harnesses makes on a developer's computer
    url: /kong-harnesses/developer-computer-changes/
---

A {{site.kong_harnesses}} profile names the {{site.ai_gateway}} that developers' agent CLIs call, how developers sign in, and the model that {{ site.claude_code }} starts with.
A profile doesn't contain secrets, so you create it once and give the same file to every developer.
Each developer then runs one command, and every computer uses the same gateway and models without editing agent settings files.
For what `setup` saves and writes on each developer's computer, see [Changes that {{site.kong_harnesses}} makes on a developer's computer](/kong-harnesses/developer-computer-changes/).

## Provider modes

The provider mode sets the API format and the model IDs that {{ site.claude_code }} uses with the gateway.
Set it with the `--provider` flag of `profile create`.

{% table %}
columns:
  - title: Mode
    key: mode
  - title: Model ID
    key: model
  - title: Agent CLIs that the profile sets up
    key: clients
  - title: Models in the {{ site.claude_code }} model picker
    key: picker
rows:
  - mode: "`anthropic` (Anthropic API, the default)"
    model: The model name that the gateway serves
    clients: |
      {{ site.claude_code }}, Codex, OpenCode, omp and pi.
      Hermes Agent too, when the profile signs in through an identity provider with `--audience-parameter audience` and the default scopes.
    picker: The built-in models and the models that the gateway lists at `GET /v1/models`
  - mode: "`foundry` (Microsoft Foundry)"
    model: The Foundry deployment name
    clients: "{{ site.claude_code }} only"
    picker: Only the models that the profile names
  - mode: "`mantle` (Amazon Bedrock Mantle)"
    model: The Bedrock model ID
    clients: "{{ site.claude_code }} only"
    picker: Only the models that the profile names
{% endtable %}

Use the `anthropic` mode unless the gateway serves Claude only through Microsoft Foundry or Amazon Bedrock Mantle and you want {{ site.claude_code }} to use that cloud's model IDs.
The `anthropic` mode is the only mode that sets up other agent CLIs, and the only mode in which {{ site.claude_code }} reads the model list from the gateway.
When the gateway lists a new model whose ID contains `claude` or `anthropic`, in any letter case, in a successful `GET /v1/models` response, the model appears in the model picker of the next {{ site.claude_code }} session without a new `setup`.
For a model with another ID, `profile activate` adds a model picker entry from that list, so developers run `kong-harnesses profile activate PROFILE_NAME` again after you add the model.

In the `foundry` and `mantle` modes, the model picker shows only the models that the profile names, so you publish a new profile to add a model.
A profile from `profile create` names one model, the `--model` value, for every {{ site.claude_code }} model role.
To offer more than one model, export the profile as in [Profile hosting](#profile-hosting), set some roles in `clients.claude-code.models` to other model IDs, such as `opus` and `haiku`, and host the edited file.
The model picker shows each model that a role names.

In every mode, {{ site.claude_code }} sends Anthropic Messages API requests to `/v1/messages` on the gateway origin, so the [AI Model](/ai-gateway/entities/ai-model/) that serves {{ site.claude_code }} uses the Anthropic format.
{{ site.claude_code }} names the model that the developer uses in the `model` field of each request, by default the profile's `--model` value.
Add each model ID that the route must accept to `config.route.model.values` of the AI Model, and set `targets[].name` to the upstream deployment name or model ID.
For the `foundry` mode, point the AI Model at your Foundry deployment, as in [Route Claude CLI traffic through {{site.ai_gateway}} and Azure](/ai-gateway/use-claude-code-with-ai-gateway-azure/).
For the `mantle` mode, use a `bedrock` [AI Model Provider](/ai-gateway/entities/ai-model-provider/), and set `targets[].config.endpoint_type: mantle` on the AI Model, as in [Route OpenAI traffic to Amazon Bedrock Mantle](/ai-gateway/route-openai-traffic-to-bedrock-mantle/).
Use `formats: [type: anthropic]` instead of `type: openai`, because the Mantle endpoint accepts the Anthropic format natively.

## Profile creation

Create the profile on your own computer with [`kong-harnesses profile create`](/kong-harnesses/profile/create/).
Run it without flags to answer the questions instead.
For the default or the `subscription` sign-in, `profile create` connects to your identity provider, so your computer must trust its certificate first.
For a private CA, see [{{site.kong_harnesses}} and private certificate authorities](/kong-harnesses/private-certificate-authorities/).

The identity provider needs a public OIDC client, without a client secret, for the authorization code flow with PKCE (S256) and refresh tokens.
Register `http://localhost:9876/callback` as a sign-in redirect URI of the client, or register another loopback URI and pass it with `--redirect-uri`.
For an example with Okta, see [Set up {{ site.claude_code }} with kong-harnesses](/ai-gateway/set-up-claude-code-with-kong-harnesses/).

{% navtabs "provider-mode" %}
{% navtab "Anthropic API" %}

```sh
kong-harnesses profile create \
  --name PROFILE_NAME \
  --issuer ISSUER_URL \
  --client-id CLIENT_ID \
  --audience AUDIENCE \
  --gateway-origin GATEWAY_ORIGIN \
  --model MODEL_NAME
```

{% endnavtab %}
{% navtab "Microsoft Foundry" %}

```sh
kong-harnesses profile create \
  --name PROFILE_NAME \
  --provider foundry \
  --issuer ISSUER_URL \
  --client-id CLIENT_ID \
  --audience AUDIENCE \
  --gateway-origin GATEWAY_ORIGIN \
  --model FOUNDRY_DEPLOYMENT_NAME
```

{% endnavtab %}
{% navtab "Amazon Bedrock Mantle" %}

```sh
kong-harnesses profile create \
  --name PROFILE_NAME \
  --provider mantle \
  --issuer ISSUER_URL \
  --client-id CLIENT_ID \
  --audience AUDIENCE \
  --gateway-origin GATEWAY_ORIGIN \
  --model BEDROCK_MODEL_ID
```

{% endnavtab %}
{% endnavtabs %}

In PowerShell, end each continued line with a backtick (`` ` ``) instead of `\`, or write the command on one line.

{% table %}
columns:
  - title: Placeholder
    key: placeholder
  - title: Value
    key: value
rows:
  - placeholder: "`PROFILE_NAME`"
    value: |
      The name of the profile.
      Developers type it to confirm the install.
  - placeholder: "`ISSUER_URL`"
    value: The `https://` OIDC issuer URL of your identity provider.
  - placeholder: "`CLIENT_ID`"
    value: The ID of the public OIDC client.
  - placeholder: "`AUDIENCE`"
    value: The audience of the access token that the gateway checks, as an absolute URI such as `api://default`.
  - placeholder: "`GATEWAY_ORIGIN`"
    value: |
      The `https://` origin of the gateway without a path, such as `https://ai-gateway.example.com`.
      Developers' computers must trust the gateway certificate.
      For a private CA, see [{{site.kong_harnesses}} and private certificate authorities](/kong-harnesses/private-certificate-authorities/).
  - placeholder: "`MODEL_NAME`, `FOUNDRY_DEPLOYMENT_NAME` or `BEDROCK_MODEL_ID`"
    value: The model ID that the profile sets for every {{ site.claude_code }} model role, in the format of the provider mode.
{% endtable %}

`--audience-parameter` sets how the sign-in request names the audience: `resource` (the default), `audience` or `none`.
Use the value that your identity provider reads.

When you give these flags, `profile create` reads the endpoints of your identity provider from its OIDC discovery document, saves the profile, and installs it on your computer.
For a `static-key` or `environment-key` profile, it skips OIDC discovery.
It then sends an empty test request without a sign-in to the gateway route of each agent CLI that the profile sets up.
When the gateway answers that no route matches, `profile create` warns about that route and keeps the agent CLI in the profile.
A route can match on the credential or on headers that only the agent CLI sends, so check each warned route with a signed-in prompt from that agent CLI.
For more options, such as MCP servers that the gateway serves, except in a `subscription` profile, and the {{ site.claude_code }} telemetry to Anthropic, see the [`profile create` reference](/kong-harnesses/profile/create/).

### Sign-in kinds

By default, developers sign in through your identity provider, and the gateway checks their access token.
The `--sign-in` flag selects another kind of sign-in:

{% table %}
columns:
  - title: "`--sign-in`"
    key: kind
  - title: What developers use
    key: use
  - title: Limits
    key: limits
rows:
  - kind: "`static-key`"
    use: |
      A key that you give each developer, without an identity provider.
      Leave out `--issuer`, `--client-id` and `--audience`.
      `login` asks for the key.
    limits: The profile doesn't set up OpenCode or Hermes Agent.
  - kind: "`environment-key`"
    use: |
      The same kind of key, read from `KONG_HARNESSES_STATIC_KEY` on every call, for a CI job.
      Leave out `--issuer`, `--client-id` and `--audience`.
      Set the variable on the `profile activate` step and on the step that runs {{ site.claude_code }}.
      On Linux, when `XDG_RUNTIME_DIR` isn't set, create a private directory with `mktemp -d` and set `XDG_RUNTIME_DIR` to it before you run {{site.kong_harnesses}}.
    limits: The profile doesn't set up OpenCode or Hermes Agent.
  - kind: "`subscription`"
    use: |
      Each developer's own Claude subscription, with the same `--issuer`, `--client-id` and `--audience` flags as the default sign-in.
      Each developer also signs in to {{ site.claude_code }} with their subscription.
      See [Serve Claude subscriptions and company Claude models](/ai-gateway/use-claude-subscriptions-with-ai-gateway/).
    limits: |
      Needs the `anthropic` mode.
      The profile sets up only {{ site.claude_code }}, and can't list gateway MCP servers.
      Update {{site.kong_harnesses}} on each developer's computer first, because a release from before subscription sign-in refuses to import the profile.
{% endtable %}

In the `anthropic` mode, {{ site.claude_code }} sends a static key in both the `Authorization: Bearer` and the `x-api-key` headers.
In the `foundry` and `mantle` modes, it sends the key only in `Authorization: Bearer`.
To accept the key in every mode, give the AI Model a `key-auth` [AI Auth Strategy](/ai-gateway/entities/ai-auth-strategy/#api-key-authentication) that reads both headers and hides the key from the model provider:

```yaml
config:
  key_names: [Authorization, x-api-key]
  header_auth_schemes: [Bearer]
  hide_credentials: true
```

When a header value starts with one of the `header_auth_schemes`, such as `Bearer`, followed by a space, the rest of the value is the key.
A header value without a scheme is used as it is.
For a complete example, see [Set up {{ site.claude_code }} with a static key](/ai-gateway/set-up-claude-code-with-a-static-key/).

## Profile hosting

Export the installed profile as a JSON file with [jq](https://jqlang.org/):

```sh
kong-harnesses profile get PROFILE_NAME -o json | jq '.profile' > PROFILE_NAME.json
```

In Windows PowerShell 5.1, `>` writes UTF-16, and `profile import` refuses that file.
Run the command in PowerShell 7 or later, which writes UTF-8.

Give the file to developers, or host it at an HTTPS URL.

{:.warning}
> Host the profile where only administrators can change it.
> The profile names the gateway and the identity provider that get each developer's sign-in, so anyone who can change the file can send those sign-ins somewhere else.

{{site.kong_harnesses}} downloads a profile only when the URL and the server meet these rules:

{% table %}
columns:
  - title: Item
    key: item
  - title: Rule
    key: rule
rows:
  - item: URL
    rule: |
      An `https://` URL of at most 2,048 bytes, without a query string, a fragment, a user name or password, an explicit `:443` port, or `.` and `..` path segments.
      Use a lowercase host name without a trailing dot, and uppercase hex digits in percent escapes.
  - item: Redirects
    rule: At most 3, with status `301`, `302`, `303`, `307` or `308`, all to the same origin.
  - item: Response
    rule: |
      Status `200` with exactly one `Content-Type: application/json` header, with or without `charset=utf-8`.
      The server must not compress the response.
      The response headers are at most 16,384 bytes.
  - item: Size
    rule: At most 65,536 bytes.
  - item: Time
    rule: 5 seconds each to connect, to finish the TLS handshake and to send the response headers, and 10 seconds for the whole download.
  - item: Access
    rule: "{{site.kong_harnesses}} doesn't send cookies or credentials, so the server must answer without a sign-in."
  - item: Network
    rule: |
      TLS 1.2 or later.
      {{site.kong_harnesses}} trusts the server certificate through the system trust store, and uses the proxy from `HTTPS_PROXY` and `NO_PROXY`.
{% endtable %}

To change the profile, publish the new file at the same URL or give developers the new file.
When the change keeps the profile's security identity, developers run the same `setup` command again.
The security identity includes the gateway origin, the issuer and its endpoints, including the revocation endpoint, the client ID, the redirect URI, the audience, the audience parameter, the scopes, the longest access token lifetime, the public client evidence, the sign-in kind, and a digest of the profile's gateway CA bundle, if it has one.
When the change alters the security identity, `setup` stops while an agent CLI still uses the old profile.
Developers then run `kong-harnesses profile cleanup` and run `setup` again, which signs them in again.
