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
  personal_access_token = "{{ site.data.entity_examples.config.konnect_variables.pat.placeholder }}"
  server_url            = "https://us.api.konghq.com/"
}
```
{% endcapture %}

{% if include.render_context %}
  <details class="mb-2">
    <summary class="rounded mb-0.5 bg-gray-200 p-2"><strong>Prerequisite:</strong> Configure your Personal Access Token</summary>
    <div>
      {{ terraform_prereq_block | markdownify }}
    </div>
  </details>
{% case include.presenter.entity_type %}
{% when 'plugin' %}
  Add the following to your Terraform configuration to create a Konnect Gateway Plugin:
{% endcase %}
{% endif %}
{% include components/entity_example/format/snippets/terraform.md presenter=include.presenter %}
