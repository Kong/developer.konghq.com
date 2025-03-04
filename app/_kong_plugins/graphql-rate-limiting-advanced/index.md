---
title: GraphQL Rate Limiting Advanced

name: GraphQL Rate Limiting Advanced
publisher: kong-inc
content_type: plugin
description: Provides rate limiting for GraphQL queries.
tags:
  - rate-limiting
  - graphql-rate-limiting-advanced
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
---

## Overview

The GraphQL Rate Limiting Advanced plugin provides rate limiting for GraphQL queries. The GraphQL Rate Limiting plugin extends the [Rate Limiting Advanced](/plugins/rate-limiting-advanced/) plugin.

Due to the nature of client-specified GraphQL queries, the same HTTP request to the same URL with the same method can vary greatly in cost depending on the semantics of the GraphQL operation in the body.

A common pattern to protect your GraphQL API is then to analyze and assign costs to incoming GraphQL queries and rate limit the consumer’s cost for a given time window.
