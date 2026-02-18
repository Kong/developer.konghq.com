---
title: Synchronize an Insomnia project with Git
permalink: /how-to/synchronize-with-git/
content_type: how_to

description: Create a new Insomnia project and enable Git Sync.

products:
- insomnia

tags:
- insomnia-documents
- collections
- mock-servers
- git

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

faqs:
  - q: Why can I only see public repositories after connecting GitHub?
    a: |
      If you can see only public repositories but not private repositories, review your [GitHub App installation settings](https://github.com/apps/insomnia-desktop/installations/select_target).

      Insomnia uses the GitHub App integration. The app must be granted access to private repositories during installation.

      To verify repository access:

      1. Go to the Insomnia GitHub App page: https://github.com/apps/insomnia-desktop
      2. Click **Configure**.
      3. Select your account or organization.
      4. Under **Repository access**, confirm that:
         - **All repositories** is selected, or
         - The required private repositories are explicitly included.
      5. If you make changes, click **Save**.

      {:.info}
      > After updating the installation settings, disconnect and reconnect GitHub in Insomnia if the repositories still don't appear.

related_resources:
  - text: Storage options in Insomnia
    url: /insomnia/storage/
  - text: Version control in Insomnia
    url: /insomnia/version-control/
---

## Create a project

{:.info}
> A Projects storage type isn't fixed. If you have an existing [cloud](/insomnia/storage/#cloud-sync) or [local](/insomnia/storage/#local-vault) project, you can also update it to use Git Sync from the projects **Settings** option.

1. In your Insomnia organization, click the **+** button under **PROJECTS** in the left pane.
1. In the **Project name** field, name your project.
1. In the **Type** field, click **Git Sync**.
1. Select whether you want to clone the repository from GitHub, GitLab, or Git:

{% capture sync %}
1. Click **Scan for files**.
1. Click **Clone Project**.
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

If your Git repository already contains Insomnia content, you will be prompted to import the content to your project. You can also create the Git Sync project now and add a repository later. 

{:.info}
> If the repository contains legacy Insomnia content (from versions prior to 11.0), Insomnia will convert this content to the new format introduced in newer versions.

## Commit and push the content to your repository

Once you've created content or made changes to existing content in your project, you can push the changes to your repository:

1. From the bottom of the left pane, click the name of the branch.
1. Click **Commit**.
1. Enter a commit message.
1. Stage changes by clicking the **+** button next to the changes that you want to commit to the repository and click **Commit**.
1. Click the name of the branch again and click **Push 1 Commit**.

Git status notifications appear at the bottom right corner of the window.