---
title: Migrate from scratch pad to Enterprise

content_type: reference
layout: reference
description: Migrate all of the data from your scratch pad account to your Enterprise account.

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
    q: How can I migrate my data from my scratch pad to my Insomnia Enterprise account?
    a: Export your scratch pad workspace as a single Insomnia JSON file, and then import it into your Insomnia Enterprise account as a new project.

faqs:
  - q: Why can't I import my scratch pad file to my Insomnia Enterprise project?
    a: Confirm that the file uses the Insomnia JSON format and ends with `.json`. Insomnia’s importer expects a supported format. For example, Insomnia JSON, Postman v2, HAR, OpenAPI.
  - q: I've successfully imported my scratch pad file to an Insomnia Enterprise project, but I don’t see items.
    a: Ensure you imported the file into the project you opened, not a different workspace. If needed, re-import into the active project.
  - q: Why can't I see my Insomnia environment variables in Table view?
    a: Enable the JSON view to confirm values, then switch back to Table view. This ensures you see nested or inherited keys in the editor.  
---

## Export from your scratch pad to JSON file
<!--vale off-->
When you switch to Insomnia Enterprise, you can export your [scratch pad](/insomnia/storage/#scratch-pad) workspace as a single Insomnia JSON file to capture all requests, collections, environments, variables, and metadata for migration.
1. In the Insomnia app, open your scratch pad workspace. 
2. From the Scratch Pad dropdown menu, select "Export".
1. Click **Export**.
3. From the **Which format would you like to export as?** dropdown menu, select "Insomnia v5".
1. Click **Done**.
1. In the File name field, enter `insomnia-scratch-pad-export.json`. 

   {:.info}
   > Make sure the file extension is `.json` to ensure that Insomnia recognizes it during import.
1. Click **Export**. This saves the export file locally.
<!--vale on-->

## Sign in to Insomnia Enterprise
1. Launch Insomnia and sign in to your Enterprise organization.
    - If your org enforces SSO, use the SSO button and complete your IdP flow. 
2. On the dashboard, confirm that you see **Personal Workspace** or your **Organization** workspaces. Enterprise accounts organize work into projects.

## Create a project
1. In the Insomnia app, sign in to your Enterprise organization. 
   If your org enforces SSO, click **Continue with SSO** and login. 
1. In the Project sidebar, click **+**.
1. In the **Project name** field, enter `Migrated scratch pad data`. 
1. In the Project type settings, select one of the following:
    * **Cloud Sync:** A cloud project to share and sync in your organization, uses E2EE.
    * **Git Sync:** Ties the project to your repository and requires each collaborator to connect with the repo.
1. Click **Create**.


## Import your workspace JSON
1. In the Insomnia app Project sidebar, click **Migrated scratch pad data**.
1. Click **Import**.
1. Click **Choose files**.
1. Click the **insomnia-scratch-pad-export.json** file.
1. Click **Scan**.
1. Click **Import**.

## (Optional) Review and fix environment variables
If you used environment variables in your imported scratch pad data, you'll need to review and fix any environment variables.

1. In the Insomnia app, click your imported scratch pad collection.
1. In the collection sidebar, click **Base environment**.
1. Click the edit icon.
1. Verify keys such as `base_url` and API tokens. 
1. Use the JSON view to confirm nested values, then enable **Table view**.
3. If your team uses [secret environment variables](/insomnia/environments/#secret-environment-variables) in the local vault, set or re-enter them as needed in Enterprise.

{:.info}
> Secret variables live in the local vault namespace and do not appear in plain text. For example, `vault.foo`. Keep your vault key safe, resetting it deletes stored secrets.

### Validate the migration
Now that your data is migrated to Insomnia Enterprise, verify that everything was migrated correctly by doing the following:
- Open a few imported requests and click **Send**. Confirm that the URL, headers, and body match what you used in scratch pad.
- Switch environments and verify that requests resolve variables as expected.
- If you chose cloud sync, sign in on another machine and confirm the project appears and stays in sync.
