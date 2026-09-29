---
title: Deleting a consumer credential with the Admin API
content_type: support
description: How to delete a consumer credential (basic-auth, key-auth, ACL, HMAC, JWT, or OAuth 2.0) using the Kong Admin API DELETE endpoint.
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources: []
tldr:
  q: How can a consumer credential be deleted with the Admin API?
  a: |
    Send a `DELETE` request to the credential's Admin API endpoint, for example `DELETE /default/consumers/joe/basic-auth/testcred`. The path segment (`basic-auth`, `key-auth`, `acls`, `hmac-auth`, `jwt`, `oauth2`) and identifier field vary by credential type.
---

## Overview

How can a consumer credential be deleted with the Admin API?

## Steps

You can delete a specific credential by sending a DELETE request to

```

http(s)://<kong-host>:<admin-port>/consumers/<workspace>/<consumer_id_or_name>/<type of credentials>/<credentials_id_or_name>
```

For example, assuming the below parameters this can be used to delete a basic auth credential:

```

kong-host: localhost
admin-port: 8001
workspace: default
consumer name: joe
credential type: basic-auth
credential username: testcred
```

Request:

```bash

curl -X DELETE -H "kong-admin-token:kong"  http://localhost:8001/default/consumers/joe/basic-auth/testcred
```

The credential types and named fields are as follows:

<!--vale off -->
{% table %}
columns:
  - title: Credential Type
    key: credential_type
  - title: Value
    key: value
  - title: Field Reference
    key: field_reference
  - title: Example
    key: example
rows:
  - credential_type: "Basic Authentication"
    value: "basic-auth"
    field_reference: "Username"
    example: ":8001/default/consumers/joe/basic-auth/<username>"
  - credential_type: "ACL"
    value: "acls"
    field_reference: "Group"
    example: ":8001/default/consumers/joe/acls/<group-name>"
  - credential_type: "Key Authentication"
    value: "key-auth"
    field_reference: "Key"
    example: ":8001/default/consumers/joe/key-auth/<key>"
  - credential_type: "HMAC Authentication"
    value: "hmac-auth"
    field_reference: "Username"
    example: ":8001/default/consumers/joe/hmac-auth/<username>"
  - credential_type: "JWT"
    value: "jwt"
    field_reference: "Key"
    example: ":8001/default/consumers/joe/jwt/<key>"
  - credential_type: "OAuth 2.0"
    value: "oauth2"
    field_reference: "Client ID"
    example: ":8001/default/consumers/joe/oauth2/<client-id>"
{% endtable %}
<!--vale on -->
