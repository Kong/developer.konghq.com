{% if include.render_context %}
{% details %}
css_classes:
  details: "flex flex-col border-b border-primary/5"
  summary: "py-3 px-5 text-primary list-none cursor-pointer"
  wrapper: "bg-secondary shadow-primary rounded-md flex flex-col text-sm"
  float_right: true
  content: "px-5 pb-3 pt-0"
summary: "**Prerequisite:** Configure your Personal Access Token"
content: |
  ```hcl
  terraform {
    required_providers {
      {{include.presenter.provider_source}} = {
        source  = "kong/{{include.presenter.provider_source}}"
      }
    }
  }
  
  provider "{{include.presenter.provider_source}}" {
    personal_access_token = "${{site.data.entity_examples.config.konnect_variables.pat.placeholder}}"
    server_url            = "https://us.api.konghq.com/"
  }
  ```
{% enddetails %}
{% case include.presenter.entity_type %}
{% when 'plugin' %}
Add the following to your Terraform configuration to create a Konnect Gateway Plugin:
{% endcase %}
{% endif %}
{% include components/entity_example/format/snippets/terraform.md presenter=include.presenter %}
