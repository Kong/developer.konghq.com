# kong-harnesses changelog

Generates `app/_changelogs/kong-harnesses.json`, the data behind the [kong-harnesses changelog page](../../app/kong-harnesses/changelog.md), from the release-please `CHANGELOG.md` of the private `Kong/kong-harnesses` repository.

The [`generate-kong-harnesses-changelog`](../../.github/workflows/generate-kong-harnesses-changelog.yml) workflow runs the script on manual dispatch. It checks out the private repository with the Kong docs GitHub App token (`GH_APP_KONG_DOCS_ID`), regenerates the JSON, and opens a pull request.

You can also run the script by hand.

## How it works

The script reads one release-please Markdown file and writes one JSON file. There is no intermediate format. It:

1. Parses each `## [<version>](<url>) (<date>)` heading as a version.
2. Keeps only versions greater than or equal to the floor.
3. Skips any heading whose version contains a `-`, such as a prerelease.
4. Groups each bullet under its section, and maps the section to a type key.
5. Strips the trailing PR and commit reference chain from each message, and keeps the bold `**scope:**` prefix.
6. Removes duplicate messages within a version and type.
7. Writes the versions newest-first to `app/_changelogs/kong-harnesses.json`.

### Section to type mapping

| Markdown section | Type key |
|---|---|
| `### Features` | `feature` |
| `### Bug Fixes` | `bugfix` |
| `### Performance` | `performance` |
| `### ⚠ BREAKING CHANGES` | `Breaking Change` |

An unknown section passes through in lower case, so the drop sorts it last under `app/_changelogs/config.yaml`.

### Release dates

The JSON holds no release dates. The [drop](../../app/_plugins/drops/tool_changelog.rb) reads each date from `release_dates` in `app/_data/tools/kong-harnesses.yml`, which [`syncReleases`](../lib/tool-versions.js) writes from the releases API.

## How to run it

The repository is private, so you need a token with read access.

```sh
cd tools/kong-harnesses-changelog

# Fetch the private repository. gh auth token supplies a token for a logged-in
# gh session.
git clone --depth 1 \
  "https://x-access-token:$(gh auth token)@github.com/Kong/kong-harnesses.git" \
  /tmp/kong-harnesses

node generate.js --input=/tmp/kong-harnesses/CHANGELOG.md

# Override the floor (default 0.18.0):
node generate.js --input=/tmp/kong-harnesses/CHANGELOG.md --min-version=0.19.0

# Write somewhere other than app/_changelogs/kong-harnesses.json:
node generate.js --input=/tmp/kong-harnesses/CHANGELOG.md --output=/tmp/kong-harnesses.json
```

Options:

| Option | Default | Purpose |
|---|---|---|
| `--input` | `CHANGELOG.md` | Path to the release-please changelog. |
| `--output` | `app/_changelogs/kong-harnesses.json` | Path to write the JSON. |
| `--min-version` | `0.18.0` | Lowest version to include. |

Commit the generated `app/_changelogs/kong-harnesses.json`.

The floor is a constant in `generate.js` and the default of the `min_version` workflow input. When `Kong/kong-harnesses` becomes public and its history re-bases, change both in one commit.

## Tests

```sh
npm test
```

The tests in `test/generate.test.js` cover the heading parse, the section map, the reference strip, the floor, version compare, prerelease skip, dedupe, unknown-section pass-through, and idempotent output, without the network.
