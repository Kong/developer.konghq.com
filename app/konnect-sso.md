---
title: "{{site.konnect_short_name}} SSO"
content_type: reference
layout: reference

products:
    - gateway

min_version:
  gateway: '3.4'

description: "{{site.konnect_short_name}} supports multiple SSO options"

related_resources:
  - text: "Authentication"
    url: /gateway/authentication/

works_on:
  - konnect

faqs:
  - q: I'm experiencing authentication issues and I have a large number of groups, how do I troubleshoot this?
    a: | 
      If users are assigned a very large number of groups (over 150 in most cases), the IdP may send the groups claim in a non-standard manner, causing authentication issues. 

      To work around this limitation in the IdP, we recommend using group filtering functions provided by the IdP for this purpose. 
      Here are some quick reference guides for common IdPs:
      * [Azure group filtering](https://learn.microsoft.com/en-us/azure/active-directory/hybrid/connect/how-to-connect-fed-group-claims#group-filtering) 
      * [Okta group filtering](https://support.okta.com/help/s/article/How-to-send-certain-groups-that-the-user-is-assigned-to-in-one-Group-attribute-statement)

      You may need to contact the support team of your identity provider in order to learn how to filter groups emitted for the application.
---

{{site.konnect_short_name}} supports external single sign-on authentication using an Identity Provider (IdP). Using SSO in {{site.konnect_short_name}}, you can enable authentication for the following:
* **The {{site.konnect_short_name}} platform:** Allow [Org admins](/teams-and-roles/) to log in with SSO. This is an alternative to {{site.konnect_short_name}}'s [built-in authentication](https://cloud.konghq.com/global/organization/settings#authentication-scheme).
* **Dev Portals:** Allow developers to log in to the [Dev Portal](/dev-portal/) with SSO.

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
    api: "[`/identity-providers`](/api/konnect/identity/v3/#/operations/create-identity-provider)<sup>1</sup>"
  - feature: "Dev Portal"
    ui: "Go to the Identity settings for your [Dev Portal](https://cloud.konghq.com/portals/)"
    api: "[`/portals/{portalId}/identity-providers`](/api/konnect/portal-management/v2/#/operations/create-portal-identity-provider)"

{% endtable %}
<!--vale on-->

{:.info}
> **Note:** When you configure the organization login path, enter a unique string that will be used in the URL your users use to log in. For example: `examplepath`.
> * The path must be unique *across all {{site.konnect_short_name}} organizations*. If your desired path is already taken, you must to choose another one.
> * The path can be any alphanumeric string.
> * The path does not require a slash (`/`).

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
* **{{site.konnect_short_name}} Org:** Test the SSO configuration by navigating to the login URI based on the organization login path you set earlier. For example: `https://cloud.konghq.com/login/examplepath`, where `examplepath` is the unique login path string set in the previous steps.
* **Dev Portal:** Test the SSO configuration by navigating to the callback URL for your Dev Portal. For example: `https://{portalId}.{region}.portal.konghq.com/login`.

If the configuration is correct, you will see the IdP sign-in page. 

You can now manage your organization's user permissions entirely from the IdP application.

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
    api: "[`/identity-provider/team-mappings`](/api/konnect/identity/v3/#/operations/update-idp-team-mappings)"
  - feature: "Dev Portal"
    ui: "Click on a Dev Portal](https://cloud.konghq.com/portals/) and go to Team Mappings in its settings."
    api: "[`/portals/{portalId}/identity-provider/team-group-mappings`](/api/konnect/portal-management/v2/#/operations/update-portal-team-group-mappings)"

{% endtable %}
<!--vale on-->

When you configure team mappings for the {{site.konnect_short_name}} org, keep the following in mind:
* Each {{site.konnect_short_name}} team can be mapped to **one** IdP group. You must have at least one group mapped to save configuration changes.
* To manage user and team memberships in {{site.konnect_short_name}} from the Organization settings, select the **Konnect Mapping Enabled** checkbox. If you enable this, approving new users is a two step process. New users logging in to {{site.konnect_short_name}} with their IdP credentials will get an access error and {{site.konnect_short_name}} administrators will need to map the new user to a valid team before the user is granted accesss.
* To assign team memberships by the IdP during SSO login via group claims mapped to {{site.konnect_short_name}} teams, select the **IdP Mapping Enabled** checkbox and enter your IdP groups in the relevant fields.