{% navtabs %}
{% navtab "Manual Installation" %}
1. Download {{site.base_gateway}}:
    ```sh
    curl -Lo kong-enterprise-edition-3.9.0.1.rpm $(rpm --eval https://packages.konghq.com/public/gateway-39/rpm/el/%{rhel}/%{_arch}/kong-enterprise-edition-3.9.0.1.el%{rhel}.%{_arch}.rpm)
    ```

2. Install {{site.base_gateway}}:
    ```
    sudo yum install -y kong-enterprise-edition-3.9.0.1.rpm
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
    sudo yum install -y kong-enterprise-edition-3.9.0.1
    ```
{% endnavtab %}
{% endnavtabs %}