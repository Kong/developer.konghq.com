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
  - q: What is the difference between local vault and scratch pad?
    a: In both local vault and scratch pad, project data is stored locally. With local vault, you can also use git sync. In scratch pad, all data is stored locally, so it is best suited for individual developers who aren't working as part of a team.
  - q: Should I use Git sync or cloud sync?
    a: Both allow you to use version control and collaborate with your team. You should use Git sync if you're already using a Git repository and your team requires detailed version tracking and rollback capabilities.
  - q: Can I create branch protections in Insomnia for cloud sync?
    a: No.
  - q: I'm using Git sync, does Insomnia uphold the branch protections we have in our repository?
    a: Yes, if you have branch protections for a branch, say `main`, you won't be able to push to that branch in Insomnia.
  - q: With Git sync, if I create a branch in my Git repository, will it pull that branch into Insomnia? And vice versa?
    a: Yes, you'll have to pull it into Insomnia. You can push branches you make in Insomnia to your repository. 
  - q: Can I bulk import across multiple Cloud Sync projects?
    a: |
      {% new_in 11.5 %} Yes. Enterprise users can activate this feature by contacting [support](https://insomnia.rest/support) to enable the feature flag on their account.
      Once activated, go to **Insomnia → Preferences → Data** and select the **Import projects to Org** option.
  - q: What are the user and Git Sync limits for the Essentials plan?  
    a: |
      On the **Essentials** plan, you can choose one of two configurations:
      - Activate **Git Sync** with a limit of up to **3 users** per organization.
      - Deactivate **Git Sync** and allow **unlimited users**.

      You can switch between configurations at any time.  
      When you reach the limit, Insomnia automatically flags it in the application. For example, if you try to add a fourth user while Git Sync is activated, or activate Git Sync when more than three users are already active.  
      In either case, you can reduce users or disable Git Sync to continue
---
Insomnia offers various storage options to cater to different user needs and preferences.

Understanding these options is crucial for efficient and secure management of your API projects. This document outlines the primary storage options available in Insomnia: local vault, scratch pad, cloud sync, and Git sync.

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
    solution: "[Local vault](#local-vault)"
  - conditions: |
      * Individual contributors who don't want their projects saved to the cloud.
      * Work on projects offline.
      * A sandbox type environment where you can experiment without interfering with team projects.
    solution: "[Scratch pad](#scratch-pad)"
  - conditions: |
      * Teams that need built-in collaboration.  
      * Users who work from multiple locations or devices.  
      * Projects that benefit from centralized, cloud-based management.
    solution: "[Cloud sync](#cloud-sync)"
  - conditions: |
      * Users who want to manage version control with their own remote Git repository.
      * Projects that require detailed version tracking and rollback capabilities.  
      * Teams that already use Git for other aspects of their development workflow.
    solution: "[Git sync](#git-sync)"
{% endtable %}
<!--vale on-->

## Local vault

Local vault is a storage option that allows all project data to be stored locally on your device, or through Git sync.
This option is ideal for users who prefer or require their data to remain off the cloud for privacy or security reasons.

Key features:
* **Local storage:** All project files are stored on your local machine.
* **No cloud interaction:** No data is sent to or stored in the cloud.
* **Security:** Enhanced security as data remains within your local environment.
* **Work offline:** Access and work on your projects without needing an internet connection.

You can create a local vault project when you create a new project in Insomnia and select the **Local vault** option.

## Scratch pad

Scratch pad is a storage option that allows all project data to be stored locally on your device.
This option is ideal for users who prefer or require their data to remain off the cloud for privacy or security reasons.

Key features:
* **Local storage:** All project files are stored on your local machine.
* **No cloud interaction:** No data is sent to or stored in the cloud.
* **Security:** Enhanced security as data remains within your local environment.
* **Work offline:** Access and work on your projects without needing an internet connection.

Before you log in to Insomnia, you can use scratch pad by clicking **Use the local Scratch Pad** at the bottom of the login screen.

## Cloud sync

Cloud sync enables users to store and synchronize their project data in the cloud securely, and use [version control](/insomnia/version-control/).

This feature is beneficial for collaboration, providing easy access to projects from different devices and locations. 

Cloud sync provides the following abilities on top of the base Insomnia functionality:
* Commit and push the contents of projects
* Revert to a previous commit
* Share commits across devices or with members of your organization
* Create and work on separate branches

Key use case features:
* **End-to-End Encryption (E2EE):** Ensures data is encrypted during transmission and storage.
* **Real-time synchronization:** Keeps your projects up-to-date across all devices.
* **Collaboration:** Share and collaborate on projects with team members.
* **Remote access:** Access your projects from anywhere with an internet connection.

{:.info}
> When you create a project with Cloud sync in an organization, the project is automatically available to all users in the organization.

### Cloud sync data flow

The following diagram shows how data flows when Insomnia is configured with cloud sync:

{% mermaid %}
flowchart LR
    subgraph userDesktop [User desktop]
        A(<b>Insomnia resources</b><br>Design documents<br>Request collections<br>Unit tests)
        B(<b>Cloud sync capabilities</b><br>Manage commits<br>Cloud pull/push<br>Cloud branches)
    end 

    subgraph unsure [ ]
        C(<b>Insomnia resources</b><br>Design documents<br>Request collections<br>Unit tests<br>Environments<br>RBAC<br>License)
        D(<b>Cloud sync capabilities</b><br>Manage commits<br>Git pull/push<br>Git branches)
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

## Git sync

Git sync allows users to use a third-party Git repository for storing project data.

This option is independent of cloud access and is suitable for users familiar with Git workflows.

Key features:
* **Version control:** Leverage Git’s [version control](/insomnia/version-control/) capabilities for your projects.
* **Independence from Insomnia’s Cloud:** Uses external Git repositories for storage.
* **Provider flexibility:** Choose any Git service provider, like GitHub, GitLab, or Bitbucket.
* **Collaboration via Git:** Collaborate with others using standard Git practices.
* {% new_in 10.2 %} **Built-in conflict resolution**: Resolve conflicts in Insomnia when pulling or pushing changes.

{:.info}
> When you create a project with Git sync in an organization, it's only available to you. The project name, its metadata, and the corresponding Git URL are not shared with other users in the organization. To collaborate on a Git sync project, each user must create a project and connect to the Git repository. This allows you to control who can access the project within the organization. <br><br>
> {% new_in 11.5 %} You can also create the Git Sync project now and add a repository later. 

### Git sync data flow

The following diagram shows how data flows when Insomnia is configured with Git sync:

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