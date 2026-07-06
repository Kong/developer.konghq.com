---
title: "How do I adjust resources to increase maximum throughput for {{site.base_gateway}} in Kubernetes?"
content_type: support
description: "When scaling {{site.base_gateway}} in Kubernetes to increase maximum throughput, ensure adequate CPU and memory resources and use performance benchmarking to determine the precise requirements."
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: What resources should be adjusted for {{site.base_gateway}} deployed in a Kubernetes environment to increase maximum throughput?
  a: |
    Throughput is primarily CPU-bound, so increase CPU allocation and run a performance benchmark to determine the right amount.
    Scale vertically (more CPU per pod) or horizontally (more pods) based on the results.
related_resources:
  - text: "{{site.base_gateway}} sizing guidelines"
    url: /gateway/resource-sizing-guidelines/#scaling-dimensions
---

## Problem

To increase the maximum throughput of {{site.base_gateway}} deployed in a Kubernetes environment, you need to determine which resources to adjust.

## Solution

When preparing to scale {{site.base_gateway}} to increase maximum throughput, it's essential to ensure that you have adequate CPU and memory resources.
The maximum throughput {{site.base_gateway}} can handle is highly dependent on these resources.
To accommodate the increased load, it's better to add more compute power, which typically involves increasing the CPU allocation to handle the additional requests.

The exact amount of CPU to increase can vary based on several factors, including the type of requests being processed, network latency, and other use case-specific details.
Therefore, we recommend conducting performance benchmarking and optimization exercises to determine the precise resource requirements.

Here are the steps you should consider:

1. Review the current resource usage (CPU and memory usage, resource limits) and the minimum and maximum number of pods per cluster.
2. Consult the {{site.base_gateway}} sizing guidelines to understand the scaling dimensions.
3. Plan and run a performance test simulating the additional transactions per second (`tps`) to assess if the current resources can handle the increased load.
4. Based on the performance test results, adjust the CPU resources accordingly. This may involve scaling vertically (increasing the CPU resources for existing pods) or horizontally (adding more pods to the cluster).

It's important to note that while you may have enough capacity both vertically and horizontally to support your required throughput increase, the performance test will provide the best indication of whether additional adjustments are needed.

Remember to monitor the performance and resource usage closely after implementing the changes to ensure that {{site.base_gateway}} is operating optimally with the increased traffic.
