---
title: How to restart {{site.base_gateway}} in a Docker Container
content_type: how_to

works_on:
    - on-prem
products:
    - gateway
tags:
  - gateway
  - container

tldr: 
  q: How do I restart {{site.base_gateway}} when it is running inside of a container
  a: You can use `kong reload`.

faqs:
  - q: What happens when I run `kong restart`?
    a: |
      Kong restart kills the `pid` which will kill the container.

---



## Restart a {{site.base_gateway}} Docker container

To restart a {{site.base_gateway}} container without killing the container run `kong reload` from within the container. 