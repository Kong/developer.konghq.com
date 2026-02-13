---
title: Sign {{site.base_gateway}} audit logs with an RSA key
permalink: /how-to/sign-gateway-audit-logs/

description: Use a key pair to sign audit logs in {{site.base_gateway}}.

content_type: how_to
related_resources:
  - text: "{{site.base_gateway}} logs"
    url: /gateway/logs/
  - text: "{{site.base_gateway}} audit logs"
    url: /gateway/audit-logs/
  # - text: Validate {{site.base_gateway}} audit log signatures
  #   url: /how-to/validate-gateway-audit-log-signatures/

products:
    - gateway

works_on:
    - on-prem

tools:
  - admin-api

min_version:
  gateway: '3.4'

entities: 
  - vault

tags:
    - logging
    - audit-logging
    - security

tldr:
    q: How do I sign audit logs with a key?
    a: Generate an RSA key pair and set the path to the key as the value of the [`audit_log_signing_key`](/gateway/configuration/#audit-log-signing-key) parameter in `kong.conf`.

prereqs:
  inline: 
    - title: Audit logging
      content: |
          This tutorial requires audit logging. To enable it, add the following line to [`kong.conf`](/gateway/manage-kong-conf/):
          ```
          audit_log = on
          ```

          Once this is done, restart the {{site.base_gateway}} container:
          ```sh
          docker restart kong-quickstart-gateway
          ```

      icon_url: /assets/icons/audit.svg

# next_steps:
#   - text: Validate {{site.base_gateway}} audit log signatures
#     url: /how-to/validate-gateway-audit-log-signatures/

cleanup:
  inline:
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg

automated_tests: false
---

## Generate a key pair

Use OpenSSL to generate a private key to sign logs and a public key to verify signatures:
```sh
openssl genrsa -out private.pem 2048
openssl rsa -in private.pem -outform PEM -pubout -out public.pem
```

## Add the private key to your container

Use the following command to add the private key to the {{site.base_gateway}} Docker container:

```sh
docker cp private.pem kong-quickstart-gateway:/usr/local/kong
```

## Enable audit log signing

Add the following line to [`kong.conf`](/gateway/configuration/#audit-log-signing-key) to sign audit logs using the private key we created:
```
audit_log_signing_key = /usr/local/kong/private.pem
```

Once this is done, restart the {{site.base_gateway}} container to apply the change:
```sh
docker restart kong-quickstart-gateway
```

## Validate

To validate, start by sending any request to generate to generate an audit log entry. For example:

{% control_plane_request %}
url: /status
{% endcontrol_plane_request %}

Then request the audit logs and check that the entry contains a signature:
{% control_plane_request %}
url: /audit/requests
{% endcontrol_plane_request %}