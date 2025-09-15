---
title: Migrate from Scratch Pad to Enterprise

content_type: how_to

description: Migrate all of the data from your Scratch Pad account to your Enterprise account.

products:
    - insomnia

breadcrumbs:
  - /insomnia/
tags:
  - insomnia
  - migration
  - account-management

related_resources:
  - text: Collections
    url: /insomnia/collections/
  - text: Environments
    url: /insomnia/environments/
  - text: Migrate collections and environments from Postman to Insomnia
    url: /how-to/migrate-collections-and-envrionments-from-postman-to-insomnia/
  - text: Import content from Postman to multiple Insomnia projects
    url: /how-to/import-content-from-postman-to-multiple-insomnia-projects/

tldr:
    q: How can I migrate my data from my Scratch Pad to my Enterprise account?
    a: Export your Scratch Pad workspace as a single Insomnia JSON file, and then import it into your Insomnia Enterprise account.

faqs:
  - q: Why can't I import my file?
    a: Confirm that the file uses Insomnia JSON format and ends with `.json`. Insomnia’s importer expects a supported format. For example, Insomnia JSON, Postman v2, HAR, OpenAPI.
  - q: Import says “succeeded” but I don’t see items.
    a: Ensure you imported into the project you opened, not a different workspace. If needed, re-import into the active project.
  - q: Why can't I see my variables in Table view?
    a: Open JSON view to confirm values, then switch back to Table view. This ensures you see nested or inherited keys in the editor.  

prereqs:
  inline:
  - title: Postman export
    content: |
      This how-to guide requires a Postman export. You can either export environments and collections individually (this can be useful if you want to import them into different Insomnia projects), or all at once from:
      * The [Postman export page](https://web.postman.co/me/export) if you're using Postman Enterprise or Cloud.
      * **Settings** > **Data** in your Postman app if you're using the scratch pad.
    icon_url: /assets/icons/postman.svg     
---
Export your Scratch Pad workspace as a single Insomnia JSON file to capture all requests, collections, environments, variables, and metadata for migration.

## Export from your Scratch Pad to JSON file
1. Open your Scratch Pad workspace. 
2. Click **Export**.
3. Select **Insomnia JSON (v4 or v5)** and save the file locally.

{:.info}
> If your export dialog does not add a file extension, rename the file to end with .json to ensure that Insomnia recognizes it during import.

## Sign in to Insomnia Enterprise
1. Launch Insomnia and sign in to your Enterprise organization.
    - If your org enforces SSO, use the SSO button and complete your IdP flow. 
2. On the dashboard, confirm that you see **Personal Workspace** or your **Organization** workspaces. Enterprise accounts organize work into projects.

## Create a project
1. Click **Create → New project**.
2. Select a Cloud project to share and sync in your organization, or select Git if your team uses a repo. 
3. Enter a name, for example Migrated Scratch Pad Data, and confirm.

{:.info}
> When to pick Cloud vs Git: Cloud sync shares the project with your org and uses E2EE, in comparison, Git sync ties the project to your repository and requires each collaborator to connect the repo.

## Import your workspace JSON
1. Open the project.
2. Click **Import → File** and then select your exported Insomnia JSON. 
3. Confirm the import summary. For example, Workspaces, Collections, Environments, and Tests.

## Review and fix environment variables
1. Click **Manage environments → Base environment**.
2. Verify keys such as `base_url` and API tokens. Use **JSON view** to confirm nested values, then return to **Table view**.
The Table and JSON are alternative editors for the same data. 
3. If your team uses **secret environment variables** in the local vault, set or re-enter them as needed in Enterprise.

{:.info}
> Secrets and vault: Secret variables live in the local vault namespace and do not appear in plain text. For example, `vault.foo`. Keep your vault key safe; resetting it deletes stored secrets.

### Validate the migration
- Open a few imported requests and click **Send**. Confirm that the URL, headers, and body match what you used in Scratch Pad.
- Switch environments and verify that requests resolve variables as expected.
- If you chose Cloud sync, sign in on another machine and confirm the project appears and stays in sync.

Once you successfully migrate from Scratch Pad to Enterprise, you'll experience the following:
- **Local → shared**: You move from local Scratch Pad storage to organization projects with Cloud or Git sync. 
- **Solo → collaboration**: Cloud projects appear to teammates in your org; Git projects connect to your repo and follow repo rules. 
- **Login policy**: Your org can require SSO for Enterprise access. Other login methods may be deactivated once SSO is on.