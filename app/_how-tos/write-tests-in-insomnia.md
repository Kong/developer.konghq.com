---
title: Write customizable Javascript tests in Insomnia
related_resources:
  - text: Automate tests in Insomnia
    url:  /how-to/automate-tests/
  - text: Chain requests in Insomnia
    url: /how-to/chain-requests/

products:
    - insomnia

tags:
    - test-apis

tldr:
    q: How do I write tests for my APIs in Insomnia?
    a: After you add a collection, you can create a new test suite for the collection and then create individual tests in the suite. 

faqs:
  - q: How do I write a Javascript test to check for a nested body in a response?
    a: |
        ```javascript
        content
        ```
  - q: How do I write a Javascript test to check for a nested array in a response?
    a: |
        ```javascript
        content
        ```

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

Before we create a test, we need to create a test suite for our collection. 

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

## 3. Create a data type in body test

Now we can test if a data type is returned in the top-level request body. 

1. Click **New test** and enter a name for the test, such as "Data type in body". 
1. From the **Select a request** drop down, select the **GET KongAir planned flights** request.
1. The following Javascript checks if an array is present in the top-level body of the response. Enter the following in the Javascript for your test:
```javascript
const response1 = await insomnia.send();
const body = JSON.parse(response1.data);
expect(body).to.be.an('array');
```
1. Click the **Play** icon next to your test. In the preview to the right, you should see that the test passes.

## 4. Create a content type in body test

Now we can test if a content type is returned in the request body. 

1. Click **New test** and enter a name for the test, such as "Content type in body". 
1. From the **Select a request** drop down, select the **GET KongAir planned flights** request.
1. The following Javascript checks if the top-level array is present in the body of the response. Enter the following in the Javascript for your test:
```javascript
const response1 = await insomnia.send();
const body = JSON.parse(response1.data);
const item = body[1];
expect(item).to.be.an('object');
```
1. Click the **Play** icon next to your test. In the preview to the right, you should see that the test passes.

## 5. Create a headers in response test

Finally, we can test if a header is returned in the response. 

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