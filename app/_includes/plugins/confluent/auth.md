The plugin supports the following authentication options for Confluent Cloud connections:
{% table %}
columns:
  - title: "Auth method"
    key: method
  - title: Description
    key: description
  - title: Example
    key: example
rows:
  - method: "API key (`cluster_api_key` / `cluster_api_secret`)"
    description: "Authenticates using a Confluent Cloud API key and secret via SASL/PLAIN."
    example: "--"
  - method: |
      SASL/OAUTHBEARER (`oauthbearer`) {% new_in 3.15 %}
    description: |
      Authenticates using short-lived OAuth 2.0 access tokens fetched automatically by {{site.base_gateway}}.
      <br><br>
      {{site.base_gateway}} uses the `client_credentials` grant to retrieve tokens from the configured `oauthbearer.token_endpoint_url`, caches them until expiry, and presents them in the SASL/OAUTHBEARER handshake. When `oauthbearer` is set, it takes precedence over `cluster_api_key`/`cluster_api_secret`.
    example: "[SASL/OAUTHBEARER authentication](./examples/oauthbearer/)"
{% endtable %}
