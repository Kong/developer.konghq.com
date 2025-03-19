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

related_resources:
  - text: Map URIs into GraphQL queries with DeGraphQL
    url: /how-to/map-uris-into-graphql-queries/
---

The DeGraphQL plugin transforms GraphQL upstreams into traditional endpoints by mapping URIs into GraphQL queries.

## How it works

DeGraphQL needs a GraphQL endpoint to query. 
This plugin must be activated on a Gateway Service or related Route that points to a GraphQL endpoint.

{{site.base_gateway}} receives traffic from clients and uses a Gateway Service with DeGraphQL routes to map URIs to GraphQL queries.

<!-- vale off -->
{% mermaid %}
flowchart LR
A(Devices/apps)
B(Gateway Service with 
DeGraphQL routes)
C(<img src="/assets/icons/graphql.svg" style="max-height:20px"/> GraphQL)

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

style C stroke:#E10098!important
style Note stroke:#e1bb86!important
style id1 stroke-dasharray:3

end
{% endmermaid %}
<!-- vale on -->
> _Figure 1: Diagram showing how {{site.base_gateway}} receives traffic from clients and uses a Gateway Service 
with DeGraphQL routes to map URIs to GraphQL queries._

For a complete tutorial, see [Map URIs into GraphQL queries with DeGraphQL](/how-to/map-uris-into-graphql-queries/).

## Example DeGraphQL routes

The following sections define some common patterns for DeGraphQL routes.

{:.info}
> Don’t include the GraphQL server path prefix in the URI parameter (`/graphql` by default).

### GraphQL query variables on URIs

GraphQL query variables can be applied on URIs.

Here's an example query that retrieves GitHub repository info from the GitHub GraphQL API:

```bash
curl -X POST http://localhost:8001/services/github/degraphql/routes \
  --data uri='/:owner/:name' \
  --data query='query ($owner:String! $name:String!){
                  repository(owner:$owner, name:$name) {
                    name
                    forkCount
                    description
                 }
               }'

```
You can access it via `org-name/repo-name`:

```sh
curl http://localhost:8000/api/kong/kong \
  --header "Authorization: Bearer $GITHUB_TOKEN"
```

Response:
```json
{
  "data": {
      "repository": {
          "description": "🦍 The Cloud-Native API Gateway ",
          "forkCount": 2997,
          "name": "kong"
      }
  }
}
```

### GraphQL query variables as GET arguments

GraphQL query variables can be provided as `GET` arguments.

Here's an example query that retrieves GitHub repository info from the GitHub GraphQL API:

```bash
curl -X POST http://localhost:8001/services/github/degraphql/routes \
  --data uri='/repo' \
  --data query='query ($owner:String! $name:String!){
                  repository(owner:$owner, name:$name) {
                    name
                    forkCount
                    description
                  }
                }'
```

You can access it via the URL query `repo?owner=owner-name&name=repo-name`:

```sh
curl "http://localhost:8000/api/repo?owner=kong&name=kuma" \
  --header "Authorization: Bearer some-token"
```

Response:
```json
{
  "data": {
      "repository": {
          "description": "🐻 The Universal Service Mesh",
          "forkCount": 48,
          "name": "kuma"
      }
  }
}
```
