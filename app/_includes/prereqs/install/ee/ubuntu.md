{% navtabs %}
{% navtab "Manual installation" %}
1. Download {{site.base_gateway}}:
```sh
curl -Lo kong-enterprise-edition-3.9.0.1.deb "https://packages.konghq.com/public/gateway-39/deb/ubuntu/pool/noble/main/k/ko/kong-enterprise-edition_3.9.0.1/kong-enterprise-edition_3.9.0.1_$(dpkg --print-architecture).deb"
```

2. Install {{site.base_gateway}}:
    ```
    sudo apt install -y ./kong-enterprise-edition-3.9.0.1.deb
    ```
{% endnavtab %}
{% navtab "Package manager" %}
1. Set up the package repository:
```sh
curl -1sLf "https://packages.konghq.com/public/gateway-39/gpg.B9DCD032B1696A89.key" |  gpg --dearmor | sudo tee /usr/share/keyrings/kong-gateway-39-archive-keyring.gpg > /dev/null
```
```
curl -1sLf "https://packages.konghq.com/public/gateway-39/config.deb.txt?distro=debian&codename=$(lsb_release -sc)" | sudo tee /etc/apt/sources.list.d/kong-gateway-39.list > /dev/null
```
2. Update the package manager:

    ```sh
    sudo apt update
    ```

3. Install {{site.base_gateway}}:
```
sudo apt install -y kong-enterprise-edition=3.9.0.1
```
{% endnavtab %}
{% endnavtabs %}