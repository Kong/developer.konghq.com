---
title: How to use a custom environment variable in a custom plugin or serverless-functions plugin when Kong is installed via a Helm chart
content_type: support
description: "Use the `kong.vault.get()` method to load a custom environment variable set via a Helm chart's `customEnv` values into a custom or serverless-functions plugin."
products:
  - gateway
  - kic
works_on:
  - on-prem
  - konnect
related_resources:
  - text: "`kong.vault.get()` reference"
    url: "/gateway/pdk/reference/kong.vault/#kong-vault-get-reference"
tldr:
  q: How do I use a custom environment variable in a custom or serverless-functions plugin when Kong is installed via a Helm chart?
  a: |
    Use `kong.vault.get()` to read a custom environment variable. Define the variable under `customEnv` in the Helm chart's `values.yaml`, then reference it in the plugin config with `kong.vault.get("{vault://env/<name>}")` — for example in a pre-function plugin's `config.access`.
---

## Overview

We installed Kong via a Helm chart and want to use a custom environment variable in a custom plugin or serverless-functions plugin. How could we implement that?

## Steps

It is possible to use the `kong.vault.get()` method to load custom environment variables.

Please follow the steps below as a reference:

1. Set the `customEnv` section in `values.yaml` and deploy Kong via the Helm chart:

   ```yaml
   # please set it in the root level of values.yaml
   customEnv:
     test_env: abc
   ```

2. Create the following service/route objects in Kong for testing purposes:

   ```yaml
   service:
     name: test
     url: https://httpbin.org/anything
     route:
       name: test
       path: /test
   ```

3. Enable a global pre-function plugin with the following configuration:

   ```yaml
   config.access: kong.response.add_header("test-env", kong.vault.get("{vault://env/test_env}"))
   ```

4. Send a request to the service/route objects created in step 2. Here we assume Kong is running at `localhost:8000`:

   ```bash
   curl http://localhost:8000/test -i
   ```

   Response:

   ```
   HTTP/1.1 200 OK
   Content-Type: application/json
   Content-Length: 379
   Connection: keep-alive
   test-env: abc
   Server: gunicorn/19.9.0
   Date: Mon, 06 Feb 2023 15:29:15 GMT
   Access-Control-Allow-Origin: *
   Access-Control-Allow-Credentials: true
   X-Kong-Upstream-Latency: 19
   X-Kong-Proxy-Latency: 1
   Via: kong/3.14.0.0-enterprise-edition

   ...
   ```

Here we could see the `test-env` response header has the value of `abc`, showing the pre-function plugin successfully loaded the custom environment variable defined in step 1.
