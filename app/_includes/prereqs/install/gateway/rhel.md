{%- capture package_url -%}{%- include install/gateway/linux/binaries/urls/rhel.html release=page.latest_release distro_codename="%{rhel}" distro_version_number="%{rhel}" arch="%{_arch}" -%}{%- endcapture -%}
{% navtabs "gateway-install-type" %}
{% navtab "Manual Installation" %}
Download and Install {{site.base_gateway}}:
```sh
curl -Lo kong-enterprise-edition-{{page.latest_release.ee_version}}.rpm $(rpm --eval {{package_url}})
sudo yum install -y kong-enterprise-edition-{{page.release.ee_version}}.rpm
```

{% endnavtab %}
{% navtab "Package manager" %}

Set up the package repository and install {{site.base_gateway}}:
{% assign distro = page.latest_release.distros_by_os[include.os] | find: "default", true %}
{% include install/gateway/linux/packages/rhel.html distro=distro release=page.latest_release os="rhel" %}

{% endnavtab %}
{% endnavtabs %}