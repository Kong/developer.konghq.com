---
title: Synchronize an Insomnia project with Git
content_type: how_to

description: Create a new Insomnia project and enable Git Sync.

products:
- insomnia

tags:
- documents
- collections
- mock-servers
- git

tier: pro

min_version:
  insomnia: '11.0'

prereqs:
    inline:
    - title: Git repository
      content: |
        To synchronize an Insomnia project with Git, you need a Git repository. You cna either use an existing repository with Insomnia content, or an empty repository.
      icon_url: /assets/icons/git.svg

tldr:
    q: How can I push content from Insomnia to a Git repository?
    a: Create an empty remote Git repository and an Insomnia project with Git Sync. In the workspace, click the button at the bottom of the left pane and connect the repository, then commit and push your content.
## TODO
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

If your Git repository already contains Insomnia content, you will be prompted to import the content to your project.

{:.info}
> If the repository contains legacy Insomnia content (from versions prior to 11.0), Insomnia will convert this content to the new format introduced in version 11.0.

## Create a new branch

Insomnia synchronizes with the repository's default branch, but it's a good practice to make changes on a different branch.

1. Click the name of the branch at the bottom of the left pane to see the Git sync menu.
1. Click **Branches**.
1. Enter a name for the new branch and click **Create**.

## Commit and push the content to your repository

Once you've created content or made changes to existing content in your project, you can push the changes to your repository:

1. Click the name of the branch at the bottom of the left pane.
1. Click **Commit**.
1. Enter a commit message.
1. Stage changes by clicking the **+** button next to the changes that you want to commit to the repository.
1. Click **Commit** or **Commit and push**.