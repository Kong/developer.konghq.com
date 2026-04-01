---
title: "{{site.ai_gateway}} resource sizing guidelines"
content_type: reference
layout: reference

products:
    - gateway
    - ai-gateway

works_on:
    - on-prem

min_version:
    gateway: '3.12'

tags:
    - performance
    - deployment-checklist
    - ai

breadcrumbs:
    - /ai-gateway/

description: "Review {{site.ai_gateway}} recommended resource allocation sizing guidelines for {{site.ai_gateway}} based on configuration and traffic patterns."

related_resources:
  - text: Performance benchmarks
    url: /gateway/performance/benchmarks/
  - text: Cluster reference
    url: /gateway/traditional-mode/#about-kong-gateway-clusters
---
The {{site.ai_gateway}} is designed to handle high‑volume inference workloads and forward requests to large language model (LLM) providers with predictable latency. This guide explains performance dimensions, capacity planning methodology, and baseline sizing guidance for AI inference traffic.

## Scaling dimensions

AI inference performance depends on both token streaming latency and sustained token throughput. Unlike traditional API traffic, most latency comes from upstream models, so the gateway must be evaluated on its ability to pass through tokens efficiently.

<!--vale off-->
{% table %}
columns:
  - title: Performance dimension
    key: dimension
  - title: Measured in
    key: measured_in
  - title: "Performance limited by..."
    key: performance
  - title: Description
    key: description
rows:
  - dimension: |
      Latency
    measured_in: |
      Milliseconds
    performance: |
      LLM TTFT and token streaming bound<br>
      Gateway overhead typically low relative to model time
    description: |
      Time to first token (TTFT) and per-token streaming latency (TPOT) dominate end-to-end latency. Gateway overhead typically adds < 10ms.
  - dimension: |
      Throughput
    measured_in: |
      Input/output tokens per second
    performance: |
      CPU-bound<br>
      Scale workers horizontally for higher sustained token throughput
    description: |
      Maximum sustained input and output tokens per second processed across all requests.
{% endtable %}
<!--vale on-->

{:.success}
> Model streams output tokens in server‑sent events (SSE). Processing streamed output is more expensive per token than input, so capacity planning must treat input and output tokens differently.

## Deployment guidance

{{site.ai_gateway}} scales primarily through **horizontal worker expansion**, not vertical tuning. Treat **token throughput** as the core capacity metric, and validate performance against real LLM latency profiles. Synthetic or low-latency backends will overstate capacity.

### Scale horizontally for token throughput

{{site.ai_gateway}} performance is CPU-bound on token processing. Adding workers increases sustained throughput **only when concurrency and streaming behavior scale correctly**.

- Add workers and nodes to increase throughput
- Validate scaling efficiency as concurrency grows
- Benchmark against real model latency and token cadence

### Allocate CPU and memory for LLM workloads

Compute sizing is dictated by **token processing**, not request count. Memory supports configuration and streaming buffers. Persistent storage demand is minimal.

- CPU determines maximum tokens per second
- Memory must support configuration and in-memory stream buffers
- A baseline ratio of 1 vCPU : 2 GB memory is sufficient for typical workloads

### Use dedicated compute instance classes

Consistent CPU performance is critical for LLM token streaming. Burstable or credit-based instances can introduce token delay spikes and unstable throughput.

- Prefer dedicated compute families (for example, AWS `c5`, `c6g`)
- Avoid burstable instances (for example, AWS `t`, GCP `e2`, Azure `B` series)

## Operational best practices

Effective scaling requires testing with realistic model behavior, applying safety margins, and accommodating upstream model differences.

- Benchmark with your model mix and prompt sizes
- Size for token/s, not just RPS
- Apply redundancy factor 2×–4×
- Consider provider differences (OpenAI vs Gemini)
- Test multi‑node scaling before production

## Baseline benchmark results

These baseline throughput numbers reflect typical single-worker token processing under streaming LLM workloads. Use these numbers as general guidance only. Benchmark performance in your own environment and with your specific model mix.

<!-- vale off -->
{% table %}
columns:
  - title: Benchmark dimension
    key: metric
  - title: Result
    key: value
rows:
  - metric: |
      Output tokens/s
    value: |
      OpenAI path: ~1.05M tokens/s
      Gemini path: ~0.78M tokens/s
  - metric: |
      Input tokens/s
    value: |
      ~4.4M tokens/s (similar for both OpenAI and Gemini)
  - metric: |
      Input:output ratio
    value: |
      ~4.2:1 – 5.6:1
{% endtable %}
<!-- vale on -->

{:.success}
> Throughput depends on the provider, the model, and the size and structure of your prompts and responses. Benchmark with your real workload to measure accurate throughput and avoid relying on synthetic or idealized figures.

## Capacity planning formula

```text
equivalent_output_load = I_peak / R + O_peak
required_workers ≈ equivalent_output_load / O_w
```
{:.no-copy-code}

Use redundancy factor 2×–4x- to handle burst, tokenization, and provider variability.

### Quick estimate rule of thumb

- 4:1 input:output ratio
- ~1M output tokens/s per vCPU worker

```
(80M / 4 + 10M) / 1M = 30 workers
→ 60–120 workers w/ redundancy
```
{:.no-copy-code}

## Buffer and memory guidance

Inference requests often include large prompts and streamed output. Buffer sizing determines whether payloads are processed in memory or spill to disk, so tune memory settings based on prompt size and workload profile.

<!-- vale off -->
{% table %}
columns:
  - title: Traffic profile
    key: profile
  - title: Typical prompt size
    key: size
  - title: max_request_body_size
    key: max
  - title: client_body_buffer_size
    key: buf
rows:
  - profile: |
      Chat apps
    size: |
      < 512 KiB
    max: |
      2–4 MiB
    buf: |
      256–512 KiB
  - profile: |
      RAG w/ embeddings
    size: |
      1–4 MiB
    max: |
      8–16 MiB
    buf: |
      1–2 MiB
  - profile: |
      Batch / large JSON
    size: |
      4–16 MiB
    max: |
      16–64 MiB
    buf: |
      2–4 MiB
{% endtable %}
<!-- vale on -->

## Instance recommendations

{{site.ai_gateway}} benefits from high clock speed, dedicated CPU, and non-burstable compute classes. Select instance families optimized for consistent CPU throughput and avoid throttled instance types.

<!-- vale off -->
{% table %}
columns:
  - title: Cloud
    key: cloud
  - title: Architecture
    key: arch
  - title: Instance family
    key: family
  - title: Notes
    key: notes
rows:
  - cloud: |
      AWS
    arch: |
      x86_64
    family: |
      `c5`, `c6i`
    notes: |
      Non-burstable compute optimized
  - cloud: |
      AWS
    arch: |
      ARM
    family: |
      `c6g`, `c7g`
    notes: |
      Graviton cost-efficient scaling
  - cloud: |
      GCP
    arch: |
      x86_64
    family: |
      `c2-standard`, `c3-standard`
    notes: |
      High clock performance
  - cloud: |
      Azure
    arch: |
      x86_64
    family: |
      `Fsv2`, `Dasv5`
    notes: |
      CPU-optimized dedicated compute
{% endtable %}
<!-- vale on -->

## Deployment sizing tiers

Cluster size depends on configured entities and sustained token throughput. Smaller environments serve team-level workloads; larger footprints handle multi-tenant platforms and enterprise AI adoption at scale.

<!-- vale off -->
{% table %}
columns:
  - title: Size
    key: size
  - title: Number of configured entities
    key: entities
  - title: Token throughput guidance (input / output)
    key: throughput
  - title: Recommended vCPUs
    key: vcpus
  - title: Use cases
    key: use_cases
rows:
  - size: |
      Small
    entities: |
      < 100 services/routes
    throughput: |
      < 10M input / < 2M output tokens/s
    vcpus: |
      18 vCPUs
    use_cases: |
      Team workloads, prototypes, low-volume inference
  - size: |
      Medium
    entities: |
      100–500 services/routes
    throughput: |
      10M–60M input / 2M–10M output tokens/s
    vcpus: |
      100 vCPUs
    use_cases: |
      Production traffic for single business unit
  - size: |
      Large
    entities: |
      500–2,000 services/routes
    throughput: |
      60M–200M input / 10M–40M output tokens/s
    vcpus: |
      360 vCPUs
    use_cases: |
      Central platform, multi-team AI adoption
  - size: |
      XL
    entities: |
      > 2,000 services/routes
    throughput: |
      > 200M input / > 40M output tokens/s
    vcpus: |
      360+ vCPUs
    use_cases: |
      Enterprise AI platform, multi-tenant environments
{% endtable %}
<!-- vale on -->