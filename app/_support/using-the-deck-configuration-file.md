---
title: Using the decK configuration file
content_type: support
description: decK can store global parameters like the Kong host and Admin token in a config file (`$HOME/.deck.yaml` by default) to make it easy to switch between environments.
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: How do I use a config file to store decK's global connection parameters?
  a: |
    decK reads global settings such as the Kong host and Admin token from a config file — `$HOME/.deck.yaml` by default, or a different file passed with `--config`. Use the sample config on GitHub as a starting point and set only the parameters you need, for example `kong-addr`, `headers`, and `tls-skip-verify`.
related_resources:
  - text: the sample provided here
    url: https://github.com/Kong/deck/blob/main/examples/deck.yml
---

## Problem

decK supports using a config file to store global parameters such as the Kong host & Admin token.How can this be configured to switch easily between environments?

## Solution

The default configuration file used is `$HOME/.deck.yaml`.

If this does not exist it can be created using the sample provided here.

```yaml

kong-addr: http://kong-instance1:8001
headers:
- "kong-admin-token: xyz"
- "kong-debug:1"
no-color: false
verbose: 0

tls-skip-verify: false
ca_cert :
```

To specify a different file to use you can pass in the `--config` parameter

`./deck --config /deck/qa.yml`

A list of available options is below:

<!--vale off -->
{% table %}
columns:
  - title: Parameter
    key: parameter
  - title: Description
    key: description
rows:
  - parameter: "`kong-addr`"
    description: "HTTP Address of Kong's Admin API."
  - parameter: "`headers`"
    description: "HTTP Headers(key:value) to inject in all requests to Kong's Admin API"
  - parameter: "`tls-server-name`"
    description: "Name to use to verify the hostname in Kong's Admin TLS certificate"
  - parameter: "`ca-cert`"
    description: "Custom CA certificate (raw contents) to use to verify Kong's Admin TLS certificate"
  - parameter: "`ca-cert-file`"
    description: "Path to a custom CA certificate to use to verify Kong's Admin TLS certificate"
  - parameter: "`verbose`"
    description: "Enable verbose logging levels. Setting this value to `2` outputs all HTTP requests/responses between decK and Kong"
  - parameter: "`no-color`"
    description: "disable colorized output"
  - parameter: "`skip-workspace-crud`"
    description: "Skip API calls related to Workspaces (Kong Enterprise only)"
  - parameter: "`konnect-email`"
    description: "Email address associated with your Konnect account"
  - parameter: "`konnect-password`"
    description: "Password associated with your Konnect account"
  - parameter: "`konnect-password-file`"
    description: "File containing password to your Konnect account"
  - parameter: "`tls-skip-verify`"
    description: "Disable verification of Kong's Admin TLS certificate"
  - parameter: "`kong-cookie-jar-path`"
    description: |
      Absolute path to a cookie-jar file in the Netscape cookie format for auth with Admin Server. You may also need to pass in as header the User-Agent that was used to create the cookie-jar
  - parameter: "`analytics`"
    description: "Share anonymized data to help improve decK"
  - parameter: "`timeout`"
    description: "Set a request timeout for the client to connect with Kong (in seconds)"
  - parameter: "`tls-client-cert`"
    description: |
      Path to the file containing TLS client certificate to use for authentication with Kong's Admin API. This value can also be set using `DECK_TLS_CLIENT_CERT_FILE` environment variable. Must be used in conjunction with `tls-client-key-file`
  - parameter: "`tls-client-key`"
    description: |
      Path to file containing the private key for the corresponding client certificate. This value can also be set using `DECK_TLS_CLIENT_KEY_FILE` environment variable. Must be used in conjunction with `tls-client-cert-file`
  - parameter: "`konnect-addr`"
    description: "Address of the Konnect endpoint"
  - parameter: "`konnect-control-plane-name`"
    description: "Konnect Control Plane name (renamed from konnect-runtime-group-name in current decK versions)"
{% endtable %}
<!--vale on -->
