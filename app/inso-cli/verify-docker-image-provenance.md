---
title: Verifying build provenance for signed Inso CLI binaries

description: Kong produces build provenance for Inso CLI Docker images artifacts, which can be verified.

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
  - text: Verify signatures for signed Inso CLI Docker images
    url: /inso-cli/verify-docker-image-signature/
---

Kong produces build provenance for Inso CLI docker container images, which can be verified using `cosign` or `slsa-verifier` with attestations published to a Docker Hub repository.

This guide provides steps to verify build provenance for signed Inso CLI Docker images in two different ways:

* A minimal example, used to verify an image without leveraging any annotations
* A complete example, leveraging optional annotations for increased trust

For the minimal example, you only need a Docker manifest digest and a GitHub repo name.

{:.warning}
> The Docker manifest digest is required for build provenance verification. The manifest digest can be different from the platform-specific image digest for a specific distribution.

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
  - shorthand: "`WORKFLOW_NAME`"
    description: GitHub workflow name 
    example: "`Release Publish`"
  - shorthand: "`WORKFLOW_TRIGGER`"
    description: GitHub workflow trigger name 
    example: "`workflow_dispatch`"
  - shorthand: "`TAG`"
    description: Docker image tag
    example: "`11.3.0`"
  - shorthand: "`VERSION`"
    description: Inso CLI version
    example: "`11.3.0`"
{% endtable %}

Because Kong uses GitHub Actions to build and release, Kong also uses GitHub's OIDC identity to generate build provenance for images, which is why many of these details are GitHub-related.

## Prerequisites

For both examples, you need to:

* Ensure [`cosign`](https://docs.sigstore.dev/cosign/system_config/installation/) or [`slsa-verifier` is installed](https://github.com/slsa-framework/slsa-verifier?tab=readme-ov-file#installation).

* Ensure `regctl` is installed.

* Collect the necessary image details.

* Parse the manifest digest for the image using `regctl`.

   ```sh
   IMAGE_DIGEST=$(regctl manifest digest kong/inso:9.3.0)
   ```

* Set the `COSIGN_REPOSITORY` environment variable:

   ```sh
   export COSIGN_REPOSITORY=kong/notary
   ```

{:.warning}
> The GitHub owner is case-sensitive (`Kong/insomnia` vs `kong/insomnia`).

## Minimal example

{% navtabs "verify" %}

{% navtab "slsa-verifier" %}
Run the `slsa-verifier verify-image` command:

```sh
slsa-verifier verify-image \
   kong/inso:$TAG@${IMAGE_DIGEST} \
   --print-provenance \
   --provenance-repository kong/notary \
   --source-uri 'github.com/Kong/$REPO'
```

The command will print "Verified SLSA provenance" if it's successful:

```sh
...
PASSED: Verified SLSA provenance
```
{% endnavtab %}

{% navtab "cosign" %}
Run the `cosign verify-attestation` command:

```sh
cosign verify-attestation \
   kong/inso:$TAG@${IMAGE_DIGEST} \
   --type='slsaprovenance' \
   --certificate-oidc-issuer='https://token.actions.githubusercontent.com' \
   --certificate-identity-regexp='^https://github.com/slsa-framework/slsa-github-generator/.github/workflows/generator_container_slsa3.yml@refs/tags/v[0-9]+.[0-9]+.[0-9]+$'
```

The command will exit with `0` when the `cosign` verification is completed:

```sh
...
echo $?
0
```
{% endnavtab %}
{% endnavtabs %}

## Complete example

{% navtabs "verify" %}

{% navtab "slsa-verifier" %}
Run the `slsa-verifier verify-image` command:

```sh
slsa-verifier verify-image \
   kong/inso:$TAG@${IMAGE_DIGEST} \
   --print-provenance \
   --provenance-repository kong/notary \
   --build-workflow-input 'version=$VERSION' \
   --source-uri 'github.com/Kong/$REPO'
```
{% endnavtab %}

{% navtab "cosign" %}
Run the `cosign verify-attestation` command:

```sh
cosign verify-attestation \
   kong/inso:$TAG@${IMAGE_DIGEST} \
   --type='slsaprovenance' \
   --certificate-oidc-issuer='https://token.actions.githubusercontent.com' \
   --certificate-identity-regexp='^https://github.com/slsa-framework/slsa-github-generator/.github/workflows/generator_container_slsa3.yml@refs/tags/v[0-9]+.[0-9]+.[0-9]+$' \
   --certificate-github-workflow-repository='Kong/$REPO' \
   --certificate-github-workflow-name='$WORKFLOW_NAME' \
   --certificate-github-workflow-trigger='$WORKFLOW_TRIGGER'
```
{% endnavtab %}
{% endnavtabs %}