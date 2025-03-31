---
title: Install {{site.base_gateway}} with Docker
description: "Learn how to install {{site.base_gateway}} with Docker"
products:
    - gateway

content_type: how_to

tldr: 
  q: How do I build a custom {{site.base_gateway}} Docker image?
  a: Create a Docker file and use [`docker build`](/how-to/run-docker-images/) to build the image.

works_on:
    - on-prem
faqs:
  - q: What can I do with a {{site.base_gateway}} custom image?
    a: You can use a custom image to specify certain settings, like custom [ports](/gateway/network-ports-firewall/) or [`kong.conf`](/gateway/manage-kong-conf/) parameters. This can be useful if your organization has certain requirements or other software that they use in conjunction with their API gateway. You can also use custom images in automation pipelines.
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
        2. Make the script executable:
            ```sh
            chmod +x docker-entrypoint.sh
            ```
    - title: Download the {{site.base_gateway}} base image
      content: |
        1. [Download](/gateway/install/#linux) the image for your desired operating system.
        2. Rename the file to either `kong.deb` or `kong.rpm` depending on the package.

related_resources:
  - text: Run Docker images
    url: /how-to/run-docker-images/
next_steps:
  - text: Learn how to run custom images 
    url: /how-to/run-docker-images/
---
