1. Set up the package repository:
```sh
curl -1sLf "https://packages.konghq.com/public/gateway-39/gpg.B9DCD032B1696A89.key" |  gpg --dearmor >> /usr/share/keyrings/kong-gateway-39-archive-keyring.gpg
```
```
curl -1sLf "https://packages.konghq.com/public/gateway-38/config.deb.txt?distro=ubuntu&codename=$(lsb_release -sc)" > /etc/apt/sources.list.d/kong-gateway-39.list
```
2. Update the package manager:

    ```sh
    sudo apt update
    ```

3. Install {{site.base_gateway}}:
```
apt install -y kong-enterprise-edition-fips=3.9.1.0
```

4. Enable FIPS

```sh
export KONG_FIPS=on && kong reload
```