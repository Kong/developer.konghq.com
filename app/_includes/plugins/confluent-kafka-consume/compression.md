The {{include.name}} plugin can compress message batches from a producer before sending them to the Kafka broker, using [`config.compression_type`](./reference/#schema--config-compression-type).
Compression reduces network bandwidth between {{site.base_gateway}} and the broker, broker disk usage, and cross-broker replication cost.

This applies only to the {{site.base_gateway}}-to-broker traffic flow.
It's independent of any HTTP-level `Content-Encoding` between clients and {{site.base_gateway}}, and works the same way in both sync and async producer modes.

{% table %}
columns:
  - title: Codec
    key: codec
  - title: Ratio
    key: ratio
  - title: Speed
    key: speed
  - title: Notes
    key: notes
rows:
  - codec: "`none` (default)"
    ratio: "N/A"
    speed: "N/A"
    notes: "No compression. Preserves current behavior on upgrade."
  - codec: "`gzip`"
    ratio: "Highest"
    speed: "Slowest"
    notes: "Best when bandwidth or storage is the binding constraint and producer CPU is cheap."
  - codec: "`snappy`"
    ratio: "Moderate"
    speed: "Fast"
    notes: "A common default for throughput-sensitive Kafka workloads."
  - codec: "`lz4`"
    ratio: "Moderate"
    speed: "Fastest"
    notes: "Recommended codec for most workloads: similar ratio to Snappy, typically faster."
{% endtable %}

{:.info}
> **Note**: `zstd` isn't available as a producer-side codec, because it requires Kafka Produce API v7+ negotiation. The consume side can already decompress `zstd` batches written by other producers.

Compression happens at the producer batch level.
{{include.name}} compresses the entire outgoing record batch as a single unit before it's sent.
Compression efficiency improves with batch size, so it's most effective in async mode, where the plugin already accumulates messages before flushing to the broker. 
In sync mode, batches are typically smaller, but compression is still available and can be worthwhile for larger payloads.

If `config.compression_type` is misconfigured or compression fails at runtime, {{include.name}} logs a warning and sends the batch uncompressed rather than dropping it.