---
title: Insomnia 3-way merge
description: Learn how Insomnia handles conflicts during Git sync so you can combine concurrent changes safely.
breadcrumbs:
  - /insomnia/
  - /insomnia/version-control/
content_type: reference
layout: reference
products:
  - insomnia

related_resources:
  - text: Version control
    url: /insomnia/version-control/
  - text: Storage options
    url: /insomnia/storage/

faqs:
  - q: Why don’t I always see the merge view?
    a: |
      After you **Commit**, when you **Pull** or **Push**, Insomnia checks for conflicting changes between your local work and the remote branch.  
      If conflicts exist, Insomnia opens the 3-way merge so you can review and reconcile them.  
      If there are no conflicts, sync completes without opening the merge view. For more information, see [Version control](/insomnia/version-control/).
  - q: Does Git sync split each request into a separate file?
    a: No. Insomnia provides conflict resolution within your project when you sync with Git; you still commit and push with standard Git actions from Insomnia.
  - q: Does Insomnia respect my repository’s branch protections when using Git sync?
    a: Yes. Insomnia respects your Git provider’s branch protections. You can’t push to a protected branch from Insomnia. 
  - q: Can I create a Git-sync project now and connect the repository later?
    a: Yes. You can create a Git-sync project and add the repository later (supported in recent versions). See Storage options → Git sync.
  - q: Does 3-way merge work for collections and design documents?
    a: Yes. 3-way merge applies to the same project resources that Git sync manages—collections, design documents, tests, and environments—so you can resolve conflicts on the content you version in Git. See the [Insomnia docs index](/index/insomnia/) and [storage overview](/insomnia/storage/).
  - q: Why does Insomnia sometimes fall back to the “choose local or remote file” conflict resolution instead of 3-way merge?
    a: |
      Insomnia uses 3-way merge to resolve Git conflicts when files are at least 20,000 lines. To protect performance and prevent errors with very large files, Insomnia applies a safety limit.
      
      If a file exceeds 100,000 lines, Insomnia doesn't attempt a 3-way merge. Instead, it reverts to the previous conflict resolution behavior and prompts you to choose between:
      - The entire local file 
      - The entire remote file
---

3-way merge is Insomnia’s built-in conflict-resolution experience for Git sync. When your local work and the remote branch both change the same content, Insomnia opens a merge view so you can choose which changes to keep without leaving the app.

## 3-way merge in Git sync
- **[Git sync](/insomnia/storage/#git-sync)** stores your Insomnia project in your third-party Git repository so you can use standard Git workflows, for example GitHub, GitLab, or Bitbucket. Your project data lives in your Git provider’s repository, not Insomnia Cloud.
- **3-way merge** is the conflict-resolution UI that appears during Git sync when conflicting edits are detected. You select which changes to keep, and you can perform and combine incoming and local manual edits where supported to stay in full control of the result.

## How it works

Insomnia opens the merge view only when both of the following are true:
- Your local changes and the remote branch modify the same content.
- You perform a **Pull** or **Push** sync action.

After committing your local changes, Insomnia syncs them with the remote repository when you **push** or **pull**. If no conflicts exist between your local and remote branches, the sync completes automatically.  
When differences require reconciliation, Insomnia performs a **three-way comparison** between the local, remote, and base versions.  

The **merge view** opens only when manual input is needed to resolve those conflicts.

When the merge view appears:
1. From the Insomnia application, in the version control panel, click **Pull**.  
1. If conflicts exist, Insomnia opens the merge view.  
1. For each conflict, choose which changes to keep.  
1. Click **Commit** to save your resolution.  
1. Click **Push** to sync your changes.

