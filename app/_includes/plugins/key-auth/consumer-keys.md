When you create [a Consumer](/gateway/entities/consumer/#set-up-a-consumer) or a [Principal identity](/identity/principals/#configure-a-principal) {% new_in 3.15 %}, you can specify a `key`.

{% navtabs "set a key" %}
{% navtab "Consumers" %}

- Declarative configuration with `keyauth_credentials`
- The `/consumers/{usernameOrId}/{{include.slug}}` endpoint.

{% endnavtab %}
{% navtab "Principals" %}

- A POST request to the `/v2/directories/{directoryId}/principals/{principalId}/api-keys` endpoint
- The {{site.konnect_short_name}} UI

{% endnavtab %}
{% endnavtabs %}


When authenticating, Consumers and principals must specify their key in either the query, body, or header:

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
      curl http://localhost:8000/$PROXY_PATH?apikey=$APIKEY
      ```
    description: |
      To use the key in URL queries, set the configuration parameter 
      [`config.key_in_query`](./reference/#schema--config-key-in-query) to 
      `true` (default option).
  - use: Key in body
    example: |
      ```bash
      curl http://localhost:8000/$PROXY_PATH \
      --data 'apikey: {some_key}'
      ```
    description: |
      To use the key in a request body, set the configuration parameter 
      [`config.key_in_body`](./reference/#schema--config-key-in-body) to `true`. 
      The default value is `false`.
  - use: Key in header
    example: |
      ```bash
      curl http://kong:8000/$PROXY_PATH \
      -H 'apikey: $APIKEY'
      ```
    description: |
      To use the key in a request body, set the configuration parameter 
      [`config.key_in_header`](./reference/#schema--config-key-in-header) 
      to `true` (default option).
{% endtable %}