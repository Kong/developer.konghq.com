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
  - q: When do I need to reload {{site.base_gateway}}?
    a: |
      Reload after changing any value in `kong.conf`, or after changing a file that a `kong.conf` parameter points to.
      These values are rendered into the NGINX configuration at startup, so {{site.base_gateway}} doesn't detect changes to them while it's running.

      You don't need to reload after changing configuration entities such as Services, Routes, plugins, or [Certificates](/gateway/entities/certificate/). Those are read from the configuration cache on every update.

related_resources:
  - text: Restart {{site.base_gateway}} on Kubernetes
    url: /how-to/restart-kong-gateway-kubernetes/
  - text: Manage kong.conf
    url: /gateway/manage-kong-conf/
  - text: Using SSL certificates in {{site.base_gateway}}
    url: /gateway/ssl-certificates/

min_version:
    gateway: '3.4'

automated_tests: false
---



## Restart a {{site.base_gateway}} Docker container

To restart a {{site.base_gateway}} container without killing the container, run `kong reload` from within the container. In this example, the container is named `kong-quickstart-gateway`:

```sh
docker exec kong-quickstart-gateway kong reload
```

{:.info}
> If {{site.base_gateway}} runs on Kubernetes, don't use `kong reload`. See [Restart {{site.base_gateway}} on Kubernetes](/how-to/restart-kong-gateway-kubernetes/) instead.
