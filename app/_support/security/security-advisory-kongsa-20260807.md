---
title: "Security Advisory KONGSA-20260807: Cumulative patch release"
content_type: support
description: "Kong ships a security patch release for each supported {{site.ee_product_name_official}} version. The release addresses issues in Kong components, NGINX, libjq and OpenSSL."
products:
  - gateway
  - ai-gateway
works_on:
  - on-prem
  - konnect
advisory:
  id: KONGSA-20260807
  cves:
    - id: CVE-2026-14916
      severity: high
      cvss_score: 7.7
      cvss_version: "4.0"
      status: affected
      summary: JWT algorithm confusion in MCP OAuth2 and DataKit JWT validation
    - id: CVE-2026-14917
      severity: high
      cvss_score: 7.7
      cvss_version: "4.0"
      status: affected
      summary: "SAML authentication bypass when `validate_assertion_signature` is false"
    - id: CVE-2026-42533
      severity: critical
      cvss_score: 9.2
      cvss_version: "4.0"
      status: affected
      summary: NGINX map directive heap buffer overflow
    - id: CVE-2026-60005
      severity: high
      cvss_score: 8.8
      cvss_version: "4.0"
      status: affected
      summary: "`ngx_http_slice_module` memory disclosure"
    - id: CVE-2026-56434
      severity: high
      cvss_score: 8.3
      cvss_version: "4.0"
      status: affected
      summary: "NGINX `ngx_http_ssi_module` use-after-free"
    - id: CVE-2026-48142
      severity: medium
      cvss_score: 6.3
      cvss_version: "4.0"
      status: affected
      summary: "NGINX `ngx_http_charset_module` buffer over-read"
    - id: CVE-2026-42055
      severity: critical
      cvss_score: 9.2
      cvss_version: "4.0"
      status: affected
      summary: NGINX HTTP/2 and gRPC upstream buffer overflow
    - id: CVE-2026-32316
      severity: low
      status: affected
      summary: libjq heap buffer overflow in large string operations
    - id: CVE-2026-33947
      severity: medium
      cvss_score: 6.2
      cvss_version: "3.1"
      status: affected
      summary: libjq stack overflow through excessively long path arrays
    - id: CVE-2026-33948
      severity: low
      cvss_score: 2.9
      cvss_version: "4.0"
      status: not_affected
      summary: jq command-line embedded NUL validation bypass
    - id: CVE-2026-39979
      severity: medium
      cvss_score: 6.9
      cvss_version: "4.0"
      status: affected
      summary: libjq out-of-bounds read in jv_parse_sized()
    - id: CVE-2026-45447
      status: not_affected
      summary: OpenSSL heap use-after-free in PKCS7_verify()
    - id: CVE-2026-34182
      status: not_affected
      summary: OpenSSL CMS AuthEnvelopedData forged messages
    - id: CVE-2026-34183
      status: not_affected
      summary: OpenSSL memory growth in QUIC PATH_CHALLENGE
    - id: CVE-2026-42764
      status: not_affected
      summary: OpenSSL NULL pointer dereference in QUIC server
    - id: CVE-2026-45445
      status: not_affected
      summary: OpenSSL AES-OCB IV ignored on the EVP_Cipher() API
    - id: CVE-2026-7383
      status: not_affected
      summary: OpenSSL heap buffer overflow in ASN.1 multibyte string conversion
    - id: CVE-2026-9076
      status: not_affected
      summary: OpenSSL out-of-bounds read in CMS password decryption
    - id: CVE-2026-34180
      severity: low
      status: affected
      summary: OpenSSL heap over-read in ASN.1 content parsing
    - id: CVE-2026-34181
      status: not_affected
      summary: OpenSSL PBMAC1 with short HMAC keys
    - id: CVE-2026-42766
      status: not_affected
      summary: OpenSSL NULL dereference in password-based CMS decryption
    - id: CVE-2026-42767
      status: not_affected
      summary: OpenSSL NULL dereference in CRMF EncryptedValue
    - id: CVE-2026-42768
      status: not_affected
      summary: OpenSSL Bleichenbacher oracle in CMS_decrypt()
    - id: CVE-2026-42769
      status: not_affected
      summary: OpenSSL trust anchor in CMP rootCaKeyUpdate
    - id: CVE-2026-42770
      status: not_affected
      summary: OpenSSL FFC-DH peer validation uses attacker-supplied q
    - id: CVE-2026-45446
      status: not_affected
      summary: OpenSSL incorrect tag processing in AES-GCM-SIV
  affected_versions:
    - "3.15.0.0 to 3.15.0.2"
    - "3.14.0.0 to 3.14.0.11"
    - "3.13.0.0 to 3.13.0.8"
    - "3.12.0.0 to 3.12.0.9"
    - "3.10.0.0 to 3.10.0.16"
    - "3.4.0.0 to 3.4.3.28"
  fixed_versions:
    - "3.15.0.3"
    - "3.14.0.12"
    - "3.13.0.9"
    - "3.12.0.10"
    - "3.10.0.17"
    - "3.4.3.29"
---

As part of its commitment to customer security, Kong is shipping a security patch release for each supported release. The release addresses a number of issues recently identified through self scans of the Kong codebase with Mythos grade tooling.

The impact and severity of these issues depend on the affected component, version, configuration, and deployment architecture.

Kong recommends that customers follow the remediation guidance in this advisory, including upgrading affected components or versions and reviewing any relevant third-party configurations.

## CVE-2026-14916: JWT algorithm confusion

A JWT signature verification vulnerability affects Kong components that perform JWT validation for MCP OAuth2 or DataKit integrations inside {{site.ee_product_name_official}}. The affected code doesn't properly validate that the JWT signing algorithm is compatible with the type of key used for verification.

As a result, an unauthenticated remote attacker may be able to craft a forged JWT that is incorrectly accepted as valid. This can lead to authentication bypass and potential compromise of confidentiality, integrity, and availability.

* **CVSS 4.0 score:** 7.7 / High
* **Vector:** CVSS:4.0/AV:N/AC:L/AT:N/PR:N/UI:N/VC:N/VI:N/VA:N/SC:H/SI:N/SA:N

### Am I affected?

You may be affected if your {{site.ee_product_name_official}} deployment uses MCP OAuth2 or DataKit inside Kong and relies on JWT validation for authentication or authorization flows. Customers not using MCP OAuth2 or DataKit inside Kong aren't expected to be affected.

## CVE-2026-14917: SAML authentication bypass

A SAML authentication bypass vulnerability affects the Kong SAML plugin when the `validate_assertion_signature` option is explicitly set to `false`. This option is enabled by default. When disabled, the plugin may extract the SAML identity from an unsigned assertion and authenticate the user without verifying a valid cryptographic signature.

As a result, an unauthenticated remote attacker may be able to submit a crafted SAML response and impersonate arbitrary users, including administrators.

* **CVSS 4.0 score:** 7.7 / High
* **Vector:** CVSS:4.0/AV:N/AC:L/AT:N/PR:N/UI:N/VC:N/VI:N/VA:N/SC:H/SI:N/SA:N

### Am I affected?

You may be affected if your {{site.ee_product_name_official}} deployment uses the SAML plugin and the `validate_assertion_signature` option is set to `false`. Customers using SAML should verify the value of this option in their plugin configuration. Deployments that don't use the SAML plugin aren't affected.

## CVE-2026-42533: NGINX map directive heap buffer overflow

{{site.ee_product_name_official}} and {{site.ai_gateway_name}} Enterprise include NGINX/OpenResty and may be affected when a custom NGINX configuration uses the `map` directive with regular-expression matching in a vulnerable expression pattern.

A remote, unauthenticated attacker with network access to an affected HTTP listener could send crafted requests that trigger a heap buffer overflow in an NGINX worker process. Successful exploitation may cause the worker process to restart, resulting in service degradation or a denial-of-service (DoS) condition. In limited environments where Address Space Layout Randomization (ASLR) is disabled or can be bypassed, arbitrary code execution may also be possible.

* **Kong severity assessment, CVSS v4.0 score:** 9.2 / Critical
* **Vector:** CVSS:4.0/AV:N/AC:H/AT:N/PR:N/UI:N/VC:H/VI:H/VA:H/SC:N/SI:N/SA:N

### Am I affected?

Consider a {{site.ee_product_name_official}} deployment affected if all of the following are true:

* Your NGINX configuration defines a `map` directive that uses regular-expression matching.
* A string expression references the regular-expression capture variables before referencing the output variable of the `map` directive, or uses a non-cacheable variable in a vulnerable expression pattern.
* An affected HTTP listener is reachable by untrusted clients or exposed to the internet.

Deployments that don't use this specific `map` configuration pattern aren't affected.

## CVE-2026-60005: NGINX slice module memory disclosure

{{site.ee_product_name_official}} and {{site.ai_gateway_name}} Enterprise include NGINX/OpenResty and may be affected when the `ngx_http_slice_module` module and its `slice` directive are used.

A remote, unauthenticated attacker with network access to an affected HTTP listener could send crafted requests that cause an NGINX worker process to access uninitialized memory. This condition may occur when the `slice` directive is combined with unnamed regular-expression captures or when a background cache update is performed.

Successful exploitation could result in limited disclosure of process memory or cause the NGINX worker process to restart. This can lead to information exposure, service degradation, or a denial-of-service (DoS) condition.

* **Kong severity assessment, CVSS v4.0 score:** 8.8 / High
* **Vector:** CVSS:4.0/AV:N/AC:L/AT:N/PR:N/UI:N/VC:L/VI:N/VA:H/SC:N/SI:N/SA:N

### Am I affected?

Consider a {{site.base_gateway}} deployment affected if all of the following are true:

* Your NGINX configuration uses the `slice` directive provided by `ngx_http_slice_module`.
* The configuration also uses unnamed regular-expression captures, or background cache updates can occur.
* An affected HTTP listener is reachable by untrusted clients or exposed to the internet.

Deployments that don't use the `slice` directive aren't affected.

## CVE-2026-56434: NGINX SSI module use-after-free

{{site.ee_product_name_official}} and {{site.ai_gateway_name}} Enterprise include NGINX/OpenResty and may be affected when Server-Side Includes (SSI) are enabled for proxied responses while response buffering is disabled.

An unauthenticated attacker who can control or modify responses returned by an upstream server could trigger a use-after-free condition in an NGINX worker process. This could occur, for example, if the attacker has a man-in-the-middle position between Kong and the upstream service or has compromised the upstream service.

Successful exploitation may allow limited modification of process memory or cause the NGINX worker process to restart. This can result in service degradation or a denial-of-service (DoS) condition.

* **Kong severity assessment, CVSS v4.0 score:** 8.3 / High
* **Vector:** CVSS:4.0/AV:N/AC:L/AT:P/PR:N/UI:N/VC:N/VI:L/VA:H/SC:N/SI:N/SA:N

### Am I affected?

Consider a {{site.base_gateway}} deployment affected if all of the following are true:

* Server-Side Includes are enabled using the `ssi on` directive.
* The affected location proxies requests using `proxy_pass`.
* Response buffering is disabled using `proxy_buffering off`.
* An attacker can control or modify responses returned by the configured upstream service.

Deployments that don't enable SSI aren't affected.

## CVE-2026-48142: NGINX charset module buffer over-read

{{site.ee_product_name_official}} and {{site.ai_gateway_name}} Enterprise include NGINX/OpenResty and may be affected when response character-set conversion is configured using `ngx_http_charset_module`.

A remote, unauthenticated attacker with network access to an affected HTTP listener could send crafted requests that, in conjunction with conditions beyond the attacker's control, trigger a heap buffer over-read in an NGINX worker process. Successful exploitation may result in limited disclosure of process memory or cause the worker process to restart. This can lead to information exposure, service degradation, or a denial-of-service (DoS) condition.

* **Kong severity assessment, CVSS v4.0 score:** 6.3 / Medium
* **Vector:** CVSS:4.0/AV:N/AC:H/AT:N/PR:N/UI:N/VC:L/VI:N/VA:L/SC:N/SI:N/SA:N

### Am I affected?

Consider a {{site.base_gateway}} deployment affected if all of the following are true:

* Your NGINX configuration sets `source_charset` to `utf-8`.
* A `charset` directive is configured in the same effective configuration context. For example:

  ```
  source_charset utf-8;
  charset koi8-r;
  ```

* The affected configuration applies to content served or proxied through Kong.
* The affected HTTP listener is reachable by untrusted clients or exposed to the internet.

The default Kong configuration sets `charset` to UTF-8. This setting alone doesn't meet the vulnerability conditions, because the issue also requires `source_charset utf-8` to be configured. Deployments that don't configure `source_charset` aren't affected.

## CVE-2026-42055: NGINX HTTP/2 and gRPC upstream buffer overflow

{{site.ee_product_name_official}} and {{site.ai_gateway_name}} Enterprise include NGINX/OpenResty and support proxying traffic to gRPC upstream services. They may be affected when HTTP/2 or gRPC upstream proxying is combined with specific non-default request-header configuration settings.

A remote, unauthenticated attacker with network access to an affected HTTP or gRPC listener could send crafted requests containing large headers while Kong is constructing an upstream request. This may trigger a heap-based buffer overflow in an NGINX worker process, causing the worker to restart. The result can be service degradation or a denial-of-service (DoS) condition.

Under limited circumstances where ASLR is disabled or can be bypassed, successful exploitation may also allow arbitrary code execution.

* **Kong severity assessment, CVSS v4.0 score:** 9.2 / Critical
* **Vector:** CVSS:4.0/AV:N/AC:H/AT:P/PR:N/UI:N/VC:H/VI:H/VA:H/SC:N/SI:N/SA:N

### Am I affected?

Consider a {{site.base_gateway}} deployment affected if all of the following are true:

* The deployment proxies HTTP/2 upstream traffic using `proxy_http_version 2`, or proxies traffic to a gRPC upstream using `grpc_pass`.
* The NGINX `ignore_invalid_headers` directive is explicitly set to `off`.
* The size component of the `large_client_header_buffers` directive is configured to a value greater than 2 megabytes. For example: `large_client_header_buffers 4 4m`.
* The affected proxy listener is reachable by untrusted clients or exposed to the internet.

The default Kong configuration doesn't meet the vulnerability conditions. Kong configures `large_client_header_buffers` as `4 8k` by default, and NGINX enables `ignore_invalid_headers` by default. Deployments using these default values aren't affected, including deployments that use gRPC without the two additional vulnerable configuration settings.

## CVE-2026-32316: libjq heap buffer overflow in large string operations

{{site.ee_product_name_official}} and {{site.ai_gateway_name}} Enterprise include libjq, which is exposed to the Kong Lua runtime and may be affected by an integer-overflow vulnerability in libjq string-handling functions.

An attacker able to influence data processed by an affected Lua jq expression could cause repeated string concatenation or replacement operations to produce a very large string. Under the vulnerable conditions, integer overflow in allocation-size calculations within `jvp_string_append()` or `jvp_string_copy_replace_bad()` may result in a heap-based buffer overflow.

Successful exploitation could cause an NGINX worker process to terminate and may result in additional heap-corruption impact, leading to service degradation or a denial-of-service condition.

* **Kong severity assessment:** Low
* **Upstream CVSS v3.1 score:** 8.2 / High
* **Vector:** CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:L/A:H

GitHub, acting as the CNA, assigned a score of 8.2 High. NVD separately lists a score of 7.5 High. NVD hasn't published a CVSS v4.0 score for this vulnerability.

### Am I affected?

Consider a {{site.base_gateway}} deployment potentially affected if all of the following are true:

* A plugin or custom Lua component evaluates jq expressions using the Kong libjq integration.
* Attacker-controlled data is supplied to the affected jq expression.
* The expression performs repeated string concatenation or replacement operations using the affected libjq functions.
* The resulting string can grow large enough to overflow the libjq internal allocation-size calculations.

Kong evaluated this vulnerability through the Lua-to-libjq execution path that Kong uses. During testing, Lua runtime limits terminated processing before a string could grow large enough to trigger the vulnerable libjq allocation condition. Kong couldn't reproduce the heap buffer overflow through the supported execution path and has assessed the practical severity for Kong deployments as Low, despite the upstream High severity rating.

## CVE-2026-33947: libjq stack overflow through excessively long path arrays

{{site.ee_product_name_official}} and {{site.ai_gateway_name}} Enterprise include libjq, which is exposed to the Kong Lua runtime and may be affected by an uncontrolled-recursion vulnerability in libjq path-processing functions.

An attacker able to influence a jq expression and its input could supply an extremely long path array to an affected operation. Processing the path may trigger excessive recursion in `jv_setpath()`, `jv_getpath()`, `delpaths_sorted()`, or the `delpaths` filter.

Successful exploitation may exhaust the stack of the NGINX worker and cause the worker process to terminate with a segmentation fault. This can result in service degradation or a denial-of-service condition.

* **Kong severity assessment, CVSS v3.1 score:** 6.2 / Medium
* **Vector:** CVSS:3.1/AV:L/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H

GitHub, acting as the CNA, assigned a score of 6.2 Medium. NVD separately lists a score of 5.5 Medium. NVD hasn't published a CVSS v4.0 score for this vulnerability.

### Am I affected?

Consider a {{site.base_gateway}} deployment affected if all of the following are true:

* A plugin or custom Lua component evaluates jq expressions using the Kong libjq integration.
* The jq expression invokes `getpath`, `setpath`, `delpaths`, or another operation that reaches the affected libjq path-processing functions.
* An attacker can control or substantially influence the path array supplied to the affected operation.
* The attacker can provide a path array with enough elements to exhaust the stack of the NGINX worker.

The default Kong configuration doesn't expose arbitrary jq expressions or libjq path operations directly to remote clients. Deployments that don't evaluate affected path operations using attacker-controlled path arrays aren't affected.

## CVE-2026-33948: jq command-line embedded NUL validation bypass

{{site.ee_product_name_official}} and {{site.ai_gateway_name}} Enterprise include libjq through a Lua integration. Kong doesn't use the jq command-line input-processing path affected by this vulnerability.

The vulnerability occurs in the jq command-line utility when JSON input is read from a buffer and `strlen()` is used to determine its length. An embedded NUL byte may cause the command-line parser to validate only the portion of the input before the NUL byte and ignore the trailing data.

This behavior could create a validation bypass when the jq command-line utility is used as a security boundary and another component subsequently processes the complete input, including the data after the embedded NUL byte.

* **Kong severity assessment, CVSS v4.0 score:** 2.9 / Low
* **Vector:** CVSS:4.0/AV:N/AC:L/AT:P/PR:N/UI:N/VC:N/VI:L/VA:N/SC:N/SI:N/SA:N/E:P

### Am I affected?

{{site.base_gateway}} and {{site.ai_gateway_name}} Enterprise aren't affected through their standard jq integration.

Kong invokes libjq directly from Lua and doesn't pass input through the affected jq command-line parsing path. As a result, the `strlen()` truncation behavior described in this vulnerability isn't present in the supported Kong libjq execution path.

Consider a deployment potentially affected only if it independently installs or invokes the jq command-line utility from a custom plugin, external script, container modification, or administrative workflow, and relies on that utility to validate input that may contain embedded NUL bytes.

## CVE-2026-39979: libjq out-of-bounds read in jv_parse_sized()

{{site.ee_product_name_official}} and {{site.ai_gateway_name}} Enterprise include libjq, which is exposed to the Kong Lua runtime and may be affected by an out-of-bounds read in the libjq counted-buffer parsing API.

The vulnerable `jv_parse_sized()` function accepts an input buffer together with an explicit length. When malformed JSON causes parsing to fail, an affected error-handling path may subsequently treat the supplied buffer as a NUL-terminated string.

If the supplied buffer doesn't contain a NUL terminator within its allocated bounds, libjq may read beyond the end of the buffer while constructing the parsing error message.

An attacker able to provide malformed JSON to an affected libjq parsing path could cause an NGINX worker process to read adjacent memory. Successful exploitation may result in limited disclosure of process memory or cause the worker process to terminate. This can lead to information exposure, service degradation, or a denial-of-service condition.

* **Kong severity assessment, CVSS v4.0 score:** 6.9 / Medium
* **Vector:** CVSS:4.0/AV:N/AC:L/AT:N/PR:N/UI:N/VC:L/VI:N/VA:L/SC:N/SI:N/SA:N

### Am I affected?

Consider a {{site.base_gateway}} deployment affected if all of the following are true:

* A plugin or custom Lua component parses JSON using the Kong libjq integration.
* The affected Lua-to-libjq execution path invokes `jv_parse_sized()`.
* An attacker can provide malformed JSON to that parsing operation.
* The input is passed as a counted buffer that isn't guaranteed to contain a NUL terminator within its allocated bounds.
* The affected parsing operation is reachable through an untrusted or internet-accessible listener.

The vulnerability applies to the libjq API and is therefore potentially relevant to embedded libjq consumers such as Kong. However, using jq filters through Lua doesn't by itself establish that the vulnerable conditions are present. Deployments aren't affected if the Lua binding doesn't invoke `jv_parse_sized()`, guarantees that input buffers are NUL-terminated, or doesn't parse attacker-controlled JSON through the affected path.

## OpenSSL vulnerabilities

The following OpenSSL vulnerabilities were assessed against {{site.ee_product_name_official}}. Unless noted, the vulnerable code isn't reachable in Kong.

### CVE-2026-45447: OpenSSL heap use-after-free in PKCS7_verify()

When OpenSSL verifies a PKCS#7 or S/MIME signed message, a maliciously crafted message whose `SignedData.digestAlgorithms` field is an empty ASN.1 SET causes `PKCS7_verify()` to free a BIO object that the calling application supplied and still owns. Any later use of that BIO is a use-after-free, which can lead to a crash, heap corruption, or potentially remote code execution.

**Is Kong affected?** No (not reachable). {{site.base_gateway}} doesn't verify PKCS#7 or S/MIME signed messages anywhere in its request path. There is no call to `PKCS7_verify()` in Kong core or in the bundled plugins. The only occurrence of the term "pkcs7" is a data field passed through to HashiCorp Vault, where verification happens on the Vault side. The `pkcs7` module is also intentionally excluded from the plugin sandbox, so a custom plugin can't reach this function either.

### CVE-2026-34182: OpenSSL CMS AuthEnvelopedData forged messages

When processing CMS (Cryptographic Message Syntax) AuthEnvelopedData content, OpenSSL may accept messages whose integrity has been tampered with, allowing an attacker to bypass authenticated-encryption integrity checks.

**Is Kong affected?** No (not reachable). Kong doesn't use the CMS subsystem. It neither produces nor consumes CMS AuthEnvelopedData structures, and the `cms` module isn't exposed to custom plugins. No code path in core, in bundled plugins, or through the sandbox decodes CMS content, so the vulnerable logic is never invoked.

### CVE-2026-34183: OpenSSL memory growth in QUIC PATH_CHALLENGE

The OpenSSL built-in QUIC implementation can be made to allocate memory without bound when handling PATH_CHALLENGE frames, leading to memory exhaustion and a denial of service.

**Is Kong affected?** No (not reachable). Kong doesn't enable the OpenSSL QUIC protocol engine. The Kong NGINX templates configure no HTTP/3 or QUIC listeners. Even in deployments that front HTTP/3, NGINX uses its own QUIC transport implementation and calls OpenSSL only for the TLS cryptographic handshake. It doesn't run the OpenSSL QUIC connection state machine where this handler lives. The vulnerable code is compiled into the library but never executed.

### CVE-2026-42764: OpenSSL NULL pointer dereference in QUIC server

A crafted QUIC initial packet sent to a server using the OpenSSL QUIC stack triggers a NULL pointer dereference, crashing the process (denial of service).

**Is Kong affected?** No (not reachable). The rationale is the same as for CVE-2026-34183. Kong never runs OpenSSL as a QUIC server, so there is no surface that processes QUIC initial packets through OpenSSL.

### CVE-2026-45445: OpenSSL AES-OCB IV ignored on the EVP_Cipher() API

When AES in OCB mode is driven through the low-level one-shot `EVP_Cipher()` API, the supplied initialization vector (IV or nonce) can be ignored. This can cause the same key and nonce pair to be reused across encryptions, which breaks the confidentiality and authenticity guarantees of OCB.

**Is Kong affected?** No (not reachable), including from custom plugins. The vulnerability is specific to the one-shot `EVP_Cipher()` call form. Kong reaches symmetric ciphers exclusively through `resty.openssl.cipher` (lua-resty-openssl 1.7.1, the pinned dependency in `kong-3.16.0-0.rockspec:42`), and that binding never calls the one-shot `EVP_Cipher()`.

### CVE-2026-7383: OpenSSL heap buffer overflow in ASN.1 multibyte string conversion

A signed integer overflow during ASN.1 multibyte-string conversion (converting string data to a Unicode or wide-character output form) can lead to a heap buffer overflow when handling crafted multibyte string input.

**Is Kong affected?** No (not reachable). The overflow requires the conversion to target the `UNIVERSALSTRING` output type, and that type can't be selected through any path Kong exposes.

### CVE-2026-9076: OpenSSL out-of-bounds read in CMS password decryption

In OpenSSL CMS password-based decryption (RFC 3211 key wrapping), using a stream-mode key-encryption cipher can cause a heap out-of-bounds read, potentially crashing the application.

**Is Kong affected?** No (not reachable). Kong doesn't perform CMS decryption of any kind, password-based or otherwise. The CMS subsystem is unused in core and bundled plugins and isn't exposed to the plugin sandbox.

### CVE-2026-34180: OpenSSL heap over-read in ASN.1 content parsing

Parsing certain crafted ASN.1 content can cause OpenSSL to read past the end of the input buffer, which may crash the application or read adjacent memory.

**Is Kong affected?** Yes, as a residual risk. Like CVE-2026-7383, this issue lives in the ASN.1 layer that underpins X.509 parsing, which Kong does exercise. The impact is a read over-run (crash class, not code execution), and the CVE is rated Low. The most exposed configuration is mTLS, where untrusted clients submit certificates that Kong must parse.

Scenario: an untrusted client (mTLS) or a malicious upstream presents a malformed certificate or CRL crafted to trigger the over-read. The worst realistic outcome is a worker-process crash. If you don't use mutual TLS validation from untrusted sources, you aren't affected.

### CVE-2026-34181: OpenSSL PBMAC1 with short HMAC keys

When PKCS#12 files use PBMAC1 for integrity protection, OpenSSL may accept them even when they're protected by an unexpectedly short HMAC key. This weakens the integrity guarantee: an attacker could forge a certificate and key bundle that passes the MAC check with about 1-in-256 probability.

**Is Kong affected?** No in core. It's conditionally reachable only through a custom plugin. Kong configures TLS using PEM-format certificates and keys, not PKCS#12 (`.p12`) bundles, so core never parses PKCS#12. The `pkcs12` module is in the plugin sandbox, so a custom plugin that imports attacker-supplied `.p12` files would be exposed. No Kong core or bundled plugin parses PKCS#12.

Scenario (only if a custom plugin imports PKCS#12): a plugin that loads `.p12` bundles from an untrusted source could be tricked into accepting a forged bundle.

### CVE-2026-42766: OpenSSL NULL dereference in password-based CMS decryption

A NULL pointer dereference during password-based CMS decryption can crash the application (denial of service).

**Is Kong affected?** No (not reachable). Kong doesn't perform CMS decryption and doesn't expose CMS to plugins. No reachable code path invokes this logic.

### CVE-2026-42767: OpenSSL NULL dereference in CRMF EncryptedValue

During CMP (Certificate Management Protocol) response processing, decrypting a CRMF EncryptedValue can trigger a NULL pointer dereference, crashing the client.

**Is Kong affected?** No (not reachable). Kong isn't a CMP client and performs no certificate-management-protocol exchanges. The CMP and CRMF code is never invoked, and these modules aren't in the plugin sandbox.

### CVE-2026-42768: OpenSSL Bleichenbacher oracle in CMS_decrypt()

With multiple RecipientInfo entries, `CMS_decrypt()` and `PKCS7_decrypt()` can leak a padding-oracle signal (Bleichenbacher-style). Over many queries, this could let an attacker decrypt data or forge a signature using the victim's RSA key.

**Is Kong affected?** No (not reachable). Kong performs neither CMS nor PKCS#7 decryption. No decryption oracle is exposed, because the underlying functions are never called in core, in bundled plugins, or through the sandbox.

### CVE-2026-42769: OpenSSL trust anchor in CMP rootCaKeyUpdate

In the CMP `rootCaKeyUpdate` flow, a certificate and issuer typo-handling weakness could let a Registration Authority substitute the root CA certificate with an arbitrary one, undermining the trust anchor.

**Is Kong affected?** No (not reachable). Kong doesn't implement CMP and doesn't perform root-CA key-update exchanges. The vulnerable flow is never entered.

### CVE-2026-42770: OpenSSL FFC-DH peer validation uses attacker-supplied q

In finite-field Diffie-Hellman (FFC-DH), peer validation can rely on an attacker-supplied `q` domain parameter, enabling a small-subgroup attack that can recover the private key.

**Is Kong affected?** No in core. It's conditionally reachable only through a custom plugin. The Kong TLS configuration uses named Diffie-Hellman groups (FFDHE and ECDHE) negotiated per RFC. In TLS 1.3, the peer doesn't supply raw DH domain parameters including `q`, so the TLS path of the gateway isn't exposed. The `dh` module is in the plugin sandbox, so a custom plugin that performs raw finite-field DH while importing peer-supplied domain parameters could be affected. No Kong core or bundled plugin does this.

Scenario (only if a custom plugin does raw FFC-DH): a plugin negotiating a raw DH key agreement and accepting a peer-provided `q` could leak its private key over repeated exchanges.

### CVE-2026-45446: OpenSSL incorrect tag processing in AES-GCM-SIV

For the AES-GCM-SIV and AES-SIV modes, authentication-tag processing for empty messages is handled incorrectly, allowing an attacker to forge an empty message with arbitrary additional authenticated data (AAD).

**Is Kong affected?** No in core. It's conditionally reachable only through a custom plugin. SIV-family ciphers aren't used by the Kong TLS configuration or by any bundled plugin. They're reachable only if a custom plugin explicitly uses `aes-*-siv` or `aes-*-gcm-siv` through `resty.openssl.cipher`. No Kong core or bundled plugin uses SIV modes.

Scenario (only if a custom plugin uses SIV): a plugin relying on AES-SIV or GCM-SIV authenticity for empty-payload messages could accept a forged message.

## Impacted products

All {{site.ee_product_name_official}} versions prior to the patch versions listed in the Patches section.

## Patches

The vulnerabilities are addressed by applying the following patch:

{% table %}
columns:
  - title: Impacted supported versions of {{site.ee_product_name_official}}
    key: impacted
  - title: Patch
    key: patch
rows:
  - impacted: "3.15.0.0 - 3.15.0.2"
    patch: "3.15.0.3"
  - impacted: "3.14.0.0 - 3.14.0.11"
    patch: "3.14.0.12"
  - impacted: "3.13.0.0 - 3.13.0.8"
    patch: "3.13.0.9"
  - impacted: "3.12.0.0 - 3.12.0.9"
    patch: "3.12.0.10"
  - impacted: "3.10.0.0 - 3.10.0.16"
    patch: "3.10.0.17"
  - impacted: "3.4.0.0 - 3.4.3.28"
    patch: "3.4.3.29"
{% endtable %}

Each patch is available for all Kong distributions through standard Kong distribution channels. Kong Cloud Gateways have been updated automatically.

If you use {{site.ee_product_name_official}} or {{site.ai_gateway_name}} Enterprise, Kong recommends upgrading to the applicable patch.
