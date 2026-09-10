---
title: single `deck sync` command does not create objects in different workspaces
content_type: support
description: Running `deck sync` with YAML files from multiple workspaces in one invocation can throw an "entity already exists" error or silently put everything in a single workspace; run `deck sync` once per workspace instead.
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources: []
tldr:
  q: Why doesn't `deck sync` create objects in the correct workspaces when I sync multiple YAML files across different workspaces?
  a: |
    A single `deck sync` invocation can't operate across multiple workspaces — it either throws an "entity already exists" error (older decK) or a self-explanatory workspace-conflict error (current decK), or it silently creates everything in the first file's workspace. Run `deck sync` once per workspace, for example with `xargs`, instead of combining files from different workspaces into one command.
---

## Problem

When we use `deck sync` with multiple yaml files for different workspaces, we might see the following error

```bash

deck sync -s file1.yaml -s file2.yaml
Error: building state: inserting service SERVICE_NAME: entity already exists
```

Note: current versions of decK no longer surface this as an ambiguous "entity already exists" error. Instead, decK fails fast with an explicit, self-explanatory error message naming both conflicting workspaces directly.

or all objects are being created in the same workspace (workspace of the first yaml file)

```bash

deck sync -s file1.yaml -s file2.yaml
creating workspace workspace1
creating service Service1
creating service Service2
Summary:
  Created: 2
  Updated: 0
  Deleted: 0
```

The reason for the error is that the sync operation isn't able to operate on multiple workspaces, and we need to run `deck` separately for each workspace.

## Solution

Therefore when updating configs for multiple workspaces, we need to run `deck sync` multiple times and each `deck sync` command should only include the config files for the same workspace. For example.

```bash

deck sync -s workspace1.yaml -s service1.yaml -s routes1.yaml
```

You can also use `xargs` to run multiple `deck sync` commands. Let's say you've got two yaml files `workspace1.yaml` and `workspace2.yaml` in your current folder.

The command below will run `deck sync -s workspace1.yaml` and `deck sync -s workspace2.yaml` respectively.

```bash

ls -1 | xargs -I % sh -c 'deck sync -s %'
```
