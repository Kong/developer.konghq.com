---
title: "{{site.konnect_short_name}} scorecards"
content_type: reference
layout: reference

products:
    - catalog
works_on:
  - konnect

description: Scorecards in {{site.konnect_catalog}} allow platform teams to monitor services for compliance with Kong-recommended and industry-defined best practices in {{site.konnect_short_name}}.

breadcrumbs:
  - /catalog/
search_aliases:
  - service catalog
related_resources:
  - text: "{{site.konnect_catalog}}"
    url: /catalog/
  - text: "{{site.konnect_catalog}} services"
    url: /catalog/services/
  - text: Catalog integrations
    url: /catalog/integrations/
---

A {{site.konnect_catalog}} scorecard helps you evaluate services based on validation criteria. Scorecards help you detect issues, like whether there are services in the catalog that don't have an on-call engineer assigned, or if you have GitHub repositories with stale pull requests that aren't getting reviewed or closed. 

From the scorecard view, you can view details on either a per-service or per-criteria basis.

You can use a scorecard template that comes prepopulated with Kong or industry best practice criteria or create a custom scorecard with criteria that you choose. You can also combine the two and use some premade template criteria and some custom criteria.

## Scorecard templates

{{site.konnect_short_name}} provides several scorecard templates to help ensure your {{site.konnect_catalog}} services adhere to industry best practices.

<!--vale off-->
{% table %}
columns:
  - title: Scorecard template
    key: template
  - title: Description
    key: description
rows:
  - template: Service documentation
    description: "Hosts your documentation files and [API specs](https://apistylebook.stoplight.io/)."
  - template: Service maturity
    description: "Measures performance reflecting industry-defined DORA metrics: deployment frequency, lead time for changes, change failure rate, and time to restore service."
  - template: Kong best practices
    description: "Best practices that we encourage users to follow when using other {{site.konnect_short_name}} applications."
  - template: Security and compliance
    description: Checks that services are protected through external monitoring and vulnerability management tools.
{% endtable %}
<!--vale on-->

## Create a scorecard

To enable a scorecard on a service:

1. In the {{site.konnect_short_name}} sidebar, click **Catalog**.
1. In the Catalog sidebar, click **[Scorecards](https://cloud.konghq.com/service-catalog/scorecards)**.
1. Click **New Scorecard**.
1. From the **Scorecard template** dropdown menu, select your template or select custom scorecard.
1. (Optional) If you want to add an additional section or custom criteria, click **Add criteria** or **Add section**.
1. Select which services you want to apply this scorecard to.
1. In the **Name** field, enter a name for your scorecard.
1. Click **Save**. 


## Service documentation linting

The service documentation template supports the following Spectral recipes:

<!--vale off-->
{% table %}
columns:
  - title: Category
    key: category
  - title: Description
    key: description
  - title: Recipe rules
    key: recipe_rules
rows:
  - category: OAS Recommended
    description: |
      Uses Stoplight's style guide. Only considers criteria tagged with `"recommended: true"`.
    recipe_rules: "[Stoplight Style Guide](https://apistylebook.stoplight.io/docs/stoplight-style-guide)"
  - category: OWASP Top 10
    description: Set of rules to check for OWASP security guidelines
    recipe_rules: "[OWASP Top 10 API Security Guide](https://apistylebook.stoplight.io/docs/owasp-top-10-2023)"
  - category: URL Versioning
    description: Set of rules to check for versioning
    recipe_rules: "[API Versioning Guide](https://apistylebook.stoplight.io/docs/versioning)"
  - category: Documentation
    description: Set of rules to check for documentation best practices
    recipe_rules: "[API Documentation Guidelines](https://apistylebook.stoplight.io/docs/documentation)"
{% endtable %}
<!--vale on-->

## Custom scorecard criteria

You can add custom criteria to a custom scorecard or a scorecard template. These allow you to further customize your scorecards.

The following table details the different custom criteria you can specify:

TABLE HERE


