---
title: Version control in Insomnia

description: Insomnia allows you to manage versions of collections, mock servers, design documents, and global environments in Insomnia, both with cloud sync and git sync.

content_type: reference
layout: reference

breadcrumbs: 
  - /insomnia/
  
related_resources:
  - text: About storage options in Insomnia
    url: /insomnia/storage/
  - text: About cloud sync
    url: /insomnia/storage/#cloud-sync
  - text: About git sync
    url: /how-to/create-a-design-document/
  - text: About documents
    url: /insomnia/documents/
  - text: Generate a collection
    url: /how-to/generate-a-collection-from-a-design-document/
  - text: Create a design document
    url: /how-to/create-a-design-document/
  - text: Create HTTP status tests
    url: /how-to/write-http-status-tests/

tags:
    - git
    - cloud-sync
    - versioning

products:
    - insomnia

faqs:
  - q: Should I use Git sync or cloud sync?
    a: Both allow you to use version control and collaborate with your team. You should use Git sync if you're already using a Git repository and your team requires detailed version tracking and rollback capabilities.
  - q: I'm using Git sync, does Insomnia uphold the branch protections we have in our repository?
    a: Yes, if you have branch protections for a branch, say `main`, you won't be able to push to that branch in Insomnia.
  - q: With Git sync, if I create a branch in my Git repository, will it pull that branch into Insomnia? And vice versa?
    a: Yes, you'll have to pull it into Insomnia. You can push branches you make in Insomnia to your repository.
  - q: Can I create branch protections in Insomnia for cloud sync?
    a: No.
  - q: How do I collaborate with others in Insomnia and use version control?
    a: If you invite them to your organization or workspace, other users can edit the same Insomnia entities and use the same branches for version control.
---

Insomnia allows you to manage versions of collections, mock servers, design documents, and global environments in Insomnia, both with cloud sync and git sync.
Branches are object-specific, meaning that the branches you have in a collection are specific to that one collection. They aren't shared with other collections or other objects, like a mock server. 

With cloud sync, versions are managed only in the Insomnia UI and can be shared with other users you've invited to your workspace. In git sync, you can pull branches from your repository into Insomnia and can also push local branches you make in Insomnia to your repository.

## Version control capabilities

Before you can manage branches, commits, and merges, click the workspace (document, collection, mock server, or global environment) from your project.

You can perform the following version control actions from Insomnia:
* Create a branch
* Checkout a branch
* Commit or push changes
* Revert changes
* Pull changes
* Merge a branch
* Resolve merge conflicts

Version control is managed from the bottom left of the sidebar.

![Version control sidebar menu location](/assets/images/insomnia/version-control-menu.png)

### AI‑powered Commit Suggestions

To streamline your commit workflow, Insomnia includes **AI commit suggestions**. Use this feature to improve commit clarity and reduce manual effort when writing messages.

To use the feature:
- Click **///** in the commit dialog.
- Insomnia analyzes your staged changes and suggests logical groupings and commit messages.
- You can drag and drop files between groups, edit the suggested messages inline, or exclude files from AI grouping.
- Double-click a message or use the edit icon to change it.
- The interface hides manual options while suggestions load, and brings them back if you switch modes.

### **Disabling AI Commit Suggestions**

Administrators or users can disable this feature from the Insomnia preferences under `****************`.  
When you deactivated:
- The **///** button is hidden.
- No AI functionality is used during the commit process.
- Manual staging, commenting, and commit flows remain unchanged.

---
