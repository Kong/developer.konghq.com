# UI writing standards

Use this page to write clear, consistent UI instructions and to include screenshots. It aligns with the Google Developer Documentation Style Guide and with Kong Docs’ site components.

# Scope and audience

* **Audience:** Internal technical writers  
* **Purpose:** Establish one house style for UI instructions and screenshots → easy to apply, testable, and maintainable across products  
* **Goal**: [Consistency](https://docs.google.com/document/d/1bpr1ziXZoCPGLLFLvYb5n96AGchG0MvoDT4_mxWCc_E/edit?tab=t.gx4tbwyaksdw#heading=h.pb0ddiqpumod), testability, and maintainability across products  
* **Foundation**: [Google for Developers](https://developers.google.com/style/voice)

# Core principles

When you write anything, you must include our core principles into every piece of work:

## Prioritize workflows

**Rule:** Explain the end-to-end task that a user finishes in the UI. Split out “pure CRUD” only when it’s a known pain point (often in troubleshooting)

| Workflow | CRUD |
| ----- | ----- |
| **Purpose:** Guide the user through a full, end-to-end task that they want to achieve. **Structure:** Write step-by-step instructions with action verbs. Use an ordered list. Shape it like a “How-to” or “Quickstart.” **When to use:** Use this when users need to complete something: “set up X,” “deploy Y,” “configure Z.” **Value:** Users complete tasks without switching contexts; validation at the end proves success. **Example:** [Get started with Kong Gateway](https://developer.konghq.com/gateway/get-started/) | **Purpose:** List what actions are possible (create, read, update, delete) or what fields exist, without placing them in the context of a full task. **Structure:** Present bullets or a table of operations or schema. Keep the tone neutral and reference-style. **When to use:** Use this on reference pages, schema docs, API endpoints, or plugin configs. Basically anywhere that users just need to know what can be done. **Value:** Fast lookup for parameters, options, and limits without narrative overhead. **Example:** [Gateway configuration reference](https://developer.konghq.com/gateway/configuration/) |

## Every page is page one

* **Rule:** Keep the concepts, steps, and validation together on one page. Don’t shatter the story into multiple pages. ([Kong Docs](https://developer.konghq.com/contributing/)) \> Don’t split a task across multiple pages—group conceptual background, step-by-step instructions, and validation (testing or outcome) all in one page..  
* **Goal**: Let readers complete a task in one flow without bouncing around; reduce friction, cognitive load, and context switching.  
* **Why use this**: According to Google’s style guide, procedures should be clear, self‑contained workflows. Self-contained procedures improve usability; place everything required to execute the task on the same page.  
* **For Kong users**: It means that when they want to do something they get all they need: what to know, how to do it, and how to confirm success, without hunting through several pages.  
  For example, [configure OIDC](https://developer.konghq.com/how-to/configure-oidc-with-user-info-auth/).

## Use active voice, present tense, plain English

**Rule:** Use active voice, present tense, plain English to clarify agency.

| Active voice | Present tense | Plain English |
| ----- | ----- | ----- |
| **What**: The subject of the sentence performs the action. **Example**: “*You configure…*” instead of “*Configuration is completed*.” **Tip**: A quick test is to see if “…by zombies” can be added to your sentence. If it can, your sentence is passive. Prefer active forms that name the actor: “Kong Gateway applies the policy.” For example, “*Configuration is completed… **by zombies**.*” | **What**: Use present tense to keep instructions immediate and actionable. Describe how Kong works, how a user interacts with the product, or how an action applies right now.  **Example**: Your verbs will look like this: *“Configure,” “Runs,” “Applies”, “Investigate”* **Note**: Only use past or future tense when you explicitly narrate history or future roadmaps. For example, in a changelog: *“This feature was added in 3.3”*. | **What**: Use simple, straightforward words and sentence structures. Avoid: Jargon that only insiders know. Overly formal or complex constructions. Nominalizations: turning verbs into nouns, e.g., *“the configuration of”* instead of *“configure”*. Passive voice that hides the actor. For example, *“The request is handled”* vs. *“Kong Gateway handles the request”*. **Example**: Complex and unclear: *“Prior to the deployment of the Kong Gateway, the initialization of the database connection is undertaken.”* Preferred Plain English: *“**Before you deploy** Kong Gateway, **initialize** the database connection.”* |

## Write for a global audience; be inclusive

**Rule:** Rely on simple words, avoid idioms, and write bias-free language.

**What**: Writing for a global audience means we:

* Use **simple, clear language** so that non-native English speakers can understand.  
* Avoid idioms or colloquialisms that don’t translate or assume specific cultural context.  
* Use language that **does not exclude or offend** people of any ability, gender, race, religion, sexual orientation, or other identity.  
* Use **bias-free, people-first** language.

For more information, go to the [Google Developer styleguide](https://developers.google.com/style/inclusive-documentation). Apply inclusive wording across Dev Portal, Gateway, and Mesh docs consistently.

# When to document the UI (and how much)

**Rule**: Match the level of UI documentation to the way users actually configure and use the feature.

* **Full UI how-to:** when the UI is the **primary workflow**.  
* **Minimum-viable UI:** when automation (decK, Terraform, Admin API) is the **dominant workflow**.  
  Always validate at the end of a full UI workflow. Always give a navigation path for minimum-viable UI.

**Important\!**: Do not use docs to paper over UX gaps. If the UI is unclear, raise an issue with PM/Design. Still document the UI if a release requires it.

## Full UI how-to

A step-by-step tutorial that guides a user through an entire task in the Kong Manager UI, including:

* Navigation,  
* Actions,  
* A validation step to prove success.

Use a full UI how-to when the UI is the **main way to configure or use the feature**, for example:

* Setting up an integration. For example, ServiceNow  
* Configuring the Dev Portal  
* Managing Service Catalog flows

When creating UI how-to documentation, remember to:

- [ ] Write a clear **title and purpose** (“Set up ServiceNow integration in Kong Manager”).  
- [ ] Provide exact **navigation steps** (“In Kong Manager, go to **Integrations** \> **ServiceNow**”).  
- [ ] Use **imperative verbs** for every action (“Click **Save**”, “Select a Service”, “Enable the Plugin”).  
- [ ] Show **sequential order** with numbered steps.  
- [ ] Add a **validation step** at the end (“Send a request to confirm the Plugin applies to the Route”).

To avoid confusing or misleading the reader, when writing:

* Don’t stop at configuration. Instead, always show the validation step.  
* Don’t use vague cues like “go to the screen.” Be exact.  
* Don’t duplicate full workflows across multiple pages. Link to the canonical how-to if needed.

**Example:** [Dev Portal setup](https://developer.konghq.com/dev-portal/) patterns show “navigate to **Dev Portal**… select **Portal Editor**… then validate visibility or access.” **Model your steps after these patterns.**

## Minimum-viable UI

A **minimum-viable UI example** shows the UI path without creating a full tutorial. It is a pointer, not a workflow. It appears side-by-side with automation methods.  
Use minimum-viable UI when **automation is the norm**. For example:

* [Managing configuration with decK](https://developer.konghq.com/deck/gateway/konnect-configuration/)  
* [Provisioning with Terraform](https://developer.konghq.com/custom-dashboards/)  
* [Performing operations with the Admin API](https://developer.konghq.com/api/gateway/admin-ee/3.11/)

When creating minimum-viable UI documentation, remember to:

- [ ] Provide the **navigation path** (“Go to **Services** \> **Add Service**”).  
- [ ] Include the **single key action** (“Click **Create**”).  
- [ ] Pair with automation steps using **tabs** (UI / decK / Terraform / Admin API) or a **side-by-side layout**.  
- [ ] Keep it short. Do not expand into a full workflow.

To avoid confusing or misleading the reader, when writing:

* Don’t write a full tutorial when users expect to automate.  
* Don’t bury UI instructions inside automation sections. Always separate them clearly.  
* Don’t omit the navigation path—UI users need to know where to start.

# Format UI steps

## **Format of a UI Step**

**Rule:** Tell the reader *where they need to be first*, then *what action they take*. Always finish on the action.

**What:**  
 A UI step sentence should have:

1. A navigation context (where the user is or should go)

2. A UI control or location reference (sidebar, menu, tab, etc.)

3. A precise action verb \+ target (e.g. Click, Select, Enter)

It ends with the action.

**Why:** Users need orientation before being asked to act. Without knowing where they are, they may get lost or make errors.

**How:**

* Always start a UI step with something like: *From the sidebar, …* or *In Kong Manager, go to Integrations …* or *Navigate to the Dev Portal.*  
* Then specify the control or menu location: *sidebar, tab, settings icon, etc.*  
* Then the action: *Select “X,” Click **Save**, Enter `value`, etc.*  
* Do **not** put the action first without telling where, except if the context has just been clearly established and repeated.

**Formula:** `[Navigation context], [UI control/location reference] + Action verb + Target.`

**Do:**

* *“From the sidebar, select **Organizations**.”*  
* *“In Kong Manager, go to **Services** \> **Add Service**, then click **Create**.”*

**Don’t:**

* *“Select Organizations from the sidebar.”* (less nice ordering: action first)  
* *“Click Create. In Services, Add Service.”* (splits context / action out of order)

# Write UI steps

Use the following rules to write instructions for the Kong UI so that users follow them easily and automation tests work reliably.

### Include one action in each step

**Rule**: Where possible, each step should contain only one action.  
**Do**: In the Key field, *enter `my-secret`.*

**Don’t**: *In the Key field, enter `my-secret`, and then click Save.*

**Why**: One action per step makes the workflow easier to follow and ensures UI automation tests can target a single control at a time.[Google for Developers](https://developers.google.com/style)

### Use consistent verbs for UI components

**Rule**: Assign one verb to each control type and use it consistently.

**Why**: Consistent verbs improve comprehension, reduce ambiguity, and stabilize automated test scripts. *Priming*\!

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

### Name and point to controls accurately

**Rule**: Always use the exact label as it appears in the UI.

**Why**: Clear naming helps users find controls quickly and ensures the docs match the product.  
**How:**

* Use icon descriptions when needed: *Click the Settings (cog) icon.*  
* Use carets to show menu navigation: *Service actions \> Add new version.*  
* Say *“Click”*, not “Click on.”  
* Write button labels in full, not as symbols. For example, write *New Plugin*, not *\+*.

**Example**: In [Dev Portal customization](https://developer.konghq.com/dev-portal/portal-customization/), the steps read: *Click **Customization** in the sidebar. From the **Menu** tab, click **Add menu item.***

### Give real, selectable values

**Rule**: Use real values that can be selected or entered in fields. If you can’t provide a real value, provide an example value and make it clear the user needs to replace it with a real value.  
**Why**: Real examples reduce ambiguity and give users confidence that they are entering data in the correct format. They also support reliable test cases.  
**Do**: 

* In the **Key** field, enter \`my-secret\`.  
* In the **URL** field, enter \`https://domain.us.kongportals.com\`.   
  Replace the Dev Portal URL with your actual URL.

**Dont**:

* Enter a secret in the **Key** field.  
* Enter your Dev Portal URL in the **URL** field.

### Bold UI component names

**Rule**: Use bold text for any visible UI component label. For example, field names, tabs, buttons, dropdowns, sidebar links.

**Why**:

* Bold formatting draws the eye to actionable elements.  
* It matches the user’s visual experience in the product  
* It reduces cognitive load, helping users scan quickly.

**Do**: *In Konnect, navigate to **Dev Portal** in the **sidebar***.

**Don’t**: *In Konnect, navigate to Dev Portal in the sidebar.*

### Dropdown selection formatting

**Rule:** When the user must select an option from a dropdown menu, enclose the item name in quotation marks.

**Why**:

* Quotation marks distinguish the selectable item from the menu itself.  
* It clarifies which part is static (menu) and which part is dynamic (item).

**Do**: *From the **Actions** dropdown menu, select “Edit”.*

**Don’t**: *From the Actions dropdown menu, select Edit.*

**Example:** In [Dev Portal APIs](https://developer.konghq.com/dev-portal/apis/), dropdown actions are described clearly, e.g. *Select “New API”*.

### Field entry formatting

**Rule:** When the user must enter specific text into a field, wrap the literal entry in backticks.

**How**:

1. Write *Enter `value` in the **Field name***.  
2. Use backticks around the entry, `` `. `` Don’t use quotes.  
3. Always bold the field label.

**Do**: *In the **Key** field, enter `my-secret`.*

**Don’t**: *In the **Key** field, enter “my-secret”.*

### Add a step for saving the configuration

**Rule:** Always include a separate step for saving settings or configuration changes. Do not assume the user knows to save.

**Do**: *Click **Save***.

**Don’t**: *Save the configuration.*

# Minimum-viable tooling parity (UI \+ decK \+ API \+ Terraform)

**Rule:** For features that support automation, always include examples or links for decK, Admin/Konnect API, and Terraform alongside UI steps; present them with tabs next to UI steps. Use `{% navtabs %}` to render parity clearly, for more information go to [Contributing to docs](https://developer.konghq.com/contributing/).

**Why:**

* Many users prefer automation; they need examples to use in infrastructure-as-code.  
* Showing parity builds confidence that all paths are supported.  
* Reduces friction for platform engineers / DevOps.

**How:**

1. In the how-to, include a **navtabs** component with at least four tabs: **UI**, **decK**, **API**, **Terraform**.  
2. In each tab, show a **minimal working** example:  
   1. **UI**  
       “In Konnect, go to **Dev Portal** \> **Custom domains**. Click **Add domain**. Enter `portal.example.com`. Click **Save**.” [Kong Docs](https://developer.konghq.com/dev-portal/custom-domains/)  
   2. **decK**  
       `# kong.yaml`

   `_format_version: "3.0"`

   `# …your declarative config…`Apply with `deck gateway sync`. Warn that sync deletes config not in the file; use tags for partial apply.

      c. **API (Konnect / Admin)**  
	          **Link** to the **Dev Portal API** OpenAPI spec for the relevant operation (for example, managing portals, pages, or settings).

**Terraform**

	 `# Example: Dev Portal / Gateway resource (illustrative)`

`resource "konnect_gateway_basic_auth" "my_basicauth" {`

  		`username          = "alice"`

  		`password          = "demo"`

  		`consumer_id       = konnect_gateway_consumer.alice.id`

  		`control_plane_id  = konnect_gateway_control_plane.tfdemo.id`

`}`  
**Use the Terraform providers page to select the correct resource and version; include “terraform apply -auto-approve” to validate.**

**Do:**

* Provide a **working Terraform** resource example or link to a focused how-to. For example, deploying Mesh with Terraform + Konnect.  
* **Link to API** endpoints or the relevant OpenAPI spec.  
* **Show decK** usage for parity and migration helpers like `kong2tf` when relevant. 

**Don’t:**

* Leave automation paths undocumented.  
* Assume users can infer API or Terraform usage without examples.

**Examples on Kong Docs that demonstrate parity:**

* [Deploy Kong Mesh with Terraform + Konnect](https://developer.konghq.com/mesh/deploy-with-terraform-konnect/) provides concrete Terraform resources, variables, and `terraform apply`.  
* [Import Konnect Mesh deployment to Terraform](https://developer.konghq.com/mesh/import-konnect-deployment-to-terraform/) shows how to bring an existing deployment under IaC control.  
* [decK gateway sync](https://developer.konghq.com/deck/gateway/sync/) documents declarative sync behavior and cautions.  
* [Terraform providers for Kong](https://developer.konghq.com/terraform/) gives resource examples and how-to links.

# Third-party UIs

**Rule**: We don’t document 3rd party UIs. Avoid step-by-step screenshots of third-party products; deep-link to vendor docs instead.

**Why:** Keeps Kong docs maintainable, reduces staleness risk, and focuses our effort on what Kong controls.

**How:** When a task involves external software, write a short description and link out. Do not include vendor UI step sequences.

**Do:** Write: *“To configure authentication via \[VendorName\], see VendorName’s docs here.”*

**Don’t:**

* Include full walkthroughs of vendor UIs inside Kong docs.  
* Embed step-by-step screens of third-party interfaces that you can’t keep updated.

**Example:** “[Supported third-party dependencies](https://developer.konghq.com/gateway/third-party-support/)” lists verified external tools and versions; it does not include third-party UI walkthroughs. 

# Callouts and notes

**Rule:** Use informational or warning callouts sparingly. Choose the correct severity.

We have a collection of elements to use:

```json
{:.warning} # yellow note
{:.info} # blue note
{:.success} # green note
{:.danger} # red note
{:.neutral} # grey note
{:.decorative} # purple note
{:.info .no-icon} # add to any note type to remove the icon 
```

**Why:**

* Too many callouts distract the reader.  
* Proper severity helps the reader evaluate urgency and risk.  
* Standardizing helps consistency across the docs.

**How:** In your editor, replicate the following format to accurately build callouts and notes:

```
{:.info}
> **Info:** Context that helps but isn’t critical.
{:.important}
> **Important:** You must do this or the task fails.
{:.warning}
> **Warning:** Risk of breakage or data loss.
```

**Do:**

* Use `{:.important}` when the user must perform a step before continuing.  
* Use `{:.warning}` before operations that could cause data loss. For example, deleting resources.

**Don’t:** Stack multiple callouts for one point or over-use warnings. We don’t want the document to look and feel like a siren is blaring.

**Example:** In [Kong Manager Configuration](https://developer.konghq.com/gateway/kong-manager/configuration/) docs, there’s an **Important** note: *“If you run the Kong Gateway quickstart script, Kong Manager is automatically enabled.”* This clarifies a behavior the user must know.