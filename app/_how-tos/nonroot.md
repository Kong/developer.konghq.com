---
title: Run {{site.base_gateway}} as a non-root user.
content_type: how_to
related_resources:
  - text: Enable RBAC
    url: /gateway/entities/rbac/#enable-rbac
  - text: Create a Super Admin
    url: /how-to/create-a-super-admin/

products:
    - gateway

works_on:
    - on-prem

tldr:
    q: How do you run {{site.base_gateway}} as a non-root user in Linux
    a: |
      When {{site.base_gateway}} is installed it creates the user group `kong`, users that belong to the `kong` can perform {{site.base_gateway}} actions. Adding your user to that user group will allow you to execute {{site.base_gateway}} commands on the system.

prereqs:
  inline:
    - title: Install {{site.base_gateway}} on Ubuntu
      include_content: prereqs/install/gateway/ubuntu
min_version:
    gateway: '3.4'

tags:
  - install
---

## 1. Add the existing user to the `kong` group

```sh
sudo usermod -aG kong your-user
```

## 2. Validate

You can validate by trying to run `kong start` which can only be done by a user or group that has execute access to the Kong directory: 

