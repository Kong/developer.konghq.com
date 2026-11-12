---
title: Build a non-distroless decK Docker image
description: Build a decK Docker image on Alpine by copying the decK and jq binaries out of Kong's official image, so the container has a shell and package manager.

content_type: how_to
permalink: /deck/build-non-distroless-docker-image/
breadcrumbs:
  - /deck/

products:
  - gateway

works_on:
  - on-prem
  - konnect

prereqs:
  skip_product: true

tags:
  - docker
  - declarative-config

tldr:
  q: How do I build a decK Docker image that includes a shell?
  a: |
    Copy the `deck` and `jq` binaries out of Kong's official `kong/deck` image and place them on an Alpine base.
    This results in the released binaries with a shell and package manager available inside the container.

related_resources:
  - text: Build a custom {{site.base_gateway}} Docker image
    url: /how-to/build-custom-docker-image/
  - text: Kong decK GitHub repository
    url: https://github.com/Kong/deck
  - text: decK Dockerfile at v1.66.1 (distroless)
    url: https://github.com/Kong/deck/blob/v1.66.1/Dockerfile
  - text: decK changelog
    url: https://github.com/Kong/deck/blob/main/CHANGELOG.md
  - text: kong/deck on Docker Hub
    url: https://hub.docker.com/r/kong/deck

faqs:
  - q: Why does a write operation like `deck gateway dump` fail with a permission error in this image?
    a: |
      The non-distroless decK Docker image runs as UID `65532`. On a Linux host, bind mounts preserve host ownership, so a write operation like `deck gateway dump -o kong.yaml` fails with a permission error on a directory owned by your own user.

      Either make the directory writable by that UID (`chmod a+w .` or `chown 65532 .`), or run as your own user for write operations:
      ```sh
      docker run --rm -u "$(id -u):$(id -g)" -v "$(pwd):/files" -w /files \
        my-org/deck:v1.66.1-alpine gateway dump --kong-addr http://$KONG_HOST:8001 -o kong.yaml
      ```

      On Docker for Mac or Windows this usually isn't needed: bind mounts pass through a VM translation layer that presents the mount as `uid=0` and doesn't enforce host UID ownership, so writes as 65532 succeed anyway.

automated_tests: false
---

Starting in decK v1.65.2, the official `kong/deck` Docker image uses a distroless base. 
This keeps the image small, but the container doesn't have a shell or package manager. 
If these are required, you can build your own image using the steps in this guide.

`deck` is a `CGO_ENABLED=0` static Go binary with no glibc or musl dependency, so you can copy it onto any base image without recompiling anything.

{:.danger}
> A non-distroless image reintroduces a shell and a package manager into a container that frequently carries {{site.konnect_short_name}} or {{site.base_gateway}} admin credentials.
> That widens the attack surface available to anything that gets code execution inside the container, so prefer the stock distroless image unless you specifically need a shell.

## Create a Dockerfile

Kong's official image is multi-arch and already contains both `deck` and `jq` at `/usr/local/bin`. Reference a release tag by digest and copy them onto a full-OS base, rather than building decK from source.

Create `Dockerfile.alpine`, which copies `deck` and `jq` from Kong's official image onto an Alpine base:

```bash
cat <<'EOF' > Dockerfile.alpine
FROM alpine:latest

LABEL org.opencontainers.image.title="deck" \
      org.opencontainers.image.description="Declarative configuration for Kong (non-distroless build)" \
      org.opencontainers.image.url="https://github.com/Kong/deck" \
      org.opencontainers.image.source="https://github.com/Kong/deck" \
      org.opencontainers.image.licenses="Apache-2.0" \
      org.opencontainers.image.vendor="Kong Inc."

USER 65532:65532

# Copy deck and jq straight out of Kong's official image.
COPY --from=kong/deck:v{{ site.data.deck_latest.version }} \
    /usr/local/bin/deck \
    /usr/local/bin/jq \
    /usr/local/bin/

ENTRYPOINT ["deck"]
EOF
```

## Build the image

```sh
docker build \
  -f Dockerfile.alpine \
  -t my-org/deck:v{{ site.data.deck_latest.version }}-alpine .
```

## Validate the image

1. Confirm the version:

   ```sh
   docker run --rm my-org/deck:v{{ site.data.deck_latest.version }}-alpine version
   ```

2. Confirm the shell is present:

   ```sh
   docker run --rm -it --entrypoint sh my-org/deck:v{{ site.data.deck_latest.version }}-alpine
   ```

## Maintenance

The image you build here is not a Kong-published artifact, so you own rebuilding it on every decK release and patching CVEs in whichever base OS you chose.

- Always reference an official `kong/deck` release tag, not a moving tag, so your image matches a released version of decK.
- Never tag a locally built image as `kong/deck:...`. Use your own org/registry namespace so it's clearly distinguished from Kong's official artifact.
