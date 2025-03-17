---
title: Install {{site.base_gateway}} on Ubuntu
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
    q: How do I install {{site.base_gateway}} on Ubuntu? 
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
## 1. Download {{site.base_gateway}}:
   ```sh
   curl -Lo kong-enterprise-edition-{{page.latest_release.ee_version}}.deb "https://packages.konghq.com/public/gateway-{{page.latest_release.major_minor_version}}/deb/ubuntu/pool/noble/main/k/ko/kong-enterprise-edition_{{page.latest_release.ee_version}}/kong-enterprise-edition_{{page.latest_release.ee_version}}_$(dpkg --print-architecture).deb"
   ```

## 2. Install {{site.base_gateway}}:
   ```
   sudo apt install -y ./kong-enterprise-edition-{{page.latest_release.ee_version}}.deb
   ```

{% endnavtab %}
{% navtab "Package manager" %}
## 1. Set up the package repository:
   ```sh
   curl -1sLf "https://packages.konghq.com/public/gateway-{{page.latest_release.major_minor_version}}/gpg.B9DCD032B1696A89.key" |  gpg --dearmor | sudo tee /usr/share/keyrings/kong-gateway-{{page.latest_release.major_minor_version}}-archive-keyring.gpg > /dev/null
   ```

   ```
   curl -1sLf "https://packages.konghq.com/public/gateway-{{page.latest_release.major_minor_version}}/config.deb.txt?distro=debian&codename=$(lsb_release -sc)" | sudo tee /etc/apt/sources.list.d/kong-gateway-{{page.latest_release.major_minor_version}}.list > /dev/null
   ```

## 2. Update the package manager:

    ```sh
    sudo apt update
    ```

## 3. Install {{site.base_gateway}}:
   ```
   sudo apt install -y kong-enterprise-edition={{page.latest_release.ee_version}}
   ```

{% endnavtab %}
{% endnavtabs %}


## Configure the Datastore

{% include how-tos/steps/datastore.md %}