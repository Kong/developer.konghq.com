---
title: Convert project storage types in Insomnia
content_type: reference
layout: reference
breadcrumbs: 
  - /insomnia/
products:
    - insomnia
tier: enterprise
description: Learn what happens when you change a project storage type in Insomnia, including supported conversions, limitations, prerequisites, and FAQs.

faqs:
  - q: Does converting a Git Sync project delete my repository?
    a: |
      No. When you convert away from Git Sync, Insomnia disconnects the project from the Git repository. Insomnia does not delete or modify the repository.
  - q: Does converting from Cloud Sync remove cloud data?
    a: |
      Yes. When you convert a Cloud Sync project to Local Vault, Insomnia permanently removes the cloud-stored data for that project.
  - q: Can I use Git Sync after converting to Local Vault?
    a: |
      Yes. After converting to Local Vault, you can enable Git Sync for the project again.
  - q: Can I use Git Sync with Cloud Sync?
    a: |
      Yes. You can use Git Sync alongside Cloud Sync.
  - q: What happens if the Git repository contains legacy Insomnia content?
    a: |
      When you create a Git Sync project from a repository that contains legacy Insomnia content, Insomnia converts the content to the current project format during project creation.

---

A project’s storage type controls where Insomnia stores the project data and how the project syncs.

When you convert a project’s storage type, Insomnia stores the project in the new storage backend. The project no longer follows the sync model of the previous storage type. There's no limit on how many times you can convert a project’s storage type.

You can convert a project to:

- **[Local Vault](/insomnia/storage/#local-vault)**
- **[Cloud Sync](/insomnia/storage/#cloud-sync)**
- **[Git Sync](/insomnia/storage/#git-sync/)**

## Prerequisites

Before you convert a project:

- If the project uses Cloud Sync or Git Sync, pull the latest changes.
- Confirm that you have access to the destination storage type:
  - For Git Sync: confirm that you can access the target repository.
  - For Cloud Sync: confirm that you can access the organization.

## Conversion behavior and limits

Each storage conversion changes where the project data is stored and how the project syncs. Before converting, review the effects of the target storage type. Converting can stop collaboration or disconnect the project from its previous storage backend.

### Convert Cloud Sync to Local Vault

When you convert a Cloud Sync project to Local Vault, Insomnia permanently removes the project’s cloud-stored data and stores the project on your local device. Cloud collaboration stops.

**Limit:** Remote cloud changes that aren't present locally aren't included after conversion.

### Convert Local Vault to Cloud Sync

When you convert a Local Vault project to Cloud Sync, Insomnia begins synchronizing the project to Insomnia Cloud. Cloud collaboration becomes available.

### Convert Git Sync to Cloud Sync

When you convert a Git Sync project to Cloud Sync, Insomnia disconnects the project from your Git repository. New changes are stored in Insomnia Cloud and aren't reflected in the original repository. Insomnia doesn't delete or modify existing files in the repository.

**Limit:** Repository changes that you didn't pull before conversion aren't included after conversion.

### Convert Git Sync to Local Vault

When you convert a Git Sync project to Local Vault, Insomnia stores the project on your local device and stops synchronizing with Git. Changes made after conversion aren't reflected in your local or remote repository. Insomnia doesn't delete or modify the remote repository.

**Limit:** Repository changes that you didn't pull before conversion aren't included after conversion.

## Convert a project storage type

To convert a project’s storage type:

1. In the Insomnia application, from the **PROJECTS** panel, hover over a project.
2. Select the dropdown arrow, and click **Settings**.
3. In **Type** field, click **Change**.
4. Select the storage type.
5. Click **Update**.

{:.info}
> If you convert a project to **Git Sync**, Insomnia displays additional configuration fields.  
> 
> You must also:
> 1. Select a Git provider.
> 1. Authorize your account.
> 1. Select a repository.
> 1. Select a branch.
