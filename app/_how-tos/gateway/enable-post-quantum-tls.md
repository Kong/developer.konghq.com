---
title: Enable post-quantum TLS in {{site.base_gateway}}
permalink: /how-to/enable-post-quantum-tls/
content_type: how_to

related_resources:
  - text: Post-quantum TLS in {{site.base_gateway}}
    url: /gateway/post-quantum-tls/
  - text: "{{site.base_gateway}} configuration reference"
    url: /gateway/configuration/
  - text: File Log plugin
    url: /plugins/file-log/
  - text: "{{site.base_gateway}} logs"
    url: /gateway/logs/

plugins:
  - file-log

entities:
  - route
  - service
  - plugin

products:
  - gateway

works_on:
  - on-prem

min_version:
  gateway: '3.17'

tools:
  - deck

prereqs:
  gateway:
    - name: KONG_SSL_CIPHER_SUITE
  inline:
    - title: Post-quantum cipher suite
      position: before
      content: |
        Set the `pqc` value of the [`ssl_cipher_suite`](/gateway/configuration/#ssl-cipher-suite) parameter before you start the data plane:

        ```sh
        export KONG_SSL_CIPHER_SUITE=pqc
        ```

        The `pqc` suite turns on [hybrid post-quantum key exchange](/gateway/post-quantum-tls/#key-exchange-groups), which restricts client connections to TLS 1.3 and offers the group list `X25519MLKEM768:SecP256r1MLKEM768:X25519:P-256:P-384`.

        This list keeps the classical groups, so a client without post-quantum support can still connect.
      icon_url: /assets/icons/gateway.svg
    - title: OpenSSL 3.5 or later
      content: |
        This tutorial uses `openssl s_client` as a test client, because the client must support post-quantum key exchange.

        Check your version:

        ```sh
        openssl version
        ```

        OpenSSL 3.5 or later supports the hybrid `X25519MLKEM768` group.
        The `curl` that ships with macOS uses LibreSSL and doesn't support post-quantum groups, so don't use it for this tutorial.
      icon_url: /assets/icons/lock.svg
  entities:
    services:
        - example-service
    routes:
        - example-secure-route
tags:
  - tls
  - security
  - encryption

search_aliases:
  - pqc
  - post-quantum cryptography

description: Enable hybrid post-quantum key exchange in {{site.base_gateway}}, check which group each session negotiates, and reject clients without post-quantum support.

tldr:
  q: How do I enable post-quantum TLS in {{site.base_gateway}}?
  a: |
    1. Set `KONG_SSL_CIPHER_SUITE=pqc` when starting {{site.base_gateway}} to offer the hybrid `X25519MLKEM768` group, then check the `/pqc-status` endpoint.
    1. Confirm that a client negotiates the group by running `openssl s_client -groups X25519MLKEM768`, and read `request.tls.curve` in the logs.
    1. To reject clients without post-quantum support, set `ssl_require_pqc = on` in the node's configuration and reload {{site.base_gateway}}.

cleanup:
  inline:
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg
---

## Enable the File Log plugin

To see which group each session negotiates, enable the [File Log plugin](/plugins/file-log/), which writes each request to the container's standard output, including the TLS fields:

{% entity_examples %}
entities:
  plugins:
    - name: file-log
      config:
        path: /dev/stdout
{% endentity_examples %}

## Check the post-quantum status

Query the [`/pqc-status` endpoint](/gateway/post-quantum-tls/#check-the-state-of-a-node) of the Admin API to confirm that the node can do post-quantum TLS and see which groups it offers to clients:

{% control_plane_request %}
url: /pqc-status
method: GET
headers:
  - 'Accept: application/json'
status_code: 200
{% endcontrol_plane_request %}

If the {{site.base_gateway}} node was launched with `KONG_SSL_CIPHER_SUITE=pqc`, the response confirms that the node offers a post-quantum group to clients:

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

* The `http.client.key_exchange` value `post-quantum` means that the group list contains a post-quantum group.
* The `http.client.source` value `ssl_curves` shows that the `pqc` suite wrote the list.

The `/pqc-status` endpoint shows only what the node offers, not what each session negotiates.

## Validate hybrid key exchange

Test the handshake with two clients: one that offers a post-quantum group, and one that offers only a classical group.

1. Connect with a client that offers the `X25519MLKEM768` group:

   ```sh
   openssl s_client -brief -connect localhost:8443 -tls1_3 \
     -groups X25519MLKEM768:X25519 </dev/null 2>&1 \
     | grep -E "Negotiated TLS1.3 group|Peer Temp Key"
   ```
   {:data-test-step="block"}

   The client and {{site.base_gateway}} negotiate the post-quantum group:

   ```
   Negotiated TLS1.3 group: X25519MLKEM768
   ```
   {:.no-copy-code}

1. Connect with a client that offers only the classical `X25519` group:

   ```sh
   openssl s_client -brief -connect localhost:8443 -tls1_3 \
     -groups X25519 </dev/null 2>&1 \
     | grep -E "Negotiated TLS1.3 group|Peer Temp Key"
   ```
   {:data-test-step="block"}

   The handshake still succeeds, because the `pqc` suite keeps the classical groups.
   The session falls back to a classical group, which `openssl s_client` reports as the peer temporary key:

   ```
   Peer Temp Key: X25519, 253 bits
   ```
   {:.no-copy-code}

1. Send a request over each kind of connection, so the File Log plugin records the negotiated groups:

   ```sh
   for groups in X25519MLKEM768:X25519 X25519; do
     printf 'GET /anything HTTP/1.1\r\nHost: localhost\r\nConnection: close\r\n\r\n' \
       | openssl s_client -quiet -connect localhost:8443 -tls1_3 -groups $groups >/dev/null 2>&1
   done
   ```
   {:data-test-step="block"}

1. Read the TLS fields from the {{site.base_gateway}} log:

   ```sh
   docker logs --tail 20 kong-quickstart-gateway 2>&1 | grep -o '"tls":{[^}]*}'
   ```
   {:data-test-step="block"}

   The `curve` field shows the group that each session negotiated:

   ```json
   "tls":{"signature_algorithm":"id-ecPublicKey","version":"TLSv1.3","curve":"X25519MLKEM768","cipher":"TLS_AES_256_GCM_SHA384","client_verify":"NONE"}
   "tls":{"signature_algorithm":"id-ecPublicKey","version":"TLSv1.3","curve":"X25519","cipher":"TLS_AES_256_GCM_SHA384","client_verify":"NONE"}
   ```
   {:.no-copy-code}

   The `signature_algorithm` field names the key type of the certificate that {{site.base_gateway}} served.
   This is the self-signed default certificate, which uses an ECDSA key.

## Require post-quantum clients

By default, a client without post-quantum support falls back to a classical group.
The [`ssl_require_pqc`](/gateway/configuration/#ssl-require-pqc) parameter rejects that client instead.

{:.warning}
> **Rejecting clients stops their traffic.**
> In production, enable `ssl_require_pqc` only after the `curve` log field shows that every client negotiates a post-quantum group.

1. Reload {{site.base_gateway}} with `ssl_require_pqc` turned on:

   ```sh
   docker exec -e KONG_SSL_REQUIRE_PQC=on kong-quickstart-gateway kong reload
   ```
   {:data-test-step="block"}

1. Confirm that the node reports the policy:

{% capture require-pqc %}
{% control_plane_request %}
url: /pqc-status
method: GET
headers:
  - 'Accept: application/json'
status_code: 200
{% endcontrol_plane_request %}
{% endcapture %}

{{ require-pqc | indent: 3 }}

   In the response, `require_pqc` should be `true`.

## Validate the requirement

1. Connect with the client that offers a post-quantum group:

   ```sh
   openssl s_client -brief -connect localhost:8443 -tls1_3 \
     -groups X25519MLKEM768:X25519 </dev/null 2>&1 \
     | grep -E "Negotiated TLS1.3 group|alert"
   ```
   {:data-test-step="block"}

   The handshake succeeds:

   ```
   Negotiated TLS1.3 group: X25519MLKEM768
   ```
   {:.no-copy-code}

1. Connect with the client that offers only a classical group:

   ```sh
   openssl s_client -brief -connect localhost:8443 -tls1_3 \
     -groups X25519 </dev/null 2>&1 \
     | grep -E "Negotiated TLS1.3 group|alert"
   ```
   {:data-test-step="block"}

   This time, {{site.base_gateway}} rejects the handshake, and the client reports a TLS alert:

   ```
   error:0A000438:SSL routines:ssl3_read_bytes:tlsv1 alert internal error
   ```
   {:.no-copy-code}

1. Read the reason from the {{site.base_gateway}} log:

   ```sh
   docker logs --tail 20 kong-quickstart-gateway 2>&1 | grep "rejecting TLS handshake"
   ```
   {:data-test-step="block"}

   The `notice` entry names the cause and the client address:

   ```
   [notice] pqc.lua:577: enforce(): rejecting TLS handshake: the client offers no post-quantum group, and ssl_require_pqc is enabled, context: ssl_client_hello_by_lua*, client: 192.168.65.1, server: 0.0.0.0:8443
   ```
   {:.no-copy-code}

   The rejected connection doesn't appear in the access log, because the handshake stops before a request exists.
