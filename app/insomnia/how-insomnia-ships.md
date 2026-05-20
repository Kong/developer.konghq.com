---
title: Insomnia release and versioning policy
content_type: reference
layout: reference
breadcrumbs:
  - /insomnia/

products:
  - insomnia

search_aliases:
  - updates
  - releases

description: How Insomnia releases new versions, with recommendations for updating.

related_resources:
  - text: Stages of software availability
    url: /stages-of-software-availability/

---

## Overview

Insomnia uses [semantic versioning](https://semver.org/), a three-part number format: MAJOR.MINOR.PATCH (for example `2.5.1`) for defining versions. 

Insomnia communicates all changes via:

- A [changelog](https://insomnia.rest/changelog).

- The [GitHub releases page](https://github.com/kong/insomnia/releases).

Public documentation updates support the latest versions of Insomnia.

## Release types

- **Generally Available (GA)**: Released to all users.
- **Beta**: A 7-day period before GA when users can opt in to test the release and provide early feedback. Opt in via **Settings > Release Channel** in the Insomnia app.
- **Preview** or **Tech Preview**: Features that are ready to use but still in active development. Preview features are clearly marked in the product.

### Recommendations

Insomnia strongly recommends using the newest version, and that all users collaborating on the same project remain on the same major version.

## Long Term Support (LTS)

Insomnia doesn't have an explicit Long Term Support (LTS) policy, nor does it publish LTS versions.  



## Backports

Fixes and changes don't backport to earlier versions. Best practice is to upgrade to the latest version.
Insomnia doesn't roll new or modified features into prior versions except in extraordinary circumstances, at our sole discretion.

## Types of Versions

{% table %}
columns:
  - title: Version
    key: version
  - title: When
    key: time
  - title: Content
    key: content
  - title: Recommendations
    key: recommendation
rows:
  - version: "Major (ex: v12)"
    time: |
      - Twice a year
      - Beta for 7 days before GA
    content: |
      - New features
      - Bug fixes
      - Architecture improvements
      - Changes or fixes that aren't backwards compatible.
    recommendation: |
      - Test the beta first to ensure compatibility.
      - Backup your work before updating.
  - version: "Minor (ex: v12.1)"
    time: "Approximately every three weeks"
    content: "Changes that are always compatible across its parent major version"
    recommendation: "Usually automated migrations, but manual migrations may be necessary on some releases."
  - version: "Patch (ex: v12.1.1)"
    time: "When needed on a minor version"
    content: |
      Only:

      - Defect fixes
      - Security patches
      - Other maintenance work
{% endtable %}



## Major version changes

Insomnia ships a major version when the release contains breaking changes. Breaking changes count as anything that, for the majority of users, could cause an existing workflow, configuration, or integration to stop working after the upgrade.


For example:

- Removing a request type, protocol, or authentication method.
- Removing or renaming a CLI command, flag, or subcommand.
- Changing the export schema for collections or environments in a way that older versions can't read.
- Dropping support for an operating system, platform, or runtime.
- Changing the plugin API in a way that breaks existing plugins.
- Removing or renaming a public API endpoint.
- Changing the default behavior of a feature in a way that affects existing users.
- Migrating the underlying data store to a format that can't be rolled back to a prior version.
- Removing a UI panel, tab, or workflow that users actively rely on.

## Minor version changes

Insomnia ships a minor version when a release adds new functionality that's fully backwards-compatible with the previous version.

For example:

- Adding a new request type, protocol, or authentication method.
- Adding a new CLI command, flag, or subcommand.
- Introducing a new UI panel, tab, or workflow.
- Adding new fields or options to the collection or environment export format, without changing existing fields.
- Adding a new plugin hook, or extending the plugin API in a way that doesn't break existing plugins.
- Adding support for a new operating system or platform.
- Deprecating a feature, command, or API without removing it.
- Adding new environment variable types or template tag functions.
- Adding a new integration, such as a Git provider or CI/CD tool.
- Adding new configuration options or preferences.

## Patch version changes

Insomnia ships a patch version when a release contains only backwards-compatible bug fixes, corrections that make Insomnia behave the way it was already documented or intended to behave.

Examples include:

- Fixing a crash or hang during request execution.
- Correcting response rendering or syntax highlighting errors.
- Fixing import or export errors that prevented valid collections from loading.
- Fixing authentication flows that didn't complete correctly.
- Fixing environment variable resolution or template tag evaluation.
- Correcting UI rendering glitches or layout issues.
- Resolving sync or collaboration conflicts, including data loss scenarios.
- Patching security vulnerabilities in bundled dependencies, with no user-facing behavior change.
- Fixing incorrect HTTP header handling or encoding.
- Correcting documentation links or in-app help text.

## Types of Releases

- Generally Available (GA): Available to anyone.
- Beta: Generally a 7\-day period before GA where clients can opt in (via Settings -> Release Channel in the app) and provide early [feedback](#user-feedback).

## Feedback

Users can provide feedback depending on the type of plan they are on:

- **Essential:** file GitHub issues for defects or ideas.
- **Pro** and **Enterprise:** reach out to support@insomnia.rest for support.
- **Enterprise** only: send feedback to your CSM or through whatever normal cadences you have with Kong/Insomnia.

## Disclaimer

Insomnia reserves the right to act and ship, however, and whenever the team deems necessary in the interests of the security and stability of products and customers. 

However, Insomnia recognizes the risk and pain that significant or breaking changes offer to customers, and strives to minimize that at all times via the previous guidelines.


