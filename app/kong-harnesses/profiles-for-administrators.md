---
title: "{{site.kong_harnesses}} profiles for administrators"
description: "Choose a provider mode and a sign-in kind, create and host a {{site.kong_harnesses}} profile for the developers of your organization, and see what setup changes on their computers."
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
  - text: kong-harnesses profile cleanup
    url: /kong-harnesses/profile/cleanup/
  - text: Serve Claude subscriptions and company Claude models on one {{site.ai_gateway}} base URL
    url: /ai-gateway/use-claude-subscriptions-with-ai-gateway/
---

A {{site.kong_harnesses}} profile is a JSON file that holds the connection settings for your {{site.ai_gateway}}.
It names the gateway that developers' agent CLIs call, the identity provider that developers sign in with, and the model that {{ site.claude_code }} starts with.
You create the profile once, and every developer installs the same file with one command, `kong-harnesses setup`.
Every computer then uses the same gateway and models without editing agent settings files.
A profile doesn't contain secrets, so you can give the same file to every developer.

To roll out a profile:

1. Choose a [provider mode](#provider-modes), and configure the gateway for that mode.
1. Choose a [sign-in kind](#sign-in-kinds).
1. If the gateway, the identity provider or the profile server uses a certificate from a private certificate authority (CA), [add the CA to the system trust store](#private-certificate-authorities).
1. [Create the profile](#profile-creation) with `kong-harnesses profile create`.
1. [Export and host the profile](#profile-hosting), and give developers the URL or the file.
1. Developers run [`setup`](#setup) with the URL or the file.

## Provider modes

The provider mode sets the API format that {{ site.claude_code }} uses with the gateway, and it decides what you give the `--model` flag of `profile create`.
Set the provider mode with the `--provider` flag.

{% table %}
columns:
  - title: Mode
    key: mode
  - title: "`--model` value"
    key: model
{% comment %}
  - title: Agent CLIs that the profile sets up
    key: clients
{% endcomment %}
rows:
  - mode: "`anthropic` (Anthropic API, the default)"
    model: The model name that the gateway serves
{% comment %}
    clients: |
      {{ site.claude_code }}, Codex, OpenCode, omp and pi.
      Hermes Agent too, when the profile uses the default sign-in with `--audience-parameter audience` and the default scopes.
{% endcomment %}
  - mode: "`foundry` (Microsoft Foundry)"
    model: The Foundry deployment name
{% comment %}
    clients: "{{ site.claude_code }} only"
{% endcomment %}
  - mode: "`mantle` (Amazon Bedrock Mantle)"
    model: The Bedrock model ID
{% comment %}
    clients: "{{ site.claude_code }} only"
{% endcomment %}
{% endtable %}

Use the `anthropic` mode unless the gateway serves Claude only through Microsoft Foundry or Amazon Bedrock Mantle and you want {{ site.claude_code }} to use that cloud's model IDs.
{% comment %}
The `anthropic` mode is the only mode that sets up other agent CLIs, and the only mode in which {{ site.claude_code }} reads the model list from the gateway.
{% endcomment %}
The `anthropic` mode is the only mode in which {{ site.claude_code }} reads the model list from the gateway.

### Models in the model picker

The model picker is the list of models that developers can choose from in {{ site.claude_code }}.
The provider mode decides what the list holds:

{% table %}
columns:
  - title: Mode
    key: mode
  - title: Models in the model picker
    key: picker
rows:
  - mode: "`anthropic`"
    picker: The built-in models and the models that the gateway lists at `GET /v1/models`
  - mode: "`foundry` and `mantle`"
    picker: Only the models that the profile names
{% endtable %}

{{ site.claude_code }} has model roles, such as `opus` and `haiku`.
`profile create` takes one model, the `--model` value, and uses it for every role.

In the `anthropic` mode, you add a model on the gateway:

* A model whose ID contains `claude` or `anthropic`, in any letter case, appears in the model picker of the next {{ site.claude_code }} session.
  The gateway must list the model in a successful `GET /v1/models` response.
  Developers don't need to run `setup` again.
* A model with another ID needs a model picker entry from the gateway's `GET /v1/models` response.
  After you add the model, developers run `kong-harnesses profile activate PROFILE_NAME` again to add the entry.

In the `foundry` and `mantle` modes, you publish a new profile to add a model.
To offer more than one model, do the following:

1. Export the profile as in [Profile hosting](#profile-hosting).
1. In the exported file, open `clients.claude-code.models`.
   This object has one entry for each model role, and the value of each entry is a model ID.
   The roles are `active`, `default`, `sonnet`, `opus`, `haiku`, `fable`, `subagent`, `background_classifier` and `auto_mode`.
   `profile create` sets every role to the `--model` value.
1. Change the roles that should use another model.
   Several roles can use the same model ID.
   For example, the following object uses `MODEL_B` for the `opus` role and `MODEL_A` for every other role:

   ```json
   "models": {
     "active": "MODEL_A",
     "default": "MODEL_A",
     "sonnet": "MODEL_A",
     "opus": "MODEL_B",
     "haiku": "MODEL_A",
     "fable": "MODEL_A",
     "subagent": "MODEL_A",
     "background_classifier": "MODEL_A",
     "auto_mode": "MODEL_A"
   }
   ```

1. Host the edited file.
   The model picker shows each model that a role names.

### Gateway routes and AI Models

Every provider mode needs an [AI Model](/ai-gateway/entities/ai-model/) on the gateway.
In every mode, {{ site.claude_code }} sends Anthropic Messages API requests to `/v1/messages` on the gateway origin.
{{ site.claude_code }} names the model that the developer uses in the `model` field of each request, by default the profile's `--model` value.
Configure the AI Model that serves {{ site.claude_code }} as follows:

* Use the Anthropic format.
* Create one AI Model for each model ID that the route must accept, all on the same path.
* Set `config.route.model` to `body_param: model`, with that model ID as the single entry of `values`.
* Set `targets[].name` to the upstream deployment name or model ID.

{% comment %}
Each provider mode needs more settings:
{% endcomment %}
The `foundry` and `mantle` modes need more settings:

{% table %}
columns:
  - title: Mode
    key: mode
  - title: AI Model settings
    key: settings
rows:
{% comment %}
  - mode: "`anthropic`"
    settings: |
      Codex sends OpenAI Responses API requests to `/v1/responses` on the gateway origin, so Codex needs an AI Model in the OpenAI format, as in [Route OpenAI Codex CLI traffic through {{site.ai_gateway}}](/ai-gateway/use-codex-with-ai-gateway/).
      OpenCode, omp, pi and Hermes Agent send their requests to `/v1/messages`, the same route as {{ site.claude_code }}.
{% endcomment %}
  - mode: "`foundry`"
    settings: Point the AI Model at your Foundry deployment, as in [Route Claude CLI traffic through {{site.ai_gateway}} and Azure](/ai-gateway/use-claude-code-with-ai-gateway-azure/).
  - mode: "`mantle`"
    settings: |
      Use a `bedrock` [AI Model Provider](/ai-gateway/entities/ai-model-provider/), and set `targets[].config.endpoint_type: mantle` on the AI Model, as in [Route OpenAI traffic to Amazon Bedrock Mantle](/ai-gateway/route-openai-traffic-to-bedrock-mantle/).
      Use `formats: [type: anthropic]` instead of `type: openai`, because the Mantle endpoint accepts the Anthropic format natively.
{% endtable %}

## Sign-in kinds

{{ site.claude_code }} sends a credential with each request, and the gateway checks it.
By default, developers sign in through your identity provider, and the gateway checks their access token.
The `--sign-in` flag of `profile create` selects another kind of sign-in:

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
      Omit `--issuer`, `--client-id` and `--audience`.
      `login` asks for the key.
{% comment %}
    limits: The profile doesn't set up OpenCode or Hermes Agent.
{% endcomment %}
    limits: None
  - kind: "`environment-key`"
    use: |
      The same kind of key, read from `KONG_HARNESSES_STATIC_KEY` on every call, for a CI job.
      Omit `--issuer`, `--client-id` and `--audience`.
      Set the variable on the `profile activate` step and on the step that runs {{ site.claude_code }}.
{% comment %}
    limits: The profile doesn't set up OpenCode or Hermes Agent.
{% endcomment %}
    limits: None
  - kind: "`subscription`"
    use: |
      Each developer's own Claude subscription, with the same `--issuer`, `--client-id` and `--audience` flags as the default sign-in.
      Each developer also signs in to {{ site.claude_code }} with their subscription.
      See [Serve Claude subscriptions and company Claude models](/ai-gateway/use-claude-subscriptions-with-ai-gateway/).
    limits: |
      Needs the `anthropic` mode.
{% comment %}
      The profile sets up only {{ site.claude_code }}, and can't list gateway MCP servers.
{% endcomment %}
      The profile can't list gateway MCP servers.
      Update {{site.kong_harnesses}} on each developer's computer first, because a release from before subscription sign-in refuses to import the profile.
{% endtable %}

### Static keys on the gateway

A `static-key` or `environment-key` profile replaces the identity provider with a key that you give each developer.
The gateway must accept that key.

In the `anthropic` mode, {{ site.claude_code }} sends the key in both `Authorization: Bearer` and `x-api-key`.
In the `foundry` and `mantle` modes, {{ site.claude_code }} sends the key only in `Authorization: Bearer`.
Give the AI Model a `key-auth` [AI Auth Strategy](/ai-gateway/entities/ai-auth-strategy/#api-key-authentication) that accepts those headers and hides the key from the model provider.

### CI jobs with an environment key

With an `environment-key` profile, {{site.kong_harnesses}} reads the key from `KONG_HARNESSES_STATIC_KEY` on every call instead of asking for it, and `setup` skips `login`.
Use this sign-in kind for a CI job.
The setup of a CI job depends on the system:

{% navtabs "environment-key-ci" %}
{% navtab "macOS and Windows" %}

The CI job doesn't need any other setup.

{% endnavtab %}
{% navtab "Linux" %}

{{site.kong_harnesses}} needs `XDG_RUNTIME_DIR` for its profile and settings locks, and each command that takes a lock fails without `XDG_RUNTIME_DIR`.
A desktop sign-in sets the variable, but most CI containers don't.
When the variable isn't set, create a private directory once, and give each step of the job that runs a {{site.kong_harnesses}} command the same `XDG_RUNTIME_DIR`.
In a CI system that runs each step in its own shell, a shell `export` ends with its step, so set the variable in the job environment.
For example, in GitHub Actions, add the following step before the first step that runs {{site.kong_harnesses}}:

```yaml
- run: echo "XDG_RUNTIME_DIR=$(mktemp -d)" >> "$GITHUB_ENV"
```

{% endnavtab %}
{% endnavtabs %}

## Private certificate authorities

When the gateway, the identity provider or the profile server uses a certificate from a private certificate authority (CA), each computer that runs {{site.kong_harnesses}} must trust that CA.
{% comment %}
{{site.kong_harnesses}}, {{ site.claude_code }}, Codex, OpenCode and Hermes Agent trust these servers through the system trust store.
When developers use Hermes Agent, omp or pi, also see [Agent CLIs that need more than the system trust store](#agent-clis-that-need-more-than-the-system-trust-store).
{% endcomment %}
{{site.kong_harnesses}} and {{ site.claude_code }} trust these servers through the system trust store.
When you can't change the system trust store, see [CA settings per program](#ca-settings-per-program).

{:.warning}
> Add the CA to the system trust store of each developer's computer and of your own computer, for example, through mobile device management (MDM).
> A CA setting in an environment variable or a settings file changes only the program that reads that setting.
> The browser that opens for the sign-in must also trust the certificate of the identity provider.

### System trust store installation

Add the CA certificate, a PEM file, to the system trust store:

{% navtabs "system-trust-store" %}
{% navtab "macOS" %}

```sh
sudo security add-trusted-cert -d -r trustRoot \
  -k /Library/Keychains/System.keychain \
  CA_CERTIFICATE_FILE
```

You can also deploy the certificate with an MDM certificate payload.

{% endnavtab %}
{% navtab "Linux" %}

On Debian and Ubuntu, copy the certificate to the CA directory:

```sh
sudo cp CA_CERTIFICATE_FILE /usr/local/share/ca-certificates/gateway-ca.crt
```

Then update the system trust store:

```sh
sudo update-ca-certificates
```

On Fedora and RHEL, copy the certificate to the CA directory:

```sh
sudo cp CA_CERTIFICATE_FILE /etc/pki/ca-trust/source/anchors/
```

Then update the system trust store:

```sh
sudo update-ca-trust
```

On Alpine, run the following commands as root.
Install the CA tools:

```sh
apk add ca-certificates
```

Copy the certificate to the CA directory:

```sh
cp CA_CERTIFICATE_FILE /usr/local/share/ca-certificates/gateway-ca.crt
```

Update the system trust store:

```sh
update-ca-certificates
```

{% endnavtab %}
{% navtab "Windows" %}

Run the following command in PowerShell as an administrator:

```powershell
certutil -addstore -f Root CA_CERTIFICATE_FILE
```

You can also deploy the certificate with Group Policy or Intune.

Each WSL distribution has its own trust store.
Install the CA in each distribution with the commands of the **Linux** tab.

{% endnavtab %}
{% endnavtabs %}

### {{ site.claude_code }} installs

The following installs of {{ site.claude_code }} install the same native binary:

{% table %}
columns:
  - title: System
    key: system
  - title: Installs
    key: installs
rows:
  - system: macOS
    installs: The native installer, the npm package and the Homebrew cask
  - system: Linux
    installs: The native installer, the npm package, the Homebrew cask and the apt, dnf and apk packages
  - system: Windows
    installs: The native installer, the npm package and the WinGet package
{% endtable %}

That binary trusts the system trust store by default, so each of these installs needs only the CA in the system trust store.
When `CLAUDE_CODE_CERT_STORE` is set without `system`, add `system` to `CLAUDE_CODE_CERT_STORE`.
An older npm install that runs {{ site.claude_code }} on Node.js reads the system trust store only on Node.js 22.15 or later.
Update that install to the native binary, or set `NODE_EXTRA_CA_CERTS` for that install.
For the Node.js limits, see the [{{ site.claude_code }} CA certificate store](https://code.claude.com/docs/en/network-config#ca-certificate-store).

{% comment %}
### Agent CLIs that need more than the system trust store

#### Hermes Agent

Sign in to Hermes Agent with `hermes auth add kong-ai-gateway` instead of the sign-in script of the Hermes Agent {{site.ai_gateway}} plugin.
That sign-in script doesn't use the Python `truststore` library, so the script reads only the default certificate paths of OpenSSL and doesn't read every CA in the system trust store.

#### omp and pi

Whether omp and pi need a CA variable after you add the CA to the system trust store depends on the system.
pi on Node.js needs Node.js 22.19 or later.

{% navtabs "omp-pi-ca" %}
{% navtab "macOS" %}

omp and pi don't read the macOS keychain by default, so set `NODE_EXTRA_CA_CERTS` or `NODE_USE_SYSTEM_CA=1` for a CA that you added to the keychain.

pi on Node.js from Homebrew trusts the CA bundle of the Homebrew `ca-certificates` package and by default ignores `NODE_USE_SYSTEM_CA`.
Homebrew builds that bundle from the certificates trusted for SSL in the System keychain (`/Library/Keychains/System.keychain`), the certificates of `/System/Library/Keychains/SystemRootCertificates.keychain` and the Mozilla certificates.
Run `brew postinstall ca-certificates` after you add the CA, or set `NODE_EXTRA_CA_CERTS`.

{% endnavtab %}
{% navtab "Linux" %}

omp and the Bun release archives of pi read the CA file `/etc/ssl/cert.pem`, or the file that `SSL_CERT_FILE` names, and the CA directory `/etc/ssl/certs`.
A CA that the CA tool of the distribution adds to these paths works for omp and pi without a variable:

* On Debian and Ubuntu, `update-ca-certificates` adds the CA to the directory `/etc/ssl/certs`.
* On Alpine, `update-ca-certificates` adds the CA to the bundle that `/etc/ssl/cert.pem` links to.
* On Fedora, `update-ca-trust` adds the CA to the bundle that `/etc/ssl/cert.pem` links to.

When `NODE_EXTRA_CA_CERTS` is set, omp stops reading these paths, and pi keeps reading them.

A `nodejs` package of Debian, Ubuntu, Fedora or Alpine that meets the pi minimum reads the CA paths of the distribution.
A CA that the CA tool of the distribution adds then works for pi on that Node.js without a variable.
Debian 12 and 13 and Ubuntu 24.04 ship Node.js 18 or 20, which pi can't run on.

Set `NODE_EXTRA_CA_CERTS` or `NODE_USE_SYSTEM_CA=1` in the following cases, because the program trusts only its own CA list by default:

* pi on a Node.js build from nodejs.org or nvm
* omp and pi on a distribution that keeps its CAs in other paths

pi on Node.js from Homebrew trusts the CA bundle of the Homebrew `ca-certificates` package and by default ignores `NODE_USE_SYSTEM_CA`.
Homebrew builds that bundle from the Mozilla certificates and the first readable system bundle of `/etc/ssl/certs/ca-certificates.crt`, `/etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem` and `/etc/ssl/ca-bundle.pem`, in that order.
When Homebrew doesn't find one of these bundles or an `openssl` command, the bundle holds only the Mozilla certificates.
Run `brew postinstall ca-certificates` after you add the CA, or set `NODE_EXTRA_CA_CERTS`.

{% endnavtab %}
{% navtab "Windows" %}

omp and pi don't read the Windows certificate store by default, so set `NODE_EXTRA_CA_CERTS` or `NODE_USE_SYSTEM_CA=1`.

{% endnavtab %}
{% endnavtabs %}

omp, and pi on Node.js or from its Bun release archives, read the following variables in the environment where they start:

{% table %}
columns:
  - title: Variable
    key: variable
  - title: Effect
    key: effect
rows:
  - variable: "`NODE_EXTRA_CA_CERTS` set to the CA file"
    effect: |
      pi adds the file to the CAs that pi already trusts.
      omp trusts only Bun's bundled CA list and that file.
      omp then stops reading the default CA file and directory of the system and the system trust store, so put every private CA that omp needs in that file, such as the CA of a proxy.
  - variable: "`NODE_USE_SYSTEM_CA=1`"
    effect: |
      pi also trusts the system trust store, but by default not on Node.js from Homebrew.
      pi on Node.js reads `NODE_USE_SYSTEM_CA` only on Node.js 22.19 or a later 22 release, or on Node.js 24.6 or later, so set `NODE_EXTRA_CA_CERTS` on an earlier release, such as Node.js 24.0 to 24.5.
      omp also trusts the system trust store only when `NODE_EXTRA_CA_CERTS` isn't set.
{% endtable %}

When the environment doesn't set `NODE_EXTRA_CA_CERTS`, omp reads the variable from the following `.env` files, in order, and uses the first value that isn't empty:

1. `.env` and the other dotenv files that Bun loads from the directory where omp starts, such as `.env.local`
1. `~/.omp/agent/.env`
1. `~/.omp/.env`
1. `~/.env`

When `OMP_PROFILE` names an omp profile, omp reads `~/.omp/profiles/OMP_PROFILE_NAME/agent/.env` and `~/.omp/profiles/OMP_PROFILE_NAME/.env` in place of the second and third file, which belong to the default omp profile.
{% endcomment %}

### CA settings per program

A profile can't give developers a CA.
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
      `profile activate` doesn't set `NODE_EXTRA_CA_CERTS`, and leaves a value that you set in place.
      When `profile activate` removes a CA bundle that an earlier {{site.kong_harnesses}} release wrote, `profile activate` restores the values that `NODE_EXTRA_CA_CERTS` and `CLAUDE_CODE_CERT_STORE` had before that release, and keeps a value that you changed after that release.
{% comment %}
  - program: Codex
    setting: |
      `CODEX_CA_CERTIFICATE` set to the CA file, exported in the shell that starts Codex.
      Don't export `SSL_CERT_FILE` for Codex, because the file replaces the system trust store for Codex and for every command that Codex runs, such as `git` and `curl`.
      When the shell must export `SSL_CERT_FILE` for {{site.kong_harnesses}}, use the bundle with the public root CAs and each private CA that the {{site.kong_harnesses}} row names.
  - program: Hermes Agent
    setting: |
      `SSL_CERT_FILE` set to a bundle file with the public root CAs of the system and each private CA, in `~/.hermes/.env` or exported in the shell that starts Hermes Agent.
      Hermes Agent passes the variable to the commands that it runs, such as `curl` and `pip`, and the file replaces their CA list, so a file with only the private CA breaks their public TLS connections.
      Hermes Agent trusts the file in addition to the system trust store.
      The sign-in script of the plugin doesn't read `~/.hermes/.env`, so sign in with `hermes auth add kong-ai-gateway`.
  - program: OpenCode
    setting: |
      `NODE_EXTRA_CA_CERTS` set to the CA file.
      When OpenCode runs as a background service, the service doesn't read later shell exports, so set the variable for the service with `opencode service set env`.
  - program: omp and pi
    setting: |
      `NODE_EXTRA_CA_CERTS` set to the CA file.
      For the effect of `NODE_EXTRA_CA_CERTS` and the `.env` files that omp reads, see [omp and pi](#omp-and-pi).
{% endcomment %}
  - program: "{{site.kong_harnesses}}"
    setting: |
{% comment %}
      `SSL_CERT_FILE` set to a bundle file with the public root CAs of the system and each private CA, exported in the shell that runs {{site.kong_harnesses}} and in the shell that starts {{ site.claude_code }}, Codex, omp or pi, because these agent CLIs run {{site.kong_harnesses}} to get each token.
      OpenCode and Hermes Agent sign in through their own plugins and don't run {{site.kong_harnesses}} for a token.
{% endcomment %}
      `SSL_CERT_FILE` set to a bundle file with the public root CAs of the system and each private CA, exported in the shell that runs {{site.kong_harnesses}} and in the shell that starts {{ site.claude_code }}, because {{ site.claude_code }} runs {{site.kong_harnesses}} to get each token.
{% endtable %}

How {{site.kong_harnesses}} reads `SSL_CERT_FILE` depends on the system:

{% navtabs "kong-harnesses-ca-bundle" %}
{% navtab "macOS" %}

Also export `GODEBUG=x509sslcertoverrideplatform=1`.
The file then replaces the system trust store for {{site.kong_harnesses}}, so a file with only the private CA breaks the token renewal with a public identity provider, and the profile download from a public profile server.

Create the bundle from the public root CAs of the system and your CA:

```sh
cat /etc/ssl/cert.pem CA_CERTIFICATE_FILE > CA_BUNDLE_FILE
```

{% endnavtab %}
{% navtab "Linux" %}

The file replaces the default CA file, and {{site.kong_harnesses}} still reads the default certificate directories.

{% endnavtab %}
{% navtab "Windows" %}

With `GODEBUG=x509sslcertoverrideplatform=1`, the `SSL_CERT_FILE` file replaces the system trust store for {{site.kong_harnesses}}.
A file with only the private CA then breaks the token renewal with a public identity provider, and the profile download from a public profile server.

{% comment %}
In step 4, set both of the following variables in the PowerShell session that runs {{site.kong_harnesses}} and in the session that starts {{ site.claude_code }}, Codex, omp or pi.
{% endcomment %}
Complete the following steps in one PowerShell session:

1. Connect once in PowerShell to each HTTPS server that {{site.kong_harnesses}} calls, so that Windows adds the root CA of each server.
   Windows adds a public root CA to the Windows certificate store only when a connection first needs that root CA.
   The servers are:

   * The gateway, unless the gateway runs on the local computer with a plain `http` URL
   * The identity provider, when the profile signs in through one
   * The profile server, when you import the profile from an HTTPS URL

   ```powershell
   Invoke-WebRequest -UseBasicParsing https://SERVER_HOST | Out-Null
   ```

   An error for the HTTP status is fine, because Windows checks the certificate chain before the request gets the status.
   Expect a TLS error for a server with a certificate from your private CA, because the automatic root update of Windows adds only public root CAs.
   The bundle gets the root of your private CA from `CA_CERTIFICATE_FILE` when you create the bundle.

1. Copy the root CAs of the Windows certificate store into a variable:

   ```powershell
   $roots = Get-ChildItem Cert:\LocalMachine\Root |
     ForEach-Object {
       "-----BEGIN CERTIFICATE-----`n" +
         [Convert]::ToBase64String($_.RawData, 'InsertLineBreaks') +
         "`n-----END CERTIFICATE-----"
     }
   ```

1. In the same PowerShell session, write those root CAs and your CA to the bundle file:

   ```powershell
   @($roots) + (Get-Content -Raw CA_CERTIFICATE_FILE) |
     Set-Content -Encoding ascii CA_BUNDLE_FILE
   ```

1. Set both of the following variables in the PowerShell session that runs {{site.kong_harnesses}} and in the session that starts {{ site.claude_code }}.
   Set `SSL_CERT_FILE` to the full path of the bundle:

   ```powershell
   $env:SSL_CERT_FILE = (Resolve-Path CA_BUNDLE_FILE).Path
   ```

   Set `GODEBUG`:

   ```powershell
   $env:GODEBUG = "x509sslcertoverrideplatform=1"
   ```

1. In the same session, install the profile if the profile isn't installed yet:

   ```powershell
   kong-harnesses profile import PROFILE_URL
   ```

1. Run the doctor checks for the profile:

   ```powershell
   kong-harnesses doctor --profile PROFILE_NAME
   ```

   The CA bundle check of the `SSL_CERT_FILE` file must show OK for each server that the check lists, also for a server whose `Invoke-WebRequest` command gave a TLS error.

When `profile import` or the CA bundle check reports an error, use the fix for that error:

{% table %}
columns:
  - title: Error
    key: error
  - title: Fix
    key: fix
rows:
  - error: Unknown certificate authority
    fix: |
      Check that the bundle holds the root CA of that server.
      For a server with a certificate from your private CA, that root CA is the one that your administrator gave you.
      If the bundle doesn't hold the root CA, add the root CA certificate to the bundle, or create the bundle again, and then run the command again.
      If the bundle holds the root CA, ask your administrator to check the certificate chain that the server sends.
      When a Windows policy [stops the automatic update of root CAs](https://learn.microsoft.com/en-us/windows-server/identity/ad-cs/configure-trusted-roots-disallowed-certificates#registry-settings-modified), ask your administrator for the public root CA that the bundle doesn't have.
  - error: Expired certificate, or certificate not valid yet
    fix: |
      A new bundle doesn't fix this error.
      Check the clock of the computer first, because a wrong clock gives the same error.
      When the clock is right, ask your administrator to check the dates of the server certificate.
  - error: Host name mismatch
    fix: |
      A new bundle doesn't fix this error.
      For the profile server, check the host in the profile URL.
      When the URL is right, or for another server, ask your administrator to fix the server certificate.
  - error: Missing or unreadable file
    fix: Check the path in the variable that the result names.
{% endtable %}

{% endnavtab %}
{% endnavtabs %}

## Profile creation

Create the profile on your own computer with [`kong-harnesses profile create`](/kong-harnesses/profile/create/).
`profile create` reads your identity provider's OIDC discovery endpoints for the default and `subscription` sign-ins, then saves and installs the profile on your computer.

For the default and the `subscription` sign-ins, `profile create` connects to your identity provider, so your computer must trust its certificate first.
For a private CA, see [Private certificate authorities](#private-certificate-authorities).
The identity provider needs a public OIDC client, without a client secret, for the authorization code flow with PKCE (S256) and refresh tokens.
Register `http://localhost:9876/callback` as a sign-in redirect URI of the client, or register another loopback URI and pass it with `--redirect-uri`.
For an example with Okta, see [Set up {{ site.claude_code }} with kong-harnesses](/ai-gateway/set-up-claude-code-with-kong-harnesses/).


### Create the profile via interview

You can run `profile create` without flags to instead answer questions to build your profile.
The command asks the questions in three steps: Connection, Discovery and Review.
Each question matches a flag, so you can also pass any answer as a flag, and `profile create` skips that question.

{% table %}
columns:
  - title: Question
    key: question
  - title: Flag
    key: flag
  - title: Answer
    key: answer
rows:
  - question: Profile name
    flag: "`--name`"
    answer: |
      The name of the profile.
      Developers type it to confirm the install.
  - question: Gateway URL
    flag: "`--gateway-origin`"
    answer: The `https://` origin of the gateway without a path, such as `https://ai-gateway.example.com`.
  - question: Sign-in
    flag: "`--sign-in`"
    answer: |
      How developers get a credential for the gateway.
      The choices are your identity provider, a key from the administrator, or the developer's own Claude subscription.
      For more information, see [Sign-in kinds](#sign-in-kinds).
  - question: Sign-in issuer
    flag: "`--issuer`"
    answer: The `https://` OIDC issuer URL of your identity provider.
  - question: Public client ID
    flag: "`--client-id`"
    answer: The ID of the public OIDC client.
  - question: Gateway audience
    flag: "`--audience`"
    answer: The audience of the access token that the gateway checks, as an absolute URI such as `api://default`.
  - question: Audience parameter
    flag: "`--audience-parameter`"
    answer: |
      How the sign-in request names the audience: `resource` (the default), `audience` or `none`.
      Use the value that your identity provider reads.
  - question: Default model
    flag: "`--model`"
    answer: |
      The model that the profile sets for every {{ site.claude_code }} model role, in the format of the [provider mode](#provider-modes).
      In the `anthropic` mode, the command lists the models that the gateway serves when the gateway lists them.
{% endtable %}

The command asks the sign-in questions only for a sign-in that uses them.
It then asks about optional {{ site.claude_code }} settings, such as the prompt cache lifetime, and shows the settings for review before it saves the profile.

### Create the profile with flags

To create the profile without questions, run the command for your provider mode.
For a `static-key` or `environment-key` profile, omit `--issuer`, `--client-id` and `--audience`, and add `--sign-in` with the kind.
For a `subscription` profile, add `--sign-in subscription`.

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

Replace the placeholders as described in the answers to the questions.
The `GATEWAY_ORIGIN` host must have a certificate that developers' computers trust.
For a private CA, see [Private certificate authorities](#private-certificate-authorities).

`profile create` also tests each agent CLI's gateway route without a sign-in, warns when a route doesn't match, and keeps the agent CLI in the profile.
Send a signed-in prompt from the affected agent CLI to check each warned route.
If [`setup`](#setup) refuses a route that matches only on a header that the agent CLI sends, developers run `setup` with `--skip-route-check`.
For all flags, such as gateway MCP servers and {{ site.claude_code }} telemetry to Anthropic, see the [`profile create` reference](/kong-harnesses/profile/create/).

## Changes on developers' computers

[`kong-harnesses setup`](/kong-harnesses/setup/) installs a {{site.kong_harnesses}} profile on a developer's computer, signs the developer in, and writes the settings of each agent CLI that the profile sets up.

### Setup

Each developer runs `setup` on their computer to install the profile, and runs it again when you change the profile, as in [Profile updates](#profile-updates).
The developer gives `setup` the profile as an HTTPS URL or as a local JSON file, so use the form that matches how you [host the profile](#profile-hosting).

From an HTTPS URL:

```sh
kong-harnesses setup PROFILE_URL
```

From a local JSON file:

```sh
kong-harnesses setup ./PROFILE_NAME.json
```

`setup` runs the following steps in order:

1. `profile import` shows the gateway and the identity provider of the profile, asks the developer to type the profile name, and installs the profile.
1. `login` signs the developer in, and saves the renewal credential or the static key in the operating system's credential store.
   When the developer enters the key of a gateway MCP server that asks for one, `login` saves that key in the same store.
1. `profile activate` writes the settings of each agent CLI that `setup` sets up.

`setup` skips `login` for an `environment-key` profile.
{% comment %}
`setup` also skips `login` when every agent CLI that `setup` sets up is OpenCode or Hermes Agent, because these agent CLIs sign in through their own plugins.
After `setup` sets up OpenCode or Hermes Agent, the developer runs the sign-in command that `kong-harnesses status` names for that agent CLI, and then restarts the agent CLI.
This sign-in is also needed when the same run sets up {{ site.claude_code }}.
{% endcomment %}

When the command doesn't name `--client`, `setup` sets up every installed agent CLI that the profile lists and that passes the [agent CLI checks](#agent-cli-checks).
{% comment %}
Add `--client claude-code` to set up only {{ site.claude_code }}.
{% endcomment %}

When the developer adds `--auto-approve`, `setup` doesn't ask the developer to type the profile name or to confirm the list of agent CLIs, and prints the import summary to stderr.
The sign-in step still opens the browser, or asks for the static key.
Use `--auto-approve` only in an onboarding script that your organization owns, because `--auto-approve` skips the developer's check of the gateway and the identity provider.

When a step fails, `setup` stops and names the step.
Fix the reported error, then run the same `setup` command again.
A step that is already done doesn't change anything: a sign-in that works stays, and an agent CLI that is already set up stays as it is.

### Agent CLI checks

Before `setup` sets up an agent CLI, `setup` sends a test request to the gateway route of that agent CLI.
{% comment %}
The test request contains the developer's sign-in, unless the agent CLI signs in through its own plugin or the profile uses the `subscription` sign-in.
{% endcomment %}
The test request contains the developer's sign-in, unless the profile uses the `subscription` sign-in.

In the following cases, `setup` warns that the agent CLI may not reach the gateway, tells the developer to send a prompt from that agent CLI to check, and goes on to the next check of the agent CLI:

- `setup` can't build a request like the one that the agent CLI sends, for example because the {{ site.claude_code }} managed settings set a credential, a gateway URL or a proxy.
  `setup` then doesn't send a test request.
- The gateway doesn't have a route for the test request or refuses the test request, and the test request doesn't contain a part that the agent CLI adds itself, such as a header from the agent CLI's own settings or a client certificate.
  A route can depend on that missing part.
- For a `subscription` profile, the gateway asks for the developer's Claude sign-in before the gateway routes the test request.

A later check can still stop `setup` before `setup` writes the settings of any agent CLI.

In the following cases, a check fails, and `setup` names the fix for the agent CLI:

- The gateway route of the agent CLI is missing, or the gateway refuses the sign-in.
{% comment %}
- The profile uses a plain `http://` gateway, and the agent CLI is Codex, OpenCode or Hermes Agent.
- The agent CLI is OpenCode, and its npm plugin registry uses plain `http://` on another computer.
{% endcomment %}

When the command doesn't name `--client`, `setup` leaves out each agent CLI that fails a check and sets up the remaining agent CLIs, or stops when none remain.
When the command names `--client`, `setup` stops.
Before `setup` writes any settings, `setup` checks that each remaining agent CLI can use the profile.
When one of them can't, `setup` stops and doesn't write the settings of any agent CLI.

### {{ site.claude_code }} settings

`profile activate` writes the following keys to the {{ site.claude_code }} user settings, `~/.claude/settings.json`.
When `CLAUDE_CONFIG_DIR` is set, `profile activate` writes the keys to `settings.json` in `CLAUDE_CONFIG_DIR` instead.

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
      {{ site.claude_code }} runs that command to get a short-lived access token, or the key of a `static-key` or `environment-key` profile.
      A `subscription` profile doesn't write `apiKeyHelper`, and removes an `apiKeyHelper` that the file already contains.
      `profile cleanup` restores the removed value.
  - key: "`env.CLAUDE_CODE_ENABLE_GATEWAY_MODEL_DISCOVERY`"
    value: |
      `1`, which turns on the model discovery from the gateway.
      Discovery has an effect only in the `anthropic` mode.
  - key: "`env.CLAUDE_CODE_API_KEY_HELPER_TTL_MS`"
    value: "`300000`, a 5-minute cache for the `apiKeyHelper` result."
  - key: "`env.ANTHROPIC_AUTH_TOKEN` and `env.ANTHROPIC_API_KEY`"
    value: Empty, so a key in the shell doesn't replace the sign-in.
  - key: "Model keys, such as `env.ANTHROPIC_MODEL`"
    value: The models that the profile names.
  - key: "Feature switches, such as `env.DISABLE_TELEMETRY`"
    value: "The {{ site.claude_code }} features that the profile turns off or on."
  - key: "`env.ANTHROPIC_CUSTOM_HEADERS`"
    value: The headers that the profile's `attribution` block names, when the profile has one.
  - key: "`hooks`"
    value: |
      For a `subscription` profile, a hook on {{ site.claude_code }} session events adds `x-kong-id-token` with a short-lived access token from the identity provider to `env.ANTHROPIC_CUSTOM_HEADERS`, so the gateway can identify the developer of each request.
      The hook makes the settings file readable by its owner only, because the header contains a token.
      `profile activate` itself doesn't write a token.
      When the gateway or the profile names a model that can't run WebSearch, a `PostToolUse` hook on WebSearch replaces a result without a search with a statement that no search ran.
{% endtable %}

In the `foundry` and `mantle` modes, `profile activate` also writes the following keys:

- `availableModels`, an allowlist with only the profile's models, so the model picker shows only these models
- `replaceBuiltInOptions`, which hides the built-in models
- `env.ANTHROPIC_DEFAULT_MODEL`, set to the profile's default model

{% comment %}
`profile activate` also writes the settings of each other agent CLI that the profile sets up.
For the settings of the other agent CLIs, see [`profile activate`](/kong-harnesses/profile/activate/).
{% endcomment %}
`profile activate` refuses a credential that the {{ site.claude_code }} settings file already contains in `env.ANTHROPIC_AUTH_TOKEN` or `env.ANTHROPIC_API_KEY`.
In the `foundry` mode, [`doctor`](/kong-harnesses/doctor/) fails when the shell or the settings file sets `ANTHROPIC_FOUNDRY_API_KEY` or `ANTHROPIC_FOUNDRY_AUTH_TOKEN`, because {{ site.claude_code }} would send that key instead of the sign-in.

### Cleanup

[`kong-harnesses profile cleanup`](/kong-harnesses/profile/cleanup/) restores each value that activation replaced, when the key still has the value that activation wrote.
A value that the developer changed after activation stays as the developer left it.
Cleanup changes only agent CLI settings, and keeps the installed profiles and the saved sign-ins.

## Profile hosting

Developers install a profile from a file or from a URL, so you must make the profile available to them.
Export the installed profile as a JSON file with [jq](https://jqlang.org/):

```sh
kong-harnesses profile get PROFILE_NAME -o json | jq '.profile' > PROFILE_NAME.json
```

For the file encodings that `profile import` accepts, see [Profile file encoding](/kong-harnesses/profile-file/#profile-file-encoding).

Give the file to developers, who run `setup` with its path, or host it at an HTTPS URL, which developers pass to `setup`.

{:.warning}
> Host the profile where only administrators can change it.
> The profile names the gateway and the identity provider that get each developer's sign-in, so anyone who can change the file can send those sign-ins somewhere else.

{{site.kong_harnesses}} downloads a profile only when the URL and the server meet the following rules:

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
    rule: 5 seconds each to connect, to finish the TLS handshake and to receive the response headers, and 10 seconds for the whole download.
  - item: Access
    rule: "{{site.kong_harnesses}} doesn't send cookies or credentials, so the server must answer without a sign-in."
  - item: Network
    rule: |
      TLS 1.2 or later.
      {{site.kong_harnesses}} trusts the server certificate through the system trust store, and uses the proxy from `HTTPS_PROXY` and `NO_PROXY`.
{% endtable %}

### Profile updates

To change the profile, publish the new file at the same URL or give developers the new file.
When the change keeps the profile's [security identity](/kong-harnesses/profile-file/#security-identity), developers run the same `setup` command again.
When the change alters the security identity, `setup` stops while an agent CLI still uses the old profile.
Developers then run `kong-harnesses profile cleanup` and run `setup` again, which signs them in again.
