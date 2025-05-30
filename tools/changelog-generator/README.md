# changelog-generator

Generate Gateway's changelog based on the entries defined in `kong-ee` repo and extra entries defined in `./missing_entries`.

## How it works

There are three stages to the process:

1. Generate temp files for new versions.
2. Set the release date for the release in `app/_data/products/gateway.yml`.
3. Merge the existing changelog file (`app/_data/changelog/gateway.json`) with the temp files generated in the previous step.

## How to run it

`changelog-generator` requires `kong-ee` to be available locally.
From the root of your clone of the dev site repo run the following commands to install the dependencies:

```bash
cd tools/changelog-generator
npm ci
```

### Generate temp files for specific versions

To generate a temp file for a specific version run:

```bash
cd tools/changelog-generator
node run.js --path='../../../kong-ee' --version='3.10.0.2'
```

where:

* `path`: is the relative path to the `kong-ee` repo.
* `version`: the version for which to generate the temp changelog file.

This creates a `./tmp/3.10.0.2.json` file containing all the changelog entries for that version.
Note: the `./tmp` folder was added to `gitignore`.

### Generate/update the changelog

There are 3 folders and one file involved in the process:

* `missing_changelogs`: contains changelog files for versions that don't have entries in `kong-ee`. These versions were generated before the new changelog process was created, so we don't have files for these entries.
* `missing_entries`:  entries that don't exist in `kong-ee` that we used to manually add to the changelog, e.g. `Known issues`.
* `tmp`: contanins changelog files generated from entries defined in `kong-ee`
* `app/_data/changelogs/gateway.json`: the actual changelog file generated from all of the above.

To generate the changelog file run:

```bash
node changelog.js
```

This script will load the existing `app/_data/changelogs/gateway.json` and:

* read `missing_changelogs` and update the existing changelog file with the missing versions.
* read `missing_entries` and update the existing changelog file with the missing entries.
* remove any duplicate entries by comparing their `message`.

### Updating the changelog when there's a new release

1. Make sure that your local copy of `kong-ee` is up to date and in the right branch (if it's a patch release).
1. Run `node run.js --path='../../../kong-ee' --version='<version>'` to generate the temp file.
1. Run `node changelog.js` to update the changelog.