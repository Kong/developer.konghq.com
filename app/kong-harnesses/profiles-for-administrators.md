---
title: "{{site.kong_harnesses}} profiles for administrators"
description: "Choose a provider mode, create and publish a {{site.kong_harnesses}} profile, see what setup changes on each developer's computer, and make each {{ site.claude_code }} install trust a private certificate authority."
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
---

A {{site.kong_harnesses}} profile names the {{site.ai_gateway}} that developers' agent CLIs call, how developers sign in, and the model that {{ site.claude_code }} starts with.
A profile doesn't contain secrets, so you create it once and give the same file to every developer.
Each developer then runs one command, and every computer uses the same gateway and models without editing agent settings files.

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
When the gateway lists a new model whose ID contains `claude` or `anthropic` in a successful `GET /v1/models` response, the model shows up in the next {{ site.claude_code }} session without a new `setup`.
For a model with another ID, `profile activate` adds a model picker entry from that list, so developers run `kong-harnesses profile activate` again after you add the model.

In the `foundry` and `mantle` modes, the model picker shows only the models that the profile names, so you publish a new profile to add a model.
A profile from `profile create` names one model, the `--model` value.

In every mode, {{ site.claude_code }} sends Anthropic Messages API requests to `/v1/messages` on the gateway origin, so the AI Model that serves {{ site.claude_code }} uses the Anthropic format.
{{ site.claude_code }} names the profile's `--model` value in the `model` field of each request, so add that value to `config.route.model.values` of the AI Model, and keep the deployment name or the upstream model ID in `targets[].name`.
For the `foundry` mode, point the AI Model at your Foundry deployment, as in [Route Claude CLI traffic through {{site.ai_gateway}} and Azure](/ai-gateway/use-claude-code-with-ai-gateway-azure/).
For the `mantle` mode, use a `bedrock` AI Model Provider, and set `targets[].config.endpoint_type: mantle` on the AI Model, as in [Route OpenAI traffic to Amazon Bedrock Mantle](/ai-gateway/route-openai-traffic-to-bedrock-mantle/).
Use `formats: [type: anthropic]` instead of `type: openai`, because the Mantle endpoint accepts the Anthropic format natively.

## Profile creation

Create the profile on your own computer with [`kong-harnesses profile create`](/kong-harnesses/profile/create/).
Run it without flags to answer the questions instead.
`profile create` connects to your identity provider, so your computer must trust its certificate first, see [Private certificate authorities](#private-certificate-authorities).

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
  - placeholder: "`MODEL_NAME`, `FOUNDRY_DEPLOYMENT_NAME` or `BEDROCK_MODEL_ID`"
    value: The model ID that the profile sets for every {{ site.claude_code }} model role, in the format of the provider mode.
{% endtable %}

`--audience-parameter` sets how the sign-in request names the audience: `resource` (the default), `audience` or `none`.
Use the value that your identity provider reads.

With these flags, `profile create` reads the endpoints of your identity provider from its OIDC discovery document, saves the profile, and installs it on your computer.
It then sends an empty test request without a sign-in to the gateway route of each agent CLI that the profile sets up.
When the gateway answers that no route matches, `profile create` warns that the agent CLI may not be able to use the gateway, and keeps the agent CLI in the profile.
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
To accept the key in every mode, set the gateway's `key-auth` [AI Auth Strategy](/ai-gateway/entities/ai-auth-strategy/#api-key-authentication) to read both headers, and to hide the key from the model provider:

```yaml
config:
  key_names: [Authorization, x-api-key]
  header_auth_schemes: [Bearer]
  hide_credentials: true
```

With `header_auth_schemes` set to `Bearer`, the strategy reads the key that follows `Bearer` in the `Authorization` header.
`header_auth_schemes` needs {{site.ai_gateway}} 2.4 or later.
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
The security identity includes the gateway origin, the issuer and its endpoints, the client ID, the redirect URI, the audience, the audience parameter, the scopes and the sign-in kind.
When the change alters the security identity, `setup` stops while an agent CLI still uses the old profile.
Developers then run `kong-harnesses profile cleanup`, run `setup` again, and sign in again.

## What setup changes on a developer's computer

A developer installs the profile with [`kong-harnesses setup`](/kong-harnesses/setup/) and the URL or the file:

```sh
kong-harnesses setup PROFILE_URL
```

```sh
kong-harnesses setup ./PROFILE_NAME.json
```

`setup` runs `profile import`, `login` and `profile activate`, in this order.
Before it installs the profile, it shows the gateway and the identity provider of the profile, and asks the developer to type the profile name.
It skips `login` for an `environment-key` profile, and when the only agent CLIs that it sets up are OpenCode and Hermes Agent, which sign in through their own plugins.
Without `--client`, `setup` sets up every installed agent CLI that the profile lists.
Add `--client claude-code` to set up only {{ site.claude_code }}.

With `--auto-approve`, `setup` doesn't ask, and prints the same summary to stderr.
Use `--auto-approve` only in an onboarding script that your organization owns, because it skips the developer's check of the gateway and the identity provider.
When a step fails, the developer runs the same command again, and `setup` continues from that step.
When the gateway refuses an agent CLI, for example because its route is missing or refuses the sign-in, `setup` leaves that agent CLI out and names the fix.
Fix the route or the sign-in, then run `setup` again.

`login` saves the sign-in in the desktop's native vault: only the renewal credential, or the static key.
`profile activate` writes these keys to the {{ site.claude_code }} user settings, `~/.claude/settings.json`, or `settings.json` in `CLAUDE_CONFIG_DIR` when it's set:

{% table %}
columns:
  - title: Key
    key: key
  - title: Value
    key: value
rows:
  - key: "`apiKeyHelper`"
    value: |
      A command that runs `kong-harnesses credential` for the profile.
      {{ site.claude_code }} runs it to get a short-lived access token, or the static key of a key profile.
      A `subscription` profile doesn't write it, and removes an `apiKeyHelper` that the file already contains until cleanup.
  - key: "`env.ANTHROPIC_AUTH_TOKEN` and `env.ANTHROPIC_API_KEY`"
    value: Empty, so a key in the shell doesn't replace the sign-in.
  - key: "Model keys, such as `env.ANTHROPIC_MODEL`"
    value: The models that the profile names.
  - key: "Feature switches, such as `env.DISABLE_TELEMETRY`"
    value: "The {{ site.claude_code }} features that the profile turns off or on."
  - key: "`env.ANTHROPIC_CUSTOM_HEADERS`"
    value: |
      The headers that the profile's `attribution` block names, when the profile has one.
      For a `subscription` profile, also the `x-kong-id-token` header.
  - key: "`hooks`"
    value: |
      Only for a `subscription` profile.
      A hook on {{ site.claude_code }} session events writes a short-lived access token from the identity provider to the `x-kong-id-token` header, so the gateway knows which developer sent each request.
{% endtable %}

Each provider mode also writes its own keys:

{% table %}
columns:
  - title: Mode
    key: mode
  - title: Keys
    key: keys
rows:
  - mode: "`anthropic`"
    keys: "`env.ANTHROPIC_BASE_URL` set to the gateway origin, and `env.CLAUDE_CODE_ENABLE_GATEWAY_MODEL_DISCOVERY` set to `1`."
  - mode: "`foundry`"
    keys: |
      `env.CLAUDE_CODE_USE_FOUNDRY` and `env.CLAUDE_CODE_SKIP_FOUNDRY_AUTH` set to `1`, and `env.ANTHROPIC_FOUNDRY_BASE_URL` set to the gateway origin.
      The model picker and the `availableModels` allowlist show only the profile's models, `replaceBuiltInOptions` hides the built-in models, and `env.ANTHROPIC_DEFAULT_MODEL` is the profile's default model.
  - mode: "`mantle`"
    keys: |
      `env.CLAUDE_CODE_USE_MANTLE` and `env.CLAUDE_CODE_SKIP_MANTLE_AUTH` set to `1`, and `env.ANTHROPIC_BEDROCK_MANTLE_BASE_URL` set to the gateway origin.
      The model picker and the `availableModels` allowlist show only the profile's models, `replaceBuiltInOptions` hides the built-in models, and `env.ANTHROPIC_DEFAULT_MODEL` is the profile's default model.
{% endtable %}

`profile activate` also writes the settings of each other agent CLI that the profile sets up, see [`profile activate`](/kong-harnesses/profile/activate/).
It refuses a credential that the {{ site.claude_code }} settings file already contains in `env.ANTHROPIC_AUTH_TOKEN` or `env.ANTHROPIC_API_KEY`.
In the `foundry` mode, [`doctor`](/kong-harnesses/doctor/) fails when the shell or the settings file sets `ANTHROPIC_FOUNDRY_API_KEY` or `ANTHROPIC_FOUNDRY_AUTH_TOKEN`, because {{ site.claude_code }} would send that key instead of the sign-in.
[`kong-harnesses profile cleanup`](/kong-harnesses/profile/cleanup/) restores each value that activation replaced, when the key still has the value that activation wrote.
A value that the developer changed after activation stays as the developer left it.

## Private certificate authorities

When the gateway, the identity provider or the profile server uses a certificate from a private certificate authority (CA), add the CA to the system trust store of each developer's computer and of your own computer, usually through mobile device management (MDM).
{{site.kong_harnesses}}, {{ site.claude_code }}, Codex, OpenCode and Hermes Agent trust these servers through the system trust store and need nothing more.
The browser that opens for the sign-in must also trust the identity provider's certificate.
Hermes Agent reads the system trust store, but the sign-in script of its {{site.ai_gateway}} plugin doesn't, so sign in to Hermes Agent with `hermes auth add kong-ai-gateway`.

omp and pi don't read the system trust store by default, so set one of these variables in the environment where they start:

{% table %}
columns:
  - title: Agent CLI
    key: client
  - title: Setting
    key: setting
rows:
  - client: omp
    setting: "`NODE_EXTRA_CA_CERTS` set to the CA file, or `NODE_USE_SYSTEM_CA=1`."
  - client: pi
    setting: "`NODE_EXTRA_CA_CERTS` set to the CA file, or, when pi runs on Node.js, `NODE_USE_SYSTEM_CA=1`."
{% endtable %}

The native installer, the npm package, the Homebrew cask, the WinGet package and the apt, dnf and apk packages of {{ site.claude_code }} install the same native binary.
That binary trusts the system trust store by default, so each of these installs needs only the CA in the system trust store.
When a developer set `CLAUDE_CODE_CERT_STORE` without `system`, add `system` back to it.
An older npm install that runs {{ site.claude_code }} on Node.js ignores the system trust store, so update it or set `NODE_EXTRA_CA_CERTS` for it.

Add the CA certificate, a PEM file, to the system trust store:

{% navtabs "system-trust-store" %}
{% navtab "macOS" %}

```sh
sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain CA_CERTIFICATE_FILE
```

You can also deploy the certificate with an MDM certificate payload.

{% endnavtab %}
{% navtab "Windows" %}

Run this command in PowerShell as an administrator:

```powershell
certutil -addstore -f Root CA_CERTIFICATE_FILE
```

You can also deploy the certificate with Group Policy or Intune.

{% endnavtab %}
{% navtab "Debian and Ubuntu" %}

```sh
sudo cp CA_CERTIFICATE_FILE /usr/local/share/ca-certificates/gateway-ca.crt
sudo update-ca-certificates
```

{% endnavtab %}
{% navtab "Fedora and RHEL" %}

```sh
sudo cp CA_CERTIFICATE_FILE /etc/pki/ca-trust/source/anchors/
sudo update-ca-trust
```

{% endnavtab %}
{% navtab "Alpine" %}

```sh
apk add ca-certificates
cp CA_CERTIFICATE_FILE /usr/local/share/ca-certificates/gateway-ca.crt
update-ca-certificates
```

{% endnavtab %}
{% endnavtabs %}

Each WSL distribution has its own trust store.
Install the CA in each distribution with the Linux commands.

When you can't change the system trust store, set the CA for each program instead:

{% table %}
columns:
  - title: Program
    key: program
  - title: Setting
    key: setting
rows:
  - program: "{{ site.claude_code }}"
    setting: |
      `NODE_EXTRA_CA_CERTS` set to the CA file, in the `env` block of the {{ site.claude_code }} user settings.
      `profile activate` doesn't set this key and leaves a value that you set in place.
      When it removes a CA bundle that an earlier {{site.kong_harnesses}} release wrote, it restores the value that the key had before that release.
  - program: Codex
    setting: "`CODEX_CA_CERTIFICATE` set to the CA file, exported in the shell that starts Codex."
  - program: OpenCode
    setting: |
      `NODE_EXTRA_CA_CERTS` set to the CA file.
      When OpenCode runs as a background service, it doesn't read later shell exports, so set the variable for the service with `opencode service set env`.
  - program: "{{site.kong_harnesses}}"
    setting: |
      `SSL_CERT_FILE` set to a file with every CA that {{site.kong_harnesses}} needs, exported in the shell that runs {{site.kong_harnesses}} and in the shell that starts each agent CLI, because the agent CLIs run {{site.kong_harnesses}} to get each token.
      On Linux, the file replaces the default CA file, and {{site.kong_harnesses}} still reads the default certificate directories.
      On macOS and Windows, also export `GODEBUG=x509sslcertoverrideplatform=1`, and the file then replaces the system trust store for {{site.kong_harnesses}}.
{% endtable %}

`profile create` doesn't take a CA bundle.
