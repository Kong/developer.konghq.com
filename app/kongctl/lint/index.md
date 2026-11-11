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

## Lint expanded declarative configuration {% new_in 1.28 %}

By default, `kongctl lint` checks each input as written, including template
definitions. Use `--expand` to lint values from local `!file` includes,
principal `!csv` inputs, and `_templates` and `_extends` inheritance. This lets
rules check included and inherited values after resource overrides have been
applied.

For example, save a shared API template in `templates.yaml`:

```yaml
_templates:
  documented-api:
    description: Create and track tasks
```

Use the template in `kong.yaml`:

```yaml
apis:
  - _extends: documented-api
    ref: tasks-api
    name: Task API
```

Lint both files with the description ruleset from the example:

```bash
kongctl lint -f templates.yaml -f kong.yaml -r ruleset.yaml --expand
```

The API passes the rule because its expanded configuration contains the
inherited `description`. Without `--expand`, the rule reports a missing
description on the API.

All selected inputs share template definitions, so include both the template
files and the files that use them. Each input is linted separately after
expansion; rules can't detect duplicates across files. Empty inputs, including
files that only define templates, are skipped. Templates are checked where
they're used. The command fails if nothing remains to lint.

For more information, see [reusable configuration templates](/kongctl/declarative/templates/).

### Input files and includes

With `--expand`, you can pass YAML files (`.yaml` or `.yml`), directories, or
standard input (`-f -`). Use `-R` to search subdirectories. URL inputs aren't
supported. Each selected input must contain one YAML document; split documents
separated by `---` into separate files.

`!file` paths resolve relative to the file containing the tag, including tags
inherited through templates. Includes must stay within the source root:

* For a file input, the root is its parent directory.
* For a directory input, the root is that directory.
* For standard input, the root is the working directory, which also resolves
  relative include paths.

Included fragments are checked as part of the file that includes them. A
fragment also selected as an input is checked independently, including lists
and scalars. Keep fragments outside selected inputs to avoid independent
checks. Vacuum may report `index-failure` for standalone scalars.

### Expansion limits and findings

`!env` (including `store: true`), `!ref`, `!secret`, and lookup tags remain
unresolved placeholders. Expansion doesn't read environment values, fetch
secrets, or contact Konnect. Rules that expect concrete values must account for
these placeholders. Existing OpenAPI `$ref` resolution and ruleset inheritance
can still access the network.

Expansion checks YAML, tag, and template syntax. It doesn't apply defaults,
validate resource schemas, or check the types of fields containing `!env`.
Passing lint doesn't establish that configuration is ready to apply. Use
[`kongctl plan`](/kongctl/plan/) for that validation.

Findings identify the input filename, but line and column numbers refer to the
expanded content held in memory. They may differ from the original source
locations. Text findings append `(expanded)` to the message; JSON and YAML
findings include `expanded: true`. Expanded content isn't saved to disk.
Expansion errors fail the command and identify the source; template errors also
report a position.

## Command usage

{% include_cached /kongctl/help/lint/index.md %}
