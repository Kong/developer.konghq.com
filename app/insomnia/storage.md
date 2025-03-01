---
title: Storage options in Insomnia

description: Insomnia offers various storage options to cater to different user needs and preferences.

content_type: reference
layout: reference

products:
    - insomnia

related_resources:
  - text: Security at Insomnia
    url: /insomnia/security/
  - text: Git sync
    url: /insomnia/git-sync/
  - text: Scratch pad
    url: /insomnia/scratch-pad/
  - text: SSO
    url: /insomnia/sso/

---

{{ page.description | liquify }}
Understanding these options is crucial for efficient and secure management of your API projects. This document outlines the three primary storage options available in Insomnia: Local Vault, Cloud Sync, and Git Sync.

| You have... | Then use... |
| --- | --- |
| * Organizations with strict data privacy regulations. <br> * Users working on sensitive projects that require enhanced security.<br> * Environments with limited or restricted internet access. | [Local vault (scratch pad)](/insomnia/storage/#local-vault-scratch-pad) | 
| * Teams requiring collaboration on API projects.<br> * Users who work from multiple locations or devices. <br> * Projects that benefit from centralized, cloud-based management. | [Cloud sync](/insomnia/storage/#cloud-sync) | 
| * Users comfortable with Git and its versioning system.<br> * Projects that require detailed version tracking and rollback capabilities.<br>* Teams that already use Git for other aspects of their development workflow. | [Git sync](/insomnia/storage/#git-sync) | 

## Local vault (scratch pad)

Local Vault is a storage option that allows all project data to be stored locally on your device. This option is ideal for users who prefer or require their data to remain off the cloud for privacy or security reasons.

Key features:
* **Local storage:** All project files are stored on your local machine.
* **No cloud interaction:** No data is sent to or stored in the cloud.
* **Security:** Enhanced security as data remains within your local environment.
* **Work offline:** Access and work on your projects without needing an internet connection.

For more information about how to configure scratch pad, see [Scratch pad](/).

## Cloud sync
Cloud Sync enables users to store and synchronize their project data in the cloud securely. This feature is beneficial for collaboration, providing easy access to projects from different devices and locations.

Key features:
* **End-to-End Encryption (E2EE):** Ensures data is encrypted during transmission and storage.
* **Real-time synchronization:** Keeps your projects up-to-date across all devices.
* **Collaboration:** Share and collaborate on projects with team members.
* **Remote access:** Access your projects from anywhere with an internet connection.

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
        E(<div style="text-align:center;"><img src="/assets/icons/database.svg" style="max-width:25px; display:block; margin:0 auto;" class="no-image-expand"/>Database</div>)
        F(<div style="text-align:center;"><img src="/assets/icons/google-cloud.svg" style="max-width:25px; display:block; margin:0 auto;" class="no-image-expand"/>Google Cloud</div>)
    end

    A <--> C
    B <--> D
    C <--> E
    C <--> F
    D <--> E
    D <--> F

{% endmermaid %}

## Git sync
Git Sync allows users to use a third-party Git repository for storing project data. This option is independent of cloud access and is suitable for users familiar with Git workflows.

{:. note}
> **Note:** Git sync applies to users subscribed to the [Team plan](https://insomnia.rest/pricing) and above.

Key features:
* **Version control:** Leverage Git’s version control capabilities for your projects.
* **Independence from Insomnia’scCloud** Uses external Git repositories for storage.
* **Provider flexibility:** Choose any Git service provider, like GitHub, GitLab, or Bitbucket.
* **Collaboration via Git:** Collaborate with others using standard Git practices.

For more information about how to configure git sync, see [Git sync](/).

The following diagram shows how data flows when Insomnia is configured with git sync:

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
        E(<div style="text-align:center;"><img src="/assets/icons/database.svg" style="max-width:25px; display:block; margin:0 auto;" class="no-image-expand"/>Database</div>)
        F(<div style="text-align:center;"><img src="/assets/icons/google-cloud.svg" style="max-width:25px; display:block; margin:0 auto;" class="no-image-expand"/>Google Cloud</div>)
    end

    subgraph Git-based source code management provider
        G(<div style="text-align:center;"><img src="/assets/icons/bitbucket.svg" style="max-width:25px; display:block; margin:0 auto;" class="no-image-expand"/>Bitbucket</div>)
        H(<div style="text-align:center;"><img src="/assets/icons/gitlab.svg" style="max-width:25px; display:block; margin:0 auto;" class="no-image-expand"/>GitLab</div>)
        I(<div style="text-align:center;"><img src="/assets/icons/github.svg" style="max-width:25px; display:block; margin:0 auto;" class="no-image-expand"/>GitHub</div>)
    end
    
    J(<b>Insomnia resources</b><br>RBAC<br>License)


    E <--> J
    F <--> J
    J <--> A
    A <--> C
    B <--> D
    C <--> G
    C <--> H
    C <--> I
    D <--> G
    D <--> H
    D <--> I
{% endmermaid %}

