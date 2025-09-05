---
title: 'DeGraphQL'
name: 'DeGraphQL'

content_type: plugin
tier: enterprise
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
search_aliases:
  - graphql

categories:
  - transformations

related_resources:
  - text: Map URIs into GraphQL queries with DeGraphQL
    url: /how-to/map-uris-into-graphql-queries/

min_version:
  gateway: '1.3'
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



end
{% endmermaid %}
<!-- vale on -->
> _Figure 1: Diagram showing how {{site.base_gateway}} receives traffic from clients and uses a Gateway Service 
with DeGraphQL routes to map URIs to GraphQL queries._

For a complete tutorial, see [Map URIs into GraphQL queries with DeGraphQL](/how-to/map-uris-into-graphql-queries/).

## Example DeGraphQL routes

The following sections define some common patterns for DeGraphQL routes.

{:.info}
> - Don’t include the GraphQL server path prefix in the `uri` configuration parameter (`/graphql` by default). 
Only include the custom portion of the path that you want to configure. For example: `uri: /my-path`, but not `uri: /graphql/my-path`.
> - The content in the `query` field should follow [the GraphQL query syntax](https://graphql.org/learn/queries/).

### GraphQL query variables on URIs

GraphQL query variables can be applied on URIs.

Here's an example query that retrieves GitHub repository info from the GitHub GraphQL API:

```yaml
_format_version: "3.0"
custom_entities:
  - type: degraphql_routes
    fields:
      service:
        name: "github"
      uri: /:owner/:name
      query: |-
        query ($owner:String! $name:String!){
                        repository(owner:$owner, name:$name) {
                          name
                          forkCount
                          description
                        }
                      }
```
You can access the new route via `org-name/repo-name`:

```sh
curl http://localhost:8000/api/kong/kong \
  --header "Authorization: Bearer $GITHUB_TOKEN"
```


### GraphQL query variables as GET arguments

GraphQL query variables can be provided as `GET` arguments.

Here's an example query that retrieves GitHub repository info from the GitHub GraphQL API:

```yaml
_format_version: "3.0"
custom_entities:
  - type: degraphql_routes
    fields:
      service:
        name: "github"
      uri: /repo
      query: |-
        query ($owner:String! $name:String!){
                  repository(owner:$owner, name:$name) {
                    name
                    forkCount
                    description
                  }
                }
```

You can access the new route by appending `repo?owner=OWNER_NAME&name=REPO_NAME` to the request URL:

```sh
curl "http://localhost:8000/api/repo?owner=kong&name=kuma" \
  --header "Authorization: Bearer $GITHUB_TOKEN"
```

