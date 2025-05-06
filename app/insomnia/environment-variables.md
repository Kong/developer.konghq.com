---
title: Environment variables

description: Configure environment variables to reuse values across multiple requests.

content_type: reference
layout: reference
breadcrumbs: 
  - /insomnia/
search_aliases:
  - env variables
  - insomnia secrets
products:
    - insomnia

related_resources:
  - text: Storage
    url: /insomnia/storage/
  - text: Git sync
    url: /insomnia/storage/#git-sync
  - text: Local vault
    url: /insomnia/storage/#local-vault
  - text: External vault
    url: /insomnia/external-vault/
---


## Environment variables

An environment is a [JSON object](https://www.json.org/json-en.html) containing key-value pairs of the data you want to reference. Access the environment manager through the environment dropdown menu at the top of the sidebar. From here, you can edit the base environment, create sub environments, assign colors, and more.

{% table %}
columns:
  - title: Environment Type
    key: type
  - title: Description
    key: description
rows:
  - type: Base Environment
    description: >-
      Assigned to every workspace and accessible via the environment manager. Variables here are available throughout the entire workspace. Commonly used for default values that do not vary across environments (e.g., resource names, sample data).
  - type: Sub Environments
    description: >-
      Typically used for environment-specific values (production, staging, development) or user-specific configurations. Activated via the environment dropdown. Sub environments can be marked as Private and won't be synced or exported.
  - type: Folder Environments
    description: >-
      Defined at the folder level.
{% endtable %}

### Referencing environment variables

Environment variables can be referenced in any text input within the Insomnia application. There are two ways to do this:

* Use the autocomplete dropdown by pressing `Control+Space`
* As you type, the autocomplete will display automatically 

## Global environments

Global environments can be defined on a project level and used across multiple collections, including leveraging them in pre-request and after-response scripting.

You can create as many global environments as you want, so you aren't limited to only one. You can store them locally on your computer or use Cloud Sync or Git Sync for collaboration (based on your storage settings for your projects).

## Environment priority order

If you define the same environment variable across different levels of environments, both at a global environment level as well as on a given collection's environments, the lowest-level value will take priority:

- Global environment (base) *(highest-level)*
- Global environment (Sub-environment)
- Collection environment (base)
- Collection environment (Sub-environment)
- Folder-level environment *(lowest-level)*


## Secret environment variables

Secret environment variables allow you to store sensitive data locally in encrypted form. These variables are masked by default, are not stored in plain text, and are only accessible within the vault namespace (for example, `vault.foo` for a variable named `foo`).

Insomnia does not persist the vault key automatically. If you lose your vault key, you can reset it, but all stored secrets will be permanently deleted for security reasons.

## Managing secrets

To store secrets:

1. Generate a vault key from the **Preferences** page.
2. Create a new **sub private environment** within any global environment.
3. Add your secret variable in the sub private environment and set its type to `Secret`.

## Using secrets in scripts

By default, secret variables are not exposed to scripts. To enable access:

1. Navigate to **Preferences** > **General** > **Security**.
1. Enable the **Enable vault in scripts** setting.

Once enabled, you can access secrets in scripts using:

```js
insomnia.vault.get('<ENV_NAME>')
```
