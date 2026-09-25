---
title: "FIPS 140-3 compliance in {{site.ai_gateway}}"
content_type: reference
layout: reference

breadcrumbs:
  - /ai-gateway/

products:
  - ai-gateway

works_on:
  - konnect

tools:
  - kongctl
  - konnect-api

min_version:
  ai-gateway: '2.2'

description: |
  Learn how to enable FIPS mode and how {{site.ai_gateway}} is FIPS 140-3 compliant.

tags:
  - ai
  - security

related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/
---

The Federal Information Processing Standard (FIPS) 140-3 is a federal standard defined by the National Institute of Standards and Technology. It specifies the security requirements that must be satisfied by a cryptographic module.

The FIPS {{site.ai_gateway}} package is FIPS 140-3 compliant. Compliance means that {{site.ai_gateway}} only uses FIPS 140-3 approved algorithms while running in FIPS mode, but the product has not been submitted to a NIST testing lab for validation.

{{site.ai_gateway}} provides the FIPS 140-3 compliant package for [supported distributions](/ai-gateway/version-support-policy/), including distroless packages. This package provides compliance for the core {{site.ai_gateway}} product and all out-of-the-box policies.

The package uses the OpenSSL FIPS Provider 3.1.2 to provide FIPS 140-3 validated cryptographic operations.

## Configure FIPS

To start a data plane in FIPS mode, set the following configuration property to `on` in the `kong.conf` configuration file before starting {{site.ai_gateway}}:

```
fips = on # fips mode is enabled, causing incompatible ciphers to be disabled
```

You can also set this configuration using an environment variable:

```bash
export KONG_FIPS=on
```

{:.warning}
> **Warning**: Migrating from non-FIPS to FIPS mode, or the reverse, is not supported.

## Password hashing

The following table describes how {{site.ai_gateway}} uses key derivation functions:

<!--vale off-->
{% table %}
columns:
  - title: Component
    key: component
  - title: Normal mode
    key: normal
  - title: FIPS mode
    key: fips
  - title: Notes
    key: notes
rows:
  - component: "core/rbac"
    normal: "bcrypt"
    fips: "PBKDF2 <sup>1</sup>"
    notes: "Compliant via OpenSSL 3.1.2 FIPS provider"
  - component: "plugins/oauth2 <sup>2</sup>"
    normal: "Argon2 or bcrypt (when `hash_secret=true`)"
    fips: "Disabled (`hash_secret` can't be set to `true`)"
    notes: "Compliant via OpenSSL 3.1.2 FIPS provider"
  - component: "plugins/key-auth-enc <sup>3</sup>"
    normal: "SHA1"
    fips: "SHA256"
    notes: "SHA1 is read-only in FIPS mode."
{% endtable %}
<!--vale on-->

## Non-cryptographic usage of cryptographic algorithms

FIPS only defines the approved algorithms to use for each specific purpose, so FIPS policy doesn't explicitly restrict the usage of cryptographic algorithms to only cases where they are necessary.

For example, using SHA-256 as the message digest algorithm is approved, while MD5 is not. However, that doesn't mean MD5 must be completely absent from the application.

The following table explains where cryptographic algorithms are used for non-cryptographic purposes in {{site.ai_gateway}}:

<!--vale off-->
{% table %}
columns:
  - title: Component
    key: component
  - title: Normal mode
    key: normal
  - title: FIPS mode
    key: fips
  - title: Notes
    key: notes
rows:
  - component: "core/balancer"
    normal: "xxhash32"
    fips: "xxhash32"
    notes: "Used to generate a unique identifier."
  - component: "core/balancer"
    normal: "crc32"
    fips: "crc32"
    notes: "crc32 isn't a message digest."
  - component: "core/uuid"
    normal: "Lua random number generator"
    fips: "Lua random number generator"
    notes: "The RNG isn't used for cryptographic purposes."
  - component: "core/declarative_config/uuid"
    normal: "UUIDv5 (namespaced SHA1)"
    fips: "UUIDv5 (namespaced SHA1)"
    notes: "Used to generate a unique identifier."
  - component: "core/declarative_config/config_hash and core/hybrid/hashes"
    normal: "MD5"
    fips: "MD5"
    notes: "Used to generate a unique identifier."
  - component: |
      core/kong_request_id
    normal: "rand(3)"
    fips: "rand(3)"
    notes: "The RNG isn't used for cryptographic purposes."
{% endtable %}
<!--vale on-->

## SSL client

FIPS 140-3 defines requirements for the cryptographic module, not for SSL client roles. {{site.ai_gateway}} does not enforce a FIPS-specific policy on outbound clients. 

Traffic that traverses {{site.ai_gateway}}'s own inbound and outbound TLS enforcement does honor the TLS 1.2/1.3 and applies the following constraints:

{% table %}
columns:
  - title: Rejected item
    key: item
  - title: Details
    key: details
rows:
  - item: "TLS 1.0 and 1.1"
    details: "Rejected at any surface Kong terminates."
  - item: "TLS 1.2 without EMS"
    details: "The handshake fails."
  - item: "Non-AES-GCM cipher suites"
    details: "The cipher list is fixed to approved AES-GCM profiles. Low-level SSL overrides no longer widen it."
  - item: "MD5 and ChaCha20"
    details: "Rejected under default OpenSSL properties."
  - item: "SAML request SHA-1 signatures"
    details: "Rejected."
  - item: "HMAC-SHA1 authentication configuration"
    details: "Rejected."
  - item: "Ed25519 / Ed448 JWKS generation"
    details: "Use RSA-PSS or a NIST-curve ECDSA key (for example P-256, P-384) instead."
  - item: "Application-supplied IVs for AES-GCM"
    details: "The FIPS provider generates the IV inside the cryptographic boundary."
  - item: "Keyring RSA keys below 2048 bits"
    details: "Rejected at configuration validation, before startup completes."
  - item: "`hash_secret = true` on the OAuth2 plugin"
    details: "The setting is disabled in FIPS mode. Use [secrets management](/gateway/secrets-management/) or [database encryption](/gateway/keyring/) instead."
{% endtable %}
