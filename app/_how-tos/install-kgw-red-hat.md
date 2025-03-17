---
title: Install {{site.base_gateway}} on Red Hat
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
    q: How do I install {{site.base_gateway}} on Red Hat? 
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
{% navtab "Manual Installation" %}
## 1. Download {{site.base_gateway}}:
   ```sh
   curl -Lo kong-enterprise-edition-{{page.latest_release.ee_version}}.rpm $(rpm --eval https://packages.konghq.com/public/gateway-{{page.latest_release.major_minor_version}}/rpm/el/%{rhel}/%{_arch}/kong-enterprise-edition-{{page.latest_release.ee_version}}.el%{rhel}.%{_arch}.rpm)
   ```

## 2. Install {{site.base_gateway}}:
   ```
   sudo yum install -y kong-enterprise-edition-{{page.latest_release.ee_version}}.rpm
   ```

{% endnavtab %}
{% navtab "Package manager" %}
## 1. Set up the package repository:
   ```sh
   curl -1sLf "https://packages.konghq.com/public/gateway-{{page.latest_release.major_minor_version}}/config.rpm.txt?distro=el&codename=$(rpm --eval '%{rhel}')" | sudo tee /etc/yum.repos.d/kong-gateway-{{page.latest_release.major_minor_version}}.repo
   ```
   ```
   sudo yum -q makecache -y --disablerepo='*' --enablerepo='kong-gateway-{{page.latest_release.major_minor_version}}'
   ```

## 2. Install {{site.base_gateway}}:
   ```
   sudo yum install -y kong-enterprise-edition-{{page.latest_release.ee_version}}
   ```

{% endnavtab %}
{% endnavtabs %}

## Configure the Datastore

{% include how-tos/steps/datastore.md %}