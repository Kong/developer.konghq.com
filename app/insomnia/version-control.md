---
title: About version control in Insomnia

content_type: concept
layout: concept

related_resources:
  - text: About storage options in Insomnia
    url: /insomnia/storage-options
  - text: About cloud sync
    url: /insomnia/cloud-sync/
  - text: About git sync
    url: /how-to/create-a-design-document/
  - text: About documents
    url: /insomnia/documents
  - text: Generate a collection
    url: /how-to/generate-a-collection-from-a-design-document/
  - text: Create a design document
    url: /how-to/create-a-design-document/
  - text: Create HTTP status tests
    url: /how-to/write-http-status-tests

tags:
    - git
    - git-sync
    - cloud-sync
    - version-control

products:
    - insomnia

faqs:
  - q: Should I use Git sync or cloud sync?
    a: Both allow you to use version control and collaborate with your team. You should use Git sync if you're already using a Git repository and your team requires detailed version tracking and rollback capabilities.
  - q: I'm using Git sync, does Insomnia uphold the branch protections we have in our repository?
    a: 
  - q: With Git sync, if I create a branch in my Git repository, will it pull that branch into Insomnia? And vice versa?
    a: 
  - q: Can I create branch protetions in Insomnia for cloud sync?
    a:  
  - q: How do I collaborate with others in Insomnia and use version control?
    a: If you invite them to your organization or workspace, other users can edit the same Insomnia entities and use the same branches for version control.
---

Insomnia allows you to manage versions of collections, mock servers, design documents, and global environments in Insomnia, both with cloud sync and git sync. Branches are object-specific, meaning that the branches you have in a collection are specific to that one collection. They aren't shared with other collections or other objects, like a mock server. 

With cloud sync, versions are managed only in the Insomnia UI and can be shared with other users you've invited to your workspace. 

In git sync, <!-- do you pull down the branches from your repo? if I create a branch in Insomnia, will it push it to my repo?-->

Branch protections, are they available? In cloud? In git?

when should I use git sync vs cloud sync? link to longer form storage about docs


## Version control capabilties

The following sections describe how to perform version control actions in Insomnia. 

Before you can manage branches, commits, and merges, click the entity (document, collection, mock server, or global environment) from your workspace.

Version control is managed from the bottom left of the sidebar.

![Version control sidebar menu location](/assets/images/insomnia/version-control-menu.png)

| Task | Steps |
| ---- | ------------ |
| Create a branch | 1. From the version control menu at the bottom left of the sidebar, click the current branch or select the branch you want to createa a branch off of from the dropdown menu.<br>1. Select **Branches** from the dropdown menu.<br>1. Enter a name for the new branch and click **Create**. |
| Checkout a branch | From the version control menu at the bottom left of the sidebar, click the current branch and then select the branch you want to checkout from the list. |
| Commit or push changes | 1. From the version control menu at the bottom left of the sidebar, click the current branch.<br>1. Select **Commit** from the dropdown menu.<br>1. Stage the changes by clicking **+** next to the changed object in the left sidebar.<br>1. Enter a commit message and either click **Commit** to commit the changes locally or click **Commit and push** to push the commit to the cloud. |
| Revert changes | 1. From the version control menu at the bottom left of the sidebar, click the current branch and then select the branch you want to revert changes on.<br>1. Select **History** from the branch dropdown menu.<br>1. Click **Restore** next to the commit you'd like to restore.<br>1. Click **Confirm**. |
| Pull changes | From the version control menu at the bottom left of the sidebar, click the current branch and then select the branch you want to pull the changes to. Click the **Pull** icon next to your branch. |
| Merge a branch | 1. From the version control menu at the bottom left of the sidebar, click the current branch and then select the branch you want to merge to. You can't merge a branch that you currently have checked out.<br>1. Select **Branches** from the dropdown menu.<br>1. Click **Merge** next to the branch you want to merge. The branch will merge into the branch it was branched off of. |
| Resolve merge conflicts | When you are merging, if there's a merge conflict, a dialog will display with the merge conflicts. Select the object in the left sidebar to view the differences and then either select **Ours** or **Theirs** to determine which changes to merge. Then, click **Resolve conflicts**.  |