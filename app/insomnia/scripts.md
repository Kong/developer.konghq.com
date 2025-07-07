---
title: Scripts in Insomnia

description: Learn how to write pre-request and after-response scripts in Insomnia.

min_version:
  insomnia: '9.3'

content_type: reference
layout: reference
breadcrumbs: 
  - /insomnia/
products:
    - insomnia
tags:
  - test-apis
related_resources:
  - text: Write a pre-request script to add an environment variable in Insomnia
    url: /how-to/write-pre-request-scripts/
  - text: Write an after-response script to test a response in Insomnia
    url: /how-to/write-after-response-script/
---

## Pre-request scripts

Pre-request scripts allow you to execute tasks before a request is sent. They can be used to:

* Manipulate environment variables or authentication
* Manipulate the contents of the request
* Send other requests to get the data you need before running the request

### Pre-request script examples

The following sections provide pre-request script examples you can use.

#### Manipulate variables

The `insomnia` object serves as a handler for interacting with various types of variables. It offers a range of methods tailored for accessing the base environment and the active environment.

```js
// set a variable in environment
insomnia.environment.set("env", "env value");
// set a variable in base environment
insomnia.baseEnvironment.set("baseEnv", "base env value");
// set a variable in variables
insomnia.variables.set("var", "var value");
// collectionVariables operations are applied to the base environment
insomnia.collectionVariables.set("collectionEnv", "collection variable value");

// get values from different scopes
const env = insomnia.environment.get("env");
const variable = insomnia.variables.get("var");
const baseEnv = insomnia.baseEnvironment.get("baseEnv");

// print values
console.log(env, variable, baseEnv);

// unset values
insomnia.environment.unset("env");
insomnia.collectionVariables.unset("baseEnv");
```

#### Interpolate variables

The `replaceIn()` method can render a string with existing variables. For example, this script interpolates a string with the variable `name`:

{% raw %}
```js
insomnia.environment.set('name', 'Insomnia User');
const welcome = insomnia.environment.replaceIn("Hello {{name}}.");
console.log(welcome);
```
{% endraw %}

#### Generate a UUID

You can use the `uuid` external library to generate a UUID and set it as an environment variable:

```js
const uuid = require('uuid');
insomnia.environment.set('user_id', uuid.v4());
console.log(insomnia.environment.get('user_id'));
```

#### Update the current request content

You can use a pre-request scripts to modify the request URL, method, query parameters, headers, or body:
```js
// update the method
insomnia.request.method = 'POST';

// update query parameters
insomnia.request.url.addQueryParams('k1=v1');
insomnia.request.url.addQueryParams('k2=v2');
console.log(insomnia.request.url.getQueryString());

// update headers
insomnia.request.addHeader({key: 'X-Header-Name-1', value: 'value1' });
insomnia.request.addHeader({key: 'X-Header-Name-2', value: 'value2' });
insomnia.request.removeHeader('X-Header-Name-1');

// update the body
insomnia.request.body.update({
 mode: 'urlencoded',
 urlencoded: [
   { key: 'k1', value: 'v1' },
   { key: 'k2', value: 'v2' },
 ],
});

// update basic auth
// basic
insomnia.request.auth.update(
    {
        type: 'basic',
        basic: [
            {key: 'username', value: 'myName'},
            {key: 'password', value: 'myPwd'},
        ],
    },
    'basic'
);
```

#### Send a request

Send another request and set the response code as an environment variable:

```js
const resp = await new Promise((resolve, reject) => {
    insomnia.sendRequest(
        'https://httpbin.org/anything',
        (err, resp) => {
            if (err != null) {
                reject(err);
            } else {
                resolve(resp);
            }
        }
    );
});

insomnia.environment.set('prevResponse', resp.code);
```

## After-response scripts

After-response scripts allow you to execute tasks after a response is received. They can be used to:

* Perform tests and assertions on the response
* Store certain parts of the response into environment variables
* Send other requests based on the data received

### After-response examples

The following sections provide after-response script examples you can use.

#### Set environment variables

The `insomnia.response.json()` method allows you to call the full response body. To access attributes from the JSON body, you first need to define a variable:

```js
// Store the whole response
insomnia.environment.set("whole_response", insomnia.response.json());

// Store a specific field
const jsonBody = insomnia.response.json();
insomnia.environment.set("specific_field", jsonBody.specific_field);
```

#### Create a test

The `insomnia.test()` method allows you to create tests that will run after the response is received. You can, for example, check that a response attribute has a specific value:

```js
const jsonBody = insomnia.response.json();

insomnia.test('Check the ID', () => {
  insomnia.expect(jsonBody.id).to.eql('abc-123');
});
```

## External libraries

The `require()` method grants access to the built-in library modules within the scripts. Here are the available libraries:
* `ajv`
* `atob`
* `btoa`
* `chai`
* `cheerio`
* `crypto-js`
* `csv-parse`
* `lodash`
* `moment`
* `postman-collection`
* `tv4`
* `uuid`
* `xml2js`

The following NodeJS modules are also available:
* `assert`
* `buffer`
* `events`
* `path`
* `querystring`
* `punycode`
* `stream`
* `string-decoder`
* `timers`
* `url`
* `util`


## Migrating scripts from Postman

Scripts exported from Postman should also work when imported into Insomnia.

There are some differences to be aware about:

* Top level awaits are allowed
* Global environment `insomnia.globals` is not supported yet
* `CollectionVariables` is mapped to `baseEnvironment` in Insomnia
* Deprecated Postman interfaces, such as `postman.setEnvironmentVariable`, are not supported yet

If you notice any incompatibility issues, please report these by creating a [new issue on GitHub](https://github.com/kong/insomnia/issues).

## Accessing folder-level environment variables

In Insomnia, requests can be grouped within folders. These folders can influence request behavior in various ways, such as overriding environment variables and defining headers.

Insomnia provides functions that allow pre-request and after-response scripts to access the current requests' parent folder.

{:.info}
> You can only access a folder from a script if the corresponding request is in that folder.

### Get folder information

The `insomnia.parentFolders.get()` method allows you to get information about a folder:

```js
const myFolder = insomnia.parentFolders.get("FOLDER NAME");
```

* It accepts either a folder name or a folder ID. You can also use `insomnia.parentFolders.getById` or `insomnia.parentFolders.getByName` to explicitly accept a folder ID or folder name.
* It searches for the folder from the bottom parent folder to the top. If multiple parent folders share the same name, it returns the first one found.
* If no matching folder is found, it returns undefined.

### Manipulate folder-level variables

You can use the `environment` methods to manipulate folder-level variables in the same way as for [environment variables](#manipulate-variables). You just need to replace `insomnia` with the folder variable. For example:

```js
const myFolder = insomnia.parentFolders.get("MyFolder");
const urlValue = myFolder.environment.get("url");
```


