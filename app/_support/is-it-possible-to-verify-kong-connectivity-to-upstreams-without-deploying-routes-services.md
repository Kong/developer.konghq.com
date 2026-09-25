---
title: Verifying Kong connectivity to Upstreams without deploying Routes/Services
content_type: support
description: "Kong bundles its own OpenSSL libraries, so you can verify TLS connectivity to an upstream and check for certificate issues before deploying any Routes or Services, using the `kong runner` command to run a Lua test script."
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources:
  - text: badssl.com
    url: https://badssl.com
tldr:
  q: Is it possible to verify Kong connectivity to Upstreams without deploying Routes/Services?
  a: |
    Kong bundles its own OpenSSL rather than using the host's, so you can verify TLS connectivity to an upstream — including certificate validity — without deploying a Route or Service, by running a Lua script with `kong runner`. `tls_certificate_verify` defaults to `on` globally and blocks unverified connections unless explicitly disabled in `kong.conf`.
---

## Problem

Confirming Kong's connectivity to Upstreams — particularly verifying connectivity to HTTPS upstreams and checking for certificate issues — normally requires deploying Routes/Services first, before rolling out new or updated Service entities.

## Solution

Kong bundles its own OpenSSL libraries within the OpenResty binaries, and does not rely on the OpenSSL version installed on the host operating system. This means that any OpenSSL-related testing or configuration should ideally be done using Kong's bundled OpenSSL to ensure consistency with the runtime environment.

To test TLS connections and verify whether an upstream service's certificate and key meet the required security standards (e.g., SECLEVEL=2), you can use the `kong runner` command to execute Lua scripts that perform HTTP requests over TLS, incorporating Kong's bundled OpenSSL settings. Below is an example script and how to run it:

#### 1. Create a Lua script for testing HTTPS connections.

Save this script to a file, for example `/usr/local/kong/scripts/https.lua`

```lua

local http = require "resty.http"

local function get_http_params()
  local host, ssl_verify
  if #args < 2 then
    print(
      "Running in interactive mode. If you wish to specify at the CLI please use the following positional arguments\nUsage: http.lua <endpoint> <ssl_verify>\n")
    io.write("Enter your HTTP endpoint: ")
    io.flush()
    host = io.read()
    io.write("Verify SSL server certificate : ")
    io.flush()
    ssl_verify = io.read()
  else
    host = args[2]
    ssl_verify = args[3]
  end

  if ssl_verify == "true" then
    ssl_verify = true
  else
    ssl_verify = false
  end

  return host, ssl_verify
end

local function connect(host, ssl_verify)
  local method = "GET"

  local httpc = http.new()
  httpc:set_timeout(5000)

  local res, err = httpc:request_uri(host, {
    method = method,
    ssl_verify = ssl_verify
  })

  if not res then
    print("failed request to " .. host .. " " .. err)
  else
    print("Request to " .. host .. " succeeded")

  end
end

local host, ssl_verify = get_http_params()
connect(host, ssl_verify)
```

#### 2. Execute the script using `kong runner`

The script takes two parameters, the upstream host and a true/false flag to indicate whether to verify the SSL certificate. For example (replace `https://your-upstream-service.com` with the actual endpoint you wish to test);

```bash

kong runner /usr/local/kong/scripts/https.lua https://your-upstream-service.com true
```

#### 3. Example of executing the script using `kong runner`

You can use the badssl.com site to check the connection results for several different common types of certificate;

```bash

# kong runner /usr/local/kong/scripts/https.lua https://no-common-name.badssl.com/ true
failed request to https://no-common-name.badssl.com/ 10: certificate has expired

# kong runner /usr/local/kong/scripts/https.lua https://dh512.badssl.com/ true
2026/09/02 14:43:35 [crit] 4861#0: *2 SSL_do_handshake() failed (SSL: error:030000A8:digital envelope routines::unknown security bits error:0A00018A:SSL routines::dh key too small), context: ngx.timer
failed request to https://dh512.badssl.com/ handshake failed
```

Important: `tls_certificate_verify` defaults to `on` globally, and this blocks the `ssl_verify=false` bypass this script's second parameter is meant to provide — attempting it produces a hard error instead of a successful, unverified connection:

```bash

# kong runner /usr/local/kong/scripts/https.lua https://no-common-name.badssl.com/ false
failed request to https://no-common-name.badssl.com/ detected attempt to disable certificate verification while global tls_certificate_verify option is enabled.
```

If you genuinely need to bypass verification for a one-off connectivity check, the global option must be disabled first (`tls_certificate_verify = off` in `kong.conf`/`KONG_TLS_CERTIFICATE_VERIFY=off`, on a non-production node) — this is a global, node-wide setting, not something the script itself can override per-call.

This approach allows you to test HTTPS connections using Kong's internal mechanisms and OpenSSL configuration, providing a more accurate representation of how Kong will interact with upstream services in your environment.
