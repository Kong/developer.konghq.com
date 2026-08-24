---
title: Installing custom dependencies in Kong Docker images
content_type: support
description: Extend the standard Kong Docker image with a custom `Dockerfile` to install additional CLI tools and Lua libraries for a custom plugin.
products:
  - gateway
  - kic
works_on:
  - on-prem
  - konnect
tldr:
  q: How can custom dependencies be installed in Kong images?
  a: |
    Extend the standard Kong Docker image with a custom `Dockerfile`: switch to the `root` user, install packages with `apt-get` (the default image is Ubuntu-based), use `luarocks` to add Lua rocks, then switch back to the `kong` user and build the image with `docker build`.
related_resources: []
---

## Overview

When using a custom plugin, there is sometimes a requirement to add some custom libraries for the plugin. How can the libraries be installed in a docker image for use in a Kubernetes deployment?

## Steps

To create a custom image using the standard Kong image as a base, it is necessary to create a `Dockerfile`. The below example of a `Dockerfile` can be used to create a custom image that has an additional CLI tool and some lua packages installed;

```dockerfile

FROM kong/kong-gateway:3.14.0.0

# Use the priviled root user to install new packages
USER root

# Install additional tools by using APT package manager here
# Example here is for adding the common tool jq into the image
# unzip is required by luarocks to install zip-packaged rocks
RUN apt-get update \
 && apt-get install -y jq unzip \
 && rm -rf /var/lib/apt/lists/*

# The lua package manger is installed by default with Kong 
# use the tool to install additional lua plugins

# Use the luarocks repository to install rock files
RUN ["luarocks", "install", "lua-resty-jwt"]

# Copy a local .rock file to the image and install it
COPY lua-zlib-1.2-0.linux-x86_64.rock /tmp
RUN luarocks install /tmp/lua-zlib-1.2-0.linux-x86_64.rock
RUN rm /tmp/lua-zlib-1.2-0.linux-x86_64.rock

# Switch back to the non-privileged kong user
USER kong
```

Note: the Enterprise `-alpine` image variant no longer exists; the default Kong Gateway image is now Ubuntu-based, so package installation uses `apt-get` rather than `apk`. Installing `unzip` is required before `luarocks install`, since zip-packaged rocks fail to install without it on the Ubuntu-based image.

To build the custom image, run the below command in the same directory and the `Dockerfile`;

```bash

docker build -t kong-with-jq-jwt .
```

This will create a local image with the tag `kong-with-jq-jwt`. You can use this in a `docker-compose` file like this;

```yaml

image: kong-with-jq-jwt:latest
```

You can then push this image to your organizations docker repository with the `docker push` command.
