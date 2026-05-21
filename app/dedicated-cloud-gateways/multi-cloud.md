---
title: "Multi-cloud Dedicated Cloud Gateway network architecture"
content_type: reference
layout: reference
description: "Learn how to deploy Dedicated Cloud Gateways across multiple cloud providers, including supported hostname strategies and their tradeoffs."

products:
    - gateway
breadcrumbs:
  - /dedicated-cloud-gateways/
works_on:
  - konnect

related_resources:
  - text: Dedicated Cloud Gateways
    url: /dedicated-cloud-gateways/
  - text: Dedicated Cloud Gateways network architecture
    url: /dedicated-cloud-gateways/network-architecture/
  - text: Dedicated Cloud Gateways private network architecture and security
    url: /dedicated-cloud-gateways/private-network/
  - text: Dedicated Cloud Gateways public network architecture and security
    url: /dedicated-cloud-gateways/public-network/
next_steps:
  - text: Dedicated Cloud Gateways production readiness checklist
    url: /dedicated-cloud-gateways/production-readiness/
tags:
  - dedicated-cloud-gateways
---

{% include sections/dcgw-multi-cloud-intro.md %}

## Hostname strategies

The three supported hostname strategies differ in how they route traffic across deployments, and what infrastructure they require:

{% table %}
columns:
  - title: Option
    key: option
  - title: How it works
    key: how
  - title: Pros
    key: pros
  - title: Cons
    key: cons
rows:
  - option: "**Cloud-specific hostnames** (recommended)"
    how: |
      Each cloud deployment gets its own hostname. Clients use the hostname for the cloud they want to target:
      * `aws.api.example.com` → AWS DCGW → AWS upstreams
      * `azure.api.example.com` → Azure DCGW → Azure upstreams
      * `gcp.api.example.com` → GCP DCGW → GCP upstreams

      You manage DNS records. Each hostname CNAMEs directly to that cloud's gateway endpoint.
    pros: |
      * Deterministic routing (no accidental cross-cloud traffic)
      * Clear operational blast radius per cloud
      * Predictable latency and egress costs
      * No additional routing layer required
    cons: |
      * Clients must know which hostname to call
      * Multiple DNS records and certificates to manage
  - option: "**Single global hostname with geo-proximity DNS**"
    how: |
      A single hostname routes traffic to the nearest cloud deployment based on the client's geographic location.
      DNS selects the closest gateway deployment and the request lands on that cloud's data planes, which route to upstream services configured in that deployment.

      {:.warning}
      > DNS routing is not HTTP-aware. `api.example.com/azure` does **not** guarantee traffic reaches the Azure deployment. If your APIs or upstreams differ per cloud, use cloud-specific hostnames to avoid cross-cloud routing.
    pros: |
      * Single hostname for all consumers
      * Optimizes latency automatically
      * Supports active/active resiliency
    cons: |
      * Only works when APIs and upstreams are identical across all clouds
      * Can introduce cross-cloud latency or private networking issues if upstreams are cloud-specific
      * No path, header, or tenant-based routing
  - option: "**Single hostname with L7 edge routing**"
    how: |
      A CDN or global load balancer sits in front of all cloud deployments and routes traffic based on path, header, or tenant.
      The L7 edge handles WAF, TLS termination, and traffic steering before forwarding requests to the correct deployment.
    pros: |
      * HTTP-aware routing under a single hostname
      * Supports path-based, header-based, and tenant-based routing
      * Centralized WAF and TLS termination
    cons: |
      * Adds an architectural component you own and operate
      * Introduces an additional latency hop
      * Most operationally complex option
{% endtable %}

## Architecture

The following diagrams show the architecture for each multi-cloud configuration option:

### Cloud-specific hostnames

Each cloud deployment gets its own hostname. Clients use the hostname for the cloud they want to target:

{% mermaid %}
flowchart LR
    client1["Client"] --> aws_dns["aws.api.example.com"]
    client2["Client"] --> azure_dns["azure.api.example.com"]
    client3["Client"] --> gcp_dns["gcp.api.example.com"]

    aws_dns --> aws["AWS DCGW"]
    azure_dns --> azure["Azure DCGW"]
    gcp_dns --> gcp["GCP DCGW"]

    aws --> aws_up["AWS upstreams"]
    azure --> azure_up["Azure upstreams"]
    gcp --> gcp_up["GCP upstreams"]
{% endmermaid %}

You can optionally use `api.example.com` (geo‑routed) for generic global access or disaster recovery.

### Geo-proximity DNS

A single hostname routes traffic to the nearest cloud deployment based on the client's geographic location.

{% mermaid %}
flowchart LR
    client["Client"] --> dns["api.example.com (geo-proximity DNS)"]

    dns --> aws["AWS DCGW"]
    dns --> azure["Azure DCGW"]
    dns --> gcp["GCP DCGW"]

    aws --> aws_up["AWS upstreams"]
    azure --> azure_up["Azure upstreams"]
    gcp --> gcp_up["GCP upstreams"]
{% endmermaid %}

### L7 edge routing

A CDN or global load balancer sits in front of all cloud deployments and routes traffic based on path, header, or tenant.

{% mermaid %}
flowchart LR
    client["Client"] --> hostname["api.example.com"]
    hostname --> edge["Global L7 edge (CDN/global load balancer)"]

    edge --> aws["AWS DCGW"]
    edge --> azure["Azure DCGW"]
    edge --> gcp["GCP DCGW"]

    aws --> aws_up["AWS upstreams"]
    azure --> azure_up["Azure upstreams"]
    gcp --> gcp_up["GCP upstreams"]
{% endmermaid %}

The global L7 edge would have:
- Path-based routing (`/aws/*`, `/azure/*`, `/gcp/*`)
- Header-based or tenant-based routing
- Centralized WAF/TLS termination