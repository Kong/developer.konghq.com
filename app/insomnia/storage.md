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
    url: /insomnia/security/
  - text: SSO
    url: /insomnia/authentication-authorization/#set-up-sso

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
      * Users working on sensitive projects that require enhanced security.  
      * Environments with limited or restricted internet access.
    solution: "[Local vault](#local-vault)"
  - conditions: |
      * Individual contributors who don't want their projects saved to the cloud
      * Work on projects offline
      * A sandbox type environment where you can experiment without interfering with team projects
    solution: "[Scratch pad](#scratch-pad)"
  - conditions: |
      * Teams requiring collaboration on API projects.  
      * Users who work from multiple locations or devices.  
      * Projects that benefit from centralized, cloud-based management.
    solution: "[Cloud sync](#cloud-sync)"
  - conditions: |
      * Users comfortable with Git and its versioning system.  
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
* **Collaborate:** With local vault, you still have the option to use [Git sync](#git-sync).

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