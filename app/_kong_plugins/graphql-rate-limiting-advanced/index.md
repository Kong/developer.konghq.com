---
title: GraphQL Rate Limiting Advanced

name: GraphQL Rate Limiting Advanced
publisher: kong-inc
tier: enterprise
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

---

## Overview

The GraphQL Rate Limiting Advanced plugin provides rate limiting for GraphQL queries. The GraphQL Rate Limiting plugin extends the [Rate Limiting Advanced](/plugins/rate-limiting-advanced/) plugin.

Due to the nature of client-specified GraphQL queries, the same HTTP request to the same URL with the same method can vary greatly in cost depending on the semantics of the GraphQL operation in the body.

A common pattern to protect your GraphQL API is then to analyze and assign costs to incoming GraphQL queries and rate limit the consumer’s cost for a given time window.
