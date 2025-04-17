When you [create a Consumer](/gateway/entities/consumer/#set-up-a-consumer), you can specify a `key` with `keyauth_credentials` (declarative configuration) or the `/consumers/{usernameOrId}/{{include.slug}}` endpoint.

When authenticating, Consumers must specify their key in either the query, body, or header:

{% table %}
columns:
  - title: Use
    key: use
  - title: Example
    key: example
    width: 50
  - title: Description
    key: description
rows:
  - use: Key in query
    example: |
      ```bash
      curl http://localhost:8000/{proxyPath}?apikey={some_key}
      ```
    description: |
      To use the key in URL queries, set the configuration parameter 
      [`config.key_in_query`](./reference/#schema--config-key-in-query) to 
      `true` (default option).
  - use: Key in body
    example: |
      ```bash
      curl http://localhost:8000/{proxyPath} \
      --data 'apikey: {some_key}'
      ```
    description: |
      To use the key in a request body, set the configuration parameter 
      [`config.key_in_body`](./reference/#schema--config-key-in-body) to `true`. 
      The default value is `false`."
  - use: Key in header
    example: |
      ```bash
      curl http://kong:8000/{proxy path} \
      -H 'apikey: {some_key}'
      ```
    description: |
      To use the key in a request body, set the configuration parameter 
      [`config.key_in_header`](./reference/#schema--config-key-in-header) 
      to `true` (default option).
{% endtable %}