---
title: Konnect Reference Platform - APIOps
content_type: reference
layout: reference

products:
    - api-ops
works_on:
  - konnect

description: Provides details on how the Konnect Reference Platform uses APIOps

breadcrumbs:
  - /konnect-reference-platform/

related_resources:
- text: Reference Platform Home
  url: /konnect-reference-platform/
- text: Reference Platform How-To
  url: /konnect-reference-platform/how-to/
---

TODO: Add documentation on the Konnect Orchestrator
TODO: Draw a mermaid diagram of the APIOps workflow

<!--vale off -->

{% mermaid %}
flowchart TB
    A[Service Application Repository] -->|reads openapi.yaml| B[Konnect Orchestrator]
    A -->|writes openapi.yaml PR| C[Platform Repository]
    C -->|reads openapi.yaml| D[OAS Conformance Workflow]
    D -->|approves/rejects openapi.yaml| E[OpenAPI to Kong Workflow]
    E -->|converts openapi.yaml<br>to kong.yaml PR| F[decK Conformance Workflow]
    F -->|approves/rejects kong.yaml| G[Stage decK Changes Workflow]
    G -->|merges kong.yaml,<br>calculates diff w/ Control Plane,<br>stages PR| H[deck Sync Workflow]
    H -->|synchronizes kong.yaml| I[Konnect Control Plane]
{% endmermaid %}

<!--vale on -->
