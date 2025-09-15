Go to the [Insomnia downloads page](https://insomnia.rest/download) to download and run the installer for Ubuntu, or use `apt-get`:
```sh
# Add to sources
curl -1sLf \
  'https://packages.konghq.com/public/insomnia/setup.deb.sh' \
  | sudo -E distro=ubuntu codename=focal bash


# Refresh repository sources and install Insomnia

sudo apt-get update
sudo apt-get install insomnia
```