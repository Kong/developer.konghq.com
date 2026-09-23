---
title: Build a non-distroless decK Docker image
description: Build a decK Docker image on Alpine by copying the decK and jq binaries out of Kong's official image, so the container has a shell and package manager.

content_type: how_to
permalink: /deck/build-non-distroless-docker-image/
breadcrumbs:
  - /deck/

products:
  - gateway

tools:
  - deck

works_on:
  - on-prem
  - konnect

tags:
  - docker
  - declarative-config

tldr:
  q: How do I build a decK Docker image that includes a shell?
  a: |
    Copy the `deck` and `jq` binaries out of Kong's official `kong/deck` image and place them on an Alpine base.
    The result is the released binaries with a shell and package manager available inside the container.

related_resources:
  - text: Use the decK Docker container
    url: /support/how-to-use-the-deck-with-container/
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

prereqs:
  skip_product: true
  inline:
    - title: Docker Buildx
      content: |
        This guide requires [Docker Buildx](https://docs.docker.com/build/concepts/overview/), which is bundled with recent Docker Desktop releases or installed separately as the `docker-buildx-plugin` package.
    - title: Network access to Docker Hub
      content: |
        The build pulls both the official `kong/deck` image and the Alpine base image from Docker Hub.

automated_tests: false
---

The official `kong/deck` Docker image uses a distroless base starting with v1.65.2. This keeps the image small, but the container has no shell and no package manager. If required, you can build your own image using the steps in this guide.

`deck` is a `CGO_ENABLED=0` static Go binary with no glibc or musl dependency, so you can copy it onto any base image without recompiling anything.

{:.warning}
> A non-distroless image reintroduces a shell and a package manager into a container that frequently carries {{site.konnect_short_name}} or {{site.base_gateway}} admin credentials.
> That widens the attack surface available to anything that gets code execution inside the container, so prefer the stock distroless image unless you specifically need a shell.

## Create a Dockerfile

Kong's official image is multi-arch and already contains both `deck` and `jq` at `/usr/local/bin`. Reference a release tag by digest and copy them onto a full-OS base, rather than building decK from source.

Create `Dockerfile.alpine` using the following as a reference.

```dockerfile
FROM alpine:3.24.2@sha256:294b683cb724975bec92580e1e685676bd4b50bda910ddb8c51d4cabeaec77e6

LABEL org.opencontainers.image.title="deck" \
      org.opencontainers.image.description="Declarative configuration for Kong (non-distroless build)" \
      org.opencontainers.image.url="https://github.com/Kong/deck" \
      org.opencontainers.image.source="https://github.com/Kong/deck" \
      org.opencontainers.image.licenses="Apache-2.0" \
      org.opencontainers.image.vendor="Kong Inc."

USER 65532:65532

# Copy deck and jq straight out of Kong's official image.
COPY --from=kong/deck:v1.66.1@sha256:0cc102cfc074abb865dcaf9222228176c39e548bb01ed7893f07c1c3adc298d6 \
     /usr/local/bin/deck \
     /usr/local/bin/jq \
     /usr/local/bin/

ENTRYPOINT ["deck"]
```

No packages are installed: Alpine already ships `/bin/sh`, `apk`, and `ca-certificates-bundle`, so TLS to the Kong Admin API or {{site.konnect_short_name}} works as-is. `USER 65532:65532` reuses the distroless base's non-root UID, which also means `apk add` at runtime needs `docker run -u 0`.

Pin both images by digest, since the version tags are mutable:

```sh
docker buildx imagetools inspect kong/deck:v1.66.1 --format '{% raw %}{{.Manifest.Digest}}{% endraw %}'
# then: COPY --from=kong/deck:v1.66.1@sha256:<digest> ...

docker buildx imagetools inspect alpine:3.24.2 --format '{% raw %}{{.Manifest.Digest}}{% endraw %}'
# then: FROM alpine:3.24.2@sha256:<digest>
```

In `name:tag@sha256:...`, the digest wins and the tag is decorative, so update both together when you bump either image.

## Build the image

For a single architecture:

```sh
docker build \
  -f Dockerfile.alpine \
  -t my-org/deck:v1.66.1-alpine .
```

If you're replacing the official image across a mixed-arch fleet, build the same Dockerfile with Buildx to match Kong's platform coverage:

```sh
docker buildx build \
  --platform linux/amd64,linux/arm64,linux/arm/v7 \
  -f Dockerfile.alpine \
  -t <your-registry>/deck:v1.66.1-alpine \
  --push .
```

Log in to `<your-registry>` with `docker login` first. A multi-platform result can't be loaded into the default local image store, hence `--push`. If you've enabled the containerd image store, `--load` works instead.

Because the Dockerfile has no `RUN` instruction, nothing executes inside the target rootfs (BuildKit performs the `COPY` on the host), so cross-building needs no QEMU emulation regardless of your host architecture. Adding a `RUN` changes that: `apk add --no-cache bash` for a richer shell, or `ca-certificates` for `update-ca-certificates` to trust a private CA, will execute on the target platform and cross-builds will then need emulation registered.

## Validate the image

Confirm the version:

```sh
docker run --rm my-org/deck:v1.66.1-alpine version
```

Confirm the shell is present. This is what fails against stock `kong/deck` v1.65.2 and later, which has no `sh`, `bash`, or `ash`:

```sh
docker run --rm -it --entrypoint sh my-org/deck:v1.66.1-alpine
# should drop you into an interactive shell as UID 65532
```

Confirm the image can reach your Kong Admin API, and that decK itself works against it:

```sh
docker run --rm --entrypoint sh my-org/deck:v1.66.1-alpine \
  -c "wget -q -O- http://<kong-host>:8001/ && echo OK"

docker run --rm my-org/deck:v1.66.1-alpine \
  gateway ping --kong-addr http://<kong-host>:8001
```

## Run decK with a declarative configuration

To run decK with a declarative configuration, mount your `kong.yaml` and set a working directory:

```sh
docker run --rm \
  -v "$(pwd):/files" \
  -w /files \
  my-org/deck:v1.66.1-alpine \
  gateway sync \
  --kong-addr http://<kong-host>:8001 \
  kong.yaml
```

The container runs as UID 65532. On a Linux host, bind mounts preserve host ownership, so commands that write to the mount, for example `deck gateway dump -o kong.yaml`, fail with a permission error on a directory owned by your user. Either make the directory writable by that UID (`chmod a+w .` or `chown 65532 .`), or run as your own user for write operations:

```sh
docker run --rm -u "$(id -u):$(id -g)" -v "$(pwd):/files" -w /files \
  my-org/deck:v1.66.1-alpine gateway dump --kong-addr http://<kong-host>:8001 -o kong.yaml
```

On Docker for Mac or Windows this usually isn't needed: bind mounts pass through a VM translation layer that presents the mount as `uid=0` and doesn't enforce host UID ownership, so writes as 65532 succeed anyway.

## Maintenance

This is not a Kong-published artifact, so you own rebuilding it on every decK release and patching CVEs in whichever base OS you chose.

- Always reference an official `kong/deck` release tag, not a moving tag, so your image matches a released version of decK.
- Bump the `kong/deck` tag and digest together to pick up a new decK release.
- Keep every base image pinned by digest and update the tag and digest together. The digest wins, so a stale digest silently pins an old image.
- Match upstream's platform list (`linux/amd64`, `linux/arm64`, `linux/arm/v7`) if you're replacing the official image for a mixed fleet.
- Never tag a locally built image as `kong/deck:...`. Use your own org/registry namespace so it's clearly distinguished from Kong's official artifact.
