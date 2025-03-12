
When this plugin is enabled, {{site.base_gateway}} sends some additional headers back to the client, indicating the state of the rate limiting policies in place:

| Header | Description |
|--------|-------------|
| RateLimit-Limit | Allowed limit in the timeframe. |
| RateLimit-Remaining | Number of available requests remaining. |
| RateLimit-Reset | The time remaining, in seconds, until the rate limit quota is reset. |
| X-RateLimit-Limit-Second | The time limit, in number of seconds. |
| X-RateLimit-Limit-Minute | The time limit, in number of minutes. |
| X-RateLimit-Limit-Day | The time limit, in number of days. |
| X-RateLimit-Limit-Month | The time limit, in number of months. |
| X-RateLimit-Limit-Year | The time limit, in number of years. |
| X-RateLimit-Remaining-Second | The number of seconds still left in the time frame. |
| X-RateLimit-Remaining-Minute | The number of minutes still left in the time frame. |
| X-RateLimit-Remaining-Day | The number of days still left in the time frame. |
| X-RateLimit-Remaining-Month | The number of months still left in the time frame. |
| X-RateLimit-Remaining-Year | The number of years still left in the time frame. |
| Retry-After |  This header appears on `429` errors, indicating how long the upstream service is expected to be unavailable to the client. <br> {% if include.name == "Rate Limiting Advanced" %} When using `window_type: sliding` and `RateLimit-Reset`, `Retry-After` may increase due to the rate calculation for the sliding window.{% endif %} |

You can optionally hide the limit and remaining headers with the [`config.hide_client_headers`](./reference/#schema--config-hide_client_headers) option.

If more than one limit is set, the plugin returns multiple time limit headers. 
For example:

```plaintext
X-RateLimit-Limit-Second: 5
X-RateLimit-Remaining-Second: 4
X-RateLimit-Limit-Minute: 10
X-RateLimit-Remaining-Minute: 9
```

If any of the limits are reached, the plugin returns an `HTTP/1.1 429` status
code to the client with the following JSON body:

```json
{ "message": "API rate limit exceeded" }
```

{:.warning}
> The headers `RateLimit-Limit`, `RateLimit-Remaining`, and `RateLimit-Reset` are based on the Internet-Draft [RateLimit Header Fields for HTTP](https://datatracker.ietf.org/doc/draft-ietf-httpapi-ratelimit-headers) and may change in the future to respect specification updates.


