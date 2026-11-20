{% capture summary %}
kong-harnesses
{% endcapture %}

{% capture details_content %}
This tutorial uses [kong-harnesses](/kong-harnesses/) to sign in developers and configure their coding agents.

Install kong-harnesses 0.17.1 or later.
Earlier releases accept only an `https://` gateway origin.

{:.info}
> **Supported computers:** kong-harnesses runs on macOS, on Windows 11, and on Linux desktops with Secret Service, such as Ubuntu 26.04, 24.04 and 22.04, and Red Hat Enterprise Linux 9, on amd64 and arm64.
> Set it up on the desktop you work on, not in WSL, a container or an SSH session.

{% navtabs "install-kong-harnesses" %}
{% navtab "macOS" %}
{% include tools/kong-harnesses/install/osx.md %}
{% endnavtab %}
{% navtab "Linux" %}
{% include tools/kong-harnesses/install/linux.md %}
{% endnavtab %}
{% navtab "Windows" %}
{% include tools/kong-harnesses/install/windows.md %}
{% endnavtab %}
{% endnavtabs %}

Run `kong-harnesses version` to check that your version is new enough.

If the shell can't find `kong-harnesses`, open a new terminal.
On macOS and Linux, export the variables from the earlier prerequisites again.
{% endcapture %}

{% include how-tos/prereq_cleanup_item.html summary=summary details_content=details_content icon_url='/assets/icons/code.svg' %}
