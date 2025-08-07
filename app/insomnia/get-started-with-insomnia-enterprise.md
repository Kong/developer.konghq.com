---
title: Get started with Insomnia Enterprise

description: Learn how to fully set up your Insomnia Enterprise account.

content_type: reference
layout: reference
breadcrumbs: 
  - /insomnia/
  - /insomnia/enterprise/
products:
    - insomnia
tier: enterprise
related_resources:
  - text: Enterprise
    url: /insomnia/enterprise/

---

## Activate your Enterprise membership

Once you've signed up for the Insomnia Enterprise plan through the [sales team](https://insomnia.rest/pricing/contact), you'll get an activation code.
The first thing you'll need to do is go to [Change subscription plan](https://app.insomnia.rest/app/subscription/update), select the Enterprise plan, and enter your activation code.
Once this is done, you'll have access to all the Enterprise features.

## Create organizations

By default, you account is created with an organization named **Personal Workspace**. 
You can invite users to that organization, but you can also create other organizations to manage access to projects.
For example, you could have a _Product_ organization and an _Engineering_ organization, with different projects accessible to different users.

To create organizations, go to [**Your organizations**](https://app.insomnia.rest/app/dashboard/organizations) and click **New organization**.

## Create teams

You can add individual users to organizations, but you can also create teams and link them to organizations.
Using the example above, you could create:

* An _Admin_ team which has access to both organizations
* A _Dev_ team which has access to the engineering organization only
* A _Product_ team which has access to the product organization only

These teams can then be synchronized with your [SCIM](#set-up-scim) provider.

To create teams, go to [**Teams**](https://app.insomnia.rest/app/enterprise/team) and click **Create Team**. Once a team is created, open it and click the **+** button to link one or several organizations to the team. 

Each time a new member is added to the team, they will automatically have access to the linked organizations.

## Invite users

...

## Add a domain

Adding a domain allows you to automatically manage users with email addresses in that domain.

For a full how-to guide on adding and verifying your domain, go to [Set up a domain in Insomnia](/insomnia/). <!-- @todo -->

## Enable SSO

Once your domain is verified, you can set up SSO with SAML 2.0 or OIDC with your preferred provider.

See our how-to guides to learn how to configure SSO for Insomnia with:
* [Okta SAML](/how-to/okta-saml-sso-insomnia/)
* [Okta OpenID Connect](/how-to/okta-oidc-sso-insomnia/)
* [Azure SAML](/how-to/azure-saml-sso-insomnia/)
<!-- what else do we support? -->



