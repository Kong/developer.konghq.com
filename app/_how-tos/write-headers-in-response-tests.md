---
title: Write tests for headers in the response in Insomnia
related_resources:
  - text: Write tests for HTTP status codes in Insomnia
    url: /how-to/write-http-status-tests/
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
    q: How do I write tests for response headers in Insomnia?
    a: After you add a collection, you can create a new test suite for the collection and then create individual tests in the suite. 

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

## 2. Create a headers in response test

Now you can test if a header is returned in the response. 

1. Click **New test** and enter a name for the test, such as "Header in the body". 
1. From the **Select a request** drop down, select the **GET KongAir planned flights** request.
1. The following Javascript checks if there are any headers in the response. Enter the following in the Javascript for your test:
```javascript
const response1 = await insomnia.send();
expect(Object.keys(response1.headers).length).to.be.greaterThan(0);
const body = JSON.parse(response1.data);
const item = body[1];
expect(item).to.be.an('object');
```
1. Click the **Play** icon next to your test. In the preview to the right, you should see that the test passes.