---
title: "FIPS 140-3 compliance in {{site.base_gateway}}"
content_type: policy
layout: reference

products:
  - gateway

breadcrumbs:
  - /gateway/
tags:
  - fips
search_aliases:
  - FIPS
  - compliance

description: |
  Learn how to enable FIPS mode and how {{site.base_gateway}} is FIPS 140-3 compliant.

related_resources:
  - text: Version support policy
    url: /gateway/version-support-policy/
  - text: Install {{site.base_gateway}}
    url: /gateway/install/
  - text: FIPS 140-2 (legacy) reference
    url: /gateway/fips-140-2-support/

works_on:
  - on-prem
  - konnect

min_version: 
  gateway: '3.14'

toc_depth: 4
---

The Federal Information Processing Standard (FIPS) 140-3 is a federal standard defined by the National Institute of Standards and Technology. It specifies the security requirements that must be satisfied by a cryptographic module.

The FIPS {{site.base_gateway}} package is FIPS 140-3 compliant. Compliance means that {{site.base_gateway}} only uses FIPS 140-3 approved algorithms while running in FIPS mode, but the product has not been submitted to a NIST testing lab for validation.

{{site.ee_product_name}} provides the FIPS 140-3 compliant package for [supported distributions](/gateway/version-support-policy/#supported-versions), including distroless packages. 
This package provides compliance for the core {{site.base_gateway}} product and all out-of-the-box plugins. 
The FIPS 140-3 package is only available for AMD64 systems. For more information, see the [{{site.base_gateway}} install page](/gateway/install/).

The package uses the OpenSSL FIPS Provider 3.1.2 to provide FIPS 140-3 validated cryptographic operations.

{:.info}
> **Note**: If you are looking for instructions on using the FIPS 140-2 package, see [FIPS 140-2 compliance in {{site.base_gateway}}](/gateway/fips-140-2-support/).

## Configure FIPS

To start in FIPS mode, set the following configuration property to `on` in the [`kong.conf` configuration](/gateway/configuration/#fips) file before starting {{site.base_gateway}}:

```
fips = on # fips mode is enabled, causing incompatible ciphers to be disabled
```

You can also set this configuration using an environment variable:

```bash
export KONG_FIPS=on
```

{:.warning}
> **Warning**: Migrating from non-FIPS to FIPS mode and backwards is not supported. 
> Migrating directly between the FIPS 140-2 and FIPS 140-3 packages is also not supported, as the FIPS 140-3 distribution ships as a separate package. 
> If you need to transition from the FIPS 140-2 package to the FIPS 140-3 package, follow the recommendations in the section [Transitioning from FIPS 140-2 to FIPS 140-3](#transitioning-from-fips-140-2-to-fips-140-3).

## Transitioning from FIPS 140-2 to FIPS 140-3

The FIPS 140-3 distribution ships as a **separate package**, so there is no in-place upgrade from a FIPS 140-2 install. 
Plan the transition as a fresh install of the FIPS 140-3 package on a supported {{site.base_gateway}} version, including preparation of your upstreams, clients, and stored configuration to match the tighter FIPS 140-3 boundary.

### Prerequisites

Before migrating to FIPS 140-3, review existing legacy configurations and prepare for the transition.

#### Items to inventory before switching to FIPS 140-3

The FIPS 140-3 package doesn't silently rewrite legacy stored artifacts, and it fails closed on configuration that references non-approved algorithms. Before enabling it, inventory the following:

{% table %}
columns:
  - title: Area
    key: area
  - title: What to check
    key: check
rows:
  - area: "Peers on Kong's TLS surface"
    check: "Inbound clients and outbound upstream services. Any peer that doesn't support TLS 1.2 with Extended Master Secret (EMS, RFC 7627) or TLS 1.3 will fail during the handshake."
  - area: "Cipher configurations"
    check: "Remove custom `ssl_ciphers` values and any `*_ssl_conf_command` overrides. The FIPS 140-3 package pins TLS 1.2 / 1.3 with approved AES-GCM profiles."
  - area: "Plugin configuration"
    check: "Referencing non-approved algorithms such as SAML request signatures, HMAC-Auth secrets, JWT Signer/JOSE/JWA algorithm choices, and any plugin still selecting SHA-1 or MD5."
  - area: "Keyring"
    check: "RSA transport keys smaller than 2048 bits must be rotated. Legacy AES-GCM exports created without an authentication tag remain importable via the explicit legacy path but must be re-exported afterward."
  - area: "`key-auth-enc` credentials"
    check: "Plan a batched `PATCH` or `POST` on each credential so it is re-hashed as SHA-256. Existing SHA-1 credentials keep working (read-only), but new credentials must be SHA-256."
{% endtable %}

#### What's not available after switching to FIPS 140-3

The following are rejected outright when the FIPS 140-3 package runs with `fips = on`:

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

### Install and verify

1. Download and install a {{site.base_gateway}} FIPS 140-3 package on a [supported OS](/gateway/version-support-policy/#supported-versions).

    Currently, the FIPS 140-3 package is only available on {{site.base_gateway}} 3.14 LTS.

2. Confirm `fips = on` in `kong.conf` or set `KONG_FIPS=on` as an environment variable.
3. Restart {{site.base_gateway}}.
4. Verify the loaded provider using the Admin API:

   ```shell
   curl -s http://localhost:8001/fips-status
   ```

5. Verify that your clients are working as expected with your new installation of {{site.base_gateway}}.

## Password hashing

The following table describes how {{site.base_gateway}} uses key derivation functions:

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

{:.info .no-icon}
> **\[1\]**: As of {{site.base_gateway}} FIPS 3.0, RBAC uses PBKDF2 as the password hashing algorithm.
<br><br>
> **\[2\]**: As of {{site.base_gateway}} FIPS 3.1, the OAuth2 plugin disables the `hash_secret` feature, so you can't turn it on. This means the password is stored as plaintext in the database. You can use secrets management or database encryption instead.
<br><br>
> **\[3\]**: As of {{site.base_gateway}} FIPS 3.1, key-auth-enc uses SHA1 to speed up lookup of a key in the database. As of {{site.base_gateway}} FIPS 3.2, SHA1 support is read-only, meaning existing credentials in the database are still validated, but any new credentials are hashed in SHA256.

{:.warning}
> **Important**: If you are migrating from {{site.base_gateway}} 3.1 to 3.2 in FIPS mode and are using the key-auth-enc plugin, you should send [PATCH or POST requests](/plugins/key-auth-enc/#create-a-key) to all existing key-auth-enc credentials to re-hash them in SHA256.

## Non-cryptographic usage of cryptographic algorithms

FIPS only defines the approved algorithms to use for each specific purpose, so FIPS policy doesn't explicitly restrict the usage of cryptographic algorithms to only cases where they are necessary.

For example, using SHA-256 as the message digest algorithm is approved, while MD5 is not. However, that doesn't mean MD5 must be completely absent from the application.

The following table explains where cryptographic algorithms are used for non-cryptographic purposes in {{site.base_gateway}}:

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
      core/kong_request_id {% new_in 3.5 %}
    normal: "rand(3)"
    fips: "rand(3)"
    notes: "The RNG isn't used for cryptographic purposes."
{% endtable %}
<!--vale on-->

## SSL client

FIPS 140-3 defines requirements for the cryptographic module, not for SSL client roles. {{site.base_gateway}} does not enforce a FIPS-specific policy on outbound clients. 
Traffic that traverses {{site.base_gateway}}'s own inbound and outbound TLS enforcement does honor the TLS 1.2/1.3 and EMS constraints described in the [limitations section](#what-s-not-available-after-switching-to-fips-140-3).

This includes:
* Using Lua to communicate over HTTPS and PostgreSQL SSL.
* Using an upstream that proxies over HTTPS.