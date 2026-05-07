---
title: Upgrade the transparent proxy
description: Clean up existing iptables rules and reinstall the transparent proxy on Universal environments.
content_type: how_to
breadcrumbs:
  - /mesh/
permalink: /mesh/upgrading-transparent-proxy/
products:
  - mesh
works_on:
  - on-prem
tldr:
  q: How do I upgrade the transparent proxy on Universal environments?
  a: Clean up existing iptables rules if needed, then reinstall the transparent proxy using `kumactl install transparent-proxy`.
tags:
  - upgrade
related_resources:
  - text: Transparent proxying
    url: /mesh/transparent-proxying/

---

The core `iptables` rules applied by {{site.mesh_product_name}}'s transparent proxy rarely change, but occasionally new features may require updates. To upgrade the transparent proxy on Universal environments, follow these steps:

### Step 1: Clean up existing iptables rules

{% if_version gte:2.9.x %}
{:.warning}
> **Important:** If you're upgrading from {{site.mesh_product_name}} version 2.9 or later, and you have **not** manually disabled the automatic addition of comments by setting `comments.disabled` to `true` in the transparent proxy configuration, **this step is unnecessary**.
>
> Starting with {{site.mesh_product_name}} 2.9, all `iptables` rules are tagged with comments, allowing {{site.mesh_product_name}} to track rule ownership. This enables `kumactl` to automatically clean up any existing `iptables` rules or custom chains created by previous versions of the transparent proxy. This process runs automatically at the start of the installation, eliminating the need for any manual cleanup beforehand.
{% endif_version %}

To manually remove existing `iptables` rules, you can either restart the host (if the rules were not persisted using system start-up scripts or `firewalld`), or run the following commands:

{:.danger}
> **Warning:** These commands will remove **all** `iptables` rules and **all** custom chains in the specified tables, including those created by {{site.mesh_product_name}} as well as any other applications or services.

```sh
iptables --table nat --flush         # Flush all rules in the nat table (IPv4)
ip6tables --table nat --flush        # Flush all rules in the nat table (IPv6)
iptables --table nat --delete-chain  # Delete all custom chains in the nat table (IPv4)
ip6tables --table nat --delete-chain # Delete all custom chains in the nat table (IPv6)

# The raw table contains rules for DNS traffic redirection
iptables --table raw --flush         # Flush all rules in the raw table (IPv4)
ip6tables --table raw --flush        # Flush all rules in the raw table (IPv6)

# The mangle table contains rules to drop invalid packets
iptables --table mangle --flush      # Flush all rules in the mangle table (IPv4)
ip6tables --table mangle --flush     # Flush all rules in the mangle table (IPv6)
```

### Step 2: Install the new transparent proxy

After clearing the `iptables` rules (if necessary), reinstall the transparent proxy. For example:

```sh
kumactl install transparent-proxy --kuma-dp-user kuma-dp --redirect-dns --verbose
```

This installs the latest version of the transparent proxy with the specified configuration. Adjust the flags as needed for your environment.
