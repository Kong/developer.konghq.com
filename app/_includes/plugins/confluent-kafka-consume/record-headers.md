The {{include.name}} plugin can forward HTTP request headers as [Kafka record headers](https://kafka.apache.org/documentation/#recordheader), which are per-record key/value metadata that lives alongside the message key and value.
This lets consumers read routing, tracing, or tenancy context without parsing the message payload.

Configure the [`config.headers`](./reference/#schema--config-headers) block to control which headers are forwarded:

{% table %}
columns:
  - title: Mode
    key: mode
  - title: Description
    key: description
  - title: Example
    key: example
rows:
  - mode: "Allowlist ([`forward_all_by_default: false`](./reference/#schema--config-headers-forward-all-by-default))"
    description: "Only forward headers listed in [`include_headers`](./reference/#schema--config-headers-include-headers)."
    example: "[Forward HTTP headers as Kafka record headers (allowlist mode)](./examples/record-headers-allowlist/)"
  - mode: "Blocklist ([`forward_all_by_default: true`](./reference/#schema--config-headers-forward-all-by-default))"
    description: "Forward all headers except those listed in [`exclude_headers`](./reference/#schema--config-headers-exclude-headers)."
    example: "[Forward HTTP headers as Kafka record headers (blocklist mode)](./examples/record-headers-blocklist/)"
{% endtable %}

Use [`config.headers.name_mappings`](./reference/#schema--config-headers-name-mappings) to rename an HTTP header to a different Kafka record header key.

Use [`config.headers.repeated_headers_behavior`](./reference/#schema--config-headers-repeated-headers-behavior) to control how duplicate HTTP headers are handled: `retain_duplicates` (default) creates a separate record header per value, `take_first` uses only the first value, and `concatenate_by_comma` joins all values with a comma.

{:.info}
> **Note**: The [`config.forward_headers`](./reference/#schema--config-forward-headers) setting embeds request headers inside the message body. `config.headers` is a separate configuration block that sets native Kafka record headers on the produced record.
