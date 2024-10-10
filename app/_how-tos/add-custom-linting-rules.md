---
title: Add custom linting rules in Insomnia

products:
- insomnia

tags:
- documents
- linting


tldr: 
  q: How do I customize linting in Insomnia?
  a: In your Git repository, add a `.spectral.yaml` file containing your custom ruleset at the same level as the `.insomnia` folder.

prereqs:
  inline:
  - title: Create a design document
    include_content: prereqs/design-document
    icon_url: /assets/icons/file.svg
  - title: Synchronize with Git
    include_content: prereqs/git-sync
    icon_url: /assets/icons/git.svg

---

## Create add the file ruleset

In the Git repository connected to your document, create a `.spectral.yaml` at the same level as the `.insomnia` folder.

## Define the rules

The custom ruleset overrides the default one. If you want to create a completely new ruleset, you can simply add your rules in the file using the [Spectral](https://docs.stoplight.io/docs/spectral/e5b9616d6d50c-rulesets) syntax. If you want to extend an existing ruleset, specify the ruleset with the `extend` property in `.spectral.yaml`.

For example, if you want to extend the [Spectral OpenAPI](https://docs.stoplight.io/docs/spectral/4dec24461f3af-open-api-rules) ruleset to add a warning when tags don't have a description, you can add the following content to `.spectral.yaml`:

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

Commit and push the file on the repository, then pull the changes in Insomnia. You may need to close and reopen the document to see the new rules applied.