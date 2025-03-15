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