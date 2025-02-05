---
title: "{{site.base_gateway}} Installation Reference"

description: |
  {{site.base_gate}} installation reference
content_type: reference
layout: reference
products:
   - gateway

related_resources:
  - text: "Managing {{site.base_gateway}} configuration"
    url: /gateway/manage-kong-conf/
   
works_on:
   - on-prem
---


## Linux
### Enterprise 
{% navtabs %}
{% navtab "Debian" %}
{% include prereqs/install/ee/debian.md %}
{% endnavtab %}
{% navtab "Ubuntu" %}
{% include prereqs/install/ee/ubuntu.md %}
{% endnavtab %}
{% navtab "Amazon Linux" %}
{% include prereqs/install/ee/amazon-linux.md %}
{% endnavtab %}
{% navtab "Red Hat" %}
{% include prereqs/install/ee/red-hat.md %}
{% endnavtab %}
{% endnavtabs %}
### Open Source

{% navtabs %}
{% navtab "Debian" %}
{% include prereqs/install/oss/debian.md %}
{% endnavtab %}
{% navtab "Ubuntu" %}
{% include prereqs/install/oss/ubuntu.md %}
{% endnavtab %}
{% navtab "Amazon Linux" %}
{% include prereqs/install/oss/amazon-linux.md %}
{% endnavtab %}
{% navtab "Red Hat" %}
{% include prereqs/install/oss/red-hat.md %}
{% endnavtab %}
{% endnavtabs %}


### FIPS install

{{site.base_gateway}} provides a FIPS 140-2 compliant package for Ubuntu 20.04 , Ubuntu 22.04 , Red Hat Enterprise 9 , and Red Hat Enterprise 8 . This package provides compliance for the core {{site.base_gateway}} product and all out of the box plugins. For more information see the [FIPS reference page](/gateway/fips/)


{% navtabs %}
{% navtab "Ubuntu" %}
{% include prereqs/install/fips/ubuntu.md %}
{% endnavtab %}
{% navtab "Red Hat" %}
{% include prereqs/install/fips/red-hat.md %}
{% endnavtab %}
{% endnavtabs %}

## Running {{site.base_gateway}} as a non-root user

When {{site.base_gateway}} is installed, the installation process creates the user group `kong`, users that belong to the `kong` can perform {{site.base_gateway}} actions. Adding your user to that user group will allow you to execute {{site.base_gateway}} commands on the system.



You can check the permissions and ownership of the {{site.base_gateway}} in Linux like this: 

`ls -l /usr/local/kong`

Which will return a list of subdirectories that contain a prefix like this: 
`drwxrwxr-x 2 kong kong`

The two `kong` values mean that the directory is owned by the user `kong` and the group `kong`. 

In Linux to make an existing user part of the Kong group you can run this command: 

`usermod -aG kong $USER`

To view existing groups associated with the user: 

`groups $USER`. 


### Nginx

In {{site.base_gateway}} the Nginx master process runs at the `root` level so that Nginx can execute actions even if {{site.base_gateway}} is running as a non-root user. This is important when building containers.

