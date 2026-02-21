{% assign summary='Kong Konnect' %}

{% capture details_content %}

This is a Konnect tutorial and requires a Konnect personal access token.

1. Create a new personal access token by opening the [Konnect PAT page](https://cloud.konghq.com/global/account/tokens) and selecting **Generate Token**.

1. Export your token to an environment variable:

    ```bash
    export KONNECT_TOKEN='YOUR_KONNECT_PAT'
    ```

1. Run the [quickstart script](https://get.konghq.com/quickstart) to automatically provision a Control Plane and Data Plane, and configure your environment:

    ```bash
    curl -Ls https://get.konghq.com/quickstart | bash -s -- -k $KONNECT_TOKEN{% for variable in include.env_variables %} -e {{ variable.name }}{% if variable.value %}={{ variable.value }}{% endif %}{% endfor %}{% if include.ports %}{% for port in include.ports %} -p {{ port }}{% endfor %}{% endif %} --deck-output
    ```

    This sets up a Konnect Control Plane named `quickstart`, provisions a local Data Plane, and prints out the following environment variable exports:

    ```bash
    export DECK_KONNECT_TOKEN=$KONNECT_TOKEN
    export DECK_KONNECT_CONTROL_PLANE_NAME=quickstart
    export KONNECT_CONTROL_PLANE_URL=https://us.api.konghq.com
    export KONNECT_PROXY_URL='http://localhost:8000'
    ```

    Copy and paste these into your terminal to configure your session.

{% endcapture %}
{% include how-tos/prereq_cleanup_item.html summary=summary details_content=details_content icon_url='/assets/icons/gateway.svg' %}