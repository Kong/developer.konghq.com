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
  - text: Changes that kong-harnesses makes on a developer's computer
    url: /kong-harnesses/developer-computer-changes/
  - text: kong-harnesses setup
    url: /kong-harnesses/setup/
---

When the gateway, the identity provider or the profile server uses a certificate from a private certificate authority (CA), each computer that runs {{site.kong_harnesses}} must trust that CA.
{{site.kong_harnesses}}, {{ site.claude_code }}, Codex, OpenCode and Hermes Agent trust these servers through the system trust store.

{:.warning}
> Add the CA to the system trust store of each developer's computer and of your own computer, for example, through mobile device management (MDM).
> A CA setting of one program doesn't change the trust of a program that reads another setting, and the browser that opens for the sign-in must also trust the certificate of the identity provider.

## System trust store installation

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

Run these commands as root:

```sh
apk add ca-certificates
cp CA_CERTIFICATE_FILE /usr/local/share/ca-certificates/gateway-ca.crt
update-ca-certificates
```

{% endnavtab %}
{% endnavtabs %}

Each WSL distribution has its own trust store.
Install the CA in each distribution with the Linux commands.

## Agent CLIs that need more than the system trust store

Sign in to Hermes Agent with `hermes auth add kong-ai-gateway`.
The `scripts/login.py` sign-in script of its {{site.ai_gateway}} plugin doesn't use `truststore`, so it reads only the default certificate paths of OpenSSL and not every CA in the system trust store.

omp and pi use their own CA list by default, except on Debian and Ubuntu as the table says, so set one of these variables in the environment where they start:

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
      When `NODE_EXTRA_CA_CERTS` is set, omp uses its own CA list and the file instead of the system trust store, so put every private CA that omp needs in the file, such as the CA of a proxy.
      On Debian and Ubuntu, omp also reads `/etc/ssl/certs`, so a CA that `update-ca-certificates` installed works without a variable, and `NODE_EXTRA_CA_CERTS` set to another file removes that trust.
  - client: pi
    setting: |
      `NODE_EXTRA_CA_CERTS` set to the CA file, or `NODE_USE_SYSTEM_CA=1`, which pi on Node.js and pi's Bun release archives both read.
      If pi runs on Node.js from Homebrew and doesn't trust a CA that you added to the macOS keychain, set `NODE_EXTRA_CA_CERTS`, because that Node.js uses a copy of the keychain from when Homebrew installed its CA certificates.
      On Debian and Ubuntu, pi's Bun release archives also read `/etc/ssl/certs`, so a CA that `update-ca-certificates` installed works without a variable, and `NODE_EXTRA_CA_CERTS` set to another file removes that trust.
{% endtable %}

## {{ site.claude_code }} installs

The native installer, the npm package, the Homebrew cask, the WinGet package and the apt, dnf and apk packages of {{ site.claude_code }} install the same native binary.
That binary trusts the system trust store by default, so each of these installs needs only the CA in the system trust store.
When `CLAUDE_CODE_CERT_STORE` is set without `system`, add `system` to it.
An older npm install that runs {{ site.claude_code }} on Node.js reads the system trust store only on Node.js 22.15 or later, so update it to the native binary or set `NODE_EXTRA_CA_CERTS` for it.
For these limits, see the [{{ site.claude_code }} CA certificate store](https://code.claude.com/docs/en/network-config#ca-certificate-store).

## CA settings per program

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
      When it removes a CA bundle that an earlier {{site.kong_harnesses}} release wrote, it restores the values that `NODE_EXTRA_CA_CERTS` and `CLAUDE_CODE_CERT_STORE` had before that release, and keeps a value that you changed after it.
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
      The plugin's `scripts/login.py` doesn't read `~/.hermes/.env`, so sign in with `hermes auth add kong-ai-gateway`.
  - program: OpenCode
    setting: |
      `NODE_EXTRA_CA_CERTS` set to the CA file.
      When OpenCode runs as a background service, it doesn't read later shell exports, so set the variable for the service with `opencode service set env`.
  - program: "{{site.kong_harnesses}}"
    setting: |
      `SSL_CERT_FILE` set to a bundle file with the public root CAs of the system and each private CA, exported in the shell that runs {{site.kong_harnesses}} and in the shell that starts {{ site.claude_code }}, Codex, omp or pi, because these agent CLIs run {{site.kong_harnesses}} to get each token.
      OpenCode and Hermes Agent sign in through their own plugins and don't run {{site.kong_harnesses}} for a token.
      On Linux, the file replaces the default CA file, and {{site.kong_harnesses}} still reads the default certificate directories.
      On macOS and Windows, also export `GODEBUG=x509sslcertoverrideplatform=1`, and the file then replaces the system trust store for {{site.kong_harnesses}}.
      A file with only the private CA then breaks the token renewal against a public identity provider or a public profile server.
      On macOS, create the bundle with `cat /etc/ssl/cert.pem CA_CERTIFICATE_FILE > CA_BUNDLE_FILE`.
{% endtable %}

`profile create` doesn't take a CA bundle.
