Each zone control plane authenticates to the {{site.konnect_short_name}}-managed global control plane with an access token. When you create a zone with the UI wizard, {{site.konnect_short_name}} provisions this token for you as a system account access token and includes it in the generated deployment instructions, so you don't need to create one manually.

{{site.konnect_short_name}} supports two types of access tokens:

- **Personal access token (PAT):** Prefixed with `kpat_` and tied to an individual user account. Use a PAT for interactive or one-off tasks.
- **System account access token (SAT):** Prefixed with `spat_` and tied to a [system account](/konnect-api/#system-accounts-and-access-tokens) rather than a person. We recommend system account tokens for zone authentication and automation because they aren't tied to a user who might leave the organization.

If you provision zones with automation instead of the UI wizard, such as with Terraform, create a system account, assign it the `Connector` role on the control plane, and generate a system account access token to authenticate the zone. For a full example, see [Deploy {{site.mesh_product_name}} using Terraform and {{site.konnect_short_name}}](/mesh/deploy-mesh-using-terraform-and-konnect/).
