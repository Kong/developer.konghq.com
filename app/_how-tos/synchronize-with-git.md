---
title: Synchronize an Insomnia project with Git
content_type: how_to

description: Create a new Insomnia project and enable Git Sync.

products:
- insomnia

tags:
- insomnia-documents
- collections
- mock-servers
- git

min_version:
  insomnia: '11.0'

search_aliases:
  - git sync

prereqs:
    inline:
    - title: Git repository
      content: |
        When you create an Insomnia project with Git Sync, you can either add the repository now or later (if you're using Insomnia 11.5 or later). If you want to add the repository when you create the project, you can either use an existing repository with Insomnia content or an empty repository.
      icon_url: /assets/icons/git.svg

tldr:
    q: How can I push content from Insomnia to a Git repository?
    a: Create a remote Git repository and an Insomnia project with Git Sync. Select the Git provider and connect to the repository. In the project, click the button at the bottom of the left pane to see the Git Sync menu and push your changes.

related_resources:
  - text: Storage options in Insomnia
    url: /insomnia/storage/
  - text: Version control in Insomnia
    url: /insomnia/version-control/
---

## Create a project

In this example, we'll create a new project with [Git Sync](/insomnia/storage/#git-sync), but you can also update an existing [cloud](/insomnia/storage/#cloud-sync) or [local](/insomnia/storage/#local-vault) project to use Git Sync from the project settings.

1. In your Insomnia organization, click the **+** button under **PROJECTS** in the left pane.
1. Name your project, select **Git Sync**, and click **Create**.
1. Select whether you want to clone the repository from GitHub, GitLab, or Git:

{% capture sync %}
1. Click **Clone**.
{% endcapture %}

{% navtabs "repo" %}

{% navtab "GitHub" %}
{% include how-tos/steps/insomnia-github.md %}
{{ sync }}
{% endnavtab %}

{% navtab "GitLab" %}
{% include how-tos/steps/insomnia-gitlab.md %}
{{ sync }}
{% endnavtab %}

{% navtab "Git" %}
{% include how-tos/steps/insomnia-git.md %}
{{ sync }}
{% endnavtab %}

{% endnavtabs %}

If your Git repository already contains Insomnia content, you will be prompted to import the content to your project. {% new_in 11.5 %} You can also create the Git Sync project now and add a repository later. 

{:.info}
> {% new_in 11.2 %} If the repository contains legacy Insomnia content (from versions prior to 11.0), Insomnia will convert this content to the new format introduced in version 11.0.

## Commit and push the content to your repository

Once you've created content or made changes to existing content in your project, you can push the changes to your repository:

1. Click the name of the branch at the bottom of the left pane.
1. Click **Commit**.
1. Enter a commit message.
1. Stage changes by clicking the **+** button next to the changes that you want to commit to the repository and click **Commit**.
1. Click the name of the branch again and click **Push 1 Commit**.

   {% new_in 11.4 %} Git status notifications will appear at the bottom right corner of the window.