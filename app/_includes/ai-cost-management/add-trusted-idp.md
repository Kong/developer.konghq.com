A trusted IdP is the OIDC issuer {{site.konnect_short_name}} verifies tokens against.
Mapping the token's `email` claim lets a newly authenticated caller match an existing principal from your org chart, instead of creating an unlinked one.

Add a trusted IdP through the {{site.konnect_short_name}} UI:
1. In the {{site.konnect_short_name}} sidebar, click **Access Management**.
1. Click **Identity Providers**.
1. Click **Add trusted IdP**.
1. In the **Name** field, enter a label for this IdP, for example `My OIDC Provider`.
1. In the **Issuer URL** field, enter your issuer URL (run `echo $OIDC_ISSUER_URL` to print the value you exported in the [prerequisites](#oidc-provider)).
1. Enable **Automatic user provisioning**.
1. In the **User provisioning claim mapping** section, enable **Set email**.
1. In the **Claim name** field, enter `email`.
1. Click **Add IdP**.

{:.info}
> In this example, we're using email because the [Keycloak setup prerequisite](#oidc-provider) sets an `email` attribute on the service account.
> This matches the `email` column in your org structure file.
> Without a matching `email` claim, automatic user provisioning still creates a principal, but it won't link to an existing org chart user.
