---
title: How to configure a certificate key with Secrets Management and the Environment Variable backend
content_type: support
description: When referencing a certificate key from an environment variable with Kong's Secrets Management feature, set the certificate's `key` field to `{vault://env/<environment variable name>}` in your declarative configuration.
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: How do I configure a certificate key using Kong's Secrets Management Environment Variable backend?
  a: |
    Set the certificate's `key` field to `{vault://env/<environment variable name>}` in your declarative config (or Kong Manager) and export the referenced environment variable with the real PEM contents — e.g. `export ENV_REFERENCE_API_KEY="$(cat key.pem)"` — since a single-quoted string with literal `\n` escapes won't produce real newlines and will fail to parse.
related_resources: []
---

## Overview

We are trying to test the beta Secrets Management feature using the Environment Variable backend but we can not get a certificate key to work. What would an example look like?

## Steps

If you have a declarative configuration file to be used with deck or in a db-less configuration, you need to make sure to configure the certificate key as `{vault://env/<environment variable name that holds the key>}`

The declarative config file should look like this:

```yaml

- cert: |-
    -----BEGIN CERTIFICATE-----
    MIIFeDCCBGCgAwIBAgIUAusYGP9BwoLFFAJdB/jY6eUzUyQwDQYJKoZIhvcNAQEL
    BQAwgZIxCzAJBgNVBAYTAlVLMRIwEAYDVQQIDAlIYW1wc2hpcmUxEjAQBgNVBAcM
    CUFsZGVyc2hvdDEQMA4GA1UECgwHS29uZyBVSzEQMA4GA1UECwwHU3VwcG9ydDEY
    MBYGA1UEAwwPU3VwcG9ydCBSb290IENBMR0wGwYJKoZIhvcNAQkBFg5zdHVAa29u
    Z2hxLmNvbTAeFw0yMTAxMjAxNTA0NDVaFw0yMjAxMjAxNTA0NDVaMIGQMQswCQYD
    VQQGEwJVSzESMBAGA1UECAwJSGFtcHNoaXJlMRIwEAYDVQQHDAlBbGRlcnNob3Qx
    EDAOBgNVBAoMB0tvbmcgVUsxEDAOBgNVBAsMB1N1cHBvcnQxFjAUBgNVBAMMDW10
    bHMtY29uc3VtZXIxHTAbBgkqhkiG9w0BCQEWDnN0dUBrb25naHEuY29tMIICIjAN
    BgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEA1/+83/YNiEVKYvcuVwYGve6afsg1
    BYCn1+E9Uwgh0uwAenT/DKB8NhqoVxc7cZ2HaTI146IGmFICmctlTWvLPLglHmTo
    byOUV6tIJAjvzyEOpC458hLGgbv8mhGXJWPxBVu7Wy6Hapz2bk0cEscfL7PHKaRu
    3D6r8/zbhhWAqe4EIt+NVYT6baaYBs7bPZQXs/sluKI+DNYuDeaAmoSuCc4ein6z
    0xDqCSMmPebzjns03ttB29vWL3eYY9dvgoCd+CPhXT/C4CHtvKbH+hOQYDtVF6MO
    1mmABAQTQWMR/00+QI0xtvuXtEPurla5dA0TN6ddCTOOcILKx62z5oc3Kqr+nHHa
    71zNzARUVaZ2vy1pRVr0DZgB7KqcFXhy/oy8IpmxUR1ASBDZl6B6RKrdQwvgLgmn
    3M/roNLAU+3nz4itpt/zf+X0suwdthrflic1R68z1SlYbyoGARWkZ/pOl6kLNVK2
    OsqQuICaajnW7t1oDd7z1+3hm+uoryDwvG6f3T9ZvWjKXYcKg7b+BjbFdahbDywD
    PgnhSz9AaoVWhR+GHIPrjRClMpEkra/yGJFvH3UpXhgg9d0DrLZE51Z75a9SvnAj
    vdLuNhx4bJbwLBgNGsJMkupzBrw4iCfbKFcBbP8o0Xjtarj7T/mkWuQ1GjWqfyrD
    55NecBPNw5C9BR0CAwEAAaOBxTCBwjAJBgNVHRMEAjAAMBEGCWCGSAGG+EIBAQQE
    AwIFoDAzBglghkgBhvhCAQ0EJhYkT3BlblNTTCBHZW5lcmF0ZWQgQ2xpZW50IENl
    cnRpZmljYXRlMB0GA1UdDgQWBBSV3F+eicU8SVT4LcDJ6eMzP0todzAfBgNVHSME
    GDAWgBR2ySl/TAlFDGO3NAVlyJaZR+XZtzAOBgNVHQ8BAf8EBAMCBeAwHQYDVR0l
    BBYwFAYIKwYBBQUHAwIGCCsGAQUFBwMEMA0GCSqGSIb3DQEBCwUAA4IBAQB5L0OZ
    WELG9Pw6Ol1BsZYgpLR4PGNBB9dKm/9dd+q+ohZVFCfXcjZ3YOU1vh/HHQrALRNY
    I58JxcVCOx/qIW2uA0iSCqIT0sNb9cJLxfZf7X+BzPPPnu0ugUJp7GzLNnHitrLC
    Xb1nmmefwgraNzp+a5IrR8RcQG1mYDuS+2HK/rybo22XcCxhob8OiDEn8+ytkKyQ
    Ipmrf9D+/68/ih6az0w1aakASMmFe8z/p6VgVQkCySCWWFG525BRdGmSImqVZ4xa
    aQFN3L+oN+JJcCFTthLOAYo32JH+xLMz7PokzSL84g3b68h59hXDoMSwB10GthL5
    T8tqV6i5miKWwvfZ
    -----END CERTIFICATE-----
  id: f3ae1bb2-ea6a-4caf-a7a7-2f078b7842db
  key: '{vault://env/env_reference_api_key}'
```

In Kong Manager the certificate key needs to be entered as in the below screenshot:

The environment variable `ENV_REFERENCE_API_KEY` can be configured in the prefered way depending on the set up, e.g. set in a linux shell. The value must contain real newline characters, not a literal `\n`-escaped single-quoted string — a single-quoted shell string with literal `\n` sequences does not produce actual newlines, and the resulting PEM will fail to parse (e.g. `PEM_read_bio_PrivateKey() failed`, causing the TLS handshake to fail). The safest way to set this is to load the key file directly so real newlines are preserved:

```bash

export ENV_REFERENCE_API_KEY="$(cat key.pem)"
```

or set in a docker container etc., making sure the value is passed with real newlines rather than escaped `\n` sequences.
