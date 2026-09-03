---
title: How to set up kong to autostart kong with systemd with a non root user
content_type: support
description: How to configure systemd to run {{site.base_gateway}} as a non-root `kong` user on RHEL and CentOS 8, instead of root.
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources: []
tldr:
  q: How do I set up {{site.base_gateway}} to autostart with systemd as a non-root user?
  a: |
    Copy Kong's `kong-enterprise-edition.service` unit file to `/home/kong/.config/systemd/user/`, remove the hardcoded `User=` and `Group=` lines, and change `WantedBy=multi-user.target` to `WantedBy=default.target`. Enable lingering for the `kong` user with `loginctl enable-linger $USER` and set `XDG_RUNTIME_DIR` so `systemctl --user` commands can start and enable the service at boot.
---

## Overview

The instructions for controlling {{site.base_gateway}} through systemd require root to be used to start kong as a root user. We would like to use a non-root user, e.g. a "kong" user.

## Steps

In RHEL and CentOS 8 you can configure systemd to control the {{site.base_gateway}} as a "kong" user by following these steps:

1. Log into the VM where you want to configure the Gateway to start as the "kong" user.
2. Create a folder called `/home/kong/.config/systemd/user/`.
3. Copy `/lib/systemd/system/kong-enterprise-edition.service` (this is the file's actual shipped location in the current {{site.ee_product_name}} package/image - it is not found under `/etc/kong/`) to `/home/kong/.config/systemd/user/`.
4. Edit `/home/kong/.config/systemd/user/kong-enterprise-edition.service` and remove the `User=` and `Group=` lines - Kong's shipped unit file hardcodes `User=root`, and a copied user-level unit will fail to start unless those lines are stripped out.
5. In the same file, replace:

   ```
   [Install]
   WantedBy=multi-user.target
   ```

   with

   ```
   [Install]
   WantedBy=default.target
   ```

6. Run the following to make sure the {{site.base_gateway}} process can continue to run when the kong user has logged off:

   ```bash
   loginctl enable-linger $USER
   ```

7. Add the following to `.bash_profile`, and source `~/.bash_profile` afterwards:

   ```bash
   export XDG_RUNTIME_DIR=/run/user/$(id -u)
   ```

8. You can now start kong using systemctl, and enable autostart at system boot with these two commands:

   ```bash
   systemctl --user start kong-enterprise-edition
   systemctl --user enable kong-enterprise-edition
   ```
