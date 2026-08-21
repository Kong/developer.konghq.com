---
min_version:
  ai-gateway: '2.0'
works_on:
  - konnect
products:
  - ai-gateway
content_type: plugin
---

The Mocking plugin allows you to provide mock endpoints to test APIs in development against your existing services. The Mocking plugin leverages standards based on the Open API Specification (OAS) for sending out mock responses to APIs. Mocking supports both Swagger 2.0 and OpenAPI 3.0.

You need an API spec you want to mock the endpoints of for the Mocking plugin to work correctly. Set the `api_specification` parameter in the policy configuration.

## Mocked responses

The Mocking plugin can mock the following responses: 

* **`200`**
* **`201`**
* **`204`**

## Behavioral headers

Behavioral headers allow you to change the behavior of the Mocking plugin for individual requests without changing the configuration.

### X-Kong-Mocking-Delay

The` X-Kong-Mocking-Delay` header tells the plugin how many milliseconds to delay before responding. The delay value must be between `0`(inclusive) and `10000`(inclusive), otherwise it returns a `400` error.

### X-Kong-Mocking-Example-Id

The `X-Kong-Mocking-Example-Id` header tells the plugin which response example is used when the endpoint has multiple examples for a single status code.

OpenAPI 3.0 allows you to define multiple examples in a single MIME type. The following example has two candidate examples: User1 and User2.

```yaml
paths:
  /query_user:
    get:
      responses:
        '200':
          description: A user object.
          content:
            application/json:
              examples:
                User1:
                  value:
                    id: 10
                    name: User1
                User2:
                  value:
                    id: 20
                    name: User2


```

### X-Kong-Mocking-Status-Code

By default, the Mocking AI Policy chooses the minimum status code that is defined in the corresponding method.

The `X-Kong-Mocking-Status-Code` header allows requests to change the default status code selection behavior by specifying a status code that is defined in the corresponding method.
