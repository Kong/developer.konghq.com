---
title: kongctl lint
description: "Validate configuration files against a linting ruleset."

content_type: reference
layout: reference

works_on:
  - konnect

tools:
  - kongctl

breadcrumbs:
  - /kongctl/

related_resources:
  - text: Declarative configuration with kongctl
    url: /kongctl/declarative/
  - text: Get started with kongctl
    url: /kongctl/get-started/
  - text: deck file lint
    url: /deck/file/lint/
  - text: vacuum linting rules
    url: https://quobix.com/vacuum/rules/

tags:
  - declarative-config
  - linting
---

`kongctl lint` validates one or more configuration files against a ruleset. Linting is powered by [vacuum](https://quobix.com/vacuum/), so rulesets use the same Spectral-compatible format as [`deck file lint`](/deck/file/lint/).

{% include linting/key-concepts.md tool="kongctl" %}

For a complete list of available rules, see the [vacuum](https://quobix.com/vacuum/rules/) documentation.

## kongctl lint example

APIs in a kongctl declarative configuration file are defined in the `apis` block. To make sure every API is documented, you may want to validate that each one has a `description`.

Here is a sample ruleset file containing a single rule that accomplishes this:

```yaml
rules:
  api-description-defined:
    description: "APIs must have a description"
    given: $.apis[*]
    severity: error
    then:
      field: description
      function: truthy
```

The [JSONPath](http://jsonpath.com/) selector specified in `given` selects every API under the `apis` key from the incoming file. For each of those objects, the `truthy` function checks that the `description` field is set.

Assume you have the following declarative configuration file (`kong.yaml`):

```yaml
apis:
  - ref: tasks-api
    name: Task API
```

Validating this configuration against the example ruleset, stored in `ruleset.yaml`, results in the following violation:

```bash
kongctl lint -f kong.yaml -r ruleset.yaml
```
Result:
```
Linting Violations: 1
Failures: 1

kong.yaml:1:1: [error] APIs must have a description: `description` must be set
```
{:.no-copy-code}

Adding a `description` to the API resolves this violation:

```yaml
apis:
  - ref: tasks-api
    name: Task API
    description: Create and track tasks
```
Run kongctl with the new ruleset:
```bash
kongctl lint -f kong.yaml -r ruleset.yaml; echo $?
```

Result:

```
0
```
{:.no-copy-code}

When `kongctl lint` finds violations at or above the `--fail-severity` level, the command returns a non-zero exit code. 
You can use this to stop a CI/CD pipeline before a problematic configuration is applied. 
To lint multiple files, pass a directory to `-f` and use `-R` to process it recursively.

## Command usage

{% include_cached /kongctl/help/lint/index.md %}
