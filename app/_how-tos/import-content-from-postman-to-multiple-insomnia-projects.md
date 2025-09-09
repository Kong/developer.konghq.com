---
title: Import content from Postman to multiple Insomnia projects

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
    url: /how-to/migrate-collections-and-envrionments-from-postman-to-insomnia/

tier: enterprise

tldr:
    q: How can I import Postman content to multiple Insomnia projects at once?
    a: First, make sure to ask your CSM to enable bulk import on your account. Then, use the [Postman Exporter](https://www.npmjs.com/package/organize-postman-export) tool to export content from your Postman account and organize the output, and import the output directory to Insomnia from **Preferences** > **Data**.

prereqs:
  inline:
  - title: Postman API key
    content: |
      This tutorial requires a Postman API key. In your Postman account, navigate to **API keys**, generate a key, and export it as an environment variable:
      ```sh
      export POSTMAN_API_KEY='your-postman-api-key'
      ```
    icon_url: /assets/icons/postman.svg
  - title: Bulk import enabled
    content: |
      This tutorial requires the **Bulk import** feature on your Insomnia Enterprise instance. This feature is not available by default, please reach out to your Customer Success Manager to enable it.
    icon_url: /assets/icons/insomnia/insomnia.svg
---

## Export your Postman content

Kong provides the [Postman Exporter](https://www.npmjs.com/package/organize-postman-export) tool, which allows you to export Postman content and organize the files in a structure supported by Insomnia for import into multiple projects. Insomnia will create a project for each Postman workspace and import each workspace's collections and environment in the corresponding project.

First, make sure that you have set the `POSTMAN_API_KEY` environment variable to your [Postman API key](#postman-api-key). You can also use the `--api-key` flag in your commands.

Run the following command to export and organize your Postman content:
```sh
npx organize-postman-export export
```

You will be prompted to install the package if you're using it for the first time. Once it's done running, you should get a response similar to this:
```sh
⚙️ Export configuration:
🔑 API Key: PMAK-68b...
📂 Output directory: postman_workspaces 

🚀 Starting Postman data export...
📥 Fetching all workspaces...
🔎 Found 1 workspaces

📂 Processing workspace: Username's Workspace
  📚 Exporting 2 collections...
     ✅ Exported collection: Uplisting API [Public].postman_collection.json
     ✅ Exported collection: Total Expert Public API.postman_collection.json
  🌍 Exporting 1 environments...
     ✅ Exported environment: Public API Details.template.postman_environment.json
  🌐 No global variables found in the workspace

 🎉 All data export completed!
```
{:.no-copy-code}

{:.info}
> If needed, you can use the `--output` flag to specify an output directory.

## Import your content to Insomnia

To import the output of the Postman export to Insomnia, make e your have the [bulk import option enabled](#bulk-import-enabled).

1. In your Insomnia app, navigate to **Preferences** > **Data** and click **Import projects**.
1. Select the Postman Exporter output directory and click **Import**.
   {:.info}
   > You can select the **Skip importing projects that already exist** checkbox if you want to avoid duplicate projects. Insomnia will ignore directories with the same e as existing projects.
1. Once Insomnia is done importing your content, click **Confirm**.

{:.warning}
> During the import, Insomnia transforms your content to convert Postman syntax to Insomnia syntax. We regularly improve these transformations, however, there are some elements that we'll likely never be able to detect and transform. For example:
> * `tests.property = expression` syntax (only bracket notation supported)
> * Expressions without semicolons in `tests` assignments
> * `request` object operations
> * `data` object operations
> * Object destructuring with `pm` variables
> * Dynamic property access with computed `pm` variables in destructuring