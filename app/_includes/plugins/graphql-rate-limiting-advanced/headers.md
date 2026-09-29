
When this plugin is enabled, {{site.base_gateway}} sends some additional headers back to the client, indicating the cost of the GraphQL query and the state of the rate limiting policies in place:

{% table %}
columns:
  - title: Header
    key: header
  - title: Description
    key: description
rows:
  - header: X-Gql-Query-Cost
    description: The calculated cost of the GraphQL query in the request.
  - header: X-RateLimit-Limit-<window>
    description: The allowed limit for the matching [`config.window_size`](./reference/#schema--config-window_size) value, for example, `X-RateLimit-Limit-Minute`.
  - header: X-RateLimit-Remaining-<window>
    description: The number of requests still available for the matching [`config.window_size`](./reference/#schema--config-window_size) value, for example, `X-RateLimit-Remaining-Minute`.
{% endtable %}

The `<window>` part of the header name is a human-readable name for these common window sizes, in seconds: `Second` (`1`), `Minute` (`60`), `Hour` (`3600`), `Day` (`86400`), `Month` (`2592000`), and `Year` (`31536000`). 
For any other [`config.window_size`](./reference/#schema--config-window_size) value, the plugin uses the raw number of seconds instead, for example, `X-RateLimit-Limit-120`.

You can optionally hide the query cost, limit, and remaining headers with the [`config.hide_client_headers`](./reference/#schema--config-hide_client_headers) option.

If more than one window is set, the plugin returns multiple limit headers.
For example:

```plaintext
X-Gql-Query-Cost: 5
X-RateLimit-Limit-Minute: 100000
X-RateLimit-Remaining-Minute: 99995
X-RateLimit-Limit-Hour: 1000000
X-RateLimit-Remaining-Hour: 999995
```

If the query cost exceeds [`config.max_cost`](./reference/#schema--config-max_cost), the plugin returns an `HTTP/1.1 403` status code to the client with the following JSON body:

```json
{ "message": "API max cost limit exceeded" }
```

If any of the rate limit windows are exceeded, the plugin returns an `HTTP/1.1 429` status code to the client with the following JSON body:

```json
{ "message": "API rate limit exceeded" }
```

{:.info}
> These headers appear on successful responses and on `403` and `429` error responses. They do not appear when the plugin rejects the request before it calculates the query cost, for example when the GraphQL query is missing or invalid, or when upstream schema introspection fails (`400` responses).
