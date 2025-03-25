---
title: Import content to Insomnia from a Git repository
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
        For this task, you need to have a remote Git repository that contains a `.insomnia` directory. To test this example, you can use the sample content provided in the [Insomnia repository](https://github.com/Kong/insomnia/tree/develop/packages/insomnia-inso/src/db/fixtures/git-repo).

        You can't clone a repository that contains multiple files in the `.insomnia/Workspace`.
      icon_url: /assets/icons/git.svg

tldr:
    q: How can I import Insomnia content from a Git repository?
    a: Click **Create** > **Git Clone** and connect to the Git repository.
---

## 1. Clone the repository

In your Insomnia project, click **Create** > **Git Clone**, and select whether you want to clone the repository from GitHub, GitLab, or Git.

{% capture clone %}
1. Click **Clone**.
{% endcapture %}

{% navtabs "repo" %}

{% navtab "GitHub" %}
{% include how-tos/steps/insomnia-github.md %}
{{ clone }}
{% endnavtab %}

{% navtab "GitLab" %}
{% include how-tos/steps/insomnia-gitlab.md %}
{{ clone }}
{% endnavtab %}

{% navtab "Git" %}
{% include how-tos/steps/insomnia-git.md %}
{{ clone }}
{% endnavtab %}

{% endnavtabs %}

## 2. Edit the content

The imported workspace opens in Insomnia, you can start working on it. Insomnia opens the repository's default branch, but you can switch to an existing branch or create a new one.
In the bottom of the window, on the left, you can see the name of the branch you are currently on. You can click it to see the Git sync menu.

![Git sync menu](/assets/images/insomnia/git-sync.png)