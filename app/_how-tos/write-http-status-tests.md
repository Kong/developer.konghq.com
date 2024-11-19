---
title: Write tests for HTTP status codes in Insomnia
content_type: how_to

related_resources:
  - text: Write tests for headers in the response in Insomnia
    url: /how-to/write-headers-in-response-test/
  - text: Write tests for content types in Insomnia
    url: /how-to/write-content-type-tests/
  - text: Write tests for data types in Insomnia 
    url: /how-to/write-data-type-tests/
  - text: Automate tests in Insomnia
    url:  /how-to/automate-tests/
  - text: Chain requests in Insomnia
    url: /how-to/chain-requests/

products:
    - insomnia

tags:
    - test-apis

tldr:
    q: How do I write HTTP status code tests in Insomnia?
    a: After you add a collection, you can create a new test suite for the collection and then use the default Javascript test. 

prereqs:
    inline:
        - title: Create and configure a collection
          include_content: prereqs/create-collection
          icon_url: /assets/icons/menu.svg
cleanup:
  inline:
    - title: Clean up Insomnia
      include_content: cleanup/products/insomnia
      icon_url: /assets/icons/insomnia/insomnia.svg
---

## 1. Create a test suite

Before you create a test, you need to create a test suite for our collection. 

To do this, click the **Tests** tab and click **New test suite** in the sidebar.

## 2. Create a HTTP status code test

You can create a test that checks a request against a certain status code. 

1. From the Test Suite you just created, click **New test**. Insomnia creates a default `Return 200` request for you:
```javascript
const response1 = await insomnia.send();
expect(response1.status).to.equal(200);
```
1. From the **Select a request** drop down, select the **GET KongAir planned flights** request.
1. Click the **Play** icon next to your test. In the preview to the right, you should see that the test passes.