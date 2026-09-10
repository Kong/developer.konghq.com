The {{ include.name }} Policy supports the following SASL authentication mechanisms for broker connections through [`config.authentication.mechanism`](./reference/#schema--config-authentication-mechanism):

{% table %}
columns:
  - title: "Mechanism"
    key: mechanism
  - title: Description
    key: description
rows:
  - mechanism: "`PLAIN`"
    description: |
      Authenticates using a username and password.
      <br><br>
      Set `authentication.strategy` to `sasl` and provide `authentication.user` and `authentication.password`.
  - mechanism: "`SCRAM-SHA-256`"
    description: |
      Authenticates using a username and password with SCRAM-SHA-256 hashing.
      <br><br>
      Set `authentication.strategy` to `sasl` and provide `authentication.user` and `authentication.password`.
  - mechanism: "`SCRAM-SHA-512`"
    description: |
      Authenticates using a username and password with SCRAM-SHA-512 hashing.
      <br><br>
      Set `authentication.strategy` to `sasl` and provide `authentication.user` and `authentication.password`.
{% endtable %}

Configure TLS for broker connections with [`config.security`](./reference/#schema--config-security).
