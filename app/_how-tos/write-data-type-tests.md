---
title: Write tests for data types in Insomnia
content_type: how_to

related_resources:
  - text: Write tests for headers in the response in Insomnia
    url: /how-to/write-headers-in-response-test/ 
  - text: Write tests for HTTP status codes in Insomnia
    url: /how-to/write-http-status-tests/
  - text: Write tests for content types in Insomnia
    url: /how-to/write-content-type-tests/
  - text: Automate tests in Insomnia
    url:  /how-to/automate-tests/
  - text: Chain requests in Insomnia
    url: /how-to/chain-requests/

products:
    - insomnia

tags:
    - test-apis

tldr:
    q: How do I write data type tests in Insomnia?
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

## Create a test suite

Before you create a test, you need to create a test suite for our collection. 

To do this, click the **Tests** tab and click **New test suite** in the sidebar.

## Create a top-level data type in body test

Now you can test if a data type is returned in the top-level request body. 

1. Click **New test** and enter a name for the test, such as "Data type in body (top-level)". 
1. From the **Select a request** drop down, select the **GET KongAir planned flights** request.
1. The following Javascript checks if an array is present in the top-level body of the response. Enter the following in the Javascript for your test:
```javascript
const response1 = await insomnia.send();
const body = JSON.parse(response1.data);
expect(body).to.be.an('array');
```
1. Click the **Play** icon next to your test. In the preview to the right, you should see that the test passes.

## Create a top-level data type in body test

Now you can test if a data type is returned in the top-level request body. 

1. Click **New test** and enter a name for the test, such as "Data type in body (nested)". 
1. From the **Select a request** drop down, select the **GET Fetch more details about a flight** request.
1. The following Javascript checks if the first string in the `meal_options` array is present in the body of the response. Enter the following in the Javascript for your test:
```javascript
const response1 = await insomnia.send();
const body = JSON.parse(response1.data);
expect(body).to.be.an('object');
expect(body).to.have.property('meal_options'); 
expect(body.meal_options).to.be.an('array');
if (body.meal_options.length > 0) {
    expect(body.meal_options[0]).to.be.a('string');
}
```
1. Click the **Play** icon next to your test. In the preview to the right, you should see that the test passes.