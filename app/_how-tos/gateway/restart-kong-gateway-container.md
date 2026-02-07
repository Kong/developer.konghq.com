---
title: How to restart {{site.base_gateway}} in a Docker container
permalink: /how-to/restart-kong-gateway-container/
description: Restart the {{site.base_gateway}} container without killing it.
content_type: how_to

works_on:
    - on-prem
products:
    - gateway
tags:
  - docker

tldr: 
  q: How do I restart {{site.base_gateway}} when it is running inside of a container
  a: Use `kong reload`.

faqs:
  - q: What happens when I run `kong restart`?
    a: |
      `kong restart` kills the `pid`, which will kill the container.


min_version:
    gateway: '3.4'

automated_tests: false
---



## Restart a {{site.base_gateway}} Docker container

To restart a {{site.base_gateway}} container without killing the container, run `kong reload` from within the container. 