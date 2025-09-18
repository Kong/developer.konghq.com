---
title: "{{site.base_gateway}} performance testing benchmarks"
content_type: reference
layout: reference

breadcrumbs:
  - /gateway/

products:
    - gateway

works_on:
    - on-prem

tags:
    - performance

min_version:
  gateway: '3.6'

description: "View Kong's benchmark for the current {{site.base_gateway}} version and learn about {{site.base_gateway}} performance testing using Kong's test suite."

related_resources:
  - text: "Resource sizing guidelines"
    url: /gateway/resource-sizing-guidelines/
  - text: "Establish a {{site.base_gateway}} performance benchmark"
    url: /gateway/performance/establish-a-benchmark/
  - text: "Optimize {{site.base_gateway}} performance"
    url: /gateway/performance/optimize/

next_steps:
  - text: Establish your own {{site.base_gateway}} performance benchmark
    url: /gateway/performance/establish-a-benchmark/
---

As of {{site.base_gateway}} 3.6.x, Kong publishes performance results on {{site.base_gateway}}, along with the test methodology and details. 
Kong plans to conduct and publish {{site.base_gateway}} performance results for each subsequent minor release.

In addition to viewing our performance test results, you can use [our public test suite](https://github.com/Kong/kong-gateway-performance-benchmark/tree/main) to conduct your own performance tests with {{site.base_gateway}}.

## {{site.base_gateway}} performance testing method and results

Kong tests performance results for {{site.base_gateway}} using [our public test suite](https://github.com/Kong/kong-gateway-performance-benchmark/tree/main).

The following sections explain the test methodology, results, and configuration.  

### Test method

The performance tests cover a number of baseline configurations and common use cases for {{site.base_gateway}}. The following describes the test cases used and the configuration methodology: 

* **Environment**: Kubernetes environment on AWS infrastructure.
* **Test use cases**: 
    * Basic {{site.base_gateway}} proxy.
    * [Rate limiting](/plugins/rate-limiting/) a request with no authentication.
    * Authentication using the [Basic Auth plugin](/plugins/basic-auth/) and rate limiting.
    * Authentication using the [Key Auth plugin](/plugins/key-auth/) and rate limiting.
* **Routes and Consumers**: Each case was tested with two different options: one with one Route and one Consumer, and one with 100 Routes and 100 Consumers, for a total of eight test cases. For test cases that didn't require authentication, no Consumers were used.
* **Traffic distribution**: Normal distribution across both Routes and Consumers.
* **Protocol**: HTTPS only.
* **Sample size**: Each test case was run five times, each for a duration of 15 minutes. The results are an average of the five different test runs.

### {{site.base_gateway}} performance benchmark results

The following table lists all Gateway versions that have been tested using Kong's benchmark test suite. 

{:.info}
> **Note:** This table is not a guarantee of current support.
> To see which {{site.base_gateway}} versions are currently supported by Kong, see the [{{site.base_gateway}} version support policy](/gateway/version-support-policy/).

{% navtabs "gateway-version" %}

{% navtab "3.11" %}

{% table %}
columns:
  - title: Test case
    key: test
  - title: Number of Routes and Consumers
    key: entities
  - title: Requests per second (RPS)
    key: rps
  - title: P99 (ms)
    key: p99
  - title: P95 (ms)
    key: p95
rows:
  - test: Kong proxy with no plugins
    entities: 1 Route, 0 Consumers
    rps: 130118.8
    p99: 6.28
    p95: 3.60
  - test: Kong proxy with no plugins
    entities: 100 Routes, 0 Consumers
    rps: 124676.0
    p99: 6.52
    p95: 3.75
  - test: Rate limit and no auth
    entities: 1 Route, 0 Consumers
    rps: 111582.8
    p99: 8.14
    p95: 3.98
  - test: Rate limit and no auth
    entities: 100 Routes, 0 Consumers
    rps: 107716.3
    p99: 8.23
    p95: 4.07
  - test: Rate limit and key auth
    entities: 1 Route, 1 Consumer
    rps: 96673.3
    p99: 9.23
    p95: 4.66
  - test: Rate limit and key auth
    entities: 100 Routes, 100 Consumers
    rps: 91456.3
    p99: 9.75
    p95: 5.06
  - test: Rate limit and basic auth
    entities: 1 Route, 1 Consumer
    rps: 91412.9
    p99: 9.86
    p95: 5.31
  - test: Rate limit and basic auth
    entities: 100 Routes, 100 Consumers
    rps: 86402.1
    p99: 10.25
    p95: 5.55
{% endtable %}

{% endnavtab %}

{% navtab "3.10" %}

{% table %}
columns:
  - title: Test case
    key: test
  - title: Number of Routes and Consumers
    key: entities
  - title: Requests per second (RPS)
    key: rps
  - title: P99 (ms)
    key: p99
  - title: P95 (ms)
    key: p95
rows:
  - test: Kong proxy with no plugins
    entities: 1 Route, 0 Consumers
    rps: 127257.3
    p99: 7.11
    p95: 4.07
  - test: Kong proxy with no plugins
    entities: 100 Routes, 0 Consumers
    rps: 124402.3
    p99: 7.39
    p95: 4.15
  - test: Rate limit and no auth
    entities: 1 Route, 0 Consumers
    rps: 112025.7
    p99: 8.38
    p95: 3.89
  - test: Rate limit and no auth
    entities: 100 Routes, 0 Consumers
    rps: 108439.2
    p99: 8.74
    p95: 4.10
  - test: Rate limit and key auth
    entities: 1 Route, 1 Consumer
    rps: 97208.2
    p99: 9.10
    p95: 4.81
  - test: Rate limit and key auth
    entities: 100 Routes, 100 Consumers
    rps: 91859.1
    p99: 9.61
    p95: 5.11
  - test: Rate limit and basic auth
    entities: 1 Route, 1 Consumer
    rps: 92862.9
    p99: 9.64
    p95: 5.05
  - test: Rate limit and basic auth
    entities: 100 Routes, 100 Consumers
    rps: 87535.4
    p99: 10.15
    p95: 5.54
{% endtable %}

{% endnavtab %}

{% navtab "3.9" %}

{% table %}
columns:
  - title: Test case
    key: test
  - title: Number of Routes and Consumers
    key: entities
  - title: Requests per second (RPS)
    key: rps
  - title: P99 (ms)
    key: p99
  - title: P95 (ms)
    key: p95
rows:
  - test: Kong proxy with no plugins
    entities: 1 Route, 0 Consumers
    rps: 134940.8
    p99: 6.79
    p95: 3.70
  - test: Kong proxy with no plugins
    entities: 100 Routes, 0 Consumers
    rps: 130779.5
    p99: 7.08
    p95: 3.79
  - test: Rate limit and no auth
    entities: 1 Route, 0 Consumers
    rps: 115281.4
    p99: 8.38
    p95: 3.87
  - test: Rate limit and no auth
    entities: 100 Routes, 0 Consumers
    rps: 111324.6
    p99: 8.57
    p95: 3.83
  - test: Rate limit and key auth
    entities: 1 Route, 1 Consumer
    rps: 101822.8
    p99: 9.09
    p95: 4.46
  - test: Rate limit and key auth
    entities: 100 Routes, 100 Consumers
    rps: 96237.6
    p99: 10.27
    p95: 4.69
  - test: Rate limit and basic auth
    entities: 1 Route, 1 Consumer
    rps: 94680.2
    p99: 9.58
    p95: 5.04
  - test: Rate limit and basic auth
    entities: 100 Routes, 100 Consumers
    rps: 89378.4
    p99: 10.20
    p95: 5.37
{% endtable %}

{% endnavtab %}

{% navtab "3.8" %}

{% table %}
columns:
  - title: Test case
    key: test
  - title: Number of Routes and Consumers
    key: entities
  - title: Requests per second (RPS)
    key: rps
  - title: P99 (ms)
    key: p99
  - title: P95 (ms)
    key: p95
rows:
  - test: Kong proxy with no plugins
    entities: 1 Route, 0 Consumers
    rps: 142443.4
    p99: 6.24
    p95: 3.55
  - test: Kong proxy with no plugins
    entities: 100 Routes, 0 Consumers
    rps: 137561.7
    p99: 6.36
    p95: 3.58
  - test: Rate limit and no auth
    entities: 1 Route, 0 Consumers
    rps: 120897.4
    p99: 8.08
    p95: 3.60
  - test: Rate limit and no auth
    entities: 100 Routes, 0 Consumers
    rps: 116867.2
    p99: 8.51
    p95: 3.78
  - test: Rate limit and key auth
    entities: 1 Route, 1 Consumer
    rps: 105657.4
    p99: 8.62
    p95: 4.38
  - test: Rate limit and key auth
    entities: 100 Routes, 100 Consumers
    rps: 100047.6
    p99: 9.12
    p95: 4.45
  - test: Rate limit and basic auth
    entities: 1 Route, 1 Consumer
    rps: 98031.6
    p99: 10.47
    p95: 5.02
  - test: Rate limit and basic auth
    entities: 100 Routes, 100 Consumers
    rps: 92548.2
    p99: 9.80
    p95: 5.25
{% endtable %}

{% endnavtab %}

{% navtab "3.7" %}

{% table %}
columns:
  - title: Test case
    key: test
  - title: Number of Routes and Consumers
    key: entities
  - title: Requests per second (RPS)
    key: rps
  - title: P99 (ms)
    key: p99
  - title: P95 (ms)
    key: p95
rows:
  - test: Kong proxy with no plugins
    entities: 1 Route, 0 Consumers
    rps: 137358.8
    p99: 7.25
    p95: 4.06
  - test: Kong proxy with no plugins
    entities: 100 Routes, 0 Consumers
    rps: 133953.4
    p99: 7.20
    p95: 4.17
  - test: Rate limit and no auth
    entities: 1 Route, 0 Consumers
    rps: 121737.2
    p99: 7.69
    p95: 4.01
  - test: Rate limit and no auth
    entities: 100 Routes, 0 Consumers
    rps: 117521.4
    p99: 8.53
    p95: 4.22
  - test: Rate limit and key auth
    entities: 1 Route, 1 Consumer
    rps: 103777.6
    p99: 9.43
    p95: 4.39
  - test: Rate limit and key auth
    entities: 100 Routes, 100 Consumers
    rps: 98777.5
    p99: 9.16
    p95: 4.79
  - test: Rate limit and basic auth
    entities: 1 Route, 1 Consumer
    rps: 97397.6
    p99: 9.69
    p95: 4.93
  - test: Rate limit and basic auth
    entities: 100 Routes, 100 Consumers
    rps: 92372.6
    p99: 10.17
    p95: 5.31
{% endtable %}

{% endnavtab %}

{% navtab "3.6" %}

{% table %}
columns:
  - title: Test case
    key: test
  - title: Number of Routes and Consumers
    key: entities
  - title: Requests per second (RPS)
    key: rps
  - title: P99 (ms)
    key: p99
  - title: P95 (ms)
    key: p95
rows:
  - test: Kong proxy with no plugins
    entities: 1 Route, 0 Consumers
    rps: 137850.4
    p99: 6.25
    p95: 3.82
  - test: Kong proxy with no plugins
    entities: 100 Routes, 0 Consumers
    rps: 132302.8
    p99: 6.55
    p95: 3.99
  - test: Rate limit and no auth
    entities: 1 Route, 0 Consumers
    rps: 116413.8
    p99: 7.59
    p95: 4.56
  - test: Rate limit and no auth
    entities: 100 Routes, 0 Consumers
    rps: 111615.8
    p99: 7.62
    p95: 4.54
  - test: Rate limit and key auth
    entities: 1 Route, 1 Consumer
    rps: 102261.6
    p99: 8.47
    p95: 5.05
  - test: Rate limit and key auth
    entities: 100 Routes, 100 Consumers
    rps: 96289.6
    p99: 8.82
    p95: 5.25
  - test: Rate limit and basic auth
    entities: 1 Route, 1 Consumer
    rps: 95297.8
    p99: 8.75
    p95: 5.66
  - test: Rate limit and basic auth
    entities: 100 Routes, 100 Consumers
    rps: 89777.4
    p99: 9.34
    p95: 5.89
{% endtable %}

{% endnavtab %}
{% endnavtabs %}


### Test environment

Kong ran these tests in AWS using EC2 machines. We used [Kubernetes taints](https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/) to ensure that {{site.base_gateway}} is on its own node while the load testing and observability tools are on their own separate nodes in the same cluster.

{{site.base_gateway}} ran on a single dedicated instance of c5.4xlarge, and the two nodes for the observability stack and K6 ran on dedicated c5.metal instances. We used the metal instances for the observability load generation toolchain to ensure they aren't resource-constrained in any way. Since [K6 is very resource-demanding](https://k6.io/docs/testing-guides/running-large-tests/#hardware-considerations) when generating a high amount of traffic during tests, we observed that using smaller or less powerful instances for the toolchain caused the observability load generation tools to be a bottleneck for {{site.base_gateway}} performance.

### Test configuration

For these tests, we changed the number of worker processes to match the number of available cores to the node running {{site.base_gateway}}, which was 16 vCPU. Accordingly, we set the number of processes to 16. This follows [Kong’s overall performance guidance](/gateway/resource-sizing-guidelines/). Outside of this change, no other tuning was made.

## Conduct your own performance test using Kong's test suite

You can use [Kong's public test suite repo](https://github.com/Kong/kong-gateway-performance-benchmark/tree/main) to help you spin up an EKS cluster with {{site.base_gateway}}, Redis, Prometheus, and Grafana installed. Additionally, it will configure [K6](https://k6.io/), a popular open source load testing tool. You can use this test suite to conduct your own performance tests.

Once the cluster is generated, you can apply the [provided YAML](https://github.com/Kong/kong-gateway-performance-benchmark/tree/main/deploy-k8s-resources/kong_helm) to configure {{site.base_gateway}} for the included test cases, and the observability plugins for metrics scraping by the Prometheus instance already provisioned in the cluster. If you’d rather define your own test scenarios, you can also define the {{site.base_gateway}} configuration you want to test and apply it to the cluster.

From there, you can use the [included bash scripts to run K6 tests](https://github.com/Kong/kong-gateway-performance-benchmark/tree/main/deploy-k8s-resources/k6_tests). After the tests complete, you can `port-forward` into the cluster and view the Grafana dashboard with the performance results.
