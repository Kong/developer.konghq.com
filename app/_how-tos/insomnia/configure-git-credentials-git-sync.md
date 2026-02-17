---
title: Configure Git credentials for Git Sync in Insomnia
content_type: how_to
permalink: /how-to/configure-git-credentials-git-sync/

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
  - q: Can Insomnia use my existing local Git configuration for authentication?
    a: |
      Yes. Insomnia can use credentials configured in your local Git environment for Git operations.

      If authentication fails, verify your local Git configuration and confirm that you have access to the repository.  

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
Insomnia Git Sync lets you store and version Insomnia project data in an external Git repository. To push and pull changes, Insomnia requires credentials that authenticate with your Git provider. For example, GitHub, GitLab, or Bitbucket.

You can configure Git credentials in three supported ways:
- In **Insomnia Preferences**
- During **Git Sync project setup**
- In your local Git configuration file

## Add credentials in Preferences

Adding credentials in **Preferences** lets you reuse them across projects.
1. In Insomnia, click **Preferences**.
2. Click **Credentials**.
3. Under **Git Credentials**, click **Add Credential**.
4. Choose one of the following:
   - **GitHub**: Complete the OAuth flow.
   - **GitLab**: Complete the OAuth flow.
   - **Access Token**: Enter the required fields, such as base URL and access token.
5. Click **Save Credential**.

Insomnia stores the credential and makes it available when creating or cloning Git Sync projects.

## Validation

To confirm that you've successfully configured your git credentials:
1. In the Insomnia application, in the **PROJECTS** panel, select the name of your branch.
1. Click **Repository Settings**.
1. Verify that your git profile is present.