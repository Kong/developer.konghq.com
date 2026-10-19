When {{include.name}} connects to an upstream (the server at [`config.url`](#{{include.schema_prefix}}-url)), it does so over TLS by default, without presenting a client certificate, and trusts only the certificate authorities (CAs) in the data plane's default trust store.
Use the following fields in `config` when your upstream needs something different:

<!-- vale off -->
{% table %}
columns:
  - title: Use case
    key: use_case
  - title: Field
    key: field
  - title: What to reference
    key: reference
rows:
  - use_case: |
      The upstream requires mutual TLS (mTLS), so {{include.name}} must prove its identity to the upstream.
    field: "[`config.certificates`](#{{include.schema_prefix}}-certificates)"
    reference: |
      One [AI Certificate](/ai-gateway/entities/ai-certificate/). It must include a private key.
      The field is an array, but accepts only one entry.
  - use_case: |
      The upstream serves a certificate signed by a private or internal CA that the data plane doesn't trust by default.
    field: "[`config.ca_certificates`](#{{include.schema_prefix}}-ca-certificates)"
    reference: |
      One or more [AI CA Certificates](/ai-gateway/entities/ai-ca-certificate/). Together, they replace the default trust store when {{include.name}} verifies the upstream.
{% endtable %}
<!-- vale on -->

You can use either field on its own, or both together.

To reference a certificate, create the AI Certificate or AI CA Certificate first, then enter its `name` in the field.
The `name` of a certificate can't be changed after you create it, so the reference stays valid.
If a referenced name doesn't exist, the API returns an `HTTP 400` error.
