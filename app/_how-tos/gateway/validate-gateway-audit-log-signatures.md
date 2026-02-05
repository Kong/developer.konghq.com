---
title: Validate {{site.base_gateway}} audit log signatures

description: Use OpenSSL to validate signatures in {{site.base_gateway}} audit logs.

content_type: how_to
related_resources:
  - text: "{{site.base_gateway}} logs"
    url: /gateway/logs/
  - text: "{{site.base_gateway}} audit logs"
    url: /gateway/audit-logs/
  - text: Sign {{site.base_gateway}} audit logs with an RSA key
    url: /how-to/sign-gateway-audit-logs/

products:
    - gateway

works_on:
    - on-prem

tools:
  - admin-api

min_version:
  gateway: '3.4'

tags:
    - logging
    - audit-logging
    - security

tldr:
    q: How do I validate audit log signatures?
    a: Enable audit logging and log signing, generate request logs, then Base64 decode and transform the logs into canonical format. You can then use OpenSSL to validate the signature.

prereqs:
  inline: 
    - title: Audit logging and log signing
      content: |
          This tutorial requires audit logging and log signing. To enable these features, add the following lines to `kong.conf`:
          ```
          audit_log = on
          audit_log_signing_key = /path/to/private.pem
          ```

          For more details, see [Sign {{site.base_gateway}} audit logs with an RSA key](/how-to/sign-gateway-audit-logs/).

          Once this is done, restart the {{site.base_gateway}} container:
          ```sh
          docker restart kong-quickstart-gateway
          ```

      icon_url: /assets/icons/audit.svg

cleanup:
  inline:
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg

published: false
# validation fails
---

## Send a request to generate audit logs

Send any request to the Admin API to create an audit log entry:

{% control_plane_request %}
url: /status
{% endcontrol_plane_request %}

## Generate audit logs

Use the following command to generate the audit logs and save the result to a JSON file:

```sh
curl http://localhost:8001/audit/requests  -o logs.json
```

## Prepare the log entry for validation

In order to validate an audit log signature we need to:
* Decode the Base64-encoded signature.
* Transform the audit log record into its canonical format. This transformation requires serializing the record into a string format that can be verified. The format is a lexically-sorted, pipe-delimited string of each audit log record part, without the `signature`, `ttl`, or `expire` fields.

To do this, you can create the following Python script:
```sh
echo 'import base64, json

with open ("logs.json") as file:
    logs = json.load(file)
    data = logs["data"][0]

values = []

def decode_signature(data):
    signature = data["signature"]
    decoded = base64.b64decode(signature)

    f = open("record_signature", "wb")
    f.write(decoded)


def serialize(data):
    data["signature"] = None
    data["expire"] = None
    data["ttl"] = None

    for k, v in sorted(data.items()):
        if type(v) == dict:
            serialize(v)
        elif type(v) == int:
            v = str(v)
            values.append(v)
        elif v != None:
            values.append(v)

decode_signature(data)
serialize(data)

canonical = "|".join(values)
f = open("canonical_record.txt", "w")
f.write(canonical)' > validate.py
```

This script will read the first log in the audit log response and generate two files:
* `record_signature`, which contains the decoded signature
* `canonical_record.txt`, which contains the audit log record in canonical format.

Run the script to generate the files:

```sh
python3 validate.py
```

## Validate the audit log signature

Use OpenSSL to validate the signature:
```sh
openssl dgst -sha256 -verify public.pem -signature record_signature canonical_record.txt
```





