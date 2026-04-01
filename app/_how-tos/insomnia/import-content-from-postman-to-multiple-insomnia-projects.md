---
title: Import content from Postman to multiple Insomnia projects
permalink: /how-to/import-content-from-postman-to-multiple-insomnia-projects/

content_type: how_to
description: Use the Postman Exporter tool to export, organize, and import your Postman content to multiple Insomnia projects.
products:
    - insomnia
breadcrumbs:
  - /insomnia/
tags:
  - postman
  - migration
  - collections
  - environments
related_resources:
  - text: Collections
    url: /insomnia/collections/
  - text: Environments
    url: /insomnia/environments/
  - text: Import and export reference for Insomnia
    url: /insomnia/import-export/
  - text: Migrate collections and environments from Postman to Insomnia
    url: /how-to/migrate-collections-and-environments-from-postman-to-insomnia/

tier: enterprise

tldr:
    q: How can I import Postman content to multiple Insomnia projects at once?
    a: First, make sure to ask your CSM to enable bulk import on your account. Then, use the [Postman Exporter](https://www.npmjs.com/package/organize-postman-export) tool to export content from your Postman account and organize the output, and import the output directory to Insomnia from **Preferences** > **Data**.

prereqs:
  inline:
  - title: Postman API key
    content: |
      This tutorial requires a Postman API key. In your Postman account settings, navigate to **API keys**, generate a key, and export it as an environment variable:
      ```sh
      export POSTMAN_API_KEY='your-postman-api-key'
      ```
    icon_url: /assets/icons/postman.svg
  - title: Bulk import enabled
    content: |
      This tutorial requires the **Bulk import** feature on your organization. This feature is not available by default. Reach out to your Customer Success Manager to enable it, and provide your organization ID. The ID starts with `org_`, and you can find it in the page URL when you open your organization in [Insomnia Admin](https://app.insomnia.rest/app/dashboard/organizations).

    icon_url: /assets/icons/insomnia/insomnia.svg

faqs:
  - q: What type of storage can I use for imported projects?
    a: |
      By default, projects are created as Cloud Sync projects, however, you can change the type as needed.
      
      If you change the type to Git Sync, you'll need to create a repository for each project and link the repository to the project manually. This will be improved in a future release.
  - q: How does Insomnia transform my Postman data?
    a: | 
       During the import, Insomnia transforms your content to convert Postman syntax to Insomnia syntax. We regularly update these transformations. The following Postman elements have limitations:
       * `tests.property = expression` syntax (only bracket notation supported)
       * Expressions without semicolons in `tests` assignments
       * `request` object operations
       * `data` object operations
       * Object destructuring with `pm` variables
       * Dynamic property access with computed `pm` variables in destructuring
---

## Export your Postman content

The [Postman Exporter](https://www.npmjs.com/package/organize-postman-export) tool allows you to export your Postman content and files to Insomnia while preserving the folder structure. In Insomnia, this imports the files into multiple projects within the same organization. Insomnia will create a project for each Postman workspace and import each workspace's collections, environments, and global variables in the corresponding project.

First, make sure that you have set the `POSTMAN_API_KEY` environment variable to your [Postman API key](#postman-api-key). You can also use the `--api-key` flag in your commands.

Run the following command to export and organize your Postman content:
```sh
npx organize-postman-export export
```
{:.info}
> If needed, you can use the `--output` flag to specify an output directory.

You will be prompted to install the package if you're using it for the first time. Once it's done running, you should get a response similar to this:
```sh
⚙️ Export configuration:
🔑 API Key: PMAK-68b...
📂 Output directory: postman_workspaces 

🚀 Starting Postman data export...
📥 Fetching all workspaces...
🔎 Found 2 workspaces

📂 Processing workspace: My Internal Workspace
  📚 Exporting 2 collections...
     ✅ Exported collection: API 1.postman_collection.json
     ✅ Exported collection: API 2.postman_collection.json
  🌍 Exporting 1 environments...
     ✅ Exported environment: Global Environment 1.postman_environment.json
  🌐 Exporting global variables...
     ✅ Exported global variables: globals.postman_globals.json
📂 Processing workspace: My Public Workspace
  📚 Exporting 1 collections...
     ✅ Exported collection: API 3.postman_collection.json
  🌍 Exporting 1 environments...
     ✅ Exported environment: Global Environment 2.postman_environment.json
  ❌ Postman API does not support global variables for public workspaces, please export it manually.

 🎉 All data export completed!
```
{:.no-copy-code}

{:.warning}
> If you have global variables in a public Postman workspace, you will have to export them manually.

This creates a `postman_workspaces` directory in your working directory with the exported content and files.

## Import your content to Insomnia

To import the output of the Postman export to Insomnia, do the following:

1. In your Insomnia app, navigate to **Preferences** > **Data**.
1.  Click **Import projects**.
1. Click **Choose folder**.
1. Select the `postman_workspaces` Postman Exporter output directory.
1. Click **Import**.
   
   {:.info}
   > You can select the **Skip importing projects that already exist** checkbox if you want to avoid duplicate projects. Insomnia will ignore directories with the same name as existing projects.
1. Once Insomnia is done importing your content, click **Confirm**.