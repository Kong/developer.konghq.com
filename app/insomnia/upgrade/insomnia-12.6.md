---
title: "Git Sync projects migration for {{site.data.products.insomnia.name}} 12.6"
content_type: reference
layout: reference
breadcrumbs:
  - /insomnia/
  - /insomnia/upgrade/
products:
    - insomnia

beta: true
min_version:
  - version: "12.6"

tags:
    - upgrade
    - versioning

faqs:
  - q: Is my project's data safe during the migration?
    a: "Yes. Your data is never deleted. The migration moves and restructures files, it doesn't remove them."
  - q: Why am I getting warnings after upgrading?
    a: |
      Warnings mean that {{site.data.products.insomnia.name}} migrated most projects, but a few couldn't update automatically. Those projects are listed on screen. {{site.data.products.insomnia.name}} has disconnected them from their Git remote and converted them into local projects so you don't lose any data. To restore Git Sync:
      1. Open the project in {{site.data.products.insomnia.name}}.
      2. Go to Project Settings → Git Sync.
      3. Reconnect the project to its remote repository.
  - q: What should I do if the migration is unsuccessful?
    a: |
      If an unexpected error stops the migration before it finishes, your data remains intact and nothing is deleted. Click **Retry Update** to try again. If the problem persists, either:
      - Copy the error logs and visit the [Git Sync docs](/insomnia/git-sync/).
      - Open a support ticket.
  - q: I have several Git Sync projects. Will the migration take a long time?
    a: "No. {{site.data.products.insomnia.name}} migrates all Git Sync projects in parallel and the process typically completes in a few seconds, regardless of how many projects you have."
  - q: Why does a project show as **Disconnected** after the migration? 
    a: This means its migration hit an error and the project was converted to a local project to preserve your data. Reconnect it via Project Settings → Git Sync. Your remote history is untouched.
  - q: Do my teammates also need to run this? 
    a: "Yes. Each person needs to migrate their local installation independently. The migration only changes local files; it doesn't push anything to the shared remote."
  - q: Can I skip the migration?
    a: "No. To use {{site.data.products.insomnia.name}} v12.6.0 and later versions, you need to run the migration. The migration screen continues to appear until it completes successfully."
  - q: Why does the {{site.data.products.insomnia.name}} app show the migration screen every time I open it?
    a: "This means a previous migration attempt didn't finish (for example, the app was closed mid-run). Click **Update Now** to complete it. If the problem persists, copy the error logs and visit the [Git Sync docs](/insomnia/git-sync/) or open a support ticket."

description: This guide walks you through migrating your Git Sync project structure to use {{site.data.products.insomnia.name}} 12.6.

related_resources:
  - text: "Git Sync in Insomnia"
    url: /insomnia/git-sync/
---

Starting with {{site.data.products.insomnia.name}} v12.6.0, Git Sync projects use a standard `.git/` folder layout so you can manage your API collections with:

- [The Git CLI](/how-to/use-git-cli)
- GitHub Desktop
- VS Code's source control panel
- Other Git tools

The first time you open {{site.data.products.insomnia.name}} v12.6.0, the app asks you to **run a one-time migration** to update your local project files to this new layout.

## What changes

Before {{site.data.products.insomnia.name}} v12.6.0, {{site.data.products.insomnia.name}} stored Git internals in a private `git/` folder and kept other project files in an `other/` subfolder. The new layout matches a standard Git repository:

{% table %}
columns:
  - title: Project files
    key: type
  - title: {{site.data.products.insomnia.name}} v12.5 and older
    key: before
  - title: {{site.data.products.insomnia.name}} v12.6 and newer
    key: after
rows:
  - type: "Git internals"
    before: |
      Stored in a private `git/` folder.
    after: |
      Stored in a standard `.git/` folder.
  - type: "Non-Git files"
    before: |
      Non-YAML files stored in an `other/` subfolder.
    after: |
      - Non-YAML files sit at the top of the {{site.data.products.insomnia.name}} project's repository.
      - Workspace metadata is in `version-control/git/<id>/insomnia.<project-id>.yaml`.
  
{% endtable %}

The migration only changes file paths. It doesn't change:

- API collections
- Environments
- Settings

## How to run the migration

1. Open {{site.data.products.insomnia.name}} v12.6.0 for the first time: a migration screen appears automatically.
1. Read the summary on the **What's new** screen.
1. Click **Continue**.
1. On the migration screen, click **Update Now**.
1. {{site.data.products.insomnia.name}} migrates all your Git Sync projects in a few seconds. When it's done, click **Open {{site.data.products.insomnia.name}}**.

The migration runs once. Future launches open {{site.data.products.insomnia.name}} normally.

## Validate 

After migrating to {{site.data.products.insomnia.name}} v12.6, you can:

- Run Git commands like `git status`, `git log`, and `git pull` in your {{site.data.products.insomnia.name}} project repository directly from your terminal.
- Open the folder in any Git GUI.
- Continue using {{site.data.products.insomnia.name}}'s built-in Git Sync exactly as in previous versions.

The migration doesn't affect:

- **Pending changes:** The migration preserves uncommitted edits and in-progress work.
- **Duplicate migrations:** {{site.data.products.insomnia.name}} ensures each project is only migrated once.

## How to roll back to an older version

The {{site.data.products.insomnia.name}} 12.6 file layout preserves your project data. However, older versions of {{site.data.products.insomnia.name}} (pre-v12.6.0) don't understand the new `.git/` layout. If you need to roll back to an older version:

1. Don't delete the project folder: it still contains the data.
1. Back up your project: push any uncommitted changes to your remote from the {{site.data.products.insomnia.name}} UI or the [Inso CLI](/inso-cli/).
1. Install the older version.
1. Clone the project again from its remote through {{site.data.products.insomnia.name}}'s Git Sync settings.
