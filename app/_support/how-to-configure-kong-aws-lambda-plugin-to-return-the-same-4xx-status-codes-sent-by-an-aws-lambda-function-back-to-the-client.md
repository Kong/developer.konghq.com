---
title: Configuring the Kong AWS Lambda plugin to return the same 4xx status codes sent by an AWS Lambda function back to the client
content_type: support
description: Explains how to enable `is_proxy_integration` on the Kong AWS Lambda plugin so it returns the same status codes sent by the AWS Lambda function to the client.
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: How do I configure the Kong AWS Lambda plugin to return the same 4xx status codes sent by an AWS Lambda function back to the client?
  a: |
    Enable `is_proxy_integration` on the Kong AWS Lambda plugin so it treats Lambda responses the way an AWS API Gateway Lambda proxy integration would, preserving the status code. Also make sure your Lambda function returns a proxy-integration-shaped response (a `statusCode` field, plus `headers` and `body`).
related_resources: []
---

## Overview

How to configure Kong AWS Lambda plugin to return the same 4xx status codes sent by an AWS Lambda function back to the client?

## Steps

To ensure Kong AWS Lambda plugin returns the same 4xx, 5xx, 2xx or any status codes sent by an AWS Lambda function back to the client, you need to enable the `is_proxy_integration` configuration in the Kong AWS Lambda plugin. This setting allows Kong to properly interpret and forward the response/status codes received from the Lambda function.

Here's a step-by-step guide to enable this configuration:

1. Locate the AWS Lambda plugin configuration in your Kong setup.

2. Modify the plugin configuration to enable or include `"is_proxy_integration": true`. This tells Kong to handle the response from AWS Lambda as if it were coming from an AWS API Gateway configured with Lambda proxy integration, which includes preserving the status code.

3. Ensure your Lambda function is returning the correct response structure for proxy integration. Here's an example AWS Lambda function:

   ```python
   def lambda_handler(event, context):
       return {
           "statusCode": 400,  # or any other 4xx/5xx code as per your logic
           "headers": {
               "Content-Type": "application/json"
           },
           "body": json.dumps({
               "message": "Hello, this is a RESTful response!",
               "data": event
           })
       }
   ```

4. After making these changes, deploy the updated plugin configuration and test to ensure that the correct status codes are being returned to the client.

By following these steps, Kong will forward the status codes from AWS Lambda function to the client, preserving the application's intended response behavior.
