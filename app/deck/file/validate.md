---
title: deck file validate
description: Validate your declarative configuration locally against predefined schemas

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
---

The `validate` command reads the state file and ensures its validity. It reads all the specified state files and reports any YAML/JSON parsing issues.

```bash
deck file validate kong.yaml
```

Example response:

```sh
Error: 1 errors occurred:
	reading file kong.yaml: validating file content: 2 errors occurred:
	validation error: object={"paths":["/demo"]}, err=services.0.routes.0: Must validate at least one schema (anyOf)
	validation error: object={"paths":["/demo"]}, err=services.0.routes.0: name is required
```

Additionally, it checks for foreign relationships and alerts in cases of broken relationships or missing links.

```bash
deck file validate kong.yaml
```

Example response:

```sh
Error: building state: route demo-route for plugin rate-limiting: entity not found
```

No communication takes places between decK and Kong during the execution of this command. This process is faster than online validation, but may catch fewer errors. For online validation, see [`deck gateway validate`](/deck/gateway/validate/).
