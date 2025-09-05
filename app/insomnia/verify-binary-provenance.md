---
title: Verifying build provenance for signed Insomnia binaries

description: Kong produces build provenance for Insomnia application binary artifacts, which can be verified.

content_type: reference
layout: reference

products:
    - insomnia

breadcrumbs:
  - /insomnia/

related_resources:
  - text: Insomnia security
    url: /insomnia/manage-insomnia/#security

---

Kong produces build provenance for Insomnia application binary artifacts, which can be verified using `cosign` / `slsa-verifier`.

This guide provides steps to verify build provenance for signed Insomnia application binary artifacts in two different ways:

* A minimal example, used to verify an binary artifacts without leveraging any annotations
* A complete example, leveraging optional annotations for increased trust

For the minimal example, you only need a compressed binary file(s) and provenance file.

For the complete example, you need the same details as the minimal example, as well as any of the optional annotations you wish to verify:

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
  - shorthand: "`VERSION`"
    description: Artifact version to download
    example: "`11.3.0`"
  - shorthand: "`BINARY_FILES`"
    description: Single space separated Insomnia binary files
    example: "`Insomnia.Core-11.3.0.{snap,tar.gz,zip,rpm,dmg,deb,exe,AppImage}`"
  - shorthand: "`PROVENANCE_FILE`"
    description: Binary provenance file
    example: "`inso-provenance.intoto.jsonl`"
{% endtable %}

Because Kong uses GitHub Actions to build and release, Kong also uses GitHub's OIDC identity to generate build provenance for binary artifacts, which is why many of these details are GitHub-related.

## Prerequisites

For both examples, you need to:

* Ensure `slsa-verifier` is installed.
* [Download Insomnia core application binaries](https://updates.insomnia.rest/downloads/release/latest?app=com.insomnia.app&channel=stable) with the file pattern `Insomnia.Core-$VERSION.{snap,tar.gz,zip,rpm,dmg,deb,exe,AppImage}`
* [Download Insomnia binary provenance attestation](https://updates.insomnia.rest/downloads/release/latest?app=com.insomnia.app&channel=stable) with the pattern `insomnia-provenance.intoto.jsonl`

{:.warning}
> The GitHub owner is case-sensitive (`Kong/insomnia` vs `kong/insomnia`).

## Minimal example

Run the `slsa-verifier verify-artifact` command:

```sh
slsa-verifier verify-artifact \
   --print-provenance \
   --provenance-path '$PROVENANCE_FILE' \
   --source-uri 'github.com/Kong/$REPO' \
   $BINARY_FILES
```

The command will print "Verified SLSA provenance" if successful:

```sh
...
PASSED: Verified SLSA provenance
```

## Complete example


Run the `slsa-verifier verify-artifact` command:

```sh
slsa-verifier verify-artifact \
   --print-provenance \
   --provenance-path '$PROVENANCE_FILE' \
   --source-uri 'github.com/Kong/$REPO' \
   --build-workflow-input 'version=$VERSION' \
   $BINARY_FILES
```