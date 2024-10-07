---
title: Create a new API specification in Insomnia
products:
    - insomnia

tags:
  - documents

tldr: 
  q: How do I create a new API spec in Insomnia?
  a: |
    Create a new API spec in Insomnia by creating a new design document and then adding your spec in the center pane editor. Specs must be in the OpenAPI 2.0.x or later format. You can create specs for a REST API or GraphQL API.
  
faqs:
  - q: Can I create a GraphQL API spec in Insomnia?
    a: Yes. For Insomnia to autodetect that your spec is in GraphQL format, the path must be `/graphql`, the method must be `POST`, the request body must be application/json and must contain a property query with the type string, and the response body must be application/json.
  - q: Can I create a spec in a collection?
    a: 
---

## 1. Create a document

In Insomnia, you can create an API spec on a [design document](). 

1. In your Insomnia workspace, click **Create** and select **Design document**.  
    ![Create a design document](/assets/images/insomnia/create-a-design-document.png)

1. Enter a name for your design document.

## 2. Create and edit your spec

Now that you have a design document, you can start creating your spec.

1. Your spec editor is in the center pane. You can create your spec there.
    ![Spec editor](/assets/images/insomnia/document-spec-editor.png)

As you create your spec, Insomnia will automatically [lint](/) it for you and render the preview in the right-side pane.

![API spec preview](/assets/images/insomnia/documents.png)



