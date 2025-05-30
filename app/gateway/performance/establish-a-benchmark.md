---
title: "Establish a {{site.base_gateway}} performance testing benchmark"
content_type: reference
layout: reference

breadcrumbs:
  - /gateway/

products:
    - gateway
    - kic

works_on:
    - on-prem

tags:
    - performance

min_version:
  gateway: '3.4'

description: "Establish a benchmark for your {{site.base_gateway}} instance."

related_resources:
  - text: "Resource sizing guidelines"
    url: /gateway/resource-sizing-guidelines/
  - text: "View official {{site.base_gateway}} benchmarks"
    url: /gateway/performance/benchmarks/
  - text: "Optimize {{site.base_gateway}} performance"
    url: /gateway/performance/optimize/
  - text: "{{site.base_gateway}} performance benchmark test suite"
    url: https://github.com/Kong/kong-gateway-performance-benchmark/tree/main

next_steps:
  - text: Review and implement optimization recommendations
    url: /gateway/performance/optimize/
---

You can establish a baseline for performance by running a benchmark of {{site.base_gateway}}.

After running a benchmark, you can optimize {{site.base_gateway}} performance by reviewing and adjusting {{site.base_gateway}} configuration
based on our [performance recommendations](/gateway/performance/optimize/).

## Prerequisites

You must have {{site.base_gateway}} 3.4.2.0 or later.

Before you conduct a benchmark test, make sure the testbed is configured correctly.
Here are a few general recommendations before you begin the benchmark tests:
* Use fewer nodes of {{site.base_gateway}} with 4 or 8 Nginx workers with corresponding CPU resource 
allocations rather than many smaller {{site.base_gateway}} nodes.
* Run {{site.base_gateway}} in [DB-less](/gateway/topologies/db-less-mode/) or [hybrid mode](/gateway/topologies/hybrid-mode/). 
In these modes, {{site.base_gateway}}’s proxy nodes aren't connected to a database, which can become another 
variable that might affect performance.

You can use [{{site.base_gateway}}'s public test suite](https://github.com/Kong/kong-gateway-performance-benchmark/tree/main) to perform your own benchmarks. 

## Perform a baseline {{site.base_gateway}} performance benchmark

Once you have implemented the recommendations in the [prerequisites](#prerequisites), you can begin the benchmark test: 

1. Configure a Route with a [Request Termination plugin](/plugins/request-termination/) and measure {{site.base_gateway}}'s performance. 
In this case, {{site.base_gateway}} responds to the request and doesn't send any traffic to the upstream server.
1. Run this test a few times to spot unexpected bottlenecks. 
Either {{site.base_gateway}}, the benchmarking client (such as k6 or Apache JMeter), or some other component will likely be an unexpected bottleneck. 
You should not expect higher performance from {{site.base_gateway}} until you solve these bottlenecks. 
Proceed to the next step only after this baseline performance is acceptable to you.
1. Once you have established the baseline, configure a Route to send traffic to the upstream server without any plugins. 
This measures {{site.base_gateway}}'s proxy and your upstream server's performance.
1. Verify that no components are unexpectedly causing a bottleneck before proceeding.
1. Run the benchmark multiple times to gain confidence in the data.
Ensure that the difference between observations isn't high (there's a low standard deviation).
1. Discard the stats collected by the benchmark's first one or two iterations. 
We recommend doing this to ensure that the system is operating at an optimal and stable level.

After these steps are completed, proceed with benchmarking {{site.base_gateway}} with additional configuration.
