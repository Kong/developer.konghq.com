---
title: 'DeGraphQL'
name: 'DeGraphQL'

content_type: plugin

publisher: kong-inc
description: 'Transform a GraphQL upstream into a REST API'

tags:
  - graphql
  - transformations

products:
    - gateway

works_on:
    - on-prem
    - konnect

topologies:
  on_prem:
    - hybrid
    - db-less
    - traditional
  konnect_deployments:
    - hybrid
    - cloud-gateways
    - serverless

icon: degraphql.png

categories:
  - transformations
---

The DeGraphQL plugin transforms GraphQL upstreams into traditional endpoints by mapping URIs into GraphQL queries.

## How it works

DeGraphQL needs a GraphQL endpoint to query. 
This plugin must be activated on a Gateway Service that points to a GraphQL endpoint.

{{site.base_gateway}} receives traffic from clients and uses a Gateway Service with DeGraphQL routes to map URIs to GraphQL queries.

<!-- vale off -->
{% mermaid %}
flowchart LR
A(Devices/apps)
B(Gateway Service with 
DeGraphQL routes)
C(<img src="/assets/icons/plugins/graphql-proxy-cache-advanced.png" style="max-height:20px"/> GraphQL)

A<-->B
subgraph id1 [Data center]
subgraph id2 [{{site.base_gateway}}]
B
end
B--Query 1-->C
B--Query 2-->C
B--Query 3-->C
B--Query 4-->C

Note[Queries are passed as 
parameters to GraphQL]

style C stroke:#E10098
style Note fill:#fdf3d8,stroke:#e1bb86
style id1 stroke-dasharray:3

end
{% endmermaid %}
<!-- vale on -->
> _Figure 1: Diagram showing how {{site.base_gateway}} receives traffic from clients and uses a Gateway Service 
with DeGraphQL routes to map URIs to GraphQL queries._

