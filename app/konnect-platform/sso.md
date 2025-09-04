---
title: "{{site.konnect_short_name}} SSO"
content_type: reference
layout: reference

products:
  - konnect

min_version:
  gateway: '3.4'

breadcrumbs:
  - /konnect/

description: "Learn how to configure single sign-on (SSO) for the {{site.konnect_short_name}} platform."

api_specs:
    - konnect/identity
    - konnect/portal-management

related_resources:
  - text: "Authentication"
    url: /konnect/authentication/
  - text: "SAML IdP mapping"
    url: /konnect-platform/saml-idp-mapping/
  - text: "{{site.konnect_short_name}} teams and roles"
    url: /konnect-platform/teams-and-roles/
  - text: Dev Portal SSO
    url: /dev-portal/sso/

works_on:
  - konnect

tags:
  - authentication
  - sso

search_aliases:
  - Okta
  - IdP

faqs:
  - q: I'm experiencing authentication issues and I have a large number of groups, how do I troubleshoot this?
    a: | 
      If users are assigned a very large number of groups (over 150 in most cases), the IdP may send the groups claim in a non-standard manner, causing authentication issues. 

      To work around this limitation in the IdP, we recommend using group filtering functions provided by the IdP for this purpose. 
      Here are some quick reference guides for common IdPs:
      * [Azure group filtering](https://learn.microsoft.com/en-us/azure/active-directory/hybrid/connect/how-to-connect-fed-group-claims#group-filtering) 
      * [Okta group filtering](https://support.okta.com/help/s/article/How-to-send-certain-groups-that-the-user-is-assigned-to-in-one-Group-attribute-statement)

      You may need to contact the support team of your identity provider in order to learn how to filter groups emitted for the application.
  - q: In the token payload, the `groups` claim is configured correctly but still appears empty, or it includes some groups but not all when Okta is configured as the IdP. How do I fix this?
    a: |
      This issue might happen if the authorization server is pulling in additional
      groups from third-party applications, for example, Google groups.

      An Okta administrator must duplicate the third-party groups
      and re-create them directly in Okta. They can do this by exporting the group
      in CSV format, then importing the CSV file into Okta to populate the new group.
  - q: "I'm getting a `failed to get state: http: named cookie not present` error when I try to authenticate with Okta, how do I fix this?"
    a: |
      This may happen if the wrong issuer URI was used, for example, the URI from your application's settings. The issuer URI must be in the following format, where `default` is
      the name or ID of the authorization server:

      ```
      https://example.okta.com/oauth2/default
      ```

      You can find this URI in your Okta developer account, under **Security** > **API**.
  - q: How do I debug my integration with Okta?
    a: |
      The Okta console provides a [Token Preview feature](https://help.okta.com/en-us/content/topics/security/api-config-test.htm) which will be useful in 
      verifying configuration values for these SSO configuration instructions. If you encounter issues configuring SSO with Okta, start by
      checking the Token Preview for the Okta application you created.
---

{{site.konnect_short_name}} supports external single sign-on authentication using an Identity Provider (IdP). Using SSO in {{site.konnect_short_name}}, you can enable authentication for the following:
* **The {{site.konnect_short_name}} platform:** Allow [Org admins](/konnect-platform/teams-and-roles/) to log in with SSO. This is an alternative to {{site.konnect_short_name}}'s [built-in authentication](https://cloud.konghq.com/global/organization/settings#authentication-scheme).
* **Dev Portals:** Allow developers to log in to the [Dev Portal](/dev-portal/sso/) with SSO.

SSO for each of these is configured through different settings, so enabling one doesn't automatically enable the other. Both methods support OIDC and SAML-based SSO.

{:.warning}
> We recommend using a single authentication method, however, {{site.konnect_short_name}} supports the ability to combine built-in authentication with _either_ OIDC or SAML based SSO. Combining both OIDC and SAML based SSO is not supported.
Keep built-in authentication enabled while you are testing IdP authentication. Only disable built-in authentication after successfully testing the configurations in these guides.

## Supported IdP providers

{{site.konnect_short_name}} supports any OIDC or SAML-compliant provider. The following have been verified to work out-of-the-box:

* Okta 
* Azure Active Directory
* Oracle Identity Cloud Service 
* Keycloak

## SSO configuration

To configure SSO in {{site.konnect_short_name}}, you must configure the following in your IdP:
* Add {{site.konnect_short_name}} to your IdP as an application
* Add users that need to use SSO to the IdP tenant.
* Set claims in your IdP

For Okta-specific configuration steps, see the [Configure a {{site.konnect_short_name}} application in Okta](#configure-a-konnect-application-in-okta) section on this page.

You can configure {{site.konnect_short_name}} SSO in the following ways:

<!--vale off-->
{% table %}
columns:
  - title: Feature
    key: feature
  - title: UI setting
    key: ui
  - title: API endpoint
    key: api
rows:
  - feature: "{{site.konnect_short_name}} platform"
    ui: "Go to the [Authentication Scheme organization settings](https://cloud.konghq.com/global/organization/settings#authentication-scheme)<sup>1</sup>"
    api: "[`/identity-providers`](/api/konnect/identity/#/operations/create-identity-provider)<sup>1</sup>"
  - feature: "Dev Portal"
    ui: "Go to the Identity settings for your [Dev Portal](https://cloud.konghq.com/portals/)"
    api: "[`/portals/{portalId}/identity-providers`](/api/konnect/portal-management/#/operations/create-portal-identity-provider)"
{% endtable %}
<!--vale on-->

{:.info}
> **Note:** When you configure the organization login path, enter a unique string that will be used in the URL your users use to log in. For example: `examplepath`.
> * The path must be unique *across all {{site.konnect_short_name}} organizations*. If your desired path is already taken, you must to choose another one.
> * The path can be any alphanumeric string.
> * The path does not require a slash (`/`).
> * (SAML only) When you save this configuration, {{site.konnect_short_name}} will generate two new values: a **Single Sign-On URL** and an **Audience URI**. In your IdP, update the previous placeholder **Single Sign-On URL** and **Audience URI (SP Entity ID)** with the new values generated by {{site.konnect_short_name}}.

When configuring SSO for Dev Portal, it's important to consider the following points:

* Developers are auto-approved by {{site.konnect_short_name}} when they use SSO to log in to the Dev Portal.
This is because {{site.konnect_short_name}} outsources the approval process to the IdP instance when using SSO. Therefore, you must restrict
who can sign up from the IdP rather than through {{site.konnect_short_name}}.
* If you plan on using [team mappings from an IdP](#team-mapping-configuration),
they must be from the same IdP instance as your SSO.
* If you have multiple Dev Portals, keep in mind that each Dev Portal has a separate SSO configuration.
You can use the same IdP for multiple Dev Portals or different IdPs per Dev Portal.

### Test and apply the configuration

{:.warning}
> **Important:** Keep built-in authentication enabled while you are testing IdP authentication. Only disable built-in authentication after successfully testing IdP authentication.

Depending on your IdP, choose one of the following to test the configuration:
* **{{site.konnect_short_name}} Org:** Test the SSO configuration by navigating to the login URI based on the organization login path you set earlier. For example: `https://cloud.konghq.com/login/$YOUR_PATH`, where `$YOUR_PATH` is the unique login path string set in the previous steps.
* **Dev Portal:** Test the SSO configuration by navigating to the callback URL for your Dev Portal. For example: `https://$YOUR_PORTAL_ID.us.portal.konghq.com/login`.

If the configuration is correct, you will see the IdP sign-in page. 

You can now manage your organization's user permissions entirely from the IdP application.

## Configure a {{site.konnect_short_name}} application in Okta

If you want to use Okta as your IdP provider for SSO, you need an Okta account with administrator access to configure Applications and Authorization Server settings.

Additionally, if you're configuring Okta SSO for Dev Portal, you'll need a [non-public {{site.konnect_saas}} Dev Portal created](/dev-portal/security-settings/) in your {{site.konnect_short_name}} organization.

{% navtabs "Okta SSO" %}
{% navtab "OIDC" %}

1. From the Applications section of the Okta console, select **Create App Integration** 
   and choose [OIDC - OpenID Connect](https://help.okta.com/oie/en-us/content/topics/apps/apps_app_integration_wizard_oidc.htm)
   with **Web Application** for the Application type. Provide the following configuration details: 
{% capture table %} 
<!-- vale off -->
{% table %}
columns:
  - title: Okta setting
    key: setting
  - title: Configuration
    key: configuration
rows:
  - setting: Grant type
    configuration: Authorization Code
  - setting: Sign-in redirect URIs
    configuration: |
      {{site.konnect_short_name}} Org: `https://cloud.konghq.com/login`  
      Dev Portal: `https://$YOUR_PORTAL_URL/login`
  - setting: Sign-out redirect URIs
    configuration: |
      {{site.konnect_short_name}} Org: `https://cloud.konghq.com/login`  
      Dev Portal: `https://$YOUR_PORTAL_URL/login`
{% endtable %}
<!-- vale on -->
{% endcapture %}
{{table | indent: 3}}

1. Optional: If you want to map Okta group claims to {{site.konnect_short_name}} Organization or Dev Portal Teams, 
modify the [OpenID Connect ID Token claims](https://developer.okta.com/docs/guides/customize-tokens-groups-claim/main/#add-a-groups-claim-for-the-org-authorization-server) 
in the **Application** > **Sign On** section of the Okta configuration, setting the following values:

    * **Group claims type**: `Filter`
    * **Group claims filter**: Enter `groups` for the claim name and enter **Matches regex** as the filter type and `.*` for the filter value.

    This claim specifies which user's groups to include in the token, in this case the wildcard regex specifies that all groups will be included.

    {:.info}
    > If the authorization server is retrieving additional groups from
    third-party applications (for example, Google groups), the `groups` claim
    will not contain them. If you want to use these third-party groups, the Okta 
    administrator will need to duplicate them directly in Okta or use a [custom token](https://developer.okta.com/docs/guides/customize-tokens-groups-claim/main/)
    to include them in the `groups` claim.

1. [Assign desired groups and users to the new Okta application](https://help.okta.com/en-us/content/topics/users-groups-profiles/usgp-assign-apps.htm).

1. Locate the following values in the Okta console, which will be used later for the
{{site.konnect_short_name}} configuration.

    * **Client ID**: Located in your Application **General -> Client Credentials** settings.
    * **Client Secret**: Located in your Application **General -> Client Secrets** settings.
    * **Issuer URI** : The Issuer is typically found in the **Security -> API -> Authorization Servers** settings.
    It should look like the following: `https://<okta-org-id>.okta.com/oauth2/default`
{% endnavtab %}
{% navtab "SAML" %}

1. From the Applications section of the Okta console, select _Create App Integration_ 
   and choose [SAML 2.0](https://help.okta.com/en-us/content/topics/apps/apps_app_integration_wizard_saml.htm?cshid=ext_Apps_App_Integration_Wizard-saml). 
   Provide a name and the following configuration details: 
{% capture table %} 
<!-- vale off -->
{% table %}
columns:
  - title: Okta setting
    key: setting
  - title: Configuration
    key: configuration
rows:
  - setting: Single Sign-On URL
    configuration: |
      {{site.konnect_short_name}} Org: `https://global.api.konghq.com/v2/authenticate/login_path/saml/acs`<br> Dev Portal: `https://$YOUR_PORTAL_URL/api/v2/developer/authenticate/saml/acs`
  - setting: Audience URI (SP Entity ID)
    configuration: "`https://cloud.konghq.com/sp/SP_ID`"
{% endtable %}
<!-- vale on -->
{% endcapture %}
{{table | indent: 3}}

1. Optional: To include additional user attributes beyond authentication, add the following three attributes in the **Attribute Statements**:
{% capture table %} 
<!-- vale off -->
{% table %}
columns:
  - title: Name
    key: name
  - title: Name format
    key: format
  - title: Value
    key: value
rows:
  - name: "`firstName`"
    format: Unspecified
    value: user.firstName
  - name: "`lastName`"
    format: Unspecified
    value: user.lastName
  - name: "`email`"
    format: Unspecified
    value: user.email
{% endtable %}
<!-- vale on -->
{% endcapture %}
{{table | indent: 3}}

1. Optional: If you want to use group claims for {{site.konnect_short_name}} [developer team mappings](#team-mapping-configuration), [configure a groups attribute claim](https://developer.okta.com/docs/guides/customize-tokens-groups-claim/main/#add-a-groups-claim-for-a-custom-authorization-server) and fill in the following fields:
{% capture table %} 
<!-- vale off -->
{% table %}
columns:
  - title: Name
    key: name
  - title: Name format
    key: format
  - title: Filter
    key: filter
  - title: Filter value
    key: value
rows:
  - name: groups
    format: Unspecified
    filter: Matches regex
    value: ".*"
{% endtable %}
<!-- vale on -->
{% endcapture %}
{{table | indent: 3}}

1. [Generate a signing certificate](https://help.okta.com/en-us/content/topics/apps/manage-signing-certificates.htm) to use in {{site.konnect_short_name}}.

1. [Assign desired groups and users to the new Okta application](https://help.okta.com/en-us/content/topics/users-groups-profiles/usgp-assign-apps.htm).

{% endnavtab %}
{% endnavtabs %}

Now you can finish [setting up SSO in {{site.konnect_short_name}}](#sso-configuration).

## Enable OIDC

As an alternative to {{site.konnect_short_name}}'s native authentication, you can enable single sign-on (SSO) using any identity provider (IdP) that supports [OpenID Connect](https://openid.net/connect/).
This allows your users to log in to {{site.konnect_short_name}} using their existing SSO credentials

To enable OIDC:

1. Send a `POST` or `PATCH` request to the [`/identity-providers` endpoint](/api/konnect/identity/#/operations/create-identity-provider), making sure `oidc` is selected for `type` and `scopes`. The `profile` and `email` scopes are recommended so {{site.konnect_short_name}} 
obtains the user's name and email address in the token response.
1. Once the SSO configuration is set, you can enable the OIDC auth method with the [`/authentication-settings` endpoint](/api/konnect/identity/#/operations/update-authentication-settings) by setting `oidc_auth_enabled: true`.
1. Verify the configuration is valid by logging in at `https://cloud.konghq.com/login/$YOUR_LOGIN_PATH`.

## Team mapping configuration

When you configure SSO for the {{site.konnect_short_name}} platform and Dev Portal, you have the option to configure team mappings from your IdP as well. Team mappings allow you to map teams from your IdP to {{site.konnect_short_name}} Org teams and Dev Portal teams. 

After you configure {{site.konnect_short_name}} SSO settings in your IdP, you can configure team mappings with the following:

<!--vale off-->
{% table %}
columns:
  - title: Feature
    key: feature
  - title: UI setting
    key: ui
  - title: API endpoint
    key: api
rows:
  - feature: "{{site.konnect_short_name}} platform"
    ui: "Go to the [Team Mapping](https://cloud.konghq.com/global/organization/settings#team-mappings ) in the Organization settings."
    api: "[`/identity-provider/team-mappings`](/api/konnect/identity/#/operations/update-idp-team-mappings)"
  - feature: "Dev Portal"
    ui: "Click on a [Dev Portal](https://cloud.konghq.com/portals/) and go to Team Mappings in its settings."
    api: "[`/portals/{portalId}/identity-provider/team-group-mappings`](/api/konnect/portal-management/#/operations/update-portal-team-group-mappings)"
{% endtable %}
<!--vale on-->

When you configure team mappings for the {{site.konnect_short_name}} org, keep the following in mind:
* You must have at least one group mapped to save configuration changes.
* To manage user and team memberships in {{site.konnect_short_name}} from the Organization settings, select the **{{site.konnect_short_name}} Mapping Enabled** checkbox. If you enable this, approving new users is a two step process. New users logging in to {{site.konnect_short_name}} with their IdP credentials will get an access error and {{site.konnect_short_name}} administrators will need to map the new user to a valid team before the user is granted access.
* To assign team memberships by the IdP during SSO login via group claims mapped to {{site.konnect_short_name}} teams, select the **IdP Mapping Enabled** checkbox and enter your IdP groups in the relevant fields.

Once team mappings are set up:
* IdP users belonging to the mapped groups can log in to {{site.konnect_short_name}}.
* When a user logs into {{site.konnect_short_name}} with their IdP account
for the first time, {{site.konnect_short_name}} automatically provisions an account with the
relevant roles.
* If your org already has non-admin {{site.konnect_short_name}} users before
mapping, on their next login they will be mapped to the teams defined by their IdP group membership.
* An organization admin can view all registered users in
{{site.konnect_short_name}}, but cannot edit their team membership from the {{site.konnect_short_name}} side. To
manage automatically-created users, adjust user permissions through the IdP, or adjust the team mapping.

Any changes to the mapped IdP groups on the IdP side are reflected in
{{site.konnect_short_name}}. For example:
* Removing a user from a group in the IdP also deactivates their
{{site.konnect_short_name}} account.
* Moving a user from one group to another changes their team in {{site.konnect_short_name}}
to align with the new group-to-team mapping.


## {{site.konnect_short_name}} Dev Portal Editor considerations

To seamlessly use the {{site.konnect_short_name}} Portal Editor preview experience, you may need to configure your IdP with additional settings to ensure the login flow and preview environment function properly.

* The Sign On URL (SSO URL) must be set to the path on your Dev Portal's custom domain, if applicable. For example: `https://example.com/login/sso`
* For for OIDC authentication, you should add an additional sign-in redirect URI set to the Kong-managed {{site.konnect_short_name}} Portal Editor Preview domain: `https://$YOUR_SUBDOMAIN.$GEO.kongportals.com/login`
* Specifically for SAML, the primary Reply URL (Assertion Consumer Service URL) must be set to the path on your Dev Portal's custom domain, if applicable. For example: `https://example.com/api/v2/developer/authenticate/saml/acs`
  * To support the {{site.konnect_short_name}} Portal Editor, you must also set an additional Reply URL (other callable SSO URLs) to the Kong-managed {{site.konnect_short_name}} Portal Editor Preview domain: `https://$YOUR_SUBDOMAIN.$GEO.kongportals.com/api/v2/developer/authenticate/saml/acs`
* Your IdP must be configured to allow embedding its sign in screen within an iframe. For example, in Okta, you can configure [Trusted Origins](https://help.okta.com/en-us/content/topics/api/trusted-origins-iframe.htm) with your IdP. You should add `https://cloud.konghq.com` as a Trusted Origin for iframe embedding. This will allow your users to use the IdP login flow in the {{site.konnect_short_name}} Portal Editor preview environment.
