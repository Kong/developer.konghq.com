---
title: "Size memory for AI payload logging"
content_type: reference
layout: reference

products:
    - gateway

works_on:
    - on-prem
    - konnect

tools:
    - deck

min_version:
    gateway: '3.8'

tags:
    - performance
    - deployment-checklist
    - ai-proxy
    - logging
    - troubleshooting

breadcrumbs:
    - /gateway/

description: "Estimate how much memory the HTTP Log plugin queue uses when the AI Proxy and AI Proxy Advanced plugins log request and response payloads, then set container memory limits, queue limits, alerts, and outage drills that prevent out-of-memory kills."

related_resources:
  - text: "{{site.base_gateway}} resource sizing guidelines"
    url: /gateway/resource-sizing-guidelines/
  - text: "Tune {{site.base_gateway}} for large payloads"
    url: /gateway/performance/large-payloads/
  - text: "Optimize {{site.base_gateway}} performance"
    url: /gateway/performance/optimize/
  - text: "{{site.ai_gateway}} resource sizing guidelines"
    url: /ai-gateway/v1/resource-sizing-guidelines-ai/
  - text: HTTP Log plugin
    url: /plugins/http-log/
  - text: AI Proxy Advanced plugin
    url: /plugins/ai-proxy-advanced/
  - text: "{{site.base_gateway}} logs"
    url: /gateway/logs/
---

Logging full request and response bodies from the [AI Proxy](/plugins/ai-proxy/) and [AI Proxy Advanced](/plugins/ai-proxy-advanced/) plugins turns each log entry from a few kilobytes into hundreds of kilobytes.
The [HTTP Log](/plugins/http-log/) plugin holds those entries in memory until the log server accepts them.
When the log server is unavailable, memory use grows for as long as the outage lasts, and a container that was sized for ordinary API traffic can be killed for running out of memory (OOM) within minutes to hours.

This page explains how that memory grows, how to estimate it from your traffic, how to choose a container memory limit and queue limits, and which logs and metrics warn you before an OOM kill.
The numbers come from Kong replay testing of a data plane with two worker processes and an unavailable log server.
Use them as a starting point and confirm them with an [outage drill](#test-with-an-outage-drill).

## How payload logging uses memory

Each {{site.base_gateway}} worker process keeps its own HTTP Log queue in memory.

{% mermaid %}
flowchart LR
  A[Client request] --> B[AI Proxy or AI Proxy Advanced]
  B --> C[Log entry with request and response bodies]
  C --> D[(HTTP Log queue in worker memory)]
  D -->|One entry per POST| E[Log server]
{% endmermaid %}

Five behaviors determine how much memory the queue uses:

* **Queue scope:** The queue lives only in the memory of each worker process.
  HTTP Log plugin instances that use the same endpoint settings share one queue.
  A worker that stops loses its queued entries.
* **Entry size:** When `logging.log_payloads` is enabled, each entry contains the request and response bodies.
  Entries averaged about 200 KB in Kong testing and reached tens of megabytes for large requests.
  Without payloads, an entry averages about 4 KB.
* **Queue limits:** The default `queue.max_entries` of 10,000 counts entries, not bytes, and `queue.max_bytes` has no default.
  At 200 KB per entry, the default allows about 1.9 GiB in each worker.
* **Slow draining:** While the log server is unavailable, the queue drops one entry per retry window.
  With default settings, that is one entry every 60 to 85 seconds.
  New entries arrive much faster, so the queue grows for the whole outage.
* **Garbage collector headroom:** The LuaJIT garbage collector starts its next cycle when the heap reaches about twice the live data.
  A queue that holds 1 GiB therefore drives the worker heap toward 2 GiB.

After the log server recovers and the queue empties, the resident memory of the worker stays high.
The LuaJIT memory allocator returns memory to the operating system only when a whole allocator block is free, and long-lived small objects keep many blocks partly used.
The worker reuses the freed memory, so it isn't a leak, but the container memory metric counts it, and the next outage starts from the higher level.
In a four-outage test, the memory of the busiest worker with an empty queue rose by about 150 to 250 MiB per outage.

## Estimate peak memory

The peak memory of a pod that logs AI payloads depends on the request rate, the outage duration, the entry size, and the baseline memory of the pod.
Use the following formulas for each pod:

```text
entries = min(R x T, queue.max_entries)
B       = min(entries x S, queue.max_bytes)
peak    = C0 + 2 x B
limit   = 1.2 x peak
```
{:.no-copy-code}

<!--vale off-->
{% table %}
columns:
  - title: Input
    key: input
  - title: Meaning
    key: meaning
  - title: How to find it
    key: find
rows:
  - input: "`R`"
    meaning: "Logged requests per second on the busiest worker, at your busiest hour."
    find: |
      Rate of `kong_ai_llm_requests_total` (requires `ai_metrics`) or the request rate in your access log.
      Clients that reuse long-lived connections can send about 94% of requests to one worker, so assume that one worker receives all of them.
  - input: "`T`"
    meaning: "Longest log server outage the queue must absorb, in seconds."
    find: "Availability history of your log server."
  - input: "`S`"
    meaning: "Mean log entry size."
    find: |
      The request body plus the response body, multiplied by 1.0 to 1.3 for JSON escaping, plus about 4 KB of metadata.
      Measure it from the `Content-Length` of POST requests at the log server, or from the `request.size` and `response.size` fields of a log entry.
  - input: "`C0`"
    meaning: "Peak memory of the pod when the queue is nearly empty."
    find: |
      Measure the peak working set of the pod under your busiest traffic with `log_payloads` disabled.
      Kong testing measured 1,250 MiB for two workers with a full plugin configuration, so use that value if you can't measure.
{% endtable %}
<!--vale on-->

Use the same unit for `S`, `B`, and `C0`.
The factor of 2 comes from the garbage collector behavior described in [How payload logging uses memory](#how-payload-logging-uses-memory).
The factor of 1.2 leaves a margin for request buffers and measurement error.
If several workers can fill their own queues, add the `B` of each worker.

The following table applies the formulas with `C0` set to 1,250 MiB, an outage of 60 minutes, and the default `queue.max_entries`:

<!--vale off-->
{% table %}
columns:
  - title: Mean entry size
    key: size
  - title: Logged requests per second
    key: rate
  - title: Backlog after 60 minutes
    key: backlog
  - title: Estimated peak with default queue limits
    key: default
  - title: Estimated peak with `max_bytes` of 256 MiB
    key: capped
  - title: Minutes until the default queue reaches 4 GiB
    key: minutes
rows:
  - size: 70 KiB
    rate: "0.4"
    backlog: "1,440 entries, 98 MiB"
    default: "1.4 GiB"
    capped: "1.4 GiB"
    minutes: "Not reached"
  - size: 70 KiB
    rate: "2"
    backlog: "7,200 entries, 492 MiB"
    default: "2.2 GiB"
    capped: "1.7 GiB"
    minutes: "Not reached"
  - size: 70 KiB
    rate: "10"
    backlog: "10,000 entries (limit), 684 MiB"
    default: "2.6 GiB"
    capped: "1.7 GiB"
    minutes: "Not reached"
  - size: 200 KiB
    rate: "0.4"
    backlog: "1,440 entries, 281 MiB"
    default: "1.8 GiB"
    capped: "1.7 GiB"
    minutes: "304"
  - size: 200 KiB
    rate: "2"
    backlog: "7,200 entries, 1.4 GiB"
    default: "4.0 GiB"
    capped: "1.7 GiB"
    minutes: "61"
  - size: 200 KiB
    rate: "10"
    backlog: "10,000 entries (limit), 1.9 GiB"
    default: "5.0 GiB"
    capped: "1.7 GiB"
    minutes: "12"
  - size: 1 MiB
    rate: "0.4"
    backlog: "1,440 entries, 1.4 GiB"
    default: "4.0 GiB"
    capped: "1.7 GiB"
    minutes: "59"
  - size: 1 MiB
    rate: "2"
    backlog: "7,200 entries, 7.0 GiB"
    default: "15.3 GiB"
    capped: "1.7 GiB"
    minutes: "12"
  - size: 1 MiB
    rate: "10"
    backlog: "10,000 entries (limit), 9.8 GiB"
    default: "20.8 GiB"
    capped: "1.7 GiB"
    minutes: "2"
{% endtable %}
<!--vale on-->

Without payload logging, an entry averages about 4 KB, the default queue never holds more than about 40 MiB, and the estimated peak stays near 1.3 GiB at any request rate.

{:.info}
> In Kong testing across 15 configurations, the estimate ranged from 8% below to 33% above the measured peak memory of the pod.
> Testing covered entries below 128 KiB less thoroughly than entries near 200 KB, so measure your own pod with an outage drill before you rely on the estimate.

## Size the container and bound the queue

### Recommended memory limits

We recommend setting `queue.max_bytes` on every HTTP Log plugin that records AI payloads, because `queue.max_entries` doesn't bound memory when entries are large.
Set the container memory limit from the queue bound, not from average traffic.

<!--vale off-->
{% table %}
columns:
  - title: Profile
    key: profile
  - title: Queue bound per worker
    key: bound
  - title: Estimated peak
    key: peak
  - title: Recommended memory limit
    key: limit
rows:
  - profile: "Payload logging disabled"
    bound: "About 40 MiB at the default 10,000 entries"
    peak: "1.3 GiB"
    limit: "2 GiB"
  - profile: "Payload logging enabled, `max_bytes` of 256 MiB"
    bound: "256 MiB"
    peak: "1.7 GiB"
    limit: "2.5 GiB"
  - profile: "Payload logging enabled, `max_bytes` of 512 MiB"
    bound: "512 MiB"
    peak: "2.2 GiB"
    limit: "3 GiB"
  - profile: "Payload logging enabled, `max_bytes` of 1 GiB"
    bound: "1 GiB"
    peak: "3.2 GiB"
    limit: "4 GiB"
  - profile: "Payload logging enabled, default queue limits, 200 KB entries"
    bound: "About 1.9 GiB"
    peak: "5.0 GiB"
    limit: "6 GiB"
{% endtable %}
<!--vale on-->

To choose `queue.max_bytes` for a limit you already have, use the following formula:

```text
max_bytes = (limit / 1.2 - C0) / 2
```
{:.no-copy-code}

<!--vale off-->
{% table %}
columns:
  - title: Memory limit
    key: limit
  - title: "Maximum `max_bytes` with `C0` of 1,250 MiB"
    key: small
  - title: "Maximum `max_bytes` with `C0` of 1,600 MiB"
    key: large
rows:
  - limit: "2 GiB"
    small: "228 MiB"
    large: "53 MiB"
  - limit: "3 GiB"
    small: "655 MiB"
    large: "480 MiB"
  - limit: "4 GiB"
    small: "1,082 MiB"
    large: "907 MiB"
{% endtable %}
<!--vale on-->

{:.warning}
> The queue rejects any single entry that is larger than `queue.max_bytes`.
> With a 2 GiB limit and a larger baseline, the formula allows only 53 MiB, which is smaller than one large entry. In that case, raise the memory limit or disable payload logging.

We recommend setting the memory request equal to the limit, because Kubernetes evicts the pods that use more memory than they request first when a node runs low on memory.
Equal values protect against eviction but don't prevent an OOM kill when the pod reaches its limit.

```yaml
resources:
  requests:
    memory: 2560Mi
  limits:
    memory: 2560Mi
```

### Queue and logging settings

The following settings bound the memory that payload logging uses.
Measured effects come from replay testing of repeated outages with entries that averaged about 200 KB.

<!--vale off-->
{% table %}
columns:
  - title: Setting
    key: setting
  - title: Default
    key: default
  - title: Effect on memory
    key: effect
  - title: Trade-off
    key: tradeoff
rows:
  - setting: |
      `config.logging.log_payloads` in AI Proxy, or `config.targets[].logging.log_payloads` in AI Proxy Advanced
    default: "`false`"
    effect: "Disabling payload logging reduced peak worker memory by 82% in a single-outage test."
    tradeoff: "Prompts and responses no longer appear in logs."
  - setting: "[`config.queue.max_bytes`](/plugins/http-log/reference/#schema--config-queue-max-bytes) in HTTP Log"
    default: "No limit"
    effect: |
      A limit of 256 MiB reduced peak worker memory by 52% and pod peak memory by 38%.
      The limit applies to each worker, counts only string entries, and doesn't count the batch that is being sent.
    tradeoff: |
      During an outage, the queue drops the oldest entries when the limit is reached.
      In the same test, about 62% of entries were dropped.
      An entry larger than the limit is rejected.
  - setting: "[`config.queue.max_entries`](/plugins/http-log/reference/#schema--config-queue-max-entries) in HTTP Log"
    default: "10,000"
    effect: "A limit of 1,000 reduced peak worker memory by 60%."
    tradeoff: |
      About 68% of entries were dropped in the same test.
      The limit doesn't track bytes, so we recommend `max_bytes` instead.
  - setting: "[`config.queue.max_retry_time`](/plugins/http-log/reference/#schema--config-queue-max-retry-time) in HTTP Log"
    default: "60 seconds"
    effect: "The queue drops one entry per retry window, so lowering the value shortens the window but doesn't bound the backlog."
    tradeoff: "A lower value discards every entry that can't be sent in time. We don't recommend it as a memory control."
  - setting: "`config.max_request_body_size` in AI Proxy and AI Proxy Advanced"
    default: "1,048,576 bytes (1 MiB)"
    effect: |
      Lowering the limit from 50 MiB to 5 MiB reduced peak worker memory by 3%.
      The setting bounds the largest request entries, but not the average entry or response bodies.
      A value of `0` removes the plugin limit.
    tradeoff: "The plugin can't process requests with larger bodies, and about 0.1% of requests returned errors in the same test."
  - setting: "[`nginx_worker_processes`](/gateway/configuration/#nginx-worker-processes)"
    default: "`auto`"
    effect: "Each worker has its own queue and its own retained baseline. One worker instead of two reduced peak pod memory by 13% in a two-worker pod."
    tradeoff: "A single worker can't isolate a failure from other traffic."
{% endtable %}
<!--vale on-->

The following example sets a byte limit on the HTTP Log queue:

{% entity_examples %}
entities:
  plugins:
    - name: http-log
      config:
        http_endpoint: http://LOG_SERVER_HOST:PORT/logs
        queue:
          max_bytes: 268435456
          max_entries: 10000
{% endentity_examples %}

Set the number of worker processes with any of the following methods:

{% navtabs "worker-processes" %}
{% navtab "kong.conf" %}

```bash
nginx_worker_processes=1
```
{% endnavtab %}
{% navtab "Environment variable" %}

```bash
KONG_NGINX_WORKER_PROCESSES=1
```
{% endnavtab %}
{% navtab "Helm chart" %}

```yaml
env:
  nginx_worker_processes: "1"
```
{% endnavtab %}
{% endnavtabs %}

## Monitor memory and queue health

{{site.base_gateway}} doesn't expose the HTTP Log queue depth or queue size as a metric.
Combine the error log, memory metrics, and data from the log server to see the queue grow before an OOM kill.

### Queue log messages

The queue writes the following messages to the error log, one set for each worker:

<!--vale off-->
{% table %}
columns:
  - title: Message
    key: message
  - title: Level
    key: level
  - title: Meaning
    key: meaning
rows:
  - message: "`handler could not process entries`"
    level: Warning
    meaning: "A send attempt failed. This message is the earliest signal of a log server problem and repeats with each retry."
  - message: "`could not send entries due to max_retry_time exceeded. N queue entries were lost`"
    level: Error
    meaning: "The queue dropped an entry after the retry time. During an outage, this message appears about once every 60 to 85 seconds for each worker."
  - message: "`queue at 80% capacity`"
    level: Warning
    meaning: "The queue holds 80% of `max_entries`. With the default of 10,000 entries of 200 KB, that is about 1.5 GiB in one worker, so don't depend on this message as an early warning."
  - message: "`queue full, dropping old entries until processing is successful again`"
    level: Error
    meaning: "The queue reached `max_entries`. The message repeats for every new entry."
  - message: "`byte capacity exceeded, N queue entries were dropped`"
    level: Error
    meaning: "The queue reached `max_bytes`."
  - message: "`string to be queued is longer (N bytes) than the queue's max_bytes (N bytes)`"
    level: Error
    meaning: "A single entry is larger than `max_bytes` and the queue rejected it."
  - message: "`queue resumed processing`"
    level: Info
    meaning: "The queue sent entries again after a drop. The default `log_level` of `notice` hides this message."
{% endtable %}
<!--vale on-->

### Memory and size metrics

The following signals show memory use and entry size:

<!--vale off-->
{% table %}
columns:
  - title: Signal
    key: signal
  - title: What it measures
    key: measures
  - title: Limits
    key: limits
rows:
  - signal: "`memory.workers_lua_vms[].http_allocated_gc` from the `/status` endpoint (add `?unit=b` for bytes)"
    measures: "Lua heap of each worker, including garbage that the collector hasn't freed."
    limits: |
      Doesn't include memory that the allocator retains or memory outside the Lua heap.
      On a data plane, each worker updates the value at most every 10 seconds while it processes requests.
  - signal: "`kong_memory_workers_lua_vms_bytes` from the [Prometheus plugin](/plugins/prometheus/)"
    measures: "The same Lua heap value, labeled with the worker `pid`."
    limits: "Scrape the Status API `/metrics` endpoint. Has the same limits as `http_allocated_gc`."
  - signal: "`kong.memory.workers.lua_vm` from [OpenTelemetry metrics](/gateway/otel-metrics/)"
    measures: "The same Lua heap value."
    limits: "Requires a configured metrics endpoint."
  - signal: "`kong_ai_llm_requests_total` and `kong_bandwidth_bytes`"
    measures: "AI request rate, and bytes received and sent."
    limits: |
      Enable `ai_metrics` and `bandwidth_metrics` on the Prometheus plugin.
      Divide the rate of `kong_bandwidth_bytes` by the request rate to estimate `S`.
  - signal: "`request.size` and `response.size` in each log entry"
    measures: "The values of the nginx `$request_length` and `$bytes_sent` variables."
    limits: "Wire sizes of the request and response. They approximate, but aren't equal to, the size of the log entry."
  - signal: "`Content-Length` of POST requests at the log server"
    measures: "The exact entry size when `queue.max_batch_size` is 1."
    limits: "Available only on the log server side."
  - signal: "`container_memory_working_set_bytes`, `container_memory_rss`, and `container_oom_events_total`"
    measures: "Memory of the container, including memory that the allocator retains."
    limits: "Provided by your Kubernetes monitoring, not by {{site.base_gateway}}."
  - signal: "`RssAnon` and `VmHWM` in `/proc/PID/status`"
    measures: "Resident memory and its peak for each worker."
    limits: "Requires access to the node or container. Use these values to compare with the Lua heap."
{% endtable %}
<!--vale on-->

{{site.base_gateway}} doesn't report the resident memory of each worker, the number of entries in a queue, or the bytes in a queue.
The difference between the resident memory of a worker and its Lua heap shows memory that the allocator retains and memory outside the Lua heap.

### Alerts

We recommend the following alerts, in this order, because the first ones react earliest:

* **Log server errors:** Alert when the error log shows `handler could not process entries` for more than two minutes.
  A log server problem is the usual cause of a queue backlog.
* **Dropped entries:** Alert on any `could not send entries due to max_retry_time exceeded` message.
  The message means that a backlog has been growing for at least one retry window.
* **Lua heap growth:** Alert when the projected heap reaches half of the container memory limit within an hour:

  ```text
  max by (pod) (predict_linear(kong_memory_workers_lua_vms_bytes[15m], 3600)) > 0.5 * LIMIT_BYTES
  ```
  {:.no-copy-code}

* **Container memory:** Alert when the working set exceeds 80% of the limit:

  ```text
  container_memory_working_set_bytes{container="proxy"} / on (pod) kube_pod_container_resource_limits{resource="memory", container="proxy"} > 0.8
  ```
  {:.no-copy-code}

* **OOM kills:** Alert on `increase(container_oom_events_total[10m]) > 0` and on the error log message `worker process PID exited on signal 9`.

{:.warning}
> To inspect what fills a worker heap during an incident, run `kong debug profiling gc-snapshot --pid WORKER_PID`.
> The command forces a full garbage collection and blocks that worker until it finishes.
> The snapshot file can contain request and response text, so handle it as sensitive data.
> See the [CLI reference](/gateway/cli/reference/) for details.

## Test with an outage drill

An outage drill measures the memory behavior of your configuration under a log server failure.
Run it before production and again after every change to payload logging, queue limits, or traffic.

1. Use the production plugin configuration and a load that matches your busiest hour, with realistic request and response sizes.
1. Make the log server unavailable. Repeat the drill with each failure mode that can occur in your environment:
   * **Fast failure:** The log server port is closed, so connections fail immediately.
   * **Timeout:** Packets to the log server are dropped, so each send attempt waits for the plugin `timeout`.
   * **Slow success:** The log server answers every request with a delay, so there are no retries and no log messages.
1. Keep the failure going for `T`, the longest outage you need to absorb.
1. Record the Lua heap and the resident memory of each worker, the peak working set of the container, and the queue messages in the error log.
1. Restore the log server, wait until the queue drains, and record the resident memory of each worker again.
1. Compare the measurements with the estimate. Repeat the drill several times to see how much memory the allocator retains between outages.

Compare the highest working set from the drill with your planned memory limit.

## Troubleshoot memory problems

### Identify how the process ended

An OOM event shows up in different places depending on what the kernel or kubelet ended:

<!--vale off-->
{% table %}
columns:
  - title: Event
    key: event
  - title: What you see
    key: see
  - title: Effect on the queue
    key: effect
rows:
  - event: "Container killed"
    see: "The container state shows `Terminated` with reason `OOMKilled` and exit code 137, and the restart count increases."
    effect: "All workers lose their queued entries."
  - event: "Worker killed"
    see: |
      The error log shows `worker process PID exited on signal 9`, and {{site.base_gateway}} starts a replacement worker. The container keeps running.
      Signal 9 alone doesn't prove an OOM kill. Check the `oom_kill` counter in the `memory.events` file of the container or the kernel log.
    effect: "The killed worker loses its queued entries and its requests in progress."
  - event: "Pod evicted"
    see: "The pod status shows `Evicted` and the message `The node was low on resource: memory`."
    effect: "The kubelet sends SIGTERM first. Workers try to send queued entries before they exit."
{% endtable %}
<!--vale on-->

For more information about killed workers, see [Kong worker processes exited on signal 9](/support/kong-worker-processes-exited-on-signal-9/).

### Memory stays high after the log server recovers

A worker with an empty queue can hold more than 1 GiB of resident memory after an outage.
The worker reuses this memory for new objects, so it doesn't grow without bound, but the container metric keeps counting it.

To release the memory, replace the workers with a reload or a rolling restart.
Entries that are still in the queue are lost, so replace workers only after the log server is healthy and the queue is empty.
Include the retained memory in `C0` by measuring it during an outage drill.

### The queue grows without log messages

A log server that returns success slowly doesn't trigger retries, so the queue produces no error log messages while it grows.
Compare the number of requests that {{site.base_gateway}} logs with the number of entries that the log server receives, and alert on log server latency.

## Operational recommendations

**Action:** Decide for each route whether payload logging is necessary, and disable `log_payloads` on high-volume routes.

**Explanation:** Disabling payload logging reduced peak worker memory by 82% in testing, and it removes the largest source of memory growth.

**Action:** Set `queue.max_bytes` on every HTTP Log plugin that can carry payloads.

**Explanation:** The default limit counts entries, not bytes, so a few large entries can use more memory than thousands of small ones.

**Action:** Set the memory limit from the [formulas](#estimate-peak-memory) and keep the memory request equal to the limit.

**Explanation:** The limit must cover the queue bound plus the baseline of the pod, and the retained memory of an earlier outage counts toward it.

**Action:** Set `nginx_worker_processes` explicitly, and match the CPU request of the container to the number of workers.

**Explanation:** Each worker holds its own baseline and its own queue, and each additional worker uses additional memory. See the [optimization guidance](/gateway/performance/optimize/) for how to choose the worker count.

**Action:** Send logs to a node-local log forwarder that buffers to disk, and forward from there to the central log server.

**Explanation:** The forwarder takes over buffering during outages of the central log server, so the memory of {{site.base_gateway}} no longer grows with the outage duration.

**Action:** Alert on log server availability and latency, and run an outage drill after every change.

**Explanation:** A log server problem is the usual trigger of a queue backlog, and the drill shows whether the memory limit still covers it.
