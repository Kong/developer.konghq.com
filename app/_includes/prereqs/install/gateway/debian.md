{% navtabs "gateway-install-type" %}
{% navtab "Manual installation" %}
1. Download {{site.base_gateway}}:
   ```sh
   curl -Lo kong-enterprise-edition-{{page.latest_release.ee_version}}.deb "https://packages.konghq.com/public/gateway-{{page.latest_release.major_minor_version}}/deb/debian/pool/bullseye/main/k/ko/kong-enterprise-edition_{{page.latest_release.ee_version}}/kong-enterprise-edition_{{page.latest_release.ee_version}}_$(dpkg --print-architecture).deb"
   ```

2. Install {{site.base_gateway}}:
   ```
   sudo apt install -y ./kong-enterprise-edition-{{page.latest_release.ee_version}}.deb
   ```

{% endnavtab %}
{% navtab "Package manager" %}
1. Set up the package repository:
   ```sh
   curl -1sLf "https://packages.konghq.com/public/gateway-{{page.latest_release.major_minor_version}}/gpg.B9DCD032B1696A89.key" |  gpg --dearmor | sudo tee /usr/share/keyrings/kong-gateway-{{page.latest_release.major_minor_version}}-archive-keyring.gpg > /dev/null
   ```

   ```
   curl -1sLf "https://packages.konghq.com/public/gateway-{{page.latest_release.major_minor_version}}/config.deb.txt?distro=debian&codename=$(lsb_release -sc)" | sudo tee /etc/apt/sources.list.d/kong-gateway-{{page.latest_release.major_minor_version}}.list > /dev/null
   ```

2. Update the package manager:

    ```sh
    sudo apt update
    ```

3. Install {{site.base_gateway}}:
   ```
   sudo apt install -y kong-enterprise-edition={{page.latest_release.ee_version}}
   ```
   
{% endnavtab %}
{% endnavtabs %}