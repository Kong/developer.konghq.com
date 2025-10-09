# UI writing standards

When an action can be done in the UI, we need to provide some UI instructions. What type of UI instructions we provide depends on if the UI is the or one of the primary ways the user will configure something:

* **Primary:** Create a UI how-to guide. Provide navigation, actions, and a validation step. Like all how-tos, always provide a validation step at the end.
* **Secondary:** Add UI instructions to a reference guide or landing page as minimum viable UI documentation. Provide a navigation path to the feature at a minimum.

**Important**: If the UI is unclear, raise an issue with PM/Design. We avoid using documentation as a UI bandaid. Still document the UI if a release requires it.

## UI steps standards

Regardless of what page the UI is documented on or if it's the primary or secondary method of configuring a feature, all UI instructions must adhere to the following guidelines. These ensure consistency and predictability for UI automated tests. Our standards are constructed in a way to match these best practices:
* Write each step to contain only one action. One action per step makes the workflow easier to follow and ensures UI automation tests can target a single control at a time.
* Tell the user the location of a component before telling them the action to perform on the component.
* All actions are documented. Do not skip steps like **Save** or **Next**. Do not provide a deep link to a UI location without providing the path to get to that location.
* Provide real values to enter or select from fields. If you can’t provide a real value, provide an example value and make it clear the user needs to replace it with a real value.
* Always use the exact label that is present in the UI. Clear naming helps users find controls quickly and ensures that the documentation matches the product.

The following sections describe how to write steps for each UI component.

### Field

**Format:** In the \**{field name}** field, enter \`{value}\`.

**Examples:** In the **Key** field, enter \`my-secret\`.

### Checkbox

**Format:** Select the \**{checkbox name}** checkbox.

**Examples:** Select the **Enable setting** checkbox.

### Toggle

**Format:**
* Enable \**{toggle name}**.
* Disable \**{toggle name}**.

**Examples:**
* Enable **Role-based access control (RBAC)**.
* Disable **Role-based access control (RBAC)**.

### Radio button

**Format:** Select \**{radio button name}**.

**Examples:** Select **OIDC**.

### Button

**Format:** Click \**{button name}**.

**Examples:** Click **Save**.

Omit the + in UI instructions for buttons.

### Tab

**Format:** Click the \**{tab name}** tab.

**Examples:** Click the **General** tab.

### Dropdown

**Format:** From the \**{menu name}** dropdown menu, select “{value}”.

**Examples:** From the **Actions** dropdown menu, select “Edit”.

### Main sidebar item (L1)

**Format:** In the {{site.konnect_short_name}} sidebar, click \[\**{L1 sidebar name}**](/link).

**Examples:** In the {{site.konnect_short_name}} sidebar, click [**Dev Portal**](/link).

### Secondary sidebar item (L2)

**Format:** In the {L1 sidebar name} sidebar, click \[\**{L2 sidebar name}**](/link).

**Examples:** In the Service Catalog sidebar, click [**Integrations**](/link).

### List

**Format:** Click \**{value}**.

**Examples:** Click **quickstart**.

### Icon

**Format:** Click the {icon name} icon.

**Examples:** 
* Click the settings icon.
* Click the edit icon.
* Click the action menu icon.

## UI instruction how-tos

A UI how-to provides all possible steps in UI instructions. They should be written like all other how-tos where there are no hidden prerequisites and we assume the user starts from scratch. Like all how-tos, always provide a validation step at the end.

**Do not** provide tabs in how-tos for other methods. For example, a how-to must not have a tab for UI and API steps in the body of the how-to. This complicates automated tests and makes it more difficult for users as steps between methods don't always align.

See the following examples of UI how-to instructions:
* [Discover and govern APIs with Service Catalog](https://developer.konghq.com/how-to/discover-and-govern-apis-with-service-catalog/)
* [Discover AWS Gateway APIs in Service Catalog with the Konnect UI](https://developer.konghq.com/how-to/discover-aws-gateway-apis-using-konnect-ui/)
* [Create a dashboard from a template](https://developer.konghq.com/how-to/create-custom-dashboards/)
* [Write a pre-request script to add an environment variable in Insomnia](https://developer.konghq.com/how-to/write-pre-request-scripts/)

## Minimum-viable UI instruction examples

A **minimum-viable UI example** shows the UI path to the feature without creating a full tutorial. Use minimum-viable UI when automation is the norm. When other methods (like API or Terraform) are supported, include nav tabs with minimum-viable instructions for each method.

See the following examples of minimum-viable UI instructions:
* [Dev Portal APIs](https://developer.konghq.com/dev-portal/apis/)
* [Service Catalog services](https://developer.konghq.com/service-catalog/services/)

## Third-party instructions

We document third-party instructions in the following conditions:
* The third-party product must be configured in a specific way for our product to work. Common examples would be SSO or transit gateways. Example: [AWS configuration for Transit Gateway peering](https://developer.konghq.com/dedicated-cloud-gateways/transit-gateways/#aws-configuration-for-transit-gateway-peering)
* The same rules apply to third-party instructions as our own. We write each step the same way we write ours and we provide documentation for all the primary ways a user interacts with the third-party (for example, CLI, UI, or API). Example: [Configure an IAM role in AWS for Service Catalog](https://developer.konghq.com/service-catalog/integrations/aws-api-gateway/#configure-an-iam-role-in-aws-for-service-catalog)
* If a user needs an entity from the third-party as a prerequisite, but it doesn't require a special configuration for Kong, you can link to third-party instructions instead. Example: [AWS configuration for Vaults](https://developer.konghq.com/how-to/configure-aws-secrets-manager-as-a-vault-backend-with-vault-entity/#aws-configuration) 

 
