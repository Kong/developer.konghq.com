---
title: GraphQL Rate Limiting Advanced

name: GraphQL Rate Limiting Advanced
publisher: kong-inc
content_type: plugin
description: Provides rate limiting for GraphQL queries
tags:
  - graphql
  - rate-limiting
  - traffic-control

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

icon: graphql-rate-limiting-advanced.png

categories:
  - traffic-control

search_aliases:
  - graphql-rate-limiting-advanced

related_resources:
  - text: GraphQL Proxy Cache Advanced plugin
    url: /plugins/graphql-proxy-cache-advanced/
---

The GraphQL Rate Limiting Advanced plugin provides rate limiting for GraphQL queries.

Due to the nature of client-specified GraphQL queries, the same HTTP request to the same URL with the same method can vary greatly in cost depending on the semantics of the GraphQL operation in the body.
To protect your GraphQL API, this plugin lets you analyze and assign costs to incoming GraphQL queries, then rate limit the consumer’s cost for a given time window.

## Rate limiting strategies

This plugin supports `cluster` and `redis` as rate limiting strategies. You can configure them using the plugin's [`config.strategy`](/plugins/graphql-rate-limiting-advanced/reference/#schema--config-strategy) parameter. If using the `cluster` strategy, all `config.redis` configuration values are ignored.

This is different from the cost strategy ([`config.cost_strategy`](/plugins/graphql-rate-limiting-advanced/reference/#schema--config-cost_strategy)), which is the method that the plugin uses to determine GraphQL query costs.

{:.warning}
> A `cluster` strategy with a sync rate of `-1` should not be used in production with hybrid mode, DB-less mode, or Konnect, as it creates security risks.

## Introspection endpoint

The introspection endpoint is generated based on the [Gateway Service path](/gateway/entities/service/), so you must define a path in the Gateway Service itself, 
instead of appending from the Route path.
  
The query and introspection endpoints _cannot_ have separate paths.

For example, when using KIC, if the query and introspection endpoints are at the path `/graphql`, they should be configured like this:
* Add the `konghq.com/strip-path: "true"` annotation to the Ingress resource
* Add the `konghq.com/path: /graphql` annotation to the Service resource

## Managing costs in GraphQL queries

{{site.base_gateway}} evaluates GraphQL query costs by introspecting the endpoint's GraphQL schema and applying cost decoration to parts of the schema tree.

Initially all nodes start with zero cost, with any operation at cost 1.
You can add rate limiting constraints on any subtree. 
If a subtree is omitted, then the rate limit window applies to the whole tree, meaning any operation.

The GraphQL Rate Limiting Advanced plugin exposes two strategies for approximating the cost of a GraphQL query, configurable via [`config.cost_strategy`](/plugins/graphql-rate-limiting-advanced/reference/#schema--config-cost_strategy):
* [`default`](#default-strategy): The default strategy tries to estimate cost on queries by counting the nesting of nodes. 
* [`node_quantifier`](#node_quantifier-strategy): Useful for GraphQL schemas that enforce quantifier arguments on any connection.

### default strategy

The default strategy is meant as a good middle ground for general GraphQL
queries, where it's difficult to assert a clear cost strategy, so every operation
has a cost of 1.

For example:

```
query { # + 1
  allPeople {  # + 1
    people { # + 1
      name # + 1
    }
  }
}
# total cost: 4
```

Default node costs can be defined by decorating the schema:

| `type_path`                | `mul_arguments`   | `mul_constant`    | `add_arguments`   | `add_constant` |
|----------------------------|-------------------|-------------------|-------------------|----------------|
| `Query.allPeople`          | ["first"]         | 1                 | []                | 1              |
| `Person.vehicleConnection` | ["first"]         | 1                 | []                | 1              |


```
query { # + 1
  allPeople(first:20) { # * 20 + 1
    people { # + 1
      name # + 1
      vehicleConnection(first:10) { # * 10 + 1
        vehicles { # + 1
          id  # + 1
          name # + 1
          cargoCapacity # + 1
        }
      }
    }
  }
}
# total cost: ((((4 * 10 + 1) + 1) + 1) * 20 + 1) + 1 = 862
```

In this example, `vehicleConnection` weight (4) is applied 10 times, and the total weight of it (40) 20 times, which gives us a rough 800.

Cost constants can be atomically defined as:

| `type_path`                | `mul_arguments`   | `mul_constant`    | `add_arguments`   | `add_constant` |
|----------------------------|-------------------|-------------------|-------------------|----------------|
| `Query.allPeople`          | ["first"]         | 2                 | []                | 2              |
| `Person.vehicleConnection` | ["first"]         | 1                 | []                | 5              |
| `Vehicle.name`             | []                | 1                 | []                | 8              |

In this example, `Vehicle.name` and `Person.vehicleConnection` have specific weights of 8 and 5 respectively. 
`allPeople` has a weight of 2, and also has double its weight when multiplied by arguments.

```
query { # + 1
  allPeople(first:20) { # 2 * 20 + 2
    people { # + 1
      name # + 1
      vehicleConnection(first:10) { # * 10 + 5
        vehicles { # + 1
          id  # + 1
          name # + 8
          cargoCapacity # + 1
        }
      }
    }
  }
}
# total cost: ((((11 * 10 + 5) + 1) + 1) * 2 * 20 + 2) + 1 = 4683
```

### node_quantifier strategy

This strategy is useful for GraphQL schemas that enforce quantifier arguments on
any connection, providing a good approximation on the number of nodes visited for satisfying a query. 
Any query without decorated quantifiers has a cost of 1.
This strategy is roughly based on [GitHub's GraphQL resource limits](https://developer.github.com/v4/guides/resource-limitations/).

For example:
```
query {
  allPeople(first:100) { # 1
    people {
      name
      vehicleConnection(first:10) { # 100
        vehicles {
          name
          filmConnection(first:5) { # 10 * 100
            films{
              title
              characterConnection(first:50) { # 5 * 10 * 100
                characters {
                  name
                }
              }
            }
          }
        }
      }
    }
  }
}
# total cost: 1 + 100 + 10 * 100 + 5 * 10 * 100 = 6101
```

| `type_path`                | `mul_arguments` | `mul_constant`    | `add_arguments`   | `add_constant` |
|----------------------------|-----------------|-------------------|-------------------|----------------|
| `Query.allPeople`          | ["first"]       | 1                 | []                | 1              |
| `Person.vehicleConnection` | ["first"]       | 1                 | []                | 1              |
| `Vehicle.filmConnection`   | ["first"]       | 1                 | []                | 1              |
| `Film.characterConnection` | ["first"]       | 1                 | []                | 1              |

In the example above:

* `allPeople` returns 100 nodes, and has been called once
* `vehicleConnection` returns 10 nodes, and has been called 100 times
* `filmConnection` returns 5 nodes, and has been called 10 * 100 times
* `characterConnection` returns 50 nodes, and has been called 5 * 10 * 100 times


Specific costs per node can be specified by adding a constant:

| `type_path`                | `mul_arguments`   | `mul_constant`    | `add_arguments`   | `add_constant` |
|----------------------------|-------------------|-------------------|-------------------|----------------|
| `Query.allPeople`          | ["first"]         | 1                 | []                | 1              |
| `Person.vehicleConnection` | ["first"]         | 1                 | []                | 42             |
| `Vehicle.filmConnection`   | ["first"]         | 1                 | []                | 1              |
| `Film.characterConnection` | ["first"]         | 1                 | []                | 1              |


```
query {
  allPeople(first:100) { # 1
    people {
      name
      vehicleConnection(first:10) { # 100 * 42
        vehicles {
          name
          filmConnection(first:5) { # 10 * 100
            films{
              title
              characterConnection(first:50) { # 5 * 10 * 100
                characters {
                  name
                }
              }
            }
          }
        }
      }
    }
  }
}
# total cost: 1 + 100 * 42 + 10 * 100 + 5 * 10 * 100 = 10201
```

### GraphQL cost decoration schema

The GraphQL cost decoration schema includes the following parameters:

| Form parameter    | Default   | Description |
|-------------------|-----------|-------------|
| `type_path`       |  none     | Path to the node to decorate. |
| `add_constant`    | `1`       | Node weight when added.   |
| `add_arguments`   | `[]`      | List of arguments to add to `add_constant`. |
| `mul_constant`    | `1`       | Node weight multiplier value. |
| `mul_arguments`   | `[]`      | List of arguments that multiply weight. |

## Costs API endpoints

<!-- @todo: update this link when api specs are added -->

The GraphQL Proxy Cache Advanced plugin exposes several [`/graphql-rate-limiting-advanced`](/api/gateway/admin-ee/) 
endpoints for cost decoration through the Kong Admin API.

You can use the Admin API to:
* Create costs on Gateway Services or globally
* Review, update, or delete existing costs

To access these endpoints, [enable the plugin](/plugins/graphql-rate-limiting-advanced/examples/) first.
The GraphQL cost management endpoints will appear once the plugin has been enabled.
