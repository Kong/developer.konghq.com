---
title: Install {{site.base_gateway}} FIPS on Red Hat
content_type: how_to
products:
    - gateway
works_on:
    - on-prem

min_version:
  gateway: '3.4'
tags:
    - rate-limiting

tldr:
    q: How do I install the {{site.base_gateway}} FIPS package on Red Hat? 
    a: Download the {{site.base_gateway}} package and install it using your package manager. Then configure the database.

tools:
    - deck

prereqs:
  skip_product: true
  inline:
    - title: Install PostgreSQL
      content: |
        [Install PostgreSQL](https://www.postgresql.org/download/)
    - title: Configure environment variables
      include_content: prereqs/install/gateway/datastore-env-variables
      icon_url: /assets/icons/file.svg
---

{% navtabs %}
{% navtab "Manual installation" %}
1. Download {{site.base_gateway}}:
    ```sh
     curl -Lo kong-enterprise-edition-fips-3.9.0.1.rpm $(rpm --eval https://packages.konghq.com/public/gateway-39/rpm/el/%{rhel}/x86_64/kong-enterprise-edition-fips-3.9.0.1.el%{rhel}.x86_64.rpm)
    ```

2. Install {{site.base_gateway}}:
    ```
    yum install kong-enterprise-edition-fips-3.9.1.0
    ```
{% endnavtab %}
{% navtab "Package manager" %}
1. Set up the package repository:
    ```sh
     curl -1sLf "https://packages.konghq.com/public/gateway-39/config.rpm.txt?distro=el&codename=$(rpm --eval '%{rhel}')" | sudo tee /etc/yum.repos.d/kong-gateway-39.repo
    ```
    ```
     sudo yum -q makecache -y --disablerepo='*' --enablerepo='kong-gateway-39'
    ```

2. Install {{site.base_gateway}}:
    ```
    yum install kong-enterprise-edition-fips-3.9.1.0
    ```
{% endnavtab %}
{% endnavtabs %}

3. Enable FIPS:

```sh
export KONG_FIPS=on && kong reload
```

## Configure the Datastore

{% include how-tos/steps/datastore.md %}