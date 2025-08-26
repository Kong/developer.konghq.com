---
title: "{{site.base_gateway}} 3.4 to 3.10 LTS upgrade"
content_type: reference
layout: reference
breadcrumbs:
  - /gateway/
  - /gateway/upgrade/
products:
    - gateway

works_on:
    - on-prem
    - konnect
search_aliases:
  - lts
tags:
    - upgrades
    - versioning

description: This guide walks you through upgrade paths for {{site.base_gateway}} 3.4 LTS to 3.10 LTS and helps you prepare for an upgrade.

related_resources:
  - text: "{{site.base_gateway}} breaking changes"
    url: /gateway/breaking-changes/
  - text: "Backing up and restoring {{site.base_gateway}}"
    url: /gateway/upgrade/backup-and-restore/
  - text: "Dual-cluster upgrade"
    url: /gateway/upgrade/dual-cluster/
  - text: "In-place upgrade"
    url: /gateway/upgrade/in-place/
  - text: "Rolling upgrade"
    url: /gateway/upgrade/rolling/
  - text: "{{site.base_gateway}} upgrade"
    url: /gateway/upgrade/
  - text: "{{site.base_gateway}} 2.8 to 3.4 LTS upgrade"
    url: /gateway/upgrade/lts-upgrade-28-34/

---

{% include /upgrade/lts-upgrade.md lts_version_from='3.4' lts_version_to='3.10' %}