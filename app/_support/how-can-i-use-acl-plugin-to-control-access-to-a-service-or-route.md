---
title: Using the ACL plugin to control access to a service or route
content_type: support
description: ACL plugin can be used as an authorization mechanism to restrict access to a service or route, by adding Consumers to allowed or denied lists using arbitrary ACL group names.
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: How can I use ACL Plugin to control access to a service or route?
  a: |
    The ACL plugin controls access to a service or route by adding consumers to allow or deny lists using arbitrary group names. It requires an authentication plugin (such as Basic Authentication, Key Authentication, OIDC, or JWT) to already be enabled on the Service or Route.
related_resources: []
---

## Overview

How can I use ACL Plugin to restrict access to a service or route?

## Steps

ACL plugin can be used as an authorization mechanism to restrict access to a service or route, by adding Consumers to allowed or denied lists using arbitrary ACL group names. This plugin requires an authentication plugin, such as Basic Authentication, Key Authentication, OIDC, or JWT to have been already enabled on the Service or Route.

Here is an example of creating two consumers, adding JWT credentials for them, and adding them to ACL groups that give them access to corresponding routes:

```bash
http POST :8001/services name=testServiceA protocol=http host=httpbin.org port:=80 path=/ip
http POST :8001/services name=testServiceB protocol=http host=httpbin.org port:=80 path=/uuid
http POST :8001/services/testServiceA/routes name=testRouteA protocols:='["http"]' paths:='["/route1"]'
http POST :8001/services/testServiceB/routes name=testRouteB protocols:='["http"]' paths:='["/route2"]'
http POST :8001/consumers username=testUser1
http POST :8001/consumers username=testUser2
http POST :8001/consumers/testUser1/jwt key=Y0B46IsmlOCvMkHdGyIb7WBxC3MTD4qT secret=B2N1rI8lYq88NKhgsRGbQrYqbF0EQM7T
http POST :8001/consumers/testUser2/jwt key=wnIkumUF8KdIb4ql2O1Sbe7uI3kRw8Au secret=NTorIcD00S1VVUeab8lVICdAFiQM60e5
http POST :8001/routes/testRouteA/plugins name=jwt
http POST :8001/routes/testRouteB/plugins name=jwt
http POST :8001/consumers/testUser1/acls group=group1
http POST :8001/consumers/testUser2/acls group=group2
http --form POST :8001/routes/testRouteA/plugins name=acl config.allow=group1
http --form POST :8001/routes/testRouteB/plugins name=acl config.allow=group2
```

Now we can issue requests from both consumers to both services and see the expected outcomes:

```bash
http GET :8000/route1 Authorization:'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJZMEI0NklzbWxPQ3ZNa0hkR3lJYjdXQnhDM01URDRxVCJ9.o14Sl-DvCkFjT6bubsODuuRrb2m_ulyrsJ2EqY6mCaI'
http GET :8000/route2 Authorization:'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJZMEI0NklzbWxPQ3ZNa0hkR3lJYjdXQnhDM01URDRxVCJ9.o14Sl-DvCkFjT6bubsODuuRrb2m_ulyrsJ2EqY6mCaI'
http GET :8000/route1 Authorization:'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJ3bklrdW1VRjhLZEliNHFsMk8xU2JlN3VJM2tSdzhBdSJ9.mrQNQ0q6T1SAabVBmSoFBTk7PMBIcaGJKdJCK7fKE-E'
http GET :8000/route2 Authorization:'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJ3bklrdW1VRjhLZEliNHFsMk8xU2JlN3VJM2tSdzhBdSJ9.mrQNQ0q6T1SAabVBmSoFBTk7PMBIcaGJKdJCK7fKE-E'
```
