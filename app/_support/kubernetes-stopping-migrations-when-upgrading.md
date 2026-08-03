---
title: Kubernetes - Stopping migrations when upgrading
content_type: support
published: false
description: Kong Gateway database migrations can be disabled during a Kubernetes Helm upgrade using `migrations.preUpgrade=false` and `migrations.postUpgrade=false`, letting a new container start without automatically updating the database.
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources: []
tldr:
  q: How do I stop Kong Gateway database migrations from running automatically during a Kubernetes Helm upgrade?
  a: |
    Set `migrations.preUpgrade=false` and `migrations.postUpgrade=false` in the Helm chart to launch a new Kong container without automatically running database migrations. The migrations container still starts for the database bootstrap, but performs no operations if the database already exists.
---

## Kubernetes - Stopping migrations when upgrading

Is it possible to stand up a new Kong version container without upgrading the database automatically?

In a scenario where it might be required to launch a newer version of a container within a Kubernetes environment without it automatically updating the Kong-EE database the following can be set to stop migrations running and allowing to be run manually:

```bash
--set migrations.preUpgrade=false --set migrations.postUpgrade=false
```

A container for migrations will still launch for the database bootstrap, however, if the Kong KB exists no operations will be performed.
