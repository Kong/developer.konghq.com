---
title: Verify signatures for signed Inso CLI Docker images

description: Inso CLI Docker container images are signed using cosign with signatures published to a Docker Hub repository.

content_type: reference
layout: reference

products:
    - insomnia

breadcrumbs:
  - /inso-cli/
  - /how-to/run-inso-cli-on-docker/

related_resources:
  - text: Insomnia security
    url: /insomnia/manage-insomnia/#security
  - text: Run Inso CLI on Docker
    url: /how-to/run-inso-cli-on-docker/
  - text: kong/inso on Docker Hub
    url: https://hub.docker.com/r/kong/inso
  - text: Verifying build provenance for signed Inso CLI docker images
    url: /inso-cli/verify-docker-image-provenance/
---

Inso CLI Docker container images are signed using `cosign` with signatures published to a Docker Hub repository.

This guide provides steps to verify signatures for signed Inso CLI Docker container images in two different ways:

* A minimal example, used to verify an image without leveraging any annotations
* A complete example, leveraging optional annotations for increased trust

For the minimal example, you only need Docker image details, a GitHub repo name, and a GitHub workflow filename.

For the complete example, you need the same details as the minimal example, as well as any of the optional annotations you want to verify:

{% table %}
columns:
  - title: Shorthand
    key: shorthand
  - title: Description
    key: description
  - title: Example Value
    key: example
rows:
  - shorthand: "`REPO`"
    description: GitHub repository
    example: "`insomnia`"
  - shorthand: "`WORKFLOW_FILENAME`"
    description: GitHub workflow filename 
    example: "`release-publish.yml`"
  - shorthand: "`WORKFLOW_NAME`"
    description: GitHub workflow name 
    example: "`Release Publish`"
  - shorthand: "`TAG`"
    description: Docker image tag
    example: "`11.3.0`"
{% endtable %}

Because Kong uses GitHub Actions to build and release, Kong also uses GitHub's OIDC identity to sign images, which is why many of these details are GitHub-related.

## Prerequisites

For both examples, you need to:

* Ensure [`cosign` is installed](https://docs.sigstore.dev/cosign/system_config/installation/).

* Collect the necessary image details.

* Set the `COSIGN_REPOSITORY` environment variable:

   ```sh
   export COSIGN_REPOSITORY=kong/notary
   ```

* Parse the image manifest digest
    ```sh
   IMAGE_DIGEST=$(regctl manifest digest kong/inso:$TAG)
   ```

{:.warning}
> GitHub owner is case-sensitive (`Kong/insomnia` vs `kong/insomnia`).

## Minimal example

Run the `cosign verify` command:

```sh
cosign verify \
   kong/inso:$TAG@${IMAGE_DIGEST} \
   --certificate-oidc-issuer='https://token.actions.githubusercontent.com' \
   --certificate-identity-regexp='https://github.com/Kong/$REPO/.github/workflows/$WORKFLOW_FILENAME'
```

## Complete example

Run the `cosign verify` command:

```sh
cosign verify \
   kong/inso:$TAG@${IMAGE_DIGEST} \
   --certificate-oidc-issuer='https://token.actions.githubusercontent.com' \
   --certificate-identity-regexp='https://github.com/Kong/$REPO/.github/workflows/$WORKFLOW_FILENAME' \
   -a repo='Kong/$REPO' \
   -a workflow='$WORKFLOW_NAME'
```