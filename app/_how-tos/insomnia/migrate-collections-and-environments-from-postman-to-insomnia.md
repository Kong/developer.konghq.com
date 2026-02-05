---
title: Migrate collections and environments from Postman to Insomnia
permalink: /how-to/migrate-collections-and-environments-from-postman-to-insomnia/

content_type: how_to
description: Migrate Postman collections and environments to Insomnia.
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
  - text: Import content from Postman to multiple Insomnia projects
    url: /how-to/import-content-from-postman-to-multiple-insomnia-projects/

tldr:
    q: How can I import my Postman data into Insomnia? 
    a: Export your Postman data as JSON files, create a project in Insomnia, click **Import** and select the files to import.

prereqs:
  inline:
  - title: Postman export
    content: |
      This how-to guide requires a Postman export. You can either export environments and collections individually (this can be useful if you want to import them into different Insomnia projects), or all at once from:
      * The [Postman export page](https://web.postman.co/me/export) if you're using Postman Enterprise or Cloud.
      * **Settings** > **Data** in your Postman app if you're using the scratch pad.
    icon_url: /assets/icons/postman.svg

faqs:
  - q: Will my Postman pre-request and post-response scripts work in Insomnia?
    a: |
      Yes, most Postman scripts can be automatically converted by Insomnia during the import process. For more details, see [Migrating scripts from Postman](/insomnia/scripts/#migrating-scripts-from-postman).
  - q: Can I import mock servers from Postman to Insomnia?
    a: No, mock servers can't be imported, they need to be recreated manually in Insomnia.
---

## Create a project in Insomnia

In Insomnia, click the **+** button in the left panel to create a new project in which you'll import your Postman data. Select your preferred project type, in this example, we'll use **Cloud Sync**.

## Import your Postman data

1. In the new project, click **Import** and select the files to import. You can import a ZIP file containing all of your Postman data, or separate JSON files.
1. Click **Scan** to get a list of all the data that will be imported into Insomnia:
   ![Import of Postman data with two collections and an environment](/assets/images/insomnia/postman-scan.png)
1. Click **Import**.

In this example, two collections and an environment are imported. Once the import is done, you'll see your content in the **Collections** and **Environments** sections. In the case of a Cloud Sync project, the imported data is automatically synchronized. You don't need to do anything else to share it with other members in your organization.

## Select global environments (Optional)

If your collections use variables from a global environments, you'll need to click **Base Environment** and select the global environment in each collection.