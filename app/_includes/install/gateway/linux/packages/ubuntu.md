{%- assign default_flavor = page.release.distros_by_os.ubuntu | find: "default", true -%}
{%- assign available_codenames = page.release.distros_by_os.ubuntu | map: "codename" -%}
{%- assign available_flavors = "" | split: ""-%}
{%- for codename in available_codenames -%}
    {%- assign name = codename | capitalize -%}
    {%- assign available_flavors = available_flavors | push: name-%}
{%- endfor -%}

```bash
curl -1sLf "{{ site.links.direct }}/gateway-{{ include.release.major_minor_version }}/gpg.{{ include.gpg_key }}.key" |  gpg --dearmor | sudo tee /usr/share/keyrings/kong-gateway-{{ include.release.major_minor_version }}-archive-keyring.gpg > /dev/null
curl -1sLf "{{ site.links.direct }}/gateway-{{ include.release.major_minor_version }}/config.deb.txt?distro=ubuntu&codename={{ default_flavor.codename }}" | sudo tee /etc/apt/sources.list.d/kong-gateway-{{ include.release.major_minor_version }}.list > /dev/null
sudo apt-get update && sudo apt-get install -y kong-enterprise-edition={{include.release.ee_version}}
```

{% html_tag type="p" css_classes="text-secondary text-sm" %}
**Note:** {{site.base_gateway}} is packaged for {{available_flavors | join: ", "}}. The snippet above assumes you are running {{default_flavor.codename | capitalize}}. Replace it with your release. To check the name of your release, run `lsb_release -sc`.
{% endhtml_tag %}