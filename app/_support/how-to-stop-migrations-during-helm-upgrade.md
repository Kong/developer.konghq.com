---
title: How to stop migrations during Helm upgrade
content_type: support
description: Set the Helm `migrations.preUpgrade` and `migrations.postUpgrade` flags to `false` to skip running Kong's database migrations during a Helm upgrade.
products:
  - kic
works_on:
  - on-prem
  - konnect
related_resources: []
published: false
tldr:
  q: How do I stop Kong's database migrations from running during a Helm upgrade?
  a: |
    Set `migrations.preUpgrade=false` and `migrations.postUpgrade=false` when running `helm upgrade`
    to skip the `kong migrations up` and `kong migrations finish` steps. This is useful for testing a
    new Kong version without committing database changes.
---

## Overview

When performing an upgrade using Helm in a Kubernetes environment it may be desirable to not run the migrations scripts:

```bash
kong migrations up
kong migrations finish
```

How can this be achieved using Helm charts?

## Steps

When running the Helm upgrade command you can set the following flags:

```bash
--set migrations.preUpgrade=false
--set migrations.postUpgrade=false
```

This disables migrations up (preUpgrade) and finish (PostUpgrade)

Disabling the PostUpgrade script is useful if you wish to test a new version of Kong without committing the database changes.
