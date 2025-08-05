---
title: Migrate from Scratch Pad to Enterprise

content_type: how_to
description: Migrate all of the data from your Scratch Pad account to your Enterprise account.
products:
    - insomnia

breadcrumbs:
  - /insomnia/
tags:
  - scratch pad
  - migration
  - collections
  - environments

related_resources:
  - text: Collections
    url: /insomnia/collections/
  - text: Environments
    url: /insomnia/environments/
  - text: Migrate collections and environments from Postman to Insomnia  

tldr:
    q: How can I migrate my data from my Scratch Pad to my Enterprise account? 
    a: Export your Scratch Pad workspace as a single Insomnia JSON file, and then import it into your Insomnia Enterprise account.

prereqs:
  inline:
    - title: An Insomnia design document
      content: |
        You need to have an Insomnia design document. For instructions on creating one see [Create a design document](/how-to/create-a-design-document/)
      icon_url: /assets/icons/code.svg
    - title: Insomnia Enterprise account
      content: |
        You need to have an Insomnia Enterprise account. For more information, go to [Insomnia Enterprise](/insomnia/enterprise/)
      icon_url: /assets/icons/code.svg
      
---
Export your Scratch Pad workspace as a single Insomnia JSON file to capture all requests, collections, environments, variables, and metadata for migration.

## Export from your Scratch Pad to JSON file
- From the dashboard, click **Export**, choose Insomnia v4/v5 format, and save the file locally to .json.

## Sign in to Insomnia Enterprise
If your organization requires Single Sign-On (SSO):
- Use your SSO provider to log in. You'll need a verified email under your enterprise domain, and then allow the login as prompted. For more information about domain verification, go to [Enterprise user management](/insomnia/enterprise-user-management/)
- Once signed in, in the Enterprise dashboard, you'll see your personal workspace or your organization's workspace.

## Create a new project
- After logging in, click **Create → New Project** from the sidebar.
- Choose **Secure Cloud** project type to enable all collaboration features and future syncing.
- Name the project. For example, “Migrated ScratchPad Data”.

## Import your workspace JSON
- Inside your project, for example “Migrated ScratchPad Data”, click **Import → From File** and upload the .json file that you saved locally in step 1.
- Confirm import and Insomnia will report the objects imported. For example, collections, design documents, environments, and tests.

## Review and fix environment variables
In Insomnia Scratch Pad, the Base Environment may include variables like `base_url` or `api_key`, especially when exporting routes generated from OpenAPI.