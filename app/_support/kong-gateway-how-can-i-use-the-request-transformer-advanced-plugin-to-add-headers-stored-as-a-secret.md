---
title: Adding headers stored as a secret with the Request Transformer Advanced plugin
content_type: support
description: "Store a header's `value` (not the whole `headerName:headerValue` pair) as the secret when using Secrets Management with the Request Transformer Advanced plugin, to avoid the header name getting URL-encoded."
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources: []
tldr:
  q: How can I use the Request Transformer Advanced plugin to add headers stored as a secret?
  a: |
    Store only the header's `value` as the secret, not the whole `headerName:headerValue` pair — otherwise the header name gets mangled and URL-encoded. Reference it with `config.add.header: {vault://env/<name>}` for environment variables, or `{vault://aws/<secret>}` (or `{vault://aws/<secret>/<key>}` for multi-value secrets) for AWS Secrets Manager.
---

## Problem

When testing the Kong Secrets Management with the Request Transformer Advanced plugin, you notice that the formatting is incorrect.

Example:

```json
{
  "headers": {
    "%7B%22Name%22": "\"gruber\"}",
    "Accept": "*/*",
    "Host": "httpbin.org",
}
```

## Cause

Failure to format this properly will result in extra characters being added to the header name, which in turn, get URL encoded as seen above.

## Solution

To use a secret as a header, the correct format is to store the `value` as seen below.

```
headerName:headerValue
```

Examples:

### Environment variable

For environment variables, including Docker and Kubernetes:

```bash
NEWHEADER="addMe:addValue"
```

Referenced as: `config.add.header: {vault://env/newheader}`

```json
{
  "headers": {
    "Accept": "*/*",
    "Addme": "addValue",
    "Host": "httpbin.org",
}
```

### AWS Secrets Manager

AWS Secrets Manager defaults to storing secrets as key/value pairs. To store headers in AWS Secrets Manager, there are a few options available.

Option 1:

Secret type: other type of secret

Key/value pairs: Choose plaintext, delete the default JSON formatting and replace it with the Header Name and Header Value separated by a colon.

Name: This can be whatever you like and will be used later when we reference the secret in the Request Transformer Plugin. For the example here I will name the secret `header`.

`addMe:addValue`

Referenced as: `config.add.header: {vault://aws/secretname}`

Option 2:

If the requirement is to store multiple Key/Value pairs inside one AWS Secret, then the Headers can be stored as a Key/Value pair inside the Secret Value. The Request Transformer Advanced plugin can then retrieve any specific Secret Value by referencing the Secret Key and add it as a header.

Referenced as: `config.add.header: {vault://aws/secretname/header}`
