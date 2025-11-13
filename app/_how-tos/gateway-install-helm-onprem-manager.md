---
title: Enable Kong Manager with {{ site.base_gateway }} on Kubernetes
short_title: Enable Kong Manager
description: View your {{ site.base_gateway }} configuration in a UI using Kong Manager
content_type: how_to
permalink: /gateway/install/kubernetes/on-prem/manager/
breadcrumbs:
  - /gateway/
  - /gateway/install/

series:
  id: gateway-k8s-on-prem-install
  position: 3
products:
  - gateway

works_on:
  - on-prem

entities: []

tldr: null

prereqs:
  skip_product: true

faqs:
  - q: I can't log in to Kong Manager.
    a: Check that `env.password` was set in `values-cp.yaml` before installing Kong. {{ site.base_gateway }} generates a random admin password if this is not set. This password can not be recovered and you must reinstall Kong to set a new admin password.

  - q: What are my login credentials?
    a: The Kong super admin username is `kong_admin`, and the password is the value set in `env.password` in `values-cp.yaml`.

  - q: Kong Manager shows a white screen.
    a: Ensure that `env.admin_gui_api_url` is set correctly in `values-cp.yaml`.

automated_tests: false
next_steps:
  - text: Rate limit a Gateway Service
    url: /how-to/add-rate-limiting-to-a-service-with-kong-gateway/
  - text: Enable key authentication on a Gateway Service
    url: /how-to/authenticate-consumers-with-key-auth-enc/

tags:
  - install
---

Kong Manager is the graphical user interface (GUI) for {{ site.base_gateway }}. It uses the Kong Admin API under the hood to administer and control {{ site.base_gateway }}.

{:.warning}
> Kong's Admin API must be accessible over HTTP from your local machine to use Kong Manager

## Installation

Kong Manager is served from the same node as the Admin API. To enable Kong Manager, make the following changes to your `values-cp.yaml` file.

1. Set `admin_gui_url`, `admin_gui_api_url` and `admin_gui_session_conf` under the `env` key:

   ```yaml
   env:
     admin_gui_url: http://manager.example.com
     admin_gui_api_url: http://admin.example.com
     # Change the secret and set cookie_secure to true if using an HTTPS endpoint
     admin_gui_session_conf: '{"secret":"secret","storage":"kong","cookie_secure":false}'
   ```

1. Replace `example.com` in the configuration with your domain.

1. Enable Kong Manager authentication under the `enterprise` key:

   ```yaml
   enterprise:
     rbac:
       enabled: true
       admin_gui_auth: basic-auth
   ```

{% include k8s/helm-ingress-setup.md service="manager" release="cp" type="private" skip_ingress_controller_install=true %}

## Testing

Visit the URL in `env.admin_gui_url` in a web browser to see the Kong Manager log in page. The default username is `kong_admin`, and the password is the value you set in `env.password` when installing the {{ site.base_gateway }} control plane in the previous step.
