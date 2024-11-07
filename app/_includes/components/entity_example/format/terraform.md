{% capture terraform_prereq_block %}
```hcl
terraform {
  required_providers {
    konnect = {
      source  = "kong/konnect"
    }
  }
}

provider "konnect" {
  personal_access_token = "${{site.data.entity_examples.config.konnect_variables.pat.placeholder}}"
  server_url            = "https://us.api.konghq.com/"
}
```
{% endcapture %}

{% if include.render_context %}
<div class="bg-secondary shadow-primary rounded-md flex flex-col text-sm">
  <details class="py-3 px-5 flex gap-1 border-b border-primary/5">
    <summary class="text-primary list-none"><strong>Prerequisite:</strong> Configure your Personal Access Token<span class="inline-flex chevron-icon float-right">{% include_svg '/assets/icons/chevron-down.svg' %}</span></summary>
    <div class="mt-2">
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
