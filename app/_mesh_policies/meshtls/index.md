---
title: Mesh TLS
name: MeshTLSes
products:
    - mesh
description: "Configure TLS mode, ciphers and version. Backends and default mode values are taken from the Mesh object."
content_type: plugin
type: policy
min_version:
  mesh: '2.9'
icon: meshtls.png
---

## TargetRef support matrix

{% tabs %}
{% tab targetRef For mode %}
{% if_version eq:2.9.x %}
| `targetRef`             | Allowed kinds        |
| ----------------------- | -------------------- |
| `targetRef.kind`        | `Mesh`, `MeshSubset` |
| `from[].targetRef.kind` | `Mesh`               |
{% endif_version %}
{% if_version gte:2.10.x %}
| `targetRef`             | Allowed kinds                                 |
| ----------------------- | --------------------------------------------- |
| `targetRef.kind`        | `Mesh`, `Dataplane`, `MeshSubset(deprecated)` |
{% endif_version %}
{% endtab %}
{% tab targetRef For tls ciphers/version %}
| `targetRef`             | Allowed kinds       |
| ----------------------- | ------------------- |
| `targetRef.kind`        | `Mesh`              |
| `from[].targetRef.kind` | `Mesh`              |
{% endtab %}
{% endtabs %}

To learn more about the information in this table, see the [matching docs](/docs/{{ page.release }}/policies/introduction).

## Configuration

The following describes the default configuration settings of the `MeshTLS` policy:

- **`tlsVersion`**: Defines TLS versions to be used by **both client and server**. Allowed values: `TLSAuto`, `TLS10`, `TLS11`, `TLS12`, `TLS13`.
- **`tlsCiphers`**: Defines TLS ciphers to be used by **both client and server**. Allowed values: `ECDHE-ECDSA-AES128-GCM-SHA256`, `ECDHE-ECDSA-AES256-GCM-SHA384`, `ECDHE-ECDSA-CHACHA20-POLY1305`, `ECDHE-RSA-AES128-GCM-SHA256`, `ECDHE-RSA-AES256-GCM-SHA384`, `ECDHE-RSA-CHACHA20-POLY1305`.
- **`mode`**: Defines the mTLS mode - `Permissive` mode encrypts outbound connections the same way as `Strict` mode, but inbound connections on the server-side accept both TLS and plaintext. Allowed values: `Strict`, `Permissive`.

{% tip %}
Setting the TLS version and ciphers on both the client and server makes it harder to configure incorrectly.
If you want to try out a specific version/cipher combination, we recommend creating a [temporary mesh](/docs/{{ page.release }}/production/mesh/#usage), deploying two applications within it, and testing whether communication is working.
If you have a use case for configuring a different set of allowed versions/ciphers on different workloads, we'd love to hear about it.
In that case, please open an [issue](https://github.com/kumahq/kuma/issues).
{% endtip %}
