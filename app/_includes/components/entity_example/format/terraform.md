{% capture terraform_prereq_block %}
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
{% endcapture %}

{% if include.render_context %}
<div class="bg-secondary shadow-primary rounded-md flex flex-col text-sm">
  <details class="flex flex-col border-b border-primary/5">
    <summary class="py-3 px-5 text-primary list-none cursor-pointer"><strong>Prerequisite:</strong> Configure your Personal Access Token<span class="inline-flex chevron-icon float-right">{% include_svg '/assets/icons/chevron-down.svg' %}</span></summary>
    <div class="px-5 pb-3">
      {{ terraform_prereq_block | markdownify }}
    </div>
  </details>
</div>
{% case include.presenter.entity_type %}
{% when 'plugin' %}
  Add the following to your Terraform configuration to create a Konnect Gateway Plugin:
{% endcase %}
{% endif %}
{% include components/entity_example/format/snippets/terraform.md presenter=include.presenter %}
