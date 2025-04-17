---
title: Requests in Insomnia

description: Insomnia allows you to configure and send different types of requests.

content_type: reference
layout: reference

products:
- insomnia

breadcrumbs:
- /insomnia/

tags:
- requests
- responses
- collections

related_resources:
  - text: Collections
    url: /insomnia/collections/

faqs:
- q: What type of requests can I send with Insomnia?
  a: |
    Insomnia supports:
    * HTTP
    * Event streams (SSE)
    * GraphQL
    * gRPC
    * WebSocket
---

## How do I create requests in Insomnia?

In Insomnia, requests are contained in collections. Before you can create a request, you need to create a collection. To do that, click **Create** > **Request collection** in your Insomnia project.

Once your collection is created, there are several ways to create requests. Click the `+` button and select an option:

|Option|Steps|
|---|---|
|Create a request from scratch|Select the type or request to create (HTTP, Event Stream, GraphQL, gRPC, or WebSocket).|
|Import a cURL command|Select **From Curl**, then paste your command and click Import.|
|Import from a file (Postman collection, Swagger, OpenAPI, HAR, WSDL)|Click **From File**, select an import option (file, URL, or clipboard), specify the file to import, then click **Scan** and **Import**.|

## How can I configure requests?

In Insomnia, you can configure every part of your request, and you can also add scripts and documentation.

{:.info}
> All of these options apply to HTTP, GraphQL, and event stream requests. WebSocket requests have all of these expect for methods and scripts, and gRPC requests have a completely different configuration. <!-- Link to gRPC docs? -->

|Element|Steps|
|---|---|
|Method|Select an HTTP method in the dropdown list, or add a custom method.|
|Endpoint|Enter a URL, and use environment variables and template tags if needed.|
|Query parameters|In the **Params** tab, click **Add** to create a new query parameter and enter the name and value. You can also add a description. The value can be single line or multi-line text. You can use the checkbox next to the parameter to remove it from the URL without deleting it completely.|
|Body|In the **Body** tab, select the type of body from the dropdown list.|
|Authentication|In  the **Auth** tab, select the authentication type from the dropdown list to get the corresponding form. If the request is in a folder, you can select **Inherit from parent** to use the folder's authentication.|
|Headers|In the **Headers** tab, click **Add** to create a new header and enter the name and value. You can also add a description. You can use the checkbox next to the header to remove it from the request without deleting it completely.|
|Scripts|In the **Scripts** tab, select **Pre-request** or **After-response** and write your script.|
|Docs|In the **Docs** tab, select **Write** to add documentation to the request. You can use Markdown and HTML syntax, and you can click **Preview** to see the rendered content.|

## What can I do with requests?

You can simply click **Send** to send a request, but you can also click the context menu to see more options.

{:.info}
> These options are only available for HTTP and event stream requests.

|Option|Description|
|---|---|
|**Generate Client Code**|Generate code based on you request. You can choose from a variety of languages.|
|**Send After Delay**|Send the request after the specified amount of time.|
|**Repeat On Interval**|Send the request on a loop with a specific interval. The loop needs to be stopped manually by clicking **Cancel**.|

<!-- The table is missing Send And Download and Download After Send, but I'm seeing weird behavior so I need to check with the team -->

## What can I do with folders in a request collection?

Folders can be used to organize requests, but you can also add configuration to be used by all requests in the folder:

* Authentication
* Headers
* Scripts
* Environment variables

You can also add documentation about the folder.