---
title: Run Inso CLI on Docker
permalink: /how-to/run-inso-cli-on-docker/

description: "Inso CLI is available as a Docker image."

content_type: how_to

products:
  - insomnia

tags:
  - docker

prereqs:
  inline:
  - title: Create a design document
    include_content: prereqs/design-document
    icon_url: /assets/icons/file.svg

tldr:
  q: How can I run Inso CLI with Docker?
  a: |
    Pull the latest [`kong/inso`](https://hub.docker.com/r/kong/inso) Docker image, then run Inso CLI commands by mounting your specs folder to the `/var/temp` folder in the container.

related_resources:
  - text: Inso CLI
    url: /inso-cli/
  - text: kong/inso on Docker Hub
    url: https://hub.docker.com/r/kong/inso
  - text: Verify signatures for signed Inso CLI Docker images
    url: /inso-cli/verify-docker-image-signature/
  - text: Verifying build provenance for signed Inso CLI Docker images
    url: /inso-cli/verify-docker-image-provenance/

faqs:
  - q: How can I use Insomnia data from a Git repository with Inso CLI on Docker?
    a: |
        Use the following command from your Insomnia Git repository folder to mount it to the `/var/temp` folder in the container:

        ```sh
        docker run -it --rm -v $(pwd):/var/temp kong/inso:latest lint spec -w /var/temp
        ```
  - q: How can I use Inso CLI on Docker with an Insomnia v4 export?
    a: |
        Use the following command to mount the folder where you keep an Insomnia v4 export:

        ```sh
        docker run -it --rm -v $(pwd):/var/temp kong/inso:latest lint spec -w /var/temp/Insomnia_YYYY-MM-DD.json
        ```
---

## Pull `kong/inso`

Pull the latest `kong/inso` Docker image:

```sh
docker pull kong/inso:latest
```

{:.info}
> All available tags can be found on Inso CLI's [Docker Hub page](https://hub.docker.com/r/kong/inso/tags).


## Run Inso CLI commands

To run Inso CLI commands in the `kong/inso` container, mount the specs folder on your host machine to a `/var/temp` folder in the container. In this example, we'll use the [`lint spec`](/inso-cli/reference/lint_spec/) command. Run the command based on the location of your Insomnia data. In this example, we're using the default application data folder:

{% navtabs "os" %}
{% navtab "macOS" %}
```sh
docker run -v $HOME/Library/Application\ Support/Insomnia:/var/temp -it --rm kong/inso:latest lint spec -w /var/temp
```
{% endnavtab %}
{% navtab "Linux" %}
```sh
docker run -v $HOME/.config/Insomnia:/var/temp -it --rm kong/inso:latest lint spec -w /var/temp
```
{% endnavtab %}
{% navtab "Windows (with Docker for Windows and WSL)" %}
```sh
docker run -v /mnt/c/Users/$YOUR_USERNAME/AppData/Roaming/Insomnia:/var/temp -it --rm kong/inso:latest lint spec -w /var/temp
```
{% endnavtab %}
{% endnavtabs %}

For more location options, see the [FAQs](#faqs).