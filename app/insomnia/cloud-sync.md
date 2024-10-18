---
title: Cloud sync 

content_type: concept
layout: concept

products:
    - insomnia

related_resources:
  - text: Storage options
    url: /insomnia/storage-options
  - text: Security at Insomnia
    url: /
  - text: Git sync
    url: /insomnia/git-sync
  - text: Scratch pad
    url: /insomnia/scratch-pad
  - text: Local vault
    url: /insomnia/local-vault
  - text: SSO
    url: /
  - text: About version control in Insomnia
    url: /insomnia/version-control

---

Cloud sync enables users to store and synchronize their project data in the cloud securely as well as use [version control](/insomnia/version-control). This feature is beneficial for collaboration, providing easy access to projects from different devices and locations. 

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

## Data flow

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