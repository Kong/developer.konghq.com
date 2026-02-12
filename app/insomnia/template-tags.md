---
title: Template tags

description: A template tag is a type of variable that you can use to reference or transform values.

content_type: reference
layout: reference
breadcrumbs: 
  - /insomnia/
products:
  - insomnia

related_resources:
  - text: Requests
    url: /insomnia/requests/
  - text: Collections
    url: /insomnia/collections/
  - text: Scripts
    url: /insomnia/scripts/
  - text: Environments
    url: /insomnia/environments/
  - text: Dynamic variables
    url: /insomnia/dynamic-variables/
  - text: Plugins
    url: /insomnia/plugins/
  - text: Plugin reference
    url: /insomnia/plugins/plugin-reference/
---

A template tag is a type of variable that you can use to reference or transform values. You can reuse an element from a request or a response, get the current timestamp, encode a value, or prompt the user for an input value.

You can create a template tag in the request URL, query parameters, body, or authentication by pressing `Control+Space` and selecting a tag. Once the tag has been added, you can click it to configure it if needed.

Available template tag functions include:
* **External Vault** to reference secrets from an [external vault](/insomnia/external-vault/)
* **Faker** to generate random data
* **Base64** to encode and decode values
* **Timestamp** to get the current date and time in a specific format
* **UUID** to generate a UUID in version 1 or version 4
* **OS** to get various details about the current Operating System
* **Hash** to apply a hash with a specific algorithm and encoding to a value
* **File** to read contents from a file
* **JSONPath** to pull data from a JSON string using JSONPath
* **Cookie** to reference a cookie value from the cookie jar
* **Prompt** to prompt a user for input
* **Response** to reference a value from another request's response
* **Request** to reference a value from the current request

## Custom template tags

If you want to extend the template tag functionality, you can do so by developing a custom template tag as an [Insomnia plugin](/insomnia/plugins/plugin-reference/). Once you’ve added your custom plugin to your Insomnia application, the template tag will show up exactly as if it were a native Insomnia tag.

Here's the schema to create custom template tags:

```js
interface TemplateTag {
  name: string,
  displayName: DisplayName,
  disablePreview?: () => boolean,
  description?: string,
  deprecated?: boolean,
  liveDisplayName?: (args) => ?string,
  validate?: (value: any) => ?string,
  priority?: number,
  args: Array<{
    displayName: string,
    description?: string,
    defaultValue: string | number | boolean,
    type: 'string' | 'number' | 'enum' | 'model' | 'boolean',
    
    // Only type === 'string'
    placeholder?: string,

    // Only type === 'model'
    modelType: string,

    // Only type === 'enum'
    options: Array<{
      displayName: string,
      value: string,
      description?: string,
      placeholder?: string,
    }>,
  }>,
  actions: Array<{
    name: string,
    icon?: string,
    run?: (context) => Promise<void>,
  }>,
};
```

For example, to create a template tag that generates a random integer, you can use the following code:
```js
/**
 * Example template tag that generates a random number 
 * between a user-provided MIN and MAX
 */
module.exports.templateTags = [{
    name: 'randomInteger',
    displayName: 'Random Integer',
    description: 'Generate a random integer.',
    args: [
        {
            displayName: 'Minimum',
            description: 'Minimum potential value',
            type: 'number',
            defaultValue: 0
        }, 
        {
            displayName: 'Maximum',
            description: 'Maximum potential value',
            type: 'number',
            defaultValue: 100
        }
    ],
    async run (context, min, max) {
        return Math.round(min + Math.random() * (max - min));
    }
}];
```

### Raw template syntax

Use **Raw template syntax** to control how Insomnia inserts and edits template tags.

It's disabled by default, which means that Insomnia opens the template tag configuration form. You configure values using structured fields, and then Insomnia generates the template tag syntax automatically.

When enabled, Insomnia inserts template tags as plain text expressions instead of opening the configuration form. This means that you must write and edit the template tag syntax manually, and Insomnia won't display field hints, validation, or guided inputs in this mode.

Use **Raw template syntax** when you want direct control over template tag expressions. Leave it disabled if you want guided configuration and inline validation.

To enable **Raw template syntax**, from inside the Insomnia application, go to **Preferences > General > Application > Raw template syntax**.