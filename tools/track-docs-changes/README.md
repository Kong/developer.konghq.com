# track-docs-changes

A tool to track  changes made to files in https://github.com/Kong/docs.konghq.com, which are used as the source for dev site pages.

## How it works

1. Read `./config/sources.yml` to build a mapping of the files in the docs repo that serve as the source for dev site pages.
2. Check for changes made to the source files in the docs repository (specify the relative path to the docs repository using the environment variable `DOCS_PATH`) over the past `DAYS_TO_CHECK_FOR_DOCS_CHANGES` days.
3. For each dev site page specified in `./config/sources.yml`, it outputs:
   * The file path corresponding to each source in the docs repository.
   * For each source, a link to the pull requests (PRs) that modified it within the specified date range.

## How to run it

In the current directory:

``` bash
npm ci
DOCS_PATH='<relative path to docs repo>' node index.js
```
