---
title: "Post-quantum TLS in {{site.base_gateway}}"
description: "Post-quantum TLS protects traffic that {{site.base_gateway}} proxies against harvest now, decrypt later attacks."
content_type: reference
layout: reference
tier: enterprise

products:
  - gateway

breadcrumbs:
  - /gateway/
tags:
  - tls
  - security
  - encryption
  - certificates
search_aliases:
  - pqc
  - post-quantum cryptography
  - hybrid key exchange

related_resources:
  - text: Enable post-quantum TLS
    url: /how-to/enable-post-quantum-tls/
  - text: "{{site.base_gateway}} configuration reference"
    url: /gateway/configuration/
  - text: SSL certificates in {{site.base_gateway}}
    url: /gateway/ssl-certificates/
  - text: Certificate entity
    url: /gateway/entities/certificate/
  - text: CA Certificate entity
    url: /gateway/entities/ca-certificate/

works_on:
  - on-prem
  - konnect

min_version:
  gateway: '3.17'

toc_depth: 3

faqs:
  - q: "Why does the post-quantum status report `available: false` in {{site.base_gateway}}?"
    a: |
      The `reason` field in the `/pqc-status` response names the cause.
      A reason that names FIPS mode means `fips` is on, so set `fips = off`.
      A reason that names `OpenSSL 3.5.0 or newer` means the node runs a build with an older OpenSSL, so upgrade the build.
      A reason that names `cannot perform ML-KEM` means the loaded OpenSSL providers don't offer ML-KEM, so check whether something overrides the `OPENSSL_CONF` environment variable.
  - q: Why does {{site.base_gateway}} refuse to start when I set both `ssl_curves` and `ssl_cipher_suite`?
    a: |
      {{site.base_gateway}} refuses to start when `ssl_cipher_suite` is `pqc` and `ssl_curves` names a different group list, because the two settings disagree about which groups {{site.base_gateway}} passes to OpenSSL.
      Keep one of the two settings.
      To write your own group list, set `ssl_cipher_suite = custom` and set `ssl_curves`.
  - q: Why do all of my clients negotiate a classical group when {{site.base_gateway}} offers a post-quantum group?
    a: |
      A client negotiates a post-quantum group only if the client offers one.
      Compare the TLS library version of each client with the [client support](#client-support) requirements.
      The `curve` log field shows the group that each session negotiated.
  - q: Why does the upstream TLS curve in {{site.base_gateway}} logs show a classical group when `proxy_ssl_curves` lists a post-quantum group?
    a: |
      The upstream doesn't support a post-quantum group, so the handshake fell back to a classical group.
      {{site.base_gateway}} completes the request and doesn't report an error for a fallback.
      To change the result, upgrade the upstream service.
  - q: Why can some clients no longer connect after I enabled `ssl_require_pqc` in {{site.base_gateway}}?
    a: |
      When `ssl_require_pqc` is enabled, {{site.base_gateway}} rejects any client that doesn't offer a post-quantum group over TLS 1.3.
      The rejection is expected for clients without post-quantum support.
      Read the `error.log` file for `notice` entries that name the client address, because a rejected handshake doesn't appear in the access log.
  - q: Why does a client report `unable to get local issuer certificate` against a post-quantum certificate?
    a: |
      A client reports `unable to get local issuer certificate` most often because it doesn't trust the CA that signed the post-quantum certificate.
      Compare the fingerprint of the CA that signed the certificate with the fingerprint of the CA in the client's trust store.
  - q: Why is `pqc_status` null for a data plane in {{site.base_gateway}}?
    a: |
      A `pqc_status` of `null` on `/clustering/data-planes` means the data plane didn't send a report, which happens when the data plane runs an older version.
      This differs from `available: false`, which means the data plane sent a report and can't do post-quantum TLS.
---

{{site.base_gateway}} can use post-quantum key exchange and post-quantum certificates in the TLS handshake.
Post-quantum TLS protects against "harvest now, decrypt later" attacks, where an attacker records encrypted traffic today and decrypts it when a quantum computer becomes available.

Post-quantum TLS adds post-quantum algorithms in the following places, which you can adopt independently:
* **Key exchange** protects recorded traffic by protecting the session keys. It's the higher priority, because an attacker can record traffic now and decrypt it later.
* **Certificate signatures** prove the identity of a server. An attacker can use a forged signature only while the certificate is valid, so they're the lower priority.

Key exchange applies to client connections and upstream connections.
Certificate signatures apply to the certificate that {{site.base_gateway}} serves to clients and the certificates that it verifies on upstream connections.

When enabling post-quantum cryptography (PQC), start with hybrid key exchange for client connections.
Most clients already support it, and a client without support will still connect.
Add stricter enforcement only after your logs show that every client negotiates a post-quantum group.

{:.success}
> **Want to get started?** See [Enable post-quantum TLS](/how-to/enable-post-quantum-tls/) to turn on hybrid key exchange, verify it, and require it.

## Requirements

To use post-quantum TLS in {{site.base_gateway}}, your Gateway node must meet the following requirements:
* {{site.base_gateway}} 3.17 or later.
* OpenSSL 3.5.0 or later. The {{site.base_gateway}} builds include a version that meets this requirement.
* FIPS mode off ([`fips = off`](/gateway/configuration/#fips)). See [FIPS mode](#fips-mode).

To check whether a node meets these requirements, see [Check the state of a node](#check-the-state-of-a-node).

## Key exchange

Key exchange protects the session keys of a TLS connection, and you configure it separately for client connections and upstream connections.

### Key exchange groups

A key exchange group is the algorithm that two TLS peers use to agree on a session key.
The name of a group describes the algorithms that it runs, and only the groups that contain ML-KEM resist a quantum attack.

<!--vale off-->
{% table %}
columns:
  - title: Group
    key: group
  - title: Algorithm
    key: algorithm
  - title: Resists quantum attack
    key: resists
rows:
  - group: "`X25519`"
    algorithm: Classical ECDH on Curve25519.
    resists: "No"
  - group: "`P-256`, `P-384`"
    algorithm: Classical ECDH on NIST curves.
    resists: "No"
  - group: "`MLKEM768`"
    algorithm: Post-quantum key encapsulation (ML-KEM-768, FIPS 203).
    resists: "Yes"
  - group: "`X25519MLKEM768`"
    algorithm: "Hybrid of X25519 and ML-KEM-768."
    resists: "Yes"
  - group: "`SecP256r1MLKEM768`"
    algorithm: "Hybrid of P-256 and ML-KEM-768."
    resists: "Yes"
{% endtable %}
<!--vale on-->

A hybrid group runs a classical algorithm and a post-quantum algorithm together, and derives the session key from both results.
The connection stays secure as long as either algorithm holds:
* If a quantum computer breaks the classical algorithm, the post-quantum algorithm still protects the session.
* If someone finds a flaw in ML-KEM, the classical algorithm still protects the session against attackers without a quantum computer.
  ML-KEM has a shorter record of attack analysis than the classical algorithms.

We recommend hybrid groups over a pure ML-KEM group, because a pure group depends on ML-KEM alone.

### Choose the key exchange groups for client connections

The following {{site.base_gateway}} parameters control key exchange.
Set them in `kong.conf` or as environment variables on each node.
In a hybrid deployment, set them on the data planes that terminate TLS.

<!--vale off-->
{% kong_config_table %}
config:
  - name: ssl_cipher_suite
  - name: ssl_curves
  - name: proxy_ssl_curves
  - name: ssl_require_pqc
{% endkong_config_table %}
<!--vale on-->

Choose how {{site.base_gateway}} sets the key exchange groups for client connections:

<!--vale off-->
{% table %}
columns:
  - title: Approach
    key: approach
  - title: Settings
    key: settings
  - title: TLS versions
    key: versions
  - title: Use when
    key: use
rows:
  - approach: Post-quantum suite
    settings: |
      * `ssl_cipher_suite = pqc`
    versions: TLS 1.3 only.
    use: You start a rollout and want to use the recommended hybrid groups without choosing them yourself.
  - approach: Custom suite
    settings: |
      * `ssl_cipher_suite = custom`
      * `ssl_protocols = TLSv1.3`
      * `ssl_curves = X25519MLKEM768:X25519`
    versions: You set them with `ssl_protocols`.
    use: You need to control the group order or the protocol versions.
  - approach: Standard suite with a group list
    settings: |
      * `ssl_cipher_suite = intermediate`
      * `ssl_curves = X25519MLKEM768:X25519`
    versions: From the suite. TLS 1.2 clients can still connect.
    use: You want your own group list and need to keep TLS 1.2 clients.
  - approach: Standard suite without a group list
    settings: |
      * `ssl_cipher_suite = intermediate`
    versions: From the suite.
    use: You don't need to control the groups and accept the OpenSSL default list.
{% endtable %}
<!--vale on-->

The `pqc` suite sets the following values:
* TLS 1.3 as the only protocol, because ML-KEM exists only in the TLS 1.3 key agreement.
* The group list `X25519MLKEM768:SecP256r1MLKEM768:X25519:P-256:P-384`, which {{site.base_gateway}} writes to [`ssl_curves`](/gateway/configuration/#ssl-curves).

The list keeps the classical groups, so a client without post-quantum support still connects and negotiates a classical group.
The `pqc` suite therefore prefers post-quantum key exchange without requiring it, which suits a gradual rollout.
To reject clients without post-quantum support, see [Require post-quantum for client connections](#require-post-quantum-for-client-connections).

OpenSSL selects the first group in the list that the client also supports, so the order of a custom list matters.
Keep the classical groups in a custom list unless every client supports a post-quantum group.
For example, the following custom list puts a hybrid group first and keeps two classical groups as a fallback:

```
ssl_cipher_suite = custom
ssl_protocols = TLSv1.3
ssl_curves = X25519MLKEM768:X25519:P-256
```

When you leave `ssl_curves` unset, OpenSSL uses its default group list, which {{site.base_gateway}} can't report.
Set `ssl_curves` or use the `pqc` suite when you need to be certain of the list.

### Require post-quantum for client connections

By default, a client without post-quantum support falls back to a classical group.
The [`ssl_require_pqc`](/gateway/configuration/#ssl-require-pqc) parameter changes this: when you set `ssl_require_pqc = on`, {{site.base_gateway}} rejects the TLS handshake of a client that doesn't offer both of the following:
* A post-quantum group
* TLS 1.3

{{site.base_gateway}} checks both conditions because a client that offers a post-quantum group but caps its version below TLS 1.3 can't use that group.

{:.warning}
> **Rejecting clients stops their traffic.**
> Enable `ssl_require_pqc` only after you confirm that all of your clients support post-quantum TLS.
> Collect the [`curve` log field](#log-fields) over a representative period, and enable the parameter only when every session negotiates a post-quantum group.

The `ssl_require_pqc` parameter applies to client connections on proxy listeners.
It doesn't apply to connections to upstreams.

{{site.base_gateway}} refuses to start when `ssl_require_pqc` is on and the configuration can't satisfy it.
For example, `ssl_curves` lists only classical groups, or TLS 1.3 isn't allowed.

A rejected client sees a TLS-level error.
For example, `openssl s_client` reports `tlsv1 alert internal error`.
The reason appears only in the gateway log, as a `notice` entry that names the cause and the client address:

```
[notice] pqc.lua:577: enforce(): rejecting TLS handshake: the client offers no post-quantum group, and ssl_require_pqc is enabled, context: ssl_client_hello_by_lua*, client: 192.168.171.1, server: 0.0.0.0:8443
```
{:.no-copy-code}

{{site.base_gateway}} stops the handshake before a request exists, so a rejected connection doesn't appear in the access log.
To investigate a client that can't connect, read the `error.log` file.

### Choose the key exchange groups for upstream connections

The [`proxy_ssl_curves`](/gateway/configuration/#proxy-ssl-curves) parameter sets the groups that {{site.base_gateway}} offers to upstream services:

```
proxy_ssl_curves = X25519MLKEM768:X25519:P-256
```

The parameter applies to connections from {{site.base_gateway}} to upstream services over HTTP, HTTPS, gRPC, and stream.
It doesn't apply to other outbound connections, such as database or Redis connections.

The `ssl_curves` parameter doesn't affect upstream connections, and `proxy_ssl_curves` doesn't affect client connections.

If an upstream doesn't support a post-quantum group, the handshake falls back to a classical group and the request completes.
Clients adopt post-quantum TLS faster than backend services do, so most operators enable client connections first.
Enable upstream connections when your backends support it.

### Conflicting settings

Use only one setting to decide the key exchange groups for a connection on a proxy listener.
{{site.base_gateway}} refuses to start or reload when two settings set different groups for the same connection.
It also refuses when a raw Nginx directive overrides the Kong setting.

{{site.base_gateway}} rejects the following combinations:
* `ssl_cipher_suite = pqc` and an `ssl_curves` value that differs from the suite's group list.
* `ssl_curves` or `proxy_ssl_curves` and a raw Nginx directive that sets a different list for the same connection.
* A raw group directive set to `auto`, which ignores the Kong setting.
* `proxy_ssl_curves` and another raw conf command on a nested Nginx block, which drops the group list.
* An `ssl_curves` value with a post-quantum group and an `ssl_protocols` value without `TLSv1.3`, even when `ssl_require_pqc` is off.

{{site.base_gateway}} accepts a raw directive that repeats the same value as the Kong setting.

## Post-quantum certificates

Certificates use ML-DSA (FIPS 204) signatures, which are independent of the key exchange group.

### Certificates for client connections

{{site.base_gateway}} can serve a classical certificate and an ML-DSA certificate on the same IP address and port.
OpenSSL selects one of them from the signature algorithms that the client announces:

<!--vale off-->
{% table %}
columns:
  - title: Client
    key: client
  - title: Certificate it receives
    key: cert
rows:
  - client: Announces ML-DSA support.
    cert: The ML-DSA certificate.
  - client: Supports classical signature algorithms only.
    cert: The classical certificate.
{% endtable %}
<!--vale on-->

Both kinds of client verify the certificate they receive, so you don't have to change a client during the rollout.

To serve both certificates for the proxy listeners, list both in [`ssl_cert`](/gateway/configuration/#ssl-cert) and [`ssl_cert_key`](/gateway/configuration/#ssl-cert-key):

```ini
ssl_cert = /path/api-ec.crt, /path/api-mldsa.crt
ssl_cert_key = /path/api-ec.key, /path/api-mldsa.key
```

The [Certificate](/gateway/entities/certificate/) entity also accepts an ML-DSA key pair.
Set the ML-DSA certificate in `cert` and `key` and the classical one in `cert_alt` and `key_alt`, or the other way around.
The two certificates must use different key types.

An ML-DSA certificate and key are much larger than classical ones, so the handshake sends more data.

### Certificates for upstream connections

The [CA Certificate](/gateway/entities/ca-certificate/) entity accepts an ML-DSA trust anchor, so {{site.base_gateway}} can verify an upstream service that presents an ML-DSA certificate.

## Observe post-quantum TLS

{{site.base_gateway}} reports post-quantum TLS through status endpoints that show what a node offers, and log fields that show what each session negotiated.

{:.info}
> **Note**: The `/pqc-status` endpoint shows what a node offers, and the log fields show what each session negotiated. The two sources can differ.
> For example, `/pqc-status` can report `upstream.key_exchange: post-quantum` while `upstream_tls.curve` is `X25519`, because the upstream doesn't support a post-quantum group.
> Base any compliance statements on the log records.

### Check the state of a node

The `/pqc-status` endpoint reports the post-quantum state of a node.
Both the [Admin API](/api/gateway/admin-ee/) and the [Status API](/api/gateway/status/) serve it with the same content.
The Status API is there because a data plane in hybrid mode doesn't run an Admin API.

```sh
curl -s http://localhost:8001/pqc-status | jq
```

The following response is from a node with `ssl_cipher_suite = pqc`, trimmed to the HTTP subsystem:

```json
{
  "available": true,
  "reason": null,
  "openssl_version": "OpenSSL 3.5.9 29 Sep 2026",
  "require_pqc": false,
  "ssl_cipher_suite": "pqc",
  "ssl_ciphers": null,
  "http": {
    "protocols": "TLSv1.3",
    "protocols_source": "ssl_cipher_suite",
    "client": {
      "curves": "X25519MLKEM768:SecP256r1MLKEM768:X25519:P-256:P-384",
      "source": "ssl_curves",
      "key_exchange": "post-quantum"
    },
    "upstream": {
      "curves": null,
      "source": "openssl-default",
      "key_exchange": "openssl-default"
    }
  },
  "stream": { "...": "Same structure as http" }
}
```
{:.no-copy-code}

The endpoint reports the HTTP and stream subsystems separately.
Each subsystem reports the protocols that it serves and, for the `client` and `upstream` connections, the group list that {{site.base_gateway}} passes to OpenSSL.

<!--vale off-->
{% table %}
columns:
  - title: Field
    key: field
  - title: Meaning
    key: meaning
rows:
  - field: "`available`, `reason`"
    meaning: Whether the node can do post-quantum TLS, and the cause when it can't.
  - field: "`curves`"
    meaning: The group list that {{site.base_gateway}} passes to OpenSSL. A value of `null` means no setting applies, and OpenSSL uses its default.
  - field: "`source`"
    meaning: The setting that the list comes from. The value is `ssl_curves`, `proxy_ssl_curves`, the name of a raw Nginx setting that took precedence, or `openssl-default`.
  - field: "`key_exchange`"
    meaning: |
      Whether the list resists a quantum attack:
      * `post-quantum`: The list contains a post-quantum group.
      * `classical`: The list contains no post-quantum group.
      * `openssl-default`: No {{site.base_gateway}} setting defines a list.
      * `unavailable`: The node can't do post-quantum TLS.
  - field: "`protocols`, `protocols_source`"
    meaning: The TLS protocol versions that the subsystem serves, and the setting that they come from.
{% endtable %}
<!--vale on-->

### Check all data planes in hybrid mode

To check every data plane, query the `/clustering/data-planes` endpoint on the control plane:

```sh
curl -s http://localhost:8001/clustering/data-planes | jq '.data[] | {hostname, version, pqc_status}'
```

The `pqc_status` of each data plane has the same content as the `/pqc-status` response of that node.
The data plane sends its report when it connects, so `pqc_status` is a snapshot from its last connection.

### Log fields

{{site.base_gateway}} adds the following fields to the log record of every logging plugin, such as [File Log](/plugins/file-log/), [HTTP Log](/plugins/http-log/), and [Kafka Log](/plugins/kafka-log/):

<!--vale off-->
{% table %}
columns:
  - title: Field
    key: field
  - title: Subsystem
    key: subsystem
  - title: Meaning
    key: meaning
rows:
  - field: "`request.tls.curve`"
    subsystem: HTTP
    meaning: The group that the client handshake negotiated.
  - field: "`request.tls.signature_algorithm`"
    subsystem: HTTP
    meaning: The key type of the certificate that {{site.base_gateway}} served, such as `id-ml-dsa-65`.
  - field: "`session.tls.curve`"
    subsystem: Stream
    meaning: The group that the client handshake negotiated.
  - field: "`session.tls.signature_algorithm`"
    subsystem: Stream
    meaning: The key type of the certificate that {{site.base_gateway}} served.
  - field: "`upstream_tls.curve`"
    subsystem: HTTP
    meaning: The group that the upstream handshake negotiated.
{% endtable %}
<!--vale on-->

The following log record is from a client that negotiated a post-quantum group and received an ML-DSA certificate, while the upstream handshake used a classical group:

```json
{
  "request": {
    "tls": {
      "version": "TLSv1.3",
      "cipher": "TLS_AES_256_GCM_SHA384",
      "curve": "X25519MLKEM768",
      "signature_algorithm": "id-ml-dsa-65"
    }
  },
  "upstream_tls": { "curve": "X25519" }
}
```
{:.no-copy-code}

Keep the following points in mind when you filter logs:
* A field without a value is absent from the record. For example, `curve` is absent when the handshake didn't negotiate a group, such as a TLS 1.2 RSA key exchange.
* The `signature_algorithm` field holds the OID short name of the certificate key type, such as `id-ml-dsa-65` or `id-ecPublicKey`, without a digest algorithm.
  A filter for a TLS signature scheme name such as `mldsa65` matches nothing.

## FIPS mode

FIPS mode and post-quantum TLS are mutually exclusive, because FIPS 140-3 validated OpenSSL providers don't include ML-KEM or ML-DSA.

When [`fips`](/gateway/configuration/#fips) is on, {{site.base_gateway}} refuses to start if the configuration enables post-quantum cryptography.
For example, `ssl_cipher_suite = pqc`, `ssl_require_pqc = on`, or a post-quantum certificate stops the node from starting.
It also rejects a post-quantum certificate in a Certificate or CA Certificate entity, a declarative configuration file, or a `POST /config` request.

A data plane in FIPS mode applies a configuration synced from a control plane even when it contains a post-quantum certificate, and logs a warning.

A FIPS build of {{site.base_gateway}} can serve post-quantum TLS when `fips` is off.

## Roll out post-quantum TLS

The following order lets you adopt post-quantum TLS without stopping the traffic of any client until the last step:

1. Observe first.
   Learn which clients connect to your gateway, and don't change the configuration.
1. Enable post-quantum key exchange for client connections with `ssl_cipher_suite = pqc`.
   Clients without support negotiate a classical group, so nothing breaks.
1. Measure.
   Count the share of post-quantum groups in `request.tls.curve` over time.
1. Add an ML-DSA certificate alongside the classical one.
   Each client selects the certificate that it can verify.
1. Enable post-quantum key exchange for upstream connections with `proxy_ssl_curves`.
   An upstream without support falls back, so nothing breaks.
1. Consider `ssl_require_pqc = on` last, only when the `curve` log field shows that post-quantum groups account for all sessions.
   Prepare a rollback plan.

You can revert every step except `ssl_require_pqc` at any time.
Only `ssl_require_pqc` stops the traffic of a client that doesn't support post-quantum TLS.

### Client support

A client negotiates a post-quantum group only when its own TLS library supports one.
The following clients support `X25519MLKEM768`:

<!--vale off-->
{% table %}
columns:
  - title: Client
    key: client
  - title: Requirement
    key: requirement
rows:
  - client: OpenSSL and curl
    requirement: OpenSSL 3.5.0 or later. Run `curl --version` to check which OpenSSL version curl uses.
  - client: Go
    requirement: Go 1.24 or later. Go enables the group by default.
  - client: Chrome and Edge
    requirement: Version 131 or later. The browsers enable the group by default.
  - client: Firefox
    requirement: Version 132 or later. Firefox enables the group by default.
{% endtable %}
<!--vale on-->

To confirm that a client negotiates a post-quantum group, run `openssl s_client` against the gateway:

```sh
echo | openssl s_client -brief -connect api.example.com:8443 -tls1_3 \
  -groups X25519MLKEM768:X25519:P-256 2>&1 \
  | grep -E "Negotiated TLS1.3 group|Peer Temp Key|Signature type"
```

A session that negotiated a post-quantum group reports `Negotiated TLS1.3 group: X25519MLKEM768`.
A session that fell back to a classical group reports the group on a `Peer Temp Key` line instead.

gRPC and the stream subsystem use the same settings.
Whether a gRPC client negotiates a post-quantum group depends on its TLS library.

## Limitations

Post-quantum TLS in {{site.base_gateway}} has the following limitations:
* FIPS mode and post-quantum TLS are mutually exclusive, because FIPS providers don't include ML-KEM or ML-DSA.
* SLH-DSA certificates aren't supported. Certificates support ML-DSA only.
* `ssl_require_pqc` constrains client connections to the proxy listeners only. No equivalent option exists for upstream connections or for the other listeners.
* A handshake that fails inside OpenSSL, such as when no common group exists, doesn't produce a structured {{site.base_gateway}} log field. The Nginx `error.log` file is the source for those failures.
