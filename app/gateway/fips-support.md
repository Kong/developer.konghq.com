---
title: "FIPS 140-2 Compliance in {{site.base_gateway}}"
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
  Learn about how to enable FIPS mode and how {{site.base_gateway}} is FIPS 140-2 compliant.

related_resources:
  - text: Version support policy
    url: /gateway/version-support-policy/
  - text: Install {{site.base_gateway}}
    url: /gateway/install/

works_on:
  - on-prem
  - konnect
---

The Federal Information Processing Standard (FIPS) 140-2 is a federal standard defined by the National Institute of Standards and Technology. It specifies the security requirements that must be satisfied by a cryptographic module. The FIPS {{site.base_gateway}} package is FIPS 140-2 compliant. Compliance means that {{site.base_gateway}} only uses FIPS 140-2 approved algorithms while running in FIPS mode, but the product has not been submitted to a NIST testing lab for validation.


{{site.ee_product_name}} provides a FIPS 140-2 compliant package for **Ubuntu 20.04**{% new_in 3.1 %}, **Ubuntu 22.04**, **Red Hat Enterprise 9**{% new_in 3.4 %}, and **Red Hat Enterprise 8**{% new_in 3.1 %}. This package provides compliance for the core {{site.base_gateway}} product and all out of the box plugins. For more information, see the [{{site.base_gateway}} install page](/gateway/install/).

The package uses the OpenSSL FIPS 3.0 module OpenSSL to provide FIPS 140-2 validated cryptographic operations.

{:.info}
> **Note**: In {{site.base_gateway}} 3.9.x or earlier, FIPS is not supported when running {{site.ee_product_name}} in free mode.

## Configure FIPS

To start in FIPS mode, set the following configuration property to `on` in the [`kong.conf` configuration](/gateway/configuration/#fips) file before starting {{site.base_gateway}}:

```
fips = on # fips mode is enabled, causing incompatible ciphers to be disabled
```

You can also set this configuration using an environment variable:

```bash
export KONG_FIPS=on
```

{:.warning .no-icon}
> Migrating from non-FIPS to FIPS mode and backwards is not supported.

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
    notes: "Compliant via OpenSSL 3.0 FIPS provider"
  - component: "plugins/oauth2 <sup>2</sup>"
    normal: "Argon2 or bcrypt (when `hash_secret=true`)"
    fips: "Disabled (`hash_secret` can’t be set to `true`)"
    notes: "Compliant via OpenSSL 3.0 FIPS provider"
  - component: "plugins/key-auth-enc <sup>3</sup>"
    normal: "SHA1"
    fips: "SHA256"
    notes: "SHA1 is read-only in FIPS mode."
{% endtable %}
<!--vale on-->


{:.info .no-icon}
> **\[1\]**: As of {{site.base_gateway}} FIPS 3.0, RBAC uses PBKDF2 as password hashing algorithm.
<br><br>
> **\[2\]**: As of {{site.base_gateway}} FIPS 3.1, the oauth2 plugin disables the `hash_secret` feature, so you can’t turn it on. This means password will be stored plaintext in the database; however, you can choose to use secrets management or database encryption instead.
<br><br>
> **\[3\]**: As of {{site.base_gateway}} FIPS 3.1, key-auth-enc uses SHA1 to speed up lookup of a key in DB. As of {{site.base_gateway}} FIPS 3.2, SHA1 support is “read-only”, meaning existing credentials in DB are still validated, but any new credentials will be hashed in SHA256.

{:.warning}
> **Important**: If you are migrating from {{site.base_gateway}} 3.1 to 3.2 in FIPS mode and are using the key-auth-enc plugin, you should send [PATCH or POST requests](/plugins/key-auth-enc/#create-a-key) to all existing key-auth-enc credentials to re-hash them in SHA256.

## Non-cryptographic usage of cryptographic algorithms

FIPS only defines the approved algorithms to use for each specific purpose, so FIPS policy doesn't explicitly restrict the usage of cryptographic algorithms to only cases where they are necessary. 


For example, using SHA-256 as the message digest algorithm is approved, while MD5 is not. However, that doesn’t mean MD5 must be completely absent from the application. For instance, the FIPS 140-2–approved version of [BoringSSL](https://csrc.nist.gov/CSRC/media/projects/cryptographic-module-validation-program/documents/security-policies/140sp3678.pdf) permits MD5 when used with TLS protocol versions 1.0 and 1.1.

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
    notes: "The RNG isn’t used for cryptographic purposes."
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
    notes: "The RNG isn’t used for cryptographic purposes."
{% endtable %}
<!--vale on-->


## SSL client

FIPS 140-2 only mentioned SSL server, which is already supported in {{site.base_gateway}} FIPS 3.0. FIPS specification isn't designated for SSL clients, so there isn't specific handling of these in {{site.base_gateway}}.

This includes:
* Using Lua to talk in HTTPS and PostgreSQL SSL
* Using an upstream that proxies in HTTPS