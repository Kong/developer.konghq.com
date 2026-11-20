---
title: "Write and publish a {{site.kong_harnesses}} profile"
description: "Create a {{site.kong_harnesses}} profile for each provider mode, publish it to developers, and make each {{ site.claude_code }} install trust a private certificate authority."
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

A {{site.kong_harnesses}} profile tells a developer's computer which {{site.ai_gateway}} to call, how developers sign in, and which model {{ site.claude_code }} starts with.
A profile doesn't contain secrets, so you create it once and give the same file to every developer.
Each developer then runs one command, and every computer uses the same gateway, sign-in and models without hand-edited agent settings.

## Choose a provider mode

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
    clients: "{{ site.claude_code }}, Codex, OpenCode, omp and pi, and Hermes Agent when `--audience-parameter` is `audience`"
    picker: The built-in models and every model that the gateway lists
  - mode: "`foundry` (Microsoft Foundry)"
    model: The Foundry deployment name
    clients: "{{ site.claude_code }} only"
    picker: Only the models that the profile names
  - mode: "`mantle` (Amazon Bedrock Mantle)"
    model: The Bedrock model ID
    clients: "{{ site.claude_code }} only"
    picker: Only the models that the profile names
{% endtable %}

Use the `anthropic` mode unless your organization needs {{ site.claude_code }} in its Foundry or Mantle mode.
The `anthropic` mode is the only mode that sets up other agent CLIs, and the only mode in which {{ site.claude_code }} reads the model list from the gateway.
A model that you add on the gateway shows up in the next {{ site.claude_code }} session, and developers don't run `setup` again.

Choose `foundry` or `mantle` when you want {{ site.claude_code }} to use that cloud's model IDs and the features that {{ site.claude_code }} offers on that cloud.
In these modes, the model picker shows only the models that the profile names, so you publish a new profile to add a model.
A profile from `profile create` names one model, the `--model` value.

In every mode, {{ site.claude_code }} sends Anthropic Messages API requests to `/v1/messages` on the gateway origin.

## Create the profile

Create the profile on your own computer with [`kong-harnesses profile create`](/kong-harnesses/profile/create/).
Run it without flags to answer the questions instead.

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
    value: The name of the profile. Developers type it to confirm the install.
  - placeholder: "`ISSUER_URL`"
    value: The `https://` OIDC issuer URL of your identity provider.
  - placeholder: "`CLIENT_ID`"
    value: The ID of a public OIDC client, without a client secret.
  - placeholder: "`AUDIENCE`"
    value: The audience of the access token that the gateway checks.
  - placeholder: "`GATEWAY_ORIGIN`"
    value: "The `https://` origin of the gateway without a path, such as `https://ai-gateway.example.com`. Developers' computers must trust the gateway certificate, see [Trust a private certificate authority](#trust-a-private-certificate-authority)."
  - placeholder: "`MODEL_NAME`, `FOUNDRY_DEPLOYMENT_NAME` or `BEDROCK_MODEL_ID`"
    value: The model that {{ site.claude_code }} starts with, in the format of the provider mode.
{% endtable %}

`profile create` reads the endpoints of your identity provider from its OIDC discovery document, saves the profile, and installs it on your computer.
It then sends a test request without a sign-in to the gateway route of each agent CLI that the profile sets up, and warns about each route that the gateway doesn't have.
For more options, such as MCP servers that the gateway serves and the {{ site.claude_code }} telemetry to Anthropic, see the [`profile create` reference](/kong-harnesses/profile/create/).

### Choose the sign-in

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
    use: A key that you give each developer, without an identity provider. `login` asks for the key.
    limits: The profile doesn't set up OpenCode.
  - kind: "`environment-key`"
    use: The same kind of key, read from `KONG_HARNESSES_STATIC_KEY` on every call, for a CI job.
    limits: The profile doesn't set up OpenCode.
  - kind: "`subscription`"
    use: "Each developer's own Claude subscription. The profile also needs `--issuer`, `--client-id` and `--audience`. See [Serve Claude subscriptions and company Claude models](/ai-gateway/use-claude-subscriptions-with-ai-gateway/)."
    limits: Needs the `anthropic` mode. The profile sets up only {{ site.claude_code }}.
{% endtable %}

In the `anthropic` mode, {{ site.claude_code }} sends a static key in both the `Authorization: Bearer` and the `x-api-key` headers.
In the `foundry` and `mantle` modes, it sends the key only in `Authorization: Bearer`, so configure the gateway to read the key from that header.

## Publish the profile

Export the installed profile as a JSON file with [jq](https://jqlang.org/):

```sh
kong-harnesses profile get PROFILE_NAME -o json | jq '.profile' > PROFILE_NAME.json
```

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
    rule: "An `https://` URL without a query string, a fragment, a user name or password, an explicit `:443` port, or `.` and `..` path segments."
  - item: Redirects
    rule: At most 3, all to the same origin.
  - item: Response
    rule: "Status `200` with exactly one `Content-Type: application/json` header, with or without `charset=utf-8`. The server must not compress the response."
  - item: Size
    rule: At most 65,536 bytes.
  - item: Time
    rule: The whole download within 10 seconds.
  - item: Access
    rule: "{{site.kong_harnesses}} doesn't send cookies or credentials, so the server must answer without a sign-in."
  - item: Network
    rule: "{{site.kong_harnesses}} trusts the server certificate through the system trust store, and uses the proxy from `HTTPS_PROXY` and `NO_PROXY`."
{% endtable %}

To change the profile, publish the new file at the same URL or give developers the new file.
Developers then run the same `setup` command again.

## What setup changes on a developer's computer

A developer installs the profile with [`kong-harnesses setup`](/kong-harnesses/setup/) and the URL or the file:

```sh
kong-harnesses setup PROFILE_URL
```

`setup` runs `profile import`, `login` and `profile activate`, in this order.
Before it installs the profile, it shows the gateway and the identity provider of the profile, and asks the developer to type the profile name.
With `--auto-approve`, it doesn't ask, and prints the same summary to stderr.
You can run `setup` again safely.

`login` saves the sign-in in the desktop's native vault: only the renewal credential, or the static key.
`profile activate` writes these keys to the {{ site.claude_code }} user settings in `~/.claude/settings.json`:

{% table %}
columns:
  - title: Key
    key: key
  - title: Value
    key: value
rows:
  - key: "`apiKeyHelper`"
    value: "A command that runs `kong-harnesses credential` for the profile, so {{ site.claude_code }} gets a short-lived access token from {{site.kong_harnesses}}. A `subscription` profile doesn't write it."
  - key: "`env.ANTHROPIC_AUTH_TOKEN` and `env.ANTHROPIC_API_KEY`"
    value: Empty, so a key in the shell doesn't replace the sign-in.
  - key: "Model keys, such as `env.ANTHROPIC_MODEL`"
    value: The models that the profile names.
  - key: "Feature switches, such as `env.DISABLE_TELEMETRY`"
    value: "The {{ site.claude_code }} features that the profile turns off."
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
    keys: "`env.CLAUDE_CODE_USE_FOUNDRY` and `env.CLAUDE_CODE_SKIP_FOUNDRY_AUTH` set to `1`, and `env.ANTHROPIC_FOUNDRY_BASE_URL` set to the gateway origin. The model picker, the `availableModels` allowlist and `env.ANTHROPIC_DEFAULT_MODEL` list only the profile's models."
  - mode: "`mantle`"
    keys: "`env.CLAUDE_CODE_USE_MANTLE` and `env.CLAUDE_CODE_SKIP_MANTLE_AUTH` set to `1`, and `env.ANTHROPIC_BEDROCK_MANTLE_BASE_URL` set to the gateway origin. The model picker, the `availableModels` allowlist and `env.ANTHROPIC_DEFAULT_MODEL` list only the profile's models."
{% endtable %}

`profile activate` refuses an API key that the settings file already contains in `env`.
In the `foundry` mode, `doctor` fails when the shell or the settings file sets `ANTHROPIC_FOUNDRY_API_KEY` or `ANTHROPIC_FOUNDRY_AUTH_TOKEN`, because {{ site.claude_code }} would send that key instead of the sign-in.
[`kong-harnesses profile cleanup`](/kong-harnesses/profile/cleanup/) gives back the value that each key had before activation.

## Trust a private certificate authority

When the gateway, the identity provider or the profile server uses a certificate from a private certificate authority (CA), add the CA to the system trust store of each developer's computer, usually through mobile device management (MDM).
{{site.kong_harnesses}}, {{ site.claude_code }}, Codex and OpenCode trust the gateway through the system trust store and need nothing more.
omp and pi run on Node.js, so they also need `NODE_USE_SYSTEM_CA=1`, or `NODE_EXTRA_CA_CERTS` set to a file with the CA, in the environment where they start.

The native installer, the npm package, the Homebrew cask and the WinGet package of {{ site.claude_code }} install the same native binary.
That binary uses the system trust store, so each of these installs needs only the CA in the system trust store.

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
    setting: "`NODE_EXTRA_CA_CERTS` set to the CA file, in the `env` block of `~/.claude/settings.json`. `profile activate` doesn't change this key."
  - program: Codex
    setting: "`CODEX_CA_CERTIFICATE` set to the CA file, exported in the shell."
  - program: "{{site.kong_harnesses}}"
    setting: "`SSL_CERT_FILE` set to a file with every CA that {{site.kong_harnesses}} needs, exported in the shell. The file replaces the system trust store for {{site.kong_harnesses}}. On macOS and Windows, also export `GODEBUG=x509sslcertoverrideplatform=1`."
{% endtable %}

`profile create` doesn't take a CA bundle.
