---
title: "{{site.kong_harnesses}} and private certificate authorities"
description: "Add a private certificate authority to the system trust store so that {{site.kong_harnesses}} and each agent CLI trust the gateway, the identity provider and the profile server, and set the CA for each program when the system trust store can't change."
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
  - text: kong-harnesses profiles for administrators
    url: /kong-harnesses/profiles-for-administrators/
  - text: kong-harnesses setup
    url: /kong-harnesses/setup/
---

When the gateway, the identity provider or the profile server uses a certificate from a private certificate authority (CA), add the CA to the system trust store of each developer's computer and of your own computer, usually through mobile device management (MDM).
{{site.kong_harnesses}}, {{ site.claude_code }}, Codex, OpenCode and Hermes Agent trust these servers through the system trust store and need nothing more, except for the Hermes Agent sign-in.
The system trust store is the standard place for a private CA, and every program on the computer trusts a CA there, not only one agent CLI.
The browser that opens for the sign-in must also trust the identity provider's certificate.
Sign in to Hermes Agent with `hermes auth add kong-ai-gateway`, because the `scripts/login.py` sign-in script of its {{site.ai_gateway}} plugin doesn't use `truststore`, which Hermes Agent uses to read the system trust store.

omp and pi don't read the system trust store by default, so set one of these variables in the environment where they start:

{% table %}
columns:
  - title: Agent CLI
    key: client
  - title: Setting
    key: setting
rows:
  - client: omp
    setting: |
      `NODE_EXTRA_CA_CERTS` set to the CA file, or `NODE_USE_SYSTEM_CA=1`.
      With `NODE_EXTRA_CA_CERTS`, omp uses its own CA list and the file instead of the system trust store, so put every private CA that omp needs in the file, such as the CA of a proxy.
      On Debian and Ubuntu, omp also reads `/etc/ssl/certs`, so a CA that `update-ca-certificates` installed works without a variable, and `NODE_EXTRA_CA_CERTS` set to another file removes that trust.
  - client: pi
    setting: |
      `NODE_EXTRA_CA_CERTS` set to the CA file, or, when pi runs on Node.js, `NODE_USE_SYSTEM_CA=1`.
      On Debian and Ubuntu, pi's Bun release archives also read `/etc/ssl/certs`, so a CA that `update-ca-certificates` installed works without a variable, and `NODE_EXTRA_CA_CERTS` set to another file removes that trust.
{% endtable %}

The native installer, the npm package, the Homebrew cask, the WinGet package and the apt, dnf and apk packages of {{ site.claude_code }} install the same native binary.
That binary trusts the system trust store by default, so each of these installs needs only the CA in the system trust store.
When `CLAUDE_CODE_CERT_STORE` is set without `system`, add `system` to it.
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
  - program: Hermes Agent
    setting: |
      `SSL_CERT_FILE` set to the CA file, which Hermes Agent trusts in addition to the system trust store.
      The plugin's `scripts/login.py` doesn't use `truststore` and doesn't read `~/.hermes/.env`, so a CA file set there doesn't fix sign-in through that script.
      Sign in with `hermes auth add kong-ai-gateway` instead.
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
