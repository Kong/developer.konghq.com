---
title: kongctl install skills
description: Install kongctl agent skills.
content_type: reference
layout: reference

works_on:
  - on-prem
  - konnect

tools:
  - kongctl

breadcrumbs:
  - /kongctl/
  - /kongctl/install/

related_resources:
  - text: kongctl install commands
    url: /kongctl/install/
  - text: Use kongctl with AI agent skills
    url: /kongctl/skills/
---

Install bundled kongctl skills and create symlinks for agent tool integration.
By default, skills are written to `.kongctl/skills/` in the current directory
and symlinked into supported agent-tool directories.

For an overview of the bundled skills and suggested workflows, see
[Use kongctl with AI agent skills](/kongctl/skills/).

## Command usage

{% include_cached /kongctl/help/install/skills.md %}
