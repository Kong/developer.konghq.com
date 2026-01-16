---
title: GraphQL Rate Limiting Advanced

name: GraphQL Rate Limiting Advanced
publisher: kong-inc
tier: enterprise
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
  - GraphQL

related_resources:
  - text: About rate limiting
    url: /rate-limiting/
  - text: Rate limiting with {{site.base_gateway}}
    url: /gateway/rate-limiting/
  - text: GraphQL Proxy Cache Advanced plugin
    url: /plugins/graphql-proxy-cache-advanced/
  - text: Governing GraphQL APIs with {{site.base_gateway}}
    url: https://konghq.com/blog/engineering/governing-graphql-apis-with-kong-gateway

notes: |
  In DB-less, hybrid mode, and Konnect, the <code>cluster</code> config strategy
  is not supported. Use <code>redis</code> instead.

min_version:
  gateway: '1.3'
---

The GraphQL Rate Limiting Advanced plugin provides rate limiting for [GraphQL queries](https://graphql.org/learn/queries/).

Due to the nature of client-specified GraphQL queries, the same HTTP request to the same URL with the same method can vary greatly in cost depending on the semantics of the GraphQL operation in the body.
To protect your GraphQL API, this plugin lets you analyze and assign costs to incoming GraphQL queries, then rate limit the Consumer’s cost for a given time window.

## Rate limiting strategies

This plugin supports `cluster` and `redis` as rate limiting strategies. You can configure them using the plugin's [`config.strategy`](/plugins/graphql-rate-limiting-advanced/reference/#schema--config-strategy) parameter. If using the `cluster` strategy, all `config.redis` configuration values are ignored.

This is different from the cost strategy ([`config.cost_strategy`](/plugins/graphql-rate-limiting-advanced/reference/#schema--config-cost_strategy)), which is the method that the plugin uses to determine GraphQL query costs.

{:.warning}
> A `cluster` strategy with a sync rate of `-1` should not be used in production with hybrid mode, DB-less mode, or Konnect, as it creates security risks.

## Introspection endpoint

The [introspection](https://graphql.org/learn/introspection/) endpoint is generated based on the [Gateway Service path](/gateway/entities/service/), so you must define a path in the Gateway Service itself, 
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

{% table %}
columns:
  - title: "`type_path`"
    key: type-path
  - title: "`mul_arguments`"
    key: mul-arguments
  - title: "`mul_constant`"
    key: mul-constant
  - title: "`add_arguments`"
    key: add-arguments
  - title: "`add_constant`"
    key: add-constant
rows:
  - type-path: "`Query.allPeople`"
    mul-arguments: '["first"]'
    mul-constant: 1
    add-arguments: '[]'
    add-constant: 1
  - type-path: "`Person.vehicleConnection`"
    mul-arguments: '["first"]'
    mul-constant: 1
    add-arguments: '[]'
    add-constant: 1
{% endtable %}


In this example, `vehicleConnection` weight (4) is applied 10 times, and the total weight of it (40) 20 times, which gives us a rough 800:
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


Cost constants can be atomically defined as:

{% table %}
columns:
  - title: "`type_path`"
    key: type-path
  - title: "`mul_arguments`"
    key: mul-arguments
  - title: "`mul_constant`"
    key: mul-constant
  - title: "`add_arguments`"
    key: add-arguments
  - title: "`add_constant`"
    key: add-constant
rows:
  - type-path: "`Query.allPeople`"
    mul-arguments: '["first"]'
    mul-constant: 2
    add-arguments: '[]'
    add-constant: 2
  - type-path: "`Person.vehicleConnection`"
    mul-arguments: '["first"]'
    mul-constant: 1
    add-arguments: '[]'
    add-constant: 5
  - type-path: "`Vehicle.name`"
    mul-arguments: '[]'
    mul-constant: 1
    add-arguments: '[]'
    add-constant: 8
{% endtable %}

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

Let's use the following example configuration: 

{% table %}
columns:
  - title: "`type_path`"
    key: type-path
  - title: "`mul_arguments`"
    key: mul-arguments
  - title: "`mul_constant`"
    key: mul-constant
  - title: "`add_arguments`"
    key: add-arguments
  - title: "`add_constant`"
    key: add-constant
rows:
  - type-path: "`Query.allPeople`"
    mul-arguments: '["first"]'
    mul-constant: 1
    add-arguments: '[]'
    add-constant: 1
  - type-path: "`Person.vehicleConnection`"
    mul-arguments: '["first"]'
    mul-constant: 1
    add-arguments: '[]'
    add-constant: 1
  - type-path: "`Vehicle.filmConnection`"
    mul-arguments: '["first"]'
    mul-constant: 1
    add-arguments: '[]'
    add-constant: 1
  - type-path: "`Film.characterConnection`"
    mul-arguments: '["first"]'
    mul-constant: 1
    add-arguments: '[]'
    add-constant: 1
{% endtable %}

Here's what it looks like in a query:
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


In the example above:

* `allPeople` returns 100 nodes and has been called once
* `vehicleConnection` returns 10 nodes and has been called 100 times
* `filmConnection` returns 5 nodes and has been called 10 * 100 times
* `characterConnection` returns 50 nodes and has been called 5 * 10 * 100 times


Specific costs per node can be specified by adding a constant:

{% table %}
columns:
  - title: "`type_path`"
    key: type-path
  - title: "`mul_arguments`"
    key: mul-arguments
  - title: "`mul_constant`"
    key: mul-constant
  - title: "`add_arguments`"
    key: add-arguments
  - title: "`add_constant`"
    key: add-constant
rows:
  - type-path: "`Query.allPeople`"
    mul-arguments: '["first"]'
    mul-constant: 1
    add-arguments: '[]'
    add-constant: 1
  - type-path: "`Person.vehicleConnection`"
    mul-arguments: '["first"]'
    mul-constant: 1
    add-arguments: '[]'
    add-constant: 42
  - type-path: "`Vehicle.filmConnection`"
    mul-arguments: '["first"]'
    mul-constant: 1
    add-arguments: '[]'
    add-constant: 1
  - type-path: "`Film.characterConnection`"
    mul-arguments: '["first"]'
    mul-constant: 1
    add-arguments: '[]'
    add-constant: 1
{% endtable %}

For example: 
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

{% table %}
columns:
  - title: "Form parameter"
    key: form-parameter
  - title: "Default"
    key: default
  - title: "Description"
    key: description
rows:
  - form-parameter: "`type_path`"
    default: "none"
    description: "Path to the node to decorate."
  - form-parameter: "`add_constant`"
    default: "`1`"
    description: "Node weight when added."
  - form-parameter: "`add_arguments`"
    default: "`[]`"
    description: "List of arguments to add to `add_constant`."
  - form-parameter: "`mul_constant`"
    default: "`1`"
    description: "Node weight multiplier value."
  - form-parameter: "`mul_arguments`"
    default: "`[]`"
    description: "List of arguments that multiply weight."
{% endtable %}

## Costs API endpoints


The GraphQL Proxy Cache Advanced plugin exposes several [`/graphql-rate-limiting-advanced`](/plugins/graphql-rate-limiting-advanced/api/) endpoints for cost decoration through the Kong Admin API.

You can use the Admin API to:
* Create costs on Gateway Services or globally
* Review, update, or delete existing costs

To access these endpoints, [enable the plugin](/plugins/graphql-rate-limiting-advanced/examples/) first.
The GraphQL cost management endpoints will appear once the plugin has been enabled.

{% include plugins/redis-cloud-auth.md %}
