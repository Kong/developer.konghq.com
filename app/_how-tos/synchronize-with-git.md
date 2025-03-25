---
title: Synchronize Insomnia content with Git
content_type: how_to

products:
- insomnia

tags:
- documents
- collections
- mock-servers
- environments
- git

tier: team

prereqs:
    inline:
    - title: Git repository
      content: |
        Create an empty remote Git repository.
      icon_url: /assets/icons/git.svg
    - title: Insomnia workspace
      content: |
        Create a workspace in Insomnia. A workspace can be a [design document](/how-to/create-a-design-document/), a [collection](), a [mock server](), or an [environment]().
      icon_url: /assets/icons/git.svg

tldr:
    q: How can I push content from Insomnia to a Git repository?
    a: Create an empty remote Git repository and an Insomnia workspace. In the workspace, click the button at the bottom of the left pane and connect the repository, then commit and push your content.
---

## 1. Select the workspace to synchronize

{% navtabs "workspace-sync" %}

{% navtab "Cloud Sync project" %}
1. Click **master** at the bottom of the left pane. 
2. Click **Switch to Git Repository**.
{% endnavtab %}

{% navtab "Local Vault project" %}
1. Click **Not synced** at the bottom of the left pane. 
2. Click **Connect Repository**.
{% endnavtab %}

{% endnavtabs %}

## 2. Connect to the repository

Select whether you want to clone the repository from GitHub, GitLab, or Git.

{% capture sync %}
1. Click **Sync**.
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

## 3. Create a new branch

Insomnia synchronizes with the repository's default branch, but it's a good practice to make changes on a different branch.

1. Click the name of the branch at the bottom of the left pane to see the Git sync menu.
1. Click **Branches**.
1. Enter a name for the new branch and click **Create**.

## 4. Commit and push the content to your repository

1. Click the name of the branch.
1. Click **Commit**.
1. Enter a commit message.
1. Select the content that you want to commit to the repository.
1. Click **Commit**, then click **Close** once the changes are committed.
1. Click the name of the branch and click **Push**.

You can see in your repository that Insomnia added a `.insomnia` directory with your content in it.