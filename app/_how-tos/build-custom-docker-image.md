---
title: Build a custom Docker image
description: "How to build a custom Docker image "

products:
    - gateway

content_type: how_to

tldr: 
  q: How do I build a custom {{site.base_gateway}} Docker image?
  a: Create a Docker file and use [`docker build`](/how-to/docker-run) to build the image.

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
        2. Make the script exectuable
            ```sh
            chmod +x docker-entrypoint.sh
            ```
    - title: Download the {{site.base_gateway}} base image
      content: |
        1. [Download](/gateway/install/#linux) the image for your desired operating system.
        2. Rename the file to either `kong.deb` or `kong.rpm` depending on the pacakge.
---


## 1. Create a Dockerfile

Create a Dockerfile using any of the following templates:

{% navtabs "Dockerfile" %}
{% navtab "Debian" %}
```
cat <<EOF > Dockerfile

FROM debian:bullseye-slim
   
COPY kong.deb /tmp/kong.deb
   
RUN set -ex; \
    apt-get update \
    && apt-get install --yes /tmp/kong.deb \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /tmp/kong.deb \
    && chown kong:0 /usr/local/bin/kong \
    && chown -R kong:0 /usr/local/kong \
    && ln -s /usr/local/openresty/luajit/bin/luajit /usr/local/bin/luajit \
    && ln -s /usr/local/openresty/luajit/bin/luajit /usr/local/bin/lua \
    && ln -s /usr/local/openresty/nginx/sbin/nginx /usr/local/bin/nginx \
    && kong version
   
COPY docker-entrypoint.sh /docker-entrypoint.sh
   
USER kong
   
ENTRYPOINT ["/docker-entrypoint.sh"]
   
EXPOSE 8000 8443 8001 8444 8002 8445 8003 8446 8004 8447
   
STOPSIGNAL SIGQUIT
   
HEALTHCHECK --interval=10s --timeout=10s --retries=10 CMD kong health
   
CMD ["kong", "docker-start"]
EOF
```
{% endnavtab %}
{% navtab "RHEL" %}
```
cat <<EOF > Dockerfile
FROM registry.access.redhat.com/ubi9/ubi:9.5
   
COPY kong.rpm /tmp/kong.rpm
   
RUN set -ex; \
    yum install -y /tmp/kong.rpm \
    && rm /tmp/kong.rpm \
    && chown kong:0 /usr/local/bin/kong \
    && chown -R kong:0 /usr/local/kong \
    && ln -s /usr/local/openresty/luajit/bin/luajit /usr/local/bin/luajit \
    && ln -s /usr/local/openresty/luajit/bin/luajit /usr/local/bin/lua \
    && ln -s /usr/local/openresty/nginx/sbin/nginx /usr/local/bin/nginx \
    && kong version
   
COPY docker-entrypoint.sh /docker-entrypoint.sh
   
USER kong
   
ENTRYPOINT ["/docker-entrypoint.sh"]
   
EXPOSE 8000 8443 8001 8444 8002 8445 8003 8446 8004 8447
   
STOPSIGNAL SIGQUIT
   
HEALTHCHECK --interval=10s --timeout=10s --retries=10 CMD kong health
   
CMD ["kong", "docker-start"]
EOF
```
{% endnavtab %}
{% navtab "Ubuntu" %}
```
cat <<EOF > Dockerfile
FROM ubuntu:24.04
   
COPY kong.deb /tmp/kong.deb
   
RUN set -ex; \
    apt-get update \
    && apt-get install --yes /tmp/kong.deb \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /tmp/kong.deb \
    && chown kong:0 /usr/local/bin/kong \
    && chown -R kong:0 /usr/local/kong \
    && ln -s /usr/local/openresty/luajit/bin/luajit /usr/local/bin/luajit \
    && ln -s /usr/local/openresty/luajit/bin/luajit /usr/local/bin/lua \
    && ln -s /usr/local/openresty/nginx/sbin/nginx /usr/local/bin/nginx \
    && kong version
   
COPY docker-entrypoint.sh /docker-entrypoint.sh
   
USER kong
   
ENTRYPOINT ["/docker-entrypoint.sh"]
   
EXPOSE 8000 8443 8001 8444 8002 8445 8003 8446 8004 8447
   
STOPSIGNAL SIGQUIT
   
HEALTHCHECK --interval=10s --timeout=10s --retries=10 CMD kong health
   
CMD ["kong", "docker-start"]
EOF
```
{% endnavtab %}
{% endnavtabs %}

## 2. Build the image

Using the [`docker build`](/how-to/docker-run/) command, you can build the image: 

```
docker build --platform linux/amd64 --no-cache -t kong-image .
```

Docker will build the image according to the parameters set in the Dockerfile.

## 3. Validate the image

Validate that the image was built correctly using [`docker run`](/how-to/docker-run): 

```
docker run -it --rm kong-image kong version
```

