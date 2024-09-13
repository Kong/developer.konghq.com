---
title: Using environment variables with decK

content_type: reference
layout: reference

works_on:
    - on-prem
    - konnect

tags:
  - api-ops

tools:
  - deck
---

To manage any values in decK files with environment varaibles, you can create environment variables 
with the `DECK_` prefix and reference them as `{%raw%}${{ env "DECK_*" }}{%endraw%}` in your state file.

When you use decK to apply configurations to {{site.base_gateway}},
decK reads data in plain text from a state file by default. To improve security, you
can also store sensitive information, for example `apiKey` or `client_secret`, in
environment variables. decK can then read data directly from the environment
variables and apply it.

{:.note}
> For storing {{site.base_gateway}} secrets in environment variables, see [Secrets Management with decK](/deck/latest/guides/vaults/).
The reference format for secrets is _not_ the same as references for environment variables used by decK.

The following example demonstrates how to apply an API key stored in an environment variable.
You can use this method for any sensitive content.

Create an environment variable:

```sh
export DECK_API_KEY={YOUR_API_KEY}
```

You can use now reference the environment variable in the relevant value in any state file.
For example, this snippet enables the Key Authentication plugin globally and creates
a consumer named `demo` with an API key. The API key is pulled from the `DECK_API_KEY`
environment variable instead of being exposed in the state file:

```yaml
_format_version: "3.0"
consumers:
- keyauth_credentials:
  - key: {%raw%}${{ env "DECK_API_KEY" }}{%endraw%}
  username: demo
  id: 36718320-e67d-4162-8b50-aa685e06c64c
plugins:
- config:
    anonymous: null
    hide_credentials: false
    key_in_body: false
    key_in_header: true
    key_in_query: true
    key_names:
    - apikey
    run_on_preflight: true
  enabled: true
  name: key-auth
  protocols:
  - grpc
  - grpcs
  - http
  - https
```
