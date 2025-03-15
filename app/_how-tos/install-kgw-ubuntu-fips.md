---
title: Install {{site.base_gateway}} FIPS package on Ubuntu
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
    q: How do I install the {{site.base_gateway}} FIPS package on Ubuntu? 
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


## 1. Set up the package repository:
```sh
curl -1sLf "https://packages.konghq.com/public/gateway-39/gpg.B9DCD032B1696A89.key" |  gpg --dearmor >> /usr/share/keyrings/kong-gateway-39-archive-keyring.gpg
```
```
curl -1sLf "https://packages.konghq.com/public/gateway-38/config.deb.txt?distro=ubuntu&codename=$(lsb_release -sc)" > /etc/apt/sources.list.d/kong-gateway-39.list
```
## 2. Update the package manager:

    ```sh
    sudo apt update
    ```

## 3. Install {{site.base_gateway}}:
```
apt install -y kong-enterprise-edition-fips=3.9.1.0
```

## 4. Enable FIPS
```sh
export KONG_FIPS=on && kong reload
```

## Configure the Datastore

{% include how-tos/steps/datastore.md %}