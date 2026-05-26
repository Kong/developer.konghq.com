---
title: Add custom linting rules in Insomnia
permalink: /how-to/add-custom-linting-rules/

content_type: how_to
description: Learn how to add custom linting rules to your APIs in Insomnia.
no_wrap: true

products:
- insomnia

tags:
  - insomnia-documents
  - linting

related_resources:
  - text: Design APIs with Insomnia
    url: /insomnia/design/


tldr: 
  q: How do I customize linting in Insomnia?
  a: In your Insomnia project, add a YAML file containing your custom ruleset.

prereqs:
  inline:
  - title: Create a design document
    include_content: prereqs/design-document
    icon_url: /assets/icons/file.svg

faqs:
  - q: How can I use custom linting with Inso CLI?
    a: |
      Create your YAML file in the same directory as the OAS file to lint, then run the [`inso lint spec`](/inso-cli/reference/lint_spec/) command.

---

## Upload the ruleset file

Upload a YAML file containing your ruleset to the project containing the design document with the OpenAPI specifications (OAS) to lint.

This places the ruleset file in the local working directory. You don't see the file in the Insomnia UI, but the linting rules are applied to the associated OAS.

## Define the rules

The custom ruleset overrides the default one. To create a completely new ruleset, add your rules in the file using the [Spectral](https://docs.stoplight.io/docs/spectral/e5b9616d6d50c-rulesets) syntax. If you want to extend an existing ruleset, specify the ruleset with the `extends` property.

{:.info}
> Available Spectral properties in Insomnia are `rules` and `extends`.

For example, to extend the default [Spectral OpenAPI](https://docs.stoplight.io/docs/spectral/4dec24461f3af-open-api-rules) ruleset to add a warning when tags don't have a description, add the following content to your ruleset file:

```yaml
extends: spectral:oas
rules:
  tag-description:
    description: Tags must have a description.
    given: $.tags[*]
    severity: warn
    then:
      field: description
      function: truthy
```

## Validate

Close and reopen the document to apply the changes. In this example, you can validate by creating a new tag without a description:

```yaml
tags:
  - name: flight-data
```

This causes a new warning to appear:
![Missing tag description warning](/assets/images/insomnia/custom-linting-warning.png)

