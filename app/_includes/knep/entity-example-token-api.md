{% capture konnect_token_api %}
1. Create a [personal access token](/konnect-api/#konnect-api-authentication) to interact with the {{site.konnect_short_name}} API. 
1. Export it to an environment variable:
    ```
    export KONNECT_TOKEN=token-goes-here
    ```
{% endcapture %}

<div class="bg-secondary shadow-primary rounded-md flex flex-col text-sm">
  <details class="flex flex-col border-b border-primary/5">
    <summary class="py-3 px-5 text-primary list-none cursor-pointer"><strong>Prerequisite:</strong> Configure your Personal Access Token<span class="inline-flex chevron-icon float-right">{% include_svg '/assets/icons/chevron-down.svg' %}</span></summary>
    <div class="px-5 pb-3">
      {{ konnect_token_api | markdownify }}
    </div>
  </details>
</div>