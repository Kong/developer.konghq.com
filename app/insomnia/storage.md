---
title: Storage options in Insomnia

description: Insomnia offers various storage options to cater to different user needs and preferences.

content_type: reference
layout: reference

breadcrumbs:
  - /insomnia/

products:
    - insomnia

related_resources:
  - text: Security at Insomnia
    url: /insomnia/manage-insomnia/#security
  - text: SSO
    url: /insomnia/authentication-authorization/#set-up-sso
  - text: Migrate from scratch pad to Enterprise
    url: /insomnia/migrate-to-enterprise-from-scratchpad/  

faqs:
  - q: What is the difference between Local Vault and Scratch pad?
    a: In both Local Vault and Scratch pad, project data is stored locally. With Local Vault, you can also use Git Sync. In scratch pad, all data is stored locally, so it is best suited for individual developers who aren't working as part of a team.
  - q: Should I use Git Sync or Cloud Sync?
    a: Both allow you to use version control and collaborate with your team. You should use Git Sync if you're already using a Git repository and your team requires detailed version tracking and rollback capabilities.
  - q: Can I create branch protections in Insomnia for Cloud Sync?
    a: No.
  - q: I'm using Git Sync, does Insomnia uphold the branch protections we have in our repository?
    a: Yes, if you have branch protections for a branch, say `main`, you won't be able to push to that branch in Insomnia.
  - q: With Git Sync, if I create a branch in my Git repository, will it pull that branch into Insomnia? And vice versa?
    a: Yes, you'll have to pull it into Insomnia. You can push branches you make in Insomnia to your repository. 
  - q: Can I bulk import across multiple Cloud Sync projects?
    a: |
      Yes. Enterprise users can activate this feature by contacting [support](https://insomnia.rest/support) to enable the feature flag on their account.
      Once activated, go to **Insomnia → Preferences → Data** and select the **Import projects to Org** option.
  - q: What are the user and Git Sync limits for the Essentials plan?  
    a: |
      On the **Essentials** plan, you can choose one of two configurations:
      - Activate **Git Sync** with a limit of up to **3 users** per organization.
      - Deactivate **Git Sync** and allow **unlimited users**.

      You can switch between configurations at any time.  
      When you reach the limit, Insomnia automatically flags it in the application. For example, if you try to add a fourth user while Git Sync is activated, or activate Git Sync when more than three users are already active.  
      In either case, you can reduce users or disable Git Sync to continue
  - q: Can I change a Cloud Sync project into a Local Vault project?
    a: |
      Yes. You can convert a Cloud Sync project to a Local Vault project at any time. Go to the project’s **Project Settings**, select **Change** from the **Type** dropdown, choose **Local Vault**, and then click **Update**. 
      
      When you do this, Insomnia permanently removes all cloud-stored data for the project and stores the project entirely on your local device. This means that collaboration through Insomnia Cloud stops, and all existing collaborators see the project as local.

      After conversion, you can still use Git Sync with the local project, and you can choose to synchronize the project back to the cloud later if you decide to collaborate again.
      
      {:.decorative}
      > **Tip:** Before converting, make sure all collaborators pull the latest updates. Any remote changes that are not present locally will be lost.
  - q: Can I change a Local Vault project into a Cloud Sync project?
    a: |
      Yes. You can convert a Local Vault storage type project to Cloud Sync storage type at any time. Go to the project’s **Project Settings**, select **Change** from the **Type** dropdown, choose **Cloud Sync**, and then click **Update**. 
      
      When you do this, Insomnia begins securely synchronizing your local project to Insomnia Cloud using encrypted storage. Cloud collaboration becomes available, which allows you to work with other users and use cloud features. The project is then accessible on any client after you log in. After conversion, you can still choose to use Git Sync alongside Cloud Sync if needed.
  - q: What happens if I change a Git Sync project into a Cloud Sync project?
    a: |
      When you change a Git Sync storage type project to a Cloud Sync storage type, the project is no longer connected to your Git repository. Any new changes made after the conversion are stored in Insomnia Cloud and are not reflected in the original repository. Your existing files in the Git repository are not deleted or modified by this change. 
      
      To update the storage type, go to the project’s **Project Settings**, select **Change** from the **Type** dropdown, choose **Cloud Sync**, and then click **Update**. 
      
      {:.decorative}
      > **Tip:** Before converting, make sure that you pull the latest updates from the repository, as any changes that aren't pulled beforehand aren't included in the Cloud Sync project. If needed, switch the project back to a local or Git-based workflow later.    
  - q: Can I change a Git Sync project into a Local Vault project?
    a: |
      Yes. You can convert a Git Sync storage type project to Local Vault storage type at any time. Go to the project’s **Project Settings**, select **Change** from the **Type** dropdown, choose **Local Vault**, and then click **Update**. 
      
      After conversion, the project is stored entirely on your local device and is no longer synchronized with Git. Changes made to the project will not be reflected in your local or remote repository. This action does not delete or modify the remote repository. 
      
      {:.decorative}
      > **Tip:** Before converting, make sure that you pull the latest project updates, as any changes that aren't pulled beforehand aren't included in the Local Vault project.
  - q: What happens if my Git repository contains legacy Insomnia content when I create a Git Sync project?
    a: If the Git repository you connect contains legacy Insomnia content, Insomnia automatically converts that content to the current project format during project creation. This ensures that the content is compatible with modern Insomnia workflows. If the repository already contains Insomnia content, whether legacy or current, Insomnia prompts you to import that content into the new Git Sync project before continuing.
  - q: Can I choose which email address Insomnia uses for Git commits?
    a: |
      Yes. If your OAuth provider account has more than one verified email address, then Insomnia lets you pick which email address to use for Git commits when you're using Git Sync. You can select only from the email addresses returned by your OAuth provider.  

      Choose the commit email when you first set up a project or when you configure Git Sync. Insomnia uses the selected email for all commit metadata in that project.

      If your OAuth provider account has only one verified email address, then Insomnia uses that email and doesn't show an email selection option in the UI.

      {:.warning}
      > From inside Insomnia, you can't create or edit email addresses. To manage email addresses, use your OAuth provider.
---
Insomnia offers various storage options to cater to different user needs and preferences.

Understanding these options is crucial for efficient and secure management of your API projects. This document outlines the primary storage options available in Insomnia: 
- [Local Vault](#local-vault)
- [Scratch pad](#scratch-pad)
- [Cloud Sync](#cloud-sync)
- [Git Sync](#git-sync)

{:.info}
> Storage type isn't fixed. It's possible to change your storage type after you create the project. For example, you can change a Local Vault project into a Cloud Sync project if your project requires collaboration.

Use the following table to understand what storage option to use:

<!--vale off-->
{% table %}
columns:
  - title: "You have..."
    key: conditions
  - title: "Then use..."
    key: solution
rows:
  - conditions: |
      * Organizations with strict data privacy regulations.  
      * Projects that must remain fully local.  
      * Environments with limited or restricted internet access.
    solution: "[Local Vault](#local-vault)"
  - conditions: |
      * Individual contributors who don't want their projects saved to the cloud.
      * Work on projects offline.
      * A sandbox type environment where you can experiment without interfering with team projects.
    solution: "[Scratch pad](#scratch-pad)"
  - conditions: |
      * Teams that need built-in collaboration.  
      * Users who work from multiple locations or devices.  
      * Projects that benefit from centralized, cloud-based management.
    solution: "[Cloud Sync](#cloud-sync)"
  - conditions: |
      * Users who want to manage version control with their own remote Git repository.
      * Projects that require detailed version tracking and rollback capabilities.  
      * Teams that already use Git for other aspects of their development workflow.
    solution: "[Git Sync](#git-sync)"
{% endtable %}
<!--vale on-->

## Local Vault

Local Vault is a storage option that allows all project data to be stored locally on your device, or through Git sync.
This option is ideal for users who prefer or require their data to remain off the cloud for privacy or security reasons.

Key features:
* **Local storage:** All project files are stored on your local machine.
* **No cloud interaction:** No data is sent to or stored in the cloud.
* **Security:** Enhanced security as data remains within your local environment.
* **Work offline:** Access and work on your projects without needing an internet connection.

You can create a Local Vault project when you create a new project in Insomnia and select the **Local Vault** option.

## Scratch pad

Scratch pad is a storage option that allows all project data to be stored locally on your device.
This option is ideal for users who prefer or require their data to remain off the cloud for privacy or security reasons.

Key features:
* **Local storage:** All project files are stored on your local machine.
* **No cloud interaction:** No data is sent to or stored in the cloud.
* **Security:** Enhanced security as data remains within your local environment.
* **Work offline:** Access and work on your projects without needing an internet connection.

Before you log in to Insomnia, you can use scratch pad by clicking **Use the local Scratch Pad** at the bottom of the login screen.

## Cloud Sync

Cloud Sync enables users to store and synchronize their project data in the cloud securely, and use [version control](/insomnia/version-control/).

This feature is beneficial for collaboration, providing easy access to projects from different devices and locations. 

Cloud Sync provides the following abilities on top of the base Insomnia functionality:
* Commit and push the contents of projects
* Revert to a previous commit
* Share commits across devices or with members of your organization
* Create and work on separate branches
* Store MCP Client configuration as part of the project

Key use case features:
* **End-to-End Encryption (E2EE):** Ensures data is encrypted during transmission and storage.
* **Real-time synchronization:** Keeps your projects up-to-date across all devices.
* **Collaboration:** Share and collaborate on projects with team members.
* **Remote access:** Access your projects from anywhere with an internet connection.

{:.info}
> When you create a project with Cloud Sync in an organization, the project is automatically available to all users in the organization.

### Cloud Sync data flow

The following diagram shows how data flows when Insomnia is configured with Cloud Sync:

{% mermaid %}
flowchart LR
    subgraph userDesktop [User desktop]
        A(<b>Insomnia resources</b><br>Design documents<br>Request collections<br>Unit tests)
        B(<b>Cloud Sync capabilities</b><br>Manage commits<br>Cloud pull/push<br>Cloud branches)
    end 

    subgraph unsure [ ]
        C(<b>Insomnia resources</b><br>Design documents<br>Request collections<br>Unit tests<br>Environments<br>RBAC<br>License)
        D(<b>Cloud Sync capabilities</b><br>Manage commits<br>Git pull/push<br>Git branches)
    end

    subgraph insomniaCloud [Insomnia Cloud]
        E(<img src="/assets/icons/database.svg" style="max-width:25px; display:block; margin:0 auto;"/>Database)
        F(<img src="/assets/icons/google-cloud.svg" style="max-width:25px; display:block; margin:0 auto;"/>Google Cloud)
    end

    A <--> C
    B <--> D
    C <--> E
    C <--> F
    D <--> E
    D <--> F

{% endmermaid %}

## Git Sync

Git Sync allows users to use a third-party Git repository for storing project data.

This option is independent of cloud access and is suitable for users familiar with Git workflows.

Key features:
* **Version control:** Leverage Git’s [version control](/insomnia/version-control/) capabilities for your projects.
* **Independence from Insomnia’s Cloud:** Uses external Git repositories for storage.
* **Provider flexibility:** Choose any Git service provider, like GitHub, GitLab, or Bitbucket.
* **Collaboration via Git:** Collaborate with others using standard Git practices.
* **Built-in conflict resolution**: Resolve conflicts in Insomnia when pulling or pushing changes.
* **MCP clients feature**: Store MCP Client configuration in the Git repository as part of the project.

{:.info}
> When you create a project with Git sync in an organization, it's only available to you. The project name, its metadata, and the corresponding Git URL are not shared with other users in the organization. To collaborate on a Git sync project, each user must create a project and connect to the Git repository. This allows you to control who can access the project within the organization. <br><br>
> You can also create the Git Sync project now and add a repository later. 

To use Git Sync, either create a new project or edit the settings of an existing project. From the **Type** dropdown menu, select "Git Sync". 

Configure the credentials for your Git repository using one of the following options:
* Add the credentials here, in the Git Sync config
* Add the credentials to your local `git.config` file
* Configure the credentials in **Preferences** > **Credentials** {% new_in 12.3 %}



### Git Sync data flow

The following diagram shows how data flows when Insomnia is configured with Git Sync:

{% mermaid %}
flowchart LR
    subgraph userDesktop [User desktop]
        A(<b>Insomnia resources</b><br>Design documents<br>Request collections<br>Unit tests<br>Environments)
        B(<b>Git capabilities</b><br>Manage commits<br>Git pull/push<br>Git branches)
    end 

    subgraph unsure [ ]
        C(<b>Insomnia resources</b><br>Design documents<br>Request collections<br>Unit tests<br>Environments)
        D(<b>Git capabilities</b><br>Manage commits<br>Git pull/push<br>Git branches)
    end

    subgraph insomniaCloud [Insomnia Cloud]
        E(<img src="/assets/icons/database.svg" style="max-width:25px; display:block; margin:0 auto;" />Database)
        F(<img src="/assets/icons/google-cloud.svg" style="max-width:25px; display:block; margin:0 auto;" />Google Cloud)
    end

    subgraph Git-based source code management provider
       subgraph .
        G(<img src="/assets/icons/bitbucket.svg" style="max-width:25px; display:block; margin:0 auto;"/>Bitbucket)
        H(<img src="/assets/icons/gitlab.svg" style="max-width:25px; display:block; margin:0 auto;" />GitLab)
        I(<img src="/assets/icons/github.svg" style="max-width:25px; display:block; margin:0 auto;" />GitHub)
        end
    end
    
    J(<b>Insomnia resources</b><br>RBAC<br>License)


    E <--> J
    F <--> J <--> A <--> C
    B <--> D
    C <--> G & H & I
    D <--> G & H & I

    style . stroke:none
{% endmermaid %}