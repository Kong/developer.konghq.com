---
title: Unit testing
name: Unit testing

content_type: concept
layout: concept

description: Test the responses of a single endpoint in Insomnia.

related_resources:
  - text: Test APIs in Insomnia
    url: /insomnia/test/
  - text: Test content types in responses
    url: /how-to/write-content-type-tests/
  - text: Test data types in responses
    url: /how-to/write-data-type-tests/
  - text: Test headers in responses
    url: /how-to/write-headers-in-response-tests/
  - text: Test HTTP statuses in responses
    url: /how-to/write-http-status-tests/
  - text: Run a collection
    url: /how-to/run-a-collection/

faqs:
  - q: Why do I need to write unit tests when I can use Insomnia to debug my code?
    a: Debugging can only help you with test syntax. Unit tests allow you to test the output of endpoints to see if they are functioning correctly.
  - q: How do I automate my unit tests in Insomnia?
    a: You can automate your unit tests by using Collection Runner or the `inso run test "document name" --env "environment name"` Inso CLI command.

tools:
    - inso-cli
---

## What is unit testing?

Unit testing typically allows you to test that the response from a single endpoint is the response you expected. These tests can help you validate that the endpoint is handling the given parameters correctly or that returns the expected error message when an incorrect value is sent. 

{% mermaid %}
sequenceDiagram
    participant API as API endpoint (/flights/KA0284/details)
    participant FS as Flight service
    participant DB as Database

    API->>FS: Call GetFlightDetails("KA0284")
    FS->>DB: Query for flight details
    DB-->>FS: Return flight details
    FS-->>API: Return flight details

    alt Flight doesn't exist
        DB-->>FS: Return error (404 not found)
        FS-->>API: Return error response (404 not found)
    end
{% endmermaid %}

## Use cases for unit testing

The following are examples of common use cases for unit testing:

|Use case | Description|
|---------|------------|
|Identifying errors | When there's an error in an endpoint, only that specific unit test will fail, so it's easier to isolate the issue.|
|Ensuring functionality | Unit tests help you ensure that each endpoint is working correctly independent of the other endpoints.|

## Unit test examples

You can use the following unit test examples in Insomnia:

### Set an environment variable

```javascript
insomnia.environment.set("variable_name", "variable_value");
```

### Check if the response is a `200`

```javascript
insomnia.test('Check if status is 200', () => {
    insomnia.expect(insomnia.response.code).to.eql(200);
});
```

### Check if the response is an array

```javascript
insomnia.test("Response should be an array", function () {
    var jsonData = insomnia.response.json();
    
    insomnia.expect(jsonData).to.be.an('array');
});
```
