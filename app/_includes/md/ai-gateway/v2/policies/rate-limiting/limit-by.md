Use [`config.limit_by`](./reference/#schema--config-limit-by) to choose what the Policy aggregates counters against:

{% table %}
columns:
  - title: Value
    key: value
  - title: Description
    key: description
rows:
  - value: "`consumer`"
    description: "The authenticated [AI Consumer](/ai-gateway/entities/ai-consumer/). This is the default."
  - value: "`consumer-group`"
    description: "The [AI Consumer Group](/ai-gateway/entities/ai-consumer-group/) the AI Consumer belongs to."
  - value: "`credential`"
    description: The credential the AI Consumer authenticated with. Use this to limit each API key separately when one AI Consumer holds several.
  - value: "`ip`"
    description: "The client IP address. See [Limit by IP address](#limit-by-ip-address)."
  - value: "`header`"
    description: "The value of the header named in [`config.header_name`](./reference/#schema--config-header-name)."
  - value: "`path`"
    description: "The request path set in [`config.path`](./reference/#schema--config-path)."
{% endtable %}

### Limit by IP address

{% include md/ai-gateway/v2/policies/rate-limiting/limit-by-ip.md %}
