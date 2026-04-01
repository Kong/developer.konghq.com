---
title: Write tests for content types in Insomnia
permalink: /how-to/write-content-type-tests/
content_type: how_to
description: Learn how to write content type tests in Insomnia.
related_resources:
  - text: Write tests for headers in the response in Insomnia
    url: /how-to/write-headers-in-response-test/ 
  - text: Write tests for HTTP status codes in Insomnia
    url: /how-to/write-http-status-tests/
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
    q: How do I write content type tests in Insomnia?
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

{% include /how-tos/steps/insomnia-test-suite.md %}

## Create a top-level content type in body test

Now we can test if a content type is returned in the top-level request body. 

1. Click **New test** and enter a name for the test, such as "Content type in body (top-level)". 
1. From the **Select a request** drop down, select the **GET KongAir planned flights** request.
1. Enter the following JavaScript to check if the top-level array is present in the body of the response:
   ```javascript
   const response1 = await insomnia.send();
   const body = JSON.parse(response1.data);
   const item = body[1];
   expect(item).to.be.an('object');
   ```
{% include /how-tos/steps/insomnia-run-tests.md %}

## Create a nested content type in body test

Now we can test if a content type is returned in the nested request body. 

1. Click **New test** and enter a name for the test, such as "Content type in body (nested)". 
1. From the **Select a request** drop down, select the **GET Fetch more details about a flight** request.
1. Enter the following JavaScript to check if the nested `meal_options` array is present in the body of the response:
   ```javascript
   const response1 = await insomnia.send();
   const body = JSON.parse(response1.data);
   expect(body).to.have.property('meal_options'); 
   expect(body.meal_options).to.be.an('array');
   expect(body).to.be.an('object'); 
   ```
{% include /how-tos/steps/insomnia-run-tests.md %}