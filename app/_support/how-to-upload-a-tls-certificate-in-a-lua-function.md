---
title: How to upload a TLS certificate in a lua function
content_type: support
description: When uploading a TLS certificate and private key as strings in a Lua function, use the `\z` escape sequence and the concatenation operator to avoid parsing errors.
tldr:
  q: How do I upload a TLS certificate string in a Lua function without parsing errors?
  a: |
    Lua has no multi-line strings and treats `--` lines as comments, so a raw PEM breaks parsing.
    Use the `\z` escape sequence to join lines, add explicit `\n` characters, and concatenate the `-----END...-----` markers with `..`. Reading `ngx.ssl` also requires setting `untrusted_lua_sandbox_requires`.
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources: []
---

## Overview

When trying to upload a TLS certificate in a lua function you may have errors parsing the certificate as string. How should the certificate string be configured?

## Steps

When uploading a TLS certificate and private key as strings, you may have parsing errors due to the following issues:

1. You can't have a multiple line string in lua

2. As the lines staring with ` -- ` are comments, this is an issue particularly for lines `-----END CERTIFICATE`

To solve the issue (1) lua has the escape sequence `\z` which skips all subsequent characters in a string literal until the first non-space character. This works for non-multiline literal text too.

For issue (2) you should enclose ` -----END CERTIFICATE----- ` as a string, and then use the `..` contact operator.

After changing the above, there's a new issue: the certificate won't be handled properly without the line breaks. To prevent this problem you should also add the `\n` new line character.

Your certificate should be configured as below:

```lua
local ssl = require 'ngx.ssl'

local certificate = assert(ssl.parse_pem_cert("-----BEGIN CERTIFICATE-----\n\z
MIIGGDCCBACgAwIBAgICAs8wDQYJKoZIhvcNAQELBQAwSzEVMBMGA1UEAwwMYXBp\n\z
some-other-lines\n\z
some-other-lines\n\z
NGoF/n/sACjBRvUetDoALyV52S8FJSl5xuuvqA==\n" ..
"-----END CERTIFICATE-----"))

local privateKey = assert(ssl.parse_pem_priv_key("-----BEGIN RSA PRIVATE KEY-----\n\z
MIIJKQIBAAKCAgEAvZUkl5zND6187s90V6/bBjhr7bJMvcJ98Mz0oJma8SBiHYOx\n\z
some-other-lines\n\z
some-other-lines\n\z
jXg8wzEwpm6OGDFgfzVX8/W44ajHe6BOawW7Bet4igtZxhxqqbowDx3LvAo4\n" ..
"-----END RSA PRIVATE KEY-----"))

local ok, err = kong.service.set_tls_cert_key(certificate, privateKey)
```

Note the above code requires configuring `untrusted_lua_sandbox_requires`:

```
untrusted_lua=sandbox
untrusted_lua_sandbox_requires=ngx.ssl
```
