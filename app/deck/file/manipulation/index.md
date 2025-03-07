---
title: Configuration Transformation
description: "Provides multiple commands to manipulate an existing declarative configuration file"

content_type: reference
layout: reference

works_on:
  - on-prem
  - konnect

tools:
  - deck

breadcrumbs:
  - /deck/
  - /deck/file/

related_resources:
  - text: All decK documentation
    url: /index/deck/

skip_index: true
---

`deck file` provides multiple commands to manipulate an existing declarative configuration file. They can be used to update values in the configuration, add new plugins and more.

| Command                                                  | Description                                                            |
| -------------------------------------------------------- | ---------------------------------------------------------------------- |
| [patch](/deck/file/manipulation/patch/)                  | Update existing values                                                 |
| [add-tags](/deck/file/manipulation/tags/#add-tags)       | Add tags to specific entities                                          |
| [remove-tags](/deck/file/manipulation/tags/#remove-tags) | Remove tags from specific entities                                     |
| [namespace](/deck/file/manipulation/namespace/)          | Add a prefix to Routes that is stripped before sending to the upstream |
