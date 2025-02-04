{% navtabs %}
{% navtab "Manually installation" %}
1. Download {{site.base_gateway}}:
```sh
curl -Lo kong-enterprise-edition-3.9.0.1.rpm $(rpm --eval https://packages.konghq.com/public/gateway-39/rpm/amzn/%{amzn}/%{_arch}/kong-enterprise-edition-3.9.0.1.aws.%{_arch}.rpm)
```

2. Install {{site.base_gateway}}:
    ```
    sudo yum install -y kong-enterprise-edition-3.9.0.1.rpm
    ```
{% endnavtab %}
{% navtab "Package manager" %}
1. Set up the package repository:
```sh
 curl -1sLf "https://packages.konghq.com/public/gateway-39/config.rpm.txt?distro=amzn&codename=$(rpm --eval '%{amzn}')" | sudo tee /etc/yum.repos.d/kong-gateway-39.repo > /dev/null
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