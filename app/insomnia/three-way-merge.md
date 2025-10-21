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

min_version:
  insomnia: '12.0'

related_resources:
  - text: Version control in Insomnia
    url: /insomnia/version-control/
  - text: Storage options in Insomnia
    url: /insomnia/storage/

faqs:
  - q: Which versions of Insomnia include conflict resolution for Git sync?
    a: Conflict resolution in Git sync is available in Insomnia 10.2 and later. See the [product announcement](https://konghq.com/blog/product-releases/insomnia-10-2) and [feature list](/insomnia/storage/) for more details.
  - q: Why don’t I always see the merge view?
    a: The merge view appears only when there are conflicting changes between your local work and the remote branch. If there are no conflicts, Insomnia completes the sync without opening the merge view. For more information, go to [version control](/insomnia/version-control/).
  - q: Does Git sync split each request into a separate file?
    a: No. Insomnia provides conflict resolution within your project when you sync with Git; you still commit and push with standard Git actions from Insomnia.
  - q: Does Insomnia respect my repository’s branch protections when using Git sync?
    a: Yes. Insomnia respects your Git provider’s branch protections; you can’t push to a protected branch from Insomnia. 
  - q: Can I create a Git-sync project now and connect the repository later?
    a: Yes. You can create a Git-sync project and add the repository later (supported in recent versions). See Storage options → Git sync.
  - q: Does 3-way merge work for collections and design documents?
    a: Yes. 3-way merge applies to the same project resources that Git sync manages—collections, design documents, tests, and environments—so you can resolve conflicts on the content you version in Git. See the Insomnia docs index and storage overview.  
---

3-way merge is Insomnia’s built-in conflict-resolution experience for Git sync. When your local work and the remote branch both change the same content, Insomnia opens a merge view so you can choose which changes to keep without leaving the app.

## 3-way merge in Git sync
- **[Git sync](/insomnia/storage/#git-sync)** is a storage option that saves your Insomnia project in a third-party Git repository so you can use standard Git workflows. For example, GitHub, GitLab, Bitbucket.
- **3-way merge** is the conflict-resolution UI that appears during Git sync when conflicting edits are detected. Use it to pick which changes you want to keep directly in Insomnia.

## When 3-way merge appears

Insomnia shows the merge view when both of the following are true:
- Your local changes and the remote branch modify the same content.
- You perform a **Pull** or **Push** sync action.

If no conflicts exist, then Insomnia completes the sync without opening the merge view.

## How to use the 3-way merge view 

1. From the Insomnia application, in the version control panel, click **Pull**.
2. If conflicts exist, Insomnia opens the merge view.
3. For each conflict, choose which changes to keep.
4. Click **Commit**.
5. Click **Push**.
