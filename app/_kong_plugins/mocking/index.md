---
title: 'Mocking'
name: 'Mocking'

content_type: plugin

publisher: kong-inc
description: ''
tier: enterprise


products:
    - gateway


works_on:
    - on-prem
    - konnect

# topologies:
#    - hybrid
#    - db-less
#    - traditional

icon: mocking.png

related_resources:
  - text: DNS configuration reference
    url: /gateway/networking/dns-config-reference
---


## Overview

The Mocking plugin allows you to provide mock endpoints to test APIs in development against your existing services. The Mocking plugin leverages standards based on the Open API Specification (OAS) for sending out mock responses to APIs. Mocking supports both Swagger 2.0 and OpenAPI 3.0.

The Mocking plugin requires an API spec to work correctly. Depending on the Kong Gateway deployment mode, set either the api_specification_filename or the api_specification parameter in `kong.conf`.

## Mocked responses

The Mocking plugin can mock the following responses: 

* **`200`**
* **`201`**
* **`204`**

## Behavioral Headers


Behavioral headers allow you to change the behavior of the Mocking plugin for the individual request without changing the configuration.

### X-Kong-Mocking-Delay

The` X-Kong-Mocking-Delay` header tells the plugin how many milliseconds to delay before responding. The delay value must be between `0`(inclusive) and `10000`(inclusive), otherwise it returns a `400` error like this: 

```json
HTTP/1.1 400 Bad Request

{
    "message": "Invalid value for X-Kong-Mocking-Delay. The delay value should between 0 and 10000ms"
}
```
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

By default, the plugin chooses the minimum status code that is defined in the corresponding method.

The `X-Kong-Mocking-Status-Code` header allows requests to change the default status code selection behavior by specifying a status code that is defined in the corresponding method.
