---
title: Run kongctl in Docker
description: >-
  Run kongctl in a Docker container to authenticate to Konnect, query resources,
  and apply local declarative configuration files.
content_type: reference
layout: reference
works_on:
  - konnect
tools:
  - kongctl
tags:
  - cli
breadcrumbs:
  - /kongctl/
related_resources:
  - text: kongctl authentication
    url: /kongctl/authentication/
  - text: kongctl configuration
    url: /kongctl/config/
  - text: kongctl declarative configuration
    url: /kongctl/declarative/
---

You can run kongctl in a Docker container without installing the CLI on your
host. Kong publishes images to
[Docker Hub](https://hub.docker.com/r/kong/kongctl)
and the [GitHub Container Registry][ghcr].
The images support Linux on AMD64 and ARM64.

[ghcr]: https://github.com/Kong/kongctl/pkgs/container/kongctl

The examples below use Docker and a POSIX-compatible shell, such as Bash or Zsh.
To run commands against {{site.konnect_short_name}}, you also need an account
with permission to access the resources you want to manage.

## Pull and run the image

Pull the latest stable image and check its version:

```bash
docker pull kong/kongctl:latest
docker run --rm kong/kongctl:latest version
```

For reproducible runs, replace `latest` with a specific release tag, such as
`{{site.data.kongctl_latest.version}}`. You can also replace `kong/kongctl` with
`ghcr.io/kong/kongctl` in these examples.

The image entrypoint is kongctl. Pass commands and flags directly after the
image name:

```bash
docker run --rm kong/kongctl:latest --help
docker run --rm kong/kongctl:latest get apis --help
```

The `--rm` Docker flag removes the container when the command exits.

## Authenticate with a personal access token

Create a [personal access token](/konnect-api/#personal-access-tokens) and
export it in your host shell:

```bash
export KONGCTL_DEFAULT_KONNECT_PAT='YOUR_KONNECT_PAT'
```

Pass the environment variable into each container with Docker's `-e` flag.
For example, list the APIs in your organization:

```bash
docker run --rm \
  -e KONGCTL_DEFAULT_KONNECT_PAT \
  kong/kongctl:latest get apis --region us
```

Replace `us` with your {{site.konnect_short_name}} region. These examples use
the `default` kongctl profile. If you select another profile, use the matching
[profile environment variable](/kongctl/config/#environment-variables).

## Use local declarative configuration files

Bind mount the directory containing your
[declarative configuration](/kongctl/declarative/) into the container. Setting
the working directory to the mount path lets kongctl resolve relative paths
within that directory.

From a directory containing your `kongctl.yaml` file, preview the changes:

```bash
docker run --rm \
  -e KONGCTL_DEFAULT_KONNECT_PAT \
  --mount type=bind,src="$(pwd)",dst=/work,readonly \
  --workdir /work \
  kong/kongctl:latest plan --mode apply -f kongctl.yaml --region us
```

To apply the configuration, allocate an interactive terminal with `-it` so you
can answer the confirmation prompt:

```bash
docker run --rm -it \
  -e KONGCTL_DEFAULT_KONNECT_PAT \
  --mount type=bind,src="$(pwd)",dst=/work,readonly \
  --workdir /work \
  kong/kongctl:latest apply -f kongctl.yaml --region us
```

For automation, omit `-it` and add `--auto-approve` to the `apply` command only
when you intend to apply changes without confirmation.

The mount is read-only because these commands only need to read your files.
If you use a command that writes files into `/work`, remove `readonly` and
ensure the directory is writable by the container's `kongctl` user. Host paths
outside the mounted directory are not available inside the container.

## Persist browser-based login credentials

You can also use [browser-based login](/kongctl/authentication/) instead of a
personal access token. Store the configuration and tokens in a named Docker
volume so they persist after the container exits:

```bash
docker volume create kongctl-home
docker run --rm -it \
  -e XDG_CONFIG_HOME=/home/kongctl/.config \
  --mount type=volume,src=kongctl-home,dst=/home/kongctl \
  kong/kongctl:latest login
```

Open the URL printed by kongctl in a browser on your host and complete the
login. Reuse the volume and configuration path in subsequent commands:

```bash
docker run --rm \
  -e XDG_CONFIG_HOME=/home/kongctl/.config \
  --mount type=volume,src=kongctl-home,dst=/home/kongctl \
  kong/kongctl:latest get apis --region us
```

The volume stores credentials as well as configuration. Keep it writable so
kongctl can save and refresh tokens. To clear the stored login credentials,
run `logout` with the same mount and environment variable:

```bash
docker run --rm \
  -e XDG_CONFIG_HOME=/home/kongctl/.config \
  --mount type=volume,src=kongctl-home,dst=/home/kongctl \
  kong/kongctl:latest logout
```
