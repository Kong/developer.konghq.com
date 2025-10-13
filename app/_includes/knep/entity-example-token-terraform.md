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

<div class="bg-secondary shadow-primary rounded-md flex flex-col text-sm">
  <details class="flex flex-col border-b border-primary/5">
    <summary class="py-3 px-5 text-primary list-none cursor-pointer"><strong>Prerequisite:</strong> Configure your Personal Access Token<span class="inline-flex chevron-icon float-right">{% include_svg '/assets/icons/chevron-down.svg' %}</span></summary>
    <div class="px-5 pb-3">
      {{ terraform_prereq_block | markdownify }}
    </div>
  </details>
</div>