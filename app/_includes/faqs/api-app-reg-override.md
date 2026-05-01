{% if include.section == "question" %}

Application registration is disabled for my {{site.dev_portal}}, can I override this for APIs or API packages?
{% elsif include.section == "answer" %}

Yes, you can override the {{site.dev_portal}} application registration setting on a per-API and API package basis. You can do this via the UI, API, or Terraform:
* **UI:** When you publish or edit a published API or API package, select the **Auto-approve application registration to this API** checkbox.
* **API:** Set `auto_approve_registrations` to `true` in a PUT request to the [`/apis/{apiId}/publications/{portalId}` endpoint](/api/konnect/api-builder/v3/#/operations/publish-api-to-portal).
* **Terraform:** Set `auto_approve_registrations` to `true` on the [`konnect_api_publication` resource](https://github.com/Kong/terraform-provider-konnect/blob/main/examples/resources/konnect_api_publication.tf).

{% endif %}