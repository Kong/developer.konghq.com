---
title: Add custom linting rules in Insomnia
permalink: /how-to/add-custom-linting-rules/

content_type: how_to
description: Learn how to add custom linting rules to your APIs in Insomnia.

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
  a: In your Git repository, add a `.spectral.yaml` file containing your custom ruleset at the same directory as the OAS file to lint.

prereqs:
  inline:
  - title: Create a design document
    include_content: prereqs/design-document
    icon_url: /assets/icons/file.svg
  - title: Synchronize with Git
    include_content: prereqs/git-sync
    icon_url: /assets/icons/git.svg

faqs:
  - q: How can I use custom linting with Inso CLI?
    a: |
      Create your `.spectral.yaml` file in the same directory as the OAS file to lint, then run the [`inso lint spec`](/inso-cli/reference/lint_spec/) command.

---

## Create add the file ruleset

In the Git repository connected to your document, create a `.spectral.yaml` at the same directory as the OAS file to lint.

## Define the rules

The custom ruleset overrides the default one. If you want to create a completely new ruleset, you can simply add your rules in the file using the [Spectral](https://docs.stoplight.io/docs/spectral/e5b9616d6d50c-rulesets) syntax. If you want to extend an existing ruleset, specify the ruleset with the `extend` property in `.spectral.yaml`.

For example, if you want to extend the default [Spectral OpenAPI](https://docs.stoplight.io/docs/spectral/4dec24461f3af-open-api-rules) ruleset to add a warning when tags don't have a description, you can add the following content to `.spectral.yaml`:

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

## Synchronize the changes

Commit and push the file on the repository, then pull the changes in Insomnia.  

{:.info}
> This will place the `.spectral.yaml` file in the local working directory.  You will not see the file in the Insomnia UI but the linting rules will be applied to the associated OAS file.

## Validate

Close and reopen the document to apply the changes. In this example, you can validate by creating a new tag without a description:
```yaml
tags:
  - name: flight-data
```

This causes a new warning to appear:
![Missing tag description warning](/assets/images/insomnia/custom-linting-warning.png)
