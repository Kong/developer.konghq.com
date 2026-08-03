---
title: How to use the secret management function when running Kong with systemd
content_type: support
description: Systemd does not support the `export` command for setting environment variables directly, so Kong's secret management values must be loaded using systemd's `Environment` or `EnvironmentFile` directives instead.
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources:
  - text: Running Kong with systemd
    url: /gateway/production/running-kong/systemd/
tldr:
  q: Why doesn't Kong's secret management function work when loading environment variables under systemd?
  a: |
    Systemd does not support the `export` command for setting environment variables, so exporting
    them directly does not work. Instead, load them using the `Environment` directive (single-line
    values) or the `EnvironmentFile` directive (multi-line values, such as certificates) in the
    `kong.service` file.
---

## Problem

Kong is running with systemd:

```bash
systemctl start kong
```

I followed https://support.konghq.com/support/s/article/how-to-import-certificate-object-from-environment-variables-to-kong-by-using-secret-management-function to use the secret management function to load the environment variables.

However it is not working, how to solve it?

## Cause

When running Kong with systemd, we can not use the `export` command to export the environment variables directly.

## Solution

Instead, systemd requires loading the environment variables by using any of the methods below.

1. Use the `Environment` directive in the `kong.service` file:

   ```
   [Service]
   ...
   Environment=MY_SECRET=abc
   ...
   ```

2. Use the `EnvironmentFile` directive in the `kong.service` file (use this method if the environment variables have multiple lines):

   1. Firstly write the environment variables in a text file (let's call it `env.txt`) like the example below:

      ```
      MY_SECRET_CERT='-----BEGIN CERTIFICATE-----
      <YOUR PUBLIC CERTIFICATE CONTENT>
      -----END CERTIFICATE-----'
      MY_SECRET_KEY='-----BEGIN PRIVATE KEY-----
      <YOUR PRIVATE KEY CONTENT>
      -----END PRIVATE KEY-----'
      ```

   2. Next refer to the above text file (`env.txt`) in the `kong.service` file:

      ```
      [Service]
      ...
      EnvironmentFile=/path/to/env.txt
      ...
      ```

      Please replace `/path/to/env.txt` with the actual file location where you put the environment variables.

Now you should be able to load the environment variables by following from step 2 of these instructions: https://support.konghq.com/support/s/article/how-to-import-certificate-object-from-environment-variables-to-kong-by-using-secret-management-function
