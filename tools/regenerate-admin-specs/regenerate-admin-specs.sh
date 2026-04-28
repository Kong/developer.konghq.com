#!/usr/bin/env bash
# regenerate-admin-specs.sh
#
# Generates the Kong Gateway Admin API OpenAPI spec for one or more versions
# and copies the result into the correct directory in this repo.
#
# Usage:
#   ./tools/regenerate-admin-specs/regenerate-admin-specs.sh [versions...] [image:tag]
#
# Examples:
#   ./tools/regenerate-admin-specs/regenerate-admin-specs.sh 3.13
#   ./tools/regenerate-admin-specs/regenerate-admin-specs.sh 3.11 3.12 3.13
#   ./tools/regenerate-admin-specs/regenerate-admin-specs.sh 3.13 kong-gateway-dev:3.13.0.0
#
# Must be run from the developer.konghq.com repo root.
# Requires Docker to be running and port 8001 to be free before each version.
# Requires kong-admin-spec-generator to be cloned as a sibling of this repo.

set -euo pipefail

DOCS_REPO="$(git rev-parse --show-toplevel)"
GENERATOR_DIR="$(dirname "$DOCS_REPO")/kong-admin-spec-generator"

# ---------------------------------------------------------------------------
# Validate environment
# ---------------------------------------------------------------------------

if [[ ! -d "$GENERATOR_DIR" ]]; then
    echo "ERROR: generator repo not found at $GENERATOR_DIR"
    echo "Clone kong-admin-spec-generator as a sibling of this repo and try again."
    exit 1
fi

if [[ $# -eq 0 ]]; then
    echo "Usage: $0 [versions...] [image:tag]"
    echo "Example: $0 3.13"
    echo "Example: $0 3.11 3.12 3.13"
    echo "Example: $0 3.13 kong-gateway-dev:3.13.0.0"
    exit 1
fi

# ---------------------------------------------------------------------------
# Parse args: separate versions from optional image:tag
# ---------------------------------------------------------------------------

VERSIONS=()
CUSTOM_IMAGE=""

for arg in "$@"; do
    if [[ "$arg" == *:* ]]; then
        CUSTOM_IMAGE="$arg"
    else
        VERSIONS+=("$arg")
    fi
done

if [[ ${#VERSIONS[@]} -eq 0 ]]; then
    echo "ERROR: no versions specified"
    exit 1
fi

echo "Generator: $GENERATOR_DIR"
echo "Docs repo: $DOCS_REPO"
echo "Versions:  ${VERSIONS[*]}"
if [[ -n "$CUSTOM_IMAGE" ]]; then
    echo "Image:     kong/$CUSTOM_IMAGE"
fi
echo ""

# ---------------------------------------------------------------------------
# Process each version
# ---------------------------------------------------------------------------

CHANGED=()
UNCHANGED=()
SKIPPED=()

for VERSION in "${VERSIONS[@]}"; do
    echo "===== $VERSION ====="
    DEST="$DOCS_REPO/api-specs/gateway/admin-ee/$VERSION/openapi.yaml"

    if [[ -n "$CUSTOM_IMAGE" ]]; then
        DOCKER_IMAGE="kong/$CUSTOM_IMAGE"
    else
        DOCKER_IMAGE="kong/kong-gateway:$VERSION"
    fi

    # setup
    echo "Running setup with $DOCKER_IMAGE ..."
    if ! DOCKER_IMAGE="$DOCKER_IMAGE" make -C "$GENERATOR_DIR" setup-kong; then
        echo "WARN: setup failed for $VERSION — skipping"
        SKIPPED+=("$VERSION (setup failed)")
        continue
    fi

    # generate
    echo "Running make kong ..."
    if ! make -C "$GENERATOR_DIR" kong; then
        echo "WARN: make kong failed for $VERSION — cleaning and skipping"
        make -C "$GENERATOR_DIR" clean || true
        SKIPPED+=("$VERSION (make kong failed)")
        continue
    fi

    GENERATED="$GENERATOR_DIR/work/openapi.yaml"

    # diff and copy before clean
    if [[ ! -f "$DEST" ]]; then
        echo "No existing spec at $DEST — copying as new file"
        mkdir -p "$(dirname "$DEST")"
        cp "$GENERATED" "$DEST"
        CHANGED+=("$VERSION (new file)")
    elif diff -q "$GENERATED" "$DEST" > /dev/null 2>&1; then
        echo "Spec is already up to date for $VERSION"
        UNCHANGED+=("$VERSION")
    else
        echo "Changes detected for $VERSION — updating spec"
        diff "$GENERATED" "$DEST" || true   # show diff; diff exits 1 on changes
        cp "$GENERATED" "$DEST"
        CHANGED+=("$VERSION")
    fi

    # clean
    make -C "$GENERATOR_DIR" clean

    echo ""
done

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------

echo "===== Summary ====="

if [[ ${#CHANGED[@]} -gt 0 ]]; then
    echo "Updated specs:"
    for v in "${CHANGED[@]}"; do echo "  - $v"; done
fi

if [[ ${#UNCHANGED[@]} -gt 0 ]]; then
    echo "Already up to date:"
    for v in "${UNCHANGED[@]}"; do echo "  - $v"; done
fi

if [[ ${#SKIPPED[@]} -gt 0 ]]; then
    echo "Skipped:"
    for v in "${SKIPPED[@]}"; do echo "  - $v"; done
fi

