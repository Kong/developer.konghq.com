---
title: "FIPS 140-2 Compliance"
content_type: reference
layout: reference
description: |
  Learn how FIPS 140-2 compliance is implemented in {{site.base_gateway}} when running in FIPS mode.
badge: enterprise
products:
  - gateway
works_on:
  - on-prem
---

The Federal Information Processing Standard (FIPS) 140-2 specifies the security requirements that must be satisfied by a cryptographic module. The FIPS {{site.base_gateway}} package is compliant with this standard when running in FIPS mode, using only approved algorithms. However, it has not been submitted for NIST validation.

{{site.ee_product_name}} provides FIPS 140-2 compliant packages for the following distributions:

* Ubuntu 22.04
* RHEL 9

The package uses the OpenSSL 3.0 FIPS module to perform cryptographic operations.


{:.note}
> FIPS is not supported in free mode. {% new_in 3.10 %}


## Password Hashing in FIPS Mode
<!-- vale off -->
{% table %}
columns:
  - title: Component
    key: component
  - title: Normal Mode
    key: normal
  - title: FIPS Mode
    key: fips
  - title: Notes
    key: notes
rows:
  - component: core/rbac
    normal: bcrypt
    fips: PBKDF2 {% new_in "Fips 3.0" %}
    notes: Compliant via OpenSSL 3.0 FIPS provider
  - component: plugins/oauth2 {% new_in "Fips 3.1" %}
    normal: Argon2 or bcrypt (when `hash_secret=true`)
    fips: Disabled (`hash_secret` can’t be set to `true`)
    notes: Compliant via OpenSSL 3.0 FIPS provider
  - component: plugins/key-auth-enc {% new_in "Fips 3.1" %}
    normal: SHA1
    fips: SHA256
    notes: SHA1 is read-only in FIPS mode
{% endtable %}

<!-- vale on -->

{:.warning}
> If upgrading from {{site.base_gateway}} 3.1 to 3.2 while using key-auth-enc, re-hash all existing credentials using [PATCH or POST requests](/plugins/key-auth-enc/examples/enable-key-auth-encrypt/).

## Non-Cryptographic Use of Cryptographic Algorithms

FIPS defines approved algorithms for cryptographic use, but does not restrict non-cryptographic uses. Some components of {{site.base_gateway}} use such algorithms for purposes like hashing IDs or load balancing.
<!-- vale off -->
{% table %}
columns:
  - title: Component
    key: component
  - title: Normal Mode
    key: normal
  - title: FIPS Mode
    key: fips
  - title: Notes
    key: notes
rows:
  - component: core/balancer
    normal: xxhash32
    fips: xxhash32
    notes: Used to generate unique identifiers
  - component: core/balancer
    normal: crc32
    fips: crc32
    notes: Not a message digest
  - component: core/uuid
    normal: Lua random number generator
    fips: Lua random number generator
    notes: RNG not used for cryptographic purposes
  - component: core/declarative_config/uuid
    normal: UUIDv5 (SHA1)
    fips: UUIDv5 (SHA1)
    notes: Used to generate unique identifiers
  - component: core/declarative_config/config_hash and core/hybrid/hashes
    normal: MD5
    fips: MD5
    notes: Used to generate unique identifiers
{% if_version gte:3.5.x %}
  - component: core/kong_request_id
    normal: rand(3)
    fips: rand(3)
    notes: RNG not used for cryptographic purposes
{% endif_version %}
{% endtable %}
<!-- vale on -->
## SSL Client Support in FIPS Mode

FIPS 140-2 only addresses SSL server compliance. {{site.base_gateway}} supports FIPS-compliant server operations in version 3.0. SSL clients are not governed by FIPS, and therefore are not subject to specific compliance handling.

Client operations include:

* Making HTTPS requests via Lua
* Using PostgreSQL over SSL
* Upstream services proxied over HTTPS
