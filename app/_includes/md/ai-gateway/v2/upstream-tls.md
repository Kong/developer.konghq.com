Every {{include.name}} generates an underlying {{site.base_gateway}} Service that proxies requests to the upstream in [`config.url`](#{{include.schema_prefix}}-url).
Two optional `config` fields control how that Service handles TLS with the upstream:

<!-- vale off -->
{% table %}
columns:
  - title: Field
    key: field
  - title: Description
    key: description
rows:
  - field: "[`config.certificates`](#{{include.schema_prefix}}-certificates)"
    description: |
      A single [AI Certificate](/ai-gateway/entities/ai-certificate/), referenced by name, that the generated Service presents as its client certificate during the TLS handshake with the upstream.
      Use this when the upstream requires mutual TLS (mTLS).
      The `certificates` array accepts one entry, and the referenced AI Certificate must include a private key.
      When the field is unset, the generated Service doesn't present a client certificate to the upstream.
  - field: "[`config.ca_certificates`](#{{include.schema_prefix}}-ca-certificates)"
    description: |
      One or more [AI CA Certificates](/ai-gateway/entities/ai-ca-certificate/), referenced by name, that build the trust store the generated Service uses to verify the upstream's TLS certificate.
      Use this when the upstream serves a certificate signed by a private or internal CA.
      When the field is unset, the generated Service uses the data plane's default trust store.
{% endtable %}
<!-- vale on -->
