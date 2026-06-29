---
title: "How do I adjust resources to increase maximum throughput for Kong in Kubernetes?"
content_type: support
description: "When scaling Kong in Kubernetes to increase maximum throughput, ensure adequate CPU and memory resources and use performance benchmarking to determine the precise requirements."
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: What resources should be adjusted for Kong deployed in a Kubernetes environment to increase maximum throughput?
  a: |
    Kong's maximum throughput is highly dependent on CPU and memory, so increasing the CPU allocation
    is usually what's needed to handle additional requests. The exact amount varies with request type,
    network latency, and other use case-specific factors, so conduct performance benchmarking to determine
    the precise requirements. Review current resource utilization and pod counts, consult the Kong sizing
    guidelines, run a performance test simulating the additional load, then scale vertically (more CPU per pod)
    or horizontally (more pods) based on the results, and monitor closely afterward.
related_resources:
  - text: Kong Sizing Guidelines
    url: /gateway/resource-sizing-guidelines/#scaling-dimensions
---

## Problem

To increase the maximum throughput of Kong deployed in a Kubernetes environment, you need to determine which resources to adjust.

## Solution

When preparing to scale Kong to increase maximum throughput, it's essential to ensure that you have adequate CPU and memory resources. The maximum throughput Kong can handle is highly dependent on these resources. To accommodate the increased load, it's better to add more compute power, which typically involves increasing the CPU allocation to handle the additional requests.

The exact amount of CPU to increase can vary based on several factors, including the type of requests being processed, network latency, and other use case-specific details. Therefore, we recommend conducting performance benchmarking and optimization exercises to determine the precise resource requirements.

Here are the steps you should consider:

1. Review the current resource usage (CPU and memory usage, resource limits) and the minimum and maximum number of pods per cluster.
2. Consult the Kong sizing guidelines to understand the scaling dimensions.
3. Plan and run a performance test simulating the additional transactions per second (`tps`) to assess if the current resources can handle the increased load.
4. Based on the performance test results, adjust the CPU resources accordingly. This may involve scaling vertically (increasing the CPU resources for existing pods) or horizontally (adding more pods to the cluster).

It's important to note that while you may have enough capacity both vertically and horizontally to support your required throughput increase, the performance test will provide the best indication of whether additional adjustments are needed.

Remember to monitor the performance and resource usage closely after implementing the changes to ensure that Kong is operating optimally with the increased traffic.
