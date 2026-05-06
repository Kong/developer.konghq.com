---
title: How Insomnia ships software
content_type: reference
layout: reference
breadcrumbs:
  - /insomnia/

products:
  - insomnia

search_aliases:
  - updates
  - releases
  - inso

description: How Insomnia releases new versions, with recommendations for updating.

related_resources:
  - text: Stages of software availability
    url: /stages-of-software-availability/

---

## Overview

In general, Insomnia follows [semantic versioning](https://semver.org/), a three-part number format: MAJOR.MINOR.PATCH (for example `2.5.1`).

Insomnia communicates all changes via:

- A [changelog](https://insomnia.rest/changelog).

- The [GitHub releases page](https://github.com/kong/insomnia/releases).

Public documentation updates support all versions of Insomnia.

## When to update

Update as often as you like, or stay on a past version. Unless you have a specific reason, the best practice is to use the newest version.

### Recommendations

Insomnia strongly recommends that all users collaborating on the same project remain on the same major version as often as possible.

## Long Term Support (LTS)

Insomnia doesn't have an explicit Long Term Support (LTS) policy, nor does it publish LTS versions.  

### Versions within the last 12 months

Insomnia's team investigates and debug support issues or bugs filed based on any version from the last 12 months. In some cases, upgrading may be necessary to complete the investigation. 

### Versions older than 12 months

For versions more than 12 months out of date, Insomnia's team provides as much assistance as possible, but can't guarantee any particular outcome or level of assistance. Insomnia recommends upgrading to see if your issue is resolved in a newer version.

## Patching Backwards

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


## Breaking Changes

Insomnia reserves the right to change and improve its software and feature set however it deems necessary. As such, it might occasionally be necessary to:

- Introduce changes that aren't backwards-compatible.
- Change how users interact with the software.

Insomnia strives to minimize user disruption via:

- Quality assurance.
- Clear user expectations.
- Automated or manual user migrations that include guidance at each step.

In the rare event that Insomnia needs to remove or reduce any core functionality or interface, the team takes steps to communicate this in advance via the blog and marketing channels. Such changes only happen on major versions of Insomnia.


As often as possible, Insomnia automatically handles and resolves any breaking changes to avoid manual user intervention, either from end users or account administrators.

### Manual intervention process

In the rare event that **manual user intervention is required**, we guarantee 30 days notice via the channels above. **Enterprise** customers also receive guidance from their customer success managers. 

For lesser changes - such as renaming a button or replacing two tabs with one - Insomnia communicates these changes clearly, as part of the [GA release](/stages-of-software-availability/), via the following resources:

- The changelog
- Public documentation
- Marketing channels

### Third party dependency

In the rare case of a third-party dependency introducing a minor change, Insomnia checks for these changes during pre-release testing, and address them on a best-effort basis by either:


- Mitigating it.
- Communicating it clearly via the previously disclosed channels.

## Changes in Major versions

Insomnia ships a major version when the release contains breaking changes. Breaking changes count as anything that, for the majority of users, could cause an existing workflow, configuration, or integration to stop working after the upgrade.


For example:

- Removing a supported request type, protocol, or authentication method.
- Removing or renaming a CLI command, flag, or subcommand.
- Changing the structure or schema of exported Insomnia collections/environments in a backwards-incompatible way.
- Dropping support for an operating system, platform, or runtime version.
- Changing the plugin API in a way that breaks existing plugins.
- Removing or renaming a public API endpoint (Insomnia Cloud / sync).
- Changing the default behavior of an existing feature in a way that alters outcomes for any nontrivial number of current users (changing how variables resolve, changing request execution orders, etc.).
- Migrating the underlying data store or storage format in a way that prevents rollback to a prior version.
- Removing a UI panel, tab, or workflow that a nontrivial number of users depends on.

## Changes in Minor versions

Insomnia ships a minor version when the release adds new functionality that is fully backwards-compatible with the previous version.

For example:

- Adding a new request type, protocol, or authentication method.
- Adding a new CLI command, flag, or subcommand.
- Introducing a new UI panel, tab, or workflow.
- Adding new fields or options to the collection/environment export format (existing fields unchanged).
- Adding a new plugin hook or extending the plugin API without breaking existing plugins.
- Adding support for a new operating system or platform.
- Deprecating (but not yet removing) a feature, command, or API.
- Adding new environment variable types or template tag functions.
- Introducing a new integration (for example a new Git provider, a new CI/CD integration).
- Adding new configuration options or preferences.

## Changes in Patch versions


Insomnia ships a patch version when the release contains only backwards-compatible bug fixes (corrections that make Insomnia behave the way it was already documented or intended to behave).

For example:

- Fixing a crash or hang during request execution.
- Correcting response rendering or syntax highlighting errors.
- Fixing import/export issues where valid collections failed to load.
- Resolving authentication flows that were not completing correctly.
- Fixing environment variable resolution or template tag evaluation bugs.
- Correcting UI rendering glitches or layout issues
- Fixing sync/collaboration conflicts or data loss scenarios.
- Updating bundled dependencies to patch security vulnerabilities (with no user-facing behavior change).
- Fixing incorrect HTTP header handling or encoding issues.
- Correcting documentation links or in-app help text. 

## Types of Releases

- Generally Available (GA): Available to anyone.
- Beta: Generally a 7\-day period before GA where clients can opt in (via Settings -> Release Channel in the app) and provide early [feedback](#user-feedback).
- Preview / Tech Preview: Features that are ready for usage by any customer, but are still in active development because it's a new problem space or the team is still experimenting on it. This feature is always clearly marked as such in our product.

## User feedback

Your feedback makes Insomnia better, and is especially critical for features that are in beta or preview.

### How to

Users can provide feedback depending on the type of plan they are on:

- **Essential:** file GitHub issues for defects or ideas.
- **Pro** and **Enterprise:** reach out to support@insomnia.rest for support.
- **Enterprise** only: send feedback to your CSM or through whatever normal cadences you have with Kong/Insomnia.

## Disclaimer

Insomnia reserves the right to act and ship, however, and whenever the team deems necessary in the interests of the security and stability of products and customers. 

However, Insomnia recognizes the risk and pain that significant or breaking changes offer to customers, and strives to minimize that at all times via the previous guidelines.


