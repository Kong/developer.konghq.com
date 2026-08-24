---
title: Minimum `kong.conf` parameters needed to use a custom TLS certificate with Kong Manager
content_type: support
description: Kong Manager serves HTTPS by default with a self-signed certificate — these `kong.conf` parameters are only needed to replace it with your own custom certificate.
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: What are the minimum configuration needed to enable HTTPS on Kong Manager?
  a: |
    Kong Manager already serves HTTPS out of the box using an auto-generated self-signed certificate — no configuration is required. The `kong.conf` parameters below (`admin_gui_ssl_cert`, `admin_ssl_cert`, and related settings) are only needed if you want to replace that certificate with your own, for example one issued by a trusted CA.
related_resources:
  - text: Docker documentation on how to mount a directory into a Docker container
    url: https://docs.docker.com/storage/bind-mounts/
---

## What are the minimum configuration needed to enable HTTPS on Kong Manager

Hi, I would like to enable HTTPS on Kong Manager, what are the minimum configuration to enable it?

Kong Manager already serves HTTPS by default, using a self-signed certificate generated automatically with zero custom configuration required. The parameters below are not needed to "enable" HTTPS itself — they are only needed if you want to replace the default self-signed certificate with your own custom certificate (for example, one issued by a trusted CA).

Below are minimum parameters that you may need to set in `kong.conf` to configure a custom certificate for Kong Manager

```

  enforce_rbac=on //enabling rbac
  admin_gui_auth=basic-auth //setting up auth to basic-auth
  admin_gui_session_conf={"secret":"secret","storage":"kong","cookie_secure":true} //setting up session for Kong manager
  admin_gui_url=https://example.com:8445 <--Domain used for Kong Manager GUI
  admin_api_uri=https://example.com:8444 <-- Domain used for Kong Admin API
  admin_gui_ssl_cert=/tmp/cert/example.com_withSAN.crt <-- Server certificate for Kong Manager
  admin_gui_ssl_cert_key=/tmp/cert/example.com.key <-- Server certificate key for Kong Manager
  admin_ssl_cert=/tmp/cert/admin_example.com_withSAN.crt <-- Server Certificate for Kong Admin API HTTPS
  admin_ssl_cert_key=/tmp/cert/admin_example.com.key <-- Server Certificate for Kong Admin API HTTPS
```

For Docker container deployment, you may need to mount the certificates and keys to the Kong container before setting up it in the environment variables. Please refer Docker documentation on how to mount directory into docker container here.
