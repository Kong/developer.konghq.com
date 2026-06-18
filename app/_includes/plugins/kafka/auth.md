The {{include.name}} plugin supports the following SASL authentication mechanisms for broker connections via [`authentication.mechanism`](./reference/#schema--config-authentication-mechanism):
{% table %}
columns:
  - title: "Mechanism"
    key: mechanism
  - title: Description
    key: description
  - title: Example
    key: example
rows:
  - mechanism: "`PLAIN`"
    description: |
      Authenticates using a username and password.
      <br><br>
      Set `authentication.strategy` to `sasl` and provide `authentication.user` and `authentication.password`.
    example: |
      {% if include.slug == "kafka-consume" %}--{% else %}[Plain authentication](./examples/plain-auth/){% endif %}
  - mechanism: "`SCRAM-SHA-256`"
    description: |
      Authenticates using a username and password with SCRAM-SHA-256 hashing.
      <br><br>
      Set `authentication.strategy` to `sasl` and provide `authentication.user` and `authentication.password`.
    example: |
      {% if include.slug == "kafka-consume" %}--{% else %}[SCRAM-SHA-256 authentication](./examples/scram-sha-256/){% endif %}
  - mechanism: "`SCRAM-SHA-512`"
    description: |
      Authenticates using a username and password with SCRAM-SHA-512 hashing.
      <br><br>
      Set `authentication.strategy` to `sasl` and provide `authentication.user` and `authentication.password`.
    example: |
      {% if include.slug == "kafka-consume" %}--{% else %}[SCRAM-SHA-512 authentication](./examples/scram-sha-512/){% endif %}
  - mechanism: |
      `OAUTHBEARER` {% new_in 3.15 %}
    description: |
      Authenticates using short-lived OAuth 2.0 access tokens fetched automatically by {{site.base_gateway}}.
      <br><br>
      {{site.base_gateway}} uses the `client_credentials` grant to retrieve tokens from the configured `authentication.oauthbearer.token_endpoint_url`, caches them until expiry, and presents them in the SASL/OAUTHBEARER handshake.
      <br><br>
      Requires the `authentication.oauthbearer` block.
    example: "[SASL/OAUTHBEARER authentication](./examples/oauthbearer/)"
{% endtable %}
