---
title: Create a Key Set with a PEM Key
content_type: how_to

entities: 
  - key
  - key-set

related_resources:
  - text: Key entity
    url: /gateway/entities/key/
  - text: Key Set entity
    url: /gateway/entities/key-set/

products:
    - gateway

works_on:
    - on-prem
    - konnect

min_version:
  gateway: '3.4'

tldr:
  q: How do I create a PEM key and add it to a Key Set?
  a: Create a Key Set with the `/key-sets` endpoint, then create a Key and configure the `set.id` or `set.name` parameter to point to the Key Set. 

prereqs:
  inline:
    - title: PEM key pair
      content: |
        This tutorial requires a public key and private key. You can generate them using OpenSSL:
        ```sh
        openssl genrsa -out private.pem 2048
        openssl rsa -in private.pem -outform PEM -pubout -out public.pem
        ```
      icon_url: /assets/icons/key.svg

cleanup:
  inline:
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg
---

## 1. Create a Key Set

{% control_plane_request %}
  url: /key-sets
  method: POST
  headers:
      - 'Accept: application/json'
      - 'Content-Type: application/json'
      - 'Kong-Admin-Token: $KONG_ADMIN_TOKEN'
  body:
      name: my-pem-key-set
{% endcontrol_plane_request %}

## 2. Create a Key

Create a Key and use either the `set.id` or `set.name` parameter to add it to the Key Set.

{% control_plane_request %}
  url: /keys
  method: POST
  headers:
      - 'Accept: application/json'
      - 'Content-Type: application/json'
      - 'Kong-Admin-Token: $KONG_ADMIN_TOKEN'
  body:
      name: my-pem-key
      kid: my-pem-key
      set:
        name: my-pem-key-set
      pem:
        private_key: "-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQCJM4C5vlcQsSqy\nxB7htKCTgX0EDx5XHgNH26faMKLh21EYVyCM/5j/twmH4nL+M31UHmFcO0WJi68f\n2MTZm0RbcAgirvgfN/6KvqAaHmQwfxLqUwI2jWClK29dTgqoTqVyYf6nN8S2HDAm\nGaCl3K3UcNUQ6faM2KgrXuiJEFdQ+ChYUo2lh1pPhsWrGLhP/Uv8Y2zEZI9jxyL3\nNl1/pEGKL5dCIeqC3eaBplZKxFYvh+DvQGNywL9rwzHqsrBp6Zh7klGZrXfzNo35\nfWfyWOkF9aNayFR7XhZBeDCdo46rvFSRFaBC39MHE8+PVjnQXWuVp2uX7WxoBrYJ\nRwLROgYdAgMBAAECggEAOsf0CKBB0Qb2kixwRqcKfOfnVcvcZdqX8TtsiJB52GYM\nMm9xpLcFJ9mVncApIDuTIGz7rXY/bpSH7Q8EF27sNHilI6bu6wEkbvEIyufmaNio\nk/gIZLLhiyI2zjTXYBCB1aWiYqYEAznEby5fo3AOkYvd3Sc/2EwikKJS4hY8MpXe\nqukMeftO0QJVrsyyWLI4HqzZDWZ9t/Wjn7Me8Y3WNb6LeyExvLd9FETzxioC1APd\nfafpcYrJjUfCgMlfGnUR4q42Yothi058UHFvpqOSWAoszF+f/9E05Ck3RY9tuUIT\nUBYUmMrGvTXxiEP57Ie3zi+yVET6kXbXnjSmrNsdyQKBgQC9CLX0MUm7QRIv+dMg\nU26fdWwWUsEbQndI2aWfDvFXeKeNGlaOlEEj2CdbC6AXlGt1jC8w3YaXUpJ78hcA\n5a+LgRV17KH7dHPtEBGPwqqc8hHY+ZOUzpcw1OtFXGnL1Zy2kqYkYC7f4hj7ILU0\ngFXR9ntfQgIbZyUpcdvf/Fa1QwKBgQC5ziDO5CZ9/mFEhL0c9grT+rsXjKYIZOV5\nKp1koIpKAZZTHcb5jjYeL3MOLrtr1Ai680Y7oeX5apjjja4DQLgyXME6tZ4OyaHv\n0vVHuoKm7XbPoFmGcMqSvARq5GKhzoV44mVNeD3RnE2JYBT+O5we1CYnUtgEKE9w\n8BL/qTLxHwKBgHHaPTzGMtJFbt7WaQKfPZFs95y6WvRAI/gMnmQea91zHfcuVdOq\nF1GvboS3i8Sn79Dsjb+wrM+XPALK3G/95qzvIi3UR/tbODcf5nPfm0LLyVQVfX2y\nr/0JQGqWLmJGVgzgZpCiHZlaZBFcscbdRNMg0U2eRAadKRS9LuDI6rBhAoGAFwkM\nHjpA32vzKSh/vaBvVTqHiXLhfrbrkCsNWlVg763ksidF7NiJsxJU5FQ83jBqaKsS\ncQAwX8ysacG96h9S9sNzHVE46EJtNitkR2FDI2jbSwBpOPaw1qJCtfHcnIzbFVKU\nFpeqqlsDbd2gnKhNQbExjbyClXld5/WLlXCnpScCgYEAlrPt8+/ukVy/dm/JgzIj\nrJebgfGjkhIGyaewhXjyF7FDnamIz+C6ncaZQd+J80pv721vFurlapbHrBWImRkM\nFHRpseR87W8MHR6jvlqUyta5eA/wDPUykgujC/6yu0o8xIF3hIT9nfqcbxjJnUL4\nS3z87tUoPLUK8HtLoXDuE0c=\n-----END PRIVATE KEY-----"
        public_key: "-----BEGIN PUBLIC KEY-----\nMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAiTOAub5XELEqssQe4bSg\nk4F9BA8eVx4DR9un2jCi4dtRGFcgjP+Y/7cJh+Jy/jN9VB5hXDtFiYuvH9jE2ZtE\nW3AIIq74Hzf+ir6gGh5kMH8S6lMCNo1gpStvXU4KqE6lcmH+pzfEthwwJhmgpdyt\n1HDVEOn2jNioK17oiRBXUPgoWFKNpYdaT4bFqxi4T/1L/GNsxGSPY8ci9zZdf6RB\nii+XQiHqgt3mgaZWSsRWL4fg70BjcsC/a8Mx6rKwaemYe5JRma138zaN+X1n8ljp\nBfWjWshUe14WQXgwnaOOq7xUkRWgQt/TBxPPj1Y50F1rladrl+1saAa2CUcC0ToG\nHQIDAQAB\n-----END PUBLIC KEY-----"
{% endcontrol_plane_request %}