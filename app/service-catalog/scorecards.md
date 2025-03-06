---
title: "{{site.konnect_short_name}} Scorecards"
content_type: reference
layout: reference

products:
    - gateway
works_on:
  - konnect

description: Scorecards in Service Catalog allow platform teams to monitor services for compliance with Kong-recommended and industry-defined best practices in {{site.konnect_short_name}}.

breadcrumbs:
  - /service-catalog/

related_resources:
  - text: "Service Catalog"
    url: /service-catalog/
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


A Service Catalog scorecard helps you evaluate services based on validation criteria. Scorecards help you detect issues, like whether there are services in the catalog that don't have an on-call engineer assigned or if you have GitHub repositories with stale pull requests that aren't getting reviewed or closed. From the scorecard view, you can view details on either a per-service or per-criteria basis.

## Scorecard templates

{{site.konnect_short_name}} provides several scorecard templates to help ensure your services adhere to industry best practices.

| Scorecard template | Description |
|--------------------|-------------|
| Service documentation | Ensures that your services are well-documented with ownership information, documentation files, and [API specs](https://apistylebook.stoplight.io/). |
| Service maturity | Measure performance reflecting industry-defined DORA metrics: deployment frequency, lead time for changes, change failure rate, and time to restore service. |
| Kong best practices | Best practices that we encourage users to follow when using other {{site.konnect_short_name}} applications. |
| Security and compliance | Enforces that services are protected through external monitoring and vulnerability management tools. |


## Service documentation linting

The service documentation template supports the following Spectral recipes:

| Category           | Description     | Recipe rules |
|------------|----------|------|
| OAS Recommended | Uses Stoplight's style guide. Only considers criteria tagged with `"recommended: true"` | [Stoplight Style Guide](https://apistylebook.stoplight.io/docs/stoplight-style-guide) |
| OWASP Top 10   | Set of rules to enforce OWASP security guidelines | [OWASP Top 10 API Security Guide](https://apistylebook.stoplight.io/docs/owasp-top-10-2023) |
| URL Versioning | Set of rules to enforce versioning | [API Versioning Guide](https://apistylebook.stoplight.io/docs/versioning) |
| Documentation  | Set of rules to enforce documentation best practices | [API Documentation Guidelines](https://apistylebook.stoplight.io/docs/documentation) |

## Enable a scorecard

To enable a scorecard on a service:
     
1. From [Service Catalog](https://cloud.konghq.com/us/service-catalog/), click **Scorecard** in the sidebar.
2. Select **New Scorecard**.
3. Name the scorecard, enable or disable scorecard criteria, and select which services you want the scorecard to apply to.
