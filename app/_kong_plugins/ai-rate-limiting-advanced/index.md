---
title: AI Rate Limiting Advanced plugin

name: AI Rate Limiting Advanced
publisher: kong-inc
tier: enterprise

products:
    - gateway

works_on:
    - on-prem
    - konnect

min_version:
  gateway: '3.7'

content_type: plugin
description: Provides rate limiting for the providers used by any AI plugins. 
tags:
  - rate-limiting
  - ai-rate-limiting-advanced
  - traffic-control

---

## Overview

The AI Rate Limiting Advanced plugin provides rate limiting for the providers used by any AI plugins. The
AI Rate Limiting plugin extends the
[Rate Limiting Advanced](/plugins/rate-limiting-advanced/) plugin.

This plugin uses the token data returned by the LLM provider to calculate the costs of queries.
The same HTTP request can vary greatly in cost depending on the calculation of the 
LLM providers.

A common pattern to protect your AI API is to analyze and
assign costs to incoming queries, then rate limit the consumer's
cost for a given time window and providers.

You can also create a generic prompt rate limit using the request prompt provider.
