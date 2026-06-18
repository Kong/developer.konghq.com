The {{include.name}} plugin supports the following authentication schemes for Solace broker connections through [`session.authentication.scheme`](./reference/#schema--config-session-authentication-scheme):
{% table %}
columns:
  - title: "Scheme"
    key: scheme
  - title: Description
    key: description
  - title: Example
    key: example
rows:
  - scheme: "`NONE`"
    description: "No authentication."
    example: "--"
  - scheme: "`BASIC`"
    description: |
      Authenticates using a username and password.
      <br><br>
      Provide `session.authentication.username` and `session.authentication.password`, or supply credentials via `session.authentication.basic_auth_header`.
    example: |
      {% if include.slug == "solace-upstream" %}[Send message to Solace queues with persistent delivery](./examples/configure-solace/){% elsif include.slug == "solace-log" %}[Enable Solace Logging](./examples/enable-solace-log/){% else %}--{% endif %}
  - scheme: "`OAUTH2`"
    description: |
      Authenticates using a static OAuth 2.0 access token.
      <br><br>
      Provide `session.authentication.access_token` directly, or supply it via `session.authentication.access_token_header`.
      The token must be rotated manually when it expires.
    example: "--"
  - scheme: |
      `CLIENT_CREDENTIALS` {% new_in 3.15 %}
    description: |
      Authenticates using short-lived OAuth 2.0 access tokens fetched and renewed automatically by {{site.base_gateway}}.
      <br><br>
      {{site.base_gateway}} uses the `client_credentials` grant to retrieve tokens from `session.authentication.client_credentials.token_endpoint`, caches them until expiry, and retries with a fresh token if Solace returns an unauthenticated response.
      <br><br>
      Requires the `session.authentication.client_credentials` block.
    example: "[OAuth 2.0 client credentials authentication](./examples/oauth-client-credentials/)"
{% endtable %}
