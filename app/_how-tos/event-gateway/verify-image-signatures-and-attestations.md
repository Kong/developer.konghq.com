---
title: Verify {{site.event_gateway}} image signatures and attestations
content_type: how_to

permalink: /event-gateway/verify-image-signatures-and-attestations/

description: "Use Cosign to verify the signature of the {{site.event_gateway}} container image and to inspect the attestations attached to it, including the SBOM and vulnerability scans."

products:
    - event-gateway

works_on:
    - konnect

tools: []

breadcrumbs:
  - /event-gateway/

tags:
    - event-gateway
    - docker
    - security

related_resources:
  - text: "Upgrading {{site.event_gateway_short}}"
    url: /event-gateway/upgrade/
  - text: "{{site.event_gateway_short}} breaking changes and known issues"
    url: /event-gateway/breaking-changes/
  - text: "{{site.event_gateway_short}} known limitations"
    url: /event-gateway/known-limitations/
  - text: "{{site.event_gateway_short}} version support policy"
    url: /event-gateway/version-support-policy/
  - text: "{{site.event_gateway_short}} changelog"
    url: /event-gateway/changelog/

prereqs:
  skip_product: true
  inline:
    - title: Cosign
      position: before
      icon_url: /assets/icons/cosign.svg
      content: |
        {{site.event_gateway}} container images and their attestations are signed using [Cosign](https://github.com/sigstore/cosign).

        Install [Cosign](https://docs.sigstore.dev/cosign/system_config/installation/) **2.4.0 or later** by following the installation instructions for your system. {{site.event_gateway_short}} signatures use the newer Sigstore bundle format (`--new-bundle-format`), which earlier Cosign versions can't verify. Check your version with `cosign version`.

        Unlike some other Kong products, {{site.event_gateway_short}} attestations and signatures are attached directly to the image, so you don't need to set `COSIGN_REPOSITORY`.
    - title: regctl
      position: before
      include_content: prereqs/regctl
      icon_url: /assets/icons/code.svg
    - title: jq
      position: before
      content: |
        You'll use [`jq`](https://jqlang.org/download/) to parse the JSON attestations that Cosign downloads.

tldr:
    q: How do I verify the {{site.event_gateway}} container image and read its SBOM?
    a: |
      {{site.event_gateway}} images are published to `kong/kong-event-gateway` on Docker Hub and signed with [Cosign](https://github.com/sigstore/cosign) using GitHub's OIDC identity.

      List every supply chain artifact attached to an image with `cosign tree kong/kong-event-gateway:VERSION`, verify the image signature with `cosign verify`, and verify or extract individual attestations (SBOM, vulnerability scans) with `cosign verify-attestation`.

automated_tests: false
---

{% assign egw_release = site.data.products["event-gateway"].releases | where: "latest", true | first %}

{{site.event_gateway}} container images are published to [`kong/kong-event-gateway`](https://hub.docker.com/r/kong/kong-event-gateway) on Docker Hub.
Each image is signed with [Cosign](https://github.com/sigstore/cosign) using GitHub's OIDC identity, and a set of attestations (SBOM, vulnerability scans, and more) is attached to it.

{:.warning}
> Image signatures and attestations are only available from {{site.event_gateway_short}} **1.1.1** onwards. Earlier releases have no supply chain artifacts attached, so the commands on this page won't return anything for them.

{:.info}
> The examples below use `kong/kong-event-gateway:{{ egw_release.version }}`. Replace the version with the {{site.event_gateway_short}} release you want to verify.
> The signing identity (`...@refs/tags/v{{ egw_release.version }}`) must match the exact release tag of the image you're verifying, so keep the version consistent between the image and the `--certificate-identity` flag.

## List the artifacts attached to an image

Use `cosign tree` to see every signature and attestation attached to an image:

```sh
cosign tree kong/kong-event-gateway:{{ egw_release.version }}
```

The output lists the supply chain artifacts (signatures and attestations) that are stored alongside the image in the registry.

## Verify the image signature

1. Read the manifest digest for the image with `regctl` and store it in a variable:

    ```sh
    export IMAGE_DIGEST=$(regctl manifest digest kong/kong-event-gateway:{{ egw_release.version }})
    echo $IMAGE_DIGEST
    ```

    This captures the image's `SHA-256` digest so you can reuse it in the commands below, and prints it:

    ```sh
    sha256:...
    ```
    {:.no-copy-code}

    Pinning to a digest guarantees you verify exactly the image you're going to run, even if the tag is later moved to a different image.

1. Verify the signature with `cosign verify`:

    ```sh
    cosign verify \
      --new-bundle-format=true \
      -a repo="kong-gateway/event-gateway" \
      -a workflow="CI" \
      --certificate-oidc-issuer="https://token.actions.githubusercontent.com" \
      --certificate-identity="https://github.com/kong-gateway/event-gateway/.github/workflows/ci.yaml@refs/tags/v{{ egw_release.version }}" \
      kong/kong-event-gateway@${IMAGE_DIGEST}
    ```

    If verification is successful, the response contains a summary of the checks that were performed:

    ```
    Verification for index.docker.io/kong/kong-event-gateway@sha256:... --
    The following checks were performed on each of these signatures:
      - The specified annotations were verified.
      - The cosign claims were validated
      - Existence of the claims in the transparency log was verified offline
      - The code-signing certificate was verified using trusted certificate authority certificates
    ```
    {:.no-copy-code}

## Verify and inspect attestations

{{site.event_gateway}} images carry several signed attestations. The most commonly used predicate types are:

{% table %}
columns:
  - title: Attestation
    key: attestation
  - title: Predicate type
    key: predicate
  - title: "`--type` value"
    key: type
rows:
  - attestation: SPDX SBOM
    predicate: "`https://spdx.dev/Document`"
    type: "`spdxjson`"
  - attestation: CycloneDX SBOM
    predicate: "`https://cyclonedx.org/bom`"
    type: "`cyclonedx`"
  - attestation: Vulnerability scan (SARIF)
    predicate: "`https://cosign.sigstore.dev/sarif/vuln/...`"
    type: "`vuln`"
  - attestation: CIS Docker benchmark
    predicate: "`https://cisecurity.org/docker/...`"
    type: "_(use the full URL)_"
{% endtable %}

{:.info}
> The exact set of attestations can change between releases. Use [`cosign tree`](#list-the-artifacts-attached-to-an-image) to see the authoritative list for the image you're verifying.

To verify an attestation's signature and print its contents, use `cosign verify-attestation` with the matching `--type`. For example, to verify the SPDX SBOM:

```sh
cosign verify-attestation \
  --type="spdxjson" \
  --certificate-oidc-issuer="https://token.actions.githubusercontent.com" \
  --certificate-identity="https://github.com/kong-gateway/event-gateway/.github/workflows/ci.yaml@refs/tags/v{{ egw_release.version }}" \
  kong/kong-event-gateway@${IMAGE_DIGEST}
```

For predicate types that don't have a built-in alias, pass the full predicate type URL to `--type` instead, for example `--type="https://cisecurity.org/docker/amd64"`.

## Extract the SBOM

To save the SPDX SBOM to a file, download the attestations and filter for the SBOM predicate type with `jq`:

```sh
cosign download attestation kong/kong-event-gateway@${IMAGE_DIGEST} \
  | jq -r 'select((.dsseEnvelope.payload // .payload | @base64d | fromjson | .predicateType) == "https://spdx.dev/Document") | (.dsseEnvelope.payload // .payload) | @base64d | fromjson | .predicate' \
  > sbom.spdx.json
```

This writes the SBOM document to `sbom.spdx.json`, which you can then feed into your SBOM tooling. To extract the CycloneDX SBOM instead, replace the predicate type with `https://cyclonedx.org/bom`.

## Validate the extracted SBOM

Confirm that the extracted file is valid JSON and contains the expected SPDX fields:

```sh
jq -e '.spdxVersion and (.packages | length > 0)' sbom.spdx.json \
  && echo "Valid SPDX SBOM with $(jq '.packages | length' sbom.spdx.json) packages"
```

If the file is a well-formed SPDX SBOM, the command prints `true` followed by the package count. If `jq` reports a parse error or the expression evaluates to `false`, the download or filter step didn't produce a valid document. Re-check the predicate type and confirm the previous commands completed successfully.
