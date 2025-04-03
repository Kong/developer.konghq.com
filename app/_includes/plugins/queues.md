
The {{include.name}} plugin uses internal queues to decouple the production of log entries from their transmission to the upstream log server.

With queuing, request information is put in a configurable queue before being sent in batches to the upstream server. 
This has the following benefits:

* Reduces any possible concurrency on the upstream server
* Helps deal with temporary outages of the upstream server due to network or administrative changes
* Can reduce resource usage both in {{site.base_gateway}} and on the upstream server by collecting multiple entries from the queue in one request

{:.info}
> **Note:** Because queues are structural elements for components in {{site.base_gateway}}, 
they only live in the main memory of each worker process and are not shared between workers.
Therefore, queued content isn’t preserved under abnormal operational situations, 
like power loss or unexpected worker process shutdown due to memory shortage or program errors.

You can use several different configurable parameters for queuing:

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
      [`config.queue.max_entries`](./reference/#schema--config-queue-max-entries)
      <br>
      [`config.queue.max_bytes`](./reference/#schema--config-queue-max-bytes)
      <br>
      [`config.queue.max_batch_size`](./reference/#schema--config-queue-max-batch-size)
    description: |
      Configure sizes for various aspects of the queue: maximum number of entries, batch size, and queue size in bytes.
      <br><br>
      When a queue reaches the maximum number of entries queued and another entry is enqueued, the oldest entry in the queue is deleted to make space for the new entry. 
      The queue code provides warning log entries when it reaches a capacity threshold of 80% and when it starts to delete entries from the queue. 
      It also writes log entries when the situation normalizes.
  - parameter: |
      Timer usage:
      <br><br>
      [`config.queue.concurrency_limit`](./reference/#schema--config-queue-concurrency-limit)
    description: |
      Only one timer is used to start queue processing in the background. You can add more if needed.
      Once the queue is empty, the timer handler terminates and a new timer is created as soon as a new entry is pushed onto the queue.
  - parameter: |
      Retry logic:
      <br><br>
      [`config.queue.initial_retry_delay`](./reference/#schema--config-queue-initial-retry-delay)
      <br>
      [`config.queue.max_coalescing_delay`](./reference/#schema--config-queue-max-entries)
      <br>
      [`config.queue.max_retry_delay`](./reference/#schema--config-queue-coalescing-delay)
      <br>
      [`config.queue.max_retry_time`](./reference/#schema--config-queue-max-retry-time)
    description: |
      If a queue fails to process, the queue library can automatically retry processing it if the failure is temporary 
      (for example, if there are network problems or upstream unavailability). 
      <br><br>
      Before retrying, the library waits for the amount of time specified by the `initial_retry_delay` parameter. 
      This wait time is doubled every time the retry fails, until it reaches the maximum wait time specified by the `max_retry_time` parameter.
{% endtable %}

When a {{site.base_gateway}} shutdown is initiated, the queue is flushed. 
This allows {{site.base_gateway}} to shut down even if it was waiting for new entries to be batched, 
ensuring upstream servers can be contacted.

Queues are not shared between workers and queuing parameters are scoped to one worker. 
For whole-system capacity planning, the number of workers needs to be considered when setting queue parameters.