---
title: Run {{site.base_gateway}} from a custom Docker image
description: "Run docker images"

products:
    - gateway

content_type: how_to

tldr: 
  q: How do I build a custom {{site.base_gateway}} Docker image?
  a: Create a Docker file

works_on:
    - on-prem

breadcrumbs:
    - /gateway/
min_version:
  gateway: '3.4'
prereqs:
  skip_product: true 
  inline:
    - title: Download the {{site.base_gateway}} entry-point script.
      content: |
        1. Download the {{site.base_gateway}} [entry-point script](https://raw.githubusercontent.com/Kong/docker-kong/master/docker-entrypoint.sh):
            ```sh
            curl -O https://raw.githubusercontent.com/Kong/docker-kong/master/docker-entrypoint.sh
            ```
        2. Make the script executable
            ```sh
            chmod +x docker-entrypoint.sh
            ```
    - title: Download the {{site.base_gateway}} base image
      content: |
        1. [Download](/gateway/install/#linux) the image for your desired operating system.
        2. Rename the file to either `kong.deb` or `kong.rpm` depending on the package.
---

@TODO https://docs.konghq.com/gateway/latest/install/docker/

Include:
- how to optionally start the database
- how to install Kong from the image