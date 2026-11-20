<!--vale off-->
{% raw %}
## 0.17.1 (2026-11-19)

### Bug Fixes

* **profile:** accept plain http for a gateway on loopback
* **vault:** make sign-in work in Windows SSH and elevated sessions

### Documentation

* **license:** record the legal approval of the license terms

## 0.17.0 (2026-11-19)

### Features

* **profile:** ship subscription sign-in in release builds

### Bug Fixes

* **budget:** refuse an http gateway origin in the budget status fetch
* **doctor:** suggest only the clients the profile configures
* **login:** create the token cache entry where KeePassXC may prompt
* **threat-model:** close the gaps that need no gateway change
* **vault:** find Linux keyring items in every collection

## 0.16.1 (2026-11-18)

### Bug Fixes

* **oidc:** listen on both loopback addresses for a localhost callback
* **release:** add licenses and supplier to the release SBOMs

## 0.16.0 (2026-11-18)

### Features

* **profile:** read a CI job's static key from the environment
* **relay:** relay a person's token into a container or SSH session
* **release:** ship an SBOM for each release binary

### Bug Fixes

* **doctor:** send the model ID as set and accept thinking output
* **oidc:** make the browser sign-in page easy to read
* **relay:** name -i when the command gives relay serve no input
* **relay:** name SSH and relay import in setup hints
* **relay:** show a relay that refuses this profile in status
* **vault:** handle a keyring with no default collection

### Documentation

* **design:** give a CI job its gateway key through the environment
* **design:** resolve decision 17 for containers and SSH

## 0.15.0 (2026-11-17)

### Features

* **profile:** trust only the system store

### Documentation

* **operations:** compare with the gateway guide of 2026-11-17

## 0.14.0 (2026-11-17)

### Features

* **clients:** configure pi through a command-resolved provider
* **fleet:** let Claude Code in WSL inherit
* **hermes:** route Hermes Agent through the gateway plugin
* **mcp:** ship gateway MCP servers in release builds
* **oidc:** style the browser sign-in result pages
* **profile:** ask for gateway MCP servers in profile setup
* **profile:** ship static keys in release builds
* **profile:** use the CA bundle for the CLI only
* **subscription:** name the developer in an identity header

### Bug Fixes

* **claudesettings:** size gateway rows under 1M at 200000
* **deps:** update Go to 1.27.4
* **doctor:** drop warnings that a working static-key setup showed
* **ksai:** let autofix change the Go module files and the Go pin

### Build

* **release:** upload every release file to Cloudsmith

### Continuous Integration

* **ksai:** upgrade KSAI to v5.0.3
* **test:** run the Go suite on Windows

### Documentation

* **design:** propose decision 18 for gateway CAs
* **mcp:** reach new gateway MCP servers through one listener
* **operations:** clarify the claude.ai gateway token contract
* **qualification:** record the macOS amd64 run under Rosetta
* **readme:** give the steps to deploy the Windows installer with Intune
* **readme:** restructure install methods, add mise and go install
* **threat-model:** add the threats of the tool class

## 0.13.0 (2026-11-10)

### Features

* **release:** install shell completion with the Homebrew formula

### Build

* **release:** cut releases from a release-please pull request

### Documentation

* **threat-model:** note that immutable releases are on
{% endraw %}
<!--vale on-->
