---
title: "Receiving '[kong] access.lua:80 session not present' when using Basic Auth"
content_type: support
description: A trailing newline in a base64-encoded Kubernetes secret can make the decoded password not match what's typed, triggering a 401 and this session error.
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources: []
tldr:
  q: Why does Basic Auth login to Kong Manager fail with "[kong] access.lua:80 session not present" even though the password looks correct?
  a: |
    The Kubernetes secret holding the password may contain a trailing newline. Decoding it and re-encoding the same value produces a different base64 string when a newline is present, so the entered password never matches the stored value, causing a 401 and this session error. Re-create the secret using a base64 value without the trailing newline and restart Kong.
---

## Problem

When trying to log into Kong Manager with Basic Auth, we are receiving the below error in Kong Debug logs.

```

"[kong] access.lua:80 session not present"
```

If we use developer tools to debug the scenario on login we see the following stack trace in the console logs of Chrome.

```

createError.js:16 Uncaught (in promise) Error: Request failed with status code 401
at e.exports (createError.js:16:1)
at e.exports (settle.js:17:1)
at f.onreadystatechange (es.function.has-instance.js:59:1)
at XMLHttpRequest.nrWrapper (login:1:15476)
```

We setup Basic Auth on our Kubernetes system and have the password stored in a secret.

## Solution

If the password being entered matches the value of the secret, I would recommend verifying the encoded value of the password inside the secret.

To verify this we can do the following:

```bash
kubectl get secrets kong-enterprise-superuser-password -o yaml -n <namespace>
```

Result:

```yaml
apiVersion: v1
data:
  password: a29uZwo=
kind: Secret
metadata:
  creationTimestamp: "2026-06-24T18:10:38Z"
  name: kong-enterprise-superuser-password
  namespace: kong
  resourceVersion: "351183"
  uid: fef2f168-245f-4d58-9c32-ae8d89ff04a4
type: Opaque
```

From here we'll grab the password listed to confirm and base64 decode it.

Sample 1:

```bash
echo a29uZwo= | base64 --decode
```

Value:

```

kong
```

From here I would rebase64 encode the value to confirm nothing extra is being added.

Sample 2:

```bash
echo -n kong | base64
```

Value:

```

a29uZw==
```

Now we can see 2 different base64 encodings for the same value. The difference is that Sample 1 contains a new line character. So the password looks correct however when entered it won't ever match the value entered causing a 401 and "[kong] access.lua:80 session not present".

To resolve this, update the secret using the base64 value without the new line character and restart Kong to log in successfully.
