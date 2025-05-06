---
title: Insomnia terminology reference

description: This page defines concepts related to Insomnia.
breadcrumbs: 
  - /insomnia/
search_aliases:
  - Insomnia terms
content_type: reference
layout: reference

products:
- insomnia

---

## Design document
A design document is a workspace containing tools to design an API specification. You can write and edit a spec, generate a collection from the spec to send requests, and create test suites to run different types of tests against your API or API spec.

For more details, see [Documents](/insomnia/documents/)

## Request collection
A request collection is a workspace for sending requests. You can create new requests or import requests from an API spec, clipboard, or even from a Postman collection. Requests can be customized with environment variables, template tags, pre-request and after-response scripts. Requests can be run individually or as a series of requests to run together.

For more details, see [Collections](/insomnia/collections/)

## Mock server
A mock server is a self-hosted or cloud-hosted way to simulate an API endpoint. You can create a mock server and define endpoints manually, or generate them from existing responses. You can customize the response code, body, and headers.

For more details, see [Mock servers](/insomnia/mock-servers/).

## Scratch Pad
The Insomnia Scratch Pad is a local workspace that you can use to send requests. It doesn't require creating an Insomnia account. The Scratch Pad functions as a collection, and you have access to all collection features.

For more details, see [Scratch Pad](/insomnia/scratch-pad/).

## Collection Runner
The Collection Runner is a tool that allows you to send multiple requests in a specific order. You can also chain requests to reuse elements from a request or response in another one.

For more details, see [Use the Collection Runner](/how-to/use-the-collection-runner/) and [Chain requests](/how-to/chain-requests/).

## Template tag
A template tag is a type of variable that you can use to reference or transform values. You can reuse an element from a request or a response, get the current timestamp, encode a value, prompt the user for an input value, etc.


## Pre-request script
A pre-request script is a feature in a collection that allows you to define actions to perform before running a request. For example, you can set a variable, add a query parameter, remove a header, etc. Once you send the request, the pre-request script runs before the request is actually sent. The results of the script are displayed in the console.

## After-response script
An after-response script is a feature in a collection that allows you to define actions to perform after receiving the response to a request. For example, you can get the response body, check for data types, clear a variable, etc. The results of the script are displayed in the console.