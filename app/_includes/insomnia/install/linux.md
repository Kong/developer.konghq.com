* Ubuntu and Debian:
    ```sh
    # Add to sources
    curl -1sLf \
    'https://packages.konghq.com/public/insomnia/setup.deb.sh' \
    | sudo -E distro=ubuntu codename=focal bash


    # Refresh repository sources and install Insomnia

    sudo apt-get update
    sudo apt-get install insomnia
    ```
    You can also download the older [year-versioned Debian packages](https://cloudsmith.io/~kong/repos/insomnia-legacy) or the [latest Debian packages](https://cloudsmith.io/~kong/repos/insomnia) directly from our package hosting.
* Snap:
    ```sh
    sudo snap install insomnia
    ```