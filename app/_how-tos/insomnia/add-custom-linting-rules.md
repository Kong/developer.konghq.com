---
title: "Add custom linting rules in {{ site.insomnia }}"
permalink: /how-to/add-custom-linting-rules/

content_type: how_to
description: Learn how to add custom linting rules to your APIs in {{ site.insomnia }}.
no_wrap: true

products:
  - insomnia 

min_version:
  insomnia: "13.0"
tags:
  - insomnia-documents
  - linting

related_resources:
  - text: "Design APIs with {{ site.insomnia }}"
    url: /insomnia/design/

tldr:
  q: How do I customize linting in {{ site.insomnia }} ?
  a: In your {{ site.insomnia }}document, click the upload icon for the **Default OAS Ruleset** and add a Spectral ruleset YAML file with your custom ruleset.

prereqs:
  inline:
  - title: Create a design document
    include_content: prereqs/design-document
    icon_url: /assets/icons/file.svg

faqs:
  - q: How can I use custom linting with Inso CLI?
    a: |
      Create a [Spectral ruleset](https://docs.stoplight.io/docs/spectral/e5b9616d6d50c-rulesets) in YAML format, and upload it to an OAS file document in Insomnia by clicking the upload icon for the **Default OAS Ruleset**.

---

{{site.insomnia}} provides a default linting ruleset. Override it to add your custom linting rules by following these steps:

## Define the rules

The custom ruleset overrides the default one. To create a new ruleset, add your rules in the file using the [Spectral](https://docs.stoplight.io/docs/spectral/e5b9616d6d50c-rulesets) syntax. If you want to extend an existing ruleset, specify the ruleset with the `extends` property.

{:.info}
> Available Spectral top level properties in {{ site.insomnia }} are `rules` and `extends`. Custom functions are not permitted. However, {{ site.insomnia }}provides support for [Spectral built-in core functions](https://docs.stoplight.io/docs/spectral/cb95cf0d26b83-core-functions).

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

## Upload the ruleset file

1. In the {{ site.insomnia }} app, navigate to a document with the OAS file you want to lint.
2. Click the upload icon for **Default OAS Ruleset** at the bottom of the pane.

This places the ruleset file in the local working directory. {{ site.insomnia }}renames this custom ruleset as `.spectral.yaml`.

You can view the content of the file by clicking `Custom Ruleset` in {{ site.insomnia }}. If you want to make changes to the file, edit it locally.

## Validate

In this example, you can confirm the rule triggers by removing the description for the `GET /flights` endpoint. This will be flagged since the ruleset doesn't allow tags without a description:

```yaml
"/flights":
    get:
      summary: Get KongAir planned flights
      tags:
      - flight-data
```

This causes a new warning to appear:

```
tag-description Tags must have a description.
```

## Override the rules {% new_in 13 %} 

Override the linting rules and use another ruleset, by using either Inso CLI or `.spectral.yaml`:

{% navtabs "custom linting" %}
{% navtab "Inso CLI" %}

Use the [Inso CLI](/inso-cli/reference/lint_spec/) with the `--ruleset` or `-r` flag and the path to your custom ruleset. Run `inso lint spec --ruleset <path-to-custom-ruleset>`. This overrides the default OpenAPI specifications (OAS) ruleset in {{ site.insomnia }}, and any ruleset in the API Spec folder.

If the `--ruleset` flag isn't specified, {{ site.insomnia }}uses one of the following, in order:

- The ruleset defined in `.spectral.yaml`, if it exists.
- The default OAS ruleset.

{% endnavtab %}
{% navtab "Use `extends` in `.spectral.yaml`" %}

Make {{ site.insomnia }}point at another ruleset in `.spectral.yaml` by using the `extends` property. For example:

```yaml
extends:
  - spectral:oas
  - ./rules/my-rules.yaml
```

If you reference a remote file (one hosted outside of your project in {{ site.insomnia }}), {{ site.insomnia }} fetches its content only when you upload the custom ruleset. If the remote file later changes, {{ site.insomnia }}:

- Doesn't track those changes in commits, because the file lives outside the project.
- Doesn't fetch them automatically for security reasons. Instead, you can refresh manually using the button next to the ruleset option.

{% endnavtab %}
{% endnavtabs %}

{:.warning}
> Make sure users in your team are running at least {{ site.insomnia }} `13.0` to avoid compatibility issues with this feature.