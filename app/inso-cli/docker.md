---
title: Inso CLI on Docker

description: 

content_type: reference
layout: reference

products:
  - insomnia

tools:
  - inso-cli

tags:
  - docker

breadcrumbs:
  - /inso-cli/

related_resources:
  - text: Inso CLI
    url: /inso-cli/
  - text: kong/inso on Docker Hub
    url: https://hub.docker.com/r/kong/inso
---

## Pull `kong/inso`

Pull the latest `kong/inso` Docker image:

```shell
docker pull kong/inso:latest
```

All available tags can be found on Inso CLI's [Docker Hub page](https://hub.docker.com/r/kong/inso/tags).


## Run Inso CLI commands

To run Inso CLI commands in the `kong/inso` container, mount the specs folder on your host machine to a `/var/temp` folder in the container. See the following examples:

### Git sync repo

Use the following command from your Insomnia Git repository folder to mount it to the `/var/temp` folder in the container:

```sh
docker run -it --rm -v $(pwd):/var/temp kong/inso:latest run test -w /var/temp
```

## Application data folder

Use the relevant command to mount the Insomnia application data folder to the `/var/temp` folder in the container:

{% navtabs "os" %}
{% navtab "macOS" %}
```sh
docker run -v $HOME/Library/Application\ Support/Insomnia:/var/temp -it --rm kong/inso:latest run test -w /var/temp
```
{% endnavtab %}
{% navtab "Linux" %}
```sh
docker run -v $HOME/.config/Insomnia:/var/temp -it --rm kong/inso:latest run test -w /var/temp
```
{% endnavtab %}
{% navtab "Windows (with Docker for Windows and WSL)" %}
```sh
docker run -v /mnt/c/Users/$YOUR_USERNAME/AppData/Roaming/Insomnia:/var/temp -it --rm kong/inso:latest run test -w /var/temp
```
{% endnavtab %}
{% endnavtabs %}

### Insomnia v4 export folder

Mount the folder where you keep an Insomnia v4 export:

```sh
docker run -it --rm -v $(pwd):/var/temp kong/inso:latest run test -w /var/temp/Insomnia_YYYY-MM-DD.json
```