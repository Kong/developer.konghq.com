<!---shared with AI Gateway Policies that support queuing: http-log, file-log, datadog, opentelemetry, statsd, statsd-advanced, zipkin, metering-and-billing --->

The {{include.name}} Policy uses internal queues to decouple the production of log entries from their transmission to the upstream server.

With queuing, entries are placed in a configurable queue before being sent in batches to the upstream server. This has the following benefits:

* Reduces concurrency on the upstream server
* Helps deal with temporary outages of the upstream server due to network or administrative changes
* Can reduce resource usage both in {{site.ai_gateway}} and on the upstream server by collecting multiple entries from the queue in one request

{:.info}
> **Note:** Because queues are structural elements for components in {{site.ai_gateway}}, they only live in the main memory of each worker process and aren't shared between workers.
Therefore, queued content isn't preserved under abnormal operational situations, like power loss or unexpected worker process shutdown due to memory shortage or program errors.

You can configure several parameters for queuing:

{% table %}
columns:
  - title: Parameters
    key: parameter
  - title: Description
    key: description
rows:
  - parameter: |
      Queue capacity limits:
      <br><br>
      [`config.queue.max_entries`](/ai-gateway/policies/{{include.slug}}/reference/#schema--config-queue-max-entries)
      <br>
      [`config.queue.max_bytes`](/ai-gateway/policies/{{include.slug}}/reference/#schema--config-queue-max-bytes)
      <br>
      [`config.queue.max_batch_size`](/ai-gateway/policies/{{include.slug}}/reference/#schema--config-queue-max-batch-size)
    description: |
      Configure sizes for various aspects of the queue: maximum number of entries, batch size, and queue size in bytes.
      <br><br>
      When a queue reaches the maximum number of entries and another entry is enqueued, the oldest entry in the queue is deleted to make space for the new entry.
      The queue code logs a warning when it reaches a capacity threshold of 80% and when it starts to delete entries from the queue, and logs again when the situation normalizes.
  - parameter: |
      Timer usage:
      <br><br>
      [`config.queue.concurrency_limit`](/ai-gateway/policies/{{include.slug}}/reference/#schema--config-queue-concurrency-limit)
    description: |
      Only one timer is used to start queue processing in the background by default. Once the queue is empty, the timer handler terminates, and a new timer is created as soon as a new entry is pushed onto the queue.
  - parameter: |
      Retry logic:
      <br><br>
      [`config.queue.initial_retry_delay`](/ai-gateway/policies/{{include.slug}}/reference/#schema--config-queue-initial-retry-delay)
      <br>
      [`config.queue.max_coalescing_delay`](/ai-gateway/policies/{{include.slug}}/reference/#schema--config-queue-max-coalescing-delay)
      <br>
      [`config.queue.max_retry_delay`](/ai-gateway/policies/{{include.slug}}/reference/#schema--config-queue-max-retry-delay)
      <br>
      [`config.queue.max_retry_time`](/ai-gateway/policies/{{include.slug}}/reference/#schema--config-queue-max-retry-time)
    description: |
      If a queue fails to process, it can automatically retry if the failure is temporary, for example due to network problems or upstream unavailability.
{% endtable %}
