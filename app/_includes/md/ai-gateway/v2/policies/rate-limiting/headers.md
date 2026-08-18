When this Policy is enabled, {{site.ai_gateway}} sends some additional headers back to the client, indicating the state of the rate limits in place:

{% table %}
columns:
  - title: Header
    key: header
  - title: Description
    key: description
rows:
  - header: RateLimit-Limit
    description: Allowed limit in the timeframe.
  - header: RateLimit-Remaining
    description: Number of available requests remaining.
  - header: RateLimit-Reset
    description: The time remaining, in seconds, until the rate limit quota is reset.
  - header: X-RateLimit-Limit-Second
    description: The time limit, in number of seconds.
  - header: X-RateLimit-Limit-Minute
    description: The time limit, in number of minutes.
  - header: X-RateLimit-Limit-Day
    description: The time limit, in number of days.
  - header: X-RateLimit-Limit-Month
    description: The time limit, in number of months.
  - header: X-RateLimit-Limit-Year
    description: The time limit, in number of years.
  - header: X-RateLimit-Remaining-Second
    description: The number of seconds still left in the time frame.
  - header: X-RateLimit-Remaining-Minute
    description: The number of minutes still left in the time frame.
  - header: X-RateLimit-Remaining-Day
    description: The number of days still left in the time frame.
  - header: X-RateLimit-Remaining-Month
    description: The number of months still left in the time frame.
  - header: X-RateLimit-Remaining-Year
    description: The number of years still left in the time frame.
  - header: Retry-After
    description: This header appears on `429` errors, indicating how long the upstream service is expected to be unavailable to the client.
{% endtable %}

You can optionally hide the limit and remaining headers with the [`config.hide_client_headers`](./reference/#schema--config-hide-client-headers) option.

If more than one limit is set, the Policy returns multiple time limit headers.
For example:

```plaintext
X-RateLimit-Limit-Second: 5
X-RateLimit-Remaining-Second: 4
X-RateLimit-Limit-Minute: 10
X-RateLimit-Remaining-Minute: 9
```

If any of the limits are reached, the Policy returns an `HTTP/1.1 429` status code to the client with the following JSON body:

```json
{ "message": "API rate limit exceeded" }
```

Override the status code with [`config.error_code`](./reference/#schema--config-error-code) and the message with [`config.error_message`](./reference/#schema--config-error-message).

{:.warning}
> The headers `RateLimit-Limit`, `RateLimit-Remaining`, and `RateLimit-Reset` are based on the Internet-Draft [RateLimit Header Fields for HTTP](https://datatracker.ietf.org/doc/draft-ietf-httpapi-ratelimit-headers) and may change in the future to respect specification updates.
