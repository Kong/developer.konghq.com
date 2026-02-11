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
  - env var
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
  - text: Keyboard Shortcuts
    url: /insomnia/keyboard-shortcuts/  
---

An environment is a JSON object containing key-value pairs of the data you want to reference. There are different levels of environments that can be used in requests and scripts:

* Global environments, which can be accessed by all collections in a project
* Collection environments, which can be accessed by all requests in a collection
* Folder environments, which can be accessed by all requests in a folder

Global and collection environments contain:
* A base environment, commonly used for default values that don't vary across environments
* Optional sub-environments, commonly used for environment-specific values (production, staging, development) or user-specific configurations. Sub-environments can be marked as private. In this case, they aren't synced or exported, and require a [vault key](#managing-secrets) to be accessed.

You can also define variables dynamically in the Collection Runner and in pre-request and after-response [scripts](/insomnia/scripts/). For more details, see [Dynamic variables](/insomnia/dynamic-variables/).

## Create an environment

Use environments to define groups of variables that Insomnia applies across your requests. 
For example, you could create variables for base URLs, tokens, or credentials. 
If your API specifications or requests contain variables, you can use an environment to replace those variables with real values.

To create an environment:
1. In your Insomnia project, click **Environments**.
1. From the **Create a new Environment** window, in the **Name** field, enter a name for your environment. For example, "My environment".
1. Click **Create**.

{:.info}
> If you create an environment in a project that uses Git Sync, you must choose where to store the folder in your linked repository.

Insomnia applies the active environment to all requests in the collection.

## Manage environments

After you create an environment, you can edit its variables and create sub-environments.

### Edit environment variables

To add or update variables in an environment:
1. In the **Environments** list, select the environment that you want to edit.
1. Define variables as key-value pairs in JSON format. For example:
    ```json
    {
	  "global-base": "4444",
	  "exampleString": "globalenv0",
    }
    ```

Changes apply immediately to requests that reference the active environment.

### Create a sub-environment

Use sub-environments to override values from the base environment. For example, you can define different URLs or credentials for development, staging, or production.

{:.info}
> A sub-environment inherits all variables from its parent environment. You only need to define the values that are different.

To create a sub-environment:
1. Open the environment that you want to extend.
1. In the left panel, beside **Base Environment**, click the plus icon.
1. Select the type of environment that you want to create.
1. In the left panel, select your new environment.
1. Enter a name. For example, "Staging" or "Production".
1. Click **Add**.
1. Define only the variables that differ from the base environment.

{:.decorative}
> You can color-code your sub-environments to make it easier to navigate them. From the sub-environment variables view, click **Color**, and then select a color to apply to your sub-environment icon.

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

## Environment variables in scripts

You can use pre-request and after-response [scripts](/insomnia/scripts/) to set, unset, or modify environment variables. To ensure compatibility with Postman variables, there are multiple functions to interact with different environment types:

{% table %}
columns:
  - title: Insomnia functions
    key: functions
  - title: Environment type
    key: env
  - title: Postman function
    key: postman
rows:
  - functions: |
      * `insomnia.baseGlobals`
      * `insomnia.variables.baseGlobalVars`
    env: Global base environment
    postman: N/A
  - functions: |
      * `insomnia.globals`
      * `insomnia.variables.globalVars`
    env: Selected global sub-environment or global base environment
    postman: "`pm.globals`"
  - functions: "`insomnia.vault`"
    env: |
      [Secret variables](#secret-environment-variables) in selected private global sub-environment
    postman: "`pm.vault`"
  - functions: |
      * `insomnia.baseEnvironment`
      * `insomnia.CollectionVariables`
      * `insomnia.variables.collectionVars`
    env: Collection base environment
    postman: "`pm.collectionVariables`"
  - functions: |
      * `insomnia.environment`
      * `insomnia.variables.environmentVars`
    env: Selected collection sub-environment, or collection base environment if no sub-environment is selected
    postman: "`pm.environment`"
  - functions: "`insomnia.parentFolders.getEnvironments`"
    env: Folder environment
    postman: N/A
  - functions: |
      * `insomnia.iterationData`
      * `insomnia.variables.iterationDataVars`
    env: |
      [Iteration data variables](/insomnia/dynamic-variables/#iteration-data)
    postman: "`pm.iterationData`"
  - functions: "`insomnia.variables.localVars`"
    env: |
      [Temporary local variables](/insomnia/dynamic-variables/#local-variables)
    postman: N/A
  - functions: "`insomnia.variables`"
    env: |
      New variables will be created as temporary local variables

      When referencing existing variables, Insomnia can look for values in all environment types, in this order:
        1. Temporary local variables
        1. Iteration data variables
        1. Folder environment
        1. Selected collection sub-environment
        1. Collection base environment
        1. Selected global sub-environment
        1. Global base environment
    postman: "`pm.variables`"
{% endtable %}

{:.info}
> **Notes**
> * In private global sub-environments, `insomnia.vault` can only be used to reference secret variables. Text and JSON variables must be referenced with `insomnia.globals` or `insomnia.variables.globalVars`.
> * If you haven't selected a global environment in your collection, you can still set global variables in scripts but these will be temporary and will not be saved anywhere. You can only reference them in the current script.

## Secret environment variables

Secret environment variables allow you to store sensitive data locally in encrypted form. These variables are masked by default, are not stored in plain text, and are only accessible within the vault namespace (for example, `vault.foo` for a variable named `foo`).

Insomnia does not persist the vault key automatically. If you lose your vault key, you can reset it, but all stored secrets will be permanently deleted for security reasons.

### Managing secrets

To store secrets:

1. Generate a vault key in Insomnia:
   1. Navigate to the **Preferences** settings page at the bottom left in the Insomnia sidebar.
   1. On the General tab, scroll to the Security section and click **Generate Vault Key**.
1. Create a new private sub-environment within any global environment.
1. Add your secret variable in the private sub-private environment and set its type to `Secret`.

   {:.warning}
   > Variables with the `Secret` type are available only in private **global** sub-environment, not in collection environments.

### Using secrets in scripts

By default, secret variables are not exposed to scripts. To enable access:

1. Navigate to the **Preferences** settings page at the bottom left in the Insomnia sidebar.
1. In the **General** tab, scroll to the **Security** section and click the **Enable vault in scripts** checkbox.

Once enabled, you can access secrets in scripts using:

```js
insomnia.vault.get('VARIABLE NAME')
```

{:.info}
> Make sure to select the relevant global private sub-environment in your collection to make the secrets available to the requests.