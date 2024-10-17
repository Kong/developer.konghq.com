---
title: Git sync

content_type: concept
layout: concept

products:
    - insomnia

tier: team

related_resources:
  - text: Security at Insomnia
    url: /
  - text: Configure git sync
    url: /
  - text: Storage options
    url: /insomnia/storage-options
  - text: Cloud sync
    url: /insomnia/cloud-sync
  - text: Scratch pad
    url: /insomnia/scratch-pad
  - text: SSO
    url: /
  - text: About version control in Insomnia
    url: /insomnia/version-control

---

Git sync allows users to use a third-party Git repository for storing project data. This option is independent of cloud access and is suitable for users familiar with Git workflows.

Key features:
* **Version control:** Leverage Git’s [version control](/insomnia/version-control) capabilities for your projects.
* **Independence from Insomnia’scCloud** Uses external Git repositories for storage.
* **Provider flexibility:** Choose any Git service provider, like GitHub, GitLab, or Bitbucket.
* **Collaboration via Git:** Collaborate with others using standard Git practices.

For more information about how to configure git sync, see [Configure git sync](/).

## Data flow

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
