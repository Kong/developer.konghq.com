---
title: Environments

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
  - text: Requests
    url: /insomnia/requests/
  - text: Collections
    url: /insomnia/collections/
  - text: Scripts
    url: /insomnia/scripts/
  - text: Dynamic variables
    url: /insomnia/dynamic-variables/
  - text: Template tags
    url: /insomnia/template-tags/
---

An environment is a JSON object containing key-value pairs of the data you want to reference. There are different levels of environments that can be used in requests and scripts:

* Global environments, which can be accessed by all collections in a project.
* Collection environments, which can be accessed by all requests in a collection.
* Folder environments, which can be accessed by all requests in a folder.

Global and collection environments contain:
* A base environment, commonly used for default values that do not vary across environments
* Optional sub-environments, commonly used for environment-specific values (production, staging, development) or user-specific configurations. Sub-environments can be marked as private. In this case they are not be synced or exported, and require a vault key to be accessed.

You can also define variables dynamically in the Collection Runner and in pre-request and after-response [scripts](/insomnia/scripts/). For more details, see [Dynamic variables](/insomnia/dynamic-variables/).

## Referencing environment variables

Environment variables can be referenced in any text input within the Insomnia application. There are two ways to do this:

* Use the autocomplete dropdown by pressing `Control+Space`
* Start typing the name of the variable to display the autocomplete dropdown

## Environment priority

If you define the same environment variable across different levels of environments, Insomnia will look for the value in the following order:

1. Folder environment
1. Selected collection sub-environment
1. Collection base environment
1. Selected global sub-environment
1. Global base environment

## Secret environment variables

Secret environment variables allow you to store sensitive data locally in encrypted form. These variables are masked by default, are not stored in plain text, and are only accessible within the vault namespace (for example, `vault.foo` for a variable named `foo`).

Insomnia does not persist the vault key automatically. If you lose your vault key, you can reset it, but all stored secrets will be permanently deleted for security reasons.

## Managing secrets

To store secrets:

1. Generate a vault key from the **Preferences** page.
1. Create a new private sub-environment within any global environment.
1. Add your secret variable in the private sub-private environment and set its type to `Secret`.

## Using secrets in scripts

By default, secret variables are not exposed to scripts. To enable access:

1. Navigate to **Preferences** > **General** > **Security**.
1. Enable the **Enable vault in scripts** setting.

Once enabled, you can access secrets in scripts using:

```js
insomnia.vault.get('VARIABLE NAME')
```

{:.info}
> Make sure to select the relevant global private sub-environment in your collection to make the secrets available to the requests.