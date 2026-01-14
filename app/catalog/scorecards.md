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

You can use a prebuilt scorecard template that includes criteria from Kong and industry best practices, or design your own scorecard from scratch. You can also mix both approaches by starting out with a template and adding criteria to fit your needs.

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

{% navtabs "scorecards" %}
{% navtab "UI" %}
1. In the {{site.konnect_short_name}} sidebar, click **Catalog**.
1. In the Catalog sidebar, click **[Scorecards](https://cloud.konghq.com/service-catalog/scorecards)**.
1. Click **New Scorecard**.
1. From the **Scorecard template** dropdown menu, select your template or select custom scorecard.
1. (Optional) If you want to add an additional section or criteria, click **Add criteria** or **Add section**.
1. Select which services you want to apply this scorecard to.
1. In the **Name** field, enter a name for your scorecard.
1. Click **Save**. 
{% endnavtab %}
{% navtab "API" %}

Create a scorecard by sending a POST request to the `/scorecards` endpoint: 

<!--vale off-->
{% konnect_api_request %}
url: /v1/scorecards
status_code: 201
method: POST
body:
  name: Kong Best Practices
  description: Best practices that we encourage users to follow when using other Konnect applications.
  scorecard_template: kong_best_practices
  criteria:
    - enabled: true
      template_name: gateway_manager_error_rate
      template_parameters:
        relative_window: 30d
        threshold: 10
      section_name: Gateway Observability
    - enabled: true
      template_name: gateway_manager_response_latency
      template_parameters:
        metric: response_latency_p95
        relative_window: 30d
        threshold: 30
      section_name: Gateway Observability
    - enabled: true
      template_name: gateway_manager_has_plugin
      template_parameters:
        category: Authentication
      section_name: Plugin Enforcement
  entity_selector:
    type: all
    parameters: null
{% endkonnect_api_request %}
<!--vale on-->

{% endnavtab %}
{% endnavtabs %}


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

You can add criteria to a custom scorecard or a scorecard template. These allow you to further customize your scorecards.

You can list all available criteria by sending a GET request to the `/criteria-templates` endpoint:

<!--vale off-->
{% konnect_api_request %}
url: /v1/criteria-templates
status_code: 201
method: GET
{% endkonnect_api_request %}
<!--vale on-->

The following table details the different criteria you can specify:

{% table %}
columns:
  - title: Criteria
    key: criteria
  - title: Description
    key: description
rows:
  - criteria: Gateway Service Error Rate
    description: |
      Ensures gateway error rate stays below a defined threshold over a selected time window.
  - criteria: Gateway Service Response Latency
    description: |
      Ensures gateway response latency stays below a defined threshold over a selected time window.
  - criteria: Gateway Service Has Plugin
    description: |
      Ensures all mapped Gateway Service resources have at least one Plugin installed from the selected category.
  - criteria: Has API Specs
    description: |
      Ensures the service has the required number of API specifications attached.
  - criteria: Has Service Docs
    description: |
      Ensures the service has the required number of documentation files attached.
  - criteria: Lint API Specs
    description: |
      Ensures all attached API specifications pass [selected lint rulesets](#service-documentation-linting).
  - criteria: Has Resources
    description: |
      Ensures the service has the required number of mapped resources of the specified type.
  - criteria: Incident Limit
    description: |
      Ensures the number of triggered incidents stays below a defined threshold over a selected time window.
  - criteria: On Call Engineer Assigned
    description: |
      Ensures an on-call engineer is assigned to the service.
  - criteria: PagerDuty Service status is enabled
    description: |
      Ensures the service has a PagerDuty resource mapped that has the active status.
  - criteria: Time Before Failure
    description: |
      Ensures time between failures exceeds a minimum threshold over a selected time window.
  - criteria: Time to Acknowledge
    description: |
      Ensures time to acknowledge incidents stays below a maximum threshold over a selected time window.
  - criteria: Time to Restore
    description: |
      Ensures time to restore the service stays below a maximum threshold over a selected time window.
  - criteria: Minimum Pull Request Approving Reviews
    description: |
      Ensures all merged PRs have at least the required number of approving reviews.
  - criteria: Stale Pull Request Limit
    description: |
      Ensures the number of open PRs older than a defined age stays below the specified threshold.
  - criteria: Time to Approve Pull Request
    description: |
      Ensures PRs are approved within a defined threshold over a selected time window.
  - criteria: Time to Merge
    description: |
      Ensures PRs are merged within a defined threshold over a selected time window.
  - criteria: Time to Workflow Completion
    description: |
      Ensures CI workflow runs complete within a defined threshold over a selected time window.
  - criteria: Open Vulnerability Limit
    description: |
      Ensures the number of Dependabot-detected open vulnerabilities higher than the selected severity stays below the defined threshold.
{% endtable %}
<!--vale on-->


