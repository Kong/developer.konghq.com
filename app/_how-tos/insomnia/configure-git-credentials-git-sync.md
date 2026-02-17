---
title: Configure Git credentials for Git Sync in Insomnia
permalink: /how-to/configure-git-credentials-git-sync/
content_type: how_to

products:
  - insomnia

description: Configure authentication and commit identity when using Git Sync in Insomnia.

tags:
  - insomnia-documents
  - git
  - git-sync

tldr:
  q: How do I configure Git credentials for Git Sync in Insomnia?
  a: Convert the project to **Git Sync**, authenticate with your Git provider, select a repository and branch, and confirm the author name and email used for commits.

faqs:
  - q: Where does Insomnia get Git credentials from?
    a: Insomnia uses the authentication provider that you selected during Git Sync setup. It also reads credentials from your local Git configuration.

prereqs:
  inline:
    - title: Git repository access
      content: |
        Ensure that you have access to the Git repository and required permissions to both push and pull changes.
      icon_url: /assets/icons/git.svg

related_resources:
  - text: Storage options in Insomnia
    url: /insomnia/storage/
  - text: Synchronize an Insomnia project with Git
    url: /how-to/synchronize-with-git/
---
Insomnia Git Sync lets you store and version Insomnia project data in an external Git repository. To push and pull changes, Insomnia requires credentials that authenticate with your Git provider, such as GitHub, GitLab, or Bitbucket.

Insomnia can obtain Git credentials in the following ways:

- From the Git Sync configuration in Insomnia
- From your local Git configuration file
- From Insomnia credential preferences

## Configure Git Sync credentials

1. In the Insomnia application, from the **PROJECTS** panel, hover over a project.
1. Select the dropdown arrow, and click **Settings**.
1. In **Type**, select **Git Sync**.
1. In **Authorized as**, select your authentication provider.
1. In **Repository**, select the repository or enter the repository URL.
1. (Optional) In **Branch**, select the branch to sync with.
1. Click **Scan for files**.

## Update local Git configuration file

[insert content]

## Edit Insomnia git credentials

1. In the Insomnia application, click **Preferences**.
1. Click **Credentials**.
1. From **Git Credentials**, click **Add Credential**.
1. Choose either:
    - GitHub: Click **Authenticate with GitHub App**.
    - GitLab: Click **Authenticate with GitLab App**.
    - Access Token: Fill out the **Access Token Credential** form and click **Save Credential**.