---
title: Dynamic variables

description: Define variables dynamically using scripts and iteration data.

content_type: reference
layout: reference
breadcrumbs: 
  - /insomnia/
search_aliases:
  - iterationdata
  - transient variables
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
  - test: Template tags
    url: /insomnia/template-tags/
---

Besides [environments](/insomnia/environments/), there are two other ways to define variables in Insomnia:
* Iteration variables, which are used in the Collection Runner to change a variable value on each iteration.
* Local variables, which are temporary variables defined in a pre-request or after-response script for each request.

## Iteration data

When you open the Collection Runner on your collection, you can see an **Upload Data** button. This allows you to upload a file containing variable values for each iteration. You can upload either a SCV or JSON file. Here's an example of the expected structure:

{% navtabs "data" %}
{% navtab "JSON" %}
```json
[
    {
        "variable_1": "value of variable_1 for the first iteration",
        "variable_2": "value of variable_2 for the first iteration"
    },
    {
        "variable_1": "value of variable_1 for the second iteration",
        "variable_2": "value of variable_2 for the second iteration"
    },
    {
        "variable_1": "value of variable_1 for the third iteration",
        "variable_2": "value of variable_2 for the third iteration"
    }
]
```
{% endnavtab %}

{% navtab "CSV" %}
```
variable_1,variable_2
value of variable_1 for the first iteration,value of variable_2 for the first iteration
value of variable_1 for the second iteration,value of variable_2 for the second iteration
value of variable_1 for the third iteration,value of variable_2 for the third iteration
```
{% endnavtab %}
{% endnavtabs %}

Once you've uploaded this file, you can use these variables anywhere in your request:
* In the URL, query parameters, body, or authentication with this format: {% raw %}`{{variable_1}}`{% endraw %}
* In scripts using `iterationData`: `insomnia.iterationData.get('variable_1')`

## Local variables

In pre-request and after-response [scripts](/insomnia/scripts/), you can manipulate environments to set, modify, or unset variables, but you can also set local temporary variables using `localVars`. For example:

```js
insomnia.variables.localVars.set("variable_name", "variable value")
```

You can then reference these temporary variables anywhere in your request:
* In the URL, query parameters, body, or authentication with this format: {% raw %}`{{variable_name}}`{% endraw %}
* In scripts using `insomnia.variables.localVars.get("variable_name")`

