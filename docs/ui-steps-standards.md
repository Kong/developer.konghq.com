# UI writing standards

Use this page to write clear, consistent UI instructions.

## Prioritize workflows

Explain the end-to-end task that a user finishes in the UI in a workflow format. Use “pure CRUD” format only when it’s a known pain point, for example, in troubleshooting.

- **Workflow**: A sequence of goal-oriented steps that guides a user through a process in a clear, repeatable order.
- **CRUD**: A method based on the four main user interface operations: Create, Read, Update, and Delete. These operations let users add, view, change, or remove information.

| Workflow | CRUD |
| ----- | ----- |
| **Purpose:** Guide the user through a full, end-to-end task that they want to achieve. **Structure:** Write step-by-step instructions with action verbs. Use an ordered list. Shape it like a “How-to” or “Quickstart.” **When to use:** Use this when users need to complete something: “set up X,” “deploy Y,” “configure Z.” **Value:** Users complete tasks without switching contexts; validation at the end proves success. **Example:** [Get started with Kong Gateway](https://developer.konghq.com/gateway/get-started/) | **Purpose:** List what actions are possible (create, read, update, delete) or what fields exist, without placing them in the context of a full task. **Structure:** Present bullets or a table of operations or schema. Keep the tone neutral and reference-style. **When to use:** Use this on reference pages, schema docs, API endpoints, or plugin configs. Basically anywhere that users just need to know what can be done. **Value:** Fast lookup for parameters, options, and limits without narrative overhead. **Example:** [Gateway configuration reference](https://developer.konghq.com/gateway/configuration/) |

## UI verbs cheat-sheet
| UI component | Verbs | Example |
| :---- | :---- | :---- |
| Field | Enter | Enter \`my-secret\` in the **Key** field. |
| Checkbox | Select | Select the **Enable setting** checkbox. |
| Radio button | Select | Select **OIDC**. |
| Toggle | Enable/Disable | Enable **Role-based access control (RBAC)**. |
| Button | Click | Click **Save**. |
| Tab | Click | Click the **General** tab. |
| Dropdown | Select | Select “Edit” from the **Actions** dropdown menu. |
| Sidebar link | Click | In **Konnect**, navigate to **Dev Portal** in the sidebar. |
| List (of control planes, Dev Portals, etc.) | Click | Click **quickstart**. |

# Scope the amount of UI documentation

Match the level of UI documentation to the way users actually configure and use the feature. Don't document the UI in abstract or exhaustive detail, like a 'menu map'; instead, tailor the steps and explanations to reflect how users really perform the task in the product.

* **Full UI how-to:** Use when the UI is the **primary workflow**. Provide navigation, actions, and a validation step. Always validate at the end of a full UI workflow.
* **Minimum-viable UI:** Use when automation is the **dominant workflow**. Provide a short pointer path with one key action, and then pair it with automation examples using tabs. Always give a navigation path for minimum-viable UI.

**Important**: If the UI is unclear, raise an issue with PM/Design. Still document the UI if a release requires it.

## Full UI how-to

Use a full UI how-to when the UI is the main way to configure or use the feature, for example:

* Set up an integration
* Configure the Dev Portal
* Manage Service Catalog flows

When creating UI how-to documentation, remember to:

- [ ] Write a clear **title and purpose**: “Set up ServiceNow integration in Kong Manager”.  
- [ ] Provide exact **navigation steps**: “In Kong Manager, go to **Integrations** > **ServiceNow**”.  
- [ ] Use **imperative verbs** for every action: “Click **Save**”, “Select a Service”, “Enable the Plugin”.  
- [ ] Show **sequential order** with numbered steps.  
- [ ] Add a **validation step** at the end: “Send a request to confirm the Plugin applies to the Route”.

To avoid confusing or misleading users:

* Don’t stop at configuration. Instead, always show the validation step.  
* Don’t use vague cues like “go to the screen.” Be exact. 
* Don’t duplicate full workflows across multiple pages. Link to the canonical how-to if needed.

[Configure OpenID Connect with the authorization code flow](/how-to/configure-oidc-with-auth-code-flow/) is an example that shows clear tasks, exact navigation, and validation.

## Minimum-viable UI

A **minimum-viable UI example** shows the UI path without creating a full tutorial. It is a pointer, not a workflow, and appears side-by-side with automation methods. Don’t bury UI instructions inside automation sections; instead always separate them clearly and give UI its own tab or block.

Use minimum-viable UI when **automation is the norm**. For example:

* [Managing configuration with decK](https://developer.konghq.com/deck/gateway/konnect-configuration/)  
* [Provisioning with Terraform](https://developer.konghq.com/custom-dashboards/)  
* [Performing operations with the Admin API](https://developer.konghq.com/api/gateway/admin-ee/3.11/)

Minimum-viable UI documentation checklist:

- [ ] Provide the **navigation path**: “Go to **Services** > **Add Service**”.  
- [ ] Include the **single key action**: “Click **Create**”.  
- [ ] Pair with automation steps using [**tabs**](/contributing/#tab-groups) or a **side-by-side layout**: UI / decK / Terraform / Admin API.  
- [ ] Keep it short. Do not expand into a full workflow.

## Format UI steps

Format UI steps to tell users *where they need to be first*, then *what action they take*. Always finish on the action. Users need orientation before being asked to act. Without knowing where they are, they may get lost or make errors because of cognitive load.

**Formula**: `[Navigation context], [UI control/location reference] + Action verb + Target.`

For example:
* *“From the sidebar, select **Organizations**.”*  
* *“In Kong Manager, go to **Services** > **Add Service**, then click **Create**.”*

UI-step checklist: 
- [ ] A navigation context: where the user is or should go to begin
- [ ] A UI control or location reference: sidebar, menu, tab
- [ ] A precise action verb + target: Click, Select, Enter 

## Write UI steps

Use the following rules to write instructions for the Kong UI so that users follow them easily and automation tests work reliably.

### Include one action in each step

Write each step to contain only one action. One action per step makes the workflow easier to follow and ensures UI automation tests can target a single control at a time.

| Do | Don't |
| :---- | :---- |
| In the Key field, enter `my-secret`. | In the Key field, enter `my-secret`, and then click Save. | 

### Name and point to controls accurately

Always use the exact label that is present in the UI. Clear naming helps users find controls quickly and ensures that the documentation matches the product. Helpful conventions to follow are:

* Use icon descriptions when needed: *Click the Settings (cog) icon.*  
* Use carets to show menu navigation: *Service actions \> Add new version.*   
* Write button labels in full, not as symbols. For example, write *New Plugin*, not *\+*.

| Do | Don't |
| :---- | :---- |
| From the **Menu** tab, click **Add menu item.** | From the tab, click the item button for the menu. |

### Give real, selectable values

Use real values that can be selected or entered in fields. If you can’t provide a real value, provide an example value and make it clear the user needs to replace it with a real value. Real examples reduce ambiguity and give users confidence that they are entering data in the correct format. They also support reliable test cases.
* Replace *portal.example.com* with the Kong domain. 
* Use numerals for numbers; users scan them faster and they reduce ambiguity for online readers.

| Do | Don't |
| :---- | :---- |
| In the **Key** field, enter \`my-secret\`. | Enter a secret in the **Key** field. |
| In the **URL** field, enter \`https://konghq.com/\`. | Enter your Dev Portal URL in the **URL** field. |
| Set `Retries` to `3`. | Set retries to three. |


### Bold UI component names

Use bold text for visible UI labels such as fields, tabs, buttons, dropdowns, and sidebar links. Bold formatting matches the user’s visual experience, reduces scanning effort, and highlights actionable elements; overall reducing cognitive load.

| Do | Don't |
| :---- | :---- |
| In Konnect, navigate to **Dev Portal** in the **sidebar** | In Konnect, navigate to Dev Portal in the sidebar. |
| In the **URL** field, enter \`https://konghq.com/\`. | Enter your Dev Portal URL in the **URL** field. |

### Dropdown selection formatting

When the user must select an option from a dropdown menu, put the selected option in quotation marks to distinguish it from menus and other UI nouns. It clarifies which part is static (menu) and which part is dynamic (item).

| Do | Don't |
| :---- | :---- |
| From the **Actions** menu, select “Edit”. | From the **Actions** menu, select Edit. |
| In **Role**, select “Admin”. | Choose Admin from the role. |

**Example:** In [Dev Portal APIs](https://developer.konghq.com/dev-portal/apis/), dropdown actions are described clearly, e.g. *Select “New API”*.

### Field entry formatting

When the user must enter specific text into a field, wrap the literal entry in backticks. 

| Do | Don't |
| :---- | :---- |
| In the **Key** field, enter `my-secret`. | In the **Key** field, enter “my-secret”. |
| In **Role**, enter `Admin`. | Choose Admin from the role. |
| In the Username field, enter `alice`. | In the Username box, type alice without marks. |


### Accessibility & inclusivity

Some users operate assistive technology or translation; idioms do not translate, keyboard users follow focus order and labels. Construct documentation to include all users with the accessibility checklist:

- [ ] Include descriptive alt text for images.
- [ ] Avoid idioms and slang so translated content remains clear.

| Do | Don't |
| :---- | :---- |
| Click **Save**, then press Enter. | Hit the button to lock it in. |
| Add alt text: “Analytics line chart that shows a spike on July 10.” | Add alt text: Useful chart.” |


### Add a step for saving the configuration

Always include a separate step for saving settings or configuration changes. Do not assume that the user knows to save.

| Do | Don't |
| :---- | :---- |
| Click **Save**. | Save the configuration. |
| Click **Apply**, then click **Save**. | Apply and it should save. |

### Minimum-viable tooling parity (UI \+ decK \+ API \+ Terraform)

For features that support automation, show automation options next to UI steps with `{% navtabs %}`, for example, UI, decK, API, Terraform. Provide a minimal working example or link to the exact reference for each method.

| Do | Don't |
| :---- | :---- |
| Warn that `deck gateway sync` removes unmanaged config and show tag-based partial apply. | Reference decK without noting destructive behavior. |
| Link to Terraform provider resources and a focused how-to. | Say “Use Terraform” with no resource or example. |

**Examples on Kong Docs that demonstrate parity:**

* [Deploy Kong Mesh with Terraform + Konnect](https://developer.konghq.com/mesh/deploy-with-terraform-konnect/) provides concrete Terraform resources, variables, and `terraform apply`.  
* [Import Konnect Mesh deployment to Terraform](https://developer.konghq.com/mesh/import-konnect-deployment-to-terraform/) shows how to bring an existing deployment under IaC control.  
* [decK gateway sync](https://developer.konghq.com/deck/gateway/sync/) documents declarative sync behavior and cautions.  
* [Terraform providers for Kong](https://developer.konghq.com/terraform/) gives resource examples and how-to links.

### Third-party UIs

We don’t document 3rd party UIs. Avoid step-by-step screenshots of third-party products; deep-link to vendor docs instead. This keeps Kong docs maintainable, reduces staleness risk, and focuses our effort on what Kong controls.

| Do | Don't |
| :---- | :---- |
| To configure SSO with Okta, see Okta’s documentation. | Click **Applications**, click **Create App Integration**, select **“OIDC”…** |
| Explain where third-party settings appear in Kong and link out for details. | Replicate the vendor’s entire wizard with screenshots. |

**Example:** “[Supported third-party dependencies](https://developer.konghq.com/gateway/third-party-support/)” lists verified external tools and versions; it does not include third-party UI walkthroughs. 
