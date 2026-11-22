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
> A CA setting changes only the program that reads it.
> The browser that opens for the sign-in must also trust the certificate of the identity provider.

## System trust store installation

Add the CA certificate, a PEM file, to the system trust store:

{% navtabs "system-trust-store" %}
{% navtab "macOS" %}

```sh
sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain CA_CERTIFICATE_FILE
```

You can also deploy the certificate with an MDM certificate payload.

{% endnavtab %}
{% navtab "Linux" %}

On Debian and Ubuntu:

```sh
sudo cp CA_CERTIFICATE_FILE /usr/local/share/ca-certificates/gateway-ca.crt
sudo update-ca-certificates
```

On Fedora and RHEL:

```sh
sudo cp CA_CERTIFICATE_FILE /etc/pki/ca-trust/source/anchors/
sudo update-ca-trust
```

On Alpine, run these commands as root:

```sh
apk add ca-certificates
cp CA_CERTIFICATE_FILE /usr/local/share/ca-certificates/gateway-ca.crt
update-ca-certificates
```

{% endnavtab %}
{% navtab "Windows" %}

Run this command in PowerShell as an administrator:

```powershell
certutil -addstore -f Root CA_CERTIFICATE_FILE
```

You can also deploy the certificate with Group Policy or Intune.

Each WSL distribution has its own trust store.
Install the CA in each distribution with the commands of the **Linux** tab.

{% endnavtab %}
{% endnavtabs %}

## {{ site.claude_code }} installs

These installs of {{ site.claude_code }} install the same native binary:

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
When `CLAUDE_CODE_CERT_STORE` is set without `system`, add `system` to it.
An older npm install that runs {{ site.claude_code }} on Node.js reads the system trust store only on Node.js 22.15 or later, so update it to the native binary or set `NODE_EXTRA_CA_CERTS` for it.
For these limits, see the [{{ site.claude_code }} CA certificate store](https://code.claude.com/docs/en/network-config#ca-certificate-store).

## Agent CLIs that need more than the system trust store

Sign in to Hermes Agent with `hermes auth add kong-ai-gateway`.
The sign-in script of its {{site.ai_gateway}} plugin doesn't use `truststore`, so it reads only the default certificate paths of OpenSSL and not every CA in the system trust store.

omp, and pi on Node.js or from its Bun release archives, read these variables in the environment where they start:

{% table %}
columns:
  - title: Variable
    key: variable
  - title: Effect
    key: effect
rows:
  - variable: "`NODE_EXTRA_CA_CERTS` set to the CA file"
    effect: |
      pi adds the file to the CAs that it already trusts.
      omp trusts only Bun's bundled CA list and that file.
      omp then stops reading the default CA file and directory of the system and the system trust store, so put every private CA that omp needs in that file, such as the CA of a proxy.
  - variable: "`NODE_USE_SYSTEM_CA=1`"
    effect: |
      pi also trusts the system trust store, but by default not on Node.js from Homebrew.
      pi on Node.js reads this variable only on Node.js 22.19 or a later 22 release, or on Node.js 24.6 or later, so set `NODE_EXTRA_CA_CERTS` on an earlier release, such as Node.js 24.0 to 24.5.
      omp also trusts the system trust store only when `NODE_EXTRA_CA_CERTS` isn't set.
{% endtable %}

When the environment doesn't set `NODE_EXTRA_CA_CERTS`, omp also reads it from these `.env` files, and the first value that isn't empty wins:

1. `.env` and the other dotenv files that Bun loads from the directory where omp starts, such as `.env.local`
1. `~/.omp/agent/.env`
1. `~/.omp/.env`
1. `~/.env`

When `OMP_PROFILE` names a profile, omp reads `~/.omp/profiles/PROFILE_NAME/agent/.env` and `~/.omp/profiles/PROFILE_NAME/.env` in place of the second and third file, which belong to the default omp profile.

pi on Node.js needs Node.js 22.19 or later.

Whether omp and pi need one of these variables depends on the system:

{% navtabs "omp-pi-ca" %}
{% navtab "macOS" %}

omp and pi don't read the macOS keychain by default, so set one of the variables for a CA that you added to the keychain.

pi on Node.js from Homebrew trusts the CA bundle of the Homebrew `ca-certificates` package and by default ignores `NODE_USE_SYSTEM_CA`.
Homebrew builds that bundle from the certificates trusted for SSL in the System keychain (`/Library/Keychains/System.keychain`), the certificates of `/System/Library/Keychains/SystemRootCertificates.keychain` and the Mozilla certificates.
Run `brew postinstall ca-certificates` after you add the CA, or set `NODE_EXTRA_CA_CERTS`.

{% endnavtab %}
{% navtab "Linux" %}

omp and the Bun release archives of pi also read the CA file `/etc/ssl/cert.pem`, or the file that `SSL_CERT_FILE` names, and the CA directory `/etc/ssl/certs`.
A CA that the CA tool of the distribution adds to these paths works for them without a variable:

* On Debian and Ubuntu, `update-ca-certificates` adds the CA to the directory `/etc/ssl/certs`.
* On Alpine, `update-ca-certificates` adds the CA to the bundle that `/etc/ssl/cert.pem` links to.
* On Fedora, `update-ca-trust` adds the CA to the bundle that `/etc/ssl/cert.pem` links to.

When `NODE_EXTRA_CA_CERTS` is set, omp stops reading these paths, and pi keeps reading them.

A `nodejs` package of Debian, Ubuntu, Fedora or Alpine that meets the pi minimum reads the CA paths of the distribution, so a CA that these steps add works for pi on that Node.js without a variable.
Debian 12 and 13 and Ubuntu 24.04 ship Node.js 18 or 20, which pi can't run on.

pi on a Node.js build from nodejs.org or nvm trusts only its own CA list by default, and so do omp and pi on a distribution that keeps its CAs in other paths, so set one of the variables for them.

pi on Node.js from Homebrew trusts the CA bundle of the Homebrew `ca-certificates` package and by default ignores `NODE_USE_SYSTEM_CA`.
Homebrew builds that bundle from the Mozilla certificates and the first readable system bundle of `/etc/ssl/certs/ca-certificates.crt`, `/etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem` and `/etc/ssl/ca-bundle.pem`, in that order.
When Homebrew finds none of these bundles or no `openssl` command, the bundle holds only the Mozilla certificates.
Run `brew postinstall ca-certificates` after you add the CA, or set `NODE_EXTRA_CA_CERTS`.

{% endnavtab %}
{% navtab "Windows" %}

omp and pi don't read the Windows certificate store by default, so set one of the variables.

{% endnavtab %}
{% endnavtabs %}

## CA settings per program

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
      The sign-in script of the plugin doesn't read `~/.hermes/.env`, so sign in with `hermes auth add kong-ai-gateway`.
  - program: OpenCode
    setting: |
      `NODE_EXTRA_CA_CERTS` set to the CA file.
      When OpenCode runs as a background service, it doesn't read later shell exports, so set the variable for the service with `opencode service set env`.
  - program: "{{site.kong_harnesses}}"
    setting: |
      `SSL_CERT_FILE` set to a bundle file with the public root CAs of the system and each private CA, exported in the shell that runs {{site.kong_harnesses}} and in the shell that starts {{ site.claude_code }}, Codex, omp or pi, because these agent CLIs run {{site.kong_harnesses}} to get each token.
      OpenCode and Hermes Agent sign in through their own plugins and don't run {{site.kong_harnesses}} for a token.
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

With the `GODEBUG` value that you set after you create the bundle, the file replaces the system trust store for {{site.kong_harnesses}}, so a file with only the private CA breaks the token renewal with a public identity provider, and the profile download from a public profile server.

Windows adds a public root CA to its certificate store only when it first needs it.
Connect once in PowerShell to the gateway, to the identity provider of a profile that signs in through one, and to the profile server of a profile that you import from an HTTPS URL, so that Windows adds the root CA of each server.
Skip the gateway when it runs on the local computer with a plain `http` URL.

```powershell
Invoke-WebRequest -UseBasicParsing https://SERVER_HOST | Out-Null
```

An error for the HTTP status is fine, because Windows checks the certificate chain before the request gets the status.
A TLS error is expected for a server with a certificate from your private CA, because Windows gets only public root CAs this way.
The bundle gets the root of your private CA from the CA certificate file in the next step.

Create the bundle in PowerShell from the root CAs of the Windows certificate store and your CA:

```powershell
$roots = Get-ChildItem Cert:\LocalMachine\Root | ForEach-Object {
  "-----BEGIN CERTIFICATE-----`n" + [Convert]::ToBase64String($_.RawData, 'InsertLineBreaks') + "`n-----END CERTIFICATE-----"
}
@($roots) + (Get-Content -Raw CA_CERTIFICATE_FILE) | Set-Content -Encoding ascii CA_BUNDLE_FILE
```

Set both variables, with the full path of the bundle, in the PowerShell session that runs {{site.kong_harnesses}} and in the session that starts {{ site.claude_code }}, Codex, omp or pi:

```powershell
$env:SSL_CERT_FILE = (Resolve-Path CA_BUNDLE_FILE).Path
$env:GODEBUG = "x509sslcertoverrideplatform=1"
```

In the same session, install the profile if it isn't installed yet:

```powershell
kong-harnesses profile import PROFILE_URL
```

When the import or the CA bundle check reports an unknown certificate authority for a server, check that the bundle holds the root CA of that server.
For a server with a certificate from your private CA, this is the root CA that your administrator gave you.
If the bundle doesn't hold it, add that root CA certificate to the bundle, or create the bundle again, and then run the command again.
If the bundle holds it, ask your administrator to check the certificate chain that the server sends.
When a Windows policy [stops the automatic update of root CAs](https://learn.microsoft.com/en-us/windows-server/identity/ad-cs/configure-trusted-roots-disallowed-certificates#registry-settings-modified), ask your administrator for a public root CA that the bundle is missing.

A new bundle doesn't fix an expired certificate or a host name mismatch.
For a certificate that is expired or not valid yet, check the clock of the computer first, because a wrong clock gives the same error.
When the clock is right, ask your administrator to check the dates of the certificate of the server.
For a host name mismatch of the profile server, check the host in the profile URL.
When the URL is right, or for another server, ask your administrator to fix the certificate of the server.

Run the doctor checks for the profile:

```powershell
kong-harnesses doctor --profile PROFILE_NAME
```

The CA bundle check of the `SSL_CERT_FILE` file must show OK for each server that you sent a web request to, also when that request gave a TLS error.
When the check reports a missing or unreadable file, check the path in the variable that the result names.
When the check fails for a server, use the fixes after the import step.

{% endnavtab %}
{% endnavtabs %}
