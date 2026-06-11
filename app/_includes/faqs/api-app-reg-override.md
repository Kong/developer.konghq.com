{% if include.section == "question" %}

Application registration auto approve is disabled for my {{site.dev_portal}}, can I override this for APIs or API packages?
{% elsif include.section == "answer" %}

Yes, when the {{site.dev_portal}} auto approve application registration setting is disabled, you can override this on a per-API and API package basis. You can do this via the UI, API, or Terraform:
* **UI:** When you publish or edit a published API or API package, select the **Auto-approve application registration to this API** checkbox.
* **API:** Set `auto_approve_registrations` to `true` in a PUT request to the [`/apis/{apiId}/publications/{portalId}` endpoint](/api/konnect/api-builder/v3/#/operations/publish-api-to-portal).
* **Terraform:** Set `auto_approve_registrations` to `true` on the [`konnect_api_publication` resource](https://github.com/Kong/terraform-provider-konnect/blob/main/examples/resources/konnect_api_publication.tf).

If application registration auto approval is enabled at the {{site.dev_portal}} level, you **cannot** override it, all APIs and API packages will be set to auto approve application registrations.

{% endif %}