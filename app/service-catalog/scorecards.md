---
title: "{{site.konnect_short_name}} scorecards"
content_type: reference
layout: reference

products:
    - gateway
    - service-catalog
works_on:
  - konnect

description: Scorecards in Service Catalog allow platform teams to monitor services for compliance with Kong-recommended and industry-defined best practices in {{site.konnect_short_name}}.

breadcrumbs:
  - /service-catalog/

related_resources:
  - text: "Service Catalog"
    url: /service-catalog/
  - text: Service Catalog services
    url: /service-catalog/services/
  - text: Traceable integration
    url: /service-catalog/integrations/traceable/
  - text: GitHub integration
    url: /service-catalog/integrations/github/
  - text: GitLab integration
    url: /service-catalog/integrations/gitlab/
  - text: SwaggerHub integration
    url: /service-catalog/integrations/swaggerhub/
  - text: Datadog integration
    url: /service-catalog/integrations/datadog/
  - text: PagerDuty integration
    url: /service-catalog/integrations/pagerduty/
---

A Service Catalog scorecard helps you evaluate services based on validation criteria. Scorecards help you detect issues, like whether there are services in the catalog that don't have an on-call engineer assigned, or if you have GitHub repositories with stale pull requests that aren't getting reviewed or closed. 

From the scorecard view, you can view details on either a per-service or per-criteria basis.

## Scorecard templates

{{site.konnect_short_name}} provides several scorecard templates to help ensure your Service Catalog services adhere to industry best practices.

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
     
1. From [Service Catalog](https://cloud.konghq.com/us/service-catalog/), click **Scorecard** in the sidebar.
2. Select **New Scorecard**.
3. Name the scorecard, configure scorecard criteria, and select which services you want the scorecard to apply to.


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


