---
title: Git sync

description: Git sync allows users to use a third-party Git repository for storing project data.

content_type: concept
layout: concept

products:
    - insomnia

tier: team

related_resources:
  - text: Security at Insomnia
    url: /insomnia/security
  - text: Configure git sync
    url: /how-to/synchronize-with-git
  - text: Storage options
    url: /insomnia/storage-options
  - text: Cloud sync
    url: /insomnia/cloud-sync
  - text: Scratch pad
    url: /insomnia/scratch-pad
  - text: Local vault
    url: /insomnia/local-vault
  - text: SSO
    url: /insomnia/sso
  - text: About version control in Insomnia
    url: /insomnia/version-control

faqs:
  - q: Should I use Git sync or cloud sync?
    a: Both allow you to use version control and collaborate with your team. You should use Git sync if you're already using a Git repository and your team requires detailed version tracking and rollback capabilities.
  - q: I'm using Git sync, does Insomnia uphold the branch protections we have in our repository?
    a: Yes, if you have branch protections for a branch, say `main`, you won't be able to push to that branch in Insomnia.
  - q: With Git sync, if I create a branch in my Git repository, will it pull that branch into Insomnia? And vice versa?
    a: Yes, you'll have to pull it into Insomnia. You can push branches you make in Insomnia to your repository.
   
---

{{ page.description | liquify }}
This option is independent of cloud access and is suitable for users familiar with Git workflows.

Key features:
* **Version control:** Leverage Git’s [version control](/insomnia/version-control) capabilities for your projects.
* **Independence from Insomnia’s Cloud:** Uses external Git repositories for storage.
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